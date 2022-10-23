local holes = {}

-- holes.lua v1.6
-- Created by SetaYoshi
-- Sprite by Wonolf
-- Sound: https://www.soundsnap.com/user-name/blastwave_fx
--        https://www.youtube.com/watch?v=LnMhJU6RsYU

local blacklistNPC = {
  -- Example: 1, 2, 3
}

local blacklistBlock = {
  -- Example: 1, 2, 3
}


local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local WARPPTYPE_CENTER = 0
local WARPPTYPE_OFFSET = 1
local WARPPTYPE_INVOFFSET = 2

local sfx_enter = Audio.SfxOpen(Misc.resolveFile("holes-enter.wav"))
local sfx_exit = Audio.SfxOpen(Misc.resolveFile("holes-exit.wav"))

local holeslist = {}
local hideNPC = {}
local hideBlock = {}
local ribbonlist = {}

local totalWorms = 0
local iniNPC = function(n)
  local config = NPC.config[n.id]
  if not n.data.ini then
    n.data.ini = true
		totalWorms = totalWorms + 1
		n.data.id = totalWorms

		n.data.sprite = Sprite.box{x = n.x, y = n.y, width = npcutils.gfxwidth(n), height = npcutils.gfxheight(n), texture = Graphics.sprites.npc[n.id].img, rotation = 0, align = Sprite.align.CENTRE, frames = npcutils.getTotalFramesByFramestyle(n)}
    n.data.collider = Colliders.Circle(n.x + 0.5*n.width, n.y + 0.5*n.height, config.radius)

    n.data.name = n.data._settings.name
    n.data.dest = n.data._settings.dest
    n.data.deadly = n.data._settings.deadly
    n.data.pushforce = n.data._settings.pushforce

    n.data.scanPlayer = n.data._settings.scanPlayer
    n.data.scanNPC = n.data._settings.scanNPC
    n.data.scanBlock = n.data._settings.scanBlock

    n.data.teleradius = Colliders.Circle(0, 0, config.radius)
    n.data.forceradius = Colliders.Circle(0, 0, config.forceradius)
    local x = math.max(config.radius, config.forceradius)
    n.data.scanradius = Colliders.Circle(0, 0, math.floor(1.5*x))
  end
end

local function getSection(x, y)
	for k,v in ipairs(Section.get()) do
		local b = v.boundary
		if (x >= b.left and x <= b.right) and (y >= b.top and y <= b.bottom) then
			return k - 1
		end
	end
	return player.section
end

local function cx(obj)
	return obj.x + 0.5*obj.width
end
local function cy(obj)
	return obj.y + 0.5*obj.height
end

local function getOffX(obj, en)
  return cx(en) - cx(obj)
end
local function getOffY(obj, en)
	return cy(en) - cy(obj)
end

local disableinputs = function(p)
	p.keys.jump = false
	p.keys.altJump = false
	p.keys.run = false
	p.keys.altRun = false
	p.keys.up = false
	p.keys.down = false
	p.keys.left = false
	p.keys.right = false
	p.keys.jump = false
	p.keys.dropItem = false
end

local function getTransitonPos(en, ex, laser)
	local secdata = {}
	local s = Section(en.section).boundary

	local offset = 64*RNG.random(-1, 1)
	local d = {{en.x + offset, s.top}, {en.x + offset, s.bottom}, {s.left, en.y + offset}, {s.right, en.y + offset}}

	local key, min = 1, -1
	for k, v in ipairs(d) do
		local r = (v[1] - en.x)^2 + (v[2] - en.y)^2
		if min == -1 or r < min then
			key, min = k, r
		end
	end

	secdata.destX = d[key][1]
	secdata.destY = d[key][2]

	local s = Section(ex.section).boundary

	local offset = 64*RNG.random(-1, 1)
	local d = {{ex.x + offset, s.top}, {ex.x + offset, s.bottom}, {s.left, ex.y + offset}, {s.right, ex.y + offset}}

	local key, min = 1, -1
	for k, v in ipairs(d) do
		local r = (v[1] - ex.x)^2 + (v[2] - ex.y)^2
		if min == -1 or r < min then
			key, min = k, r
		end
	end
	secdata.secX = d[key][1]
	secdata.secY = d[key][2]

	return secdata
end

