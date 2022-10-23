local balloon = {}

local npcManager = require("npcManager")

local npcutils = require("npcs/npcutils")
local balls = require("AI_balloon")
local klonoa = require("characters/klonoa")

local npcID = NPC_ID
balls.ID.red = npcID
klonoa.UngrabableNPCs[npcID] = true

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 64,
	width = 32,
	height = 32,
	gfxoffsety = 32,
	speed = 1,
	frames = 1,
	framespeed = 4,
	framestyle = 0,
	score = 0,
	jumphurt = true,
	spinjumpsafe = false,
	nohurt = true,
	noyoshi=true,
	grabside = false,
	harmlessthrown=false,
	noiceball=false,
	nofireball=false,
	nogravity = true,
	respawn = 150
})
npcManager.registerHarmTypes(npcID, {HARM_TYPE_NPC, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_EXT_FIRE, HARM_TYPE_EXT_ICE, HARM_TYPE_EXT_HAMMER})

balloon.onTickNPC = balls.onTickNPC
balloon.onDrawNPC = balls.onDrawNPC


function balloon.onInitAPI()
  npcManager.registerEvent(npcID, balloon, "onTickNPC")
	npcManager.registerEvent(npcID, balloon, "onDrawNPC")
end

return balloon
