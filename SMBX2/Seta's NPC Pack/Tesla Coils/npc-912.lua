local tesla = {}

-- teslacoil.lua v1.0
-- Created by SetaYoshi
-- Sprite by Wonolf

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local teslacoil = require("AI_teslacoil")

local npcID = NPC_ID
teslacoil.ID.althead_up = npcID

local config = npcManager.setNpcSettings({
	id = npcID,

  width = 32,
  height = 32,
	gfxwidth = 32,
	gfxheight = 32,

	frames = 5,
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
	nohurt = false,
	iscoin = false,
	jumphurt = true,
	spinjumpsafe = true,
	notcointransformable = true,

	poweredframes = 4
})

tesla.onTickNPC = teslacoil.althead_onTickNPC
tesla.onDrawNPC = teslacoil.onDrawNPC


function tesla.onInitAPI()
  npcManager.registerEvent(npcID, tesla, "onTickNPC")
	npcManager.registerEvent(npcID, tesla, "onDrawNPC")
end

return tesla
