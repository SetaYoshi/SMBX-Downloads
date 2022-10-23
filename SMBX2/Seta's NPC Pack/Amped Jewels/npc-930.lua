local jewel = {}

-- AmpedJewel.lua v1.1
-- Created by SetaYoshi
-- Sprite by Void
-- Sound from https://www.youtube.com/watch?v=lWEFv8g3fQo

local npcManager = require("npcManager")
local textplus = require("textplus")
local npcutils = require("npcs/npcutils")
local lineguide = require("lineguide")

local npcID = NPC_ID
local sfx_power = Audio.SfxOpen("ampedjewel-powered.wav")

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

	jumphurt = true,
  noblockcollision = true,
  spinjumpsafe = true,
  nogravity = true,
  notcointransformable = true,
	nohurt = true,
	noyoshi = true,

  poweredframes = 1,
  lightningframes = 3,
  lightningframespeed = 2
})
npcManager.registerHarmTypes(npcID, {HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP}, {[HARM_TYPE_JUMP] = 10, [HARM_TYPE_SPINJUMP] = 10})

lineguide.registerNpcs(npcID)
local light = Graphics.loadImage(Misc.resolveFile("npc-"..npcID.."-1.png"))

local sfxjump = 2
local jewelid = 0
local reset = true
local rays = {}

local function shareval(t1, t2)
  for i = 1, #t1 do
    for j = 1, #t2 do
      if t1[i] == t2[j] then return true end
    end
  end
end

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function iniCheck(n)
  local data = n.data
  if not data.check then
    data.check = true
    data.ontime = data._settings.ontime
    data.offtime = data._settings.offtime
    data.timer = data.timer or 0

    data.hitbox = Colliders.Circle(0, 0, 1)
		data.wasactive = true
    data.active = false
    data.connections = {}


    data.tags = {}
    data.tagstext = string.split(data._settings.tagstext, ",")
    for i = 1, #data.tagstext do
      data.tags[i] = trim(data.tagstext[i])
    end

    jewelid = jewelid + 1
    data.index = jewelid

    data.lightframe = 0
    data.lightanimationframe = 0
  end
end

function jewel.onTickNPC(n)
  local data = n.data
  iniCheck(n)
	if not (data._basegame.lineguide and data._basegame.lineguide.state == 1) then
		n.speedX, n.speedY = npcutils.getLayerSpeed(n)
	end

	if reset then
		rays = {}
		reset = false
	end

  if data.offtime ~= 0 then
    data.timer = data.timer + 1
    if data.timer > data.ontime + data.offtime then
      data.timer = 0
    end
  end

  if data.timer <= data.ontime then
    data.hitbox.x, data.hitbox.y = n.x + 0.5*n.width, n.y + 0.5*n.height
    data.hitbox.radius = 1000

    if n.data.tags[1] ~= "" then
      for _, npc in ipairs(Colliders.getColliding{a = data.hitbox, b = npcID, btype = Colliders.NPC, filter = function(npc) return npc.data.check and n ~= npc and (not npc.data.connections[n.data.index]) and (npc.data.timer <= npc.data.ontime or npc.data.offtime == 0) and shareval(n.data.tags, npc.data.tags) end}) do
        n.data.active = true
        npc.data.active = true
        n.data.connections[npc.data.index] = true
        table.insert(rays, {start = n, stop = npc, frame = data.lightframe})
      end
    end
  else
    data.frameY = 0
  end

	if data.active then
		if not data.wasactive and data.offtime > 0 then
			SFX.play(sfx_power)
		end
		data.wasactive = true
	else
		data.wasactive = false
	end
end

function jewel.onTick()
  local pl = Player.get()
  for i = #rays, 1, -1 do
    local ray = rays[i]
    if not ray.start or not ray.stop or not ray.start.isValid or not ray.stop.isValid then
      table.remove(rays, i)
    else
      local start = vector.v2(ray.start.x + 0.5*ray.start.width, ray.start.y + 0.5*ray.start.height)
      local stop = vector.v2(ray.stop.x + 0.5*ray.stop.width, ray.stop.y + 0.5*ray.stop.height)
      for k, p in ipairs(pl) do
        if Colliders.linecast(start, stop, p) then
          p:harm()
        end
      end
    end
  end
