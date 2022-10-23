local nokobon = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local npcID = NPC_ID

local THROWN_NPC_COOLDOWN    = 0x00B2C85C
local SHELL_HORIZONTAL_SPEED = 0x00B2C860
local SHELL_VERTICAL_SPEED   = 0x00B2C864

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	speed = 1,
	frames = 12,
	framespeed = 4,
	framestyle = 0,
	score = 0,
	jumphurt = false,
	spinjumpsafe = false,
	nohurt = false,
	noyoshi=false,
	grabside = false,
	harmlessthrown=false,
	noiceball=false,
	nofireball=false,
	isshell = true,
	warningdelay = 200,
	explosiondelay = 320,
	restingframes = 4,
	nospecialanimation = false
})
npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_TAIL, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_NPC, HARM_TYPE_LAVA},
	{[HARM_TYPE_TAIL] = 10,
	[HARM_TYPE_PROJECTILE_USED] = 10,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
})

function nokobon.onTickNPC(npc)
	if Defines.levelFreeze then return end

	if npc:mem(0x12A, FIELD_WORD) <= 0 then
		npc.ai3 = 0
		return
	end

	if npc.direction == 0 then
		npc.direction = 1
	end
	if not npc.friendly then
		npc.ai3 = npc.ai3 + 1
	end

	if npc.ai3 >= NPC.config[npc.id].explosiondelay then
		npc:kill(HARM_TYPE_PROJECTILE_USED)
	end
end

function nokobon.onDrawNPC(npc)
	if npc:mem(0x12A, FIELD_WORD) <= 0 then return end
	npc.ai5 = 1
	if not config.nospecialanimation then

		local frames = config.restingframes
		local offset = 0
		local gap = config.frames - config.restingframes
		if npc.ai3 >= config.warningdelay then
			npc.animationTimer = npc.animationTimer + 1
			frames = config.frames - config.restingframes
			offset = config.restingframes
			gap = 0
		end
		npcutils.restoreAnimation(npc)
		npc.animationFrame = npcutils.getFrameByFramestyle(npc, {
			frames = frames,
			offset = offset,
			gap = gap
		})
		if npc.speedX == 0 then
			npc.animationFrame = config.restingframes*math.floor(npc.animationFrame/config.restingframes)
		end
	end
end

function nokobon.onNPCKill(eventObj, npc, reason)
	if npc.id == npcID and npc.ai5 == 1 then
		if reason == 1 or reason == 2 or reason == 7 then
			eventObj.cancelled = true
			npc.speedX = 0
			npc.speedY = -5
		elseif reason ~= 9 then
			Explosion.spawn(npc.x + npc.width/2, npc.y + npc.height/2, 2)
			Animation.spawn(924, npc.x, npc.y)
		end
	end
end

-- big thanks to Mr.DoubleA
function nokobon.onNPCHarm(eventObj,v,reason,culprit)
	if v.id ~= npcID then return end

	local culpritIsPlayer = (culprit and culprit.__type == "Player")
	local culpritIsNPC    = (culprit and culprit.__type == "NPC"   )

	if reason == HARM_TYPE_JUMP then
		if v:mem(0x138,FIELD_WORD) == 2 then
			v:mem(0x138,FIELD_WORD,0)
		end

		if culpritIsPlayer and culprit:mem(0xBC,FIELD_WORD) <= 0 and culprit.mount ~= 2 then
			if v.speedX == 0 and (culpritIsPlayer and v:mem(0x130,FIELD_WORD) ~= culprit.idx)  then
				SFX.play(9)
				v.speedX = mem(SHELL_HORIZONTAL_SPEED,FIELD_FLOAT)*culprit.direction
				v.speedY = 0

				v:mem(0x12E,FIELD_WORD,mem(THROWN_NPC_COOLDOWN,FIELD_WORD))
				v:mem(0x130,FIELD_WORD,culprit.idx)
				v:mem(0x132,FIELD_BOOL,true)
			elseif (culpritIsPlayer and v:mem(0x130,FIELD_WORD) ~= culprit.idx) or (v:mem(0x22,FIELD_WORD) == 0 and (culpritIsPlayer and culprit:mem(0x40,FIELD_WORD) == 0)) then
				SFX.play(2)
				v.speedX = 0
				v.speedY = 0

				if v:mem(0x1C,FIELD_WORD) > 0 then
					v:mem(0x18,FIELD_FLOAT,0)
					v:mem(0x132,FIELD_BOOL,true)
				end
			end
		end
	elseif reason == HARM_TYPE_FROMBELOW or reason == HARM_TYPE_TAIL then
		SFX.play(9)

		v:mem(0x132,FIELD_BOOL,true)
		v.speedY = -5
		v.speedX = 0
	elseif reason == HARM_TYPE_LAVA then
		v:mem(0x122,FIELD_WORD,reason)
	elseif reason ~= HARM_TYPE_PROJECTILE_USED and v:mem(0x138, FIELD_WORD) ~= 4 then
		if reason == HARM_TYPE_NPC then
			if not (v.id == 24 and culpritIsNPC and (culprit.id == 13 or culprit.id == 108)) then
				v:mem(0x122,FIELD_WORD,reason)
			end
		else
			v:mem(0x122,FIELD_WORD,reason)
		end
	elseif reason == HARM_TYPE_PROJECTILE_USED then
		if culpritIsNPC and culprit:mem(0x132,FIELD_BOOL) and (culprit.id < 117 or culprit.id > 120) then
			v:mem(0x122,FIELD_WORD,reason)
		end
	end

	eventObj.cancelled = true
end

function nokobon.onInitAPI()
	npcManager.registerEvent(npcID, nokobon, "onTickNPC")
	npcManager.registerEvent(npcID, nokobon, "onDrawNPC")
	registerEvent(nokobon, "onNPCHarm", "onNPCHarm")
	registerEvent(nokobon, "onNPCKill", "onNPCKill")
end

return nokobon
