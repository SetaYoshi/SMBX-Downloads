local reflector = {}

local redstone = require("redstone")
local npcManager = require("npcManager")
local lineguide = require("lineguide")
local utils = require("npcs/npcutils")

reflector.name = "reflector"
reflector.id = NPC_ID
reflector.order = 0.28

reflector.onRedPower = function(n, c, power, dir, hitbox)
  if redstone.is.sickblock(c.id) or redstone.is.deadsickblock(c.id) then
    n.data.isOn = false
    n.data.deadTimer = 4
    n.data.frameY = 1
  else
    redstone.setEnergy(n, power)
  end
end

reflector.onRedInventory = function(n, c, inv, dir, hitbox)
  local data = n.data

  data.angleList = {inv}
  data.angleCurr = 1
end

reflector.config = npcManager.setNpcSettings{
	id = reflector.id,

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

	score = 0,
	blocknpctop = false,
	playerblocktop = false,
	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	spinjumpsafe = false,
	jumphurt = true,
	ignorethrownnpcs = true,
	notcointransformable = true,
	staticdirection = true,

  thickness = 4, -- The thickness of the reflector image
}

lineguide.registerNpcs(reflector.id)


function reflector.prime(n)
	local data = n.data
	local img = Graphics.sprites.npc[reflector.id].img

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.type or 0
  data.frameY = data.frameY or 0

  if data.isOn == nil then data.isOn = true end
  data.isOnPrev = data.isOn
  data.deadTimer = data.deadTimer or 0
  data.angleList = redstone.parseNumList(data._settings.angle or "0")
  data.angle = data.angleList[1]
  data.angleCurr = 1

  local w, h = utils.gfxwidth(n), utils.gfxheight(n)
  local sprite = Sprite{x = n.x, y = n.y, width = w, height = h, texture = img, pivot = Sprite.align.CENTER}
  data.sprite = sprite
  data.sprite.rotation = -data.angle
  sprite.texscale = vector(img.width, img.height)

  data.collision = Colliders.Rect(n.x + 0.5*n.width, n.y + 0.5*n.height, reflector.config.thickness, h, -data.angle)
  data.collision.reflector = n

  data.invspace = true
end

function reflector.onRedTick(n)
  local data = n.data
  data.observ = false

	redstone.setLayerLineguideSpeed(n)

	if n:mem(0x136, FIELD_BOOL) then  -- NPC is being thrown
		n.speedX, n.speedY = 0, 0
	end

  if data.power > 0 and data.powerPrev == 0 then
    data.angleCurr = data.angleCurr + 1
    if data.angleCurr > #data.angleList then
      data.observ = true
      data.angleCurr = 1
    end
    data.angle = data.angleList[data.angleCurr]
  end

  if data.angle ~= data.anglePrev then
    data.sprite.rotation = -data.angle
    data.collision.rotation = -data.angle
  end

  if data.deadTimer > 0 then
    data.deadTimer = data.deadTimer - 1
    if data.deadTimer == 0 then
      data.isOn = true
      data.frameY = 0
    end
  end

  if data.isOn ~= data.isOnPrev then
    data.observ = true
  end

  data.isOnPrev =  data.isOn
  data.anglePrev = data.angle
  redstone.resetPower(n)
end

function reflector.onRedDraw(n)
	local data = n.data

	if n.despawnTimer <= 0 or not data.sprite then return end
  local sprite = data.sprite

	sprite.x = n.x + n.width*0.5 + reflector.config.gfxoffsetx
	sprite.y = n.y + n.height*0.5 + reflector.config.gfxoffsety

	local p = -45
	if reflector.config.foreground then
		p = -15
	end

  local y = sprite.texposition.y
  sprite.texposition.y = y - utils.gfxheight(n)*data.animFrame - data.frameY*reflector.config.gfxheight
  sprite:draw{priority = p, sceneCoords = true}
	sprite.texposition.y = y

  n.animationFrame = -99
  n.animationTimer = -99
end

redstone.register(reflector)

return reflector
