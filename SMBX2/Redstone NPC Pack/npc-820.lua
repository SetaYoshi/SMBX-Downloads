local tnt = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local floor = math.floor

tnt.name = "tnt"
tnt.id = NPC_ID

tnt.test = function()
  return "isTnt", function(x)
    return (x == tnt.name or x == tnt.id)
  end
end

tnt.onRedPower = function(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

tnt.config = npcManager.setNpcSettings({
	id = tnt.id,

  width = 32,
  height = 32,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 2,
	framespeed = 8,
	framestyle = 0,
  invisible = false,

  nogravity = false,
	jumphurt = true,
  notcointransformable = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true,

  effectid = 800, -- The explosion effect ID
  explosionradius = 128,    -- The radius of the explosion
  explosiontimer = 130,  -- The time it takes for the bomb to explode
  destroyblock = false    -- If set to true, the explosion will destory blocks (when false, certain blocks like brick blocks still explode)
})

local TYPE_TNT = 0
local TYPE_MINECART = 1

local sfxcharge = Audio.SfxOpen(Misc.resolveFile("tnt-charge.ogg"))
local sfxexplode  = Audio.SfxOpen(Misc.resolveFile("tnt-explosion.ogg"))

function tnt.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.type or 0
  data.frameY = data.frameY or 0

  data.timer = data.timer or 0
  data.isFused = data.isFused or false
  data.beenBlowned = data.beenBlowned or false
  data.blownedTimer = data.blownedTimer or 0

  data.explosionhitbox = Colliders.Circle(0, 0, tnt.config.explosionradius)
  data.redarea = redstone.basicRedArea(n)
end

local function explode(n)
  local data = n.data

  SFX.play(sfxexplode)
  data.explosionhitbox.x, data.explosionhitbox.y = n.x + 0.5*n.width, n.y + 0.5*n.height
  local e = Effect.spawn(tnt.config.effectid, data.explosionhitbox.x, data.explosionhitbox.y)
  e.x, e.y = e.x - 0.5*e.width, e.y - 0.5*e.height

  for _, v in ipairs(Colliders.getColliding{a = data.explosionhitbox, b = NPC.ALL, btype = Colliders.NPC, filter = function(v) return v ~= n and not v.isHiddend end}) do
    if v.id == tnt.id then
      local vdata = v.data
      if vdata.isFused then
        vdata.timer = 0
      else
        vdata.beenBlowned = true
        vdata.blownedTimer = 5
        if vdata.frameX == TYPE_TNT then
          vdata.timer = floor(tnt.config.explosiontimer*0.5)
        elseif vdata.frameX == TYPE_MINECART then
          vdata.timer = 5
        end
      end
    end
    redstone.explosionNPCAI(v, n)
  end
  for _, b in ipairs(Colliders.getColliding{a = data.explosionhitbox, b = Block.ALL, btype = Colliders.BLOCK, filter = function(v) return not v.isHidden end}) do
    redstone.explosionBlockAI(b, n)
  end
  for _, p in ipairs(Player.get()) do
    if Colliders.collide(data.explosionhitbox, p) then
      redstone.explosionPlayerAI(p, n)
    end
  end

  n:kill()
end

local function explodeOnContact(n)
  local data = n.data
  redstone.updateRedArea(n)
  for _, p in ipairs(Player.get()) do
    if Colliders.collide(data.redarea, p) then
      data.isFused = true
      data.timer = 5
      break
    end
  end
end

function tnt.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.frameX == TYPE_TNT then
    if data.isFused then
      redstone.applyFriction(n)
    else
      n.speedY = -Defines.npc_grav
    end
  elseif data.frameX == TYPE_MINECART then
    if data.isFused then
      n.speedX = 0
    else
      n.speedX = n.direction*tnt.config.speed
    end
  end

  if data.frameX == TYPE_MINECART and not data.isFused then
    explodeOnContact(n)
  end

  if data.beenBlowned then
    data.blownedTimer = data.blownedTimer - 1
    if data.blownedTimer <= 0 then
      data.beenBlowned = false
      data.isFused = true
    end
  elseif data.isFused then
    data.timer = data.timer - 1
    if data.timer <= 0 then
      explode(n)
    end
  elseif data.power > 0 then
      SFX.play(sfxcharge)
      if data.frameX == TYPE_TNT then
        data.timer = tnt.config.explosiontimer
      elseif data.frameX == TYPE_MINECART then
        data.timer = 5
      end
      data.isFused = true
      data.observ = true
  end

  if data.isFused then
    data.frameY = 1
  else
    data.frameY = 0
  end

  redstone.resetPower(n)
end

tnt.onRedDraw = redstone.drawNPC

redstone.register(tnt)

return tnt
