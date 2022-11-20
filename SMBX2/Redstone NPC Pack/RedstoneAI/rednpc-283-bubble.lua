local npcAI = {}

-- vv Customization vv

-- NONE AVAILABLE

-- ^^ Customization ^^

local npcID = NPC_ID
local redstone = require("redstone")

function npcAI.onRedPower(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 then
    n.ai3 = 1
  end

  if n.ai3 == 1 then
    data.observ = true
  end

  redstone.resetPower(n)
end


return npcAI
