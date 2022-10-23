local tesla = {}

-- teslacoil.lua v1.0
-- Created by SetaYoshi
-- Sprite by Wonolf

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local teslacoil = require("AI_teslacoil")

local npcID = NPC_ID
teslacoil.ID.elecBall = npcID

local config = npcManager.setNpcSettings({
	id = npcID,

  width = 32,
  height = 32,
	gfxwidth = 32,
	gfxheight = 32,

	frames = 4,
	framespeed = 8,
	score = 0,
	speed = 1,
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
	nohurt = false,
	iscoin = false,
	jumphurt = true,
	spinjumpsafe = true,
	notcointransformable = true
})

local iniNPC = function(n)
  if not n.data.ini then
    n.data.ini = true
		n.data.angle = n.data._settings.angle
		n.data.speed = n.data.speed or n.data._settings.speed
		n.data.destname = n.data._settings.destname
  end
end

local function findNearest(n, x, y, name)
  name = name or ""
	local closest
	local closestdist = -1
	for _, head in ipairs(NPC.get(teslacoil.ID.head)) do
		local newdist = (x - head.x)^2 + (y - head.y)^2
    if n ~= head and (newdist < closestdist or closestdist == -1) and head.data.name == name then
      closestdist = newdist
			closest = head
		end
	end
	return closest
end

function tesla.onTickNPC(n)
	if Defines.levelFreeze or n:mem(0x12A, FIELD_WORD) <= 0 or n:mem(0x12C, FIELD_WORD) ~= 0 or n:mem(0x136, FIELD_BOOL) or n:mem(0x138, FIELD_WORD) > 0 then return end
	iniNPC(n)
	local data = n.data

	-- n:mem(0x128,	FIELD_BOOL, false)
	-- n:mem(0x12A, FIELD_WORD, 180)

	if data.destname ~= "" then
		data.dest = findNearest(n, n.x + 0.5*n.width, n.y + 0.5*n.height, data.destname)
		data.destname = ""
	end

	if data.dest and data.dest.isValid then
		local dest = data.dest
		local v = vector.v2((dest.x + 0.5*dest.width) - (n.x + 0.5*n.width), (dest.y + 0.5*n.width) - (n.y + 0.5*n.height))
		data.vec = v
		v = data.speed*(v:normalize())
		n.speedX, n.speedY = v.x, v.y
	end

	for _, npc in ipairs(Colliders.getColliding{a = n, b = teslacoil.ID.interactions, btype = Colliders.NPC, filter = function(v) return true end}) do
		teslacoil.interaction(npc)
	end

end

function tesla.onInitAPI()
  npcManager.registerEvent(npcID, tesla, "onTickNPC")
end

return tesla
