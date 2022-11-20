local npcAI = {}

-- vv Customization vv

-- If set to true, the lotus will no longer spawn pollen automatically
npcAI.onlyShootWithPower = false

-- Cooldown between shots for when the lotus is continously powered
npcAI.cooldown = 40

-- ^^ Customization ^^

local redstone = require("redstone")
local npcID = NPC_ID

function npcAI.onRedPower(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false

  if npcAI.onlyShootWithPower and n.ai1 == 0 then
    n.ai2 = 0
  end

  if data.power > 0 and (n.ai1 ~= 2 or (n.ai1 == 2 and n.ai2 > npcAI.cooldown) or data.powerPrev == 0) then
    n.ai1, n.ai2 = 1, 69
  end

  if n.ai1 == 1 and n.ai2 == 69 then
    data.observ = true
  end

  redstone.resetPower(n)
end

return npcAI
