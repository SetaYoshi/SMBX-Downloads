local teslacoil = {}

-- teslacoil.lua v1.0
-- Created by SetaYoshi
-- Sprite by Wonolf
-- Sound from https://www.youtube.com/watch?v=lWEFv8g3fQo

teslacoil.ID = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

-- SFX is chosen at random
local sfx = {}
local maxsfx = 0
while true do
  maxsfx = maxsfx + 1
  local p = Misc.resolveFile("teslacoil-"..maxsfx..".wav")
  if p then
    table.insert(sfx, Audio.SfxOpen(p))
  else
    break
  end
end

local function getBody(n, d)
  local x, y, w, h, id
  if d == 1 then
    x, y, w, h, id = n.x, n.y + n.height, n.width, 8, teslacoil.ID.body_hor
  elseif d == 2 then
    x, y, w, h, id = n.x + n.width, n.y, 8, n.height, teslacoil.ID.body_ver
  elseif d == 3 then
    x, y, w, h, id = n.x, n.y - 8, n.width, 8, teslacoil.ID.body_hor
  else
    x, y, w, h, id = n.x - 8, n.y, 8, n.height, teslacoil.ID.body_ver
  end
  for _, body in ipairs(Colliders.getColliding{a = Colliders.Box(x, y, w, h), b = id, btype = Colliders.NPC, filter = function(v) return true end}) do
    return body
  end
end

local function getDir(id)
  if id == teslacoil.ID.head_up or id == teslacoil.ID.althead_up then
    return 1
  elseif id == teslacoil.ID.head_left or id == teslacoil.ID.althead_left then
    return 2
  elseif id == teslacoil.ID.head_down or id == teslacoil.ID.althead_down then
    return 3
  elseif id == teslacoil.ID.head_right or id == teslacoil.ID.althead_right then
    return 4
  end
end

teslacoil.interaction = function(npc)
  if npc.id == 285 then
    npc:transform(431)
  elseif npc.id == 492 then
    npc:transform(493)
  elseif table.icontains({95, 98, 99, 100, 148, 149, 150, 228}, npc.id) then
    npc.ai1 = 1
  end
end

local function update(n, v, d)
  n.data.electric = v
  n.friendly = not v
  local x, y, w, h
  if d == 1 then
    x, y, w, h = n.x, n.y + n.height, n.width, 8
  elseif d == 2 then
    x, y, w, h = n.x + n.width, n.y, 8, n.height
  elseif d == 3 then
    x, y, w, h = n.x, n.y - 8, n.width, 8
  else
    x, y, w, h = n.x - 8, n.y, 8, n.height
  end

  if v then
    for _, npc in ipairs(Colliders.getColliding{a = n, b = teslacoil.ID.interactions, btype = Colliders.NPC, filter = function(v) return true end}) do
      teslacoil.interaction(npc)
    end
  end

  for _, body in ipairs(Colliders.getColliding{a = Colliders.Box(x, y, w, h), b = teslacoil.ID.body, btype = Colliders.NPC, filter = function(v) return true end}) do
    update(body, v, d)
  end
end


local function findNearest(n, x, y, name)
  name = name or ""
	local closest
	local closestdist = -1
	for _, head in ipairs(NPC.get(ID_head)) do
		local newdist = (x - head.x)^2 + (y - head.y)^2
    if n ~= head and (newdist < closestdist or closestdist == -1) and head.data.name == name then
      closestdist = newdist
			closest = head
		end
	end
	return closest
end



local head_iniNPC = function(n)
  if not n.data.ini then
    n.data.ini = true
		n.data.electric = false
    n.data.name = n.data._settings.name
    n.data.dest = n.data._settings.dest
    n.data.onTime = n.data._settings.onTime
    n.data.offTime = n.data._settings.offTime
    n.data.electric = n.data._settings.electric
    n.data.elecSpeed = n.data._settings.elecSpeed
    n.data.time = 0
    n.data.firsttime = true
  end
end

