local transmitter = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local floor, ceil, abs = math.floor, math.ceil, math.abs
local insert = table.insert

transmitter.name = "transmitter"
transmitter.id = NPC_ID

transmitter.test = function()
  return "isTransmitter", function(x)
    return (x == transmitter.id or x == transmitter.name)
  end
end

transmitter.onRedPower = function(n, c, power, dir, hitbox)
  if redstone.isReciever(c.id) and d == (n.data.frameX + 2)%4 then
    return true
  end
  redstone.setEnergy(n, power)
end

transmitter.config = npcManager.setNpcSettings({
	id = transmitter.id,

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

  nogravity = true,
  notcointransformable = true,
	jumphurt = true,
  noblockcollision = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true,

  debug = false
})

local iwifi = Graphics.loadImage(Misc.resolveFile("npc-"..transmitter.id.."-1.png"))

function transmitter.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.dir or 0
  data.frameY = data.frameY or 0
end

local dirToAngle = {
  [0] = 180,
  [1] = -90,
  [2] = 0,
  [3] = 90
}

local function getOutputPosition(n, dir)
  if dir == 0 then
    return vector(n.x, n.y + n.height*0.5)
  elseif dir == 1 then
    return vector(n.x + 0.5*n.width, n.y)
  elseif dir == 2 then
    return vector(n.x + n.width, n.y + n.height*0.5)
  elseif dir == 3 then
    return vector(n.x + 0.5*n.width, n.y + n.height)
  end
end

local function getInversePosition(n, point)
  if abs(n.x - point.x) < 4 then
    return 0
  elseif abs(n.y - point.y) < 4 then
    return 1
  elseif abs(n.x + n.width - point.x) < 4 then
    return 2
  elseif abs(n.y + n.height - point.y) < 4 then
    return 3
  end
end

local function debugdraw(start, stop)
  local n = 2*((start - stop):normalize()):rotate(90)
  local z1, z2, z3, z4 = start + n, start - n, stop + n, stop - n
  Graphics.glDraw{vertexCoords = {z1.x, z1.y, z2.x, z2.y, z4.x, z4.y, z1.x, z1.y, z3.x, z3.y, z4.x, z4.y}, priority = 0, sceneCoords = true, color = Color.green}
end


local function fixCollider(c)
  if c.width < 0 then
    c.x = c.x + c.width
    c.width = -c.width
  elseif c.width == 0 then
    c.x = c.x - 2
    c.width = c.width + 4
  end
  if c.height < 0 then
    c.y = c.y + c.height
    c.height = -c.height
  elseif c.height == 0 then
    c.y = c.y - 2
    c.height = c.height + 4
  end
  return c
end


local function getBlockDiff(start, stop)
  return (start - stop).length/32
end

local findInRaycast
findInRaycast = function(start, ray, power, blacklist, found, i)
  i = i + 1
  if i == 50 then return end -- just in case of infinite loop

  local maxRay = ray*power*32
  local boundBox = fixCollider(Colliders.Box(start.x, start.y, maxRay.x, maxRay.y))  -- sometimes max ray may contain negative values

  local redirectorList = {}
  local recieverList = {}

  local reflectorList = Colliders.getColliding{a = boundBox, b = redstone.component.reflector.id, btype = Colliders.NPC, filter = function(v) return v ~= blacklist and not v.isHidden and v.data.isOn end}
  local redirectorList = Colliders.getColliding{a = boundBox, b = {redstone.component.repeater.id, redstone.component.absorber.id}, btype = Colliders.NPC, filter = function(v) return v ~= blacklist and not v.isHidden end}
  local recieverList = Colliders.getColliding{a = boundBox, b = redstone.component.reciever.id, btype = Colliders.NPC, filter = function(v) return not v.isHidden end}

  if reflectorList and reflectorList[1] then
    for k, v in ipairs(reflectorList) do
      insert(redirectorList, v.data.collision)
    end
  end


  local redirectorData = {}
  local closestBlockage = {npc = nil, dist = nil, stop = nil, normal = nil}

  for k, v in ipairs(redirectorList) do
    local iscollision, point, normal, crashcollider = Colliders.raycast(start, maxRay, v)

    if iscollision then
      local d = (start - point).length

      local ignoreThisOne = false
      if redstone.isRepeater(crashcollider.id) then
        local dir = getInversePosition(crashcollider, point)
        if dir and dir ~= (crashcollider.data.frameX + 2)%4 then
          ignoreThisOne = true
        end
      end

      if not ignoreThisOne and (not closestBlockage.dist or d < closestBlockage.dist) then
        closestBlockage = {npc = crashcollider, dist = d, stop = point, normal = normal}
      end
    end
  end

  local noBlockage = not closestBlockage.stop

  if transmitter.config.debug then
    if noBlockage then
      debugdraw(start, start + maxRay)
    else
      debugdraw(start, closestBlockage.stop)
    end
  end

  for k, v in ipairs(recieverList) do
    local iscollision, point, normal, crashcollider = Colliders.raycast(start, maxRay, v)

    if iscollision then
      if noBlockage or (start - point).length < closestBlockage.dist then
        local diff = getBlockDiff(start, point)
        insert(found, {npc = crashcollider, power = ceil(power - diff)})
      end
    end
  end


  if not noBlockage then
    local npc = closestBlockage.npc
    local stop = closestBlockage.stop
    local normal = closestBlockage.normal

    if redstone.isRepeater(npc.id) then
      Graphics.drawImageToSceneWP(iwifi, npc.x + 0.5*npc.width - iwifi.width*0.5, npc.y + 0.5*npc.height - iwifi.height*0.5, -44.9)
      local out = getOutputPosition(npc, npc.data.frameX)
      findInRaycast(out, vector(1, 0):rotate(dirToAngle[npc.data.frameX]), 15, npc, found, i)
    elseif npc.reflector then
      local newpath = -2*(ray .. normal)*normal + ray
      local diff = getBlockDiff(start, stop)
      findInRaycast(stop, newpath, power - diff, npc.reflector, found, i)
    elseif redstone.isAbsorber(npc.id) then
      return
    end
  end
end


function transmitter.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power ~= 0 then
    local out = getOutputPosition(n, data.frameX)
    local foundRecievers = {}
    findInRaycast(out, vector(1, 0):rotate(dirToAngle[data.frameX]), data.power, n, foundRecievers, 0)
    if foundRecievers then
      for k, v in ipairs(foundRecievers) do
        redstone.energyFilter(v.npc, n, v.power, data.frameX, n)
      end
    end
  end

  if data.power == 0 then
    data.frameY = 0
  else
    data.frameY = 1
  end

  if data.power ~= data.powerPrev then
    data.observ = true
  end

  redstone.resetPower(n)
end

transmitter.onRedDraw = redstone.drawNPC

redstone.register(transmitter)

return transmitter
