local chip = {}

local redstone = require("redstone")
local npcManager = require("npcManager")
local repl = require("base/game/repl")

chip.name = "chip"
chip.id = NPC_ID
chip.order = 0.10

chip.onRedPower = function(n, c, power, dir, hitbox)
  return true
end

chip.config = npcManager.setNpcSettings({
	id = chip.id,

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
  invisible = true,

	jumphurt = true,
  noblockcollision = true,
  nogravity = true,
  notcointransformable = true,
	nohurt = true,
	noyoshi = true
})

local function luafy(msg)
  return "return function(param) local timer, npc, powerLevel = param.timer, param.attachedNPC, param.powerLevel "..msg.." return {timer = timer, powerLevel = powerLevel} end"
end

local function defaultfunc(onTime, offTime, power)
  return "if timer <= "..onTime.." then powerLevel = "..power.." else powerLevel = 0 end if timer >= "..(offTime + onTime).." then timer = 0 end"
end

function chip.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data.frameX or 0
  data.frameY = data.frameY or 0

  data.timer = data.timer or 0

  if data._settings.advanced then
    data.script = data._settings.func or ""
  else
    data.script = defaultfunc(data._settings.onTime or 200, data._settings.offTime or 200, data._settings.powerlevel or 15)
    if not data._settings.active then
      data.timer = data._settings.ontime or 200
    end
  end

  data.func = redstone.luaParse("CONTROL CHIP", n, luafy(data.script))
end

function chip.onRedTick(n)
  local data = n.data

  if data.attached then
    local npc = data.attachedNPC
    if not (npc and npc.isValid) then
      n:kill() return
    end

    n.x, n.y = npc.x, npc.y
    data.timer = data.timer + 1

    local results = redstone.luaCall(data.func, {timer = data.timer, attachedNPC = npc})
    data.timer = results.timer or data.timer
    data.power = results.powerLevel or data.power

    if data.power > 0 then
      redstone.energyFilter(npc, n, data.power, -1, npc)
    end
  else
    local npc = Colliders.getColliding{a = n, b = NPC.ALL, atype = Colliders.NPC, btype = Colliders.NPC, filter = function(npc) return npc.isValid and not npc.isHidden and n ~= npc and (redstone.comList[npc.id] or redstone.npcAI[npc.id]) end}
    if npc[1] then
      data.attached = true
      data.attachedNPC = npc[1]
    end
  end

  if data.power > 0 then
    data.frameY = 1
  else
    data.frameY = 0
  end
end

function chip.onRedDraw(n)
  redstone.drawNPC(n)
end

redstone.register(chip)

return chip
