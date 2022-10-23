local button = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local sl = require("stoplight")
local exNPC = require("extraNPCProperties")

local sfxtoggle = 2
local colorID = {}

function button.register(id, color)
  colorID[id] = color
end

local function dataCheck(n)
  local data = n.data
  if not data.ini then
		data.ini = true
		data.broken = data._settings.broken
		data.countdown = 0
	end
end

function button.onTickButton(n)
  local data = n.data
	dataCheck(n)

  if data.countdown > 0 then
    data.countdown = data.countdown - 1
		if data.broken and data.countdown == 0 then
			n:kill()
		end
  end
end

function button.onDrawButton(n)
  dataCheck(n)
  local config = NPC.config[n.id]

  local frames = config.pressedFrames
  local offset = 0
  local gap = config.frames - config.pressedFrames
  if n.data.countdown ~= 0 then
    n.animationTimer = n.animationTimer + 1
    frames = config.frames - config.pressedFrames
    offset = config.pressedFrames
    gap = 0
  end
  n.animationFrame = npcutils.getFrameByFramestyle(n, {
    frames = frames,
    offset = offset,
    gap = gap
  })
end

function button.onButtonHarm(event, n, reason, culprit)
  if colorID[n.id] and (reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP) then
		event.cancelled = true
    -- Play SFX when jumped on
		if reason == HARM_TYPE_JUMP then
			SFX.play(sfxtoggle)
		end

    -- Spawn paricles when the button triggers a button change
		if sl.currentColor ~= colorID[n.id] then
			for i = 1, 4 do
				local e = Animation.spawn(n.id, n.x, n.y)
				e.speedX = RNG.irandomEntry({-1, 1})*RNG.random(2, 4)
				e.speedY = RNG.random(-8, -4)
			end
		end

		if n.data.countdown == 0 then

			if exNPC.getData(n).tagsList[1] == "intro" then  -- special intro case
				sl.change("red", {disableEffect = true, intro = true})
			else
				sl.change(colorID[n.id])
			end
		end
		n.data.countdown = 20
  end
end

return button
