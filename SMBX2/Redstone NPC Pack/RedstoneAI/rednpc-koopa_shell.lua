local redstone = require("redstone")

-- vv Customization vv

local shellList = {5, 7, 73, 24, 172, 174, 113, 114, 115, 116}

-- ^^ Customization ^^


local function onDispense(n)
  n.speedX = 7.1*n.direction
end

for _, id in ipairs(shellList) do
  redstone.register({
    id = id,
    onDispense = onDispense,
  })
end
