local redstone = require("redstone")

-- vv Customization vv

-- List of NPCs ID this file will affect
local wigglerList = {446, 448}

-- ^^ Customization ^^


local function prime(n)
  local data = n.data
  data.wasAngry = data._basegame.isAngry
end

local function onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 and not data._basegame.isAngry then
    data._basegame.turningAngry = true
    SFX.play(9)
  end

  if data._basegame.isAngry ~= data.wasAngry then
    data.observ = true
  end

  data.wasAngry = data._basegame.isAngry
  redstone.resetPower(n)
end

for _, id in ipairs(wigglerList) do
  redstone.register({
  id = id,
  prime = prime,
  onRedTick = onRedTick,
})
end
