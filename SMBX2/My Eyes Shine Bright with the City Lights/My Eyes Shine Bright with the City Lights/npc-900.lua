local lib = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local rooms = require("rooms")
local sl = require("stoplight")

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,

	gfxwidth = 64,
	gfxheight = 64,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 4,
	framespeed = 8,
	framestyle = 0,

	width = 64,
	height = 64,

  jumphurt = true,
  nohurt = true,
  notcointransformable = true,
	nogravity = true,
	noblockcollision = 0,
	nofireball = 1,
	noiceball = 1,
	noyoshi = 1,
	speed = 0,
  npcblock = false,
})

local blinkerTimer = 0

local colorList = {
	none = Color.black,
	green = Color.green,
	yellow = Color.yellow,
	red = Color.red
}

local frameList = {
	none = 0,
	green = 1,
	yellow = 2,
	red = 3
}

local offsetList = {
	none = 0,
	green = 48,
	yellow = 32,
	red = 16
}

rooms.npcResetProperties[npcID] = {
	despawn = false, respawn = false,

	extraSave = function(n, fields)
		fields.darkness = n.data.darkness
	end,

	extraRestore = function(n, fields)
		n.data.darkness = fields.darkness
	end

}

local function dataCheck(n)
  local data = n.data
  if not data.darkness then
    data.darkness = Darkness.Light(n.x + 0.5*n.width, n.y, 32, 5, colorList[sl.currentColor])
		Darkness.addLight(data.darkness)

	end
end


function lib.onTickNPC(n)
  local data = n.data
	dataCheck(n)
	n.friendly = true

	local currentColor = sl.currentColor

  if sl.intro or sl.yellowTimer > 0 then
		blinkerTimer = blinkerTimer + 1
		if (sl.intro and blinkerTimer % 30 < 15) or (sl.yellowTimer > 0 and sl.yellowTimer % 45 > 25) then
			currentColor = 'none'
		end
	else
		blinkerTimer = 0
	end


  data.darkness.x = n.x + 0.5*n.width
  data.darkness.y = n.y + offsetList[currentColor]
	data.darkness.colour = colorList[currentColor]


	data.darkness.enabled = n.despawnTimer ~= 0
end

function lib.onDrawNPC(n)
	n.animationTimer = -99
	n.animationFrame = frameList[sl.currentColor]
end


function lib.onInitAPI()
  npcManager.registerEvent(npcID, lib, "onTickNPC")
  npcManager.registerEvent(npcID, lib, "onDrawNPC")
end

return lib
