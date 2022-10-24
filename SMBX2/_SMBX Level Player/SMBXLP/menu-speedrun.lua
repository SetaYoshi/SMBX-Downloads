local submenu = {}

local stat = GameData.SMBXLP_stat
local settings = GameData.SMBXLP_set

local eventu = require("eventu")
local textplus = require("textplus")
local savestate = require("savestate")
local listgen = require(GameData.SMBXLP_dir.."listgenerator.lua")

local icons = Graphics.loadImage(GameData.SMBXLP_dir.."icons.png")
local textfont = textplus.loadFont("textplus/font/6.ini")
local keyname = {"left", "up", "down", "right", "altJump", "jump", "run", "altRun", "pause", "dropItem"}
local savest
local shownedpop = false

local startedadvantage = false
local startedmultiplayer = false

local camd = {}

submenu.name = "Speedrun"
submenu.type = "STATIC_LIST"

local speeddata = {"Create Savestate", "Load Savestate", "Timer: Change LE", "Timer: Change AS", "Timer: Change MP", "Declare Advantage State", "Show Timer in Seconds", "Show Timer in Frames", "Enable Pop-Up", "Disable Checkpoints", "Show Inputs", "Allow Cheat Validation"}
local speedlist = listgen.create{
  list = speeddata,
  textscale = 2,
  textspacing = 24,
  maxlines = 8
}

local function bool2num(b)
  if b then return 2 end
  return 1
end

local function bool2name(b)
  if b then return "T" end
  return "F"
end

for i = 1, 10 do
  stat.besttime[i] = stat.besttime[i] or {}
  for j = 1, 2 do
    stat.besttime[i][j] = stat.besttime[i][j] or {}
    for k = 1, 2 do
      stat.besttime[i][j][k] = stat.besttime[i][j][k] or false
    end
  end
end

local function getbesttime(winstate, advantage, multiplayer)
  winstate = winstate or settings.timerle
  advantage = advantage or settings.timeras
  multiplayer = multiplayer or settings.timermp

	return stat.besttime[winstate][bool2num(advantage)][bool2num(multiplayer)]
end

local function setbesttime(x)
  local winstate = Level.winState()
  if winstate == 0 then return end

  stat.besttime[winstate][bool2num(startedadvantage)][bool2num(startedmultiplayer)] = x
end

local function setadvantage(p)
  if not settings.advantage[p.idx] then return end
  p.character = settings.advantage[p.idx].character
	p.powerup = settings.advantage[p.idx].powerup
	p.mount = settings.advantage[p.idx].mount
	p.mountColor = settings.advantage[p.idx].mountColor
	p.reservePowerup = settings.advantage[p.idx].reservePowerup
  p:mem(0x16,	FIELD_WORD, settings.advantage[p.idx].health)
end

local function saveadvantage(p)
  settings.advantage[p.idx] = {}
  settings.advantage[p.idx].character = p.character
  settings.advantage[p.idx].powerup = p.powerup
  settings.advantage[p.idx].mount = p.mount
  settings.advantage[p.idx].mountColor = p.mountColor
  settings.advantage[p.idx].reservePowerup = p.reservePowerup
  settings.advantage[p.idx].health = p:mem(0x16, FIELD_WORD)
end

local function checkadvantage(p)
  return p.powerup ~= 1 or p.mount ~= 0 or p.reservePowerup ~= 0 or ((p.character == CHARACTER_PEACH or p.character == CHARACTER_TOAD or p.character == CHARACTER_LINK or p.character == CHARACTER_KLONOA or p.character == CHARACTER_ROSALINA) and p:mem(0x16,	FIELD_WORD) ~= 1)
end

