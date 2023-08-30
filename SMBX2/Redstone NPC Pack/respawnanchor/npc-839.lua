-- v1.3.0

local respawnanchor = {}

local redstone = require("redstone")
local npcManager = require("npcManager")
local cps = require("checkpoints")
local cpai = require("npcs/AI/checkpoints")

respawnanchor.name = "respawnanchor"
respawnanchor.id = NPC_ID
respawnanchor.order = 0.54


local sin, floor, ceil = math.sin, math.floor, math.ceil

local TYPE_ANCHOR = 0
local TYPE_HOST = 1

local portalLen = 12
local killed_all = false

local gfxportal = Graphics.loadImageResolved("npc-"..respawnanchor.id.."-3.png")

local sfxactivate1 = Audio.SfxOpen(Misc.resolveFile("respawnanchor-activate-1.ogg"))
local sfxactivate2 = Audio.SfxOpen(Misc.resolveFile("respawnanchor-activate-2.ogg"))

local sfxbreak = Audio.SfxOpen(Misc.resolveFile("respawnanchor-break.ogg"))
local sfxkill = Audio.SfxOpen(Misc.resolveFile("respawnanchor-kill.ogg"))

local psmoke = {
  Misc.resolveFile("npc-"..respawnanchor.id.."-particle-1.ini"),
  Misc.resolveFile("npc-"..respawnanchor.id.."-particle-2.ini"),
} 

cps.registerNPC(respawnanchor.id)
cpai.addID(respawnanchor.id, true)

respawnanchor.onRedPower = function(n, c, power, dir, hitbox)
  if redstone.is.sickblock(c.id) or redstone.is.deadsickblock(c.id) then
    if n.data.frameX == TYPE_ANCHOR then
      if n.data.frameY == 1 then
        SFX.play(sfxbreak)
        n.data._basegame.checkpoint:reset()
      end
    elseif n.data.frameX == TYPE_HOST then
      SFX.play(sfxbreak)
      n.data.deathActive = false
    end
  else
    redstone.setEnergy(n, power)
  end
end

respawnanchor.config = npcManager.setNpcSettings({
	id = respawnanchor.id,

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
  noblockcollision = true,
  notcointransformable = true,
	jumphurt = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true,
  disabledespawn = false,
  spawnoffsety = -32,

  portalframes = 4,
  portalframespeed = 8,
})


local function killPlayer(p)
  local bomb = NPC.spawn(134, p.x, p.y)
  for i = 0, 1, 0.1 do
    bomb.speedY = 0
    bomb.x = p.x + 0.5*p.width - 0.5*bomb.width
    bomb.y = (p.y - 32) + i*(p.height + 32 - bomb.height)
    bomb.ai1, bomb.ai2 = 0, 1
    Routine.skip()
  end
  bomb.ai1 = -15
  p:kill()
end

local function spiralEffect(emitter)
  local particles = emitter.particles

  for k, p in ipairs(particles) do
    if not p.spiral then
      p.spiral = vector(0, 0.8):rotate(RNG.random(360))
    end

    p.spiral = p.spiral:rotate(2*(p.ttl/p.initTtl))

    -- p.speedX, p.speedY = p.spiral.x, p.spiral.y
    p.x = p.x + p.spiral.x
    p.y = p.y + p.spiral.y
  end
end

local function drawPortal(n, p)
  local framespeed = respawnanchor.config.portalframespeed
  local frames = respawnanchor.config.portalframes
  local frame = floor((lunatime.tick()%(frames*framespeed))/framespeed)
  
  local pos = vector(p.x + 0.5*p.width, p.y - gfxportal.height/frames - 4 - 4*sin(lunatime.tick()*0.05))
  local wr, hr = 0.5*vector((portalLen - n.data.deathTrans)/portalLen*gfxportal.width, 0), 0.5*vector(0, 1*gfxportal.height/frames)
  
  local m1, m2 = pos - wr, pos + wr
  
  local z1, z2, z3, z4 = m1 - hr, m1 + hr, m2 - hr, m2 + hr
  local tx, ty, tw, th = 0, frame/frames, 1, (1 + frame)/frames
  
  
  Graphics.glDraw{
    texture = gfxportal,
    priority = 0,
    opacity = 1,
    vertexCoords = {z1.x, z1.y, z2.x, z2.y, z3.x, z3.y, z4.x, z4.y},
    textureCoords = {tx, ty, tx, th, tw, ty, tw, th},
    primitive = Graphics.GL_TRIANGLE_STRIP,
    sceneCoords = true,
  }
end

function respawnanchor.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.type or 0
  data.frameY = data.frameY or 0

  data.pistImmovable = true

	data._basegame.checkpoint.powerup = nil
	data._basegame.checkpoint.sound = nil

  data.deathDelay = data._settings.delay
  data.deathTimer = data.deathDelay
  data.deathActive = false
  data.deathTrans = portalLen
  
  data.particle = Particles.Emitter(0, 0, psmoke[data.frameX + 1])
  data.particle:attach(n)
  -- data.particle:setParam('texture', Misc.resolveFile("npc-"..respawnanchor.id.."-1.png"))
end

function respawnanchor.onRedTick(n)
  local data = n.data
  data.observ = false
  
  if data.power > 0 and data.frameY == 0 then
    if data.frameX == TYPE_ANCHOR then
      SFX.play(sfxactivate1)
      data._basegame.checkpoint:reset()
	  	data._basegame.checkpoint:collect()
    elseif data.frameX == TYPE_HOST and not killed_all then
      SFX.play(sfxactivate2)
      data.deathActive = true
      data.deathTimer = data.deathDelay
      data.deathTrans = portalLen
    end
  end

  if data.deathActive  then
    if data.deathTrans > 0 then
      data.deathTrans = data.deathTrans - 1
    end
  else
    if data.deathTrans < portalLen then
      data.deathTrans = data.deathTrans + 1
    end
  end

  if data.deathActive  then
    data.deathTimer = data.deathTimer - 1

    if data.deathTimer == 0 then
      killed_all = true
      data.deathActive = false

      SFX.play(sfxkill)
      for k, p in ipairs(Player.get()) do
        Routine.run(killPlayer, p, bomb)
      end
    end
  end

  if (data.frameX == TYPE_ANCHOR and data._basegame.checkpoint.id == GameData.__checkpoints[Level.filename()].current) or (data.frameX == TYPE_HOST and data.deathActive) then
    data.particle:Emit(1)
    
    data.frameY = 1
    data.observ = true
    
  else
    data.frameY = 0
    data.observ = false
  end
  spiralEffect(data.particle)
  
  redstone.resetPower(n)
end

function respawnanchor.onRedDraw(n)
  local data = n.data
  
  redstone.drawNPC(n)

  if not respawnanchor.config.invisible then
    if data.deathActive or data.deathTrans < portalLen then

      for k, p in ipairs(Player.get()) do
        if data.deathActive or data.deathTrans < portalLen then
          drawPortal(n, p)
        end

        if data.deathActive and p.deathTimer == 0 then
          local x = p.x + floor(0.15*p.width)
          local w = floor(p.width*0.7)
          Graphics.drawBox{x = x, y = p.y - 10, width = w, height = 4, color = Color.gray, sceneCoords = true}
          Graphics.drawBox{x = x, y = p.y - 10, width = ceil(data.deathTimer/data.deathDelay*w), height = 4, color = Color.red, sceneCoords = true}
        end
      end
    end

    data.particle:Draw(-46)
  end


end

redstone.register(respawnanchor)

return respawnanchor
