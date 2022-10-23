local button = {}

-- button.lua v1.1
-- Created by SetaYoshi
-- Sprite by Void

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
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
  npcblock = true,
	iswalker = true,

  pressedFrames = 1
})
npcManager.registerHarmTypes(npcID, {HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP}, {[HARM_TYPE_JUMP] = 10, [HARM_TYPE_SPINJUMP] = 10})

local sfxtoggle = 2

local function dataCheck(n)
  local data = n.data
  if not data.ini then
		data.ini = true
    data.event = data._settings.eventname
		data.broken = data._settings.broken
		data.countdown = 0
	end
end

function button.onTickNPC(n)
  local data = n.data
	dataCheck(n)

  if data.countdown > 0 then
    data.countdown = data.countdown - 1
		if data.broken and data.countdown == 0 then
			n:kill()
		end
  end
end

function button.onDrawNPC(n)
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

function button.onNPCHarm(event, n, reason, culprit)
  if n.id == npcID and (reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP) then
		if reason == HARM_TYPE_JUMP then
			SFX.play(sfxtoggle)
		end
    event.cancelled = true
		if n.data.countdown == 0 then
			triggerEvent(n.data.event)
		end
		n.data.countdown = 20
  end
end

function button.onInitAPI()
	registerEvent(button, "onNPCHarm", "onNPCHarm")
  npcManager.registerEvent(npcID, button, "onTickNPC")
  npcManager.registerEvent(npcID, button, "onDrawNPC")
end

return button
