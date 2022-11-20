local npcAI = {}

-- These are the custom zappakoopas made by MrDoubleA

-- vv Customization vv

-- If set to true, the zappakoopa will no longer shoot lasers automatically
npcAI.onlyShootWithPower = true

-- ^^ Customization ^^

local redstone = require("redstone")
local npcID = NPC_ID
local config = NPC.config[npcID]

local STATE_WALK    = 0
local STATE_PREPARE = 1
local STATE_ATTACK  = 2
local STATE_RETURN  = 3

function npcAI.onRedPower(n, c, power, dir, hitbox)
  local data = n.data
  redstone.setEnergy(n, power)

  if data.power > 0 then
    if data.state == STATE_ATTACK and data.timer > config.attackTime - 2 then
      data.timer = config.attackTime - 10
    elseif data.powerPrev == 0 then
      data.state = 1
      data.timer = 0
    end
  elseif data.power == 0 and data.powerPrev > 0 and data.state ~= STATE_WALK then
    data.state = 0
  end
end

function npcAI.onRedTick(n)
  local data = n.data

  if npcAI.onlyShootWithPower and data.state == STATE_WALK then
    data.timer = 0
  end

  redstone.resetPower(n)
end

return npcAI
