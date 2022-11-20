local npcAI = {}

-- vv Customization vv

-- NONE AVAILABLE

-- ^^ Customization ^^

local npcID = NPC_ID
local redstone = require("redstone")

local abs = math.abs

function npcAI.onRedPower(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 and n.ai4 == 0 then
    n.ai4 = 1
    n.ai2 = 5
    n.ai3 = 20

    n.y = n.y - 4
    n.speedY = -abs(NPC.config[npcID].jumpheight)

    data.frame = 1
    SFX.play(24)
  end

  if n.ai3 == 20 then
    data.observ = true
  end

  redstone.resetPower(n)
end


return npcAI
