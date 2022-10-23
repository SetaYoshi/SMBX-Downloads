local button = {}

local npcManager = require("npcManager")
local ai = require("button_AI")

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 2,
	framespeed = 8,
	framestyle = 0,

	width = 32,
	height = 32,

  jumphurt = 0,
  nohurt = true,
  notcointransformable = true,
	nogravity = false,
	noblockcollision = 0,
	nofireball = 1,
	noiceball = 1,
	noyoshi = 1,
	speed = 0,
  npcblock = false,
	iswalker = true,

  pressedFrames = 1
})
npcManager.registerHarmTypes(npcID, {HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP}, {[HARM_TYPE_JUMP] = 10, [HARM_TYPE_SPINJUMP] = 10})

ai.register(npcID, "red")

button.onTickNPC = ai.onTickButton
button.onDrawNPC = ai.onDrawButton
button.onNPCHarm = ai.onButtonHarm

function button.onInitAPI()
	registerEvent(button, "onNPCHarm", "onNPCHarm")
  npcManager.registerEvent(npcID, button, "onTickNPC")
  npcManager.registerEvent(npcID, button, "onDrawNPC")
end

return button
