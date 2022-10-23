local dropper = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

dropper.name = "dropper"
dropper.id = NPC_ID

local TYPE_DROPPER = 0
local TYPE_DISPENSER = 1

dropper.test = function()
  return "isDropper", function(x)
    return (x == dropper.id or x == dropper.name)
  end
end

dropper.onRedPower = function(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

dropper.onRedInventory = function(n, c, inv, dir, hitbox)
  n.data.inv = inv
end

dropper.config = npcManager.setNpcSettings({
	id = dropper.id,

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

  nogravity = true,
  notcointransformable = true,
  noblockcollision = true,
	jumphurt = true,
	nohurt = true,
	noyoshi = true,
  blocknpc = true,
  playerblock = true,
  playerblocktop = true,
  npcblock = true
})

local sfxdrop = Audio.SfxOpen(Misc.resolveFile("dropper-drop.ogg"))

local function chooseDir(n, frameX, v)
  if frameX == 0 then
    v.x, v.y = n.x - v.width, n.y + (n.height - v.height)
  elseif frameX == 1 then
    v.x, v.y = n.x + 0.5*(n.width - v.width), n.y - v.height
  elseif frameX == 2 then
    v.x, v.y = n.x + n.width, n.y + (n.height - v.height)
  elseif frameX == 3 then
    v.x, v.y = n.x + 0.5*(n.width - v.width), n.y + n.height
  end
end

local directionMap = {
  [0] = -1,
  [1] = -1,
  [2] = 1,
  [3] = -1
}

function dropper.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.dir or 0
  data.frameY = data._settings.type or 0

  data.overwrite = data._settings.overwrite or false
  data.autofire = data._settings.autofire or false
end

function dropper.onRedTick(n)
  local data = n.data
  data.observ = false

  if (data.power > 0 and data.powerPrev == 0) or (data.inv > 0 and data.autofire) then
    if not (data.inv > 0 and data.inv < 1000) then
      if not dropper.config.invisible then
        local v = Animation.spawn(10, 0, 0)
        chooseDir(n, n.data.frameX, v)
      end
    else
      local v = NPC.spawn(data.inv, 0, 0, player.section)
      chooseDir(n, n.data.frameX, v)
      v.direction = directionMap[data.frameX]
      redstone.spawnEffect(10, v)

      if data.frameY == TYPE_DISPENSER and redstone.npcAI[v.id] and redstone.npcAI[v.id].onDispense then
        redstone.npcAI[v.id].onDispense(v)
      end
    end

    if redstone.onScreenSound(n) then
      SFX.play(sfxdrop)
    end
    
    data.inv = 0
  end

  if data.inv > 0 then
    data.observ = true
    data.invspace = data.overwrite
  else
    data.invspace = true
  end

  redstone.resetPower(n)
end

dropper.onRedDraw = redstone.drawNPC

redstone.register(dropper)

return dropper
