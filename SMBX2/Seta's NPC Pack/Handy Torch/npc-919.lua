local handytorch = {}

-- handytorch.lua v1.1
-- Created by SetaYoshi

-- You can customize these!!
local hotwhitelist = table.map({})  -- << Add hot NPC IDs here

local checkHot = function(n)
	return NPC.config[n.id].isHot or hotwhitelist[n.id]
end

local coldwhitelist = table.map({45, 237})  -- << Add hot NPC IDs here
-- 45: SMB3 Ice Block
-- 237: SMW Yoshi Ice Block
local checkCold = function(n)
	return NPC.config[n.id].isCold or coldwhitelist[n.id]
end

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,

  width = 32,
  height = 32,
	gfxwidth = 32,
	gfxheight = 64,

	frames = 3,
	framespeed = 8,
	score = 0,
	speed = 0,
	playerblocktop = true,
	npcblocktop = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	grabside = false,
	isshoe = false,
	isyoshi = false,
	nohurt = true,
	iscoin = false,
	jumphurt = true,
	spinjumpsafe = true,
	notcointransformable = true,

	flameframes = 2,
	flamesize = 32
})

npcManager.registerHarmTypes(npcID,
	{{HARM_TYPE_TAIL, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_LAVA},
	[HARM_TYPE_TAIL] = 245,
	[HARM_TYPE_PROJECTILE_USED] = 245,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
})

local function iniNPC(n)
	if not n.data.ini then
		n.data.ini = true
		n.data.active = n.data._settings.active
		n.data.eventon = n.data._settings.on
		n.data.eventoff = n.data._settings.off
		n.data.hitbox = Colliders.Box(0, 0, n.width + 8, n.height + config.flamesize + 8)
		n.data.basehitbox = Colliders.Box(0, 0, n.width + 8, n.height + 12)
  end
end

function handytorch.onTickNPC(n)
	local data = n.data
  iniNPC(n)

	data.hitbox.x, data.hitbox.y = n.x - 4, n.y - 4 - config.flamesize
	data.basehitbox.x, data.basehitbox.y = n.x - 4, n.y - 6

	if data.active then -- Check for water NPCs
		for _, npc in ipairs(Colliders.getColliding{a = data.hitbox, b = NPC.ALL, btype = Colliders.NPC, filter = checkCold}) do
			if data.active and data.eventoff ~= "" then
				triggerEvent(data.eventoff)
			end
			data.active = false
			if n.id == 265 then
				npc:kill(1)
			end
		end
		for _, p in ipairs(Player.getIntersecting(data.hitbox.x, data.hitbox.y, data.hitbox.x + data.hitbox.width, data.hitbox.y + data.hitbox.height)) do
		  p:harm()
		end
	else  -- Check for fire NPCs
		for _, npc in ipairs(Colliders.getColliding{a = data.basehitbox, b = NPC.ALL, btype = Colliders.NPC, filter = checkHot}) do
			if not data.active and data.eventon ~= "" then
				triggerEvent(data.eventon)
			end
			data.active = true
			if n.id == 13 or n.id == 246 then
				npc:kill(1)
			end
		end
	end

end

function handytorch.onDrawNPC(n)
		if  config.nospecialanimation then return end

		local frames = config.frames - config.flameframes
		local offset = 0
		local gap = config.flameframes
		if n.data.active then
			offset = frames
			frames = config.flameframes
			gap = 0
		end
		npcutils.restoreAnimation(n)
		n.animationFrame = npcutils.getFrameByFramestyle(n, {
			frames = frames,
			offset = offset,
			gap = gap
		})

end


function handytorch.onInitAPI()
  npcManager.registerEvent(npcID, handytorch, "onTickNPC")
	npcManager.registerEvent(npcID, handytorch, "onDrawNPC")
	registerEvent(npcID, handytorch, "onNPCKill")
end

return handytorch
