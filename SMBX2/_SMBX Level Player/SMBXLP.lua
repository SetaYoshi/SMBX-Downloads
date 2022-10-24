local SMBXLP = {}

-- Put the next line at the bottom of lunabase.lua. You can find the file in data/scripts/base/engine/lunabase.lua
-- if not isOverworld and GameData.SMBXLP_activated and Level.filename() ~= "SMBX Level Player.lvlx" then require(getSMBXPath().."\\worlds\\"..GameData.SMBXLP_foldername.."\\SMBXLP.lua") end
-- Make sure its a single line

local listgen = require(GameData.SMBXLP_dir.."listgenerator.lua")
local save = require(GameData.SMBXLP_dir.."save.lua")
local click = require("click")
local eventu = require("eventu")
local rng = require("rng")
local repl = require("base/game/repl")

-- Save data for menu (planned on upgrading save.lua for v1.1. As of now it works in a very awkard method, aka I rushed that library)
save.filepath = GameData.SMBXLP_leveldir
save.data_default = table.clone({deathx = {}, deathy = {}, complete = 0, deathcount = 0, besttime = {}})
save.load()

save.menufilepath = GameData.SMBXLP_dir.."menusavedata"
save.menudata_default = table.clone({
  filedir = "",
  menuhist = {{0, 0}},
  set = {filter = 0, menukeytype = 0, menukeypnum = 0, menukeyname = "Pause Key", menukey = 0, tabkey = 0, advantage = {}, inflife = false, timerle = 1, timeras = false, timermp = false, musicvolume = 128, effectvolume = 128}
})
save.menuload()


-- Initialize useful GameData (perhaps integrate a custom method for GameData in save.lua?)
GameData.SMBXLP_menuhist = save.menudata[Misc.saveSlot()].menuhist
GameData.SMBXLP_filedir = save.menudata[Misc.saveSlot()].filedir
GameData.SMBXLP_set = save.menudata[Misc.saveSlot()].set
GameData.SMBXLP_stat = save.data[Misc.saveSlot()]

GameData.SMBXLP_restart = GameData.SMBXLP_restart or false
GameData.SMBXLP_timer = GameData.SMBXLP_timer or 0
GameData.SMBXLP_invalid = GameData.SMBXLP_invalid or false
GameData.SMBXLP_typedcheat = GameData.SMBXLP_typedcheat or false

-- Table that holds all information of menu data to interact with
SMBXLP.menu = {}
local menu = SMBXLP.menu

-- Load all modules
local allmodules = {
  [0] = require(GameData.SMBXLP_dir.."menu-preview.lua"), -- This is hardcoded
  [1] = require(GameData.SMBXLP_dir.."menu-continue.lua"),
  [2] = require(GameData.SMBXLP_dir.."menu-restart.lua"),
  [3] = require(GameData.SMBXLP_dir.."menu-player.lua"),
  [4] = require(GameData.SMBXLP_dir.."menu-characters.lua"),
  [5] = require(GameData.SMBXLP_dir.."menu-costumes.lua"),
  [6] = require(GameData.SMBXLP_dir.."menu-powerups.lua"),
  [7] = require(GameData.SMBXLP_dir.."menu-mounts.lua"),
  [8] = require(GameData.SMBXLP_dir.."menu-cheats.lua"),
  [9] = require(GameData.SMBXLP_dir.."menu-filters.lua"),
  [10] = require(GameData.SMBXLP_dir.."menu-movecam.lua"),
  [11] = require(GameData.SMBXLP_dir.."menu-speedrun.lua"),
  [12] = require(GameData.SMBXLP_dir.."menu-controls.lua"),
  [13] = require(GameData.SMBXLP_dir.."menu-setting.lua"),
  [14] = require(GameData.SMBXLP_dir.."menu-exit.lua")
}

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then return true end
  end
  return false
end

-- Generate hardcoded list of tab hotkeys (these are harcoded)
local tablist = {}
tablist[0] = {
  name = "None",
  func = function() end
}
tablist[1] = {
  name = "REPL",
  func = function()
    menu.plx = player.x
    menu.ply = player.y
    menu.repltabactivated = true
    repl.activeInEpisode = true
  end
}
menu.tablist = tablist


-- Generate a list for the modules
local modulelist = listgen.create{
  list = {},
  textscale = 2.5,
  textspacing = 26,
  width = 158,
  maxlines = 8
}
menu.modulelist = modulelist

