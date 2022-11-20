local sickblock = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

sickblock.name = "sickblock"
sickblock.id = NPC_ID
sickblock.order = 0.64

local TYPE_NORMAL = 0
local TYPE_MASKED = 1
local TYPE_ASYMPTOMATIC = 2
local MODE_NORMAL = 0
local MODE_ANGELIC = 1

local found = false
sickblock.onRedPower = function(n, c, power, dir, hitbox)
  if n.data.frameX == TYPE_ASYMPTOMATIC then
    n.data.immune = redstone.is.sickblock(c.id)
  end

  found = true
  redstone.setEnergy(n, power)
end

sickblock.config = npcManager.setNpcSettings({
  id = sickblock.id,

  width = 32,
  height = 32,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 1,
	framespeed = 8,
	framestyle = 0,
  invisible = false,
  mute = false,

  nogravity = true,
	jumphurt = true,
  noblockcollision = true,
  notcointransformable = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true,


  hasnosoul = false,
  deathtimer = 4     -- Amount of frames it takes
})

local sfxpower = Audio.SfxOpen(Misc.resolveFile("sickblock-power.ogg"))
local sfxdeath = Audio.SfxOpen(Misc.resolveFile("sickblock-death.ogg"))

local infectionList

local EXISTS_REAPER
local EXISTS_DEADSICKBLOCK

local function deadfilter(v)
  return not v.data.isDead and not v.data.immune
end

function sickblock.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.type or 0
  data.frameY = data.frameY or 0

  data.mode = data._settings.mode or 0
  data.isDead = data.isDead or false
  data.deathTimer = data.deathTimer or 0
  data.immune = data.immune or false
  data.immuneTimer = data.immuneTimer or 0

  data.redarea = data.redarea or redstone.basicRedArea(n)
  data.redhitbox = data.redhitbox or redstone.basicRedHitBox(n)
end


function sickblock.onRedLoad()
  infectionList = redstone.id("sickblock", "reflector")

  EXISTS_REAPER = redstone.id.reaper
  EXISTS_DEADSICKBLOCK = redstone.id.deadsickblock
end

function sickblock.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.isDead and data.deathTimer > 0 then
    data.deathTimer = data.deathTimer - 1
    if data.deathTimer == 0 then
      found = false
      if data.frameX ~= TYPE_MASKED then
        redstone.updateRedArea(n)
        redstone.updateRedHitBox(n)
        redstone.passEnergy{source = n, power = 15, hitbox = data.redhitbox, area = data.redarea, npcList = infectionList, filter = deadfilter}
      end
      if not found and redstone.onScreenSound(n) then
        SFX.play(sfxdeath)
      end
    end
  end


  if data.power > 0 and not data.isDead then
    if redstone.onScreenSound(n) then
      SFX.play(sfxpower)
    end

    data.observ = true
    data.isDead = true
    data.deathTimer = sickblock.config.deathtimer

    if not data.immune then
      data.pistIgnore = true
      n.friendly = true
    end

    if EXISTS_REAPER then
      redstone.component.reaper.onPostNPCKill(n)
    end
  end

  if data.immuneTimer > 0 then
    data.immuneTimer = data.immuneTimer - 1
    if data.immuneTimer == 0 then
      data.immune = false
    end
  end

  if data.isDead then
    if data.deathTimer == 0  then
      if data.immune then
        data.isDead = false
        data.immuneTimer = sickblock.config.deathtimer + 2
      else
        if EXISTS_DEADSICKBLOCK then
          data.frameY = data.mode
          n.id = redstone.id.deadsickblock
        else
          n:kill()
        end
      end
    else
      data.frameY = 2
    end
  else
    data.frameY = data.mode
  end

  redstone.resetPower(n)
end

sickblock.onRedDraw = redstone.drawNPC

redstone.register(sickblock)

return sickblock
