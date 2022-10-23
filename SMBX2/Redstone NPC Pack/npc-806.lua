local alternator = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

alternator.name = "alternator"
alternator.id = NPC_ID

alternator.test = function()
  return "isAlternator", function(x)
    return (x == alternator.id or x == alternator.name)
  end
end

local TYPE_ALTERNATOR = 0
local TYPE_INVERTER = 1

alternator.onRedPower = function(n, c, power, dir, hitbox)
  local data = n.data
  local validDir1, validDir2

  if data.type == TYPE_ALTERNATOR then
    if data.frameX == 0 then
      validDir1, validDir2 = 1, 3
    else
      validDir1, validDir2 = 0, 2
    end
  elseif data.type == TYPE_INVERTER then
    validDir1 = (data.frameX - data.facing + 1) % 4
  end

  if dir == -1 or dir == validDir1 or dir == validDir2 then
    redstone.setEnergy(n, power)
  else
    return true
  end
end

alternator.config = npcManager.setNpcSettings({
	id = alternator.id,

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

  nogravity = true,
	jumphurt = true,
  noblockcollision = true,
  notcointransformable = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true
})

local function faceCheck(n)
  if RNG.random()*100 <= n then
    return -1
  end
  return 1
end

function alternator.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.dir or 0
  data.frameY = data.frameY or 0

  data.facing = data.facing or -1
  data.type = data._settings.type or 0
  data.invspace = true

  data.redhitbox = data.redhitbox or redstone.basicRedHitBox(n)
end

function alternator.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 then
    redstone.updateRedHitBox(n)

    if data.inv ~= 0 and data.powerPrev == 0 and data.type == TYPE_ALTERNATOR then
      data.facing = faceCheck(data.inv)
    end

    if data.type == TYPE_ALTERNATOR then
      redstone.passDirectionEnergy{source = n, power = data.power, hitbox = data.redhitbox[data.frameX + data.facing + 2]}
    elseif data.type == TYPE_INVERTER then
      local dir1, dir2 = 2, 4
      if data.frameX == 1 then dir1, dir2 = 1, 3 end
      redstone.passDirectionEnergy{source = n, power = data.power, hitbox = data.redhitbox[dir1]}
      redstone.passDirectionEnergy{source = n, power = data.power, hitbox = data.redhitbox[dir2]}
    end
  elseif data.powerPrev > 0 then
    if data.inv ~= 0 and data.type == TYPE_INVERTER then
      data.facing = faceCheck(data.inv)
    end

    if data.inv == 0 then
      data.facing = -data.facing
    end
  end

  if (data.power == 0 and data.powerPrev ~= 0) or (data.power ~= 0 and data.powerPrev == 0) then
    data.observ = true
  end

  if data.power == 0 then
    data.frameY = 0
  elseif data.facing == -1 then
    data.frameY = 1
  else
    data.frameY = 2
  end

  if data.type == TYPE_INVERTER then
    data.frameY = data.frameY + 3
  end

  redstone.resetPower(n)
end

alternator.onRedDraw = redstone.drawNPC

redstone.register(alternator)

return alternator
