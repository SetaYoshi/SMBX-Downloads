local RS = {}

--  ===============================
--  ====   Redstone.lua v1.2   ====
--  ====     By  SetaYoshi     ====
--  ===============================

--[[
        :::::::::   ::::::::::  :::::::::    ::::::::  :::::::::::  ::::::::   ::::    :::  ::::::::::
       :+:    :+:  :+:         :+:    :+:  :+:    :+:     :+:     :+:    :+:  :+:+:   :+:  :+:
      +:+    +:+  +:+         +:+    +:+  +:+            +:+     +:+    +:+  :+:+:+  +:+  +:+
     +#++:++#:   +#++:++#    +#+    +:+  +#++:++#++     +#+     +#+    +:+  +#+ +:+ +#+  +#++:++#
    +#+    +#+  +#+         +#+    +#+         +#+     +#+     +#+    +#+  +#+  +#+#+#  +#+
   #+#    #+#  #+#         #+#    #+#  #+#    #+#     #+#     #+#    #+#  #+#   #+#+#  #+#
  ###    ###  ##########  #########    ########      ###      ########   ###    ####  ##########

        :::     :::     :::         ::::::::
       :+:     :+:   :+:+:        :+:    :+:
      +:+     +:+     +:+              +:+
     +#+     +:+     +#+            +#+
     +#+   +#+      +#+          +#+
     #+#+#+#       #+#   #+#   #+#
      ###       #######  ### ##########

        :::::::::   :::   :::          ::::::::   ::::::::::  :::::::::::  :::    :::   :::   ::::::::    ::::::::   :::    :::  :::::::::::
       :+:    :+:  :+:   :+:         :+:    :+:  :+:             :+:    :+: :+:  :+:   :+:  :+:    :+:  :+:    :+:  :+:    :+:      :+:
      +:+    +:+   +:+ +:+          +:+         +:+             +:+   +:+   +:+  +:+ +:+   +:+    +:+  +:+         +:+    +:+      +:+
     +#++:++#+     +#++:           +#++:++#++  +#++:++#        +#+  +#++:++#++:  +#++:    +#+    +:+  +#++:++#++  +#++:++#++      +#+
    +#+    +#+     +#+                   +#+  +#+             +#+  +#+     +#+   +#+     +#+    +#+         +#+  +#+    +#+      +#+
   #+#    #+#     #+#            #+#    #+#  #+#             #+#  #+#     #+#   #+#     #+#    #+#  #+#    #+#  #+#    #+#      #+#
  #########      ###             ########   ##########      ###  ###     ###   ###      ########    ########   ###    ###  ###########










   ::::::::::: :::    ::: ::::::::::: ::::::::      ::::::::::: :::::::::: :::    ::: :::::::::::          :::        ::::::::   ::::::::  :::    ::: ::::::::          :::::::::  :::::::::  :::::::::: ::::::::::: ::::::::::: :::   :::          ::::::::   ::::::::   ::::::::  :::                    :::::::::  ::::::::::: ::::::::  :::    ::: ::::::::::: :::::::::
      :+:     :+:    :+:     :+:    :+:    :+:         :+:     :+:        :+:    :+:     :+:              :+:       :+:    :+: :+:    :+: :+:   :+: :+:    :+:         :+:    :+: :+:    :+: :+:            :+:         :+:     :+:   :+:         :+:    :+: :+:    :+: :+:    :+: :+:                    :+:    :+:     :+:    :+:    :+: :+:    :+:     :+:    :+:     :+:
     +:+     +:+    +:+     +:+    +:+                +:+     +:+         +:+  +:+      +:+              +:+       +:+    +:+ +:+    +:+ +:+  +:+  +:+                +:+    +:+ +:+    +:+ +:+            +:+         +:+      +:+ +:+          +:+        +:+    +:+ +:+    +:+ +:+                    +:+    +:+     +:+    +:+        +:+    +:+     +:+           +:+
    +#+     +#++:++#++     +#+    +#++:++#++         +#+     +#++:++#     +#++:+       +#+              +#+       +#+    +:+ +#+    +:+ +#++:++   +#++:++#++         +#++:++#+  +#++:++#:  +#++:++#       +#+         +#+       +#++:           +#+        +#+    +:+ +#+    +:+ +#+                    +#++:++#:      +#+    :#:        +#++:++#++     +#+          +#+
   +#+     +#+    +#+     +#+           +#+         +#+     +#+         +#+  +#+      +#+              +#+       +#+    +#+ +#+    +#+ +#+  +#+         +#+         +#+        +#+    +#+ +#+            +#+         +#+        +#+            +#+        +#+    +#+ +#+    +#+ +#+                    +#+    +#+     +#+    +#+   +#+# +#+    +#+     +#+        +#+
  #+#     #+#    #+#     #+#    #+#    #+#         #+#     #+#        #+#    #+#     #+#              #+#       #+#    #+# #+#    #+# #+#   #+# #+#    #+#         #+#        #+#    #+# #+#            #+#         #+#        #+#            #+#    #+# #+#    #+# #+#    #+# #+#        #+#         #+#    #+#     #+#    #+#    #+# #+#    #+#     #+#
  ###     ###    ### ########### ########          ###     ########## ###    ###     ###              ########## ########   ########  ###    ### ########          ###        ###    ### ##########     ###         ###        ###             ########   ########   ########  ########## ##          ###    ### ########### ########  ###    ###     ###        ###

]]


