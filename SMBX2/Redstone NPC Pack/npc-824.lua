local note = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

note.name = "note"
note.id = NPC_ID

note.test = function()
  return "isNote", function(x)
    return (x == note.id or x == note.name)
  end
end

note.onRedPower = function(n, c, power, dir, hitbox)
  return true
end

note.config = npcManager.setNpcSettings({
	id = note.id,

  width = 32,
  height = 32,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
  invisible = false,

	frames = 1,
	framespeed = 8,
	framestyle = 0,

  nogravity = true,
  notcointransformable = true,
  foreground = true,
  noblockcollision = true,
  nohurt = true,
  jumphurt = true
})

function note.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.type or 0
  data.frameY = data.frameY or 0

  data.timer = data.timer or 0
end

function note.onRedTick(n)
  local data = n.data
  n.friendly = true
  n.speedY = -1.4

  data.timer = data.timer + 1
  if data.timer > 25 then
	  n.opacity = 1 - (1/(50 - 25))*(data.timer - 25)
  end
  if data.timer >= 50 then
    n:kill()
  end
end

note.onRedDraw = redstone.drawNPC

redstone.register(note)

return note
