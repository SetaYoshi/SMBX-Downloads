local chest = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

local iclone = table.iclone
local split = string.split

chest.name = "chest"
chest.id = NPC_ID

local TYPE_NORMAL = 0
local TYPE_BARREL = 1
local TYPE_ENDER = 2

local enderchestinvIDList = {0}


chest.test = function()
  return "isChest", function(x)
    return (x == chest.id or x == chest.name)
  end
end

chest.onRedPower = function(n, c, power, dir, hitbox)
  return true
end

chest.onRedInventory = function(n, c, inv, dir, hitbox)
  local data = n.data

  if data.frameX == TYPE_ENDER then
    enderchestinvIDList = {inv}
  else
    data.invList = {inv}
  end

  data.invCurr = 1
end

chest.enderID = 0

chest.config = npcManager.setNpcSettings({
  id = chest.id,

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

  grabtop = true,
  grabside = true,
  nogravity = false,
	jumphurt = true,
	nohurt = true,
  notcointransformable = true,
  noyoshi = false,
  harmlessgrab = true,
  blocknpc = true,
  blocknpctop = true,
  playerblock = false,
  playerblocktop = true,

  grabfix = true -- custom fix for the "death when thrown inside a wall"
})

local sfxbreak = Audio.SfxOpen(Misc.resolveFile("chest-break.ogg"))

function chest.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.type or 0
  data.frameY = data.frameY or 0

  data.invList = data._settings.inv or "0"

  if data.invList ~= "" and data.invList ~= "0" then
    data.invList = split(data.invList, ",")
    for i = 1, #data.invList do
      data.invList[i] = tonumber(data.invList[i])
    end
    if data.frameX == 2 then
      enderchestinvIDList = iclone(data.invList)
    end
  else
    data.invList = {0}
  end

  data.invOut = data.invList[1]
  data.invCurr = 1

  data.timer = data.timer or 0
  data.amount = data._settings.quantity or 1

  data.redhitbox = redstone.basicDirectionalRedHitBox(n, 3)
  data.invspace = true
end

function chest.onRedTick(n)
  local data = n.data
  redstone.applyFriction(n)

  if data.frameX == TYPE_ENDER then
    data.invList = enderchestinvIDList
    chest.enderID = enderchestinvIDList
    if data.invCurr > #data.invList then
      data.invCurr = 1
    end
  end

  data.invOut = data.invList[data.invCurr]

  if data.invOut ~= 0 then
    redstone.updateDirectionalRedHitBox(n, 3)
    local passed = redstone.passInventory{source = n, npcList = redstone.component.hopper.id, inventory = data.invOut, hitbox = data.redhitbox}

    if passed then
      data.invCurr = data.invCurr + 1
      if data.invCurr > #data.invList then
        data.invCurr = 1
      end

      if data.frameX == TYPE_BARREL then
        data.amount = data.amount - 1
        if data.amount == 0 then
          if not redstone.isMuted(n) then
            SFX.play(sfxbreak)
          end
          redstone.spawnEffect(10, n)
          n:kill()
        end
      end
    end
  end

  if data.invOut == 0 then
    data.observ = false
  else
    data.observ = true
  end
end

chest.onRedDraw = redstone.drawNPC

redstone.register(chest)

return chest
