local npcAI = {}

local npcID = NPC_ID
local config = NPC.config[npcID]
local redstone = require("redstone")

-- vv Customization vv

-- If set to true, the chuck will no longer spawn baseballs by its own and need redstone power
npcAI.onlyShootWithPower = true

-- If set to false, the chuck will only spawn a single baseball instead of shooting the amount set in its volley setting
npcAI.shootVolley = false

-- ^^ Customization ^^


function npcAI.onRedPower(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power == 0 then
    if n.ai2 == -20 and npcAI.onlyShootWithPower then
      n.ai3 = 0
    end
    if npcAI.onlyShootWithPower and n.ai3 == 0 and n.ai2 == 0 then
      n.ai2 = -20
    end
  else
    if not npcAI.shootVolley then
      n.ai3 = 1
    end
    if n.ai2 < 0 and n.ai3 == 0 then
      local volley = 1
      if npcAI.shootVolley then volley = data._settings.volley end
      n.ai3 = volley

      n.ai2 = 0
    end
  end

  if n.ai2 == config.throwtime + 8 then
    data.observ = true
  end


  redstone.resetPower(n)
end


return npcAI
