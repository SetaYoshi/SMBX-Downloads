local wormhole = {}

-- whitehole.lua v1.4
-- Created by SetaYoshi
-- Sprite by Wonolf
-- Sound: https://www.soundsnap.com/user-name/blastwave_fx
--        https://www.youtube.com/watch?v=LnMhJU6RsYU

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local holes = require("AI_holes")
local lineguide = require("lineguide")

local npcID = NPC_ID
lineguide.registerNpcs(npcID)


local blacklistNPC = {

}

local config = npcManager.setNpcSettings({
	id = npcID,

  width = 48,
  height = 48,
	gfxwidth = 48,
	gfxheight = 48,

	frames = 1,
	framespeed = 8,
	score = 0,
	speed = 0,
	playerblock = false,
	npcblock = false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	grabside = false,
	isshoe = false,
	isyoshi = false,
	nohurt = true,
	iscoin = false,
	jumphurt = true,
	spinjumpsafe = false,
	notcointransformable = true,
	ignorethrownnpcs  = true,
	ignorethrownnpcs  = true,

  rotationspeed = 8,
	radius = -1,
	forceradius = -1,
	laserspeed = 15,

	transition = true,
  sectiontransition = true,

	disableribbon = false,
	warptype = 1
})

npcManager.registerHarmTypes(npcID, {}, {})
if config.radius == -1 then
	config.radius = math.ceil(config.width*0.5)
end
if config.forceradius == -1 then
	config.forceradius = math.ceil(config.width*2)
end

wormhole.onTickNPC = holes.onTickNPC
wormhole.onDrawNPC = holes.onDrawNPC
holes.register(npcID)

function wormhole.onInitAPI()
  npcManager.registerEvent(npcID, wormhole, "onTickNPC")
	npcManager.registerEvent(npcID, wormhole, "onDrawNPC")
end

return wormhole
