local piston = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local insert = table.insert

piston.name = "piston"
piston.id = NPC_ID
piston.order = 0.74

piston.config = npcManager.setNpcSettings({
	id = piston.id,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
  invisible = false,

	frames = 1,
	framespeed = 8,
	framestyle = 0,

  width = 32,
	height = 32,

  nogravity = true,
  notcointransformable = true,
	jumphurt = true,
  noblockcollision = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true,

  alwayspull = false,
  pushMax = 320,
  interval = 8,
  deadzone = 16
})


  -- ===============
  -- === PISTONS ===
  -- ===============

  -- Determines if a block is immovable by a piston
  local immovableblock = table.map({})
  redstone.blockImmovable = function(b)
    if immovableblock[b.id] then
      return true
    end
  end

  -- Determines if an NPC is immovable by a piston
  redstone.npcImmovable = function(n)
    if (n and n.data and n.data.pistImmovable) then
      return true
    end
  end

  -- Determines if a player is immovable by a piston
  redstone.playerImmovable = function(p)
    if p:mem(0x4A, FIELD_BOOL) then
      return true
    end
  end

  -- Determines if a block is intangible
  local intangibleBlock = table.map(expandedDefines.BLOCK_SEMISOLID..expandedDefines.BLOCK_SIZEABLE..expandedDefines.BLOCK_NONSOLID)
  redstone.blockIgnore = function(b)
    if intangibleBlock[b.id] then
      return true
    end
  end

  -- Determines if an NPC is intangible
  redstone.npcIgnore = function(n)
    if (n and n.data and n.data.pistIgnore) or redstone.is.dust(n.id) or n:mem(0x12C, FIELD_WORD) ~= 0 then
      return true
    end
  end

  -- Determines if an player is intangible
  redstone.playerIgnore = function(p)
    return false
  end


local sfxextend = Audio.SfxOpen(Misc.resolveFile("piston-extend.ogg"))
local sfxretract = Audio.SfxOpen(Misc.resolveFile("piston-retract.ogg"))

function piston.updateRedArea(n)
  local data = n.data
  if data.origframe == 0 then
    data.easybox.x, data.easybox.y = n.x - data.easybox.width, n.y + 2
    data.hardbox.x, data.hardbox.y = n.x - data.hardbox.width, data.easybox.y
    data.deadbox.x, data.deadbox.y = data.hardbox.x - data.deadbox.width - 2, data.easybox.y
    data.intbox.x, data.intbox.y = n.x - data.intbox.width, data.easybox.y
    data.pullbox.x, data.pullbox.y = n.x - data.pullbox.width, data.easybox.y
  elseif data.origframe == 1 then
    data.easybox.x, data.easybox.y = n.x + 2, n.y - data.easybox.height
    data.hardbox.x, data.hardbox.y = data.easybox.x, n.y - data.hardbox.height + 2
    data.deadbox.x, data.deadbox.y = data.easybox.x, data.hardbox.y - data.deadbox.height - 2
    data.intbox.x, data.intbox.y = data.easybox.x, n.y - data.intbox.height
    data.pullbox.x, data.pullbox.y = data.easybox.x, n.y - data.pullbox.height
  elseif data.origframe == 2 then
    data.easybox.x, data.easybox.y = n.x + n.width, n.y + 2
    data.hardbox.x, data.hardbox.y = data.easybox.x, data.easybox.y
    data.deadbox.x, data.deadbox.y = data.hardbox.x + data.hardbox.width + 2, data.easybox.y
    data.intbox.x, data.intbox.y = data.easybox.x, data.easybox.y
    data.pullbox.x, data.pullbox.y = data.easybox.x, data.easybox.y
  elseif data.origframe == 3 then
    data.easybox.x, data.easybox.y = n.x + 2, n.y + n.height
    data.hardbox.x, data.hardbox.y = data.easybox.x, data.easybox.y
    data.deadbox.x, data.deadbox.y = data.easybox.x, data.hardbox.y + data.hardbox.height + 2
    data.intbox.x, data.intbox.y = data.easybox.x, data.easybox.y
    data.pullbox.x, data.pullbox.y = data.easybox.x, data.easybox.y
  end
