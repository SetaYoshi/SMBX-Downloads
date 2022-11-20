local flame = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local deg, atan2 = math.deg, math.atan2
local append = table.append

flame.name = "flame"
flame.id = NPC_ID
flame.order = 0.62

flame.onRedPower = function(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

flame.config = npcManager.setNpcSettings({
  id = flame.id,

  width = 32,
  height = 32,

  gfxheight = 32,
  gfxwidth = 32,
  gfxoffsetx = 0,
  gfxoffsety = 0,

  frames = 4,
  framespeed = 2,
  framestyle = 0,
  invisible = false,

  nogravity = 1,
  jumphurt = 1,
  nofireball = 1,
  noiceball = 0,
  grabside = 0,
  grabtop = 0,
  noyoshi = 1,
  playerblock = 0,
  spinjumpsafe = true,
  notcointransformable = true,
  nogravity = true,
  noblockcollision = true,
  ishot = true,

  firespeed = 4,  -- The speed of the fireball in pixel/frame
  bouncetype = 1  -- The different flame's AIs when colliding with a wall: 0: Bounce, 1: Destroy, 2: Pass-through
})

-- A table of block IDs and the "melting" behavior
local iceBlock = {}

-- Frozen coin block turns into a SMB3 coin
iceBlock[620] = function(b, n)
  NPC.spawn(10, b.x, b.y, n.section)
  redstone.spawnEffect(10, b)
  b:remove()
end

-- Frozen muncher block turns into a muncher
iceBlock[621] = function(b, n)
  b.id = 109
  redstone.spawnEffect(10, b)
end

-- Ice block melts
iceBlock[633] = function(b, n)
  b:remove()
  redstone.spawnEffect(10, b)
end

-- Large ice blocks takes two flame hits to melt
iceBlock[634] = function(b, n)
  if b.data.flame_metling then
    b:remove()
    redstone.spawnEffect(10, b)
  else
    b.data.flame_metling = true
  end
end

-- List of ice blocks to scan
local iceBlock_MAP = unmap(iceBlock)
flame.iceBlock, flame.iceBlock_MAP = iceBlock, iceBlock_MAP


local TYPE_BOUNCE = 0
local TYPE_HIT = 1
local TYPE_NOCOLL = 2

function flame.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data.frameX or 0
  data.frameY = data.frameY or 0

  data.angle = data.angle or data._settings.angle or 0
  data.vector = vector.v2(flame.config.firespeed, 0):rotate(-data.angle)

  data.disabledespawn = true
  data.redhitbox = Colliders.Circle(0, 0, 0.5*n.width + 6)
end

-- Determines if a block is bouncable
local blockfilter = function(n, d)
  return function(v)
    if v.isHidden or Block.NONSOLID_MAP[v.id] then
      return false
    elseif Block.SEMISOLID_MAP[v.id] then
      local m = vector(n.x + 0.5*n.width, n.y + 0.5*n.height)
      return d.y > 0 and Colliders.raycast(m, d, Colliders.Box(v.x, v.y, v.width, 2))
    end
    return true
  end
end

-- Determines if an NPC is bouncable
local npcfilter = function(n, d)
  return function(v)
    local c = NPC.config[v.id]
    if n.data.immuneparent and v == n.data.parent then
      return false
    elseif c.blocknpc or c.playerblock or c.npcblock then
      return true
    elseif c.npcblocktop or c.playerblocktop then
      local m = vector(n.x + 0.5*n.width, n.y + 0.5*n.height)
      return d.y > 0 and Colliders.raycast(m, 10*d:normalize(), Colliders.Box(v.x, v.y, v.width, 2))
    end
  end
end

-- Does the actual bounce calculation
local function doBounce(n)
  local cx, cy = n.x + 0.5*n.width, n.y + 0.5*n.height
  local data = n.data

  local iscollision, point, normal, crashcollider
  local blockList = Colliders.getColliding{a = data.redhitbox, b = Block.ALL, btype = Colliders.BLOCK, filter = blockfilter(n, data.vector)}
  local npcList = Colliders.getColliding{a = data.redhitbox, b = NPC.ALL, btype = Colliders.NPC, filter = npcfilter(n, data.vector)}

  local collList = append(blockList, npcList)
  if collList[1] then
    local startpoint = vector.v2(cx, cy)
    local rayLen = vector.v2(0.5*n.width + 6, 0):rotate(-data.angle)
    iscollision, point, normal, crashcollider = Colliders.raycast(startpoint, rayLen, collList)
  end

  if iscollision then
    if flame.config.bouncetype == TYPE_BOUNCE then
      data.vector = -2*(data.vector .. normal)*normal + data.vector
      data.angle = deg(atan2(-data.vector.y, data.vector.x))
    elseif flame.config.bouncetype == TYPE_HIT then
      local e = Effect.spawn(10, n.x + 0.5*n.width, n.y + 0.5*n.height)
      e.x, e.y = e.x - e.width*0.5, e.y - e.height*0.5
      n:kill()
    end
  end
end


function flame.onRedTick(n)
  local data = n.data

  -- Get center of NPC
  local cx, cy = n.x + 0.5*n.width, n.y + 0.5*n.height
  if data.angle > 360 or data.angle < 0 then
    data.angle = data.angle%360
  end

  -- Create vector speed and update collider box
  data.vector = vector(flame.config.firespeed, 0):rotate(-data.angle)
  data.redhitbox.x, data.redhitbox.y = cx, cy

  -- Melt any ice blocks that are in the way
  local iceList = Colliders.getColliding{a = data.redhitbox, b = iceBlock_MAP, btype = Colliders.BLOCK, filter = redstone.nothidden}
  if iceList[1] then
    local b = iceList[1] -- Get the first block in the list
    iceBlock[b.id](b, n) -- Do the given action of the block
    n:kill()
  end

  -- If set to bounce or hit, then do the nessesary calculations
  if flame.config.bouncetype ~= TYPE_NOCOLL then
    -- Prevent the flame from colliding with the flamethrower it spawned on
    if data.immuneparent and data.parent.isValid and not Colliders.collide(n, data.parent) then
      data.immuneparent = false
    end

    doBounce(n)
  end

  -- Apply speed
  n.speedX = data.vector.x
  n.speedY = data.vector.y
end

flame.onRedDraw = redstone.drawNPC

redstone.register(flame)

return flame
