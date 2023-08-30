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

local function luafy(msg)
  return "return function(object) local npc = object if npc.isHidden then return false end "..msg.." end"
end

function broadcaster.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data.frameX or 0
  data.frameY = data.frameY or 0

  data.broadcastID = data.broadcastID or redstone.parseList(data._settings.broadcastID)
  data.filter = redstone.luaParse("BROADCASTER", n, luafy(data._settings.filter or "return true"))

  data.hitbox = Colliders.Box(0, 0, 1000, 1200)
end

function broadcaster.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 and #data.broadcastID > 0 then
    data.hitbox.x, data.hitbox.y = n.x - 500, n.y - 600
    redstone.passDirectionEnergy{source = n, npcList = data.broadcastID, power = data.power, hitbox = data.hitbox, filter = data.filter}
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
