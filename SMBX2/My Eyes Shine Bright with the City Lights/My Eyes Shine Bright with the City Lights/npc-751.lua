local smwfuzzy = {}

local npcID = NPC_ID

local npcManager = require("npcManager")
local rb = require("ringBurner")

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

-- settings
local config = {
	id = npcID,
	gfxoffsety = 0,
	width = 32,
    height = 32,
    gfxwidth = 32,
    gfxheight = 32,
    frames = 1,
    framestyle = 0,
    noiceball = true,
    nofireball=true,
    noyoshi = true,
	noblockcollision = true,
	nowaterphysics = true,
    spinjumpsafe = false,
    nogravity = true,
    windup = 100,
    radius = 192,
    pulsespeed = 2,
    pulsedrag = 0.1,
    playerblock = true,
    npcblock = true,
    playerblocktop = true,
    npcblocktop = true,
    nohurt = true
}

npcManager.setNpcSettings(config)

function smwfuzzy.onInitAPI()
    rb.register(npcID)
end

return smwfuzzy
