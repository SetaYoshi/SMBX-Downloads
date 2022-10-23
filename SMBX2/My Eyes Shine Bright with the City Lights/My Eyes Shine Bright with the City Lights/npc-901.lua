local bonybeetle = {}

local npcManager = require("npcManager")
local sl = require("stoplight")

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	frames = 2,
	framestyle = 1,
	jumphurt = 0,
	nofireball=1,
	noyoshi=1,
	speed = 1,
	luahandlesspeed=true
})

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_NPC,
		HARM_TYPE_LAVA,
		HARM_TYPE_SWORD,
		HARM_TYPE_TAIL
	},
	{
		[HARM_TYPE_JUMP] = 921,
		[HARM_TYPE_SPINJUMP] = 921,
		[HARM_TYPE_FROMBELOW]=163,
		[HARM_TYPE_PROJECTILE_USED]=163,
		[HARM_TYPE_HELD]=163,
		[HARM_TYPE_NPC]=163,
		[HARM_TYPE_TAIL]=163,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
)

local function iniCheck(n)
	local data = n.data

	if not data.ini then
		data.ini = true
		data.state = 'idle'
		data.timer = 0

		if sl.currentColor then
			data.state = 'stop'
		end
	end
end

stateOffset = {
	['green'] = 'idle',
	['yellow'] = 'idle',
	['red'] = 'stop'
}

function bonybeetle.onTickNPC(n)
	local data = n.data
	iniCheck(n)

  if sl.currentColor == 'green' and data.state == 'stop' or sl.currentColor == 'red' and data.state == 'idle' then
		data.state = 'hide'
		data.timer = 0
	end

	if data.state == 'hide' then
    data.timer = data.timer + 1
		if data.timer == 8 then
      data.state = stateOffset[sl.currentColor]
		end
	end
end

local stopOffset = {
	[-1] = 5,
	[1] = 6
}

function bonybeetle.onDrawNPC(n)
	local data = n.data
  iniCheck(n)

	if data.state == 'stop' then
		n.animationFrame = n.animationFrame + stopOffset[n.direction] + math.floor(n.animationTimer/4)
	elseif data.state == 'hide' then
		n.animationFrame = stopOffset[n.direction] - 1
  end
end

function bonybeetle.onNPCHarm(eventObj, n, reason, culprit)
	if n.id == npcID then
		if sl.currentColor == 'red' then
			if culprit and type(culprit) == 'Player' then
				culprit:harm()
			end
			eventObj.cancelled = true
		else
			local e = Animation.spawn(163, n.x, n.y)
			e.speedX = RNG.random(2, 4)*RNG.irandomEntry({-1, 1})
			e.speedY = RNG.random(-6, -8)
			SFX.play(57)
		end
	end
end


function bonybeetle.onInitAPI()
	npcManager.registerEvent(npcID, bonybeetle, "onTickNPC", "onTickNPC")
	npcManager.registerEvent(npcID, bonybeetle, "onDrawNPC", "onDrawNPC")
	registerEvent(bonybeetle, "onNPCHarm", "onNPCHarm")
	registerEvent(bonybeetle, "onStopLight", "onStopLight")
end

return bonybeetle
