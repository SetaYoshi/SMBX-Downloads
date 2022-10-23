local source = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local min, abs, deg, atan2 = math.min, math.abs, math.deg, math.atan2
local insert = table.insert

source.name = "beamsource"
source.id = NPC_ID

source.test = function()
  return "isBeamSource", function(x)
    return (x == source.name or x == source.id)
  end
end

local reset = false
local rays = {}
local npcID = NPC_ID

source.config = npcManager.setNpcSettings({
	id = source.id,

  width = 32,
  height = 32,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

  frames = 1,
  framestyle = 0,
  framespeed = 8,
  invisible = false,

	nogravity = false,
	noblockcollision = false,
	playerblock = true,
	playerblocktop = true,
	npcblock = true,
	npcblocktop = true,
	speed = 1,
	foreground = 0,
	jumphurt = true,
	nohurt = true,
	score = 0,
	noiceball = true,
	nowaterphysics = false,
	foreground = true,
	noyoshi = false,
	harmlessgrab = true,
	harmlessthrown = true,
  grabside = false,
	ignorethrownnpcs = true,

  beamframes = 1,
  beamframespeed = 4,
})
npcManager.registerHarmTypes(npcID, {HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP}, {[HARM_TYPE_JUMP] = 10, [HARM_TYPE_SPINJUMP] = 10})


local ilightning = Graphics.loadImage(Misc.resolveFile("npc-"..source.id.."-1.png"))
local rayFrames = 2
local rayWidth, rayHeight = ilightning.width, ilightning.height/rayFrames

local TYPE_POINTER
local TYPE_DEATHRAY

local function tableMultiInsert(tbl,tbl2)
  for _, v in ipairs(tbl2) do
    insert(tbl, v)
  end
end

local function correctAngle(a, d)
  if d == -1 then
    return (180 - a) % 360
  end
  return a % 360
end

local function getFrameX(a, d)
  a = correctAngle(a, d)
  if a <= 45 or a >= 315 then
    return 2
  elseif a > 45 and a <= 135 then
    return 1
  elseif a > 135 and a <= 225 then
    return 0
  else
    return 3
  end
end

local function getStart(n, a, d)
  a = (0.5*(1 - d)*180 + a*d)% 360
  if a <= 45 or a >= 315 then
    return vector(n.x + n.width, n.y + 0.5*n.height)
  elseif a > 45 and a <= 135 then
    return vector(n.x + 0.5*n.width, n.y)
  elseif a > 135 and a <= 225 then
    return vector(n.x, n.y + 0.5*n.height)
  else
    return vector(n.x + 0.5*n.width, n.y + n.height)
  end
end

local colorlist = {Color.red..0.8, Color(1, 0.42, 0, 0.8), Color(0.5, 0, 1, 0.8), Color.pink..0.8}


function source.prime(n)
  local data = n.data

  data.angleList = redstone.parseNumList(data._settings.angle or "0")
  data.angle = data.angleList[1]
  data.angleCurr = 1

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = getFrameX(data.angle, n.direction)
  data.frameY = data._settings.type

  data.color = data.color or colorlist[data._settings.color + 1]
  n.direction = 1
end

