local submenu = {}

local playerManager = require("playerManager")
local listgen = require(GameData.SMBXLP_dir.."listgenerator.lua")

local characterData = {id = {}, name = {"Random"}}
for k, v in pairs(playerManager.getCharacters()) do
  table.insert(characterData.id, k)
  table.insert(characterData.name, v.name)
end

local characterlist = listgen.create{
  list = characterData.name,
  textscale = 2,
  textspacing = 24,
  maxlines = 12
}

submenu.name = "Characters"
submenu.type = "STATIC_LIST"

submenu.input = function(menu, p)
  characterlist.basiccontrol(p)
  local validclick = characterlist.basiccursor(menu.mx(0), menu.my(0))
  if p.keys.jump == KEYS_PRESSED or validclick then
    local x
    if characterlist.option == 1 then
      x = menu.betterrng(characterData.id, menu.playeredit.character)
    else
      x = characterData.id[characterlist.option - 1]
    end
    menu.playeredit.character = x
    SFX.play(menu.sfx_select)
    GameData.SMBXLP_invalid = true
  end
end

local colorAI = function(option, text, menu)
  if option == 1 then
    return text, "rainbow"
  elseif characterData.id[option - 1] == menu.playeredit.character then
    return text, Color.green
  end
  return text
end

submenu.draw = function(menu)
  characterlist.draw(menu.mx(0), menu.my(0), menu.mz(0), colorAI, menu)
end

return submenu
