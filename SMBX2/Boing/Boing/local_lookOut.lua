local lookOut = {}

local inputs2 = API.load("inputs2")

local click = {}
local camera = {}
local hist = {}

local arrowUp = Graphics.loadImage(Misc.resolveFile("lookOut/up.png"))
local arrowDown = Graphics.loadImage(Misc.resolveFile("lookOut/down.png"))
local arrowLeft = Graphics.loadImage(Misc.resolveFile("lookOut/left.png"))
local arrowRight = Graphics.loadImage(Misc.resolveFile("lookOut/right.png"))
local isAnim = false
local isEnd = false
lookOut.speed = 5
lookOut.border = 50
lookOut.useCursor = true
lookOut.useArrows = true
lookOut.endCursor = true
lookOut.endPause = true
lookOut.endAnimation = true
lookOut.draw = true

function lookOut.onInitAPI()
	registerEvent(lookOut, "onCameraUpdate", "onCameraUpdate", true)
  	registerEvent(lookOut, "onDraw", "onDraw", true)
end

function lookOut.activate(x,y)
  hist.x = Camera.get()[1].x
  hist.y = Camera.get()[1].y
  if not x then x = Camera.get()[1].x end
  if not y then y = Camera.get()[1].y end
  camera.x = x
  camera.y = y
  isAnim = true
end
function lookOut.deactivate()
  if lookOut.endAnimation then
    isEnd = true
  else
    Misc.unpause()
  end
  isAnim = false
end
function lookOut.isActivated()
  return isAnim
end
function lookOut.isEnding()
  return isEnd
end

local arrowOffset = 0
local arrowDir = 1
function lookOut.onDraw()

  arrowOffset = arrowOffset + arrowDir
  if math.abs(arrowOffset) == 8 then
    arrowDir = arrowDir*(-1)
  end

  if not isAnim or not lookOut.draw then return end
  local bounds = Section(player.section).boundary
  if camera.x > bounds.left then
    Graphics.drawImageWP(arrowLeft,16 + arrowOffset,292,5)
  end
  if camera.x + 800 < bounds.right then
    Graphics.drawImageWP(arrowRight,768 - arrowOffset,292,5)
  end
  if camera.y > bounds.top then
    Graphics.drawImageWP(arrowUp,392,16 + arrowOffset,5)
  end
  if camera.y + 600 < bounds.bottom then
    Graphics.drawImageWP(arrowDown,392,568 - arrowOffset,5)
  end
end

function lookOut.onCameraUpdate()
  click.x = mem(0x00B2D6BC,FIELD_DFLOAT)
  click.y = mem(0x00B2D6C4,FIELD_DFLOAT)
  click.hold = mem(0x00B2D6CC,FIELD_BOOL)
  if click.hold and not histPress then
    click.click = true
  else
    click.click = false
  end
  histPress = click.hold
  histX = click.x
  histY = click.y
  if isEnd then

	  Misc.pause()
    local endSpeed = lookOut.speed*1.5
    if camera.x < hist.x then
      camera.x = camera.x + endSpeed
    elseif camera.x > hist.x then
      camera.x = camera.x - endSpeed
    end
    if camera.y < hist.y then
      camera.y = camera.y + endSpeed
    elseif camera.y > hist.y then
      camera.y = camera.y - endSpeed
    end
    if math.abs(camera.x - hist.x) < endSpeed then
      camera.x = hist.x
    end
    if math.abs(camera.y - hist.y) < endSpeed then
      camera.y = hist.y
    end
    if camera.x == hist.x and camera.y == hist.y then
      isEnd = false
      Misc.unpause()
    end
    Camera.get()[1].x = camera.x
    Camera.get()[1].y = camera.y
  end

  if isAnim then

	  Misc.pause()
    if (lookOut.endCursor and click.click) or (lookOut.endPause and inputs2.state[1].pause == inputs2.HOLD) then
      lookOut.deactivate()
    end
    if (lookOut.useCursor and click.x <= lookOut.border) or (lookOut.useArrows and inputs2.state[1].left == inputs2.HOLD) then
      camera.x = camera.x - lookOut.speed
    elseif (lookOut.useCursor and click.x >= 800 - lookOut.border) or (lookOut.useArrows and inputs2.state[1].right == inputs2.HOLD) then
      camera.x = camera.x + lookOut.speed
    end
    if (lookOut.useCursor and click.y <= lookOut.border) or (lookOut.useArrows and inputs2.state[1].up == inputs2.HOLD) then
      camera.y = camera.y - lookOut.speed
    elseif (lookOut.useCursor and click.y >= 600 - lookOut.border) or (lookOut.useArrows and inputs2.state[1].down == inputs2.HOLD) then
      camera.y = camera.y + lookOut.speed
    end
    local bounds = Section(player.section).boundary
    if camera.x < bounds.left then
      camera.x = bounds.left
    elseif camera.x + 800 > bounds.right then
      camera.x = bounds.right - 800
    end
    if camera.y < bounds.top then
      camera.y = bounds.top
    elseif camera.y + 600 > bounds.bottom then
      camera.y = bounds.bottom - 600
    end
    Camera.get()[1].x = camera.x
    Camera.get()[1].y = camera.y
  end
end

return lookOut
