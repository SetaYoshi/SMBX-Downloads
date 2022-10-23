local lib = {}

local rooms = require("rooms")

local icons = Graphics.loadImageResolved("icons.png")
local stopbox = Graphics.loadImageResolved("stopbox.png")

local capture = Graphics.CaptureBuffer(800,600)
local hueFilter = Shader()
hueFilter:compileFromFile(nil, Misc.resolveFile("hueFilter.frag"))

lib.currentColor = 'red'
lib.previousColor = lib.currentColor

local slAnim = 0
local slOut = 'none'
local slIn = 'none'
local currentlyPlayingSong = nil

local hudIconTransitionActive = false
local hudIconTransitionTimer = 0

local hudIconTransitionDuration = 16


local dingSFX = Misc.resolveSoundFile("ding.ogg")
local blinkSFX = Misc.resolveSoundFile("blinker.ogg")
local resetColor = {}

-- Color definitions for the hue overlay
local colorList = {
  none = vector(1, 1, 1),
  green = vector(0.9, 1, 0.9),
  red = vector(1, 0.8, 0.8),
  yellow = vector(1, 0.95, 0.8),
}

-- Filepaths for the different music files used depending on the color
local musicList = {
  green = "Green-Light.ogg",
  yellow = "Green-Light.ogg",
  red = "Red-Light.ogg"
}

-- Position of each icon in the icons image
local iconSourceMap = {
  green = 0,
  yellow = 32,
  red = 64
}

-- Initialize everything for the transition animation
-- needs something so the animation doesnt cutoff if a new color happens mid animation
local function newCircleAnim(color)
  slAnim = 1
  slOut = slIn
  slIn = color
end

-- Transition between two different versions of the same song to give it that feeeel
local function musicChange(color, forced)
  local musicPath = "My Eyes Shine Bright with the City Lights/"..(musicList[color])

  if (musicPath == currentlyPlayingSong or musicPath == nil) and not forced then
    return
  end

  local musicPos
  if currentlyPlayingSong ~= nil then
    musicPos = Audio.MusicGetPos()
  end
  for sectionID = 0, 3 do
    Audio.MusicChange(sectionID, musicPath, 1000)
  end
  if musicPos then Audio.MusicSetPos(musicPos) end
  currentlyPlayingSong = musicPath

  -- Routine.run(function()
  --   local musicPos
  --
  --   if currentlyPlayingSong ~= nil then
  --     Audio.MusicStopFadeOut(100)  -- This is in miliseconds
  --     Routine.waitSeconds(0.1,true)    -- This is in seconds
  --     musicPos = Audio.MusicGetPos()
  --   end
  --
  --   currentlyPlayingSong = musicPath
  --
  --   Audio.MusicOpen(musicPath)
  --   Audio.MusicPlayFadeIn(50)  -- This is in miliseconds too!
  --
  --   if musicPos then
  --     Audio.MusicSetPos(musicPos)
  --   end
  -- end)
end


local yellowRout
lib.yellowTimer = 0
local function yellowFunc()
  local start = lib.yellowTimer

  for i = start, 0, -1 do
    lib.yellowTimer = i

    if i % 45 == 0 and i > 0 then
      SFX.play(blinkSFX)
    end
    Routine.skip()
  end

  lib.change("red")
end

-- Call this function to change the stoplight state
-- params:
--   params.disableEffect: Disables the color and music change
--   params.instant: Used to make the hue change instant (AKA disable the circle animation but keep the music change)
--   params.intro: Used to indicate this change is for the intro cutscene.
--   param.yellowTimer: Used when newColor is yellow. This is the time until the stoplight auto changes to red
function lib.change(newColor, params)
  params = params or {}

  -- Stop the yellow timer if the color is changed prematurely
  if yellowRout and yellowRout.isValid and yellowRout:getTime() > 0 then
    yellowRout:abort()
    lib.yellowTimer = 0
  end

  -- If color is set to yellow, begin a countdown until an automatic red change
  if newColor == "yellow" then
    lib.yellowTimer = params.yellowTimer or lunatime.toTicks(5)
    yellowRout = Routine.run(yellowFunc)
  end

  -- Run the neat transition effects
  if not params.disableEffect then
    newCircleAnim(newColor)
    if params.instant then
      slAnim = 0
    end

    if lib.currentColor ~= newColor then
      if musicList[newColor] then
        musicChange(newColor)
      end

      if not params.instant then
        SFX.play(dingSFX)

        hudIconTransitionActive = true
        hudIconTransitionTimer = 0
      end
    end
  end

  lib.intro = params.intro
  lib.previousColor = lib.currentColor
  lib.currentColor = newColor
  EventManager.callEvent("onStopLight", newColor) -- Will be useful once we start making the NPCs (maybe not)
