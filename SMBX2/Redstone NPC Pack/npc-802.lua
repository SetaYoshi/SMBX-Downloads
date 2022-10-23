local observer = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local floor = math.floor

observer.name = "observer"
observer.id = NPC_ID

observer.test = function()
  return "isObserver", function(x)
    return (x == observer.id or x == observer.name)
  end
end

observer.onRedPower = function()
  return true
end

observer.config = npcManager.setNpcSettings({
	id = observer.id,

  width = 32,
  height = 32,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 1,
	framespeed = 8,
	framestyle = 0,
  invisible = false,

	width = 32,
	height = 32,

  nogravity = true,
	jumphurt = true,
  noblockcollision = true,
  notcointransformable = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true,

  poweronmove = true  -- When the observer gets moved by a piston, activate the observer
})

local function scanBox(n, dir)
  if dir == 0 or dir == 2 then
    return Colliders.Box(0, 0, n.width*0.5, n.height*0.9)
  else
    return Colliders.Box(0, 0, n.width*0.9, n.height*0.5)
  end
end

local function updateScanBox(n, dir)
  if dir == 0 then
    n.data.observbox.x, n.data.observbox.y = n.x - n.width*0.5, n.y + n.height*0.05
  elseif dir == 1 then
    n.data.observbox.x, n.data.observbox.y = n.x + n.width*0.05, n.y - n.height*0.5
  elseif dir == 2 then
    n.data.observbox.x, n.data.observbox.y = n.x + n.width, n.y + n.height*0.05
  else
    n.data.observbox.x, n.data.observbox.y = n.x + n.width*0.05, n.y + n.height
  end
end

function observer.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.dir or 0
  data.frameY = data.frameY or 0

  data.powerTimer = data.powerTimer or 0
  data.isOn = data.isOn or false
  data.observNotice = data.observNotice or false
  data.prevX = data.prevX or floor(n.x)
  data.prevY = data.prevY or floor(n.y)

  data.observbox = scanBox(n, data.frameX)
  data.redhitbox = redstone.basicDirectionalRedHitBox(n, (data.frameX + 2)%4)
end

function observer.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.isOn then
    redstone.updateDirectionalRedHitBox(n, (data.frameX + 2)%4)
    redstone.passDirectionEnergy{source = n, power = data.power, hitbox = data.redhitbox}

    data.powerTimer = data.powerTimer + 1
    if data.powerTimer == 4 then
      data.observ = true
    elseif data.powerTimer >= 5 and not data.observNotice then
      data.powerTimer = 0
      data.isOn = false
    end
  end

  if data.isOn  then
    data.frameY = 1
  else
    data.frameY = 0
  end

  data.observNotice = false
end

local filter = function(n) return n.data.observ end

function observer.onRedTickObserver(n)
  local data = n.data

  updateScanBox(n, data.frameX)
  for _, v in ipairs(Colliders.getColliding{a = data.observbox, b = NPC.ALL, btype = Colliders.NPC, filter = filter}) do
    data.isOn = true
    data.power = v.data.observpower
    data.observNotice = true
    break
  end

  if observer.config.poweronmove then
    n.x = floor(n.x)
    n.y = floor(n.y)
    if data.prevX ~= n.x or data.prevY ~= n.y then
      data.isOn = true
      data.power = 15
      data.observNotice = true
    end
    data.prevX = n.x
    data.prevY = n.y
  end
end

function observer.onRedDraw(n)
  redstone.drawNPC(n)
end

redstone.register(observer)

return observer