-- local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local textplus = require("textplus")
local repl = require("base/game/repl")

local insert, remove, unmap = table.insert, table.remove, table.unmap
local split = string.split

--[[
  TODO
  fix up transmitter
  fix up source (use flame algorithm)
]]


-- Defines redstone event order
RS.componentList = {
  "chip",           --DONE
  "chest",          --DONE
  "hopper",         --DONE
  "redblock",       --DONE
  "button",         --DONE
  "lever",          --DONE
  "block",          --DONE
  "torch",          --DONE
  "reflector",      --DONE
  "beamsource",     --DONE
  "absorber",       --DONE
  "alternator",     --DONE
  "repeater",       --DONE
  "capacitor",      --DONE
  "transmitter",    --DONE
  "reciever",       --DONE
  "operator",       --DONE
  "reaper",         --DONE
  "spyblock",       --DONE
  "soundblock",     --DONE
  "noteblock",      --DONE
  "note",           --DONE
  "broadcaster",    --DONE
  "dropper",        --DONE
  "flamethrower",   --DONE
  "flame",          --DONE
  "sickblock",      --DONE
  "deadsickblock",  --DONE
  "tnt",            --DONE
  "jewel",          --DONE
  "lectern",        --DONE
  "reddoor",        --DONE
  "piston",         -- pistons will be done in a later update
  "piston_ehor",
  "piston_ever",
  "dust",           --DONE
  "commandblock",   --DONE
  "observer"        --DONE
}

-- AI, a file meant to be edited by the level author
RS.redConfig = require("redstone_config")
local redConfig = RS.redConfig

-- Function to register a component
RS.component = {}
function RS.register(module)
  RS.component[module.name] = module
end

RS.npcAI = {}
RS.npcList = {}
--[[
  Function to register NPC AI
  @registerNPC(NPCID, AI)
  NPCID: The ID to apply the AI
  AI:    An AI table. Must be built as the following:
    npcAI = {
       onRedPower = function()
       onRedInventory = function()
       onRedTick = function()
       onDispense = function()
    }
    any function is optional.
]]
function RS.registerNPC(ID, npcAI)
  insert(RS.npcList, ID)
  RS.npcAI[ID] = npcAI
end


--[[
  Adds energy to an NPC
  @setEnergy(npc, power, dir)
  npc:   The NPC that energy will be applied to
  power: The energy level that will be applied. If the NPC already has a higher energy level, nothing will happen
  dir:   Optional, the direction the energy is applied [0: left, 1:up, 2:right, 3:down]
]]
RS.setEnergy = function(n, p, d)
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

-- Helper function
-- Determines how energy interacts between components
--[[
  n: NPC being powered
  c: compenent providing power
  p: The amount of power being provided
  d: The direction being provided
  hitbox: The hitbox of the power provided
--]]

