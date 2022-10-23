local jewel = {}

local redstone = require("redstone")
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local lineguide = require("lineguide")

local min = math.min
local insert, remove = table.insert, table.remove
local split, trim = string.split, string.trim

jewel.name = "jewel"
jewel.id = NPC_ID

jewel.test = function()
  return "isJewel", function(x)
    return (x == jewel.id or x == jewel.name)
  end
end

jewel.config = npcManager.setNpcSettings({
	id = jewel.id,

  width = 32,
  height = 32,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 1,
	framespeed = 8,
	framestyle = 0,
  invisible = false,
  mute = false,

	jumphurt = false,
  noblockcollision = true,
  spinjumpsafe = false,
  nogravity = true,
  notcointransformable = true,
	nohurt = true,
	noyoshi = true,

  lightningframes = 3,  -- The amount of frames in the lightning image
  lightningframespeed = 2,  -- The framespeed for the lightning animation
  lightningthickness = -1,  -- Set -1 for random, otherwise use this value
})
npcManager.registerHarmTypes(jewel.id, {HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP}, {[HARM_TYPE_JUMP] = 10, [HARM_TYPE_SPINJUMP] = 10})

lineguide.registerNpcs(jewel.id)

local ilightning = Graphics.loadImage(Misc.resolveFile("npc-"..jewel.id.."-1.png"))
local rayWidth, rayHeight = ilightning.width, ilightning.height/jewel.config.lightningframes

local sfxpower = Audio.SfxOpen(Misc.resolveFile("ampedjewel-powered.ogg"))
local sfxjump = 2

local jewid = 0
local reset = {}
local rays = {}

local function shareval(t1, t2)
  for i = 1, #t1 do
    for j = 1, #t2 do
      if t1[i] == t2[j] then return true end
    end
  end
end

local function tableMultiInsert(tbl,tbl2)
  for _, v in ipairs(tbl2) do
    insert(tbl, v)
  end
end

function jewel.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.type or 0
  data.frameY = data.frameY or 0

  jewid = jewid + 1
  data.index = data.inedx or jewid
  data.active = data.ective or false
  data.connections = {}

  local tagstext = split(data._settings.tagstext, ",")
  data.pins = {}
  for i = 1, #tagstext do
    data.pins[i] = trim(tagstext[i])
  end

  data.lightAnimFrame = data.lightAnimFrame or 0
  data.lightAnimTimer = data.lightAnimTimer or 0
  data.lightThickness = data.lightThickness or RNG.random(1, 2)

  data.hitbox = Colliders.Circle(0, 0, 1000)
end

function jewel.onRedTick(n)
  local data = n.data
  data.observ = false

  redstone.setLayerLineguideSpeed(n)
  if reset then
    rays = {}
    reset = false
  end

  if data.power == 0 then
    data.frameY = 0
  else
    data.frameY = 1
    data.hitbox.x, data.hitbox.y = n.x + 0.5*n.width, n.y + 0.5*n.height

    if n.data.pins[1] ~= "" then
      for _, npc in ipairs(Colliders.getColliding{a = data.hitbox, b = jewel.id, btype = Colliders.NPC, filter = function(npc) return n ~= npc and (not npc.data.connections[n.data.index]) and (npc.data.power > 0 or npc.data.powerPrev > 0) and shareval(n.data.pins, npc.data.pins) end}) do
        npc.data.active = true
        n.data.active = true
        n.data.connections[npc.data.index] = true
        insert(rays, {startNPC = n, stopNPC = npc, frame = data.lightAnimFrame, thickness = data.lightThickness})
      end
    end

    if data.powerPrev == 0 and redstone.onScreenSound(n) then
      SFX.play(sfxpower)
    end
  end

  if (data.power ~= 0 and data.powerPrev == 0) or (data.power == 0 and data.powerPrev ~= 0) then
    data.observ = true
  end

  data.lightAnimTimer = data.lightAnimTimer + 1
  if data.lightAnimTimer >= jewel.config.lightningframespeed then
    data.lightAnimTimer =  0
    data.lightAnimFrame = data.lightAnimFrame + 1
    if data.lightAnimFrame >= jewel.config.lightningframes then
      data.lightAnimFrame =  0
    end
  end

  redstone.resetPower(n)
