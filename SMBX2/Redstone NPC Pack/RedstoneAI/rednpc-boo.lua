local redstone = require("redstone")

-- vv Customization vv

-- List of NPCs ID this file will affect
local booList = {38, 43, 44}

-- ^^ Customization ^^


function onRedPower(n, c, power, dir, hitbox)
  return true
end

local function prime(n)
  local data = n.data

  data.redarea = data.redarea or redstone.basicRedArea(n)
  data.redhitbox = data.redhitbox or redstone.basicRedHitBox(n)
end

local function onRedTick(n)
  local data = n.data
  data.observ = false

  if n.ai1 == 0 then
    redstone.updateRedArea(n)
    redstone.updateRedHitBox(n)
    redstone.passEnergy{source = n, power = 15, hitbox = data.redhitbox, area = data.redarea}
  end

  if n.ai1 ~= data.prevAI then
    data.observ = true
  end

  data.prevAI = n.ai1
end

for _, id in ipairs(booList) do
  redstone.register({
    id = id,
    prime = prime,
    onRedPower = onRedPower,
    onRedTick = onRedTick,
  })
end