--[[
  Adds energy to an NPC following standard filter procedures. This function checks if an NPC has criteria for being powered
  @energyFilter(n, c, power, dir, hitbox)
  n:       The NPC that energy will be applied to
  c:       The NPC that is supplying the energy
  power:   The energy level being applied
  dir:     The direction the energy is applied [0: left, 1:up, 2:right, 3:down]
  hitbox:  The hitbox that was used to apply energy
]]
RS.energyFilter = function(n, c, p, d, hitbox)
  if n == c then return end
  n.data.power = n.data.power or 0

  local component = RS.comList[n.id] or RS.npcAI[n.id]
  if component and component.onRedPower then
    return component.onRedPower(n, c, p, d, hitbox)
  else
    RS.setEnergy(n, p)
  end
end

-- A function that returns true. Can be used in filters in getColliding
RS.nofilter = function() return true end

-- A function that returns true when an NPC is not hidden. Can be used in filters in getColliding
RS.nothidden = function(v) return not v.isHidden end

-- Helper function
-- Passes energy to the sorroundings of the NPC in all directions
--[[
  source: The NPC being the source of power
  power: The amount of power being provided
  area: Collider box representing area from where to search NPCs.
  npcList: List of NPCs the power should affect
  hitbox: The list collision box of the power as a box collider {x, y, w, h, direction}
    direction of power (0:left, 1:up, 2:right, 3:down). If left empty then direction is universal
]]
RS.passEnergy = function(args)
  args.npcList = args.npcList or RS.comID
  args.filter = args.filter or RS.nothidden
  local list = Colliders.getColliding{a = args.area, b = args.npcList, btype = Colliders.NPC, filter = args.filter}
  local found = false
  for _, v in ipairs(args.hitbox) do
    for i = #list, 1, -1 do
      local n = list[i]
      if Colliders.collide(v, n) then
        local power = args.power
        if args.powerAI then power = args.powerAI(n, args.source, args.power, v.direction, v) end
        local cancelled = RS.energyFilter(n, args.source, power, v.direction, v)
        if not cancelled then
          found = true
          remove(list, i)
        end
      end
    end
  end
  return found
end

-- Helper function
-- Passes energy in a single direction
--[[
  source: The NPC being the source of power
  power: The amount of power being provided
  npcList: List of NPCs the power should affect
  hitbox: The collision box of the power as a box collider {x, y, w, h, direction}
    direction of power (0:left, 1:up, 2:right, 3:down). If left empty then direction is universal
]]
RS.passDirectionEnergy = function(args)
  local c = args.hitbox
  args.npcList = args.npcList or RS.comID
  local list = Colliders.getColliding{a = c, b = args.npcList, btype = Colliders.NPC, filter = RS.nothidden}
  for _, n in ipairs(list) do
    if Colliders.collide(c, n) then
      local power = args.power
      if args.powerAI then power = args.powerAI(n, args.source, args.power, c.direction, c)  end
      RS.energyFilter(n, args.source, power, c.direction, c)
    end
  end
end

-- Helper function
-- Passes inventory items. Returns true if the pass is successful
--[[
  source: The NPC being the source of the inventory
  inventory: The inventory ID being passed
  npcList: List of NPCs the power should affect
  hitbox: The collision box of the power as a box collider {x, y, w, h}
]]
RS.passInventory = function(args)
  local c = args.hitbox
  args.npcList = args.npcList or RS.comID
  local list = Colliders.getColliding{a = c, b = args.npcList, btype = Colliders.NPC, filter = RS.nofilter}
  for _, n in ipairs(list) do
    if Colliders.collide(c, n) and n.data.invspace then
      local com = RS.comList[n.id] or RS.npcAI[n.id]
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
  Creates a hitbox to be used for internal redstone functions. Used to filter down NPCs when passing power.
  Hitbox can be updated using @updateRedArea
  @basicRedArea(npc)
  npc: NPC whose area will be applied to
]]
RS.basicRedArea = function(n)
  return Colliders.Box(0, 0, 1.5*n.width, 1.5*n.height)
end

--[[
  Creates a list of hitboxes to be used for internal redstone functions. Used to pass power in every direction
  Hitbox can be updated using @updateRedHitBox
  @basicRedHitBox(npc)
  npc: NPC whose area will be applied to
]]
RS.basicRedHitBox = function(n)
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
  Creates a hitbox to be used for internal redstone functions. Used to pass power in a specific direction
  Hitbox can be updated using @updateDirectionalRedHitBox
  @basicDirectionalRedHitBox(npc, dir)
  npc: NPC whose area will be applied to
  dir: The direction the hitbox will be created [0: left, 1:up, 2:right, 3:down]
]]
RS.basicDirectionalRedHitBox = function(n, dir)
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
  Updates a red area created using @redarea(). The red are must be stored in NPCObj.data.redarea
  @updateRedArea(npc)
  npc: NPC whose redarea will be updated
]]
RS.updateRedArea = function(n)
  n.data.redarea.x = n.x - 0.25*n.width
  n.data.redarea.y = n.y - 0.25*n.height
