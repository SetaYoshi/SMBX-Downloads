local torch = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

torch.name = "torch"
torch.id = NPC_ID

torch.test = function()
  return "isTorch", function(x)
    return (x == torch.id or x == torch.name)
  end
end

torch.onRedPower = function(n, c, power, dir, hitbox)
  if (redstone.isBlock(c.id) and dir == 1) or redstone.isChip(c.id) then
    redstone.setEnergy(n, power)
  else
    return true
  end
end

torch.config = npcManager.setNpcSettings({
	id = torch.id,

  width = 32,
  height = 64,

	gfxwidth = 32,
	gfxheight = 64,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 2,
	framespeed = 8,
	framestyle = 0,
  invisible = false,

  noblockcollision = true,
  notcointransformable = true,
  nogravity = true,
	jumphurt = true,
	nohurt = true,
	noyoshi = true,
})

function torch.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data.frameX or 0
  data.frameY = data.frameY or 0

  data.redarea = data.redarea or redstone.basicRedArea(n)
  data.redhitbox = data.redhitbox or redstone.basicRedHitBox(n)
end

function torch.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power == 0 then
    redstone.updateRedArea(n)
    redstone.updateRedHitBox(n)
    redstone.passEnergy{source = n, power = 15, hitbox = data.redhitbox, area = data.redarea}
  end

  if (data.power == 0 and data.powerPrev ~= 0) or (data.power ~= 0 and data.powerPrev == 0) then
    data.observ = true
  end

  if data.power == 0 then
    data.frameY = 0
  else
    data.frameY = 1
  end

  redstone.resetPower(n)
end

torch.onRedDraw = redstone.drawNPC

redstone.register(torch)

return torch