-- Update what options appear on the actual list. Use disable parameter so certain submenus dont appear
menu.updatemodules = function(disable)
  menu.modules = {[0] = allmodules[0]}
  local modulenamelist = {[0] = allmodules[0].name}
  for k, v in ipairs(allmodules) do
    if not table.contains(disable, v.name) then
      table.insert(menu.modules, v)
      table.insert(modulenamelist, v.name)
      v.tablist = v.tablist or {}
      for _, q in ipairs(v.tablist) do
        table.insert(tablist, {name = q.name, func = q.func})
      end
    end
  end
  menu.modulelist.list = modulenamelist
  menu.modulelist.update()
end

-- Better rng used by multiple modules
menu.betterrng = function(tbl, x)
  local t = {}
  for _, v in ipairs(tbl) do
    if v ~= x then
      table.insert(t, v)
    end
  end
  return rng.irandomEntry(t)
end

-- Returns the position of a module using a name
menu.findmodule = function(name)
  for k, v in ipairs(menu.modules) do
    if v.name == name then
      return k
    end
  end
end

-- Only show the "Change Player" module in multiplayer
local disable = {}
if not player2 then table.insert(disable, "Change Player") end
menu.updatemodules(disable)

-- Misc variables
menu.isMenu = false
menu.cooldown = 0
menu.wasrepl = false
menu.disable = false
menu.disablekeys = false
menu.disablesidekeys = false
menu.playerinput = player
menu.playeredit = player
menu.activatedmodule = 0
menu.customcamera = false
menu.section = 0
menu.camx = 0
menu.camy = 0
menu.plx = 0
menu.ply = 0

menu.ox, menu.oy, menu.oz = 174, 100, 9.99
menu.x, menu.y, menu.z = menu.ox, menu.oy, menu.oz
menu.img = Graphics.loadImage(GameData.SMBXLP_dir.."menu-screen.png")

menu.px = function(x) return menu.x + x end
menu.py = function(y) return menu.y + y end
menu.pz = function(z) return menu.z + z end

menu.mx = function(x) return menu.x + 220 + x end
menu.my = function(y) return menu.y + 64 + y end
menu.mz = function(z) return menu.z + z end

menu.sfx_open = Audio.SfxOpen(GameData.SMBXLP_dir.."open.wav")
menu.sfx_close = Audio.SfxOpen(GameData.SMBXLP_dir.."close.wav")
menu.sfx_select = Audio.SfxOpen(GameData.SMBXLP_dir.."select.wav")
menu.sfx_scroll = Audio.SfxOpen(GameData.SMBXLP_dir.."scroll.wav")

-- Lock the camera to disable split screen
menu.lockcamera = function()
  menu.customcamera = true
  menu.section = player.section
  menu.camx = camera.x
  menu.camy = camera.y
  menu.plx = player.x
  menu.ply = player.y
end

-- Unlock the camera and make it go back to normal
menu.unlockcamera = function()
  menu.customcamera = false
  player.section = menu.section
end


-- Turn the menu on or off
menu.toggle = function(mute)
  if menu.cooldown ~= 0 or menu.disable then return end
  local currmodule = menu.modules[menu.activatedmodule]
  if menu.isMenu then
    if currmodule and currmodule.exit and menu.activatedmodule ~= 0 then currmodule.exit(menu) end
    Misc.unpause()
    menu.unlockcamera()
    repl.active = false
    repl.activeInEpisode = false
    if not mute then SFX.play(menu.sfx_close) end
  else
    if currmodule and currmodule.start and menu.activatedmodule ~= 0 then currmodule.start(menu) end
    Misc.pause()
    menu.lockcamera()
    repl.activeInEpisode = true
    if not mute then SFX.play(menu.sfx_open) end
  end
  menu.cooldown = 5
  menu.isMenu = not menu.isMenu
end

