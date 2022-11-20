local commandblock = {}

local redstone = require("redstone")
local npcManager = require("npcManager")
local repl = require("base/game/repl")

local insert = table.insert

commandblock.name = "commandblock"
commandblock.id = NPC_ID
commandblock.order = 0.78

local TYPE_PULSE = 0
local TYPE_REPEAT = 1

commandblock.onRedPower = function(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power, dir)
end

commandblock.config = npcManager.setNpcSettings({
	id = commandblock.id,

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
  npcblock = true
})

local function luafy(msg)
  return "return function(param) local commandBlock, powerLevel, powerLevelPrevious, powerDirection, script = param.commandBlock, param.powerLevel, param.powerLevelPrevious, param.powerDirection, param.script "..msg.." return {} end"
end

function commandblock.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.type or 0
  data.frameY = data.frameY or 0

  data.script = data._settings.script or ""
  data.rotutine = false

  data.func = redstone.luaParse("COMMAND BLOCK", n, luafy(data.script))
end

function commandblock.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 then
    if (data.frameX == TYPE_REPEAT) or (data.frameX == TYPE_PULSE and data.powerPrev == 0 and not (data.routine and data.routine.isValid)) then
      local params = {commandBlock = n, powerLevel = data.power, powerDirection = data.dir, powerLevelPrevious = data.powerPrev, script = data.script}

      if data.powerPrev == 0 then
        insert(repl.log, "[COMMAND BLOCK] "..n.x..", "..n.y)
        insert(repl.log, data.script)
        insert(repl.history, data.script)
      end

      if data.frameX == TYPE_PULSE then
        data.routine = Routine.run(redstone.luaCall, data.func, params)
      else
        redstone.luaCall(data.func, params)
      end

    end
  else
  end

  if (data.frameX == TYPE_REPEAT and data.power ~= 0) or (data.frameX == TYPE_PULSE and ((data.routine and data.routine.isValid) or (data.routine and not data.routine.isValid and data.power ~= 0 and data.powerPrev == 0))) then
    data.observ = true
    data.frameY = 1
  else
    data.frameY = 0
  end

  redstone.resetPower(n)
end

commandblock.onRedDraw = redstone.drawNPC

redstone.register(commandblock)

return commandblock
