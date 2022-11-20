local tnt = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local floor = math.floor

tnt.name = "tnt"
tnt.id = NPC_ID
tnt.order = 0.66

tnt.onRedPower = function(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

tnt.onDispense = function(n)
  n.data.isFused = true
  n.data.timer = tnt.config.explosiontimer
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



-- What should an NPC do when hit by an explosion
local function tntNPCFilter(v)
  return not v.isGenerator and not v.isHidden and not v.friendly and v:mem(0x124, FIELD_BOOL) and v.id ~= 13 and v.id ~= 291 and not NPC.config[v.id].isinteractable
end

local function onExplosionNPC(n, tnt)
  if tntNPCFilter(n) then
    n:harm(HARM_TYPE_NPC)
  end

  if redstone.is.sickblock(n.id) then
    redstone.setEnergy(n, 15)
  elseif not NPC.config[n.id].nogravity then
    local t = vector.v2(n.x + 0.5*n.width - tnt.data.explosionhitbox.x, n.y + 0.5*n.height - tnt.data.explosionhitbox.y)
    t = 6*t:normalise()
    n.speedX, n.speedY = clamp(n.speedX + t.x, -8, 8), clamp(1.1*(n.speedY + t.y), -8, 8)
  end
end

-- What should a block do when hit by an explosion
local function onExplosionBlock(b, tnt)
  if (Block.SOLID_MAP[b.id] or Block.SEMISOLID_MAP[b.id]) and not Block.SIZEABLE_MAP[b.id] then
    if tnt.config.destroyblock then
      b:remove(true)
    else
      if Block.config[b.id].smashable ~= 3 then
        b:hit()
      else
        b:remove(true)
      end
    end
  end
end

-- What should a player do when hit by an explosion
local function onExplosionPlayer(p, tnt)
  if not p:mem(0x4A, FIELD_BOOL) then -- In statue form
    p:harm()
    local t = vector.v2(p.x + 0.5*p.width - tnt.data.explosionhitbox.x, p.y + 0.5*p.height - tnt.data.explosionhitbox.y)
    t = 8*t:normalise()
    if p:isGroundTouching() and t.y < 0 then
      p.y = p.y - 4
      p:mem(0x146, FIELD_WORD, 0)
    end
    p.speedX, p.speedY = clamp(p.speedX + t.x, -12, 12), clamp(1.1*(p.speedY + t.y), -15, 15)
  end
end



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
    onExplosionNPC(v, n)
  end
  for _, b in ipairs(Colliders.getColliding{a = data.explosionhitbox, b = Block.ALL, btype = Colliders.BLOCK, filter = function(v) return not v.isHidden end}) do
    onExplosionBlock(b, n)
  end
  for _, p in ipairs(Player.get()) do
    if Colliders.collide(data.explosionhitbox, p) then
      onExplosionPlayer(p, n)
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
