local lever = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

lever.name = "lever"
lever.id = NPC_ID

lever.test = function()
  return "isLever", function(x)
    return (x == lever.id or x == lever.name)
  end
end

lever.onRedPower = function(n, c, power, dir, hitbox)
  return true
end

lever.config = npcManager.setNpcSettings({
	id = lever.id,

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
	nogravity = false,
  notcointransformable = true,
  nohurt = true,
	noblockcollision = 0,
	nofireball = 1,
	noiceball = 1,
	noyoshi = 1,
	speed = 0,
  npcblock = true,
	iswalker = true
})
npcManager.registerHarmTypes(lever.id, {HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP}, {[HARM_TYPE_JUMP] = 10, [HARM_TYPE_SPINJUMP] = 10})

local sfxtoggle = 2

function lever.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data.frameX or 0
  data.frameY = data.frameY or 0

  data.isOn = data._settings.state == 1
  data.cooldown = data.cooldown or 0

  data.redarea = data.redarea or redstone.basicRedArea(n)
  data.redhitbox = data.redhitbox or redstone.basicRedHitBox(n)
end

function lever.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.cooldown > 0 then
    data.cooldown = data.cooldown - 1
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

lever.onRedDraw = redstone.drawNPC

function lever.onNPCHarm(event, n, reason, culprit)
	if n.id == lever.id and (reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP) then
    if n.data.cooldown == 0 then
      n.data.isOn = not n.data.isOn
      n.data.observ = true
      n.data.cooldown = 5
      if redstone.onScreenSound(n) then
        SFX.play(sfxtoggle)
      end
    end
    event.cancelled = true
  end
end

function lever.onInitAPI()
	registerEvent(lever, "onNPCHarm", "onNPCHarm")
end

redstone.register(lever)

return lever
