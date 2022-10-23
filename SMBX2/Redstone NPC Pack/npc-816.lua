local flamethrower = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

flamethrower.name = "flamethrower"
flamethrower.id = NPC_ID

flamethrower.test = function()
  return "isFlamethrower", function(x)
    return (x == flamethrower.name or x == flamethrower.id)
  end
end

flamethrower.onRedPower = function(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

flamethrower.onRedInventory = function(n, c, inv, dir, hitbox)
  local data = n.data

  data.angleList = {inv}
  data.angleCurr = 1
  data.invspace = false
end

flamethrower.config = npcManager.setNpcSettings({
	id = flamethrower.id,

  width = 32,
  height = 32,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 4,
	framespeed = 8,
	framestyle = 0,
  invisible = false,

  nogravity = true,
  notcointransformable = true,
  noblockcollision = true,
	jumphurt = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true,
})

local sfxfire = 16

function flamethrower.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data.frameX or 0
  data.frameY = data.frameY or 0

  data.angleList = redstone.parseNumList(data._settings.angle or "0")
  data.angle = data.angleList[1]
  data.angleCurr = 1
  data.invspace = true

  data.redarea = data.redarea or Colliders.Box(0, 0, n.width + 4, n.height + 2)
  data.redhitbox = redstone.basicDirectionalRedHitBox(n, 3)
end

function flamethrower.onRedTick(n)
  if Defines.levelFreeze then return end
  redstone.setLayerLineguideSpeed(n)

  local data = n.data
  data.observ = false

  data.redarea.x, data.redarea.y = n.x - 2, n.y - 1

  -- Melt any ice blocks that are in the way
  local iceList = Colliders.getColliding{a = data.redarea, b = redstone.iceBlock_MAP, btype = Colliders.BLOCK, filter = function(b)
    if not b.isHidden then
      redstone.iceBlock[b.id](b, n)
    end
  end}

  if data.power > 0 and data.powerPrev == 0 then
    data.invspace = true

    data.angle = data.angleList[data.angleCurr]
    data.angleCurr = data.angleCurr + 1
    if data.angleCurr > #data.angleList then
      data.observ = true
      data.angleCurr = 1
    end

    if redstone.onScreenSound(n) then
      SFX.play(sfxfire)
    end
    local e = Animation.spawn(10, n.x + 0.5*n.width - 16, n.y + 0.5*n.height - 16)
    local v = NPC.spawn(redstone.component.flame.id, n.x, n.y, n:mem(0x146, FIELD_WORD))
    v.x = v.x + 0.5*(n.width - v.width)
    v.y = v.y + 0.5*(n.height - v.height)
    v.data.angle = data.angle
    v.data.parent = n
    v.data.immuneparent = true
    redstone.component.flame.prime(v)
  end

  redstone.updateDirectionalRedHitBox(n, 3)
  local passed = redstone.passInventory{source = n, npcList = redstone.component.hopper.id, inventory = data.angle, hitbox = data.redhitbox}


  redstone.resetPower(n)
end

function flamethrower.onTick()
  for k, p in ipairs(Player.get()) do
    local list = Colliders.getColliding{a = Colliders.Box(p.x - 2, p.y - 2, p.width + 4, p.height + 4), b = flamethrower.id, btype = Colliders.NPC, filter = redstone.nofilter}
    if list[1] then
      p:harm()
    end
  end
end

flamethrower.onRedDraw = redstone.drawNPC

function flamethrower.onInitAPI()
  registerEvent(flamethrower, "onTick", "onTick")
end

redstone.register(flamethrower)

return flamethrower
