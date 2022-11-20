local transmitter = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local floor, ceil, abs = math.floor, math.ceil, math.abs
local insert = table.insert

transmitter.name = "transmitter"
transmitter.id = NPC_ID
transmitter.order = 0.40

transmitter.onRedPower = function(n, c, power, dir, hitbox)
  if redstone.is.reciever(c.id) and d == (n.data.frameX + 2)%4 then
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

  debug = true,
  effectid = 802,
})

local interactions = {}
local interactionsList = {}
transmitter.interactions = interactions

function transmitter.registerInteraction(id, t)
  t.filter = t.filter or function() return true end

  interactions[id] = t
  table.insert(interactionsList, id)
end
local registerInteraction = transmitter.registerInteraction

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

local function debugdraw(start, stop, power)
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
  local trueRay = maxRay
  local boundBox = fixCollider(Colliders.Box(start.x, start.y, maxRay.x, maxRay.y))  -- sometimes max ray may contain negative values

  local interactionList = Colliders.getColliding{a = boundBox, b = interactionsList, btype = Colliders.NPC, filter = function(v) return interactions[v.id].filter(v) and v ~= blacklist and not v.isHidden end} or {}
  local recieverList = Colliders.getColliding{a = boundBox, b = redstone.id.reciever, btype = Colliders.NPC, filter = function(v) return not v.isHidden end}

  local interactionColls = {}
  local foundInteractable = false

  for k, v in ipairs(interactionList) do
    local collFunc = interactions[v.id].collision
    if collFunc then
      insert(interactionColls, collFunc(v))
    else
      insert(interactionColls, v)
    end
  end

  for k, v in ipairs(interactionColls) do
    local iscollision, point, normal, crashcollider = Colliders.raycast(start, maxRay, v)
    if iscollision then
      local d = (start - point).length

      local id
      if crashcollider.reflector then id = redstone.id.reflector else id = crashcollider.id end

      local isInteractable = interactions[id].canInteract(iscollision, point, normal, crashcollider)

      if isInteractable and (not foundInteractable or d < foundInteractable.dist) then
        foundInteractable = {npc = crashcollider, dist = d, stop = point, normal = normal}
      end
    end
  end

  if foundInteractable then
    trueRay = foundInteractable.dist*ray
  end

  if transmitter.config.debug then
    debugdraw(start, start + trueRay, power)
  end

  for k, v in ipairs(recieverList) do
    local iscollision, point, normal, crashcollider = Colliders.raycast(start, trueRay, v)
    if iscollision then
      local diff = getBlockDiff(start, point)
      insert(found, {npc = crashcollider, power = ceil(power - diff)})
    end
  end


  if foundInteractable then
    local npc = foundInteractable.npc
    local stop = foundInteractable.stop
    local normal = foundInteractable.normal
    local newPower = power - trueRay.length/32

    local id
    if npc.reflector then id = redstone.id.reflector else id = npc.id end

    interactions[id].action(npc, trueRay, start, stop, normal, newPower, found, i)
  end
end