local worlddead = false
local function getExitPos(obj, ex, offX, offY)
  local config = NPC.config[ex.id]
	if config.warptype == WARPPTYPE_CENTER then
		return cx(ex) - 0.5*obj.width, cy(ex) - 0.5*obj.height
	elseif config.warptype == WARPPTYPE_OFFSET then
		return cx(ex) + offX - 0.5*obj.width,	cy(ex) + offY - 0.5*obj.height
	else
		return cx(ex) - offX - 0.5*obj.width,	cy(ex) - offY - 0.5*obj.height
	end
end

local function poofeffect(obj)
	if worlddead then return end
	local e = Animation.spawn(10, cx(obj), cy(obj))
	e.x = e.x - 0.5*e.width
	e.y = e.y - 0.5*e.height
end

local function findNearest(n, x, y, name)
  name = name or ""
	local closest
	local closestdist = -1
	for _, worm in ipairs(NPC.get(holeslist)) do
		local newdist = (x - worm.x)^2 + (y - worm.y)^2
    if n ~= worm and (newdist < closestdist or closestdist == -1) and (worm.data.name == name or name == "") then
      closestdist = newdist
			closest = worm
		end
	end
	return closest
end


local function createLaser(en, ex, obj)
  local config = NPC.config[en.id]
	local laser = {x = cx(obj), y = cy(obj), section = en.section, ribbon = Particles.Ribbon(0, 0, Misc.resolveFile("holes-ribbon.ini"))}
	laser.ribbon:Emit(1)
	if not config.disableribbon then
		table.insert(ribbonlist, laser.ribbon)
	end
	obj.laser = laser
	return laser
end

local function hide(en, ex, obj, laser)
	if type(obj) == "NPC" then
		obj.friendly = true
		obj.section = ex.section
		obj.x = en.x
		obj.y = en.y
		obj:mem(0x12A,	FIELD_WORD, 180)
  elseif type(obj) == "Block" then
		obj.section = ex.section
		obj.x = en.x
		obj.y = en.y
	else
		disableinputs(obj)
		obj:mem(0x140, FIELD_WORD, 2);
		obj:mem(0x142, FIELD_BOOL, true);
		obj.data.wormhole[en.data.id] = true
		obj.data.wormhole[ex.data.id] = true
		if obj.section == en.section then
			obj.x, obj.y = en.x, en.y
		elseif obj.section == ex.section then
			obj.x, obj.y = ex.x, ex.y
		else
			Misc.dialog("?")
		end
	end

	obj.speedX = 0
	obj.speedY = -Defines.npc_grav
end

local beginanim = function(en, ex, obj)
  poofeffect(obj)

  if type(obj) == "NPC" then
    table.insert(hideNPC, obj)
	  obj.data.wormhole_friendly = obj.friendly
		obj.data.wormhole_animFrame = obj.animationFrame
		obj.data.wormhole_animTimer = obj.animationTimer
  elseif type(obj) == "Block" then
    table.insert(hideBlock, obj)
    obj.isHidden = true
	else
		obj.data.jumpforce = obj:mem(0x11C, FIELD_WORD)
  end

	obj.data.inwormhole = true
	obj.data.wormhole_speedX = obj.speedX
	obj.data.wormhole_speedY = obj.speedY
end

local endanimation = function(en, ex, obj, laser, offX, offY)
  obj.x, obj.y = getExitPos(obj, ex, offX, offY)

	poofeffect(obj)
	laser.ribbon.enabled = false

	if type(obj) == "NPC" then
    obj.section = ex.section
		obj.friendly = obj.data.wormhole_friendly
		obj.data.disablewormhole = false
		obj.data.wormhole[ex.data.id] = true
    obj.animationFrame = obj.data.wormhole_animFrame
    obj.animationTimer = obj.data.wormhole_animTimer

		for k = #hideNPC, 1, -1 do
			local npc = hideNPC[k]
			if npc.isValid and obj == npc then
				table.remove(hideNPC, k)
				break
			end
		end
  elseif type(obj) == "Block" then
		obj.isHidden = false
    obj.data.disablewormhole = false
    obj.data.wormhole[ex.data.id] = true
    for k = #hideBlock, 1, -1 do
			local block = hideBlock[k]
			if block.isValid and obj == block then
				table.remove(hideBlock, k)
				break
			end
		end

    local b = Block.spawn(1,0,0)
    b:delete()
	else
    obj.section = ex.section
		obj.data.wormhole[ex.data.id] = true
		obj:mem(0x11C, FIELD_WORD, obj.data.jumpforce)
	end
	obj.data.inwormhole = false
	obj.speedX = obj.data.wormhole_speedX
	obj.speedY = obj.data.wormhole_speedY
