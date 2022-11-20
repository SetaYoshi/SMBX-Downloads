local redstone = require("redstone")

-- vv Customization vv

-- List of NPCs ID this file will affect
local donutList = {46, 212}

-- ^^ Customization ^^


local function onRedPower(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

local function onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 then
    n.ai1 = 1
    n.ai3 = 30
  end

  if n.ai1 == 1 and data.prevAI ~= 1 then
    data.observ = true
  end

  data.prevAI = n.ai1
  redstone.resetPower(n)
end

for _, id in ipairs(donutList) do
  redstone.register({
    id = id,
    onRedPower = onRedPower,
    onRedTick = onRedTick,
  })
end
