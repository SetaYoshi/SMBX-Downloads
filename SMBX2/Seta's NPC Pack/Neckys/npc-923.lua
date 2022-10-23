local necky = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 126,
	gfxheight = 80,
	width = 82,
	height = 56,
	gfxoffsetx = -22,
	frames = 13,
	framespeed = 6,
	framestyle = 1,
	score = 1,
	noblockcollision = false,
	nogravity = false,

  peekingframes = 2,
	throwingframes = 7,
	spawnID = 920,
	spawnoffsetx = 20,
	spawnoffsety = 0,
	spawnDelay = 8
})
npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA},
	{[HARM_TYPE_JUMP] = 922,
	[HARM_TYPE_FROMBELOW] = 922,
	[HARM_TYPE_NPC] = 922,
	[HARM_TYPE_HELD] = 922,
	[HARM_TYPE_TAIL] = 922,
	[HARM_TYPE_PROJECTILE_USED] = 922,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
})

local sfx_death = Audio.SfxOpen(Misc.multiResolveFile("necky-death.wav", "../sounds/necky-death.wav"))
local sfx_flap = Audio.SfxOpen(Misc.multiResolveFile("necky-flap.wav", "../sounds/necky-flap.wav"))

local nutarc = function(n)
	n.speedY = n.speedY + 2*Defines.npc_grav
end

local listspeed = {1, 0, -1}

local function dataCheck(n)
	local data = n.data._basegame
	local settings = n.data._settings
	if data.check == nil then
		data.check = true
		data.isshooting = false
		data.variant = settings.variant
		data.yforce = settings.yforce
		data.cooldown = settings.cooldown
		data.timer = data.cooldown
		data.peektimer = 0
		data.throwtimer = 0
		data.animation = 0
		data.shot = 0
	end
end

local function variant_standard(n)
	local data = n.data._basegame
	local f = n.animationFrame
	if n.direction == 1 then f = f - config.frames end
	if data.timer > 0 then
		data.timer = data.timer - 1
	end
	if data.peektimer > 0 then
		data.peektimer = data.peektimer - 1
	end
	if data.throwtimer > 0 then
		data.throwtimer = data.throwtimer - 1
	end

	if data.animation == 1 and (f == config.frames - config.throwingframes - 1 and data.peektimer > 0) then
		n.animationTimer = 0
	elseif data.animation == 2 then
		if f == config.frames - 1 and data.throwtimer ~= 0 then
			n.animationTimer = 0
		elseif f ~= config.frames - 1 then
			n.animationTimer = n.animationTimer + 1
		end

		if 16 - data.throwtimer == config.spawndelay then
			local npc = NPC.spawn(config.spawnID, n.x + n.width*0.5, n.y + config.spawnoffsety)
			npc.data.throwned = true
			npc.data.speedf = nutarc
			npc.data.lasty = n.y + n.height
			npc.speedY = -data.yforce
			if data.variant == 1 then
				npc.x = npc.x - 0.5*npc.width
				npc.speedX = 0
			else
				npc.x = npc.x - 0.5*npc.width + config.spawnoffsetx*n.direction
				npc.speedX = 2*n.direction
			end
		end
	end

	if data.animation == 0 and (f == config.frames - config.peekingframes - config.throwingframes - 1 and n.animationTimer == config.framespeed - 1 and data.timer == 0) then
		data.animation = 1
		data.peektimer = 60
	elseif data.animation == 1 and (f == config.frames - config.throwingframes - 1 and n.animationTimer == config.framespeed - 1 and data.peektimer == 0) then
		data.animation = 2
		data.throwtimer = 16
	elseif data.animation == 2 and (f == config.frames - 1 and n.animationTimer == config.framespeed - 1) then
		data.animation = 0
		data.timer = data.cooldown
	end
end

