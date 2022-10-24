-- NOTE: this code is very messy and the code is pretty much wrapped with scotch tape. Dont look until I make the code look pretty
local submenu = {}

-- This module open up a lot of different settings that affect the game or menu as a whole

local textplus = require("textplus")
local keys = require(GameData.SMBXLP_dir.."keys.lua")
local listgen = require(GameData.SMBXLP_dir.."listgenerator.lua")
local click = require("click")
local eventu = require("eventu")

local choosingmenukey = false
local unvalidkey = false
local unvalidreason = 0
local validmenuclick = true
local inputList = {"up", "down", "left", "right", "run", "altrun", "jump", "altjump", "dropitem", "pause"}
local settings = GameData.SMBXLP_set
local menulocked = false
local sideheld = 0

-- Generate a list for options
local setlist = listgen.create{
  list = {"Set MenuKey to Pause", "Set MenuKey to Custom", "Music Volume", "Effect Volume", "Show Framerate", "Force Reload", "Infinite Lives", "Disable Death Markers", "Tab HotKey"},
  textscale = 2,
  textspacing = 24,
  maxlines = 9
}

-- Sets the volume to all vanilla sounds and SFX.play() sounds
local setsfxvolume = function(n)
  for k = 1, 91 do
    Audio.sounds[k].sfx.volume = n
  end
  SFX.volume.MASTER = (n)/128
end

-- Get controller config based on the index of player
local geticonfig = function(idx)
  if idx == player.idx then
    return inputConfig1
  else
    return inputConfig2
  end
end

submenu.name = "Settings"
submenu.type = "STATIC_LIST"

submenu.input = function(menu, p)
  setlist.basiccontrol(p)
  local validclick = setlist.basiccursor(menu.mx(0), menu.my(72))
  if p.rawKeys.jump == KEYS_PRESSED or validclick then
    SFX.play(menu.sfx_select)
    validmenuclick = validclick
    if setlist.option == 1 then
      settings.menukeyname = "Pause Key"
      settings.menukeytype = 0
      settings.menukey = 0
    elseif setlist.option == 2 then
      choosingmenukey = true
      menu.disablekeys = true
    elseif setlist.option == 3 then
      Audio.MusicVolume(settings.musicvolume*1.28)
    elseif setlist.option == 4 then
      Audio.MusicVolume(settings.musicvolume*1.28)
    elseif setlist.option == 5 then
      -- menu.toggle()
      Cheats.trigger("framerate", true)
      -- eventu.setFrameTimer(1, function()
      --   menu.isMenu = true
      --   Misc.pause()
      -- end)
    elseif setlist.option == 6 then
      settings.forcereload = not settings.forcereload
    elseif setlist.option == 7 then
      settings.inflife = not settings.inflife
      if settings.inflife then
        mem(0x00B2C5AC, FIELD_FLOAT, 99)
      end
    elseif setlist.option == 8 then
      settings.disablemarker = not settings.disablemarker
    elseif setlist.option == 9 then
      settings.tabkey = settings.tabkey + 1
      if settings.tabkey > #menu.tablist then
        settings.tabkey = 0
      end
    end
  end

  if setlist.option == 3 or setlist.option == 4 then
    local mv
    if setlist.option == 3 then
      mv = settings.musicvolume
    else
      mv = settings.effectvolume
    end
    menu.disablesidekeys = true
    if menu.playerinput.rawKeys.left or menu.playerinput.rawKeys.right then
      sideheld = sideheld + 1
      if sideheld == 1 or (sideheld > 20 and sideheld%10 == 0) then
        if menu.playerinput.rawKeys.left then
          mv = mv - 6.4
        elseif menu.playerinput.rawKeys.right then
          mv = mv + 6.4
        end
        if setlist.option == 4 then
          SFX.play(menu.sfx_scroll)
        end
      end
    else
      sideheld = 0
    end
    mv = math.clamp(0, mv, 128)
    if mv < 0.1 then mv = 0 end
    if setlist.option == 3 then
      settings.musicvolume = mv
    else
      settings.effectvolume = mv
    end
    Audio.MusicVolume(settings.musicvolume*1.28)
    setsfxvolume(settings.effectvolume*1.28)
  else
    menu.disablesidekeys = false
  end
end

local colorAI = function(option, text, menu)
  if (option == 1 and settings.menukeytype == 0) then
    return text, Color.green
  elseif option == 2 and (settings.menukeytype ~= 0 or choosingmenukey) then
    if choosingmenukey then
      return text, "rainbow"
    else
      return text, Color.green
    end
  elseif option == 9 then
    if settings.tabkey == 0 then
      return text, Color.orange
    else
      return text, Color.green
    end
  elseif option > 4 then
    if (option == 5 and Cheats.get("framerate").active) or (option == 6 and settings.forcereload) or (option == 7 and settings.inflife) or (option == 8 and settings.disablemarker)  then
      return text, Color.green
    else
      return text, Color.orange
    end
  end
  return text