end


function lib.onTick()
  -- Update the circle hue animation timer if active
  if slAnim > 0 then
    slAnim = math.max(0, slAnim - 1/32)
  end

  if hudIconTransitionActive then
    hudIconTransitionTimer = hudIconTransitionTimer + 1
    hudIconTransitionActive = (hudIconTransitionTimer < hudIconTransitionDuration)
  end
end


function lib.onDraw()
  capture:captureAt(5)

  -- shader for the circle hue overlay
  local radius = 500 - (500 - 32)*slAnim
  Graphics.drawScreen{texture = capture, priority = 5, shader = hueFilter, uniforms = {center = vector(400, 300), radius = radius, inColor = colorList[slIn], outColor = colorList[slOut]}}
end

Graphics.overrideHUD(function()
  -- draw the icon for the current color
  Graphics.drawImageWP(stopbox, 372, 16, 4.999)

  local displayColor = lib.currentColor
  local iconWidth = icons.width / 3
  local iconHeight = icons.height

  local iconOpacity = 1

  if hudIconTransitionActive then
    iconWidth = iconWidth * math.cos((hudIconTransitionTimer / hudIconTransitionDuration) * math.pi)

    if iconWidth > 0 then
      displayColor = lib.previousColor
    else
      iconWidth = -iconWidth
    end
  end

  if displayColor == "yellow" then
    if lib.yellowTimer > 64 then
      iconOpacity = math.lerp(1,0.25,math.abs(math.cos(lib.yellowTimer / 12)))
    elseif lib.yellowTimer%10 < 5 then
      iconOpacity = 0
    else
      iconOpacity = 0.75
    end
  end

  Graphics.drawBox{
    texture = icons,color = Color.white.. iconOpacity,
    centred = true,priority = 4.999,
    x = 400,y = 44,
    width = iconWidth,height = iconHeight,
    sourceWidth = icons.width / 3,sourceHeight = iconHeight,
    sourceX = iconSourceMap[displayColor],sourceY = 0,
  }

  --[[local sx = iconSourceMap[lib.currentColor]
  if lib.yellowTimer == 0 or lib.yellowTimer % 45 < 25 then
    Graphics.drawImageWP(icons, 400 - 16, 44 - 16, sx, 0, 32, 32, 5.1)
  end]]
end)

function lib.onRoomEnter(idx)
  if not resetColor[idx] then
    if lib.currentColor == "yellow" then
      resetColor[idx] = "red"
    else
      resetColor[idx] = lib.currentColor
    end
  end
end

function lib.onReset(fromRespawn)
  if fromRespawn then
    if resetColor[rooms.currentRoomIndex] == lib.currentColor then
      musicChange(resetColor[rooms.currentRoomIndex], true)
    end
    lib.change(resetColor[rooms.currentRoomIndex] or "red", {instant = true})
  end
end

function lib.onStart()
  -- Audio.SeizeStream(-1)
  lib.change(lib.currentColor, {disableEffect = true})    -- don't want cars to explode, after all.
end


function lib.onInitAPI()
  registerEvent(lib, 'onTick', 'onTick')
  registerEvent(lib, 'onDraw', 'onDraw')
  registerEvent(lib, 'onStart', 'onStart')
  registerEvent(lib, 'onRoomEnter', 'onRoomEnter')
  registerEvent(lib, 'onReset', 'onReset')
end

return lib