end

--[[
  Updates a red area created using @redhitbox(). The red are must be stored in NPCObj.data.redhitbox
  @updateRedHitBox(npc)
  npc: NPC whose redhitbox will be updated
]]
RS.updateRedHitBox = function(n)
  local list = n.data.redhitbox
  list[1].x, list[1].y = n.x - 0.25*n.width, n.y + 0.05*n.height
  list[2].x, list[2].y = n.x + 0.05*n.width, n.y - 0.25*n.height
  list[3].x, list[3].y = n.x + n.width, n.y + 0.05*n.height
  list[4].x, list[4].y = n.x + 0.05*n.width, n.y + n.height
end

--[[
  Updates a red area created using @basicDirectionalRedHitBox(). The red are must be stored in NPCObj.data.redhitbox
  @updateDirectionalRedHitBox(npc)
  npc: NPC whose redhitbox will be updated
  dir: The direction the redhitbox is facing [0: left, 1:up, 2:right, 3:down]
]]
RS.updateDirectionalRedHitBox = function(n, dir)
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

local conch = {}
local function configCache(id)
  if not conch[id] then
    conch[id] = NPC.config[id]
  end

  return conch[id]
end

--[[
  Updates the animFrame and animTimer data to somewhat replicate SMBX animation system.
  The values must be stored in NPCObj.data.animTimer and NPCObj.data.animFrame
  @updateDraw(npc)
  npc: NPC whose timers will be updated
]]
RS.updateDraw = function(n, data)
  local config = configCache(n.id)

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
  Updates the power and powerPrev values
  @resetPower(npc)
  npc: NPC that is affected
]]
RS.resetPower = function(n)
  n.data.powerPrev = n.data.power
  n.data.power = 0
end

--[[
  Applies friction to NPCs that are touching the floor. TO be used to fix NPCs that are thrown but will slide in the floor
  @resetPower(npc)
  npc: NPC that is affected
]]
RS.applyFriction = function(n)
  if n.collidesBlockBottom then
    n.speedX = n.speedX*0.5
  end
end

--[[
  Spawns an effect centered to the object
  @spawnEffect(effectID, obj)
  obj: OBJ that is affected
]]
RS.spawnEffect = function(id, obj)
  if type(obj) == "NPC" and NPC.config[id].invisible then return end
  local e = Effect.spawn(id, obj.x + 0.5*obj.width, obj.y + 0.5*obj.height)
  e.x, e.y = e.x - e.width, e.y - e.height
end

--[[
  Returns a vector representing the displacemenent between their positions
  @spawnEffect(obj1, obj2)
]]
RS.displacement = function(a, b)
  return vector((a.x + 0.5*a.width) - (b.x + 0.5*b.width), (a.y + 0.5*a.height) - (b.y + 0.5*b.height))
end

RS.printNPC = function(text, n, xo, yo)
  local x, y = n.x, n.y
  if xo then x = x + xo end
  if yo then y = y + yo end
  textplus.print{text = tostring(text), x = x, y = y, sceneCoords = true, priority = 0}
end

RS.parseList = function(str)
  if str == "" then return false end
  local list = split(str, ",")
  local t = {}
  for k, v in ipairs(list) do
    t[tonumber(v)] = true
  end
  return t
end

RS.parseNumList = function(str)
  if str == "" then return false end
  local list = split(str, ",")
  local t = {}
  for k, v in ipairs(list) do
    local n = tonumber(v)
    if n then insert(t, n) end
  end
  return t
end

RS.setLayerLineguideSpeed = function(n)
  if not (n.data._basegame.lineguide and n.data._basegame.lineguide.state == 1) then
    n.speedX, n.speedY = npcutils.getLayerSpeed(n)
  end
end

local camlist = {camera, camera2}
RS.onScreen = function(n)
  for _, c in ipairs(camlist) do
    if Colliders.collide(n, Colliders.Box(c.x, c.y, c.width, c.height)) then
      return true
    end
  end
  return false
