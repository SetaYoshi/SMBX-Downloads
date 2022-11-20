local door = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

door.name = "reddoor"
door.id = NPC_ID
door.order = 0.72

door.onRedPower = function(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

door.config = npcManager.setNpcSettings({
	id = door.id,

  width = 32,
  height = 64,

	gfxwidth = 32,
	gfxheight = 64,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 2,
	framespeed = 8,
	framestyle = 0,
  invisible = false,
  mute = false,

  nogravity = true,
  noblockcollision = true,
  notcointransformable = true,
	jumphurt = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = false,
  playerblock = false,
  playerblocktop = false,
  npcblock = false,

  effectid = 801  -- The door effect ID
})

local sfxunlocked = 29
local sfxlocked = 35

function door.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data.frameX or 0
  data.frameY = data.frameY or 0

  data.priority = -75

  for k, v in ipairs(Warp.get()) do
    local c = Colliders.Box(v.entranceX, v.entranceY, v.entranceWidth, v.entranceHeight)
    if Colliders.collide(n, c) then
      data.warp = v
    end
  end
end

function door.onRedTick(n)
  local data = n.data
  data.observ = false


  if not door.config.invisible and ((data.power ~= 0 and data.powerPrev == 0) or (data.power == 0 and data.powerPrev ~= 0)) then
    local e = Animation.spawn(10, n.x + 0.5*n.width, n.y + 0.5*n.height)
    e.x, e.y = e.x - e.width*0.5, e.y - e.height*0.5
  end

  if data.warp then
    local warp = data.warp

    warp:mem(0x0C, FIELD_BOOL, data.power == 0) -- Hide warp when door is unpowered
    warp.entranceX, warp.entranceY = n.x + 0.5*n.width - 16, n.y + n.height - 32

    if data.power > 0 and not door.config.invisible then
      for k, p in ipairs(Player.get()) do
        if p.forcedState == FORCEDSTATE_DOOR and p.forcedTimer == 1 and Colliders.collide(n, p) then
          local e = Effect.spawn(door.config.effectid, n.x + 0.5*n.width, n.y + n.height)
          e.x, e.y = e.x - 0.5*e.width, e.y - e.height
          break
        end
      end
    end
  end

  if (data.power > 0 and data.powerPrev == 0) or (data.power == 0 and data.powerPrev > 0) then
    data.observ = true

    if redstone.onScreenSound(n) then
      if data.power == 0 then
        SFX.play(sfxlocked)
      else
        SFX.play(sfxunlocked)
      end
    end
  end

  if data.power == 0 then
    data.frameY = 0
  else
    data.frameY = 1
  end

  redstone.resetPower(n)
end

door.onRedDraw = redstone.drawNPC

redstone.register(door)

return door
