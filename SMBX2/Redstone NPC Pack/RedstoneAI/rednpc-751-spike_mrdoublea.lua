local npcAI = {}

-- These are the custom spikes made by MrDoubleA

-- vv Customization vv

-- If set to true, the spike will no longer spit spike balls automatically
npcAI.onlyShootWithPower = true

-- ^^ Customization ^^

local redstone = require("redstone")
local npcID = NPC_ID

function npcAI.onRedPower(n, c, power, dir, hitbox)
  local data = n.data
  redstone.setEnergy(n, power)

  if data.power > 0 and data.powerPrev == 0 and data.state == 0 then
    data.state = 1
    data.timer = 0
  end
end

function npcAI.onRedTick(n)
  if npcAI.onlyShootWithPower and n.data.state == 0 then
    n.data.timer = 0
  end

  redstone.resetPower(n)
end

return npcAI
