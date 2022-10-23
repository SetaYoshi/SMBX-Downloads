local operator = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local max, clamp = math.max, math.clamp

operator.name = "operator"
operator.id = NPC_ID

operator.test = function()
  return "isOperator", function(x)
    return (x == operator.id or x == operator.name)
  end
end

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

local mouthAI = function(n, c, power, dir, hitbox)
  if redstone.operatorNPC_mouth[n.id] then
    return redstone.operatorNPC_mouth[n.id](n, c, c.data.power, dir, hitbox)
  else
    return power
  end
end

local plusAI = function(n, c, power, dir, hitbox)
  return redstone.operatorNPC_plus[n.id](n, c, c.data.power, dir, hitbox)
end

local minusAI = function(n, c, power, dir, hitbox)
  return redstone.operatorNPC_minus[n.id](n, c, c.data.power, dir, hitbox)
end

local dirlist = {['eyes'] = 0, ['minus'] = 1, ['mouth'] = 2, ['plus'] = 3}
function operator.powerSide(n, dir)
  return n.data.pow[(n.data.frameX + dirlist[dir])%4]
end

function operator.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.dir or 0
  data.frameY = data.frameY or 0

  n.powerSide = operator.powerSide
  data.pow = data.pow or {[0] = 0, [1] = 0, [2] = 0, [3] = 0}
  data.diff = data.diff or 0
  data.timer = data.timer or 0

  data.redhitbox = redstone.basicRedHitBox(n)
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
  redstone.passDirectionEnergy{source = n, power = 0, hitbox = data.redhitbox[(data.frameX + 1)%4 + 1], npcList = redstone.operatorNPC_minus_MAP, powerAI = minusAI}
  redstone.passDirectionEnergy{source = n, power = 0, hitbox = data.redhitbox[(data.frameX - 1)%4 + 1], npcList = redstone.operatorNPC_plus_MAP, powerAI = plusAI}

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
