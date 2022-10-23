local spyblock = {}

-- spyblock.lua v1.0
-- Created by SetaYoshi

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,

  width = 32,
  height = 32,
	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 2,
	framespeed = 8,
	framestyle = 0,

	width = 32,
	height = 32,

  nogravity = true,
	jumphurt = true,
  noblockcollision = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  blocknpctop = true,
  playerblock = true,
  playerblocktop = true,
	notcointransformable = true,

	nospecialanimation = false,
  restingframes = -1
})

if config.restingframes == -1 then
	NPC.config[npcID].restingframes = math.ceil(config.frames*0.5)
end

local iniNPC = function(n)
  if not n.data.ini then
    n.data.ini = true
    n.data.prevState = false
    n.data.isOn = false
    n.data.collider = Colliders.Box(n.x, n.y - 2, n.width, n.height)
    n.data.eventname = n.data._settings.eventname
    n.data.scanplayer = n.data._settings.scanplayer
    n.data.scannpc = n.data._settings.scannpc
  end
end

function spyblock.onTickNPC(n)
  iniNPC(n)
  local data = n.data

  data.isOn = false
  data.collider.x = n.x
  data.collider.y = n.y - 2


  local npcscan = n.ai1
  if npcscan == 0 then npcscan = NPC.ALL end
  if n.data.scannpc then
    for _, npc in ipairs(Colliders.getColliding{a = npcscan, b = data.collider, atype = Colliders.NPC, filter = function(v) return v ~= n end}) do
      data.isOn = true
      break
    end
  end
  if n.data.scanplayer then
    for _, p in ipairs(Player.getIntersecting(n.x, n.y - 2, n.x + n.width, n.y)) do
      data.isOn = true
      break
    end
  end

  if data.isOn and not data.prevState and data.eventname and data.eventname ~= "" then
    triggerEvent(data.eventname)
  end

  data.prevState = data.isOn
end

function spyblock.onDrawNPC(n)
	if not config.nospecialanimation then
		local frames = config.frames - config.restingframes
		local offset = 0
		local gap = config.restingframes
		if n.data.isOn then
			frames = config.restingframes
			offset = config.frames - config.restingframes
			gap = 0
    end
    n.animationFrame = npcutils.getFrameByFramestyle(n, { frames = frames, offset = offset, gap = gap })
	end
end

function spyblock.onInitAPI()
  npcManager.registerEvent(npcID, spyblock, "onTickNPC")
	npcManager.registerEvent(npcID, spyblock, "onDrawNPC")
end

return spyblock