end

local function newredarea(n)
  local data = n.data
  local config_hor = redstone.component.piston_ehor.config
  local config_ver = redstone.component.piston_ever.config
  if data.frameX == 0 then
    return Colliders.Box(0, 0, data.pistdiff - 2, config_hor.height - 4), Colliders.Box(0, 0, piston.config.pushMax, config_hor.height - 4), Colliders.Box(0, 0, piston.config.deadzone, config_hor.height - 4), Colliders.Box(0, 0, piston.config.interval, config_hor.height - 4), Colliders.Box(0, 0, 2, config_hor.height - 4)
  elseif data.frameX == 1 then
    return Colliders.Box(0, 0, config_ver.width - 4, data.pistdiff - 2), Colliders.Box(0, 0, config_ver.width - 4, piston.config.pushMax), Colliders.Box(0, 0, config_ver.width - 4, piston.config.deadzone), Colliders.Box(0, 0, config_ver.width - 4, piston.config.interval), Colliders.Box(0, 0, config_ver.width - 4, 2)
  elseif data.frameX == 2 then
    return Colliders.Box(0, 0, data.pistdiff - 2, config_hor.height - 4), Colliders.Box(0, 0, piston.config.pushMax, config_hor.height - 4), Colliders.Box(0, 0, piston.config.deadzone, config_hor.height - 4), Colliders.Box(0, 0, piston.config.interval, config_hor.height - 4), Colliders.Box(0, 0, 2, config_hor.height - 4)
  else
    return Colliders.Box(0, 0, config_ver.width - 4, data.pistdiff - 2), Colliders.Box(0, 0, config_ver.width - 4, piston.config.pushMax), Colliders.Box(0, 0, config_ver.width - 4, piston.config.deadzone), Colliders.Box(0, 0, config_ver.width - 4, piston.config.interval), Colliders.Box(0, 0, config_ver.width - 4, 2)
  end
end


function piston.prime(n)
  local data = n.data

  data.frameX = data._settings.dir or 0
  data.frameY = data._settings.type or 0

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0
  data.powerTimer = data.powerTimer or 0

  if not redstone.is.piston(n.id) then
    if redstone.is.piston_ehor(n.id) then
      if data.frameX == 0 then
        data.origframe = 0
      else
        data.origframe = 2
      end
    elseif redstone.is.piston_ever(n.id) then
      if data.frameX == 0 then
        data.origframe = 1
      else
        data.origframe = 3
      end
    end
  else
    data.origframe = data.frameX
  end

  if data.origframe == 0 then
    data.pistdiff = redstone.component.piston_ehor.config.width - piston.config.width
    data.newframe = 0
    data.newid =  redstone.component.piston_ehor.id
    data.offX = 0.5*(piston.config.width - redstone.component.piston_ehor.config.width)
    data.offY = 0
    data.direction = vector.v2(-1, 0)
  elseif data.origframe == 1 then
    data.pistdiff = redstone.component.piston_ever.config.height - piston.config.height
    data.newframe = 0
    data.newid = redstone.component.piston_ever.id
    data.offX = 0
    data.offY = 0.5*(piston.config.height - redstone.component.piston_ever.config.height)
    data.direction = vector.v2(0, -1)
  elseif data.origframe == 2 then
    data.pistdiff = redstone.component.piston_ehor.config.width - piston.config.width
    data.newframe = 1
    data.newid = redstone.component.piston_ehor.id
    data.offX = -0.5*(piston.config.width - redstone.component.piston_ehor.config.width)
    data.offY = 0
    data.direction = vector.v2(1, 0)
  elseif data.origframe == 3 then
    data.pistdiff = redstone.component.piston_ever.config.height - piston.config.height
    data.newframe = 1
    data.newid = redstone.component.piston_ever.id
    data.offX = 0
    data.offY = -0.5*(piston.config.height - redstone.component.piston_ever.config.height)
    data.direction = vector.v2(0, 1)
  end

  data.easybox, data.hardbox, data.deadbox, data.intbox, data.pullbox = newredarea(n)
