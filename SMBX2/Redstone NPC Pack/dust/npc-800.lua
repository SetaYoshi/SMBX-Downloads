-- v1.3.0

local dust = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local insert, iclone = table.insert, table.iclone

dust.name = "dust"
dust.id = NPC_ID
dust.order = 0.76

dust.config = npcManager.setNpcSettings({
	id = dust.id,

  width = 32,
  height = 32,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 1,
	framespeed = 8,
	framestyle = 0,
  invisible = false,

  noblockcollision = true,
  notcointransformable = true,
  nogravity = true,
	jumphurt = true,
	nohurt = true,
	noyoshi = true,
  disabledespawn = false,

  basicdust = false,  -- A less laggy, but less accurate dust AI
  debug = true,      -- Debugs the power level of the NPC
  automap = true,    -- Automaps index 0 automatically
	istransparent = true,
})

local dustMap = {}
dustMap["true true true true"]     = 1
dustMap["true false true false"]   = 2
dustMap["false true false true"]   = 3
dustMap["false false true true"]   = 4
dustMap["false true true false"]   = 5
dustMap["true true false false"]   = 6
dustMap["true false false true"]   = 7
dustMap["true false true true"]    = 8
dustMap["false true true true"]    = 9
dustMap["true true true false"]    = 10
dustMap["true true false true"]    = 11
dustMap["true false false false"]  = 12
dustMap["false true false false"]  = 13
dustMap["false false true false"]  = 14
dustMap["false false false true"]  = 15
dustMap["false false false false"] = 16

local networks = {}

local function collectDust(n, net)
  if n.data.redNetwork == net then return end
  n.data.redNetwork = net

  if not n.data.redhitbox then return end

  net[n] = {{}, {}, {}, {}}
  for dir, coll in ipairs(n.data.redhitbox) do
    local l = Colliders.getColliding{a = coll, b = redstone.comID, btype = Colliders.NPC, filter = function(v) return v ~= n and not v.isHidden end} 
    for _, npc in ipairs(l) do
      table.insert(net[n][dir], npc)

      collectDust(npc, net)
    end
  end
end

local function createNetwork(n)
  local t = {}
  local k = #networks + 1
  networks[k] = t
  t.ID = k
  
  collectDust(n, t)
end

local function destroyNetwork(k, t)
  for _, v in ipairs(t) do
    v.data.redNetwork = nil
  end
  networks[k] = nil
end

local function foundDust(n, coll)
  for k, v in NPC.iterateIntersecting(coll.x, coll.y, coll.x + coll.width, coll.y + coll.height) do
    if redstone.comList[v.id] and v ~= n and n.layerName == v.layerName and (v.id ~= dust.id or v.data.colorType == n.data.colorType) then
      return true
    end
  end
  return false
end

local function setFrameX(n)
  redstone.updateRedHitBox(n)
  local redhitbox = n.data.redhitbox

  local fLeft = foundDust(n, redhitbox[1])
  local fUp = foundDust(n, redhitbox[2])
  local fRight = foundDust(n, redhitbox[3])
  local fDown = foundDust(n, redhitbox[4])

  n.data.frameX = dustMap[tostring(fLeft).." "..tostring(fUp).." "..tostring(fRight).." "..tostring(fDown)] or 0
end



-- Look guys, I tried my best here.
-- delete network if x, y, layer state, or color state changed!!!
local function instantpower(n)
  local power = n.data.power

  if not n.data.redNetwork then
    createNetwork(n)
  end

  local net = n.data.redNetwork
  for dir, t in ipairs(net[n]) do
    for _, v in ipairs(t) do
      if v.id == dust.id then
        if n.data.power > v.data.power + 1 and n.data.colorType == v.data.colorType and not n.isHidden then
          redstone.setEnergy(v, n.data.power - 1)
          redstone.updateRedArea(v)
          redstone.updateRedHitBox(v)
          instantpower(v)
        end
      else
          redstone.energyFilter(v, n, n.data.power, dir - 1, coll)
        end
      end
  end
end

function dust.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = (data._settings.mapX or 1)
  data.frameY = data.frameY or 0

  data.colorType = data._settings.color or 0
  data.pistIgnore = data.pistIgnore or true

  data.redarea = data.redarea or redstone.basicRedArea(n)
  data.redhitbox = data.redhitbox or redstone.basicRedHitBox(n)

  n.priority = -46
end

local function onRedPowerBasic(n, c, p, d, hitbox)
  if c.id == dust.id then
    if c.data.colorType == n.data.colorType then
      redstone.setEnergy(n, p - 1)
    end
  else
    redstone.setEnergy(n, p)
  end
end

local function onRedTickBasic(n)
  local data = n.data
  data.observ = false

  if dust.config.automap and data.frameX == 0 then
    setFrameX(n)
  end
  if dust.config.debug and not n.isHidden then
    redstone.printNPC(n.data.power, n, 12, 12)
  end

  if data.power > 0 then
    redstone.updateRedArea(n)
    redstone.updateRedHitBox(n)
    redstone.passEnergy{source = n, power = data.power, hitbox = data.redhitbox, area = data.redarea}
  end

  data.frameY = ((data.power == 0 and 0) or (data.power < 8 and 1) or 2) + 3*data.colorType

  data.observ = data.powerPrev ~= data.power
  redstone.resetPower(n)
end


local function onRedPowerComplex(n, c, p, d, hitbox)
  if not redstone.is.dust(c.id) then
    redstone.setEnergy(n, p)
    redstone.updateRedArea(n)
    redstone.updateRedHitBox(n)
    instantpower(n)
  end
end

local function onRedTickComplex(n)
  n.data.observ = false

  if dust.config.automap and n.data.frameX == 0 then
    setFrameX(n)
  end
end

local function onRedTickEndComplex(n)
  local data = n.data
  
  if dust.config.debug and not n.isHidden then
    redstone.printNPC(n.data.power, n, 12, 12)
  end

  data.frameY = ((data.power == 0 and 0) or (data.power < 8 and 1) or 2) + 3*data.colorType
  
  data.observ = data.powerPrev ~= data.power  
  redstone.resetPower(n)
end


if dust.config.basicdust then
  dust.onRedPower = onRedPowerBasic
  dust.onRedTick = onRedTickBasic
else
  dust.onRedPower = onRedPowerComplex
  dust.onRedTick = onRedTickComplex
  dust.onRedTickEnd = onRedTickEndComplex
end


dust.onRedDraw = redstone.drawNPC

redstone.register(dust)

return dust