end

RS.isMuted = function(n)
  return configCache(n.id).mute
end

RS.onScreenSound = function(n)
  if RS.isMuted(n) then return false end
  for _, c in ipairs(camlist) do
    if Colliders.collide(n, Colliders.Box(c.x - 100, c.y - 100, c.width + 200, c.height + 200)) then
      return true
    end
  end
  return false
end


RS.getByTag = function(tag)
  for _, v in NPC.iterate() do
    if v.data._settings._global.redTag == tag then
      return v
    end
  end
end

RS.getListByTag = function(tag)
  local t = {}
  for _, v in NPC.iterate() do
    if v.data._settings._global.redTag == tag then
      insert(t, v)
    end
  end
  return t
end

RS.powerTag = function(tag, power)
  local list = RS.getListByTag(tag)
  power = power or 15
  for k, v in ipairs(list) do
    RS.setEnergy(v, power)
  end
end

-- Helper function
-- Draws the custom npc that most components use
RS.drawNPC = function(n)
  local config = NPC.config[n.id]
  n.animationFrame = -1

  if not RS.onScreen(n) or config.invisible then return end

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

RS.showLayer = function(layername, hideSmoke)
  local layer = Layer.get(layername)
  if layer then layer:show(hideSmoke or false) end
end

RS.hideLayer = function(layername, hideSmoke)
  local layer = Layer.get(layername)
  if layer then layer:hide(hideSmoke or false) end
end

RS.toggleLayer = function(layername, hideSmoke)
  local layer = Layer.get(layername)
  if layer then layer:toggle(hideSmoke or false) end
end

RS.reddata = {}

local proxytbl = {}

local proxymt = {
	__index = function(t, k) return RS[k] or lunatime[k] or RNG[k] or math[k] or Routine[k] or _G[k] end,
	__newindex = function() end
}
setmetatable(proxytbl, proxymt)

local funcCache = {}
RS.luaParse = nil -- Local outside for recursion
RS.luaParse = function(name, n, msg, recurse)
	if funcCache[msg] then return funcCache[msg] end

	local str = msg
	local chunk, err = load(str, str, "t", proxytbl)
  
	if chunk then
		local func = chunk()
		funcCache[msg] = func
		return func
	elseif not recurse then
		return RS.luaParse(name, n, msg:gsub("\r?\n", ";\n"), true)
	else
    insert(repl.log, "ERROR ["..name.."] x:"..n.x..", y:"..n.y..", section:"..n.section)
    insert(repl.log, err)
    Misc.dialog("["..name.."] x:"..n.x..", y:"..n.y..", section:"..n.section.."\n\n"..err)
    return RS.luaParse(name, n, "return function() return {} end")
	end
end

RS.luaCall = function(func, params)
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
local function primechecker(n)
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
end



local function forceStart()
  local sort = {}

  for _, n in ipairs(NPC.get(RS.comID, -1)) do
    local order = RS.comOrder[n.id]
    sort[order] = sort[order] or {}
    n.animationFrame = -1
    insert(sort[order], n)
  end

  for i = 1, #RS.comID do
    if sort[i] then
      for _, n in ipairs(sort[i]) do
        if not n.data.prime then
          primechecker(n)
          RS.comList[n.id].prime(n)
        end
      end
    end
  end
end

local function tickLogic(com, n)
  if not n.data.prime then
    primechecker(n)
    com.prime(n)
  end
  -- Copied from spawnzones.lua by Enjl
  if RS.disabledespawn and not n.isHidden and not n.data.disabledespawn then
    if n:mem(0x124,FIELD_BOOL) then
      n:mem(0x12A, FIELD_WORD, 180)
    elseif n:mem(0x12A, FIELD_WORD) == -1 then
      if not RS.onScreen(n) then
        n:mem(0x124,FIELD_BOOL, true)
        n:mem(0x12A, FIELD_WORD, 180)
      end
    end
    n:mem(0x74, FIELD_BOOL, true)
  end

  if com.config.grabfix then n:mem(0x134, FIELD_WORD, 0) end -- Custom grabfix (thx mrdoublea)

  com.onRedTick(n)
end

