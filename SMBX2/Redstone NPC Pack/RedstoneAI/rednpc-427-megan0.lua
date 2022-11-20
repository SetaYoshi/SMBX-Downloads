local npcAI = {}

-- vv Customization vv

-- NONE AVAILABLE

-- ^^ Customization ^^

local redstone = require("redstone")
local npcID = NPC_ID

function npcAI.onRedPower(n, c, power, dir, hitbox)
  return true
end

function npcAI.prime(n)
  local data = n.data

  data.redarea = data.redarea or redstone.basicRedArea(n)
  data.redhitbox = data.redhitbox or redstone.basicRedHitBox(n)
end

function npcAI.onRedTick(n)
  local data = n.data

  redstone.updateRedArea(n)
  redstone.updateRedHitBox(n)
  redstone.passEnergy{source = n, power = 15, hitbox = data.redhitbox, area = data.redarea}
end

return npcAI
