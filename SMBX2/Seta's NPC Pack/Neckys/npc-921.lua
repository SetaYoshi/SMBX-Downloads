local mininecky = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 48,
	gfxheight = 48,
	width = 48,
	height = 48,
	gfxoffsety = 0,
	frames = 7,
	framespeed = 6,
	framestyle = 1,
	score = 1,
	nogravity = true,

	delaycycle = 3,
	speedy = 3,
	flyingframes = 4,
	nospecialanimation = false,
	amplitude = 96,
	spawnid = 920,
	spawndelay = 16,
	spawnoffsetx = 20,
	spawnoffsety = -12,
	spawncooldown = 25,
})
npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA},
	{[HARM_TYPE_JUMP] = 921,
	[HARM_TYPE_FROMBELOW] = 921,
	[HARM_TYPE_NPC] = 921,
	[HARM_TYPE_HELD] = 921,
	[HARM_TYPE_TAIL] = 921,
	[HARM_TYPE_PROJECTILE_USED] = 921,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
})

local sfx_death = Audio.SfxOpen(Misc.multiResolveFile("mininecky-death.wav", "../sound/mininecky-death.wav"))
local sfx_flap = Audio.SfxOpen(Misc.multiResolveFile("necky-flap.wav", "../sound/necky-flap.wav"))
local sfx_spit = Audio.SfxOpen(Misc.multiResolveFile("necky-spit.wav", "../sound/necky-spit.wav"))

local function dataCheck(n)
	local data = n.data._basegame
	local settings = n.data._settings
	if data.check == nil then
		data.check = true
		data.timer = data.timer or 0
		data.originy = n.y
		data.offY = 0
		data.variant = settings.variant
		data.diry = -1
		data.isSpitting = false
		data.isSpittingcooldown = false
		if not settings.override then
			settings.delaycycle = config.delaycycle
			settings.amplitude = config.amplitude
		end
		data.spawnid = n.ai1
		if data.spawnid == 0 then
			data.spawnid = config.spawnid
		end
	end
end


local function variant1(n, data, settings)
	if (n.animationFrame == 0 or n.animationFrame == config.frames) and n.animationTimer == 0 then
		n.ai4 = n.ai4 + 1
	end
	if n.ai4 >= settings.delaycycle then
		data.isSpitting = true
		n.speedX = 0
		n.speedY = 0
		n.ai4 = n.ai4 + 1
		if n.ai4 == settings.delaycycle + config.spawndelay then
			data.isSpittingcooldown = true
			local nut = NPC.spawn(data.spawnid, n.x + n.width/2 + config.spawnoffsetx*n.direction, n.y + n.height/2 + config.spawnoffsety, n:mem(0x146, FIELD_WORD))
			nut.x = nut.x - nut.width/2
			nut.direction = n.direction
			nut.friendly = n.friendly
			nut.layerName = "Spawned NPCs"
			SFX.play(sfx_spit)
		elseif n.ai4 >= settings.delaycycle + (config.frames - config.flyingframes)*config.framespeed + config.spawncooldown then
			n.ai4 = 0
			data.isSpitting = false
			data.isSpittingcooldown = false
		end
	else
		data.timer = (data.timer + 4)%360
		if data.timer%15 == 0 then
			SFX.play(sfx_flap)
		end
		n.speedY = (2/3)*math.sin(math.rad(data.timer))
	end
end

local function variant2(n, data, settings)
	if data.isSpitting or ((data.timer >= settings.amplitude/config.speedY) and (n.animationFrame == 0 or n.animationFrame == config.frames) and n.animationTimer == 0) then
		data.isSpitting = true
		n.speedX = 0
		n.speedY = 0
		n.ai4 = n.ai4 + 1
		if n.ai4 == config.spawndelay then
			data.isSpittingcooldown = true
			local nut = NPC.spawn(data.spawnid, n.x + n.width/2 + config.spawnoffsetx*n.direction, n.y + n.height/2 + config.spawnoffsety, n:mem(0x146, FIELD_WORD))
			nut.x = nut.x - nut.width/2
			nut.direction = n.direction
			nut.friendly = n.friendly
			nut.layerName = "Spawned NPCs"
			SFX.play(sfx_spit)
		elseif n.ai4 >= settings.delaycycle + (config.frames - config.flyingframes)*config.framespeed + config.spawncooldown then
			n.ai4 = 0
			data.diry = -data.diry
			data.isSpitting = false
			data.isSpittingcooldown = false
			data.timer = 0
		end
	else
		data.timer = data.timer + 1
		if data.timer%15 == 0 then
			SFX.play(sfx_flap)
		end
		n.speedY = config.speedY*data.diry
	end