local function tickendLogic(n)
  local com = RS.comList[n.id]
  if not n.data.prime then
    primechecker(n)
    com.prime(n)
  end

  if com.onRedTickEnd then
    com.onRedTickEnd(n)
  end

  if n.data.animTimer then
    RS.updateDraw(n, n.data)
  end
end

local function drawLogic(n)
  local com = RS.comList[n.id]

  if validCheck(n) then
    if not n.data.prime then
      primechecker(n)
      com.prime(n)
    end

    if com.onRedDraw then
      com.onRedDraw(n)
    end
  else
    n.animationFrame = -1
  end
end

local function npcTickLogic(n)
  if n.data and validCheck(n) then
    local dat = RS.npcAI[n.id]
    if not n.data.prime then
      primechecker(n)
      if dat.prime then
        dat.prime(n, n.data)
      end
    end

    if dat.onRedTick then
      dat.onRedTick(n, n.data)
    end
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

  So, all NPC AI goes through this function, this is why the profiler takes you here. This is incharge of passing the AI in order
  Can there be improvememnts to this function? Maybe, but this is the best I got

  Also, dust is laggy, if you have a lot of it, try using the basicdust flag and see if that doesnt break your stuff (it probably wont break anything and it will save you from a LOT of lag)
]]

local redstoneLogic = function(func)
  local sort = {}
  local f = function(n)
    local order = RS.comOrder[n.id]
    sort[order] = sort[order] or {}
    if validCheck(n) then
      insert(sort[order], n)
    else
      n.animationFrame = -1
    end
  end

  for _, v in ipairs(sectionList()) do
    Colliders.getColliding{a = sectionCache(v), b = RS.comID, btype = Colliders.NPC, filter = f}
  end

  for i = 1, #RS.comID do
    if sort[i] then
      local com = RS.comList[RS.comID[i]]
      for _, n in ipairs(sort[i]) do
        func(com, n)
      end
    end
  end
end

local redstoneLogic_UNSORT = function(func)
  for _, v in ipairs(sectionList()) do
    Colliders.getColliding{a = sectionCache(v), b = RS.comID, btype = Colliders.NPC, filter = func}
  end
end

function RS.onStart()
  -- Load config functions
  local config = redConfig.loadconfig(RS)
  for k, v in pairs(config) do
    RS[k] = v
  end

  redConfig.loadAI(RS)


  -- Adds a check for each component. e.g. RS.isDust()
  RS.comID = {}
  RS.comOrder = {}
  RS.comList = {}
  for k, v in ipairs(RS.componentList) do
    local com = RS.component[v]
    local testname, func = com.test()
    RS[testname] = func

    -- com.onTickNPC = tickLogic
    -- npcManager.registerEvent(com.id, com, "onTickNPC")
    -- com.onDrawNPC = drawLogic
    -- npcManager.registerEvent(com.id, com, "onDrawNPC")
    -- com.onTickEndNPC = tickendLogic
    -- npcManager.registerEvent(com.id, com, "onTickEndNPC")

    insert(RS.comID, com.id)
    RS.comList[com.id] = com
    RS.comOrder[com.id] = k
  end

  forceStart()
end

function RS.onTick()
  -- component onTick
   redstoneLogic(tickLogic)

  -- Basegame NPCs AI for broadcaster component
  for k, v in ipairs(sectionList()) do
    Colliders.getColliding{a = sectionCache(v), b = RS.npcList, btype = Colliders.NPC, filter = npcTickLogic}
  end
end


function RS.onTickEnd()
  -- component onTickEnd
  redstoneLogic_UNSORT(tickendLogic)

  -- Observers need this special case to work properly!
  local onRedTickObserver = RS.component.observer.onRedTickObserver
  for k, v in ipairs(sectionList()) do
    local l = Colliders.getColliding{a = sectionCache(v), b = RS.component.observer.id, btype = Colliders.NPC, filter = validCheck}
    for _, n in ipairs(l) do
      onRedTickObserver(n)
    end
  end
end

function RS.onDraw()
  -- component onDraw
  redstoneLogic_UNSORT(drawLogic)
end


function RS.onInitAPI()
	registerEvent(RS, "onStart", "onStart")
	registerEvent(RS, "onTick", "onTick")
  registerEvent(RS, "onTickEnd", "onTickEnd")
  registerEvent(RS, "onDraw", "onDraw")
end

return RS
