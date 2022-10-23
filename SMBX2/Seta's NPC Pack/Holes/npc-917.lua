local wormhole = {}

-- blackhole.lua v1.4
-- Created by SetaYoshi
-- Sprite by Wonolf
-- Sound: https://www.soundsnap.com/user-name/blastwave_fx
--        https://www.youtube.com/watch?v=LnMhJU6RsYU

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local lineguide = require("lineguide")
local holes = require("AI_holes")

local npcID = NPC_ID
lineguide.registerNpcs(npcID)

local config = npcManager.setNpcSettings({
	id = npcID,

  width = 48,
  height = 48,
	gfxwidth = 48,
	gfxheight = 48,

	frames = 1,
	framespeed = 8,
	score = 0,
	speed = 0,
	playerblock = false,
	npcblock = false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	grabside = false,
	isshoe = false,
	isyoshi = false,
	nohurt = true,
	iscoin = false,
	jumphurt = true,
	spinjumpsafe = false,
	notcointransformable = true,
	ignorethrownnpcs  = true,

	  rotationspeed = 8,
		radius = -1,
		forceradius = -1,
		laserspeed = 15,

		transition = true,
	  sectiontransition = true,

		disableribbon = false,
		warptype = WARPPTYPE_OFFSET,
		pushforce = 1
})

if config.radius == -1 then
	NPC.config[npcID].radius = math.ceil(config.width*0.5)
end
if config.forceradius == -1 then
	config.forceradius = math.ceil(config.width*2)
end

--
-- local iniNPC = function(n)
--   if not n.data.ini then
--     n.data.ini = true
-- 		n.data.sprite = Sprite.box{x = n.x, y = n.y, width = npcutils.gfxwidth(n), height = npcutils.gfxheight(n), texture = Graphics.sprites.npc[npcID].img, rotation = 0, align = Sprite.align.CENTRE, frames = npcutils.getTotalFramesByFramestyle(n)}
--     n.data.collider = Colliders.Circle(n.x + 0.5*n.width, n.y + 0.5*n.height, config.radius)
-- 		n.data.scanNPC = n.data._settings.scanNPC
--     n.data.scanPlayer = n.data._settings.scanPlayer
-- 		n.data.scanBlock = n.data._settings.scanBlock
--   end
-- end
--
--
--
-- local function cx(obj)
-- 	return obj.x + 0.5*obj.width
-- end
-- local function cy(obj)
-- 	return obj.y + 0.5*obj.height
-- end
--
-- local function poofeffect(obj)
-- 	local e = Animation.spawn(10, cx(obj), cy(obj))
-- 	e.x = e.x - 0.5*e.width
-- 	e.y = e.y - 0.5*e.height
-- end
--
-- local function scan(n, obj)
-- 	local data = n.data
-- 	if Colliders.collide(data.collider, obj) and obj ~= n and not obj.data.disablewormhole and not (type(obj) == "NPC" and (config.blacklistNPC[obj.id] or obj:mem(0x12C, FIELD_WORD) ~= 0)) and not (obj.data and obj.data.inwormhole) and not (type(obj) == "Player" and obj.deathTimer > 0) then
--     local v = vector.v2(cx(n) - cx(obj), cy(n) - cy(obj))
-- 		local m = math.sqrt(v.x^2 + v.y^2)
-- 		v =  math.min(0.1, 1/m)*v
-- 		obj.speedX, obj.speedY = obj.speedX + v.x, obj.speedY + v.y
-- 		if type(obj) == "Block" then
-- 			obj.x, obj.y = obj.x + 10*v.x, obj.y + 10*v.y
-- 		end
-- 		if m <= 16 then
-- 			poofeffect(obj)
-- 			if type(obj) == "Block" then
-- 				obj.x = 0
-- 				obj:delete()
-- 			else
-- 				obj:kill()
-- 			end
-- 		end
-- 	end
-- end
--
-- function wormhole.onTickNPC(n)
--   iniNPC(n)
--   local data = n.data
--
--   -- Adjust sprite and collision
-- 	data.sprite:rotate(config.rotationspeed*n.direction)
--   data.collider.x = n.x + 0.5*n.width
--   data.collider.y = n.y + 0.5*n.height
--
-- 	-- Search for players that should be warped
-- 	if n.data.scanPlayer then
-- 		for _, p in ipairs(Player.get()) do
-- 			scan(n, p)
-- 		end
-- 	end
--
-- 	-- Search for NPCs that should be warped
-- 	if n.data.scanNPC then
-- 		for _, npc in ipairs(NPC.getIntersecting(n.x - 64, n.y - 64, n.x + n.width + 128, n.y + n.height + 128)) do
-- 			scan(n, npc)
-- 		end
-- 	end
--
-- 	-- Search for Blocks that should be warped
-- 	if n.data.scanBlock then
-- 		for _, b in ipairs(Block.getIntersecting(n.x - 64, n.y - 64, n.x + n.width + 128, n.y + n.height + 128)) do
-- 			scan(n, b)
-- 		end
-- 	end
-- end
--
-- function wormhole.onDrawNPC(n)
-- 	local p = -45
-- 	if config.foreground then	p = -15	end
-- 	n.data.sprite.x = n.x + n.width*0.5 + config.gfxoffsetx
-- 	n.data.sprite.y = n.y + n.height*0.5 + config.gfxoffsety
-- 	n.data.sprite:draw{priority = p - 0.1, sceneCoords = true, frame = n.animationFrame + 1}
-- 	npcutils.hideNPC(n)
-- end

wormhole.onTickNPC = holes.onTickNPC
wormhole.onDrawNPC = holes.onDrawNPC
holes.register(npcID)

function wormhole.onInitAPI()
  npcManager.registerEvent(npcID, wormhole, "onTickNPC")
	npcManager.registerEvent(npcID, wormhole, "onDrawNPC")
end

return wormhole
