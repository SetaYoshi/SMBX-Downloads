local extraNPCProperties = require("extraNPCProperties")
local playerphysicspatch = require("playerphysicspatch")
local coyotetime = require("coyotetime")
local antizip = require("antizip")
local spawnzones = require("spawnzones")
local rooms = require("rooms")
local intro = require("intro")

-- Graphics.activateHud(false)
rooms.resetOnEnteringRoom = false
rooms.dontPlayMusicThroughLua = true
rooms.blocksReset = false

local sl = require("stoplight")
local basemod = require("basemod")

local eventNameList = table.map({"green", "yellow", "red"})

-- littleDialogue
local littleDialogue = require("littleDialogue")
do
	littleDialogue.registerStyle("custom", {borderSize = 12})
	littleDialogue.defaultStyleName = "custom"
end


-- Handle the background
-- mda the woz here
local paralx2 = require("paralx2")

local reflectionBuffer = Graphics.CaptureBuffer(800,600)
local reflectionShader = Shader()
reflectionShader:compileFromFile(nil, "bg_reflection.frag")

local backgroundAnim = 0
local backgroundColors = {
	none = Color.darkgrey,
	green = Color(0.75,1,0.75),
	yellow = Color(1,1,0.25),
	red = Color(1,0.45,0.45),
}


function onStart()
	if player.section == 0 then
		intro.begin()
	end

	player:transform(CHARACTER_MARIO)
	player.powerup = PLAYER_SMALL
	player.mount = MOUNT_NONE
end

function onTick()
	-- Adds a transition between color changes so its not too sudden
	if backgroundAnim > 0 then
		backgroundAnim = math.max(0, backgroundAnim - 1/32)
	end
end

function onCameraDraw(camIdx)
	local c = Camera(camIdx)
	local sectionObj = Section(Player(camIdx).section)

	if sectionObj.backgroundID == 1 then
		local bg = sectionObj.background
		local bounds = sectionObj.origBoundary

		local reflectionY
		local reflectionHeight

		for _, layer in ipairs(bg.layers) do
			-- Handle shader uniforms and other layer properties
			local uniforms = layer.uniforms
			local image = layer.img

			if layer.name == "water" then
				uniforms.cameraX = c.x - bounds.left
				uniforms.imageSize = vector(image.width,image.height)
				uniforms.focus = paralx2.focus
				uniforms.time = lunatime.tick()

				reflectionHeight = image.height
				reflectionY = camera.height - image.height + layer.y + (bounds.bottom - (camera.y + camera.height))*layer.parallaxY
			elseif layer.name == "bottomBuildings" or layer.name == "topBuildings" then
				local currentColor = backgroundColors[sl.currentColor]
				if backgroundAnim > 0 then
					currentColor = math.lerp(currentColor, backgroundColors[sl.previousColor], backgroundAnim)
				end

				layer.color = currentColor
			end
		end


		-- Reflections
		if reflectionY ~= nil and reflectionY <= camera.height then
			reflectionBuffer:captureAt(-97)

			Graphics.drawBox{
				texture = reflectionBuffer,priority = -97,
				x = 0,y = reflectionY + reflectionHeight,
				width = camera.width,height = -reflectionHeight,
				sourceWidth = camera.width,sourceHeight = reflectionHeight,
				sourceX = 0,sourceY = reflectionY - reflectionHeight,
				shader = reflectionShader,uniforms = {
					imageSize = vector(camera.width,camera.height),
					time = lunatime.tick(),
				},
			}
		end
	end
end


function onEvent(eventName)
	if eventNameList[eventName] then
		sl.change(eventName)
	end

	if eventName == "hugo" then
		SFX.play(Misc.resolveSoundFile("what have you done"))
	end
	if eventName == "ending" then
		Routine.run(function()
			Routine.skip()
			littleDialogue.create{text = "What a trip! I am glad to finally be home"}
			Routine.skip()
			littleDialogue.create{text = "Oh look, I have a letter in the mail"}
			Routine.skip()
			littleDialogue.create{text = "Dear Mario,\n\nWe have reviewed your claim in your loss of vehicle. As part of your insurance membership, we have baked a cak- wait, no, we're giving you a payment of one power star.\n\nPlease dont hit our helmets again,\nChuck's Auto Insurance\n"}
			Routine.skip()
			Layer.get("star"):show(false)
		end)
	end
end

function onStopLight(color)
	backgroundAnim = 1
end