function transmitter.onRedLoad()
  registerInteraction(redstone.id.repeater, {
    ["canInteract"] = function(iscollision, point, normal, crashcollider)
      local dir = getInversePosition(crashcollider, point)
      return dir and dir == (crashcollider.data.frameX + 2)%4
    end,

    ["action"] = function(npc, ray, start, stop, normal, power, found, i)
      if lunatime.tick()%Effect.config[transmitter.config.effectid][1].lifetime == 0 then
        local e = Animation.spawn(transmitter.config.effectid, npc.x + 0.5*npc.width, npc.y)
        e.x, e.y = e.x - e.width*0.5, e.y - e.height - 2
      end

      local out = getOutputPosition(npc, npc.data.frameX)
      findInRaycast(out, vector(1, 0):rotate(dirToAngle[npc.data.frameX]), 15, npc, found, i)
    end,
  })

  registerInteraction(redstone.id.capacitor, {
    ["canInteract"] = function(iscollision, point, normal, crashcollider)
      local dir = getInversePosition(crashcollider, point)
      return dir and dir == (crashcollider.data.frameX + 2)%4
    end,

    ["action"] = function(npc, ray, start, stop, normal, power, found, i)
      if lunatime.tick()%Effect.config[transmitter.config.effectid][1].lifetime == 0 then
        local e = Animation.spawn(transmitter.config.effectid, npc.x + 0.5*npc.width, npc.y)
        e.x, e.y = e.x - e.width*0.5, e.y - e.height - 2
      end
      local data = npc.data
      local out = getOutputPosition(npc, npc.data.frameX)
      findInRaycast(out, vector(1, 0):rotate(dirToAngle[npc.data.frameX]), data.capacitance/data.maxcapacitance*power, npc, found, i)
    end,
  })

  registerInteraction(redstone.id.alternator, {
    ["canInteract"] = function(iscollision, point, normal, crashcollider)
      local dir = getInversePosition(crashcollider, point)
      if crashcollider.data.type == 0 then
        return dir and 1 - dir%2 == crashcollider.data.frameX
      else
        return dir and dir%2 == crashcollider.data.frameX
      end
    end,

    ["action"] = function(npc, ray, start, stop, normal, power, found, i)

      local dir = getInversePosition(npc, stop)
      if npc.data.type == 0 then
        if lunatime.tick()%Effect.config[transmitter.config.effectid][1].lifetime == 0 then
          local e = Animation.spawn(transmitter.config.effectid, npc.x + 0.5*npc.width, npc.y)
          e.x, e.y = e.x - e.width*0.5, e.y - e.height - 2
        end

        local dir = npc.data.frameX + npc.data.facing + 1
        local out = getOutputPosition(npc, dir)
        findInRaycast(out, vector(1, 0):rotate(dirToAngle[dir]), power, npc, found, i)
      elseif  dir == npc.data.frameX + 1 + npc.data.facing then
        if lunatime.tick()%Effect.config[transmitter.config.effectid][1].lifetime == 0 then
          local e = Animation.spawn(transmitter.config.effectid, npc.x + 0.5*npc.width, npc.y)
          e.x, e.y = e.x - e.width*0.5, e.y - e.height - 2
        end

        local dir = 2 - npc.data.frameX
        local out1 = getOutputPosition(npc, dir + 1)
        local out2 = getOutputPosition(npc, dir - 1)
        findInRaycast(out1, vector(1, 0):rotate(dirToAngle[dir + 1]), power, npc, found, i)
        findInRaycast(out2, vector(1, 0):rotate(dirToAngle[dir - 1]), power, npc, found, i)
      end
    end,
  })

  registerInteraction(redstone.id.fuse, {
    ["canInteract"] = function(iscollision, point, normal, crashcollider)
      local dir = getInversePosition(crashcollider, point)
      return dir and (dir == (crashcollider.data.frameX)%4 or dir == (crashcollider.data.frameX + 2)%4)
    end,

    ["action"] = function(npc, ray, start, stop, normal, power, found, i)
      if not npc.data.broken then
        if lunatime.tick()%Effect.config[transmitter.config.effectid][1].lifetime == 0 then
          local e = Animation.spawn(transmitter.config.effectid, npc.x + 0.5*npc.width, npc.y)
          e.x, e.y = e.x - e.width*0.5, e.y - e.height - 2
        end

        local out = getOutputPosition(npc, npc.data.frameX)
        findInRaycast(out, vector(1, 0):rotate(dirToAngle[npc.data.frameX]), power, npc, found, i)
      end
    end,
  })

  registerInteraction(redstone.id.absorber, {
    ["canInteract"] = function()
      return true
    end,

    ["action"] = function()
    end,
  })

  registerInteraction(redstone.id.reflector, {
    ["filter"] = function(n)
      return n.data.isOn
    end,

    ["collision"] = function(n)
      return n.data.collision
    end,

    ["canInteract"] = function()
      return true
    end,

    ["action"] = function(npc, ray, start, stop, normal, power, found, i)
      local dir = ray:normalize()
      local newpath = -2*(dir .. normal)*normal + dir

      findInRaycast(stop, newpath, power, npc.reflector, found, i)
    end,
  })
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
