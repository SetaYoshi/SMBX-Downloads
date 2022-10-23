local lib = {}

local blockmanager = require("blockmanager")
local sl = require("stoplight")

local max, lerp = math.max, math.lerp
local insert = table.insert
local imunch = Graphics.loadImage(Misc.resolveFile("munchers.png"))

local blockID = BLOCK_ID
local colorLight = 'none'
local animColor = 'none'
local animTimer = 0
local animStep = 1/60

local animFrame = 0
local animTick = 0
local frames = 8
local framespeed = 4

local vertexCoords, textureCoords = {}, {}

local config = blockmanager.setBlockSettings({
	id = blockID,
	gfxoffsety = 0,
	width = 32,
	height = 32,
})

local colorList = {
	none = Color.white,
	green = Color.white,
	yellow = Color(0.2, 1, 0.2),
	red = Color(0.3, 0.3, 1)
}

function lib.onStopLight(color)
	if color ~= animColor then
		if not ((color == "yellow" and animColor == "red") or (animColor == "yellow" and color == "red")) then -- hacky but it works
			animTimer = 1
		end
		animColor = color
	end
end

function lib.onTick()
	if animTimer > 0 then
		animTimer = animTimer - animStep
		if max(animTimer, 0) == 0 then
			animTimer = 0
			colorLight = animColor
		end

		if animColor == "red" or animColor == "yellow" then
		  framespeed = 4 + (1 - animTimer)*4
		else
			framespeed = 8 - (1 - animTimer)*4
		end
	end

	if framespeed ~= 8 or animFrame ~= 0 then
		animTick = animTick + 1
	end

	if animTick >= framespeed then
		animTick = 0
		animFrame = animFrame + 1
		if animFrame == frames then
			animFrame = 0
		end
	end
end

function lib.onDraw()
	local color = colorList[animColor]
	if animTimer > 0 then
		color = lerp(colorList[animColor], colorList[colorLight], animTimer)
	end

	Graphics.glDraw{texture = imunch, vertexCoords = vertexCoords, textureCoords = textureCoords, priority = -45 - 0.01, sceneCoords = true, color = color}
	vertexCoords, textureCoords = {}, {}
end


local function tableMultiInsert(tbl, tbl2)
  for _, v in ipairs(tbl2) do
    insert(tbl, v)
  end
end

local function left(z1, z2, z3, z4)
	return z1, z2, z3, z4
end

local function up(z1, z2, z3, z4)
	return z2, z4, z1, z3
end

local function right(z1, z2, z3, z4)
	return z2, z1, z4, z3
end

local function down(z1, z2, z3, z4)
	return z3, z1, z4, z2
end

local dirZ = {
	[0] = left,
	[1] = up,
	[2] = right,
	[3] = down
}

function lib.onCollideBlock(v,n)
	if(n.__type == "Player") and sl.currentColor == "green" then
		if n:mem(0x140,FIELD_WORD) == 0 and n:mem(0x13E,FIELD_WORD) == 0 then
			n:harm()
		end
	end
end

function lib.onDrawBlock(n)
	n.animationFrame = -99
	n.animationTimer = -99

	local z1 = vector(n.x, n.y)
	local z2 = z1 + vector(n.width, 0)
	local z3 = z1 + vector(0, n.height)
	local z4 = z1 + vector(n.width, n.height)

  local z1, z2, z3, z4 = dirZ[n.data._settings.dir](z1, z2, z3, z4)

	tableMultiInsert(vertexCoords,{z1.x, z1.y, z2.x, z2.y, z4.x, z4.y, z1.x, z1.y, z3.x, z3.y, z4.x, z4.y})
	tableMultiInsert(textureCoords, {0, animFrame/frames, 0, (animFrame + 1)/frames, 1, (animFrame + 1)/frames, 0, animFrame/frames, 1, animFrame/frames, 1, (animFrame + 1)/frames})
end

function lib.onInitAPI()
	registerEvent(lib, "onTick", "onTick")
	registerEvent(lib, "onDraw", "onDraw")
	registerEvent(lib, "onStopLight", "onStopLight")
	blockmanager.registerEvent(blockID, lib, "onCollideBlock")
  blockmanager.registerEvent(blockID, lib, "onDrawBlock")
end

return lib
