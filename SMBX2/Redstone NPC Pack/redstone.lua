local redstone = {}

--  =================================
--  ====    Redstone.lua v1.3.0  ====
--  ====      By  SetaYoshi      ====
--  =================================


function string.startswith(str, start)
  return str:sub(1, #start) == start
end

function string.endswith(str, ending)
	return ending == "" or str:sub(-#ending) == ending
end

--[[

  ██████╗░███████╗██████╗░░██████╗████████╗░█████╗░███╗░░██╗███████╗  ██╗░░░██╗░░███╗░░░░░██████╗░
  ██╔══██╗██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔══██╗████╗░██║██╔════╝  ██║░░░██║░████║░░░░░╚════██╗
  ██████╔╝█████╗░░██║░░██║╚█████╗░░░░██║░░░██║░░██║██╔██╗██║█████╗░░  ╚██╗░██╔╝██╔██║░░░░░░█████╔╝
  ██╔══██╗██╔══╝░░██║░░██║░╚═══██╗░░░██║░░░██║░░██║██║╚████║██╔══╝░░  ░╚████╔╝░╚═╝██║░░░░░░╚═══██╗
  ██║░░██║███████╗██████╔╝██████╔╝░░░██║░░░╚█████╔╝██║░╚███║███████╗  ░░╚██╔╝░░███████╗██╗██████╔╝
  ╚═╝░░╚═╝╚══════╝╚═════╝░╚═════╝░░░░╚═╝░░░░╚════╝░╚═╝░░╚══╝╚══════╝  ░░░╚═╝░░░╚══════╝╚═╝╚═════╝░
  
  ██████╗░██╗░░░██╗  ░██████╗███████╗████████╗░█████╗░██╗░░░██╗░█████╗░░██████╗██╗░░██╗██╗
  ██╔══██╗╚██╗░██╔╝  ██╔════╝██╔════╝╚══██╔══╝██╔══██╗╚██╗░██╔╝██╔══██╗██╔════╝██║░░██║██║
  ██████╦╝░╚████╔╝░  ╚█████╗░█████╗░░░░░██║░░░███████║░╚████╔╝░██║░░██║╚█████╗░███████║██║
  ██╔══██╗░░╚██╔╝░░  ░╚═══██╗██╔══╝░░░░░██║░░░██╔══██║░░╚██╔╝░░██║░░██║░╚═══██╗██╔══██║██║
  ██████╦╝░░░██║░░░  ██████╔╝███████╗░░░██║░░░██║░░██║░░░██║░░░╚█████╔╝██████╔╝██║░░██║██║
  ╚═════╝░░░░╚═╝░░░  ╚═════╝░╚══════╝░░░╚═╝░░░╚═╝░░╚═╝░░░╚═╝░░░░╚════╝░╚═════╝░╚═╝░░╚═╝╚═╝
  
]]
  

local expandedDefines = require("expandedDefines")
local npcutils = require("npcs/npcutils")
local textplus = require("textplus")
local repl = require("base/game/repl")

local insert, map, unmap, append, remove = table.insert, table.map, table.unmap, table.append, table.remove
local min, max, abs, clamp = math.min, math.max, math.abs, math.clamp
local split, gmatch, find, sub, startswith, endswith = string.split, string.gmatch, string.find, string.sub


--[[
  TODO
  fix up transmitter
  fix up source (use flame algorithm)
]]

-- Set this to false and the script will no longer stop NPCs from despawning. This will reduce lag in your level! I reccomend you set this to false and install spawnzones into your level
redstone.disabledespawn = false

redstone.componentList = {}
redstone.component = {}

-- Function to register a component
function redstone.register(module)
  module.name = module.name or "noname_"..RNG.randomInt(1000, 9999)
  module.order = module.order or 0.5
  module.config = module.config or NPC.config[module.id]
  module.test = function(x) return (x == module.id or x == module.name)  end
  
  redstone.component[module.name] = module
  table.insert(redstone.componentList, module)
end


redstone.is = {}
setmetatable(redstone.is, {
  __index = function(t, k)
    local com = redstone.component[k]
    if com then
      return com.test
    else
      return function() return false end
    end
  end,
  
  __call = function(t, x, ...)
    local inp = {...}
  
    for k, v in ipairs(inp) do
      local is = redstone.is[v](x)
      if is then
        return true
      end
    end
  
    return false
  end,
})


redstone.id = {}
setmetatable(redstone.id, {
  __index = function(t, k)
    local com = redstone.component[k]
    if com then
      return com.id
    end
  end,
  
  __call = function(t, ...)
    local inp = {...}
    local out = {}
  
    for k, v in ipairs(inp) do
      local id = redstone.id[v]
      if id then
        table.insert(out, id)
      end
    end
  
    return out
  end,
})



-- Helper functions
-- All the following functions can be used by other NPCs and inside of control chips and command blocks
--[[
  Terminology:

  n: NPC being powered
  c: compenent providing power
  p: The amount of power being provided
  d: The direction being provided
  hitbox: The hitbox of the power provided
--]]

--[[
  @setEnergy(npc, power, dir)
  Adds energy to an NPC
    npc:   The NPC that energy will be applied to
    power: The energy level that will be applied. If the NPC already has a higher energy level, nothing will happen
    dir:   Optional, the direction the energy is applied [0: left, 1:up, 2:right, 3:down]
]]

function redstone.setEnergy(n, p, d)
  if not n.data.power then return end
  if p > n.data.power then
    n.data.power = p
    if d then
      n.data.dir = (d + 2)%4
    else
      n.data.dir = -1
    end
  end
end


--[[
  @energyFilter(n, c, power, dir, hitbox)
  Adds energy to an NPC following standard filter procedures. This function checks if an NPC has criteria for being powered
    n:       The NPC that energy will be applied to
    c:       The NPC that is supplying the energy
    power:   The energy level being applied
    dir:     The direction the energy is applied [0: left, 1:up, 2:right, 3:down]
    hitbox:  The hitbox that was used to apply energy
]]
function redstone.energyFilter(n, c, p, d, hitbox)
  if n == c then return end
  n.data.power = n.data.power or 0

  local component = redstone.comList[n.id]
  if component and component.onRedPower then
    return component.onRedPower(n, c, p, d, hitbox)
  else
    redstone.setEnergy(n, p)
  end
end

-- A function that always returns true. Can be used in filters in getColliding
function redstone.nofilter() return true end

-- A function that returns true when an NPC is not hidden. Can be used in filters in getColliding
function redstone.nothidden(v) return not v.isHidden end


--[[
  @passEnergy(args)
  Passes energy to the sorroundings of the NPC in all directions
    source: The NPC being the source of power
    power: The amount of power being provided
    area: Collider box representing area from where to search NPCs.
    npcList: List of NPCs the power should affect
    hitbox: The list collision box of the power as a box collider {x, y, w, h, direction}
      direction of power (0:left, 1:up, 2:right, 3:down). If left empty then direction is universal
]]
function redstone.passEnergy(args)
  args.npcList = args.npcList or redstone.comID
  args.filter = args.filter or redstone.nothidden

  local list = Colliders.getColliding{a = args.area, b = args.npcList, btype = Colliders.NPC, filter = args.filter}
  local found = false

  for _, v in ipairs(args.hitbox) do
    for i = #list, 1, -1 do
      local n = list[i]
      if Colliders.collide(v, n) then
        local power = args.power

        if args.powerAI then power = args.powerAI(n, args.source, args.power, v.direction, v) end
        local cancelled = redstone.energyFilter(n, args.source, power, v.direction, v)

        if not cancelled then
          found = true
          remove(list, i)
        end
      end
    end
  end

  return found
end


--[[
  @passDirectionEnergy(args)
  Passes energy in a single direction
    source: The NPC being the source of power
    power: The amount of power being provided
    npcList: List of NPCs the power should affect
    hitbox: The collision box of the power as a box collider {x, y, w, h, direction}
      direction of power (0:left, 1:up, 2:right, 3:down). If left empty then direction is universal
]]
function redstone.passDirectionEnergy(args)
  local c = args.hitbox
  args.npcList = args.npcList or redstone.comID
  local list = Colliders.getColliding{a = c, b = args.npcList, btype = Colliders.NPC, filter = redstone.nothidden}
  for _, n in ipairs(list) do
    if Colliders.collide(c, n) then
      local power = args.power
      if args.powerAI then power = args.powerAI(n, args.source, args.power, c.direction, c)  end
      redstone.energyFilter(n, args.source, power, c.direction, c)
    end
  end
end

--[[
  @passInventory
  Passes inventory items. Returns true if the pass is successful
    source: The NPC being the source of the inventory
    inventory: The inventory ID being passed
    npcList: List of NPCs the power should affect
    hitbox: The collision box of the power as a box collider {x, y, w, h}
]]
function redstone.passInventory(args)
  local c = args.hitbox
  args.npcList = args.npcList or redstone.comID
  local list = Colliders.getColliding{a = c, b = args.npcList, btype = Colliders.NPC, filter = redstone.nofilter}
  for _, n in ipairs(list) do
    if Colliders.collide(c, n) and n.data.invspace then
      local com = redstone.comList[n.id]
      if com.onRedInventory then
        return not com.onRedInventory(n, args.source, args.inventory, c.direction, c)
      else
        n.data.inv = args.inventory
        return true
      end
    end
  end
end


--[[
  @basicRedArea(npc)
  Creates a hitbox to be used for internal redstone functions. Used to filter down NPCs when passing power.
  Hitbox can be updated using @updateRedArea
    npc: NPC whose area will be applied to
]]
function redstone.basicRedArea(n)
  return Colliders.Box(0, 0, 1.5*n.width, 1.5*n.height)
end

--[[
  @basicRedHitBox(npc)
  Creates a list of hitboxes to be used for internal redstone functions. Used to pass power in every direction
  Hitbox can be updated using @updateRedHitBox
    npc: NPC whose area will be applied to
]]
function redstone.basicRedHitBox(n)
  local list = {
    Colliders.Box(0, 0, 0.25*n.width, 0.9*n.height),
    Colliders.Box(0, 0, 0.9*n.width, 0.25*n.height),
    Colliders.Box(0, 0, 0.25*n.width, 0.9*n.height),
    Colliders.Box(0, 0, 0.9*n.width, 0.25*n.height)
  }

  for i = 1, 4 do
    list[i].direction = i - 1
  end

  return list
end

--[[
  @basicDirectionalRedHitBox(npc, dir)
  Creates a hitbox to be used for internal redstone functions. Used to pass power in a specific direction
  Hitbox can be updated using @updateDirectionalRedHitBox
    npc: NPC whose area will be applied to
    dir: The direction the hitbox will be created [0: left, 1:up, 2:right, 3:down]
]]
function redstone.basicDirectionalRedHitBox(n, dir)
  local coll

  if dir == 0 then
    coll = Colliders.Box(0, 0, 0.25*n.width, 0.9*n.height)
  elseif dir == 1 then
    coll = Colliders.Box(0, 0, 0.9*n.width, 0.25*n.height)
  elseif dir == 2 then
    coll = Colliders.Box(0, 0, 0.25*n.width, 0.9*n.height)
  elseif dir == 3 then
    coll = Colliders.Box(0, 0, 0.9*n.width, 0.25*n.height)
  end

  coll.direction = dir

  return coll
end

--[[
  @updateRedArea(npc)
  Updates a red area created using @redarea(). The red are must be stored in NPCObj.data.redarea
    npc: NPC whose redarea will be updated
]]
function redstone.updateRedArea(n)
  n.data.redarea.x = n.x - 0.25*n.width
  n.data.redarea.y = n.y - 0.25*n.height
end

--[[
  @updateRedHitBox(npc)
  Updates a red area created using @redhitbox(). The red are must be stored in NPCObj.data.redhitbox
    npc: NPC whose redhitbox will be updated
]]
function redstone.updateRedHitBox(n)
  local list = n.data.redhitbox
  list[1].x, list[1].y = n.x - 0.25*n.width, n.y + 0.05*n.height
  list[2].x, list[2].y = n.x + 0.05*n.width, n.y - 0.25*n.height
  list[3].x, list[3].y = n.x + n.width, n.y + 0.05*n.height
  list[4].x, list[4].y = n.x + 0.05*n.width, n.y + n.height
end

--[[
  @updateDirectionalRedHitBox(npc)
  Updates a red area created using @basicDirectionalRedHitBox(). The red are must be stored in NPCObj.data.redhitbox
    npc: NPC whose redhitbox will be updated
    dir: The direction the redhitbox is facing [0: left, 1:up, 2:right, 3:down]
]]
function redstone.updateDirectionalRedHitBox(n, dir)
  local coll = n.data.redhitbox
  if dir == 0 then
    coll.x, coll.y = n.x - 0.5*n.width, n.y + 0.05*n.height
  elseif dir == 1 then
    coll.x, coll.y = n.x + 0.05*n.width, n.y - 0.5*n.height
  elseif dir == 2 then
    coll.x, coll.y = n.x + n.width, n.y + 0.05*n.height
  elseif dir == 3 then
    coll.x, coll.y = n.x + 0.05*n.width, n.y + n.height
  end
end



--[[
  @updateDraw(npc)
  Updates the animFrame and animTimer data to somewhat replicate SMBX animation system.
  The values must be stored in NPCObj.data.animTimer and NPCObj.data.animFrame
    npc: NPC whose timers will be updated
]]
function redstone.updateDraw(n)
  local data = n.data
  local config = NPC.config[n.id]

  data.animTimer = data.animTimer + 1
  if data.animTimer >= config.frameSpeed then
    data.animTimer = 0
    data.animFrame = data.animFrame + 1
    if data.animFrame >= config.frames then
      data.animFrame = 0
    end
  end
end

--[[
  @resetPower(npc)
  Updates the power and powerPrev values. meant to be called at the end of onRedTick
    npc: NPC that is affected
]]
function redstone.resetPower(n)
  n.data.powerPrev = n.data.power
  n.data.power = 0
end

--[[
  @resetPower(npc)
  Applies friction to NPCs that are touching the floor. To be used to fix NPCs that are thrown but will slide in the floor
    npc: NPC that is affected
]]
function redstone.applyFriction(n)
  if n.collidesBlockBottom then
    n.speedX = n.speedX*0.5
  end
end

--[[
  @spawnEffect(effectID, obj)
  Spawns an effect centered to the object
    obj: OBJ that is affected
]]
function redstone.spawnEffect(id, obj)
  if type(obj) == "NPC" and NPC.config[id].invisible then return end
  local e = Effect.spawn(id, obj.x + 0.5*obj.width, obj.y + 0.5*obj.height)
  e.x, e.y = e.x - e.width*0.5, e.y - e.height*0.5
end

--[[
  @spawnEffect(obj1, obj2)
  Returns a vector representing the displacemenent between their positions
]]
function redstone.displacement(a, b)
  return vector((a.x + 0.5*a.width) - (b.x + 0.5*b.width), (a.y + 0.5*a.height) - (b.y + 0.5*b.height))
end

--[[
  @printNPC(text, npc, xoffset, yoffset)
  prints debug text to an npc. the offsets are optional
]]
function redstone.printNPC(text, n, xo, yo)
  local x, y = n.x, n.y

  if xo then x = x + xo end
  if yo then y = y + yo end

  textplus.print{text = tostring(text), x = x, y = y, sceneCoords = true, priority = 0}
end

--[[
  @parseListMAP(str)
  Turns "1, 2, 3"  ->  {[1] = true, [2] = true, [3] = true}
]]
function redstone.parseListMAP(str)
  if str == "" then return {} end

  local t = {}
  for k, v in ipairs(split(str, ",")) do
    t[tonumber(v)] = true
  end

  return t
end

--[[
  @parseListMAP(str)
  Turns "1, 2, 3"  ->  {1,2 ,3}
]]
function redstone.parseNumList(str)
  if str == "" then return {} end

  local t = {}
  for k, v in ipairs(split(str, ",")) do
    local n = tonumber(v)
    if n then insert(t, n) end
  end

  return t
end

--[[
  @setLayerLineguideSpeed(npc)
  Applies movement from lineguides and layer speeds and simply deals with it
]]
function redstone.setLayerLineguideSpeed(n)
  if not (n.data._basegame.lineguide and n.data._basegame.lineguide.state == 1) then
    n.speedX, n.speedY = npcutils.getLayerSpeed(n)
  end
end

--[[
  @onScreen(npc)
  Returns true if the npc is in either camera
]]
local camlist = {camera, camera2}
function redstone.onScreen(n)
  for _, c in ipairs(camlist) do
    if Colliders.collide(n, Colliders.Box(c.x, c.y, c.width, c.height)) then
      return true
    end
  end
  return false
end

redstone.isMuted = function(n)
  return NPC.config[n.id].mute
end

redstone.onScreenSound = function(n)
  if redstone.isMuted(n) then return false end
  for _, c in ipairs(camlist) do
    if Colliders.collide(n, Colliders.Box(c.x - 100, c.y - 100, c.width + 200, c.height + 200)) then
      return true
    end
  end
  return false
end


redstone.getByTag = function(tag)
  for _, v in NPC.iterate() do
    if v.data._settings._global.redTag == tag then
      return v
    end
  end
end

redstone.getListByTag = function(tag)
  local t = {}
  for _, v in NPC.iterate() do
    if v.data._settings._global.redTag == tag then
      insert(t, v)
    end
  end
  return t
end

redstone.powerTag = function(tag, power)
  local list = redstone.getListByTag(tag)
  power = power or 15
  for k, v in ipairs(list) do
    redstone.setEnergy(v, power)
  end
end

-- Helper function
-- Draws the custom npc that most components use
redstone.drawNPC = function(n)
  local config = NPC.config[n.id]
  n.animationFrame = -1

  if not redstone.onScreen(n) or config.invisible then return end

  local z = n.data.priority or -45
  if config.foreground then
    z = -15
  elseif n:mem(0x12C, FIELD_WORD) > 0 then
    z = -30
  elseif n:mem(0x138, FIELD_WORD) > 0 then
    z = -75
  end
  Graphics.draw{
    type = RTYPE_IMAGE,
    isSceneCoordinates = true,
    image = Graphics.sprites.npc[n.id].img,
    x = n.x + (n.width - config.gfxwidth)*0.5 + config.gfxoffsetx,
    y = n.y + n.height- config.gfxheight + config.gfxoffsety,
    sourceX = n.data.frameX*config.gfxwidth,
    sourceY = (n.data.frameY*config.frames + n.data.animFrame)*config.gfxheight,
    sourceWidth = config.gfxwidth,
    sourceHeight = config.gfxheight,
    priority = z,
    opacity = n.opacity
  }
end

redstone.showLayer = function(layername, hideSmoke)
  local layer = Layer.get(layername)
  if layer then layer:show(hideSmoke or false) end
end

redstone.hideLayer = function(layername, hideSmoke)
  local layer = Layer.get(layername)
  if layer then layer:hide(hideSmoke or false) end
end

redstone.toggleLayer = function(layername, hideSmoke)
  local layer = Layer.get(layername)
  if layer then layer:toggle(hideSmoke or false) end
end

redstone.reddata = {}

local proxytbl = {}

local proxymt = {
	__index = function(t, k) return redstone[k] or lunatime[k] or RNG[k] or math[k] or Routine[k] or _G[k] end,
	__newindex = function() end
}
setmetatable(proxytbl, proxymt)

local funcCache = {}
redstone.luaParse = nil -- Local outside for recursion
redstone.luaParse = function(name, n, msg, recurse)
	if funcCache[msg] then return funcCache[msg] end

	local str = msg
	local chunk, err = load(str, str, "t", proxytbl)

	if chunk then
		local func = chunk()
		funcCache[msg] = func
		return func
	elseif not recurse then
		return redstone.luaParse(name, n, msg:gsub("\r?\n", ";\n"), true)
	else
    insert(repl.log, "ERROR ["..name.."] x:"..n.x..", y:"..n.y..", section:"..n.section)
    insert(repl.log, err)
    Misc.dialog("["..name.."] x:"..n.x..", y:"..n.y..", section:"..n.section.."\n\n"..err)
    return redstone.luaParse(name, n, "return function() return {} end")
	end
end

redstone.luaCall = function(func, params)
  return func(params)
end

-- Helper function
-- Checks if the NPC is valid
local function sectionList()
  local t = {}
  for k, p in ipairs(Player.get()) do
    t[p.section] = true
  end
  return unmap(t)
end

local seccah = {}
local function sectionCache(id)
  local coll = seccah[id]
  local s = Section(id).boundary
  if not coll then
    seccah[id] = Colliders.Box(0,0,0,0)
    coll = seccah[id]
  end
  coll.x, coll.y, coll.width, coll.height = s.left, s.top, s.right - s.left, s.bottom - s.top
  return coll
end

local function validCheck(v)
  return not (v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0)
end

-- List of important per-NPC variables
local function primechecker(n, com)
  local data = n.data
  data.prime = true

  -- Power of the NPC, ranges from 0 to 15
  data.power = data.power or 0

  -- Power of the NPC, in the previous frame
  data.powerPrev = data.powerPrev or 0

  -- When true, an observer facing this NPC gets powered
  data.observ = data.observ or false

  -- The power level the observer will output when data.observ is true
  data.observpower = data.observpower or 15

  -- The current inventory slot of the NPC, 0 is empty
  data.inv = data.inv or 0

  -- If true, the inventory slot can be filled
  data.invspace = data.invspace or false

  if com.prime then
    com.prime(n)
  end
end



local function forceStart()
  local sort = {}

  for _, n in ipairs(NPC.get(redstone.comID, -1)) do
    local order = redstone.comOrder[n.id]
    sort[order] = sort[order] or {}
    n.animationFrame = -1
    insert(sort[order], n)
  end

  for i = 1, #redstone.comID do
    if sort[i] then
      for _, n in ipairs(sort[i]) do
        if not n.data.prime then
          primechecker(n, redstone.comList[n.id])
        end
      end
    end
  end
end

local function tickLogic(com, n)
  if not n.data.prime then
    primechecker(n, com)
  end
  -- Copied from spawnzones.lua by Enjl
  if (redstone.disabledespawn or com.config.disabledespawn or n.data.disabledespawn) and not n.isHidden then
    if n:mem(0x124,FIELD_BOOL) then
      n:mem(0x12A, FIELD_WORD, 180)
    elseif n:mem(0x12A, FIELD_WORD) == -1 then
      if not redstone.onScreen(n) then
        n:mem(0x124,FIELD_BOOL, true)
        n:mem(0x12A, FIELD_WORD, 180)
      end
    end
    n:mem(0x74, FIELD_BOOL, true)
  end

  if com.config.grabfix then n:mem(0x134, FIELD_WORD, 0) end -- Custom grabfix (thx mrdoublea)
  if com.config.nogravity then redstone.setLayerLineguideSpeed(n) end

  if com.onRedTick then com.onRedTick(n) end
end

local function tickendLogic(n)
  local com = redstone.comList[n.id]
  if not n.data.prime then
    primechecker(n, com)
  end

  if com.onRedTickEnd then
    com.onRedTickEnd(n)
  end

  if n.data.animTimer then
    redstone.updateDraw(n)
  end
end

local function drawLogic(n)
  local com = redstone.comList[n.id]

  if validCheck(n) then
    if not n.data.prime then
      primechecker(n, com)
    end

    if com.onRedDraw then
      com.onRedDraw(n)
    end
  else
    n.animationFrame = -1
  end
end



-- Helper function
-- Passes a function to all NPCs of all component types
--[[
  I know the profiler took you here, but I can explain
  In order for the system to work, there has to be some type of order in which the NPCs are called
  so for example, chest are the first to execute its AI, then hoppers, and at the end, dust and observers

  This order ensures that energy is being passed correctly and that the NPCs interact with each other properly
  so because of this, I cannot use onTickNPC, Im sure if the system was built differently at its foundation it might be possible...
  but this wasnt made that way and Im not to sure how to change the approach at this point.

  So, all NPC AI goes through this function, this is why the profiler takes you here. This is in charge of passing the AI in order
  Can there be improvememnts to this function? Maybe, but this is the best I got

  Also, dust is laggy, if you have a lot of it, try using the basicdust flag and see if that doesnt break your stuff (it probably wont break anything and it will save you from a LOT of lag)
]]

local redstoneLogic = function(func)
  local sort = {}
  local f = function(n)
    local order = redstone.comOrder[n.id]
    sort[order] = sort[order] or {}
    if validCheck(n) then
      insert(sort[order], n)
    else
      n.animationFrame = -1
    end
  end

  for _, v in ipairs(sectionList()) do
    Colliders.getColliding{a = sectionCache(v), b = redstone.comID, btype = Colliders.NPC, filter = f}
  end

  for i = 1, #redstone.comID do
    if sort[i] then
      local com = redstone.comList[redstone.comID[i]]
      for _, n in ipairs(sort[i]) do
        func(com, n)
      end
    end
  end
end

local redstoneLogic_UNSORT = function(func)
  for _, v in ipairs(sectionList()) do
    Colliders.getColliding{a = sectionCache(v), b = redstone.comID, btype = Colliders.NPC, filter = func}
  end
end

function redstone.onStart()

  redstone.loadAI()

  -- Adds a check for each component. e.g. redstone.isDust()
  redstone.comID = {}
  redstone.comOrder = {}
  redstone.comList = {}
  for k, com in ipairs(redstone.componentList) do
    insert(redstone.comID, com.id)
    redstone.comList[com.id] = com
    redstone.comOrder[com.id] = k

    if com.onRedLoad then com.onRedLoad() end
  end

  forceStart()
end

function redstone.onTick()
  -- component onTick
   redstoneLogic(tickLogic)
end


function redstone.onTickEnd()
  -- component onTickEnd
  redstoneLogic_UNSORT(tickendLogic)

  -- Observers need this special case to work properly!
  if redstone.id.observer then
    local onRedTickObserver = redstone.component.observer.onRedTickObserver
    for k, v in ipairs(sectionList()) do
      local l = Colliders.getColliding{a = sectionCache(v), b = redstone.component.observer.id, btype = Colliders.NPC, filter = validCheck}
      for _, n in ipairs(l) do
        onRedTickObserver(n)
      end
    end
  end
end

function redstone.onDraw()
  -- component onDraw
  redstoneLogic_UNSORT(drawLogic)
end



local function split(str, delim)
	local ret = {}
	if not str then
		return ret
	end
	if not delim or delim == '' then
		for c in gmatch(str, '.') do
			insert(ret, c)
		end
		return ret
	end
	local n = 1
	while true do
		local i, j = find(str, delim, n)
		if not i then break end
		insert(ret, sub(str, n, i - 1))
		n = j + 1
	end
	insert(ret, sub(str, n))
	return ret
end

local function getNameID(name)
  local id = ''
  for k, v in ipairs(split(name)) do
    if k > 7 and k < #name - 3 then
      if tonumber(v) then
        id = id..v
      else
        break
      end
    end
  end
  return tonumber(id)
end

function redstone.loadAI()
local filepaths = {"", "../", "/RedstoneAI", "../RedstoneAI"}
local requirepaths = {"", "", "RedstoneAI/", "RedstoneAI/"}

  local redfiles = {}

  for k, p in ipairs(filepaths) do
    for _, v in ipairs(Misc.listLocalFiles(p)) do
      if string.startswith(v, "rednpc-") and string.endswith(v, ".lua") then
        insert(redfiles, {p, requirepaths[k], v})
      end
    end
  end

  local pNPC_ID = NPC_ID
  for k, v in ipairs(redfiles) do
    local path, name = v[2], v[3]
    local id = getNameID(name)
    if id then
      _G.NPC_ID = id
      local t = require(string.sub(path..name, 1, -5))
      t.id = id
      redstone.register(t)
    else
      require(sub(path..name, 1, -5))
    end
  end
  _G.NPC_ID = nil
end





function redstone.onInitAPI()
	registerEvent(redstone, "onStart", "onStart")
	registerEvent(redstone, "onTick", "onTick")
  registerEvent(redstone, "onTickEnd", "onTickEnd")
  registerEvent(redstone, "onDraw", "onDraw")
end

return redstone