-- Handle inputs in the menu (needs cleaup, it looks messy)
-- TBH, I kinda dont know whats going on either. I promise I'll fix it later
menu.input = function()
  local playerinput = menu.playerinput
  if menu.activatedmodule == 0 then
    modulelist.basiccontrol(menu.playerinput)
    local validclick = modulelist.basiccursor(menu.px(16), menu.py(150))
    if (playerinput.rawKeys.jump == KEYS_PRESSED or playerinput.rawKeys.right == KEYS_PRESSED) or validclick or (click.click and click.box{x = menu.mx(0), y = menu.my(0), width = 200, height = 340} and menu.modules[modulelist.option].type == "STATIC_LIST") then
      local currmodule = menu.modules[modulelist.option]
      if currmodule.type == "STATIC_FUNC" then
        currmodule.activate(menu)
      else
        if currmodule.start then currmodule.start(menu) end
        SFX.play(menu.sfx_select)
        menu.activatedmodule = modulelist.option
      end
    end
    if (playerinput.rawKeys.run == KEYS_PRESSED) then
      menu.toggle()
    end
  else
    if (playerinput.rawKeys.run == KEYS_PRESSED or (not menu.disablesidekeys and playerinput.rawKeys.left == KEYS_PRESSED)) or (click.click and click.box{x = menu.px(16), y = menu.py(150), width = modulelist.width, height = modulelist.textspacing*(modulelist.maxarrowoffset + 1) + 34}) then
      local currmodule = menu.modules[menu.activatedmodule]
      SFX.play(menu.sfx_close)
      if currmodule.exit then currmodule.exit(menu) end
      menu.activatedmodule = 0
      menu.customcamera = true
    else
      menu.modules[menu.activatedmodule].input(menu, playerinput)
    end
  end
end

-- Formula for the color pattern for menu
local lightgray = Color(0.48, 0.48, 0.48)
local colorAI = function(option, text)
  if modulelist.option == option then
    return text, Color.green
  elseif menu.activatedmodule ~= 0 then
    return text, lightgray
  end
  return text
end

-- Draw the menu
menu.draw = function()
  Graphics.drawImageWP(menu.img, menu.x, menu.y, menu.z)
  menu.modules[0].onDraw(menu)
  modulelist.draw(menu.px(16), menu.py(150), menu.pz(0), colorAI)
  menu.modules[modulelist.option].draw(menu, menu.activatedmodule == 0)
end

function SMBXLP.onDraw()
  -- menu toggle cooldown (the cooldown gives it that menu feel, ya get me?)
  if menu.cooldown > 0 then
    menu.cooldown = menu.cooldown - 1
  end

  -- General manager code
  if not menu.disablekeys and not repl.active then
    if menu.isMenu then
      -- Check inputs for menu purposes
      menu.input(menu, menu.playerinput)

      -- Close menu if pause is hit and menukey is set to pause key or there is a click outside the menu
      if (GameData.SMBXLP_set.menukey == 0 and menu.playerinput.rawKeys.pause == KEYS_PRESSED) or (click.click and not click.box{x = menu.x, y = menu.y, width = menu.img.width, height = menu.img.height}) then
        menu.toggle()
      end
    elseif GameData.SMBXLP_set.menukeytype == 0 then
      -- Open menu if pause is hit and menukey is set to pause key
      for _, p in ipairs({player, player2}) do
        if p and p.rawKeys.pause == KEYS_PRESSED then
          menu.playeredit = p
          menu.playerinput = p
          menu.toggle()
        end
      end
    end
  end

  -- Do everything related to dragging the menu using the mouse
  if menu.isMenu and click.click then
    -- Detect if there was a click on the top of the menu
    if click.box{x = menu.x, y = menu.y, width = menu.img.width, height = 48} then
      menu.isdrag = true
    end
  elseif menu.isdrag then
    -- Move the menu with the same speed as the mouse
    if click.hold then
      menu.x = menu.x + click.speedX
      menu.y = menu.y + click.speedY
    elseif click.released then
      menu.isdrag = false
      -- Reset menu position if it is dragged ofscreen or the top part is inaccesible
      if menu.x > 790 or menu.x < -menu.img.width + 10 or menu.y > 590 or menu.y < 0 then
        menu.x, menu.y = menu.ox, menu.oy
      end
    end
  end

  -- Draw the menu
  if menu.isMenu and not repl.active then
    menu.draw()
  end

  -- REPL does some weird things when you turn it off, here is a workaround fix
  if menu.wasrepl and not repl.active then
    player.x = menu.plx
    player.y = menu.ply
    if menu.repltabactivated then
      menu.repltabactivated = false
    else
      Misc.pause()
    end
  end
  menu.wasrepl = repl.active
end

