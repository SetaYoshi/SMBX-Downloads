local redblock = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local floor, ceil = math.floor, math.ceil

redblock.name = "redblock"
redblock.id = NPC_ID

redblock.test = function()
  return "isRedblock", function(x)
    return (x == redblock.id or x == redblock.name)
  end
end

local pswitch = false
local TYPE_NORMAL = 0
local TYPE_CRACKED = 1
local TYPE_TIMED = 2
local TYPE_PBLOCK = 3
local TYPE_CAMERA = 4

redblock.onRedPower = function(n, c, p, d, hitbox)
  local data = n.data

  if data.frameX == TYPE_CRACKED then
    redstone.setEnergy(n, p)
  elseif data.origin == TYPE_TIMED then
    data.countdown = data.delay
    redstone.setEnergy(n, p)
  else
    return true
  end
end

redblock.config = npcManager.setNpcSettings({
	id = redblock.id,

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

  grabtop = true,
  notcointransformable = true,
  grabside = true,
  nogravity = false,
	jumphurt = false,
	nohurt = true,
  noiceball = true,
	noyoshi = false,
  harmlessgrab = true,
  npcblocktop = false,
  blocknpc = true,
  blocknpctop = true,
  playerblock = true,
  playerblocktop = true,

  grabfix = true -- custom fix for the "death when thrown inside a wall"
})
npcManager.registerHarmTypes(redblock.id, {HARM_TYPE_LAVA}, {[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}})


function redblock.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.type or 0
  data.frameY = data.frameY or 0

  data.delay = (data._settings.delay or 6)*10
  data.countdown = data.countdown or 0
  data.origin = data.origin or data.frameX

  data.redarea = data.redarea or redstone.basicRedArea(n)
  data.redhitbox = data.redhitbox or redstone.basicRedHitBox(n)
end

local AIList = {}

AIList[TYPE_NORMAL] = function(n) end

AIList[TYPE_CRACKED] = function(n)
  local data = n.data

  if data.frameX == TYPE_CRACKED and data.power > 0 then
    data.frameX = TYPE_NORMAL
    data.observ = true
  end
end

AIList[TYPE_TIMED] = function(n)
  local data = n.data

  if data.frameX == TYPE_NORMAL then
    data.countdown = data.countdown - 1
    if data.countdown <= 0 then
      data.frameX = TYPE_TIMED
      data.observ = true
    end
  elseif data.frameX == TYPE_TIMED then
    if data.countdown == data.delay then
      data.frameX = TYPE_NORMAL
      data.observ = true
    end
  end
end

AIList[TYPE_PBLOCK] = function(n)
  local data = n.data

  if not pswitch and data.frameX == TYPE_NORMAL then
    data.frameX = TYPE_PBLOCK
    data.observ = true
  elseif pswitch and data.frameX == TYPE_PBLOCK then
    data.frameX = TYPE_NORMAL
    data.observ = true
  end
end

AIList[TYPE_CAMERA] = function(n)
  local data = n.data

  local incamera = redstone.onScreen(n)
  if not incamera and data.frameX == TYPE_NORMAL then
    data.frameX = TYPE_CAMERA
    data.observ = true
  elseif incamera and data.frameX == TYPE_CAMERA then
    data.frameX = TYPE_NORMAL
    data.observ = true
  end
end

function redblock.onRedTick(n)
  local data = n.data
  data.observ = false

  redstone.applyFriction(n)
  AIList[data.origin](n)

  if data.frameX == TYPE_NORMAL then
    redstone.updateRedArea(n)
    redstone.updateRedHitBox(n)
    redstone.passEnergy{source = n, power = 15, hitbox = data.redhitbox, area = data.redarea}
  end

  redstone.resetPower(n)
end

function redblock.onRedDraw(n)
  local data = n.data
  redstone.drawNPC(n)

  if not redblock.config.invisible and data.origin == TYPE_TIMED and data.frameX == TYPE_NORMAL then
    local color = Color.red
    if data.powerPrev == 0 then color = Color.green end
    local x = n.x + floor(0.15*n.width)
    local w = floor(n.width*0.7)
    Graphics.drawBox{x = x, y = n.y - 10, width = w, height = 4, color = Color.gray, sceneCoords = true}
    Graphics.drawBox{x = x, y = n.y - 10, width = ceil(data.countdown/data.delay*w), height = 4, color = color, sceneCoords = true}
  end
end

function redblock.onEvent(eventName)
  if eventName == "P Switch - Start" then
    pswitch = true
  elseif eventName == "P Switch - End" then
    pswitch = false
  end
end

function redblock.onInitAPI()
	registerEvent(redblock, "onEvent", "onEvent")
end

redstone.register(redblock)

return redblock