end

local function chaos(obj)
	local t = 0
	while true do
		t = t + 1
		Defines.earthquake = math.min(t*0.1, 10)
		if t > 30 then
      NPC.spawn(210, obj.x + 128*RNG.random(-1, 1), obj.y + 64*RNG.random(-1, 1), obj.section)
		end
		if t > 60 then
			NPC.spawn(210, obj.x + 128*RNG.random(-1, 1), obj.y + 128*RNG.random(-1, 1), obj.section)
		end
		if t == 180 then
			for _, p in ipairs(Player.get()) do
				p:kill()
			end
		end
		Routine.waitFrames(1)
	end
end





-- This is the magic where it all happens
local teleport = function(en, ex, obj)
  local config = NPC.config[en.id]
	local offX, offY = getOffX(en, obj), getOffY(en, obj)
	local objType = type(obj)

  if objType == "NPC" and table.contains(holeslist, obj.id) and not worlddead then
		worlddead = true
    Routine.run(chaos(obj))
	end

  SFX.play(sfx_enter)

  -- If transiton effect is off, teleport the item immedietly
	if not config.transition or (not config.sectiontransition and en.section ~= ex.section) then
		poofeffect(obj)
		obj.x, obj.y = getExitPos(obj, ex, offX, offY)
		obj.section = ex.section
		poofeffect(obj)
    return
	end

  -- Ribbon and transition data
	local laser = createLaser(en, ex, obj)

  -- If entrance and exit are at different positions then get transition data
  local secdata
	if en.section ~= ex.section then
		secdata = getTransitonPos(en, ex, laser)
	end

  -- Begin the animation
	beginanim(en, ex, obj)

	while true do
		if not obj.isValid or not en.isValid or not ex.isValid then
			laser.ribbon.enabled = false
			break
		end

    -- Destination where laser is travelling
		local destx, desty = getExitPos(obj, ex, offX, offY)

		-- If entrance and exit are at different sections, then update the destination data
    if secdata and en.section == laser.section then
			destx, desty = secdata.destX, secdata.destY
		end

    -- Update laser speed
		local v = vector.v2(laser.x - destx - 0.5*obj.width, laser.y - desty - 0.5*obj.height)
		local w = config.laserspeed*(v:normalize())
		laser.x, laser.y = laser.x - w.x, laser.y - w.y
		laser.ribbon.x, laser.ribbon.y = laser.x, laser.y

    -- Hide warped object
    hide(en, ex, obj, laser)

    -- if laser reached destination, then exit animation
		if v.x^2 + v.y^2 < 64 then
			if secdata and laser.section == en.section then
				laser.x, laser.y, laser.section = secdata.secX, secdata.secY, ex.section
				laser.ribbon:Break()
			else
				SFX.play(sfx_exit)
				endanimation(en, ex, obj, laser, offX, offY)
				break
			end
		end

		Routine.waitFrames(1)
	end
end

local function scan(n, obj)
  local data = n.data
  if Colliders.collide(obj, n.data.teleradius) then
    if n.data.deadly then
      poofeffect(obj)
      if type(obj) == "Block" then
        obj:remove()
      else
        obj:kill()
      end
    else
      if not obj.data.wormhole[n.data.id] then
        obj.data.wormhole[n.data.id] = true
        local worm = findNearest(n, n.x + 0.5*n.width, n.y + 0.5*n.height, n.data.dest)
        if worm then
          obj.data.wormhole[worm.data.id] = true
          Routine.run(function() teleport(n, worm, obj) end)
        end
      end
    end
  else
    obj.data.wormhole[n.data.id] = false
  end
end

local function push(n, obj)
  if Colliders.collide(obj, n.data.forceradius) then
    local v = vector.v2(getOffX(n, obj), getOffY(n, obj))
    v = n.data.pushforce*(v:normalize())
    if type(obj) == "Block" then
      obj.data.spx = obj.data.spx or 0
      obj.data.spy = obj.data.spy or 0
      obj.data.spx, obj.data.spy = obj.data.spx + v.x, obj.data.spy + v.y
      obj.x, obj.y = obj.x + obj.data.spx, obj.y + obj.data.spy
    else
      obj.speedX, obj.speedY = obj.speedX + v.x, obj.speedY + v.y
    end
  end
end


