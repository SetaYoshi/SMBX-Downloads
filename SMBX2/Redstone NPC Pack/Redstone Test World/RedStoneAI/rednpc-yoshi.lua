local npcAI = {}

local npcID = NPC_ID
local redstone = require("redstone")

-- vv Customization vv

-- List of NPCs ID this file will affect
npcAI.yoshiList = {95, 98, 99, 100, 148, 149, 150, 228}

-- How should yoshi behave when powered
--  0: When powered, yoshi will always run away
--  1: If powered > 7 then yoshi will run, otherwise yoshi will stop running
--  2: Yoshi will toggle between running and stopping with every pulse
npcAI.powerType = 2

-- ^^ Customization ^^


function npcAI.prime(n)
  local data = n.data

  data.prevAI = data.prevAI or n.ai1
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false

  if npcAI.powerType == 0 then
    if data.power > 0 and n.ai1 == 0 then
      n.ai1 = 1
      SFX.play(49)
    end
  elseif npcAI.powerType == 1 then
    if data.power > 7 and n.ai1 == 0 then
      n.ai1 = 1
      SFX.play(49)
    elseif data.power > 0 and data.power < 8 and n.ai1 == 1 then
      n.ai1 = 0
      SFX.play(49)
    end
  elseif npcAI.powerType == 2 then
    if data.power > 0 and data.powerPrev == 0 then
      if n.ai1 == 0 then
        n.ai1 = 1
        SFX.play(49)
      elseif n.ai1 == 1 then
        n.ai1 = 0
        SFX.play(49)
      end
    end
  end

  if data.prevAI ~= n.ai1 then
    data.observ = true
  end

  data.prevAI = n.ai1
  redstone.resetPower(n)
end

function npcAI.onDispense(n)
  n.ai1 = 1
  SFX.play(49)
end

for _, v in ipairs(npcAI.yoshiList) do
  redstone.registerNPC(v, npcAI)
end

return npcAI
