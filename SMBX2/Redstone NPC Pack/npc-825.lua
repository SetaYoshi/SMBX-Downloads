local broadcaster = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

broadcaster.name = "broadcaster"
broadcaster.id = NPC_ID

broadcaster.test = function()
  return "isBroadcaster", function(x)
    return (x == broadcaster.id or x == broadcaster.name)
  end
end

broadcaster.onRedPower = function(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

broadcaster.config = npcManager.setNpcSettings({
	id = broadcaster.id,

  width = 32,
  height = 32,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 4,
	framespeed = 8,
	framestyle = 0,
  invisible = false,

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

function broadcaster.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data.frameX or 0
  data.frameY = data.frameY or 0

  data.redarea = data.redarea or redstone.basicRedArea(n)
  data.redhitbox = data.redhitbox or redstone.basicRedHitBox(n)
end

function broadcaster.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 and redstone.npcList[1] then
    redstone.updateRedArea(n)
    redstone.updateRedHitBox(n)
    redstone.passEnergy{source = n, npcList = redstone.npcList, power = data.power, hitbox = data.redhitbox, area = data.redarea}
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

function broadcaster.onRedDraw(n)
  redstone.drawNPC(n)
end

redstone.register(broadcaster)


return broadcaster
