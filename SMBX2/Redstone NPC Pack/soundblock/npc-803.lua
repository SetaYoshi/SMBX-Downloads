local soundblock = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

soundblock.name = "soundblock"
soundblock.id = NPC_ID
soundblock.order = 0.52

soundblock.onRedPower = function(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

soundblock.onRedInventory = function(n, c, inv, dir, hitbox)
  n.data.inv = inv
end

soundblock.config = npcManager.setNpcSettings({
	id = soundblock.id,

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

  nogravity = true,
  noblockcollision = true,
  notcointransformable = true,
	jumphurt = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true
})

local function validateSound(n)
  local data = n.data

  if tonumber(data.inv) then
    data.sound = tonumber(data.inv)
  else
    local soundpath = Misc.resolveSoundFile(data.inv)
    if not soundpath then error("Invalid sound path in sound block in section "..n.section.." ["..n.x..", "..n.y.."]\n"..data.inv) end
    data.sound = Audio.SfxOpen(soundpath)
  end

  data.inv = 0
end

function soundblock.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data.frameX or 0
  data.frameY = data.frameY or 0

  data.inv = data._settings.sfx or "29"
  data.invspace = true
  data.powertimer = data.powertimer or 0
  data.pistImmovable = true

  validateSound(n)
end

function soundblock.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.powertimer > 0 then
    data.powertimer = data.powertimer - 1
  end
  if data.inv > 0 then
    validateSound(n)
  end

  if data.power > 0 and data.powerPrev == 0 then
    SFX.play(data.sound)
    data.observ = true
    data.powertimer = 30
  end

  if data.powertimer > 0 then
    data.frameY = 1
  else
    data.frameY = 0
  end

  redstone.resetPower(n)
end

soundblock.onRedDraw = redstone.drawNPC

redstone.register(soundblock)

return soundblock
