-- v1.3.0

local respawnanchor = {}

local redstone = require("redstone")
local npcManager = require("npcManager")
local cps = require("checkpoints")
local cpai = require("npcs/AI/checkpoints")

respawnanchor.name = "respawnanchor"
respawnanchor.id = NPC_ID
respawnanchor.order = 0.54

respawnanchor.onRedPower = function(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

respawnanchor.onRedInventory = function(n, c, inv, dir, hitbox)
  n.data.inv = inv
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
})

local sfxactivate = Audio.SfxOpen(Misc.resolveFile("respawnanchor-activate.ogg"))
local psmoke = Misc.resolveFile("npc-"..respawnanchor.id.."-particle.ini")

cps.registerNPC(respawnanchor.id)
cpai.addID(respawnanchor.id, true)

local function spiralEffect(emitter)
  local particles = emitter.particles

  for k, p in ipairs(particles) do
    if not p.spiral then
      p.spiral = vector(0, 0.8):rotate(RNG.random(360))
    end

    p.spiral = p.spiral:rotate(2*(p.ttl/p.initTtl))
    -- Misc.dialog((p.ttl/p.initTtl))
    -- p.speedX, p.speedY = p.spiral.x, p.spiral.y
    p.x = p.x + p.spiral.x
    p.y = p.y + p.spiral.y
  end
end

function respawnanchor.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data.frameX or 0
  data.frameY = data.frameY or 0

  data.pistImmovable = true

	data._basegame.checkpoint.powerup = nil
	data._basegame.checkpoint.sound = nil

  data.particle = Particles.Emitter(0, 0, psmoke);
  data.particle:attach(n)
  -- data.particle:setParam('texture', Misc.resolveFile("npc-"..respawnanchor.id.."-1.png"))
end

function respawnanchor.onRedTick(n)
  local data = n.data
  data.observ = false
  
  if data.power > 0 and data.powerPrev == 0 then
    SFX.play(sfxactivate)
    data._basegame.checkpoint:reset()
		data._basegame.checkpoint:collect()
  end
  
  if data._basegame.checkpoint.id == GameData.__checkpoints[Level.filename()].current then
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
  data.particle:Draw(-46)
end

redstone.register(respawnanchor)

return respawnanchor