local maxdist = 1000
local createray
function createray(start, r, color, x, blacklist, deathray, found)
	if x <= 0 then return end
  local iscollision, stop, normal, crashcollider
	local max = r*maxdist

	local iscollision, point, normal, crashcollider
	local center = start + r*maxdist*0.5
	local lightcollider = Colliders.Rect(center.x, center.y, 4, maxdist, 90 - deg(atan2(-r.y, r.x)))

  -- This is the part where we organizie all objects that could get in the way
  local npcList = Colliders.getColliding{a = lightcollider, b = NPC.ALL, btype = Colliders.NPC, filter = function(v)
    if v == blacklist then
      return false
    elseif redstone.isDeadsickblock(v.id) then
      return deathray
    elseif v.isHidden or redstone.transparentNPC(v, r) or (redstone.isReflector(v.id) and not v.data.isOn) then
      return false
    end
    return true
  end}
  local blockList = Colliders.getColliding{a = lightcollider, b = Block.ALL, btype = Colliders.BLOCK, filter = function(v)
    if v.isHidden or redstone.transparentBlock(v, r) then
      return false
    end
    return true
  end}

	local currc
  local newDirection
  local collisionlist = {}
  for i = 1, #npcList do
    local npc = npcList[i]
    if (redstone.isReflector(npc.id)) and npc.data.collision and npc.data.collision ~= blacklist then
      insert(collisionlist, npc.data.collision)
    else
      insert(collisionlist, npc)
    end
  end
  for i = 1, #blockList do
    insert(collisionlist, blockList[i])
  end
  for _, p in ipairs(Player.get()) do
    if not redstone.transparentPlayer(p, r) then
      insert(collisionlist, p)
    end
  end


  if collisionlist[1] then
    iscollision, stop, normal, crashcollider = Colliders.raycast(start, max, collisionlist)
  end

  local frame = 0
  if deathray then frame = 1 end
  stop = stop or (start + max)

  insert(rays, {start = start, stop = stop, color = color, frame = frame})

  if iscollision then
    if deathray and type(crashcollider) == "Player" then
      crashcollider:harm()
      -- return
    elseif crashcollider.reflector then
      local newDirection = -2*(r .. normal)*normal + r
      createray(stop, newDirection, color, x - 1, crashcollider, deathray, found)
    elseif redstone.isAbsorber(crashcollider.id) and (color == Color.white or crashcollider.data.color == Color.white or crashcollider.data.color == color) then
      insert(found, crashcollider)
    elseif redstone.isSickblock(crashcollider.id) and deathray then
      insert(found, crashcollider)
    elseif redstone.isDeadsickblock(crashcollider.id) and deathray then
      insert(found, crashcollider)
      createray(stop, r, color, x - 1, crashcollider, deathray, found)
    end
  end
end


function source.onRedTick(n)
	local data = n.data
  data.observ = false

  if reset then
		reset = false
		rays = {}
	end

  data.frameX = getFrameX(data.angle, n.direction)

	if n.collidesBlockBottom then
		n.speedX = n.speedX*0.5
	end

  if data.power > 0 and data.powerPrev == 0 then
    data.angleCurr = data.angleCurr + 1
    if data.angleCurr > #data.angleList then
      data.observ = true
      data.angleCurr = 1
    end
    data.angle = data.angleList[data.angleCurr]
  end

	local v = getStart(n, data.angle, n.direction)
	local r = vector(1, 0):rotate(-correctAngle(data.angle, n.direction))
  local found = {}
	createray(v, r, data.color, 80, nil, data.frameY == 1, found)
  for k, v in ipairs(found) do
    redstone.energyFilter(v, n, 15, -1, n)
  end

  redstone.resetPower(n)
end

source.onRedDraw = redstone.drawNPC

local function drawRay(ray)
  local p = -45
  if source.config.foreground then p = -15 end

  local start = ray.start
  local stop = ray.stop
  local frame = ray.frame
	local color = ray.color

  local lenght = (start - stop).length
  local vertexCoords,textureCoords = {}, {}
  local direction = (stop - start):normalize()
  local lineWidth = direction:rotate(90)*rayHeight/rayFrames

  local texX, texY, texH = (1 - (1.2*lunatime.tick() % rayWidth)/rayWidth),  frame/rayFrames, (frame + 1)/rayFrames
  local segment = start

  local j = 0
  while j < lenght do
    local segmentLength = min(lenght - j, (1 - texX)*rayWidth)
    local texW = segmentLength/rayWidth + texX

    local y = direction*segmentLength
    local z1, z2, z3, z4 = segment + lineWidth, segment - lineWidth, segment + y + lineWidth, segment + y - lineWidth

    tableMultiInsert(vertexCoords, {z1.x, z1.y, z2.x, z2.y, z4.x, z4.y, z1.x, z1.y, z3.x, z3.y, z4.x, z4.y})
    tableMultiInsert(textureCoords, {texX, texY, texX, texH, texW, texH, texX, texY, texW, texY, texW, texH})

    texX = 0
    segment = segment + y
    j = j + segmentLength
  end

  Graphics.glDraw{texture = ilightning, vertexCoords = vertexCoords, textureCoords = textureCoords, priority = p - 0.01, sceneCoords = true, color = color}
end

function source.onDraw()
  if source.config.invisible then return end

  for i = #rays, 1, -1 do
    drawRay(rays[i])
  end

	reset = true
end

function source.onInitAPI()
	registerEvent(source, "onDraw", "onDraw")
end

redstone.register(source)

return source
