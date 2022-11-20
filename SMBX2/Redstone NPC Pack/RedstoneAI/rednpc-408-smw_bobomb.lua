local npcAI = {}

local redstone = require("redstone")
local npcID = NPC_ID

-- vv Customization vv

-- NONE AVAILABLE

-- ^^ Customization ^^

function npcAI.onRedPower(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 then
    n:transform(409)
    n.speedX = 0
  end

  data.prevID = n.id
  redstone.resetPower(n)
end

return npcAI
