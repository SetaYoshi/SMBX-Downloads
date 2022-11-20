local piston_ever = {}

local redstone = require("redstone")
local npcManager = require("npcManager")
local expandedDefines = require("expandedDefines")

piston_ever.name = "piston_ever"
piston_ever.id = NPC_ID
piston_ever.order = 0.7401

piston_ever.onRedPower = function(n, c, p, d, hitbox)
  local px, py, pw, ph = n.x, n.y, n.width, redstone.component.piston.config.height
  if n.data.frameX == 0 then
    py = n.y + n.height - ph
  end

  if Colliders.collide(hitbox, Colliders.Box(px, py, pw, ph)) then
    redstone.setEnergy(n, p)
  -- else
  --   return true
  end
end


piston_ever.config = npcManager.setNpcSettings({
	id = piston_ever.id,

	gfxwidth = 32,
	gfxheight = 64,
	gfxoffsetx = 0,
	gfxoffsety = 0,
  invisible = false,

	frames = 1,
	framespeed = 8,
	framestyle = 0,

  width = 32,
	height = 64,

  nogravity = true,
	jumphurt = true,
  notcointransformable = true,
  noblockcollision = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true
})

piston_ever.prime = redstone.component.piston.prime
piston_ever.onRedTick = redstone.component.piston.ext_onTick


function piston_ever.onRedDraw(n)
  redstone.drawNPC(n)
end

redstone.register(piston_ever)

return piston_ever