local function variant_spray(n)
	local data = n.data._basegame
	local f = n.animationFrame
	if n.direction == 1 then f = f - config.frames end
	if data.timer > 0 then
		data.timer = data.timer - 1
	end
	if data.peektimer > 0 then
		data.peektimer = data.peektimer - 1
	end
	if data.throwtimer > 0 then
		data.throwtimer = data.throwtimer - 1
	end

	if data.animation == 1 and (f == config.frames - config.throwingframes - 1 and data.peektimer > 0) then
		n.animationTimer = 0
	elseif data.animation == 2 then
		if f == config.frames - 1 and data.throwtimer ~= 0 then
			n.animationTimer = 0
		elseif f ~= config.frames - 1 then
			n.animationTimer = n.animationTimer + 1
		end

		if 16 - data.throwtimer == config.spawndelay then
			local npc = NPC.spawn(config.spawnID, n.x + n.width*0.5, n.y + config.spawnoffsety)
			npc.x = npc.x - 0.5*npc.width + config.spawnoffsetx*n.direction
			npc.data.throwned = true
			npc.data.speedf = nutarc
			npc.data.lasty = n.y + n.height
			npc.speedX, npc.speedY = listspeed[data.shot + 1]*2*n.direction, -data.yforce

			data.shot = data.shot + 1
			if data.shot == 3 then
				data.shot = 0
				data.animation = 0
				data.timer = data.cooldown
			else
				data.timer = 10
				data.animation = 3
			end
		end
	end

	if data.animation == 0 and (f == config.frames - config.peekingframes - config.throwingframes - 1 and n.animationTimer == config.framespeed - 1 and data.timer == 0) then
		data.animation = 1
		data.peektimer = 60
	elseif data.animation == 1 and (f == config.frames - config.throwingframes - 1 and n.animationTimer == config.framespeed - 1 and data.peektimer == 0) then
		data.animation = 2
		data.throwtimer = 16
	elseif data.animation == 2 and (f == config.frames - 1 and n.animationTimer == config.framespeed - 1 and data.throwtimer == 0) then
		data.animation = 0
		data.timer = data.cooldown
	elseif data.animation == 3 and (f == config.frames - config.peekingframes - config.throwingframes - 1 and n.animationTimer == config.framespeed - 1 and data.timer == 0) then
		data.animation = 2
		data.throwtimer = 16
	end
end

function necky.onTickNPC(n)
	if Defines.levelFreeze or n:mem(0x12A, FIELD_WORD) <= 0 or n:mem(0x12C, FIELD_WORD) ~= 0 or n:mem(0x136, FIELD_BOOL) or n:mem(0x138, FIELD_WORD) > 0 then return end
	local data = n.data._basegame
	dataCheck(n)

	if data.variant == 2 then
		variant_spray(n)
	else
		variant_standard(n)
	end
end

function necky.onDrawNPC(n)
	if n:mem(0x12A, FIELD_WORD) <= 0 or config.nospecialanimation then return end
	local data = n.data._basegame
	local settings = n.data._settings
  local anim = data.animation

	local frames = config.frames - config.peekingframes - config.throwingframes
	local offset = 0
	local gap = config.peekingframes + config.throwingframes
	if anim == 1 then
		data.prefv = 0
		frames = config.peekingframes
		offset = config.frames - config.peekingframes - config.throwingframes
		gap = config.throwingframes
	elseif anim == 2 then
		frames = config.throwingframes
		offset = config.frames - config.throwingframes
		gap = 0
	end


	npcutils.restoreAnimation(n)
	n.animationFrame = npcutils.getFrameByFramestyle(n, {frames = frames,	offset = offset, gap = gap})

	-- possible fix for animation bug??
	-- data.prefv = data.prefv or 0
	-- if data.prefv > n.animationFrame then
	-- 	data.prefv = n.animationFrame
	-- end
	-- if anim == 2 and n.animationFrame <= data.prefv then
	-- 	n.animationFrame = data.prefv
	-- 	n.animationTimer = 0
	-- end
	-- data.prefv = n.animationFrame

end


function necky.onPostNPCKill(n, reason)
	if n.id == npcID then
		SFX.play(sfx_death)
	end
end

function necky.onInitAPI()
	npcManager.registerEvent(npcID, necky, "onTickNPC")
	npcManager.registerEvent(npcID, necky, "onDrawNPC")
	registerEvent(necky, "onPostNPCKill", "onPostNPCKill")
end

return necky