end

local function transformPiston(n, data)
  n:transform(data.newid)
  data.frameX = data.newframe
  data.observ = true
  data.powerTimer = 0
  n.x = n.x + data.offX
  n.y = n.y + data.offY
end

local function findFirstEmpty(n, data)
  local empty = true

  -- check easy push
  for k, c in ipairs({Block, NPC, Player}) do
    for _, v in ipairs(c.getIntersecting(data.easybox.x, data.easybox.y, data.easybox.x + data.easybox.width, data.easybox.y + data.easybox.height)) do
      if (k == 1 and redstone.blockImmovable(v)) or (k == 2 and redstone.npcImmovable(v)) or (k == 3 and data.frameY == 2 and redstone.playerImmovable(v)) then
        return -1
      elseif (k == 1 and not redstone.blockIgnore(v)) or (k == 2 and not redstone.npcIgnore(v)) or (k == 3 and data.frameY == 2 and not redstone.playerIgnore(v)) then
        empty = false
        break
      end
    end
  end

  if empty then
    return 0
  end

  -- check hard push
  data.intbox.x, data.intbox.y = data.intbox.x + data.direction.x*data.pistdiff, data.intbox.y + data.direction.y*data.pistdiff
  for i = data.pistdiff, piston.config.pushMax, piston.config.interval do
    empty = true
    for k, c in ipairs({Block, NPC, Player}) do
      for _, v in ipairs(c.getIntersecting(data.intbox.x, data.intbox.y, data.intbox.x + data.intbox.width, data.intbox.y + data.intbox.height)) do
        if (k == 1 and redstone.blockImmovable(v)) or (k == 2 and redstone.npcImmovable(v)) or (k == 3 and data.frameY == 2 and redstone.playerImmovable(v)) then
          return -1
        elseif (k == 1 and not redstone.blockIgnore(v)) or (k == 2 and not redstone.npcIgnore(v)) or (k == 3 and data.frameY == 2 and not redstone.playerIgnore(v)) then
          empty = false
          break
        end
      end
    end
    data.intbox.x, data.intbox.y = data.intbox.x + data.direction.x*piston.config.interval, data.intbox.y + data.direction.y*piston.config.interval

    if empty then
      return i
    end
  end

  -- check dead zone
  for k, c in ipairs({Block, NPC, Player}) do
    for _, v in ipairs(c.getIntersecting(data.deadbox.x, data.deadbox.y, data.deadbox.x + data.deadbox.width, data.deadbox.y + data.deadbox.height)) do
      if (k == 1 and not redstone.blockIgnore(v)) or (k == 2 and not redstone.npcIgnore(v)) or (k == 3 and data.frameY == 2) then
        return -1
      end
    end
  end

  return piston.config.pushMax
end


local function getEasy(n, data)
  local list = {}

  for k, c in ipairs({Block, NPC, Player}) do
    for _, v in ipairs(c.getIntersecting(data.easybox.x, data.easybox.y, data.easybox.x + data.easybox.width, data.easybox.y + data.easybox.height)) do
      if (k == 1 and redstone.blockImmovable(v)) or (k == 2 and redstone.npcImmovable(v)) or (k == 3 and data.frameY == 2 and redstone.playerImmovable(v)) then
        return -1
      elseif ((k == 1 and not redstone.blockIgnore(v)) or (k == 2 and not redstone.npcIgnore(v))) or (k == 3) and v ~= n then
        insert(list, v)
      end
    end
  end

  return list
end

local function coordHardPush(n, d, l)
  if d == 0 then
    return n.x - l, n.y, l, n.height
  elseif d == 1 then
    return n.x, n.y - l, n.width, l
  elseif d == 2 then
    return n.x + n.width, n.y, l, n.height
  else
    return n.x, n.y + n.height, n.width, l
  end
