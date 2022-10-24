local preview = {}

local playerManager = require("playerManager")

local x, y, z, width, height = 60, 64, 0, 100, 100

local animtimer = 0
local animspeed = 9
local animframe = 0
local animfr = {
  [-1] = {1, 2},
  [CHARACTER_MARIO] = {0, 1}
}
local IDToCoords = function(id)
  return 500 + 100*math.floor(id/10), 100*(id%10 + 1)
end

function preview.onDraw(menu)
  local framelist = animfr[menu.playeredit.character] or animfr[-1]

  animtimer = animtimer + 1
  if animtimer >= animspeed then
    animtimer = 0
    animframe = animframe + 1
    if animframe >= #framelist then
      animframe = 0
    end
  end

  local px, py = IDToCoords(animframe)
  -- Graphics.draw{
  --   image = Graphics.sprites[playerManager.getName(menu.playeredit.character)][menu.playeredit.powerup].img,
  --   x = menu.px(x),
  --   y = menu.py(y),
  --   priority = menu.pz(z),
  --   type = RTYPE_IMAGE,
  --   sourceWidth = width,
  --   sourceHeight = height,
  --   sourceX = px,
  --   sourceY = py
  -- }
  menu.playeredit:render{x = menu.px(x), y = menu.py(y), priority = menu.pz(0), frame = 1, direction = 1, sceneCoords=false}
end

return preview
