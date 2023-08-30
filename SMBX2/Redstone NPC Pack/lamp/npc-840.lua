-- v1.3.0

local lamp = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

lamp.name = "reddoor"
lamp.id = NPC_ID
lamp.order = 0.51

lamp.onRedPower = function(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

lamp.config = npcManager.setNpcSettings({
	id = lamp.id,

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
  npcblock = true,
  disabledespawn = false,

  lightradius = 64,
})

local colorList = {
  Color.red,
  Color.orange,
  Color.yellow,
  Color.green,
  Color.blue,
  Color.purple,
}


function lamp.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.color or 0
  data.frameY = data.frameY or 0

  data.darkness = data.darkness or Darkness.Light(0, 0, lamp.config.lightradius, data._settings.brightness, colorList[data.frameX + 1])
	Darkness.addLight(data.darkness)
  data.darkness:attach(n)
  data.darkness.enabled = false
end

function lamp.onRedTick(n)
  local data = n.data
  data.observ = false

  data.darkness.x, data.darkness.y = n.x + 0.5*n.width, n.y + 0.5*n.height


  if (data.power > 0 and data.powerPrev == 0) or (data.power == 0 and data.powerPrev > 0) then
    data.observ = true

    if redstone.onScreenSound(n) then
      if data.power == 0 then
        data.darkness.enabled = false
      else
        data.darkness.enabled = true
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

lamp.onRedDraw = redstone.drawNPC

redstone.register(lamp)

return lamp
