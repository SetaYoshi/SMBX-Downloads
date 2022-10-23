local dust = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local insert, iclone = table.insert, table.iclone

dust.name = "dust"
dust.id = NPC_ID

dust.test = function()
  return "isDust", function(x)
    return (x == dust.id or x == dust.name)
  end
end

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

  basicdust = false,  -- A less laggy, but less accurate dust AI
  debug = false,      -- Debugs the power level of the NPC
  automap = true    -- Automaps index 0 automatically
})

local dustMap = {}
dustMap["true true true true"] = 1
dustMap["true false true false"] = 2
dustMap["false true false true"] = 3
dustMap["false false true true"] = 4
dustMap["false true true false"] = 5
dustMap["true true false false"] = 6
dustMap["true false false true"] = 7
dustMap["true false true true"] = 8
dustMap["false true true true"] = 9
dustMap["true true true false"] = 10
dustMap["true true false true"] = 11
dustMap["true false false false"] = 12
dustMap["false true false false"] = 13
dustMap["false false true false"] = 14
dustMap["false false false true"] = 15
dustMap["false false false false"] = 16

local function foundDust(n, coll)
  local found = false

  Colliders.getColliding{a = coll, b = dust.id, btype = Colliders.NPC, filter = function(v)
    if v ~= n and n.layerName == v.layerName and v.data.colorType == n.data.colorType then
      found = true
    end
  end}

  return found
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


local dustQueque = {}
local dustRemain = {}


-- Look guys, I tried my best here.
local function instantpower(n)
  local power = n.data.power
  local list = NPC.get(redstone.comID, n.section) --Colliders.getColliding{a = data.redarea, b = redstone.comID, btype = Colliders.NPC, filter = redstone.nofilter}
  dustRemain = {n}
  dustQueque = {}
  while dustRemain[1] do
    for _, dust in ipairs(dustRemain) do
      local data = dust.data
      for dir, coll in ipairs(data.redhitbox) do
        for k = #list, 1, -1 do
          local v = list[k]
          if Colliders.collide(v, coll) then
            if v.id == dust.id then
              if v ~= dust and data.power > v.data.power + 1 and data.colorType == v.data.colorType then
                redstone.setEnergy(v, dust.data.power - 1)
                redstone.updateRedArea(v)
                redstone.updateRedHitBox(v)
                insert(dustQueque, v)
              end
            else
              redstone.energyFilter(v, dust, dust.data.power, dir - 1, coll)
            end
          end
        end
      end
    end
    dustRemain = iclone(dustQueque)
    dustQueque = {}
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




if dust.config.basicdust then
  dust.onRedPower = function(n, c, p, d)
    if c.id == dust.id then
      if c.data.colorType == n.data.colorType then
        redstone.setEnergy(n, p - 1)
      end
    else
      redstone.setEnergy(n, p)
    end
  end

  function dust.onRedTick(n)
    local data = n.data
    data.observ = false

    if dust.config.automap and data.frameX == 0 then
      setFrameX(n)
    end

    if data.power > 0 then
      redstone.updateRedArea(n)
      redstone.updateRedHitBox(n)
      redstone.passEnergy{source = n, power = data.power, hitbox = data.redhitbox, area = data.redarea}
    end

    if data.power == 0 then
      data.frameY = 0
    elseif data.power < 8 then
      data.frameY = 1
    else
      data.frameY = 2
    end
    data.frameY = data.frameY + 3*data.colorType

    data.observ = data.powerPrev ~= data.power
    redstone.resetPower(n)
  end

else
  dust.onRedPower = function(n, c, p, d, hitbox)
    if not redstone.isDust(c.id) then
      redstone.setEnergy(n, p)
      redstone.updateRedArea(n)
      redstone.updateRedHitBox(n)
      instantpower(n)
    end
  end

  function dust.onRedTick(n, v)
    local data = n.data
    data.observ = false

    if dust.config.automap and data.frameX == 0 then
      setFrameX(n)
    end
  end

  function dust.onRedTickEnd(n)
    local data = n.data

    if data.power == 0 then
      data.frameY = 0
    elseif data.power >= 8 then
      data.frameY = 2
    else
      data.frameY = 1
    end
    data.frameY = data.frameY + 3*data.colorType

    if dust.config.debug and not n.isHidden then
      redstone.printNPC(n.data.power, n, 12, 12)
    end

    data.observ = data.powerPrev ~= data.power

    redstone.resetPower(n)
  end
end


dust.onRedDraw = redstone.drawNPC

redstone.register(dust)

return dust
