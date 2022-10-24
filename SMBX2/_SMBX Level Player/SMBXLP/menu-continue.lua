local submenu = {}

-- This module closes the menu when selected. It also displays the level name and statistics of the current level

local eventu = require("eventu")
local textplus = require("textplus")

local stat = GameData.SMBXLP_stat

submenu.name = "Continue"
submenu.type = "STATIC_FUNC"

-- If there is no level name, use file name instead
local levelName = Level.name()
if levelName == "" then
  levelName = Level.filename()
end

local marker = Graphics.loadImage(GameData.SMBXLP_dir.."marker.png")
local deathmarker = {}

-- Close the menu when activated
submenu.activate = function(menu)
  menu.toggle()
  -- Disable the jump key until it is released
  -- This is because the player nor jumps when you select this option
  eventu.run(function()
    while true do
      if not menu.playerinput.jumpKeyPressing then
        return
      end
      menu.playerinput.jumpKeyPressing = false
      eventu.waitFrames(1)
    end
  end)
end

-- Print the level name and stats
submenu.draw = function(menu)
  textplus.print{text = levelName.."\n\n<color green>Deaths:</color> "..stat.deathcount.."\n<color green>Finished:</color> "..stat.complete, x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2, maxWidth = 220}
end

-- Gather the 10 previous deaths inside the x, y, w, h range
local getdeathmarker = function(x, y, w, h)
  local max = 10
  for k = 1, stat.deathcount do
    local dx = stat.deathx[k]
    local dy = stat.deathy[k]
    if max == 0 then
      break
    elseif dx > x and dx < x + w and dy > y and dy < y + h then
      max = max - 1
      table.insert(deathmarker, {dx, dy, (k == 1)})
    end
  end
end

function submenu.onTickEnd()
  local alldeath = true
  for _, p in ipairs(Player.get()) do

    -- Detect if the player is dead
    if p:mem(0x13C, FIELD_BOOL) or p:mem(0x13E, FIELD_WORD) >= 3 then
      -- First frame the player is dead, save the coordinates of death and update the death counter
      if p:mem(0x13E, FIELD_WORD) == 3 then
        local bound = Section(p.section).boundary
        local x = math.clamp(bound.left + 32, p.x + p.width*0.5, bound.right - 32)
        local y = math.clamp(bound.top + 32, p.y + p.height*0.5, bound.bottom - 32)
        table.insert(stat.deathx, 1, math.floor(x))
        table.insert(stat.deathy, 1, math.floor(y))
        stat.deathcount = #stat.deathx
      end
    else
      alldeath = false
    end

    -- If the "infinite lives" setting is activated, add a life when the player dies and respawns
    if GameData.SMBXLP_set.inflife and (p:mem(0x13E, FIELD_WORD) == 3 or p:mem(0x122, FIELD_BOOL)) then
      mem(0x00B2C5AC, FIELD_FLOAT, 99)
    end
  end

  -- if all players are dead, prepare the death markers
  if not deathmarker[1] and alldeath and not GameData.SMBXLP_set.disablemarker then
    for _, c in ipairs(Camera.get()) do
      getdeathmarker(c.x, c.y, c.width, c.height)
    end
  end
end

-- Draw the death markers once all players are dead
function submenu.onCameraDraw(idx)
  if idx == 1 and deathmarker[1] then
    for k, v in ipairs(deathmarker) do
      -- The latest death has a different opacity than the rest
      if v[3] then
        Graphics.drawImageToSceneWP(marker, v[1] - 16, v[2] - 16, 5)
      else
        Graphics.drawImageToSceneWP(marker, v[1] - 16, v[2] - 16, 0.4, 5)
      end
    end
  end
end

-- Register listener functions
function submenu.onInitAPI()
  registerEvent(submenu, "onTickEnd", "onTickEnd")
	registerEvent(submenu, "onCameraDraw", "onCameraDraw")
end

return submenu