end

function jewel.onTick()
  local playerList = Player.get()

  for i = #rays, 1, -1 do
    local ray = rays[i]
    if not (ray.startNPC and ray.stopNPC) and not (ray.startNPC.isValid and ray.stopNPC.isValid) then
      remove(rays, i)
    else
      local start = vector(ray.startNPC.x + 0.5*ray.startNPC.width, ray.startNPC.y + 0.5*ray.startNPC.height)
      local stop = vector(ray.stopNPC.x + 0.5*ray.stopNPC.width, ray.stopNPC.y + 0.5*ray.stopNPC.height)
      for k, p in ipairs(playerList) do
        if Colliders.linecast(start, stop, p) then
          p:harm()
        end
      end
    end
  end
end

function jewel.onRedTickEnd(n)
  n.data.connections = {}
  n.data.active = false

	reset = true
end

jewel.onRedDraw = redstone.drawNPC


local function drawRay(start, stop, frame, thickness)
  local p = -45
  if jewel.config.foreground then p = -15 end
  if jewel.config.lightningthickness ~= -1 then thickness = jewel.config.lightningthickness end

  local lenght = (start - stop).length
  local vertexCoords,textureCoords = {}, {}
  local direction = (stop - start):normalize()
  local lineWidth = thickness*direction:rotate(90)*rayHeight/jewel.config.lightningframes

  local texX, texY, texH = (1 - (1.8*lunatime.tick() % rayWidth)/rayWidth),  frame/jewel.config.lightningframes, (frame + 1)/jewel.config.lightningframes
  local segment = start

  local j = 0
  while j < lenght do
    local segmentLength = math.min(lenght - j, (1 - texX)*rayWidth)
    local texW = segmentLength/rayWidth + texX

    local y = direction*segmentLength
    local z1, z2, z3, z4 = segment + lineWidth, segment - lineWidth, segment + y + lineWidth, segment + y - lineWidth

    tableMultiInsert(vertexCoords, {z1.x, z1.y, z2.x, z2.y, z4.x, z4.y, z1.x, z1.y, z3.x, z3.y, z4.x, z4.y})
    tableMultiInsert(textureCoords,{texX, texY, texX, texH, texW, texH, texX, texY, texW, texY, texW, texH})

    texX = 0
    segment = segment + y
    j = j + segmentLength
  end

  Graphics.glDraw{texture = ilightning, vertexCoords = vertexCoords,textureCoords = textureCoords, priority = p - 0.01, sceneCoords = true}
end

-- Huge Thanks to Mr.DoubleA for helping me getting this to work!
function jewel.onDraw()
  if jewel.config.invisible then return end

  local p = -45
  if jewel.config.foreground then p = -15 end

  for i = #rays, 1, -1 do
    local ray = rays[i]
    if (ray.startNPC and ray.stopNPC) and (ray.startNPC.isValid and ray.stopNPC.isValid) then
      local start = vector.v2(ray.startNPC.x + 0.5*ray.startNPC.width, ray.startNPC.y + 0.5*ray.startNPC.height)
      local stop = vector.v2(ray.stopNPC.x + 0.5*ray.stopNPC.width, ray.stopNPC.y + 0.5*ray.stopNPC.height)
      drawRay(start, stop, ray.frame, ray.thickness)
    else
      remove(rays, i)
    end
  end
end

function jewel.onNPCHarm(event, n, reason, culprit)
  if n.id == jewel.id and (reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP) then
    SFX.play(sfxjump)
    if n.data.power > 0 or n.data.powerPrev > 0 then
      culprit:harm()
    end
    event.cancelled = true
  end
end

function jewel.onInitAPI()
	registerEvent(jewel, "onNPCHarm", "onNPCHarm")
  registerEvent(jewel, "onTick", "onTick")
  registerEvent(jewel, "onDraw", "onDraw")
end

redstone.register(jewel)

return jewel
