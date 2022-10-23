local lever = {}

-- lever.lua v1.0
-- Created by SetaYoshi


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
	nogravity = false,
  notcointransformable = true,
  nohurt = true,
	noblockcollision = 0,
	nofireball = 1,
	noiceball = 1,
	noyoshi = 1,
	speed = 0,
  npcblock = true,
	iswalker = true,

  pressedFrames = 1
})
npcManager.registerHarmTypes(npcID, {HARM_TYPE_JUMP}, {[HARM_TYPE_JUMP] = 10, [HARM_TYPE_SPINJUMP] = 10})

local sfxtoggle = 2

local function dataCheck(n)
  local data = n.data
  if not data.ini then
    data.ini = true
    data.isOn = data._settings.state == 1
    data.layerName = data._settings.layername
    data.smoke = data._settings.smoke
  end
end


function lever.onDrawNPC(n)
  dataCheck(n)
  local frames = config.pressedFrames
  local offset = 0
  local gap = config.frames - config.pressedFrames
  if n.data.isOn then
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

function lever.onNPCHarm(event, n, reason, culprit)
  if n.id == npcID and (reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP) then
		if reason == HARM_TYPE_JUMP then
			SFX.play(sfxtoggle)
		end
		n.data.isOn = not n.data.isOn
    local layer = Layer.get(n.data.layerName)
    if layer then
      if n.data.isOn then
        layer:show(n.data.smoke)
      else
        layer:hide(n.data.smoke)
      end
    end
    event.cancelled = true
  end
end

function lever.onInitAPI()
	registerEvent(lever, "onNPCHarm", "onNPCHarm")
  npcManager.registerEvent(npcID, lever, "onDrawNPC")
end

return lever
