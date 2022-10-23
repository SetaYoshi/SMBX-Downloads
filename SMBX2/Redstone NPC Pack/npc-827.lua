local deadsickblock = {}

local redstone = require("redstone")
local npcManager = require("npcManager")

deadsickblock.name = "deadsickblock"
deadsickblock.id = NPC_ID

deadsickblock.test = function()
  return "isDeadsickblock", function(x)
    return (x == deadsickblock.id or x == deadsickblock.name)
  end
end

local MODE_NORMAL = 0
local MODE_ANGELIC = 1

deadsickblock.onRedPower = function(n, c, power, dir, hitbox)
  if n.data.power == 0 and n.data.mode == MODE_ANGELIC then
    redstone.setEnergy(n, power)
    redstone.updateRedArea(n)
    redstone.updateRedHitBox(n)
    redstone.passEnergy{source = n, power = 15, hitbox = n.data.redhitbox, area = n.data.redarea, npcList = {deadsickblock.id, redstone.component.reflector.id}, filter = function(v) return (v.data.mode == MODE_ANGELIC and v.data.power == 0 and c ~= v) or redstone.isReflector(v.id) end}
  else
    return true
  end
end

deadsickblock.config = npcManager.setNpcSettings({
	id = deadsickblock.id,

  width = 32,
  height = 32,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
  foreground = true,

	frames = 1,
	framespeed = 8,
	framestyle = 0,
  invisible = false,
  mute = false,

  nogravity = true,
	jumphurt = true,
  notcointransformable = true,
	nohurt = true,
	noyoshi = true,
  noblockcollision = true,
  blocknpc = false,
  blocknpctop = false,
  playerblock = false,
  playerblocktop = false
})

local function revive(n)
  local data = n.data

  n.friendly = false
  if redstone.onScreenSound(n) then
    SFX.play(14)
  end
  data.isDead = false
  data.pistIgnore = false
  n.id = redstone.component.sickblock.id
end

deadsickblock.prime = redstone.component.sickblock.prime

function deadsickblock.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.mode == MODE_ANGELIC and data.power == 0 and data.deathTimer == 0 then
    data.deathTimer = redstone.component.sickblock.config.deathtimer + 1
    data.observ = true
  end

  if data.deathTimer > 0 then
    data.deathTimer = data.deathTimer - 1
    if data.deathTimer == 0 then
      revive(n)
    end
  end

  if data.deathTimer > 0 then
    data.frameY = 2
  else
    data.frameY = data.mode
  end

  redstone.resetPower(n)
end

deadsickblock.onRedDraw =  redstone.drawNPC

redstone.register(deadsickblock)

return deadsickblock