-- If puase menu is set to pause key, deactivate the vanilla pause screen
function SMBXLP.onPause(eventObj)
  if GameData.SMBXLP_set.menukeytype == 0 then
    eventObj.cancelled = true
  end
end

-- If menuKey is set to a custom keyboard key, toggle menu when the custom key is pressed
-- If tab is pressed, enable the tab hotkey set by the user
function SMBXLP.onKeyboardPressDirect(id, b)
  if not menu.disablekeys and GameData.SMBXLP_set.menukeytype == 1 and id == GameData.SMBXLP_set.menukey and not b and not repl.active then
    menu.toggle()
  end

  if id == 9 and not b and not menu.isMenu and GameData.SMBXLP_set.tabkey ~= 0 and GameData.SMBXLP_activated then
    tablist[GameData.SMBXLP_set.tabkey].func(menu)
  end
end

-- If menuKey is set to a custom controller button, toggle menu when the custom buttom is pressed
function SMBXLP.onControllerButtonPress(buttonIdx, playerNum, controllerName)
  if not menu.disablekeys and GameData.SMBXLP_set.menukeytype == 2 and buttonIdx == GameData.SMBXLP_set.menukey and not b and not repl.active then
    menu.toggle()
  end
end

local function getSection(x,y,w,h)
	for k,v in ipairs(Section.get()) do
		local b = v.boundary
		if (x + w >= b.left and x <= b.right) and (y+h >= b.top and y <= b.bottom) then
			return k-1
		end
	end
	return -1
end

-- Disable splitscreen when the menu is on
function SMBXLP.onCameraUpdate(idx)
  if menu.customcamera then
    -- Brute force camera 1 to be at render position of 0,0 with a sixe of 800x600
    -- Brute force camera 2 to be outside of the screen so it is never visible
    -- Change camera 1's and camera 2's scene position if the menu is focusing on player 2
    if idx == 1 then
      if menu.playeredit.idx == 2 then
        camera.x = camera2.x
        camera.y = camera2.y
      else
        camera.x = menu.camx
        camera.y = menu.camy
      end
      camera.renderX = 0
      camera.renderY = 0
      camera.width = 800
      camera.height = 600
    else
      camera2.renderY = 800
    end

    -- Run custom camera code for modules
    local cf = menu.modules[menu.activatedmodule].camera
    if cf then cf(idx, menu) end

    -- Make sure that the camera doesnt go outside the section's boundary
    local s = getSection(camera.x+2, camera.y+2, 800, 600)
    if s == -1 then s = menu.playeredit.section end
    if s >= 0 then
      sec = Section(s).boundary
      camera.x = math.clamp(sec.left, camera.x, sec.right - 800)
      camera.y = math.clamp(sec.top, camera.y, sec.bottom - 600)
      player.section = s
    end
  end
end


-- Fix for the "Level - Start" glitch ;)
-- Cancel the vanilla "Level - Start" event, if called
-- Afterwards, manually trigger the "Level - Start" event on start guaranteeing it is always called once
local realstart
function SMBXLP.onStart()
  if not realstart then
    realstart = true
    triggerEvent("Level - Start")
    Misc.cheatBuffer("SMBXLP")
  end
end

function SMBXLP.onEventDirect(eventObj, eventName)
  if eventName == "Level - Start" and not realstart then
    eventObj.cancelled = true
  end
end

-- Save all data when a level is exited (this is what I meant that save.lua is awkard to use atm)
function SMBXLP.onExitLevel()
  Misc.saveGame()
  save.menudata[Misc.saveSlot()].menuhist = GameData.SMBXLP_menuhist
  save.menudata[Misc.saveSlot()].filedir = GameData.SMBXLP_filedir
  save.save()
  save.menusave()
end

-- Register listener functions
function SMBXLP.onInitAPI()
  registerEvent(SMBXLP, "onDraw", "onDraw")
  registerEvent(SMBXLP, "onStart", "onStart")
  registerEvent(SMBXLP, "onPause", "onPause")
  registerEvent(SMBXLP, "onExitLevel", "onExitLevel")
  registerEvent(SMBXLP, "onEventDirect", "onEventDirect")
  registerEvent(SMBXLP, "onCameraUpdate", "onCameraUpdate", true)
  registerEvent(SMBXLP, "onKeyboardPressDirect", "onKeyboardPressDirect")
  registerEvent(SMBXLP, "onControllerButtonPress", "onControllerButtonPress")
end

return SMBXLP
