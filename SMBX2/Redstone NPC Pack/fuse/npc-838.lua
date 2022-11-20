local fuse = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

fuse.name = "fuse"
fuse.id = NPC_ID
fuse.order = 0.365

fuse.onRedPower = function(n, c, power, dir, hitbox)
  local data = n.data

  if data.broken then
    return true
  end

  local validDir1, validDir2
  if data.frameX == 0 then
    validDir1, validDir2 = 0, 2
  else
    validDir1, validDir2 = 1, 3
  end

  if dir == -1 or dir == validDir1 or dir == validDir2 then
    redstone.setEnergy(n, power)
    if dir == validDir1 then
      data.facing = -1
    else
      data.facing = 1
    end
  elseif redstone.is.repeater(c.id) then
    redstone.setEnergy(n, 15)
    return true
  end
end

fuse.config = npcManager.setNpcSettings({
	id = fuse.id,

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
  notcointransformable = true,
	jumphurt = true,
  noblockcollision = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true
})

local sfxpop = Audio.SfxOpen(Misc.resolveFile("fuse-pop.ogg"))


function fuse.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.dir or 0
  data.frameY = data.frameY or 0

  data.limit = data._settings.limit or 8
  data.facing = data.facing or -1
  data.broken = data.broken or false

  data.redhitbox = data.redhitbox or redstone.basicRedHitBox(n)
end

function fuse.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power >= data.limit and not data.broken then
    data.broken = true
    data.observ = true
    redstone.spawnEffect(10, n)
    if redstone.onScreenSound(n) then
      SFX.play(sfxpop)
    end
  end

  if data.broken then
    data.frameY = 2
  elseif data.power > 0 then
    data.frameY = 1
      redstone.updateRedHitBox(n)
    redstone.passDirectionEnergy{source = n, power = data.power, hitbox = data.redhitbox[data.frameX + data.facing + 2]}
  else
    data.frameY = 0
  end

  if (data.power == 0 and data.powerPrev ~= 0) or (data.power ~= 0 and data.powerPrev == 0) then
    data.observ = true
  end

  redstone.resetPower(n)
end

fuse.onRedDraw = redstone.drawNPC

redstone.register(fuse)

return fuse