end

local function variant3(n, data, settings)
	if data.isSpitting or (data.timer >= settings.amplitude/config.speedY)  or (data.diry == -1 and data.timer == 10) then
		n.speedX = 0
		n.speedY = 0
		if (n.animationFrame == 0 or n.animationFrame == config.frames) and n.animationTimer == 0 then
			data.isSpitting = true
		end
		if data.isSpitting then
			n.ai4 = n.ai4 + 1
		end
		if n.ai4 == config.spawndelay then
			data.isSpittingcooldown = true
			local nut = NPC.spawn(data.spawnid, n.x + n.width/2 + config.spawnoffsetx*n.direction, n.y + n.height/2 + config.spawnoffsety, n:mem(0x146, FIELD_WORD))
			nut.x = nut.x - nut.width/2
			nut.direction = n.direction
			nut.friendly = n.friendly
			nut.layerName = "Spawned NPCs"
			SFX.play(sfx_spit)
		elseif n.ai4 >= settings.delaycycle + (config.frames - config.flyingframes)*config.framespeed + config.spawncooldown then
			n.ai4 = 0
			if data.timer ~= 10 then
				data.diry = -data.diry
				data.timer = 0
			else
				data.timer = data.timer + 1
			end
			data.isSpitting = false
			data.isSpittingcooldown = false
		end
	else
		data.timer = data.timer + 1
		if (data.diry == 1 and data.timer == 10) then
			data.timer = data.timer + 1
		end
		if data.timer%15 == 0 then
			SFX.play(sfx_flap)
		end
		n.speedY = config.speedY*data.diry
	end
end

function mininecky.onTickNPC(n)
	if Defines.levelFreeze or n:mem(0x12A, FIELD_WORD) <= 0 or n:mem(0x12C, FIELD_WORD) ~= 0 or n:mem(0x136, FIELD_BOOL) or n:mem(0x138, FIELD_WORD) > 0 then return end
	local data = n.data._basegame
	local settings = n.data._settings
	dataCheck(n)

  if settings.variant == 0 then
		variant1(n, data, settings)
	elseif settings.variant == 1 then
		variant2(n, data, settings)
	elseif settings.variant == 2 then
		variant3(n, data, settings)
	end

end

function mininecky.onDrawNPC(n)
	if n:mem(0x12A, FIELD_WORD) <= 0 or config.nospecialanimation then return end
	local data = n.data._basegame
	local settings = n.data._settings

		local frames = config.flyingframes
		local offset = 0
		local gap = config.frames - config.flyingframes

		if data.isSpittingcooldown then
			frames = 1
			offset = config.frames - 1
			gap = 0
		elseif data.isSpitting then
			frames = config.frames - config.flyingframes
			offset = config.flyingframes
			gap = 0
		end
		npcutils.restoreAnimation(n)
		n.animationFrame = npcutils.getFrameByFramestyle(n, {
			frames = frames,
			offset = offset,
			gap = gap
		})
end

function mininecky.onPostNPCKill(n, reason)
	if n.id == npcID then
		SFX.play(sfx_death)
	end
end

function mininecky.onInitAPI()
	npcManager.registerEvent(npcID, mininecky, "onTickNPC")
	npcManager.registerEvent(npcID, mininecky, "onDrawNPC")
	registerEvent(mininecky, "onPostNPCKill", "onPostNPCKill")
end

return mininecky
