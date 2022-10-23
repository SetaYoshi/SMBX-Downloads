local lib = {}

-- this is the lib where we modify basegame stuff

local sl = require("stoplight")

local yellowIsh = Color(0.5, 0.5, 0)

local function clappingChuck(n)

end --321

NPC.config[319].noblockcollision = false
local function baseball(n)
  if n.collidesBlockLeft or collidesBlockRight then
    n:kill()
    Effect.spawn(10, n.x - 8, n.y - 8)
  end
end

-- do [NPC_ID] = tickFunc() and it just works
local npcTickList = {
  [319] = baseball
}

local npcIDList = table.unmap(npcTickList)


function lib.onStart()
  for k, v in ipairs(BGO.get(153)) do
    v.data = {}
    local data = v.data

    local s = Section.getIdxFromCoords(v.x, v.y)
    local darkness = Darkness.Light({x = v.x + 9, y = v.y + 12, radius = 96, brightness = 5, type = Darkness.lighttype.SPOT, spotangle = 30, color = yellowIsh})
    darkness.enabled = true
    v.data.darkness = darkness
    v.data.section = s
    Darkness.addLight(darkness)
  end
end

function lib.onSectionLoad()
  local activeSections = table.map(Section.getActiveIndices())
  for k, v in ipairs(BGO.get(153)) do
    d.enabled = activeSections[v.data.section]
  end
end

function lib.onTick()
  for k, v in ipairs(NPC.get(npcIDList, Section.getActiveIndices())) do
    npcTickList[v.id](v)
  end
end

function lib.onInitAPI()
  registerEvent(lib, "onStart")
  registerEvent(lib, "onTick")
  registerEvent(lib, "onSectionLoad")
end

return lib
