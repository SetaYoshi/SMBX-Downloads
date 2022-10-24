local submenu = {}

local rng = require("rng")
local playerManager = require("playerManager")
local listgen = require(GameData.SMBXLP_dir.."listgenerator.lua")

local characterID = {}
for k, v in pairs(playerManager.getCharacters()) do
  table.insert(characterID, k)
end

local costumeData = {}
local costumeList = {}
for _, v in pairs(characterID) do
  costumeData[v] = playerManager.getCostumes(v)
  table.insert(costumeData[v], 1, "None")
  local t = table.clone(costumeData[v])
  table.insert(t, 1, "Random")
  costumeList[v] = listgen.create{
    list = t,
    textscale = 2,
    textspacing = 24,
    maxlines = 12
  }
end

submenu.name = "Costumes"
submenu.type = "STATIC_LIST"

submenu.input = function(menu, p)
  local costumelistsp = costumeList[menu.playeredit.character]
  costumelistsp.basiccontrol(p)
  local validclick = costumelistsp.basiccursor(menu.mx(0), menu.my(0))
  if p.rawKeys.jump == KEYS_PRESSED or validclick then
    local costumecharlist = costumeData[menu.playeredit.character]
    local x
    if costumelistsp.option == 1 then
      local costumename = playerManager.getCostume(menu.playeredit.character) or "None"
      x = menu.betterrng(costumecharlist, costumename)
    else
      x = costumecharlist[costumelistsp.option - 1]
    end
    playerManager.setCostume(menu.playeredit.character, x)
    GameData.SMBXLP_invalid = true
    SFX.play(menu.sfx_select)
  end
end

local colorAI = function(option, text, menu)
  if option == 1 then
    return text, "rainbow"
  elseif costumeData[menu.playeredit.character][option - 1] == playerManager.getCostume(menu.playeredit.character) or (option == 2 and playerManager.getCostume(menu.playeredit.character) == nil) then
    return text, Color.green
  end
  return text
end

submenu.draw = function(menu)
  costumeList[menu.playeredit.character].draw(menu.mx(0), menu.my(0), menu.mz(0), colorAI, menu)
end

return submenu