end

submenu.draw = function(menu)
  setlist.draw(menu.mx(0), menu.my(72), menu.mz(0), colorAI, menu)

  if not choosingmenukey then
    menu.disablekeys = false
  end

  if click.click then
    if validmenuclick then
      validmenuclick = false
    else
      choosingmenukey = false
      unvalidkey = false
    end
  end

  if choosingmenukey then
    local txt = "Please <color red>hold</color> a valid key"
    if unvalidkey then
      txt = txt.."\n<color red>UNVALID KEY SELECTED"
      if unvalidreason < 3 then
        txt = txt.."\nKey used by player "..unvalidreason
      elseif unvalidreason == 3 then
        txt = txt.."\nHardcoded key"
      end
      txt = txt.."</color>"
    end
    textplus.print{text = txt, x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2}
  else
    if setlist.option <= 2 then
      textplus.print{text = "Current MenuKey:<br><color green>"..settings.menukeyname.." ("..settings.menukey..")</color>", x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2}
    elseif setlist.option == 3 then
      textplus.print{text = "Music Volume: "..settings.musicvolume*0.78125, x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2, plaintext = true}
      Graphics.drawBox{x = menu.mx(0), y = menu.my(38), width = 210, height = 4, color = {0.3, 0.6, 0.3, 1}, priority = menu.mz(0)}
      Graphics.drawBox{x = menu.mx(settings.musicvolume*210/128), y = menu.my(30), width = 4, height = 20, color = {0.1, 0.4, 0.1, 1}, priority = menu.mz(0)}
    elseif setlist.option == 4 then
      textplus.print{text = "Effect Volume: "..settings.effectvolume*0.78125, x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2, plaintext = true}
      Graphics.drawBox{x = menu.mx(0), y = menu.my(38), width = 210, height = 4, color = {0.2, 0.2, 0.5, 1}, priority = menu.mz(0)}
      Graphics.drawBox{x = menu.mx(settings.effectvolume*210/128), y = menu.my(30), width = 4, height = 20, color = {0, 0, 0.5, 1}, priority = menu.mz(0)}
    elseif setlist.option == 5 then
      textplus.print{text = "Displays the framerate\n(Framerate is frozen\nwhen menu is open)", x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2, plaintext = true}
    elseif setlist.option == 6 then
      textplus.print{text = "Forces the level\nto reload on completion", x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2, plaintext = true}
    elseif setlist.option == 7 then
      textplus.print{text = "Forces the lives counter\nto 99", x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2, plaintext = true}
    elseif setlist.option == 8 then
      textplus.print{text = "Disables the markers\nthat appear on death", x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2, plaintext = true}
    elseif setlist.option == 9 then
      textplus.print{text = "Current Tab HotKey\n<color green>"..menu.tablist[settings.tabkey].name.."</color>", x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2}
    end
  end
end

local function setmenuKey(type, name, id, pnum)
  settings.menukeytype = type
  settings.menukeyname = name
  settings.menukeypnum = pnum or 0
  settings.menukey = id
end

local isinvalid = function(type, id, playerNum)
  unvalidkey = false
  if type == 0 and ((id >= 112 and id <= 123) or id == 9) then
    unvalidkey = true
    unvalidreason = 3
    return true
  end
  for i = 1, 2 do
    local iconfig = geticonfig(i)
    if iconfig.inputType ~= type or (playerNum and i ~= playerNum) then

    else
      for k, v in ipairs(inputList) do
        if not (k <= 4 and iconfig.inputType ~= 0) and iconfig[v] == id then
          unvalidkey = true
          unvalidreason = i
          return true
        end
      end
    end
  end
end

function submenu.onKeyboardPressDirect(id, held)
  if not (choosingmenukey) or isinvalid(0, id) or not held then return end
  setmenuKey(1, keys.getName("Keyboard", id), id)
  unvalidkey = false
  choosingmenukey = false
end

function submenu.onControllerButtonPress(buttonIdx, playerNum, controllerName)
  if not (choosingmenukey) or isinvalid(geticonfig(playerNum).inputType, buttonIdx, playerNum) then return end
  setmenuKey(2, keys.getName(controllerName, buttonIdx), buttonIdx, playerNum)
  unvalidkey = false
  choosingmenukey = false
end

function submenu.onStart()
  Audio.MusicVolume(settings.musicvolume*1.28)
  setsfxvolume(settings.effectvolume*1.28)
  if settings.inflife then
    mem(0x00B2C5AC, FIELD_FLOAT, 99)
  end
end

function submenu.onInitAPI()
  registerEvent(submenu, "onStart", "onStart")
  registerEvent(submenu, "onKeyboardPressDirect", "onKeyboardPressDirect")
  registerEvent(submenu, "onControllerButtonPress", "onControllerButtonPress")
end

return submenu
