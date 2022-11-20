local npcAI = {}

local redstone = require("redstone")
local npcID = NPC_ID

local config = NPC.config[npcID]
local ceil = math.ceil

-- vv Customization vv

-- NONE AVAILABLE

-- ^^ Customization ^^

function npcAI.onRedPower(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

function npcAI.prime(n)
  local data = n.data
  data.prevID = data.prevID or npcID
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 and data.powerPrev == 0 then
    data._basegame.explodeTimer = ceil(NPC.config[n.id].fuse*65) - 1
  end

  if n.id ~= data.prevID or data._basegame.explodeTimer == ceil(config.fuse*65) - 1 then
    data.prevID = npcID
    data.observ = true
  end

  redstone.resetPower(n)
end

return npcAI
