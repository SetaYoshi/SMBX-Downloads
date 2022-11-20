local redstone = require("redstone")

-- vv Customization vv

-- List of NPCs ID this file will affect. This is for the walking birds NPCs
local birdist = {501, 502, 503, 504}

-- List of NPCs ID this file will affect. This is for the flying bird NPCs
local flybirdList = {505, 506, 507, 508}

-- ^^ Customization ^^


local function onRedPower(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

local function bird_onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 then
    n.id = n.id + 4
    n.speedY = -1
    n.dontMove = false
    n.direction = DIR_LEFT
    n.data._basegame.moveState = 3
    data.observ = true
  end

  redstone.resetPower(n)
end

local function fly_onRedTick(n)
  local data = n.data
  data.observ = false

  if not data.hasObserv then
    data.hasObserv = true
    data.observ = true
  end

  redstone.resetPower(n)
end


for _, id in ipairs(birdist) do
  redstone.register({
    id = id,
    onRedPower = onRedPower,
    onRedTick = bird_onRedTick,
  })
end

for _, id in ipairs(flybirdList) do
  redstone.register({
    id = id,
    onRedPower = onRedPower,
    onRedTick = fly_onRedTick,
  })
end
