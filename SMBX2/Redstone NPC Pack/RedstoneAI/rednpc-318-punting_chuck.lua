local npcAI = {}

local npcID = NPC_ID
local redstone = require("redstone")

-- vv Customization vv

-- If set to true, the chuck will no longer spawn footballs by its own and need redstone power
npcAI.onlyShootWithPower = true

-- Cooldown between kicks when spawning footballs when powered
npcAI.cooldown = 40

-- ^^ Customization ^^

function npcAI.onRedPower(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power == 0 then
    if npcAI.onlyShootWithPower and n.ai2 > npcAI.cooldown then
      n.ai2 = npcAI.cooldown + 2
    end
  else
    if n.ai2 > npcAI.cooldown then
      n.ai2 = npcAI.cooldown
    end
  end

  if n.ai2 == 10 then
    data.observ = true
  end

  redstone.resetPower(n)
end


return npcAI
