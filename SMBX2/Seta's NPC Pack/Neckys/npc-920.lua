local nut = {}

-- neckys.lua v1.1
-- Created by SetaYoshi
-- Sprites by FireSeraphim
-- Sounds by DKCPlayer

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,

  width = 20,
  height = 20,
	gfxwidth = 20,
	gfxheight = 20,

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
	jumphurt = true,
	spinjumpsafe = false,
	iscoin = false,
	notcointransformable = true,
	foreground = true,

	poweredframes = 2
})

local harmTypes = {
	[HARM_TYPE_SWORD]=10,
	[HARM_TYPE_PROJECTILE_USED]=10,
	[HARM_TYPE_TAIL]=10,
	[HARM_TYPE_FROMBELOW]=10,
	[HARM_TYPE_HELD]=10,
	[HARM_TYPE_NPC]=10,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
}
npcManager.registerHarmTypes(npcID, table.unmap(harmTypes), harmTypes)

local sfx_bounce = Audio.SfxOpen(Misc.multiResolveFile("nut-bounce.wav", "sound/nut-bounce.wav"))

local default = function(n)
	n.data.v = n.data.v or vector.v2(3*n.direction, 0)
	n.speedX, n.speedY = n.data.v.x, n.data.v.y
end

local function iniNPC(n)
  local data = n.data
  if not data.check then
		data.check = true
		data.speedf = data.speedf or default
		data.serach = Colliders.Box(0, 0, n.width, n.height)
		data.lasty = n.y
	end
end


local blist = Block.SOLID..Block.PLAYER..Block.SEMISOLID
function nut.onTickNPC(n)
	if Defines.levelFreeze or n:mem(0x12A, FIELD_WORD) <= 0 or n:mem(0x12C, FIELD_WORD) ~= 0 or n:mem(0x136, FIELD_BOOL) or n:mem(0x138, FIELD_WORD) > 0 then return end
	local data = n.data
	iniNPC(n)

	data.speedf(n)
	if data.throwned then
		data.serach.x, data.serach.y, data.serach.height = n.x + n.speedX, n.y + n.height, n.speedY
		if n.y > data.lasty and n.speedY > 2 then
			local highest
			local list = Colliders.getColliding{a = data.serach, b = blist, btype = Colliders.BLOCK, filter = function(b)
				if (not b.isHidden and b:mem(0x5A, FIELD_WORD) == 0) then
					if (not highesty or b.y > highesty) and (b.y - n.height) > data.lasty then
						highest = b
					end
				end
			end}
			if highest then
				-- Misc.dialog("A")
				SFX.play(sfx_bounce)
				data.lasty = highest.y + 8
				n.y = highest.y - n.height
				n.speedY = -n.speedY*0.6
				n.speedX = n.speedX*0.9
			end
		end
	end
end


function nut.onInitAPI()
  npcManager.registerEvent(npcID, nut, "onTickNPC")
end

return nut
