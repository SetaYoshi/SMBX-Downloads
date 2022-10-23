local necky = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 112,
	gfxheight = 112,
	width = 64,
	height = 28,
	gfxoffsetx = 12,
	gfxoffsety = 36,
	frames = 11,
	framespeed = 3,
	framestyle = 1,
	score = 1,
	noblockcollision = true,
	nogravity = true,

	amplitude = 96
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

local sfx_death = Audio.SfxOpen(Misc.multiResolveFile("necky-death.wav", "sound/necky-death.wav"))
local sfx_flap = Audio.SfxOpen(Misc.multiResolveFile("necky-flap.wav", "sound/necky-flap.wav"))

local rad, sin, cos, pi = math.rad, math.sin, math.cos, math.pi

local function dataCheck(n)
	local data = n.data._basegame
	local settings = n.data._settings
	if not data.check then
		data.check = true
		data.timer = data.timer or 0
		data.hormove = settings.hormove
		data.vermove = settings.vermove
		data.period = settings.period
		data.dirx = 1
		data.diry = 1
		data.amplitude = settings.amplitude or 128
		settings.w = settings.w or 0.2
		data.w = settings.w*2*pi/65
	end
end

function necky.onTickNPC(n)
	if Defines.levelFreeze or n:mem(0x12A, FIELD_WORD) <= 0 or n:mem(0x12C, FIELD_WORD) ~= 0 or n:mem(0x136, FIELD_BOOL) or n:mem(0x138, FIELD_WORD) > 0 then return end
	local data = n.data._basegame
	local settings = n.data._settings
	dataCheck(n)
  data.timer = data.timer + 1
	if data.timer % 30 == 0 then
		SFX.play(sfx_flap)
	end
	if data.period then
		if data.hormove then
			n.speedX = -data.amplitude*data.w*sin(data.w*data.timer)
		end
		if data.vermove then
			n.speedY = data.amplitude*data.w*cos(data.w*data.timer)
		end
	else
		if data.hormove then
			n.speedX = config.speed*n.direction
		end
		if data.vermove then
			n.speedY = config.speed*n.direction
		end
	end
end


function necky.onPostNPCKill(n, reason)
	if n.id == npcID then
		SFX.play(sfx_death)
	end
end

function necky.onInitAPI()
	npcManager.registerEvent(npcID, necky, "onTickNPC")
	registerEvent(necky, "onPostNPCKill", "onPostNPCKill")
end

return necky
