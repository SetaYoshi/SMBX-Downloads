local operator = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local max, clamp = math.max, math.clamp

operator.name = "operator"
operator.id = NPC_ID
operator.order = 0.44

operator.onRedPower = function(n, c, power, dir, hitbox)
  local data = n.data
  data.pow = data.pow or {[0] = 0, [1] = 0, [2] = 0, [3] = 0}

  if dir == -1 then
    dir = n.data.frameX
  else
    dir = (dir + 2)%4
  end

  data.pow[dir] = max(data.pow[dir], power)
end

operator.config = npcManager.setNpcSettings({
	id = operator.id,

  width = 32,
  height = 32,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 4,
	framespeed = 8,
	framestyle = 0,
  invisible = false,

  nogravity = true,
  notcointransformable = true,
  noblockcollision = true,
	jumphurt = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true
})


operator.operations = {}
local operations = operator.operations

local mouthList, plusList, minusList = {}, {}, {}
function operator.registerOperation(id, t)
  if id then
    operations[id] = t
    if t.mouth then table.insert(mouthList, id) end
    if t.plus then table.insert(plusList, id) end
    if t.minus then table.insert(minusList, id) end
  end
end
local registerOperation = operator.registerOperation

local mouthAI = function(n, c, power, dir, hitbox)
  if operations[n.id] and operations[n.id].mouth then
    return operations[n.id].mouth(n, c, c.data.power, dir, hitbox)
  else
    return power
  end
end

local plusAI = function(n, c, power, dir, hitbox)
  if not operations[n.id] then Misc.dialog(n.id) end
  return operations[n.id].plus(n, c, c.data.power, dir, hitbox)
end

local minusAI = function(n, c, power, dir, hitbox)
  return operations[n.id].minus(n, c, c.data.power, dir, hitbox)
end

local dirlist = {['eyes'] = 0, ['minus'] = 1, ['mouth'] = 2, ['plus'] = 3}
local function powerSide(n, dir)
  return n.data.pow[(n.data.frameX + dirlist[dir])%4]
end


function operator.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.dir or 0
  data.frameY = data.frameY or 0

  n.powerSide = powerSide
  data.pow = data.pow or {[0] = 0, [1] = 0, [2] = 0, [3] = 0}
  data.diff = data.diff or 0
  data.timer = data.timer or 0

  data.redhitbox = redstone.basicRedHitBox(n)
end

function operator.onRedLoad()
  registerOperation(redstone.id.repeater, {
    -- AND GATE
    ["plus"] = function(n, c, power, dir, hitbox)
      if c:powerSide('eyes') > 0 and c:powerSide('minus') > 0 then
        return 15
      else
        return 0
      end
    end,

    -- XOR GATR
    ["minus"] = function(n, c, power, dir, hitbox)
      local power_eyes = c:powerSide('eyes') > 0
      local power_plus = c:powerSide('plus') > 0
      if (power_eyes or power_plus) and not (power_eyes and power_plus) then
        return 15
      else
        return 0
      end
    end,
  })

  registerOperation(redstone.id.alternator, {
    -- TURNOUT
    ["mouth"] = function(n, c, power, dir, hitbox)
      if c.data.powerPrev == 0 and c.data.power > 0 then
        n.data.facing = -n.data.facing
      end
      return 15
    end
  })

  registerOperation(redstone.id.capacitor, {
    -- EQUAL TO
    ["mouth"] = function(n, c, power, dir, hitbox)
      if power == n.data.maxcapacitance then
        n.data.unlocked = true
        return power
      else
        return 0
      end
    end,

    -- GREATER THAN
    ["plus"] = function(n, c, power, dir, hitbox)
      if power > n.data.maxcapacitance then
        n.data.unlocked = true
        return power
      else
        return 0
      end
    end,

    -- LESS THAN
    ["minus"] = function(n, c, power, dir, hitbox)
      if power < n.data.maxcapacitance then
        n.data.unlocked = true
        return power
      else
        return 0
      end
    end,
  })

  registerOperation(redstone.id.spyblock, {
    ["mouth"] = function(n, c, power, dir, hitbox)
      -- MEDIAN COMPARE
      if n.data.type == 0 then
        if (c:powerSide('eyes') > c:powerSide('plus') and c:powerSide('plus') > c:powerSide('minus')) or (c:powerSide('minus') > c:powerSide('plus') and c:powerSide('plus') > c:powerSide('eyes')) then
          return c:powerSide('plus')
        elseif (c:powerSide('eyes') > c:powerSide('minus') and c:powerSide('minus') > c:powerSide('plus')) or (c:powerSide('plus') > c:powerSide('minus') and c:powerSide('minus') > c:powerSide('eyes')) then
          return c:powerSide('minus')
        else
          return c:powerSide('eyes')
        end
      -- ALL DIFF
      elseif n.data.type == 2 then
        return abs(c.data.diff)
      end
      return 0
    end,

    ["plus"] = function(n, c, power, dir, hitbox)
      -- MAX COMPARE
      if n.data.type == 0 then
        return max(c:powerSide('eyes'), c:powerSide('minus'))

      -- POS DIFF
      elseif n.data.type == 2 then
        if c.data.diff > 0 then
          return c.data.diff
        end
      end
      return 0
    end,

    ["minus"] = function(n, c, power, dir, hitbox)
      -- MIN COMPARE
      if n.data.type == 0 then
        return min(c:powerSide('eyes'), c:powerSide('plus'))

      -- NEG DIFF
      elseif n.data.type == 2 then
        if c.data.diff < 0 then
          return -c.data.diff
        end
      end
      return 0
    end
  })

  registerOperation(redstone.id.reaper, {
    ["mouth"] = function(n, c, power, dir, hitbox)
      return 15 - power
    end
  })
end

function operator.onRedTick(n)
  local data = n.data
  data.observ = false

  data.power = clamp(n:powerSide('eyes') + n:powerSide('plus') - n:powerSide('minus'), 0, 15)

  if n.data.powerPrev ~= n.data.power then
    n.data.diff = n.data.power - n.data.powerPrev
    n.data.timer = 5
  end

  if n.data.timer <= 0 then
    n.data.diff = 0
  else
    n.data.timer = n.data.timer - 1
  end


  redstone.updateRedHitBox(n)
  redstone.passDirectionEnergy{source = n, power = data.power, hitbox = data.redhitbox[(data.frameX + 2)%4 + 1], powerAI = mouthAI}
  redstone.passDirectionEnergy{source = n, power = 0, hitbox = data.redhitbox[(data.frameX + 1)%4 + 1], npcList = minusList, powerAI = minusAI}
  redstone.passDirectionEnergy{source = n, power = 0, hitbox = data.redhitbox[(data.frameX - 1)%4 + 1], npcList = plusList, powerAI = plusAI}

  if (data.power == 0 and data.powerPrev ~= 0) or (data.power ~= 0 and data.powerPrev == 0) then
    data.observ = true
  end

  if n:powerSide('eyes') == 0 and n:powerSide('plus') == 0 and n:powerSide('minus') == 0 then
    data.frameY = 0
  else
    data.frameY = 1
  end

  data.pow = {[0] = 0, [1] = 0, [2] = 0, [3] = 0}
  redstone.resetPower(n)
end

operator.onRedDraw = redstone.drawNPC

redstone.register(operator)

return operator
