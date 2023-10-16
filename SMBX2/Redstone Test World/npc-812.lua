-- v1.3.0

local spyblock = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

spyblock.name = "spyblock"
spyblock.id = NPC_ID
spyblock.order = 0.48

spyblock.onRedPower = function(n, c, power, dir, hitbox)
  if redstone.is.operator(c.id) and power > 0 then
    n.data.isOn = true
    redstone.setEnergy(n, power)
  end
  return true
end

spyblock.config = npcManager.setNpcSettings({
	id = spyblock.id,

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
  disabledespawn = false,
})

local function luafy(msg)
  return "return function(object) local player, npc, block, bgo = object, object, object, object "..msg.." end"
end

function spyblock.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.dir or 0
  data.frameY = data._settings.type or 0

  data.isOn = data.isOn or false
  data.prevState = data.prevState or false
  data.type = data._settings.type or 0

  data.whitelist = data.whitelist or redstone.parseListMAP(data._settings.whitelist)
  data.filter = redstone.luaParse("SPYBLOCK", n, luafy(data._settings.filter or "return true"))

  data.redhitbox = redstone.basicDirectionalRedHitBox(n, (data.frameX + 2)%4)
end

local TYPE_PLAYER  = 0
local TYPE_NPC     = 1
local TYPE_BLOCK   = 2
local TYPE_BGO     = 3
local TYPE_POWERED = 4

local function passPower(n, power)
  local data = n.data

  redstone.updateDirectionalRedHitBox(n, (data.frameX + 2)%4)
  redstone.passDirectionEnergy{source = n, power = power, hitbox = data.redhitbox}
  if not data.prevState then
    data.observ = true
  end
end

local getFuncType = {}
local getCheckType = {}
getFuncType[TYPE_PLAYER] = Player.getIntersecting
getCheckType[TYPE_PLAYER] = "character"

getFuncType[TYPE_NPC] = NPC.iterateIntersecting
getCheckType[TYPE_NPC] = "id"

getFuncType[TYPE_BLOCK] = Block.iterateIntersecting
getCheckType[TYPE_BLOCK] = "id"

getFuncType[TYPE_BGO] = BGO.iterateIntersecting
getCheckType[TYPE_BGO] = "id"

local function scanBox(n, dir)
  if dir == 0 then
    return n.x - 2, n.y, 2, n.height
  elseif dir == 1 then
    return n.x, n.y - 2, n.width, 2
  elseif dir == 2 then
    return n.x + n.width, n.y, 2, n.height
  else
    return n.x, n.y + n.height, n.width, 2
  end
end

local function scan(n, v, id)
  local data = n.data

  local whitelistpass = true
  local filterpass = redstone.luaCall(data.filter, v)
  local hiddenpass = not v.isHidden
  local datapass = not (v.data and v.data.hasNoScan)

  if #table.unmap(data.whitelist) ~= 0 then
    whitelistpass = data.whitelist[id]
  end

  if datapass then
    if type(v) == 'npc' then
      datapass = NPC.config[id].hasnoscan
    elseif type(v) == 'block' then
      datapass = Block.config[id].hasnoscan
    elseif type(v) == 'bgo' then
      datapass = BGP.config[id].hasnoscan
    end
  end
  
  if whitelistpass and filterpass and hiddenpass and datapass then
    data.isOn = true
    passPower(n, 15)
    return true
  end
end

function spyblock.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 then
    passPower(n, data.power)
  else
    local func, check = getFuncType[data.type], getCheckType[data.type]
    local x, y, w, h = scanBox(n, data.frameX)
    if data.type == TYPE_PLAYER then
      for _, v in ipairs(func(x, y, x + w, y + h)) do
        if scan(n, v, v[check]) then break end
      end
    else
      for _, v in func(x, y, x + w, y + h) do
        if scan(n, v, v[check]) then break end
      end
    end
  end

  if not data.isOn and data.prevState then
    data.observ = true
  end

  if data.isOn  then
    data.frameY = TYPE_POWERED
  else
    data.frameY = data.type
  end

  data.prevState = data.isOn
  data.isOn = false

  redstone.resetPower(n)
end

spyblock.onRedDraw = redstone.drawNPC

redstone.register(spyblock)

return spyblock