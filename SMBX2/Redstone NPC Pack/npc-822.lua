local reciever = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

reciever.name = "reciever"
reciever.id = NPC_ID

reciever.test = function()
  return "isReciever", function(x)
    return (x == reciever.id or x == reciever.name)
  end
end

reciever.onRedPower = function(n, c, power, dir, hitbox)
  if redstone.isTransmitter(c.id) or redstone.isChip(c.id) then
    redstone.setEnergy(n, power)
  end
end

reciever.config = npcManager.setNpcSettings({
	id = reciever.id,

  width = 32,
  height = 32,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 8,
	framespeed = 8,
	framestyle = 0,
  invisible = false,

  nogravity = true,
	jumphurt = true,
  noblockcollision = true,
  notcointransformable = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true
})

function reciever.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data.frameX or 0
  data.frameY = data.frameY or 0

  data.redarea = data.redarea or redstone.basicRedArea(n)
  data.redhitbox = data.redhitbox or redstone.basicRedHitBox(n)
end

function reciever.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power ~= 0 then
    redstone.updateRedArea(n)
    redstone.updateRedHitBox(n)
    redstone.passEnergy{source = n, power = data.power, hitbox = data.redhitbox, area = data.redarea}
  end

  if data.power == 0 then
    data.frameY = 0
  else
    data.frameY = 1
  end

  if data.power ~= data.powerPrev then
    data.observ = true
  end

  redstone.resetPower(n)
end

reciever.onRedDraw = redstone.drawNPC

redstone.register(reciever)

return reciever
