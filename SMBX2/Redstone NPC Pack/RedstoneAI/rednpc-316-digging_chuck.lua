local npcAI = {}

local npcID = NPC_ID
local config = NPC.config[npcID]
local redstone = require("redstone")

-- vv Customization vv

-- If set to true, the chuck will no longer spawn rocks by its own and need redstone power
npcAI.onlyShootWithPower = true

-- If set to false, the chuck will only spawn a single rock instead of shooting the amount set in its volley setting
npcAI.shootVolley = true

-- ^^ Customization ^^


function npcAI.onRedPower(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power == 0 then
    if npcAI.onlyShootWithPower and n.ai3 ~= 0 and n.ai2 > config.startwait and n.ai2 < config.startwait + config.digwait then
      n.ai2 = config.startwait + config.digwait
    end
  else
    if n.ai2 < config.startwait + config.digwait - 1 then
      local volley = data._settings.volley
      if npcAI.shootVolley then volley = 0 end
      n.ai3 = volley
      n.ai2 = config.startwait + config.digwait - 1
    end
  end

  if n.ai2 == config.startwait + config.digwait + config.liftwait - 1 then
    data.observ = true
  end

  redstone.resetPower(n)
end


return npcAI
