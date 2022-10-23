local button = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

button.name = "button"
button.id = NPC_ID

button.test = function()
  return "isButton", function(x)
    return (x == button.id or x == button.name)
  end
end

button.onRedPower = function(n, c, power, dir, hitbox)
  return true
end

button.config = npcManager.setNpcSettings({
	id = button.id,

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
  mute = false,

  jumphurt = 0,
  nohurt = true,
  notcointransformable = true,
	nogravity = false,
	noblockcollision = 0,
	nofireball = 1,
	noiceball = 1,
	noyoshi = 1,
	speed = 0,
  npcblock = true,
	iswalker = true
})
npcManager.registerHarmTypes(button.id, {HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP}, {[HARM_TYPE_JUMP] = 10, [HARM_TYPE_SPINJUMP] = 10})

local sfxtoggle = 2

local TYPE_NORMAL = 0
local TYPE_DETERIORATED = 1

function button.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.type or 0
  data.frameY = data.frameY or 0

  data.delay = (data._settings.delay or 2)*10
  data.countdown = data.countdown or 0
  data.isOn = (data._settings.state == 1)
  if data.isOn then
    data.countdown = n.data.delay
  end

  data.redarea = data.redarea or redstone.basicRedArea(n)
  data.redhitbox = data.redhitbox or redstone.basicRedHitBox(n)
end

function button.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.countdown > 0 then
    data.countdown = data.countdown - 1
    if data.countdown == 0 then
      data.observ = true
      data.isOn = false

      if data.frameX == TYPE_DETERIORATED then
        n:kill()
      end
    end
  end

  if data.isOn then
    redstone.updateRedArea(n)
    redstone.updateRedHitBox(n)
    redstone.passEnergy{source = n, power = 15, hitbox = data.redhitbox, area = data.redarea}
  end

  if data.isOn then
    data.frameY = 1
  else
    data.frameY = 0
  end
end

button.onRedDraw = redstone.drawNPC

function button.onNPCHarm(event, n, reason, culprit)
  if n.id == button.id and (reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP) then
    local data = n.data

    data.isOn = true
    if data.countdown == 0 then
      data.observ = true
      data.observTimer = 1
    end
    if data.frameX == TYPE_NORMAL or (data.frameX == TYPE_DETERIORATED and data.countdown == 0) then
      data.countdown = data.delay
    end

    if redstone.onScreenSound(n) then
      SFX.play(sfxtoggle)
    end

    event.cancelled = true
  end
end

function button.onInitAPI()
	registerEvent(button, "onNPCHarm", "onNPCHarm")
end

redstone.register(button)

return button
