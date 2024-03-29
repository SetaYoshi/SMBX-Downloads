-- v1.3.0

local piston_ehor = {}

local redstone = require("redstone")
local npcManager = require("npcManager")
local expandedDefines = require("expandedDefines")

piston_ehor.name = "piston_ehor"
piston_ehor.id = NPC_ID
piston_ehor.order = 0.7401

piston_ehor.onRedPower = function(n, c, p, d, hitbox)
  local px, py, pw, ph = n.x, n.y, redstone.component.piston.config.width, n.height
  if n.data.frameX == 0 then
    px = n.x + n.width - pw
  end

  if Colliders.collide(hitbox, Colliders.Box(px, py, pw, ph)) then
    redstone.setEnergy(n, p)
  -- else
  --   return true
  end
end

piston_ehor.config = npcManager.setNpcSettings({
	id = piston_ehor.id,

	gfxwidth = 64,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
  invisible = false,

	frames = 1,
	framespeed = 8,
	framestyle = 0,

  width = 64,
	height = 32,

  nogravity = true,
	jumphurt = true,
  notcointransformable = true,
  noblockcollision = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true,
  disabledespawn = false,
})

piston_ehor.prime = redstone.component.piston.prime
piston_ehor.onRedTick = redstone.component.piston.ext_onTick


function piston_ehor.onRedDraw(n)
  redstone.drawNPC(n)
end

redstone.register(piston_ehor)

return piston_ehor
