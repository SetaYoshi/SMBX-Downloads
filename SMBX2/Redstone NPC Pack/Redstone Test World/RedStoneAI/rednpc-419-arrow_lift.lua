local npcAI = {}

-- vv Customization vv

-- NONE AVAILABLE

-- ^^ Customization ^^

local redstone = require("redstone")
local nID = n_ID

-- Copied from the arrowlift NPC file
local function spawnGhost(n)
  local data = n.data
  local settings = data._settings
  local config = n.config[419]

  if data._basegame.child and data._basegame.child.isValid then
    data._basegame.child:kill()
  end

  local ghost = n.spawn(418, n.x + n.width*0.5, n.y - 4, n.section, false, false)
  data._basegame.child = ghost

  local ghostdata = ghost.data._basegame
  local ghostsettings = ghost.data._settings

  ghostdata.animation = 0
  ghostdata.timer = 0

  if not ghostsettings.override then
    ghostsettings.life = config.life
    ghostsettings.speed = config.speed
  end
  ghost.x = ghost.x - ghost.width*0.5
  ghost.dontMove = n.dontMove
  ghost.layerName = "Spawned NPCs"
  ghostdata.parent = n
  ghostsettings.life = settings.life
  ghostsettings.speed = settings.speed
  if settings.type == 0 then
    ghostsettings.type = -1
    ghostsettings.sp = true
  else
    ghostsettings.type = data._basegame.type - 1
    ghostsettings.sp = false
  end
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 and data.powerPrev == 0 and data._basegame.type then
    spawnGhost(n)
  end

  if data._basegame.child and data._basegame.child.data._basegame.timer == 0 then
    data.observ = true
  end

  redstone.resetPower(n)
end

return npcAI
