local lib = {}

local sl = require("stoplight")
local littleDialogue = require("littleDialogue")
local exNPC = require("extraNPCProperties")
local active = false

local camAnim1 = 0
local camAnim1Active = false

local camAnim2 = 0
local camAnim2Start = 0
local camAnim2Stop = 0
local camAnim2Active = false

local makePlayerInvinsible = true
local disableInputs = false

local trafficSound

local function startCamera()
  Routine.waitFrames(60)
  camAnim1Active = true

  trafficSound.volume = 0.5
end

local function dialog()
  Routine.waitFrames(20)

  littleDialogue.create{text = "Come on... <tremble 1>move it</tremble>!!|I've been here for half a minute already!"}
  Routine.waitFrames(65*8)  -- (the reason I use waitFrames is because I set it to waitFrames(1) when im working in the intro)
  littleDialogue.create{text = "Alright, FINE...|I've clearly got to do something about this."}

  Routine.waitFrames(1)
  player.speedY = -6
  player.y = player.y - 4
  SFX.play(1)
  Routine.waitFrames(4)

  makePlayerInvinsible = false

  while (not player:isOnGround()) do
    Routine.skip()
  end

  disableInputs = false
end

local function dialog2()
  disableInputs = false
  littleDialogue.create{text = "OH NO|MY CAR|How am I going to get home now?"}
  Layer.get("IntroSigns"):show(false)
end

local function activateStopLight()
  disableInputs = true
  Layer.get("IntroWall"):hide(true)
  Layer.get("IntroProtect"):show(true)
  local marioCar = exNPC.getWithTag("mario_car")[1]

  marioCar.friendly = true
  repeat
    Routine.waitFrames(1)
  until player:isGroundTouching()
  Layer.get("IntroProtect"):hide(true)

  Routine.waitFrames(80)
  sl.change('green')
  Routine.waitFrames(10)

  camAnim2Active = true
  camAnim2Start = camera.x
  camAnim2Stop = marioCar.x - 400

  Routine.waitFrames(5)
  marioCar.friendly = false
  marioCar:kill()
  SFX.play(Misc.resolveSoundFile("nitro"))

  local e = Effect.spawn(NPC.config[marioCar.id].deathEffectID,marioCar.x + marioCar.width*0.5,marioCar.y + marioCar.height*0.5, marioCar.data.color)
  e.direction = marioCar.direction
  e.speedX = -3 * e.direction
  e.speedY = -12
  e.rotation = -18 * e.direction

  Routine.wait(1)

  for i = 0.5, 0, -0.008 do
    trafficSound.volume = i
    Routine.waitFrames(1)
  end
  trafficSound.volume = 0
  -- trafficSound.playing = false  -- not working for some reason???
end

function lib.begin()
  active = true
  disableInputs = true

  trafficSound = SFX.play{sound = Audio.SfxOpen(Misc.resolveFile("Traffic.ogg")), play = true, loops = 0}
  Routine.run(startCamera)
end

function lib.onInputUpdate()
  if disableInputs then
    for k, v in pairs(player.keys) do
      if not (Misc.isPaused() and k == "jump") then
        player.keys[k] = false
      end
    end
  end
end

function lib.onTick()
  if not active then return end

  if camAnim1Active and camAnim1 < 1 then
    camAnim1 = camAnim1 + 1/60
    if camAnim1 >= 1 then
      camAnim1Active = false
      Routine.run(dialog)
    end
  end
  if camAnim2Active and camAnim2 < 1 then
    camAnim2 = camAnim2 + 1/120
    if camAnim2 >= 1 then
      camAnim2Active = false
      Routine.run(dialog2)
    end
  end
end

function lib.onDraw()
  if not active then return end

  if makePlayerInvinsible then
    for k, p in ipairs(Player.get()) do
      p.frame = 100
    end
  end
end

function lib.onCameraUpdate(c)
  if not active then return end
  if c == 1 then
    if camAnim1Active or camAnim1 == 0 then
      local start = Section(0).boundary.right - 800
      local stop = player.x + 0.5*player.width - 400
      camera.x = start - (start - stop)*camAnim1
    elseif camAnim2Active then
      if camAnim2 < 0.4 then
        camera.x = camAnim2Start - (camAnim2Start - camAnim2Stop)*math.min(1, camAnim2/0.4)
      elseif camAnim2 > 0.8 then
        camera.x = camAnim2Stop - (camAnim2Stop - camAnim2Start)*(camAnim2 - 0.8)/(1 - 0.8)
      else
        camera.x = camAnim2Stop
      end
    end
  end
end

function lib.onStopLight(color)
  if not active then return end
  if sl.intro then
    Routine.run(activateStopLight)
  end
end

function lib.onReset()
  if not active then return end
  camAnim1 = 1
  camAnim1Active = false
  camAnim2 = 0
  camAnim2Active = false
end

function lib.onLoadSection1()
  active = false
  sl.intro = false
end

function lib.onInitAPI()
  registerEvent(lib, 'onTick', 'onTick')
  registerEvent(lib, 'onInputUpdate', 'onInputUpdate')
  registerEvent(lib, 'onDraw', 'onDraw')
  registerEvent(lib, 'onCameraUpdate', 'onCameraUpdate')
  registerEvent(lib, 'onLoadSection1', 'onLoadSection1')
  registerEvent(lib, 'onStopLight', 'onStopLight')
  registerEvent(lib, 'onReset', 'onReset')
end

return lib
