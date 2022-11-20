local npcAI = {}

local npcID = NPC_ID
local config = NPC.config[npcID]
local redstone = require("redstone")

-- vv Customization vv

--  NONE AVAILABLE

-- ^^ Customization ^^


function npcAI.onRedPower(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 and n.ai2 ~= 1 then
    n.ai2 = 1
  end

  if n.ai3 == config.hitcooldown then
    data.observ = true
  end

  redstone.resetPower(n)
end


return npcAI
