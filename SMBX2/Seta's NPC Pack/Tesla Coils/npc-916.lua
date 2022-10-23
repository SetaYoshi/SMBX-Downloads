local teslacoil = {}

-- teslacoil.lua v1.0
-- Created by SetaYoshi
-- Sprite by Wonolf

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local teslacoil = require("AI_teslacoil")

local npcID = NPC_ID
teslacoil.ID.shock = npcID

local config = npcManager.setNpcSettings({
	id = npcID,

  width = 32,
  height = 64,
	gfxwidth = 32,
	gfxheight = 64,

	frames = 4,
	framespeed = 8,
	score = 0,
	speed = 1,
	-- playerblock = false,
	-- npcblock = false,
	nogravity = true,
	noblockcollision = true,
	-- nofireball = false,
	-- noiceball = false,
	-- noyoshi = true,
	-- grabside = false,
	-- isshoe = false,
	-- isyoshi = false,
	-- nohurt = false,
	-- jumphurt = true,
	-- spinjumpsafe = true,
	iscoin = false,
	notcointransformable = true,
	foreground = true,

	poweredframes = 2
})

local harmTypes = {
	[HARM_TYPE_SWORD]=10,
	[HARM_TYPE_PROJECTILE_USED]=10,
	[HARM_TYPE_SPINJUMP]=10,
	[HARM_TYPE_TAIL]=10,
	[HARM_TYPE_JUMP]=10,
	[HARM_TYPE_FROMBELOW]=10,
	[HARM_TYPE_HELD]=10,
	[HARM_TYPE_NPC]=10,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
}
npcManager.registerHarmTypes(npcID, table.unmap(harmTypes), harmTypes)


local iniNPC = function(n)
  if not n.data.ini then
    n.data.ini = true
		n.data.electric = false
		if n.direction == 0 then
			n.direction = 1
		end
		n.data.dir = n.direction
  end
end

local function findBody(n, d)
	for _, body in ipairs(Colliders.getColliding{a = n, b = teslacoil.ID.climbable, atype = Colliders.NPC, btype = Colliders.NPC, filter = function(v) return true end}) do
		n.data.electric = body.data.electric
		if body.id == 910 or body.id == 906 or body.id == 908 or body.id == 912 or body.id == 914 then
			if d == -1 then	d = 1
			else d = 3
			end
		else
			if d == -1 then	d = 2
			else d = 4
			end
		end
		break
	end
  local x, y, w, h
  if d == 1 then
		x, y, w, h = n.x, n.y + n.height, n.width, 8
  elseif d == 2 then
		x, y, w, h = n.x - 8, n.y, 8, n.height
  elseif d == 3 then
		x, y, w, h = n.x, n.y - 8, n.width, 8
  else
		x, y, w, h = n.x + n.width, n.y, 8, n.height
  end
  for _, body in ipairs(Colliders.getColliding{a = Colliders.Box(x, y, w, h), b = teslacoil.ID.climbable, atype = Colliders.NPC, btype = Colliders.NPC, filter = function(v) return true end}) do
    return body
  end
end

function teslacoil.onTickNPC(n)
	if Defines.levelFreeze or n:mem(0x12A, FIELD_WORD) <= 0 or n:mem(0x12C, FIELD_WORD) ~= 0 or n:mem(0x136, FIELD_BOOL) or n:mem(0x138, FIELD_WORD) > 0 then return end
  iniNPC(n)
  local data = n.data

  local body = findBody(n, data.dir)

	if data.electric then
		n.speedX, n.speedY = 0, 0
	else
		if body then
			local off = 0
			if body.id == 907 or body.id == 909 or body.id == 911 or body.id == 913 or body.id == 915 then off = 2 end
			local v = vector.v2((n.x + 0.5*n.width) - (body.x + 0.5*body.width), (n.y + 0.5*n.height + off) - (body.y + 0.5*body.height))
			local w = config.speed*(v:normalize())
			n.speedX, n.speedY = -w.x, -w.y
		else
			data.dir = -data.dir
		end
	end

end

function teslacoil.onDrawNPC(n)
	local config = NPC.config[n.id]
	if not config.nospecialanimation then
		local frames = config.frames - config.poweredframes
		local offset = 0
		local gap = config.collectedframes
		if n.data.electric then
			frames = config.poweredframes
			offset = config.frames - config.poweredframes
			gap = 0
		end
		n.animationFrame = npcutils.getFrameByFramestyle(n, { frames = frames, offset = offset, gap = gap })
	end
end


function teslacoil.onInitAPI()
  npcManager.registerEvent(npcID, teslacoil, "onTickNPC")
	npcManager.registerEvent(npcID, teslacoil, "onDrawNPC")
end

return teslacoil