end

function jewel.onTickEndNPC(n)
  n.data.connections = {}
  n.data.power = 0
  n.data.active = false
	reset = true
end

function jewel.onDrawNPC(n)
	local data = n.data
	iniCheck(n)
  n.data.lightanimationframe = n.data.lightanimationframe + 1
  if n.data.lightanimationframe > config.lightningframespeed then
    n.data.lightanimationframe =  0
    n.data.lightframe = n.data.lightframe + 1
    if n.data.lightframe >= config.lightningframes then
      n.data.lightframe =  0
    end
  end
  if not config.nospecialanimation then
    local frames = config.frames - config.poweredframes
    local offset = 0
    local gap = config.collectedframes
    if n.data.timer <= data.ontime then
      frames = config.poweredframes
      offset = config.frames - config.poweredframes
      gap = 0
    end
    n.animationFrame = npcutils.getFrameByFramestyle(n, { frames = frames, offset = offset, gap = gap })
  end
end

-- Huge Thanks to Mr.DoubleA for helping me getting this to work!
local function tableMultiInsert(tbl,tbl2) -- I suppose that I now use this any time I use glDraw, huh
    for _,v in ipairs(tbl2) do
        table.insert(tbl,v)
    end
end

function jewel.onDraw()
  local p = -45
  if config.foreground then
    p = -15
  end
  for i = #rays, 1, -1 do
    local ray = rays[i]
    if ray.start and ray.stop and ray.start.isValid and ray.stop.isValid then
      local start = vector.v2(ray.start.x + 0.5*ray.start.width, ray.start.y + 0.5*ray.start.height)
      local stop = vector.v2(ray.stop.x + 0.5*ray.stop.width, ray.stop.y + 0.5*ray.stop.height)
			local frames = config.lightningframes
      local frame = ray.frame
      local laserLength = (start - stop).length
      local vertexCoords,textureCoords = {},{}
      local v = start
      local w = (stop - start):normalize()
      local n = (w:normalize()):rotate(90)*light.height/(frames*2)
      while i <= laserLength do
        local segmentLength = math.min(light.width, laserLength - i)
        local y = w*segmentLength
        local z1, z2, z3, z4 = v + n, v - n, v + y + n, v + y - n
        tableMultiInsert(vertexCoords,{z1.x, z1.y, z2.x, z2.y, z4.x, z4.y, z1.x, z1.y, z3.x, z3.y, z4.x, z4.y})
        tableMultiInsert(textureCoords,{0,((frame  )/frames), 0 ,((frame+1)/frames), (segmentLength/light.width),((frame+1)/frames), 0,((frame  )/frames), (segmentLength/light.width),((frame  )/frames), (segmentLength/light.width),((frame+1)/frames)})
        v = v + y
        i = i + light.width
      end
      Graphics.glDraw{texture = light, vertexCoords = vertexCoords,textureCoords = textureCoords, priority = p-0.01,sceneCoords = true}
    end
  end
end

function jewel.onNPCHarm(event, n, reason, culprit)
  if n.id == npcID and (reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP) then
    SFX.play(sfxjump)
    if n.data.power > 0 then
      culprit:harm()
    end
    event.cancelled = true
  end
end

function jewel.onInitAPI()
  npcManager.registerEvent(npcID, jewel, "onTickNPC", "onTickNPC")
  npcManager.registerEvent(npcID, jewel, "onTickEndNPC", "onTickEndNPC")
  npcManager.registerEvent(npcID, jewel, "onDrawNPC", "onDrawNPC")

	registerEvent(jewel, "onNPCHarm", "onNPCHarm")
  registerEvent(jewel, "onTick", "onTick")
  registerEvent(jewel, "onDraw", "onDraw")
end

return jewel