local function filternpc(obj)
  if not obj.data.disablewormhole  and not (blacklistNPC[obj.id] or obj:mem(0x12C, FIELD_WORD) ~= 0) and not (obj.data and obj.data.inwormhole) then
    return true
  end
end
local function filterblock(obj)
  if not obj.data.disablewormhole and not (obj.data and obj.data.inwormhole) and not (blacklistBlock[obj.id] or obj.isHidden) then
    return true
  end
end

function holes.onTickNPC(n)
  iniNPC(n)
  local data = n.data
  local config = NPC.config[n.id]
  if not (data._basegame.lineguide and data._basegame.lineguide.state == 1) then
    n.speedX, n.speedY = npcutils.getLayerSpeed(n)
  end

  local ncx, ncy = cx(n), cy(n)
  data.scanradius.x, data.scanradius.y = ncx, ncy
  data.teleradius.x, data.teleradius.y = ncx, ncy
  data.forceradius.x, data.forceradius.y = ncx, ncy

  -- Adjust sprite and collision
	data.sprite:rotate(config.rotationspeed*n.direction)
  data.collider.x = n.x + 0.5*n.width

  -- Search for players that should be warped
	if n.data.scanPlayer then
    local list_player = Player.get()
		for _, p in ipairs(list_player) do
      p.data = p.data or {}
      p.data.wormhole = p.data.wormhole or {}
      if n.data.pushforce ~= 0 then
        push(n, p)
      end
      if p.deathTimer == 0 then
        scan(n, p)
      end
		end
	end

	-- Search for NPCs that should be warped
	if n.data.scanNPC then
    local npc_list = Colliders.getColliding{a = data.scanradius, b = NPC.ALL, btype = Colliders.NPC, filter = npcfilter}
		for _, npc in ipairs(npc_list) do
      npc.data.wormhole = npc.data.wormhole or {}
      if n.data.pushforce ~= 0 then
        push(n, npc)
      end
      if npc ~= n then
        scan(n, npc)
      end
		end
	end

  -- Search for Blocks that should be warped
  if n.data.scanBlock then
    for _, b in ipairs(Colliders.getColliding{a = data.scanradius, b = Block.ALL, btype = Colliders.BLOCK, filter = blockfilter}) do
      b.data = b.data or {}
      b.data.wormhole = b.data.wormhole or {}
      if n.data.pushforce ~= 0 then
        push(n, b)
      end
      scan(n, b)
    end
  end

end

function holes.onDrawNPC(n)
  local config = NPC.config[n.id]
  local p = -45
  if config.foreground then	p = -15	end
  n.data.sprite.x = n.x + n.width*0.5 + config.gfxoffsetx
  n.data.sprite.y = n.y + n.height*0.5 + config.gfxoffsety
  n.data.sprite:draw{priority = p - 0.1, sceneCoords = true, frame = n.animationFrame + 1}
  npcutils.hideNPC(n)
end

function holes.onCameraDraw(c)
  if c ~= 1 then return end
  -- Hide NPCs that are in laser mode
	for k = #hideNPC, 1, -1 do
		local n = hideNPC[k]
		if n.isValid then
			n.animationFrame = -999
			n.animationTimer = 1
		else
			table.remove(hideNPC, k)
		end
	end

  -- Draw all the ribbons
	for k = #ribbonlist, 1, -1 do
		local p = ribbonlist[k]
		if p:Count() > 0 then
			p:Draw(-60)
		else
			table.remove(ribbonlist, k)
		end
	end
end

-- Adjust the camera to the laser if a player is warping
function holes.onCameraUpdate(idx)
	if idx == 2 then return end
  local c, p
	if idx == 1 and player.data and player.data.inwormhole then
		c, p = camera, player
	elseif idx == 2 and player.data and player2.data.inwormhole then
		c, p = camera2, player2
	end

	if c then
		c.x, c.y = p.laser.x - 400, p.laser.y - 300

		-- Make sure that the camera doesnt go outside the section's boundary

    sec = Section(getSection(c.x + 2, c.y + 2, 800, 600)).boundary
    camera.x, camera.y = math.clamp(sec.left, c.x, sec.right - 800), math.clamp(sec.top, c.y, sec.bottom - 600)
    p.section = p.laser.section
	end
end

function holes.register(id)
  table.insert(holeslist, id)
end

function holes.onInitAPI()
	registerEvent(holes, "onCameraDraw", "onCameraDraw", true)
	registerEvent(holes, "onCameraUpdate", "onCameraUpdate", true)
end

return holes
