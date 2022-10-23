local npcAI = {}

-- vv Customization vv

-- NONE AVAILABLE

-- ^^ Customization ^^

local npcID = NPC_ID
local redstone = require("redstone")

local sfxsqueal = Misc.resolveFile("sound/extended/pig-squeal.ogg")

local function angryPig(n)
  n.ai1, n.ai3, n.ai4 = 1, -30, 30
  n.data._basegame.xAccel = 0
  SFX.play(sfxsqueal)
end

function npcAI.onRedPower(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false
  
  if data.power > 0 and data.powerPrev == 0 and n.ai1 ~= 1 then
    angryPig(n)
  end

  if data.prevAI ~= n.ai1 then
    data.observ = true
  end

  data.prevAI = n.ai1
  redstone.resetPower(n)
end

function npcAI.onDispense(n)
  Routine.run(function()
    Routine.waitFrames(2)
    angryPig(n)
  end, n)
end

return npcAI
