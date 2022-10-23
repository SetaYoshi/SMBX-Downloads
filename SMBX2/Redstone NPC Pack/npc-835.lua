local absorber = {}

local redstone = require("redstone")
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

absorber.name = "absorber"
absorber.id = NPC_ID

absorber.test = function()
  return "isAbsorber", function(x)
    return (x == absorber.name or x == absorber.id)
  end
end

absorber.onRedPower = function(n, c, p, d, hitbox)
	if redstone.isChip(c.id) or redstone.isBeamSource(c.id) then
		redstone.setEnergy(n, p)
	end
end

absorber.config = npcManager.setNpcSettings({
	id = absorber.id,

  width = 32,
  height = 32,

	gfxwidth = 32,
	gfxheight = 32,
  gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 1,
	framespeed = 4,
	framestyle = 0,
	invisible = false,

	score = 0,
	jumphurt = true,
	spinjumpsafe = false,
	nohurt = true,
	noyoshi=true,
	grabside = false,
	harmlessthrown=false,
  noblockcollision = true,
	noiceball=false,
	nofireball=false,
	nogravity = true,
})
npcManager.registerHarmTypes(absorber.id, {})

local colorlist = {Color.white, Color.red..0.8, Color(1, 0.42, 0, 0.8), Color.purple..0.8, Color.purple..0.8}

function absorber.prime(n)
  local data = n.data

	data.frameX = data._settings.color
  data.frameY = data.frameY or 0

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

	data.color = colorlist[data._settings.color + 1]
	data.collision = Colliders.Circle(n.x + 0.5*n.width, n.y + 0.5*n.height, n.width*0.5)
	data.collision.colormydata = data.color

	data.redarea = data.redarea or redstone.basicRedArea(n)
	data.redhitbox = data.redhitbox or redstone.basicRedHitBox(n)
end

function absorber.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power == 0 then
		data.frameY = 0
	else
		data.frameY = 1

		redstone.updateRedArea(n)
		redstone.updateRedHitBox(n)
		redstone.passEnergy{source = n, power = 15, hitbox = data.redhitbox, area = data.redarea}
	end

  if (data.power ~= 0 and data.powerPrev == 0) or (data.power == 0 and data.powerPrev ~= 0) then
    data.observ = true
  end

	redstone.resetPower(n)
end

absorber.onRedDraw = redstone.drawNPC

redstone.register(absorber)

return absorber