-- From speedruntimer.lua by pixelpest, The0x539, mechdragon777
local function formatTime(t)
	realMiliseconds = math.floor(t*15.6)
	miliseconds = realMiliseconds%1000
	realSeconds = math.floor(realMiliseconds/1000)
	seconds = realSeconds%60
	realMinutes = math.floor(realSeconds/60)
	minutes = realMinutes%60
	hours = math.floor(realMinutes/60)
	if hours < 10 then hours = "0"..tostring(hours)	end	if minutes < 10 then minutes = "0"..tostring(minutes)	end
	if seconds < 10 then seconds = "0"..tostring(seconds)	end
	if miliseconds < 10 then miliseconds = "00"..tostring(miliseconds)
	elseif miliseconds < 100 then	miliseconds = "0"..tostring(miliseconds) end
	return table.concat({hours, minutes, seconds, miliseconds}, ":")
end

local function printinput(p, idx)
  for k, v in ipairs(keyname) do
    if p.rawKeys[v] then
      Graphics.draw{image = icons, type = RTYPE_IMAGE, x = camera.width - 18*(11 - k) - 12, y = camera.height - 32*idx, priority = 9.9, sourceX = 16*(k - 1), sourceWidth = 16}
    end
  end
end

local function printtimer()
	local color
	if GameData.SMBXLP_invalid then
		color = Color.red
	elseif getbesttime() and GameData.SMBXLP_timer < getbesttime() then
		color = Color.green
	end
	local txt
	if settings.frames and settings.seconds then
		txt = "Time: "..formatTime(GameData.SMBXLP_timer).." ["..GameData.SMBXLP_timer.."]"
	elseif settings.frames then
		txt = "Time: "..GameData.SMBXLP_timer
	elseif settings.seconds then
		txt = "Time: "..formatTime(GameData.SMBXLP_timer)
	end
	local y
	if GameData.SMBXLP_activated then
		y = 32
	else
		y = 64
	end
	if txt then
		textplus.print{text = txt, x = 8, y = camera.height - y, priority = 9.9, font = textfont, xscale = 2, yscale = 2, color = color}
	end
end

local function generateOut()
	local txt = ""
	local oldtime = getbesttime(Level.winState(), startedadvantage, startedmultiplayer)
	local newtime = GameData.SMBXLP_timer
	if GameData.SMBXLP_invalid then
		txt = txt.."unfortunately, the level was not validly completed"
	elseif not oldtime then
		setbesttime(newtime)
		txt = txt.."Congratulations, a new record has been created"
	elseif newtime < oldtime then
		setbesttime(newtime)
		txt = txt.."Congratulations, a new record has been set\n"
		txt = txt.."You beat your time by: "..formatTime(oldtime - newtime).." ["..(oldtime - newtime).."]"
	elseif oldtime == newtime then
		txt = txt.."Congratula- ... strange, you tied to your record\n"
	else
		txt = txt.."Unfortunately, a new record was not set\n"
		txt = txt.."You lost by: "..formatTime(newtime - oldtime).." ["..(newtime - oldtime).."]"
	end
  txt = txt.."\n"
  if oldtime then
    txt = txt.."\nPrevious Time: "..formatTime(oldtime).." ["..(oldtime).."]"
  end
  txt = txt.."\nYour Time: "..formatTime(newtime).." ["..newtime.."]"
  txt = txt.."\n\nFORMAT:"
  txt = txt.."\n* Exit Type: "..Level.winState()
  txt = txt.."\n* Starting Advantage: "..tostring(startedadvantage)
  txt = txt.."\n* In Multiplayer: "..tostring(startedmultiplayer)
  txt = txt.."\n\nWas a cheat typed: "..tostring(GameData.SMBXLP_typedcheat)
  txt = txt.."\nAllow typed cheats: "..tostring(settings.enablecheat or false)
	if settings.popup then
		Misc.showRichDialog("LEVEL COMPLETE", txt, true)
	end
end

local createsavestate = function()
  savest = savestate.save()
  camd[1] = camera.x
  camd[2] = camera.y
end

