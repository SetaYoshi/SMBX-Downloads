local block = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

block.name = "block"
block.id = NPC_ID

block.test = function()
  return "isBlock", function(x)
    return (x == block.id or x == block.name)
  end
end

block.onRedPower = function(n, c, power, dir, hitbox)
  if redstone.isOperator(c.id) or redstone.isAlternator(c.id) or redstone.isObserver(c.id) or redstone.isSpyblock(c.id) or redstone.isRepeater(c.id) or redstone.isCapacitor(c.id) or redstone.isLever(c.id) or redstone.isButton(c.id) or redstone.isReciever(c.id) or redstone.isReaper(c.id) or redstone.isChip(c.id) or (redstone.isTorch(c.id) and dir == 1) then
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