end

local function getHard(n, data, l)
  local list = {}
  local x, y, w, h = coordHardPush(n, data.frameX, l)
  for k, c in ipairs({Block, NPC}) do
    for _, v in ipairs(c.getIntersecting(x, y, x + w, y + h)) do
      if (k == 1 and not redstone.blockIgnore(v)) or (k == 2 and not redstone.npcIgnore(v)) and v ~= n then
        insert(list, v)
      end
    end
  end

  x, y, w, h = coordHardPush(n, data.frameX, l + 32)
  for _, v in ipairs(Player.getIntersecting(x, y, x + w, y + h)) do
    -- Misc.dialog("A")/
    if not redstone.playerIgnore(v) then
      insert(list, v)
    end
  end

  return list
end

function piston.onRedTick(n)
  local data = n.data
  data.observ = false
  if data.power > 0 then
    piston.updateRedArea(n)

    local l = findFirstEmpty(n, data)
    if l == -1 then
      data.power = 0
      return
    end
    local easylist = getEasy(n, data)
    if type(easylist) == "number" then
      data.power = 0
      return
    end
    local hardlist = getHard(n,  data, l)
    if redstone.onScreenSound(n) then
      SFX.play(sfxextend)
    end
    for _, v in ipairs(hardlist) do
      v.x, v.y = v.x + data.pistdiff*data.direction.x, v.y + data.pistdiff*data.direction.y
    end
    for _, v in ipairs(easylist) do
      v.data = v.data or {}
      v.data.stick = lunatime.tick()

      if data.frameX == 0 then
        v.x = n.x - data.pistdiff - v.width
      elseif data.frameX == 1 then
        v.y = n.y - data.pistdiff - v.height
      elseif data.frameX == 2 then
        v.x = n.x + n.width + data.pistdiff
      else
        v.y = n.y + n.height + data.pistdiff
      end
    end
    Block.spawn(1,0,0):delete()
    transformPiston(n, n.data)
  end
end


local function shouldpull(n, k, v)

  if k == 1 then
    if redstone.npcImmovable(v) or redstone.npcIgnore(v) then
      return false
    end
  elseif k == 2 then
    if redstone.blockImmovable(v) or redstone.blockIgnore(v) then
      return false
    end
  elseif k == 3 and n.data.frameY == 2 then
    if redstone.playerImmovable(v) or redstone.playerIgnore(v) then
      return false
    end
  end

  if piston.config.alwayspull or n.data.frameY == 2 then
    return true
  else
    return not (v.data and v.data.stick and (lunatime.tick() - v.data.stick <= 6))
  end
end


function piston.ext_onTick(n)
  local data = n.data

  if data.power == 0 then
    piston.updateRedArea(n)
    n.x = n.x - data.offX
    n.y = n.y - data.offY
    data.frameX = data.origframe
    n:transform(piston.id)
    data.observ = true
    if redstone.onScreenSound(n) then
      SFX.play(sfxretract)
    end

    if data.frameY > 0 then
      for k, f in ipairs({NPC, Block, Player}) do
        for _, v in ipairs(f.getIntersecting(data.pullbox.x, data.pullbox.y, data.pullbox.x + data.pullbox.width, data.pullbox.y + data.pullbox.height)) do
          if shouldpull(n, k, v) and not v ~= n then
            v.x = v.x - data.pistdiff*data.direction.x
            v.y = v.y - data.pistdiff*data.direction.y
          end
        end
      end
      Block.spawn(1,0,0):delete()
    end
    data.powerTimer = 0
  else
    if data.powerTimer == 1 then
      data.observ = false
    end
    data.powerTimer = data.powerTimer + 1
  end

  data.power = 0
end


function piston.onRedDraw(n)
  redstone.drawNPC(n)
end

redstone.register(piston)

return piston