function teslacoil.head_onTickNPC(n)
  if Defines.levelFreeze or n:mem(0x12A, FIELD_WORD) <= 0 or n:mem(0x12C, FIELD_WORD) ~= 0 or n:mem(0x136, FIELD_BOOL) or n:mem(0x138, FIELD_WORD) > 0 then return end
  head_iniNPC(n)
  local data = n.data

  -- n:mem(0x128,	FIELD_BOOL, false)
  -- n:mem(0x12A, FIELD_WORD, 180)

  if data.firsttime then
    data.firsttime = false
    local body = getBody(n, getDir(n.id))
    if body then
      update(body, data.electric, getDir(n.id))
    end
  end

  data.time = data.time + 1
  if data.electric then
    if data.time >= n.data.onTime then
      data.electric = false
      data.time = 0

      if data.dest ~= "" then
        local dest = findNearest(n, n.x, n.y, n.data.dest)
        if dest then
          local ball = NPC.spawn(teslacoil.ID.elecBall, n.x, n.y, n.section)
          ball.data.dest = dest
          ball.data.speed = data.elecSpeed
        end
      end
      local body = getBody(n, getDir(n.id))
      if body then
        update(body, false, getDir(n.id))
      end
    end
  else
    if data.time >= data.offTime and data.offTime > 0 then
      data.electric = true
      data.time = 0

      SFX.play(RNG.irandomEntry(sfx))
      local body = getBody(n, getDir(n.id))
      if body then
        update(body, true, getDir(n.id))
      end
    end
  end

  for _, ball in ipairs(Colliders.getColliding{a = n, b = teslacoil.ID.elecBall, atype = Colliders.NPC, btype = Colliders.NPC, filter = function(v) return (v.data.dest == n or not v.data.dest) and (v.data.vec.x^2 + v.data.vec.y^2 <= 16) end}) do
    ball:kill()
    data.time = 0
    if not data.electric then
      local body = getBody(n, getDir(n.id))
      SFX.play(RNG.irandomEntry(sfx))
      if body then
        update(body, true, getDir(n.id))
      end
    end
    data.electric = true
  end

  n.friendly = not data.electric
end






-- AI althead
local function althead_iniNPC(n)
  if not n.data.ini then
    n.data.ini = true
		n.data.electric = false
    n.data.onTime = n.data._settings.onTime
    n.data.offTime = n.data._settings.offTime
    n.data.electric = n.data._settings.electric
    n.data.time = 0
    n.data.firsttime = true
  end
end

function teslacoil.althead_onTickNPC(n)
  if Defines.levelFreeze or n:mem(0x12A, FIELD_WORD) <= 0 or n:mem(0x12C, FIELD_WORD) ~= 0 or n:mem(0x136, FIELD_BOOL) or n:mem(0x138, FIELD_WORD) > 0 then return end
  althead_iniNPC(n)
  local data = n.data

  -- n:mem(0x128,	FIELD_BOOL, false)
  -- n:mem(0x12A, FIELD_WORD, 180)

  if data.firsttime then
    data.firsttime = false
    local body = getBody(n, getDir(n.id))
    if body then
      update(body, data.electric, getDir(n.id))
    end
  end

  data.time = data.time + 1
  if data.electric then
    if data.time >= data.onTime and data.offTime > 0 then
      data.electric = false
      data.time = 0

      local body = getBody(n, getDir(n.id))
      if body then
        update(body, false, getDir(n.id))
      end
    end
  else
    if data.time >= data.offTime and data.onTime > 0 then
      data.electric = true
      data.time = 0

      SFX.play(RNG.irandomEntry(sfx))
      local body = getBody(n, getDir(n.id))
      if body then
        update(body, true, getDir(n.id))
      end
    end
  end

  n.friendly = not data.electric
end






-- AI BODY
local body_iniNPC = function(n)
  if not n.data.ini then
    n.data.ini = true
    if n.data.electric == nil then
      n.data.electric = false
    end
  end
end

function teslacoil.body_onTickNPC(n)
  body_iniNPC(n)
  -- n:mem(0x128,	FIELD_BOOL, false)
  -- n:mem(0x12A, FIELD_WORD, 180)
end


-- General

function teslacoil.onDrawNPC(n)
	local config = NPC.config[n.id]
	if not config.nospecialanimation then
		local frames = config.frames - config.poweredframes
		local offset = 0
		local gap = config.collectedframes
		if n.data.electric then
			frames = config.poweredframes
			offset = config.frames - config.poweredframes
			gap = 0
		end
		n.animationFrame = npcutils.getFrameByFramestyle(n, { frames = frames, offset = offset, gap = gap })
	end
end

function teslacoil.onStart()
  local idlist = teslacoil.ID
  idlist.head = {idlist.head_up, idlist.head_left, idlist.head_down, idlist.head_right}
  idlist.body = {idlist.body_hor, idlist.body_ver}
  idlist.climbable_ver = {idlist.head_up, idlist.head_down, idlist.althead_up, idlist.althead_down, idlist.body_ver}
  idlist.climbable_hor = {idlist.head_left, idlist.head_right, idlist.althead_left, idlist.althead_right, idlist.body_hor}
  idlist.climbable = table.append(idlist.climbable_hor, idlist.climbable_ver)
  idlist.interactions = {95, 98, 99, 100, 148, 149, 150, 228, 285, 492}
end

function teslacoil.onInitAPI()
	registerEvent(teslacoil, "onStart", "onStart", true)
end

return teslacoil
