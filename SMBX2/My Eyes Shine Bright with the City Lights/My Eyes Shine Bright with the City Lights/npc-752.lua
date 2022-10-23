local smwfuzzy = {}

local npcManager = require("npcManager")
local rb = require("ringBurner")

local npcID = NPC_ID

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
    windup = 240,
    radius = 128,
    pulsespeed = 2,
    pulsedrag = 0.1,
    playerblock = true,
    npcblock = true,
    playerblocktop = true,
    npcblocktop = true,
    jumphurt = true
}

npcManager.setNpcSettings(config)

function smwfuzzy.onInitAPI()
    npcManager.registerEvent(npcID, smwfuzzy, "onTickEndNPC")
    rb.register(npcID)
end

function smwfuzzy.onTickEndNPC(v)
    if Defines.levelFreeze then return end

    if v:mem(0x12A, FIELD_WORD) <= 0 then
        return
    end

    for k,p in ipairs(Player.get()) do
        if Colliders.speedCollide(p, v) then
            p:harm()
        end
    end
end

return smwfuzzy
