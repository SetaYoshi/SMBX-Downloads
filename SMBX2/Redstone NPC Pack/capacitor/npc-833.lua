local capacitor = {}

local redstone = require("redstone")
local npcManager = require("npcManager")
local textplus = require("textplus")

local floor = math.floor

capacitor.name = "capacitor"
capacitor.id = NPC_ID
capacitor.order = 0.38

capacitor.onRedPower = function(n, c, power, dir, hitbox)
  local data = n.data
  
  if dir == -1 or dir == n.data.frameX or redstone.is.operator(c.id) then
    redstone.setEnergy(n, power)
  elseif redstone.is.repeater(c.id) and (dir == (data.frameX + 1)%4 or dir == (data.frameX - 1)%4) then
    data.updateCounter = true
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
  mute = false,

  nogravity = true,
  notcointransformable = true,
	jumphurt = true,
  noblockcollision = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true,

  showCounter = true,
})

local sfxcharge =  Audio.SfxOpen(Misc.resolveFile("capacitor-charge.ogg"))
local sfxcharged =  Audio.SfxOpen(Misc.resolveFile("capacitor-charged.ogg"))

local function updateCounter(n)
  local data = n.data

  if data.capacitance < data.maxcapacitance then
    data.counterTimer = 64
    data.capacitance = data.capacitance + 1
    if data.capacitance < data.maxcapacitance then
      SFX.play(sfxcharge)
    end
  end

  if not data.unlocked and data.capacitance >= data.maxcapacitance then
    data.unlocked = true

    redstone.spawnEffect(10, n)
    if redstone.onScreenSound(n) then
      SFX.play(sfxcharged)
    end
  end
end

function capacitor.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.dir or 0
  data.frameY = data.frameY or 0

  data.capacitance = 0
  data.maxcapacitance = data._settings.capacitance + 1
  data.unlocked = data.unlocked or false
  data.updateCounterPrev = data.updateCounterPrev or false
  data.updateCounter = data.updateCounter or false
  data.invspace = true
  data.counterTimer = data.counterTimer or 0

  data.redhitbox = data.redhitbox or redstone.basicDirectionalRedHitBox(n, data.frameX)
end

function capacitor.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.counterTimer > 0 then
    data.counterTimer = data.counterTimer - 1
  end

  if data.power == 0 and data.powerPrev > 0 then
    data.invspace = true
  end

  if data.updateCounter and not data.updateCounterPrev then
    updateCounter(n)
  end

  if data.power > 0 then
    if data.powerPrev == 0 then
      updateCounter(n)
    end

    if data.unlocked then
      redstone.updateDirectionalRedHitBox(n, data.frameX)
      redstone.passDirectionEnergy{source = n, power = data.power, hitbox = data.redhitbox}
    end
  end


  data.observpower = floor(15*data.capacitance/data.maxcapacitance)
  if data.observpower > 0 then
    data.observ = true
  end

  if data.power == 0 then
    data.frameY = 0
  elseif data.capacitance >= data.maxcapacitance then
    data.frameY = 2
  else
    data.frameY = 1
  end

  data.updateCounterPrev = data.updateCounter
  data.updateCounter = false

  redstone.resetPower(n)
end

function capacitor.onRedDraw(n)
  local data = n.data

  redstone.drawNPC(n)

  if data.counterTimer > 0 and capacitor.config.showCounter and not capacitor.config.invisible then
    local v = data.maxcapacitance - data.capacitance
    local color = Color.white
    if v == 0 then
      v = "!"
      color = Color.red
    else
      v = tostring(v)
    end
    textplus.print{text = v, sceneCoords = true, x = n.x + 0.5*n.width, y = n.y - 2 - 4*math.sin(4*lunatime.time()), pivot = {0.5, 1}, xscale = 2, yscale = 2, color = color}
  end
end

redstone.register(capacitor)

return capacitor