local loadsavestate = function(menu)
  if savest then
    GameData.SMBXLP_invalid = true
    local ismenu = menu.isMenu
    if ismenu then menu.toggle(true) end
    savestate.load(savest)
    if ismenu then
      Misc.pause()
      menu.section = player.section
      menu.camx = camd[1]
      menu.camy = camd[2]
      menu.isMenu = true
    end
  end
end

submenu.input = function(menu, p)
  speedlist.basiccontrol(p)
  local validclick = speedlist.basiccursor(menu.mx(0), menu.my(96))
  if p.rawKeys.jump == KEYS_PRESSED or validclick then
    if speedlist.option == 1 then
      createsavestate()
    elseif speedlist.option == 2 then
      loadsavestate(menu)
    elseif speedlist.option == 3 then
      settings.timerle = settings.timerle + 1
      if settings.timerle > 7 then settings.timerle = 1 end
    elseif speedlist.option == 4 then
      settings.timeras = not settings.timeras
    elseif speedlist.option == 5 then
      settings.timermp = not settings.timermp
    elseif speedlist.option == 6 then
      settings.advantage.active = not settings.advantage.active
      if settings.advantage.active then
        saveadvantage(player)
        local txt = "When starting a level, the player will begin with the following settings:\n\nPLAYER 1:\nCharacter: "..settings.advantage[1].character.."\nPowerup state: "..settings.advantage[1].powerup.."\nMount Type: "..settings.advantage[1].mount.."\nMount Color: "..settings.advantage[1].mountColor.."\nReserve Box: "..settings.advantage[1].reservePowerup.."\nHealth: "..settings.advantage[1].health
        if player2 then
          saveadvantage(player2)
          if settings.advantage[2].character then
            txt = txt.."\n\nPLAYER 2:\nCharacter: "..settings.advantage[2].character.."\nPowerup state: "..settings.advantage[2].powerup.."\nMount Type: "..settings.advantage[2].mount.."\nMount Color: "..settings.advantage[2].mountColor.."\nReserve Box: "..settings.advantage[2].reservePowerup.."\nHealth: "..settings.advantage[2].health
          end
        end
        Misc.showRichDialog("Advantage State", txt, true)
      end
    elseif speedlist.option == 7 then
      settings.seconds = not settings.seconds
    elseif speedlist.option == 8 then
      settings.frames = not settings.frames
    elseif speedlist.option == 9 then
      settings.popup = not settings.popup
    elseif speedlist.option == 10 then
      settings.disablecheckpoint = not settings.disablecheckpoint
    elseif speedlist.option == 11 then
      settings.showinput = not settings.showinput
    elseif speedlist.option == 12 then
      settings.enablecheat = not settings.enablecheat
    end
    SFX.play(menu.sfx_select)
  end
end


local colorAI = function(option, text, menu)
  if option > 5 then
    if (option == 6 and settings.advantage.active) or (option == 7 and settings.seconds) or (option == 8 and settings.frames) or (option == 9 and settings.popup) or (option == 10 and settings.disablecheckpoint) or (option == 11 and settings.showinput) or (option == 12 and settings.enablecheat) then
      return text, Color.green
    else
      return text, Color.orange
    end
  end
  return text
end

submenu.draw = function(menu)
	textplus.print{text = "Current best time:\nFormat: LE["..settings.timerle.."]  AS["..bool2name(settings.timeras).."]  MP["..bool2name(settings.timermp).."]", x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2, color = Color.green, plaintext = true}
	if getbesttime() then
		textplus.print{text = formatTime(getbesttime()).." ["..getbesttime().."]", x = menu.mx(0), y = menu.my(48), priority = menu.mz(0), xscale = 2, yscale = 2, plaintext = true}
	else
		textplus.print{text = "Time not set", x = menu.mx(0), y = menu.my(48), priority = menu.mz(0), xscale = 2, yscale = 2, plaintext = true}
	end
  speedlist.draw(menu.mx(0), menu.my(96), menu.mz(0), colorAI, menu)
