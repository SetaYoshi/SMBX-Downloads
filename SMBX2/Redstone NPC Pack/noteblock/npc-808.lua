local noteblock = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local min = math.min

noteblock.name = "noteblock"
noteblock.id = NPC_ID
noteblock.order = 0.54

noteblock.onRedPower = function(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

noteblock.config = npcManager.setNpcSettings({
	id = noteblock.id,

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
  mute = false,

  nogravity = true,
	jumphurt = true,
  notcointransformable = true,
	nohurt = true,
	noyoshi = true,
  noblockcollision = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true
})

local animTimer = 0
local animFrame = 0

local EXISTS_NOTE

function noteblock.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = (data._settings.inv or 1) - 1
  data.frameY = data.frameY or 0

  data.instrument = data.instrument or 0
  data.invspace = true
end

function noteblock.onRedLoad()
  EXISTS_NOTE = redstone.id.note
end

function noteblock.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.inv > 0 then
    data.frameX = min(data.inv, 24) - 1
    data.inv = 0
  end

  if data.power > 0 and data.powerPrev == 0 then
    data.observ = true
    data.observpower = data.power

    if EXISTS_NOTE then
      local v = NPC.spawn(redstone.id.note, n.x, n.y, n:mem(0x146, FIELD_WORD))
      v.data._settings.type = data.frameX
      redstone.component.note.prime(v)
    end

    if not redstone.isMuted(n) then
      --START SOUND
    end
  end
  if data.power == 0 and data.powerPrev > 0 then
    --END SOUND
  end

  if data.power > 0 then
    data.frameY = 1
  else
    data.frameY = 0
  end

  redstone.resetPower(n)
end

function noteblock.onRedDraw(n)
  n.data.animTimer = animTimer
  n.data.animFrame = animFrame
  redstone.drawNPC(n)
end

local config = noteblock.config
function noteblock.onDraw()
  animTimer = animTimer + 1
  if animTimer >= config.frameSpeed then
    animTimer = 0
    animFrame = animFrame + 1
    if animFrame >= config.frames then
      animFrame = 0
    end
  end
end

function noteblock.onInitAPI()
  registerEvent(noteblock, "onDraw", "onDraw")
end

redstone.register(noteblock)

return noteblock
