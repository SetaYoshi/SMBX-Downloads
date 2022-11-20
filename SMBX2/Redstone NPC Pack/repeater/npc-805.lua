local repeater = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

repeater.name = "repeater"
repeater.id = NPC_ID
repeater.order = 0.36

repeater.onRedPower = function(n, c, power, dir, hitbox)
  local data = n.data
  if (dir == -1 or dir == data.frameX) then
    redstone.setEnergy(n, power)
  elseif c.id == repeater.id and (dir == (data.frameX + 1)%4 or dir == (data.frameX - 1)%4) then
    data.locked = true
    data.lockedCooldown = 2
  else
    return true
  end
end

repeater.config = npcManager.setNpcSettings({
	id = repeater.id,

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
  notcointransformable = true,
	jumphurt = true,
  noblockcollision = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true
})


function repeater.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.dir or 0
  data.frameY = data.frameY or 0

  data.delay = (data._settings.delay or 2)*10
  data.isOn = data.isOn or false
  data.onTimer = data.onTimer or 0
  data.timerPrev = data.timerPrev or 0
  data.locked = data.locked or false
  data.lockedCooldown = data.lockedCooldown or 0

  data.redhitbox = data.redhitbox or redstone.basicDirectionalRedHitBox(n, data.frameX)
end

function repeater.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.isOn then
    redstone.updateDirectionalRedHitBox(n, data.frameX)
    redstone.passDirectionEnergy{source = n, power = 15, hitbox = data.redhitbox}
    if data.power == 0 and data.onTimer == 0 then
      data.onTimer = data.delay
    elseif data.power > 0 then
      data.onTimer = 0
    end
  else
    if data.power > 0 and data.onTimer == 0 then
      data.onTimer = data.delay
    end
  end

  if data.locked then
    data.power = data.powerPrev
    data.onTimer = data.timerPrev
  elseif data.onTimer > 0 then
    data.onTimer = data.onTimer - 1
    if data.onTimer == 0 then
      data.isOn = not data.isOn
      data.observ = true
    end
  end
  data.timerPrev = data.onTimer

  if data.lockedCooldown > 0 then
    data.lockedCooldown = data.lockedCooldown - 1
    if data.lockedCooldown == 0 then
      data.locked = false
    end
  end

  if data.isOn then
    data.frameY = 1
  else
    data.frameY = 0
  end
  if data.locked then
    data.frameY = data.frameY + 2
  end

  redstone.resetPower(n)
end

repeater.onRedDraw = redstone.drawNPC

redstone.register(repeater)

return repeater
