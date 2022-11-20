local block = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

block.name = "block"
block.id = NPC_ID
block.order = 0.24

block.onRedPower = function(n, c, power, dir, hitbox)
  if redstone.is(c.id, "operator", "alternator", "observer", "spyblock", "repeater", "capacitor", "lever", "button", "reciever", "reaper", "chip") or (redstone.is.torch(c.id) and dir == 1) then
    redstone.setEnergy(n, power)
  else
    return true
  end
end

block.config = npcManager.setNpcSettings({
	id = block.id,

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
  notcointransformable = true,
  noblockcollision = true,
	jumphurt = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true
})

function block.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = (data._settings.mapX or 1) - 1
  data.frameY = data.frameY or 0

  data.redarea = data.redarea or redstone.basicRedArea(n)
  data.redhitbox = data.redhitbox or redstone.basicRedHitBox(n)
end

function block.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 then
    redstone.updateRedArea(n)
    redstone.updateRedHitBox(n)
    redstone.passEnergy{source = n, power = data.power, hitbox = data.redhitbox, area = data.redarea}
  end

  data.observ = data.powerPrev ~= data.power

  redstone.resetPower(n)
end

block.onRedDraw = redstone.drawNPC

redstone.register(block)

return block
