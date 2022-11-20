local deadsickblock = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

deadsickblock.name = "deadsickblock"
deadsickblock.id = NPC_ID
deadsickblock.order = 0.6401

local MODE_NORMAL = 0
local MODE_ANGELIC = 1

deadsickblock.onRedPower = function(n, c, power, dir, hitbox)
  if n.data.power == 0 and n.data.mode == MODE_ANGELIC then
    redstone.setEnergy(n, power)
    redstone.updateRedArea(n)
    redstone.updateRedHitBox(n)
    redstone.passEnergy{source = n, power = 15, hitbox = n.data.redhitbox, area = n.data.redarea, npcList = {deadsickblock.id, redstone.id.reflector}, filter = function(v) return (v.data.mode == MODE_ANGELIC and v.data.power == 0 and c ~= v) or redstone.is.reflector(v.id) end}
  else
    return true
  end
end

deadsickblock.config = npcManager.setNpcSettings({
	id = deadsickblock.id,

  width = 32,
  height = 32,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
  foreground = true,

	frames = 1,
	framespeed = 8,
	framestyle = 0,
  invisible = false,
  mute = false,

  nogravity = true,
	jumphurt = true,
  notcointransformable = true,
	nohurt = true,
	noyoshi = true,
  noblockcollision = true,
  blocknpc = false,
  blocknpctop = false,
  playerblock = false,
  playerblocktop = false,

  hasnosoul = false
})

local EXIST_SICKBLOCK

local function revive(n)
  local data = n.data

  n.friendly = false
  if redstone.onScreenSound(n) then
    SFX.play(14)
  end
  data.isDead = false
  data.pistIgnore = false

  if EXIST_SICKBLOCK then
    n.id = redstone.id.sickblock
  else
    n:kill()
  end
end

function deadsickblock.prime(n)
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

function deadsickblock.onRedLoad()
  EXIST_SICKBLOCK = redstone.id.sickblock
end

function deadsickblock.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.mode == MODE_ANGELIC and data.power == 0 and data.deathTimer == 0 then
    data.deathTimer = (EXIST_SICKBLOCK and redstone.component.sickblock.config.deathtimer + 1) or 5
    data.observ = true
  end

  if data.deathTimer > 0 then
    data.deathTimer = data.deathTimer - 1
    if data.deathTimer == 0 then
      revive(n)
    end
  end

  if data.deathTimer > 0 then
    data.frameY = 2
  else
    data.frameY = data.mode
  end

  redstone.resetPower(n)
end

deadsickblock.onRedDraw =  redstone.drawNPC

redstone.register(deadsickblock)

return deadsickblock
