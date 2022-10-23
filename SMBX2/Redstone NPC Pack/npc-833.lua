local capacitor = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local floor = math.floor

capacitor.name = "capacitor"
capacitor.id = NPC_ID

capacitor.test = function()
  return "isCapacitor", function(x)
    return (x == capacitor.id or x == capacitor.name)
  end
end

capacitor.onRedPower = function(n, c, power, dir, hitbox)
  if dir == -1 or dir == n.data.frameX or redstone.isOperator(c.id) then
    redstone.setEnergy(n, power)
  else
    return true
  end
end

capacitor.onRedInventory = function(n, c, inv, dir, hitbox)
  n.data.maxcapacitance = inv
  n.data.invspace = false
end

capacitor.config = npcManager.setNpcSettings({
	id = capacitor.id,

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


function capacitor.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.dir or 0
  data.frameY = data.frameY or 0

  data.capacitance = 0
  data.maxcapacitance = data._settings.capacitance
  data.unlocked = data.unlocked or false
  data.invspace = true

  data.redhitbox = data.redhitbox or redstone.basicDirectionalRedHitBox(n, data.frameX)
end

function capacitor.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 then
    if data.unlocked then
      redstone.updateDirectionalRedHitBox(n, data.frameX)
      redstone.passDirectionEnergy{source = n, power = data.power, hitbox = data.redhitbox}
    elseif data.powerPrev == 0 then
      data.capacitance = data.capacitance + 1
    end
  end

  if data.power == 0 and data.powerPrev > 0 then
    data.invspace = true
    if data.capacitance >= data.maxcapacitance then
      data.unlocked = true
    end
  end

  data.observpower = floor(15*data.capacitance/data.maxcapacitance)
  if data.observpower > 0 then
    data.observ = true
  end

  if data.power == 0 then
    data.frameY = 0
  elseif data.capacitance > data.maxcapacitance then
    data.frameY = 2
  else
    data.frameY = 1
  end

  redstone.resetPower(n)
end

capacitor.onRedDraw = redstone.drawNPC

redstone.register(capacitor)

return capacitor
