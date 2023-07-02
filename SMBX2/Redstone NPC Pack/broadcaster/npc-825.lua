local broadcaster = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

broadcaster.name = "broadcaster"
broadcaster.id = NPC_ID
broadcaster.order = 0.12

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
  npcblock = true,
  disabledespawn = false,
})

function broadcaster.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data.frameX or 0
  data.frameY = data.frameY or 0

  data.broadcastID = data.broadcastID or redstone.parseNumList(data._settings.broadcastID)

  data.hitbox = Colliders.Box(0, 0, 800, 600)
  data.hitbox.direction = 0
end

function broadcaster.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 then
    data.hitbox.x, data.hitbox.y = n.x - 400, n.y - 300
    redstone.passDirectionEnergy{source = n, npcList = data.broadcastID, power = data.power, hitbox = data.hitbox}
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

broadcaster.onRedDraw = redstone.drawNPC

redstone.register(broadcaster)


return broadcaster
