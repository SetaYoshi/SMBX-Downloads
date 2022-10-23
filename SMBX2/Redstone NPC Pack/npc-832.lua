local reaper = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local insert, remove = table.insert, table.remove

reaper.name = "reaper"
reaper.id = NPC_ID

reaper.test = function()
  return "isReaper", function(x)
    return (x == reaper.id or x == reaper.name)
  end
end

reaper.onRedPower = function(n, c, power, dir, hitbox)
  if redstone.isOperator(c.id) and dir == (n.data.frameX + 2)%4 then
    n.data.isOn = true
    redstone.setEnergy(n, power)
  else
    return true
  end
end

reaper.config = npcManager.setNpcSettings({
	id = reaper.id,

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

  soulspeed = 6,       -- The speed at which the souls travel at
  disablesoulanim = false,  -- Set to true to disable the soul effect animation
})

local isoul = Graphics.loadImage(Misc.resolveFile("npc-"..reaper.id.."-1.png"))
local sfxeat = Audio.SfxOpen(Misc.resolveFile("reaperblock-consume.ogg"))
local sfxeatfast = Audio.SfxOpen(Misc.resolveFile("reaperblock-consumefast.ogg"))
local ribbontail = Misc.resolveFile("npc-"..reaper.id.."-ribbon.ini")
local ribbonlist = {}

local function hasSoul(n, soulNPC)
  local data = n.data
  if data.whitelist then return data.whitelist[soulNPC.id] end
  return redstone.hasSoul(soulNPC)
end

local function canKill(soulNPC)
  return redstone.hasSoul(soulNPC)
end

local function exposeSoul(n, soulNPC, dist)
  local data = n.data

  if reaper.config.disablesoulanim then
    data.queque = data.queque + 1
  else
    local soul = {x = soulNPC.x + soulNPC.width*0.5, y = soulNPC.y + soulNPC.height*0.5, ribbon = Particles.Ribbon(0, 0, ribbontail)}
    soul.ribbon.x, soul.ribbon.y = soul.x, soul.y
    soul.ribbon:Emit(1)
    insert(data.souls, soul)
  end
  if redstone.onScreenSound(n) then
    if dist^2 < 160 then
      SFX.play(sfxeatfast)
    else
      SFX.play(sfxeat)
    end
  end
end

local function collisionBox(n, d)
  if d == 0 then
    return n.x - 2, n.y + 2, 2, n.height - 4
  elseif d == 1 then
    return n.x + 2, n.y - 2, n.width - 4, 2
  elseif d == 2 then
    return n.x + n.width, n.y + 2, 2, n.height - 4
  else
    return n.x + 2, n.y + n.height, n.width - 4, 2
  end
end

local function scanNPC(n)
  local x, y, w, h = collisionBox(n, n.data.frameX)
  for _, v in ipairs(NPC.getIntersecting(x, y, x + w, y + h)) do
    if v.isValid and not v.isHidden and canKill(v) then
      redstone.spawnEffect(10, v)
      v:kill()
    end
  end
end

local function updateSouls(n)
  local data = n.data

  local cx, cy = n.x + 0.5*n.width, n.y + 0.5*n.height
  for i = #data.souls, 1, -1 do
    local soul = data.souls[i]
    local v = vector.v2(cx - soul.x, cy -  soul.y)
    if v.length < reaper.config.soulspeed then
      data.queque = data.queque + 1
      soul.ribbon.enabled = false
      soul.ribbon:Break()
      insert(ribbonlist, soul.ribbon)
      remove(data.souls, i)
    else
      v = v:normalize()*reaper.config.soulspeed
      soul.x, soul.y = soul.x + v.x, soul.y + v.y
      soul.ribbon.x, soul.ribbon.y = soul.x, soul.y
    end
  end
end

local function passPower(n, power)
  local data = n.data

  redstone.updateDirectionalRedHitBox(n, (data.frameX + 2)%4)
  redstone.passDirectionEnergy{source = n, power = power, hitbox = data.redhitbox}
end

function reaper.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.dir or 0
  data.frameY = data.frameY or 0

  data.isOn = data.isOn or false
  data.prevState = data.prevState or false
  data.onTimer = data.onTimer or 0
  data.cooldown = data.cooldown or 0
  data.souls = data.souls or {}
  data.queque = data.queque or 0
  data.whitelist = data.whitelist or redstone.parseList(data._settings.whitelist)

  data.redhitbox = redstone.basicDirectionalRedHitBox(n, (data.frameX + 2)%4)
end

function reaper.onRedTick(n)
  local data = n.data
  data.observ = false

  if #data.souls > 0 then
    updateSouls(n)
  end

  if data.power > 0 or n.data.isOn then
    passPower(n, data.power)
  elseif data.queque > 0 then
    data.isOn = true

    if data.cooldown == 0 then
      data.onTimer = data.onTimer + 1
      if data.onTimer > 5 then
        data.onTimer = 0
        data.cooldown = 5
        data.queque = data.queque - 1
      end
    else
      data.isOn = false
      data.cooldown = data.cooldown - 1
    end

    if data.isOn then
      passPower(n, 15)
    end
  end

  scanNPC(n)

  if not data.isOn and data.prevState then
    data.observ = true
  end

  if data.isOn or #data.souls > 0  then
    data.frameY = 1
  else
    data.frameY = 0
  end

  data.prevState = data.isOn
  data.isOn = false
  redstone.resetPower(n)
end

function reaper.onRedDraw(n)
  redstone.drawNPC(n)

  if reaper.config.invisible then return end
  if #n.data.souls > 0 then
    local hw, hh = isoul.width*0.5, isoul.height*0.5
    for _, s in ipairs(n.data.souls) do
      Graphics.drawImageToScene(isoul, s.x - hw, s.y - hh)
      s.ribbon:Draw(-60)
    end
  end
end

function reaper.onDraw()
  if reaper.config.invisible then return end

  -- Draw all the dead ribbons
  for k = #ribbonlist, 1, -1 do
    local p = ribbonlist[k]
    if p:Count() > 0 then
      p:Draw(-60)
    else
      remove(ribbonlist, k)
    end
  end
end

function reaper.onPostNPCKill(soulNPC, reason)
  local list = Colliders.getColliding{a = Colliders.Box(soulNPC.x - 800, soulNPC.y - 600, 1600 + soulNPC.width, 1200 + soulNPC.height), b = reaper.id, btype = Colliders.NPC, filter = redstone.nofilter}
  if list then
    local closest = -1
    local reaperNPC
    for _, v in ipairs(list) do
      local dist = (v.x + 0.5*v.width - soulNPC.x - 0.5*soulNPC.width)^2 + (v.y + 0.5*v.height - soulNPC.y - 0.5*soulNPC.height)^2
      if (closest == -1 or dist < closest) and hasSoul(v, soulNPC) then
        closest = dist
        reaperNPC = v
      end
    end
    if reaperNPC then
      exposeSoul(reaperNPC, soulNPC, closest)
    end
  end
end

function reaper.onInitAPI()
  registerEvent(reaper, "onDraw", "onDraw")
	registerEvent(reaper, "onPostNPCKill", "onPostNPCKill")
end

redstone.register(reaper)

return reaper
