local submenu = {}

local textplus = require("textplus")
local keys = require(GameData.SMBXLP_dir.."keys.lua")
local listgen = require(GameData.SMBXLP_dir.."listgenerator.lua")
local click = require("click")

local delay = 1
local playeredit = player
local choosingcontrolkey = false
local choosingallkeys = false
local controlKeyID = 0
local unvalidkey = false
local validmenuclick = true
local inputList = {"up", "down", "left", "right", "run", "altrun", "jump", "altjump", "dropitem", "pause"}

local controllist = listgen.create{
  list = {"Set All Controller Keys", "Set Up Key", "Set Down Key", "Set Left Key", "Set Right Key", "Set Run Key", "Set Altrun Key", "Set Jump Key", "Set Altjump Key", "Set Drop Item Key", "Set Pause Key"},
  textscale = 2,
  textspacing = 24,
  maxlines = 9
}

local geticonfig = function (idx)
  if idx == player.idx then
    return inputConfig1
  else
    return inputConfig2
  end
end

submenu.name = "Controls"
submenu.type = "STATIC_LIST"

submenu.input = function(menu, p)
  controllist.basiccontrol(p)
  local validclick = controllist.basiccursor(menu.mx(0), menu.my(72))
  if p.rawKeys.jump == KEYS_PRESSED or validclick then

    SFX.play(menu.sfx_select)
    choosingcontrolkey = true
    menu.disablekeys = true
    playeredit = menu.playeredit
    validmenuclick = validclick
    delay = 1

    if controllist.option == 1 then
      choosingallkeys = true
      controlKeyID = 1
      controllist.move(1)
      if geticonfig(playeredit.idx).inputType ~= 0 then
        controllist.move(4)
        controlKeyID = 5
      end
    else
      choosingallkeys = false
      controlKeyID = controllist.option - 1
      if geticonfig(playeredit.idx).inputType ~= 0 and controlKeyID <= 4 then
        choosingcontrolkey = false
      end
    end
  end
end

local colorAI = function(option, text, menu)
  if choosingcontrolkey and (option - 1 == controlKeyID) or option == 1 then
    return text, "rainbow"
  end
  return text
end

submenu.draw = function(menu)
  controllist.draw(menu.mx(0), menu.my(72), menu.mz(0), colorAI, menu)

  local battery = Misc.GetSelectedControllerPowerLevel()
  if battery >= 0 then
    Graphics.draw{image = Graphics.sprites.hardcoded[54].img, type = RTYPE_IMAGE, x = menu.mx(192), y = menu.my(-64), priority = menu.mz(0), sourceY = 128 - 32*(math.min(3, battery) + 1), sourceHeight = 32}
  end

  if not choosingcontrolkey then
    if delay > 0 then
      delay = delay - 1
    else
      menu.disablekeys = false
    end
  end

  if geticonfig(playeredit.idx).inputType ~= 0 and choosingcontrolkey and controllist.option < 6 then
    controlKeyID = 5
    controllist.option = 6
    controllist.offset = 0
    controllist.arrowoffset = 5
  end

  if click.click then
    if validmenuclick then
      validmenuclick = false
    else
      choosingcontrolkey = false
      unvalidkey = false
    end
  end

  if choosingcontrolkey then
    local txt = "Please <color red>hold</color> a valid key"
    if unvalidkey then
      txt = txt.."\n<color red>UNVALID KEY SELECTED"
      if unvalidreason == 3 then
        txt = txt.."\nHardcoded key"
      elseif unvalidreason == 4 then
        txt = txt.."\nWrong Control"
      end
      txt = txt.."</color>"
    end
    textplus.print{text = txt, x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2}
  else
    if controllist.option == 1 then
      textplus.print{text = "Select to set all\ncontrol keys", x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2, plaintext = true}
    else
      local iconfig = geticonfig(menu.playeredit.idx)
      local id
      local controllerName = Misc.GetSelectedControllerName(menu.playeredit.idx)
      if iconfig.inputType == 0 or controllist.option > 5 then
        local id = iconfig[inputList[controllist.option - 1]]
        textplus.print{text = "Current Control Key:<color green>\n"..controllerName.."\n"..keys.getName(controllerName, id).." ("..id..")</color>", x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2}
      else
        textplus.print{text = "Current Control Key:\n<color green>"..controllerName.."</color>\n<color red>Control Stick (Hardcoded)</color>", x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2}
      end
    end
  end
end



local function setcontrolkey(playerid, buttonname, controltype, controlid)
  local iconfig = geticonfig(playerid)
  iconfig[buttonname] = controlid
end

local isinvalid = function(type, id, playerNum)
  unvalidkey = false
  local iconfig = geticonfig(playerNum)
  if type == 0 and (id >= 112 and id <= 123) or (type ~= 0 and id == 9) then
    unvalidkey = true
    unvalidreason = 3
    return true
  elseif not ((type == 0 and type == iconfig.inputType ) or (type ~= 0 and iconfig.inputType ~= 0)) then
    unvalidkey = true
    unvalidreason = 4
    return true
  end
end

local function advancesetallkeys()
  controlKeyID = controlKeyID + 1
  controllist.move(1, true)
  if controlKeyID == 11 then
    controlKeyID = 0
    choosingcontrolkey = false
  end
end

function submenu.onKeyboardPressDirect(id, held)
  if not (choosingcontrolkey) or isinvalid(0, id, playeredit.idx) or held then return end
  setcontrolkey(playeredit.idx, inputList[controlKeyID], 0, id)
  unvalidkey = false
  if choosingallkeys then
    advancesetallkeys()
  else
    controlKeyID = 0
    choosingcontrolkey = false
  end
end

function submenu.onControllerButtonPress(buttonIdx, playerNum, controllerName)
  if not (choosingcontrolkey) or isinvalid(geticonfig(playeredit.idx).inputType, buttonIdx, playeredit.idx) or playerNum ~= playeredit.idx then return end
  setcontrolkey(playeredit.idx, inputList[controlKeyID], 0, buttonIdx)
  unvalidkey = false
  if choosingallkeys then
    advancesetallkeys()
  else
    controlKeyID = 0
    choosingcontrolkey = false
  end
end

function submenu.onInitAPI()
  registerEvent(submenu, "onKeyboardPressDirect", "onKeyboardPressDirect")
  registerEvent(submenu, "onControllerButtonPress", "onControllerButtonPress")
end

return submenu
