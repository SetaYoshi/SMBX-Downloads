local submenu = {}

-- This module allows you to activate and toggle all cheats in the game

local rng = require("rng")
local listgen = require(GameData.SMBXLP_dir.."listgenerator.lua")

submenu.name = "Cheats"
submenu.type = "STATIC_LIST"

local cheatdata = Cheats.listCheats()
table.sort(cheatdata)
local cheatlist = listgen.create{
  list = cheatdata,
  textscale = 2,
  textspacing = 24,
  maxlines = 12
}

submenu.input = function(menu, p)
  cheatlist.basiccontrol(p)
  local validclick = cheatlist.basiccursor(menu.mx(0), menu.my(0))
  if p.keys.jump == KEYS_PRESSED or validclick then
    GameData.SMBXLP_invalid = true
    SFX.play(menu.sfx_select)
    Cheats.trigger(cheatdata[cheatlist.option])
  end
end


local colorAI = function(option, text, menu)
  local cheatinfo = Cheats.get(cheatdata[option])
  if cheatinfo.onToggle then
    if cheatinfo.active then
      return text, Color.green
    else
      return text, Color.orange
    end
  end
  return text
end

submenu.draw = function(menu)
  cheatlist.draw(menu.mx(0), menu.my(0), menu.mz(0), colorAI, menu)
end

function submenu.onInputUpdate()
  if Misc.cheatBuffer() == "" then
    Misc.cheatBuffer("SMBXLP")
    GameData.SMBXLP_typedcheat = true
    if not GameData.SMBXLP_set.enablecheat then
      GameData.SMBXLP_invalid = true
    end
  end
end

function submenu.onInitAPI()
  registerEvent(submenu, "onInputUpdate", "onInputUpdate", true)
end

return submenu
