local bino = {}

-- bino.lua v1.0
-- Created by SetaYoshi

-- SFX list
local sfx_openmenu = 13
local sfx_closemenu = 35

local npcID = NPC_ID

local npcManager = require("npcManager")

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 26,
	gfxheight = 64,
	width = 26,
	height = 64,
	frames = 1,
	framespeed = 8,
	score = 0,
	speed = 0,
	playerblock = false,
	npcblock = false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	grabside = false,
	isshoe = false,
	isyoshi = false,
	nohurt = true,
	iscoin = false,
	jumphurt = true,
	spinjumpsafe = false,
	notcointransformable = true,

	pausegame = true,
	speed = 5
})

local iniNPC = function(n)
  if not n.data.ini then
    n.data.ini = true
  end
end

-- Menu variables
local activated = false
local playerinput = player
local cammove = {}
local validpress = false
local section
local arrowOffset = 0
local arrowDir = 1

local exclamation = Graphics.sprites.hardcoded[43].img
local left = Graphics.loadImageResolved("npc-"..npcID.."-left.png")
local right = Graphics.loadImageResolved("npc-"..npcID.."-right.png")
local up = Graphics.loadImageResolved("npc-"..npcID.."-up.png")
local down = Graphics.loadImageResolved("npc-"..npcID.."-down.png")


-- Temporarily deactivate a input
local function deactiveCon(name)
  return function()
    while true do
      if not playerinput[name] then
        return
      end
      playerinput[name] = false
      Routine.waitFrames(1)
    end
  end
end

local function activate(p)
	activated = true
	validpress = false
	playerinput = p
	local c = camera
	if p.idx ~= 1 then c = camera2 end
	cammove.x, cammove.y = c.x, c.y
	section = p.section
	SFX.play(sfx_openmenu)
	if config.pausegame then
		Misc.pause()
	end
end

local function deactivate(p)
	activated = false
	Misc.unpause()
	SFX.play(sfx_closemenu)
	deactiveCon("runKeyPressing")
	deactiveCon("upKeyPressing")
	deactiveCon("altRunKeyPressing")
end

function bino.onTick()
  if not activated then
    for _, p in ipairs(Player.get()) do
      for _, n in ipairs(Colliders.getColliding{a = p, b = npcID, atypec= Colliders.PLAYER, btype = Colliders.NPC, filter = function() return true end}) do
        Graphics.drawImageToSceneWP(exclamation, n.x + n.width*0.5 - 0.5*exclamation.width, n.y - exclamation.height - 4, -40)
				-- Activate menu when a player presses up on an NPC
        if p.rawKeys.up == KEYS_PRESSED then
          activate(p)
        end
      end
    end
  end
end

-- Disable split-screen when menu is activated
function bino.onCameraUpdate(idx)
  if activated then
    if idx == 1 then
      camera.renderX, camera.renderY, camera.width, camera.height = 0, 0, 800, 600

			arrowOffset = arrowOffset + arrowDir
		  if math.abs(arrowOffset) == 8 then
		    arrowDir = arrowDir*(-1)
		  end

		  if playerinput.rawKeys.left then
		    cammove.x = cammove.x - config.speed
		  elseif playerinput.rawKeys.right then
		    cammove.x = cammove.x + config.speed
		  end
		  if playerinput.rawKeys.up and validpress then
		    cammove.y = cammove.y - config.speed
		  elseif playerinput.rawKeys.down then
		    cammove.y = cammove.y + config.speed
		  end

			local sec = Section(playerinput.section).boundary

			if not playerinput.rawKeys.up then validpress = true end
		  cammove.x = math.clamp(sec.left, cammove.x, sec.right - 800)
		  cammove.y = math.clamp(sec.top, cammove.y, sec.bottom - 600)
		  camera.x = cammove.x
		  camera.y = cammove.y

			if camera.x > sec.left then
				Graphics.drawImageWP(left, 16 + arrowOffset,292,5)
			end
			if camera.x + 800 < sec.right then
				Graphics.drawImageWP(right, 768 - arrowOffset,292,5)
			end
			if camera.y > sec.top then
				Graphics.drawImageWP(up, 392, 16 + arrowOffset,5)
			end
			if camera.y + 600 < sec.bottom then
				Graphics.drawImageWP(down,392, 568 - arrowOffset,5)
			end

			if playerinput.rawKeys.run == KEYS_PRESSED then
				deactivate()
			end
    else
      camera2.renderY = 800
    end
  end
end

function bino.onTickNPC(n)
  iniNPC(n)
end

function bino.onInputUpdate()
	if activated and not config.pausegame then
		playerinput.jumpKeyPressing = false
		playerinput.runKeyPressing = false
		playerinput.altRunKeyPressing = false
		playerinput.altJumpPressing = false
		playerinput.dropItemKeyPressing = false
		playerinput.leftKeyPressing = false
		playerinput.rightKeyPressing = false
		playerinput.upKeyPressing = false
		playerinput.downKeyPressing = false
	end
end
function bino.onInitAPI()
  npcManager.registerEvent(npcID, bino, "onTickNPC")

  registerEvent(bino, "onTick", "onTick")
	registerEvent(bino, "onInputUpdate", "onInputUpdate")
  registerEvent(bino, "onCameraUpdate", "onCameraUpdate", true)
end

return bino
