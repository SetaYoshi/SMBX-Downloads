local npcAI = {}

-- vv Customization vv

-- If set to true, the spike will no longer spawn spike balls by its own and need redstone power
npcAI.onlyShootWithPower = true

-- ^^ Customization ^^

local npcID = NPC_ID
local redstone = require("redstone")

function npcAI.onRedPower(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false

    if n.ai2 == 1 and npcAI.onlyShootWithPower then
      n.ai3 = 2
    end

    if data.power > 0 and n.ai2 == 1 then
      n.ai2 = 2
      n.ai1 = 60
      n.ai3 = 0
      n.ai4 = 0
      SFX.play(23)
    end

    if n.ai2 == 1 and n.ai1 == 60 then
      data.observ = true
    end

  redstone.resetPower(n)
end


return npcAI
