local hopper = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

hopper.name = "hopper"
hopper.id = NPC_ID

hopper.test = function()
  return "isHopper", function(x)
    return (x == hopper.id or x == hopper.name)
  end
end

hopper.onRedPower = function(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

hopper.onRedInventory = function(n, c, inv, dir, hitbox)
  n.data.inv = inv
end

hopper.config = npcManager.setNpcSettings({
	id = hopper.id,

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
  noblockcollision = true,
  notcointransformable = true,
	jumphurt = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true
})

function hopper.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.dir or 0
  data.frameY = data.frameY or 0

  data.inv = data._settings.inv or 0
  data.timer = data.timer or 0

  data.redhitbox = redstone.basicDirectionalRedHitBox(n, data.frameX)
end

function hopper.onRedTick(n)
  local data = n.data

  if data.inv ~= 0 then
    data.observ = true
    data.invspace = false
  else
    data.observ = false
    data.invspace = true
  end

  if data.power == 0 and data.inv ~= 0 then
    data.timer = data.timer + 1
    if data.timer >= 8 or data.powerPrev > 0 then
      data.timer = 0
      redstone.updateDirectionalRedHitBox(n, data.frameX)
      local passed = redstone.passInventory{source = n, inventory = data.inv, hitbox = data.redhitbox}
      if passed then
        data.inv = 0
        data.invspace = true
      else
        data.invspace = false
      end
    end
  end

  if data.power == 0 then
    data.frameY = 0
  else
    data.frameY = 1
  end

  redstone.resetPower(n)
end

hopper.onRedDraw = redstone.drawNPC

redstone.register(hopper)

return hopper