end

function submenu.onStart()
  if GameData.SMBXLP_restart then
    if GameData.SMBXLP_restart.type == 1 then
    elseif GameData.SMBXLP_restart.type == 2 then
      GameData.SMBXLP_timer = 0
      GameData.SMBXLP_invalid = false
      GameData.SMBXLP_typedcheat = false
			if settings.advantage.active then setadvantage(player) if player2 then setadvantage(player2) end end
    else
      GameData.SMBXLP_timer = 0
      GameData.SMBXLP_invalid = true
      GameData.SMBXLP_typedcheat = false
			if settings.advantage.active then setadvantage(player) if player2 then setadvantage(player2) end end
    end
	elseif settings.disablecheckpoint then
	  GameData.SMBXLP_timer = 0
		GameData.SMBXLP_invalid = false
    GameData.SMBXLP_typedcheat = false
		if settings.advantage.active then setadvantage(player) if player2 then setadvantage(player2) end end
  end

	if checkadvantage(player) or (player2 and checkadvantage(player2)) then
    startedadvantage = true
	end
  if player2 then
    startedmultiplayer = true
  end
end

function submenu.onDraw()
	if Level.winState() == 0 then
		GameData.SMBXLP_timer = GameData.SMBXLP_timer + 1
	elseif not shownedpop then
		shownedpop = true
		generateOut()
  end
end

function submenu.onCameraDraw(idx)
  if idx == 1 then
    if settings.seconds or settings.frames then
			printtimer()
		end
		if settings.showinput then
			if player2 then
				printinput(player, 2)
				if camera.width == 800 and camera.height == 600 and player2 then
					printinput(player2, 1)
				end
			else
				printinput(player, 1)
			end
		end
	elseif settings.showinput and (camera.width ~= 800 or camera.height ~= 600) and player2 then
    printinput(player2, 1)
  end
end

local winstate
function submenu.onTickEnd()
	winState = Level.winState()
end

function submenu.onExitLevel()
  if winState ~= 0 then
		GameData.SMBXLP_invalid = false
    GameData.SMBXLP_timer = 0
    stat.complete = stat.complete + 1
		if settings.forcereload then
			Checkpoint.reset()
			mem(0x00B250B0, FIELD_STRING, "")
			Level.load("../"..GameData.SMBXLP_filedir.."/"..Level.filename(), "SMBX Level Player")
		end
	end
  if settings.disablecheckpoint then
    Checkpoint.reset()
    mem(0x00B250B0, FIELD_STRING, "")
  end
end

submenu.tablist = {}
submenu.tablist[1] = {
  name = "Create Savestate",
  func = function(menu)
    createsavestate()
    SFX.play(menu.sfx_select)
  end
}
submenu.tablist[2] = {
  name = "Load Savestate",
  func = function(menu)
    SFX.play(menu.sfx_close)
    if savest then loadsavestate(menu) end
  end
}
submenu.tablist[3] = {
  name = "Set to Advantage State",
  func = function(menu)
    SFX.play(menu.sfx_select)
    if settings.advantage.active then setadvantage(player) if player2 then setadvantage(player2) end
  else Misc.showRichDialog("Advantage State", "Advantage state is currently deactivated. To use this you must first declare an\nadvantage state in the speedrunning submenu.\n\nWhen setting an advantage state, the menu will remember your current character, \npower-up, mount, etc. When activating this hotkey, you will return to that declared state.", true)
    end
  end
}

function submenu.onInitAPI()
  registerEvent(submenu, "onExitLevel", "onExitLevel")
  registerEvent(submenu, "onTickEnd", "onTickEnd")
	registerEvent(submenu, "onCameraDraw", "onCameraDraw", true)
  registerEvent(submenu, "onStart", "onStart", true)
  registerEvent(submenu, "onDraw", "onDraw", true)
end


return submenu
