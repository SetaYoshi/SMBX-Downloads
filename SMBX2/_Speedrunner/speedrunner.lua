local lib = {}

-- Important data needed for the rest of the library
local PATH = getSMBXPath().."\\worlds\\_Speedrunner\\"
local textplus = require("textplus")
local playerManager = require("playerManager")
local savestate = require("savestate")
local inEpisode = Misc.saveSlot() > 0

local starcoin
if not isOverworld then
  starcoin = require("npcs/AI/starcoin")
end

local function formatTime(t)
	if t < 0 then t = -t end
	realMiliseconds = math.floor(t*15.6)
	miliseconds = realMiliseconds%1000
	realSeconds = math.floor(realMiliseconds/1000)
	seconds = realSeconds%60
	realMinutes = math.floor(realSeconds/60)
	minutes = realMinutes%60
	hours = math.floor(realMinutes/60)
	if hours < 10 then hours = "0"..tostring(hours)	end
  if minutes < 10 then minutes = "0"..tostring(minutes)	end
	if seconds < 10 then seconds = "0"..tostring(seconds)	end
	if miliseconds < 10 then miliseconds = "00"..tostring(miliseconds)
	elseif miliseconds < 100 then	miliseconds = "0"..tostring(miliseconds) end
  if hours ~= "00" then
	  return table.concat({hours, minutes, seconds, miliseconds}, ":")
  else
    return table.concat({minutes, seconds, miliseconds}, ":")
  end
end

local function signSym(n)
	if n < 0 then
		return "-"
  end
	return "+"
end

local function tplusColorCode(s, n)
	if n < 0 then
		return "<color rainbow>"..s.."</color>"
	elseif n > 0 then
		return "<color red>"..s.."</color>"
	else
		return "<color gray>"..s.."</color>"
  end
end

GameData._speeddata = GameData._speeddata or {}
local speeddata = GameData._speeddata



-- Reset timer when an episode run begins
if inEpisode then
	if speeddata.prevsavefile ~= Misc.saveSlot() or speeddata.prevepisodepath ~= Misc.episodePath() then
		speeddata.etimer = nil
		speeddata.log = nil
	end
	speeddata.prevepisodepath = Misc.episodePath()
	speeddata.prevsavefile = Misc.saveSlot()
	speeddata.etimer = speeddata.etimer or 0
end


-- Different speedrun categories
local catPowerup = false
local catMult = false
local catStarcoins = false

-- Set up the menu settings
local settingsLib = require(PATH.."settings.lua")
local settings = settingsLib.data



-- Only save the attempt counter from being reset
local s_attemptcount = speeddata.attempt
local s_prevlevel = speeddata.prevLevel

-- reset gamedata to simulate the level being loaded for the first time
if settings.disableChecks and not inEpisode then
  _G.GameData = {_speeddata = {}, _repl = {log = {}, history = {}}, __activatedCheats = {}, _basegame = {bigSwitch = {}}, __checkpoints = { [Level.filename()] = {} } }
end

speeddata = GameData._speeddata

speeddata.attempt = s_attemptcount
speeddata.prevLevel = s_prevlevel

speeddata.etimer = speeddata.etimer or 0
speeddata.log = speeddata.log or {}

speeddata.logger = speeddata.logger or {}
speeddata.startState = speeddata.startState or {}
speeddata.timer = speeddata.timer or 0
speeddata.attempt = speeddata.attempt or 0
speeddata.starcoin = speeddata.starcoin or {}

if not isOverworld then
	-- Easy workaround to detect if the player collected the starcoins in a run
	local starcoin_collect = starcoin.collect
	starcoin.collect = function(coin)
		local CoinData = starcoin.getTemporaryData()
		if CoinData[coin.ai2] then
			speeddata.starcoin[coin.ai2] = true
		end
		-- Check if all the starcoins have been collected
		catStarcoins = (#speeddata.starcoin == starcoin.max()) and (#speeddata.starcoin > 0)

		starcoin_collect(coin)
	end


	-- Need to detect when a new level is loaded through the editor!
	local prevLevel = speeddata.prevLevel
	local currLevel = Misc.episodePath()..string.match(Level.filename(), "(.+)%..+$")
	if prevLevel ~= currLevel then
		speeddata.logger = {}
		speeddata.startState = {}
		speeddata.attempt = 0
		speeddata.timer = 0
		speeddata.starcoin = {}
	end
	speeddata.prevLevel = currLevel
end


-- Images and lookups
local iInputs = Graphics.loadImage(PATH.."inputs.png")
local iCategories = Graphics.loadImage(PATH.."categories.png")
local iStat = Graphics.loadImage(PATH.."stat.png")
local iFavorite = Graphics.loadImage(PATH.."favorite.png")
local textfont = textplus.loadFont("textplus/font/6.ini")

local timerX = {0, 8, 400, 792}
local timerXSplit = {0, 8, 200, 396}
local timerPivot = {vector(0, 0), vector(0, 1), vector(0.5, 1), vector(1, 1)}
local timerSize = {1, 2, 2.5}

local pList = {player, player2}
local keyname = {"left", "up", "down", "right", "jump", "altJump", "run", "altRun", "dropItem", "pause"}
local inputX = {0, 8, 376, 744}
local inputXSplit = {0, 8, 176, 644}

local finTypes = {
  [0] = "Custom Game End",
  [1]  = "Roulette",
  [2]  = "? Orb",
  [3]  = "Keyhole",
  [4]  = "Crystal Orb",
  [5]  = "Game End",
  [6]  = "Star",
  [7]  = "Goal Tape",
  [8]  = "Offscreen Exit",
  [9]  = "Warp Exit",
}

local forcedTypes = {
	[FORCEDSTATE_NONE] = "None",
	[FORCEDSTATE_POWERUP_BIG] = "Powerup Mushroom",
	[FORCEDSTATE_POWERDOWN_SMALL] = "Powerdown Mushroom",
	[FORCEDSTATE_PIPE] = "Warp Pipe",
	[FORCEDSTATE_POWERUP_FIRE] = "Powerup Fire Flower",
	[FORCEDSTATE_POWERUP_LEAF] = "Powerup Leaf",
	[FORCEDSTATE_RESPAWN] = "Respawning",
  [FORCEDSTATE_DOOR] = "Warp Door",
	[FORCEDSTATE_INVISIBLE] = "Invisible",
	[FORCEDSTATE_ONTONGUE] = "Yoshi Tongue",
	[FORCEDSTATE_SWALLOWED] = "Yoshi Swallowed",
	[FORCEDSTATE_POWERUP_TANOOKI] = "Powerup Tanooki",
	[FORCEDSTATE_POWERUP_HAMMER] = "Powerup Hammer",
	[FORCEDSTATE_POWERUP_ICE] = "Powerup Ice",
	[FORCEDSTATE_POWERDOWN_FIRE] = "Powerdown Fire",
  [FORCEDSTATE_POWERDOWN_ICE] = "Powerdown Ice",
	[FORCEDSTATE_MEGASHROOM] = "Mega Mushroom",
	[FORCEDSTATE_TANOOKI_POOF] = "Tanooki Statue"
}

-- Important things to keep track of
local episodeName = mem(0xB2C624, FIELD_STRING)
local forceExitWarp = 0
local isFollowingSectionSplit = false
local sectionSplit = 1
local customFinish = {}

local hasLevelWon
local hasEpisodeWon
local levelWinTimeDiff
local episodeWinTimeDiff

local prevBestRun
local savest
local hasbegun
local notif = {txt = "", timer = -1}

-- Things to log while playing the level!
local logger = speeddata.logger
logger.inputs = logger.inputs or {}
logger.sectionsplit = logger.sectionsplit or {}
logger.forcedState = logger.forcedState or {}
logger.onground = logger.onground or 0
logger.spinjump = logger.spinjump or 0
logger.sliding = logger.sliding or 0
for k, v in ipairs(keyname) do
	logger.inputs[v] = logger.inputs[v] or 0
end


-- Load the library that stores the level's PBs
local levelstatLib
local levelstat
if not isOverworld then
	levelstatLib = require(PATH.."levelstat.lua")
	levelstat = levelstatLib.data
end

-- Load the library that stores the episodes's PBs
local worldstatLib
local worldstat
if inEpisode then
  worldstatLib = require(PATH.."worldstat.lua")
  worldstat = worldstatLib.data
end


-- Input manager for menu
local commander = require(PATH.."mycommander.lua")
commander.register{{menu = 192, delete = 46, savestate = 116, loadstate = 117, back = {name = "run"}, select = {name = "jump"}, up = {name = "up"},  down = {name = "down"}, left = {name = "left"}, right = {name = "right"}}}
--        192 is the tilde key | 46 is the delete key | 116 is the f5 key | 117 is the f6 key

-- Load the menu library and pass important data
local menu = require(PATH.."mymenu.lua")
menu.data = settings
menu.input = commander[1]
menu.save = settingsLib.save

menu.aScroll = Audio.SfxOpen(PATH.."scroll.ogg")
menu.aOpen = Audio.SfxOpen(PATH.."open.ogg")
menu.aClose = Audio.SfxOpen(PATH.."close.ogg")
menu.aSelect = Audio.SfxOpen(PATH.."select.ogg")

-- Inputs for the PBs menu
local logtick = function(subdata)
	local input = menu.input
  if input.select.time == 1 or (input.select.time > 20 and input.select.time % 15 == 0) then
    subdata.mode = subdata.mode + 1
    if subdata.mode == 4 then subdata.mode = 1 end
    SFX.play(menu.aScroll)
  end

	if input.up.time == 1 or (input.up.time > 20 and input.up.time % 15 == 0) then
		subdata.suboption = subdata.suboption - 1
    SFX.play(menu.aScroll)
	elseif input.down.time == 1 or (input.down.time > 20 and input.down.time % 15 == 0) then
		subdata.suboption = subdata.suboption + 1
    SFX.play(menu.aScroll)
	end
	if subdata.suboption <= 0 then
		subdata.suboption = math.max(1, #levelstat)
	elseif subdata.suboption > #levelstat then
		subdata.suboption = 1
	end

  if menu.input.delete.time == 180 then
    table.remove(levelstat, subdata.suboption)
    levelstatLib.save()
    SFX.play(43)
    if subdata.suboption > #levelstat then
  		subdata.suboption = 1
  	end
    menu.submenu = 0
  end
end


local charNameList = {}
local costumelist = {"NONE"}
for k, v in pairs(playerManager.getCharacters()) do
	charNameList[k] = v.name
	for _, c in ipairs(playerManager.getCostumes(k)) do
		table.insert(costumelist, c)
	end
end
local function getCharName(id)
  local s = charNameList[id]
  if s then return s end
  return "Unknown"
end

local function getCostumeName(name)
  if not name then return "None" end
  return name
end

local powNameList = {"Small", "Mushroom", "Fire Flower", "Super Leaf", "Tanooki Suit", "Hammer Suit", "Ice Flower"}
local function getPowName(id)
  local s = powNameList[id]
  if s then return s end
  return "Unknown"
end

local mountNameList = {"None", "Goomba Shoe", "Podoboo Shoe", "Lakitu Shoe", "Green Yoshi", "Blue Yoshi", "Yellow Yoshi", "Red Yoshi", "Black Yoshi", "Purple Yoshi", "Pink Yoshi", "Cyan Yoshi", "Clown Car"}
local function getMountName(type, color)
  if type == 0 then
    return mountNameList[1]
  elseif type == 1 then
    return mountNameList[1 + color]
  elseif type == 2 then
    return mountNameList[4 + color]
  elseif type == 3 then
    return mountNameList[12]
  end
  return "Unknown"
end

local boxNameList = {[9] = "Mushroom", [14] = "Fire Flower", [22] = "Billy Gun", [26] = "Spring", [29] = "Hammer Bro.", [31] = "Key", [32] = "P-Switch", [34] = "Super Left", [35] = "Goomba Shoe", [49] = "Ptooie", [56] = "Koopa Clown Car", [95] = "Green Yoshi", [98] = "Blue Yoshi", [99] = "Yellow Yoshi", [100] = "Red Yoshi", [148] = "Black Yoshi", [149] = "Purple Yoshi", [150] = "Pink Yoshi", [169] = "Tanooki Suit", [170] = "Hammer Suit", [183] = "Fire Flower", [184] = "Mushroom", [185] = "Mushroom", [191] = "Podoboo Shoe", [194] = "Rainbow Shell", [228] = "Cyan Yoshi", [241] = "Pow-Block", [249] = "Mushroom", [250] = "Heart", [264] = "Ice Flower", [277] = "Ice Flower", [278] = "Propeller Block", [279] = "Flamethrower Propeller Block", [293] = "Starman", [325] = "Green Baby Yoshi", [326] = "Red Baby Yoshi", [327] = "Blue Yoshi", [328] = "Yellow Baby Yoshi", [329] = "Baby Black Yoshi", [330] = "Purple Baby Yoshi", [331] = "Pink Baby Yoshi", [332] = "Cyan Yoshi", [334] = "Snake Block", [419] = "Arrow Lift", [425] = "Mega Mushroom", [427] = "Red Spring", [428] = "Sideways Spring", [462] = "Heart", [666] = "Walking Rinka Block"}
local function getBoxName(id)
  if id == 0 then return "None" end
  local s = boxNameList[id]
  if s then return id.."("..s..")" end
  return id
end

local function textplusPBPrint(text, x, y)
  textplus.print{text = text, x = x, y = 8 + 26*y, xscale = 2, yscale = 2, plaintext = true, font = textfont, priority = 9.99}
end

local PBModes = {"BEST", "RUNS", "SAVED"}

local function renderLevelStats(logs, id, episodeMode)
  local offset = 0
  if episodeMode then offset = 1 end

  local selection = logs[id]
  local category = selection.category

  local heading = selection.levelName
  if #logs > 1 then heading = "["..id.."/"..#logs.."] "..heading end

  local exitname = finTypes[category.type]
  if category.section ~= -1 then exitname = exitname.." @"..category.section end

  textplusPBPrint(heading,  8, 2 + offset*5)
  if not episodeMode then
    textplusPBPrint(getSMBXVersionString(selection.smbxversion), 8, 3)
  end
  textplusPBPrint(selection.date, 8, 4 + offset*4)
  textplusPBPrint(exitname,       8, 5 + offset*4)

  for k, v in ipairs({"powerup", "mult", "starcoin"}) do
    local sourceX, sourceY = 16*(k - 1), 0
    if category[v] then sourceY = 16 end
    Graphics.draw{type = RTYPE_IMAGE, x = 8 + 18*(k - 1), y = 8 + 26*(6 + offset*4), priority = 9.99, image = iCategories, sourceX = sourceX, sourceY = sourceY, sourceWidth = 16, sourceHeight = 16}
  end

  textplusPBPrint(formatTime(selection.time).."  ["..selection.time.."]",       8, 7 + offset*4)
  textplusPBPrint("Attempts:"..selection.attempts,                              8, 8 + offset*4)

  for k, pstate in ipairs(selection.startstate) do
    textplusPBPrint(getCharName(pstate.character).."\n"..getCostumeName(pstate.costume).."\n"..getPowName(pstate.powerup).."\n"..getMountName(pstate.mount, pstate.mountcolor).."\n"..getBoxName(pstate.reserveBox).."\n"..pstate.health, 36 + (k - 1)*300, 9 + offset*4)
    for i = 1, 6 do
      Graphics.draw{type = RTYPE_IMAGE, x = 16 + (k - 1)*300, y = 8 + 26*(9 + offset*4) + 18*(i - 1), priority = 9.99, image = iStat, sourceX = 16*(i - 1), sourceY = 0, sourceWidth = 16, sourceHeight = 16}
    end
  end
end

-- Render for PBs menu
local logdraw = function(subdata)
  local starSX = 0
  if not actice then starSX = 32 end
  Graphics.draw{type = RTYPE_IMAGE, x = 8, y = 8, priority = 9.99, image = iFavorite, sourceX = starSX, sourceWidth = 32}

  for k, v in ipairs(PBModes) do
    if k == subdata.mode then
      textplusPBPrint(">"..v.."<", 108 + (k - 1)*200, 0)
    else
      textplusPBPrint(" "..v.." ", 108 + (k - 1)*200, 0)
    end
  end

  if #levelstat == 0 then
    textplusPBPrint("No Records Found!", 8, 2)
    return
  end

  renderLevelStats(levelstat, subdata.suboption)

end


local function epitick(subdata)
  local input = menu.input
  local runs = worldstat.runs
  if input.select.time == 1 or (input.select.time > 20 and input.select.time % 15 == 0) then
    subdata.mode = subdata.mode + 1
    if subdata.mode == 4 then subdata.mode = 1 end
    SFX.play(menu.aScroll)
  end
  if input.left.time == 1 or (input.left.time > 20 and input.left.time % 15 == 0) then
		subdata.suboptionx = subdata.suboptionx - 1
    SFX.play(menu.aScroll)
	elseif input.right.time == 1 or (input.right.time > 20 and input.right.time % 15 == 0) then
		subdata.suboptionx = subdata.suboptionx + 1
    SFX.play(menu.aScroll)
	end
	if subdata.suboptionx <= 0 then
		subdata.suboptionx = math.max(1, #runs + 1)
	elseif subdata.suboptionx > #runs + 1 then
		subdata.suboptionx = 1
	end

	if input.up.time == 1 or (input.up.time > 20 and input.up.time % 15 == 0) then
		subdata.suboptiony = subdata.suboptiony - 1
    SFX.play(menu.aScroll)
	elseif input.down.time == 1 or (input.down.time > 20 and input.down.time % 15 == 0) then
		subdata.suboptiony = subdata.suboptiony + 1
    SFX.play(menu.aScroll)
	end
	local run
	if subdata.suboptionx == 1 then
		run = worldstat.best
	else
		run = worldstat.runs[subdata.suboptionx - 1]
	end
	if not run then return end
	if subdata.suboptiony <= 0 then
		subdata.suboptiony = math.max(1, #run.log)
	elseif subdata.suboptiony > #run.log then
		subdata.suboptiony = 1
	end
end

local function epidraw(subdata)
  local starSX = 0
  if not actice then starSX = 32 end
  Graphics.draw{type = RTYPE_IMAGE, x = 8, y = 8, priority = 9.99, image = iFavorite, sourceX = starSX, sourceWidth = 32}

  for k, v in ipairs(PBModes) do
    if k == subdata.mode then
      textplusPBPrint(">"..v.."<", 108 + (k - 1)*200, 0)
    else
      textplusPBPrint(" "..v.." ", 108 + (k - 1)*200, 0)
    end
  end

	local run
	if subdata.suboptionx == 1 then
		run = worldstat.best
		if not run then
      textplusPBPrint("No Records Found!", 8, 2)
			return
		end
	else
		run = worldstat.runs[subdata.suboptionx - 1]
	end

  local selection = run.log[subdata.suboptiony]

  local heading = run.episodeName
  if #worldstat.runs > 1 then heading = "("..subdata.suboptionx.."/"..#worldstat.runs..") "..heading  end
  textplusPBPrint(heading,  8, 2)
  textplusPBPrint(getSMBXVersionString(run.smbxversion), 8 , 3)
  textplusPBPrint(run.date, 8, 4)
  textplusPBPrint(formatTime(run.time).."  ["..run.time.."]",       8, 5)

  renderLevelStats(run.log, subdata.suboptiony, true)
end
local function sectionsplittable(max)
	local t = {"HIDE"}
	for i = 1, max do table.insert(t, tostring(i)) end
	return t
end

local function resetGame()
  menu.toggle()
  GameData._speeddata = nil
  Misc.exitGame()
end

-- Register the menu
menu.register{name = "Check Episode PB", type = "submenu", subdata = {suboptionx = 1, suboptiony = 1, mode = 1,}, input = epitick, render = epidraw, levelBanned = true}
if not isOverworld then
  menu.register{name = "Check Level PB", type = "submenu", subdata = {suboption = 1, mode = 1}, input = logtick, render = logdraw}
end

menu.register{name = "Timer Mode", type = "list", var = "timerMode", list = {"Clock", "Frame", "Clock + Frame"}}
menu.register{name = "Timer Size", type = "list", var = "timerSize", list = {"SMALL", "MEDIUM", "LARGE"}}

menu.register{name = "Position Timer", type = "list", var = "timerPosition", list = {"HIDE", "LEFT", "CENTER", "RIGHT"}}
menu.register{name = "Position Inputs", type = "list", var = "inputPosition", list = {"HIDE", "LEFT", "CENTER", "RIGHT"}}
menu.register{name = "Position Attempts", type = "list", var = "attemptsPosition", list = {"HIDE", "LEFT", "CENTER", "RIGHT"}}

if not isOverworld then
  menu.register{name = "Show Section Split", type = "list", var = "sectionsplit", list = sectionsplittable(#levelstat)}
end

menu.register{name = "Transparent", type = "toggle", var = "transperent"}
menu.register{name = "Enable Popout", type = "toggle", var = "popout", episodeBanned = true}
menu.register{name = "Print Log", type = "toggle", var = "printlog"}
menu.register{name = "Disable Checkpoints", type = "toggle", var = "disableChecks", episodeBanned = true}
menu.register{name = "Enable Savestate HotKeys", type = "toggle", var = "enablesavestate", episodeBanned = true}
menu.register{name = "Reset Episode", type = "func", func = resetGame, levelBanned = true}
menu.register{name = "Enable Extra Advantage Start Features", type = "toggle", var = "enableas", episodeBanned = true}
menu.register{name = "[AS] P1 Costume", type = "list", var = "asCostume1", list = costumelist, episodeBanned = true}
menu.register{name = "[AS] P2 Costume", type = "list", var = "asCostume2", list = costumelist, episodeBanned = true}
menu.register{name = "[AS] P1 Reserve Box", type = "numpad", var = "asBox1", min = 0, max = NPC_MAX_ID, episodeBanned = true}
menu.register{name = "[AS] P2 Reserve Box", type = "numpad", var = "asBox2", min = 0, max = NPC_MAX_ID, episodeBanned = true}
menu.register{name = "[AS] P1 Health", type = "list", var = "asHealth1", list = {"1", "2", "3"}, episodeBanned = true}
menu.register{name = "[AS] P2 Health", type = "list", var = "asHealth2", list = {"1", "2", "3"}, episodeBanned = true}

-- Check if the episode or level has a custom finish
local file = io.open(Misc.episodePath().."speedrun_custom_ending.lua", "r") -- r read mode
if file and not isOverworld then
  file:close()
	customFinish = require("speedrun_custom_ending")
  if type(customFinish) == "string" then
    customFinish = {[Level.filename()] = customFinish}
  end
end

-- Checks if a player has an "advantage" (not small default)
local hasHealth = {[CHARACTER_PEACH] = true, [CHARACTER_TOAD] = true, [CHARACTER_LINK] = true, [CHARACTER_KLONOA] = true, [CHARACTER_ROSALINA] = true}
local function checkadvantage(p)
  return playerManager.getCostume(p.character) or p.powerup ~= 1 or p.mount ~= 0 or (hasHealth[p.character] and p:mem(0x16,	FIELD_WORD) ~= 1) or (not hasHealth[p.character] and p.reservePowerup ~= 0)
end

-- Checks if the table share the same values
local function sameTable(t1, t2)
  for k, v in pairs(t1) do
    if v ~= t2[k] then
      return false
    end
  end
  return true
end

local function parseElem(v, form, size)
  local sizeDiff = size - #tostring(v)
	if form == 'type' then
		v = string.rep(" ", sizeDiff)..v..":"
	elseif form == 'value' then
		v = string.rep(" ", sizeDiff)..tostring(v)
	elseif form == 'percentage' then
		v = "%"..string.rep(" ", sizeDiff)..tostring(v)
	elseif form == 'timeFrame' then
		v = "["..string.rep(" ", sizeDiff)..tostring(v).."]"
	elseif form == 'timeClock' then
		v = string.rep(" ", sizeDiff)..v
	end
	return v
end

-- Helper to make lists look nice
local function generateList(header, anatomy, list)
	local sizes = {}
	for k, v in ipairs(list) do
		for p, q in ipairs(v) do
			sizes[p] = math.max(sizes[p] or 0, #tostring(q))
		end
	end

	local s = header..":\n"
	for k, v in ipairs(list) do
		s = s.."  * "
		for p, q in ipairs(v) do
			s = s..parseElem(q, anatomy[p], sizes[p]).." "
		end
		s = s.."\n"
	end

	return s
end

local function displayPopout(finType, exitSection)
	local title = "SPEEDRUNNER POPOUT - LEVEL COMPLETE"
	if levelWinTimeDiff then
		if levelWinTimeDiff < 0 then
			title = "SPEEDRUNNER POPOUT - NEW BEST"
		elseif levelWinTimeDiff > 0 then
			title = "SPEEDRUNNER POPOUT - BETTER LUCK NEXT TIME"
		else
			title = "SPEEDRUNNER POPOUT - TIED UP THE LEVEL"
		end
	end


	local txt = "=== "..Level.name().." ===\n"
	txt = txt.."SMBX Version: "..getSMBXVersionString(SMBX_VERSION).."\n"
	txt = txt.."Timestamp: "..os.date().."\n"
	txt = txt.."Exit Type: "..finTypes[finType].."   @"..exitSection.."\n"
	txt = txt.."\n"
	txt = txt.."Time: "..formatTime(speeddata.timer).."  ["..speeddata.timer.."]\n"
	if levelWinTimeDiff then
		local sign = signSym(levelWinTimeDiff)
		txt = txt.."Best: "..formatTime(speeddata.timer - levelWinTimeDiff).."  ["..(speeddata.timer - levelWinTimeDiff).."]\n"
		txt = txt.."Time Difference of: "..sign..formatTime(levelWinTimeDiff).." ["..sign..math.abs(levelWinTimeDiff).."]\n"
	end
	txt = txt.."\n"
	txt = txt.."\n"
	txt = txt..generateList("CATEGORIES", {'type', 'value'},
	  {{"Advatage Start", catPowerup},
		 {"Multiplayer", catMult},
		 {"Starcoins", catStarcoins}})

	txt = txt.."\n"
	txt = txt.."\n"

	for k, pstate in ipairs(speeddata.startState) do
		txt = txt..generateList("PLAYER "..k, {'type', 'value'},
		{{"Character", getCharName(pstate.character)},
		 {"Costume", getCostumeName(pstate.costume)},
		 {"Powerup", getPowName(pstate.powerup)},
		 {"Mount", getMountName(pstate.mount, pstate.mountcolor)},
		 {"Health", pstate.health}})

		 txt = txt.."\n"
		 txt = txt.."\n"
	end


	local sectionData = {}
	for k, v in pairs(logger.sectionsplit) do
		table.insert(sectionData, {v.id, formatTime(v.time), v.time, math.floor(v.time/speeddata.timer*10000)/100})
	end
	txt = txt..generateList("SECTION", {'type', 'timeClock', 'timeFrame', 'percentage'}, sectionData)

	txt = txt.."\n"
	txt = txt.."\n"

	local inputData = {}
	for k, v in pairs(logger.inputs) do
		table.insert(inputData, {k, formatTime(v), v, math.floor(v/speeddata.timer*10000)/100})
	end
	txt = txt..generateList("INPUTS", {'type', 'timeClock', 'timeFrame', 'percentage'}, inputData)

	txt = txt.."\n"
	txt = txt.."\n"
	local forcedStateData = {}
	for k, v in pairs(logger.forcedState) do
		table.insert(forcedStateData, {forcedTypes[k], "["..k.."]:", formatTime(v), v, math.floor(v/speeddata.timer*10000)/100})
	end
	txt = txt..generateList("FORCED STATE", {'type', 'value', 'timeClock', 'timeFrame', 'percentage'}, forcedStateData)

	txt = txt.."\n"
	txt = txt.."\n"

	txt = txt..generateList("MISC", {'type', 'timeClock', 'timeFrame', 'percentage'},
		{{"Touching Ground", formatTime(logger.onground), logger.onground, math.floor(logger.onground/speeddata.timer*10000)/100},
		 {"Sliding", formatTime(logger.sliding), logger.sliding, math.floor(logger.sliding/speeddata.timer*10000)/100},
		 {"Spin Jumping", formatTime(logger.spinjump), logger.spinjump, math.floor(logger.spinjump/speeddata.timer*10000)/100}})


  if settings.printlog then
		time = os.date("*t")
		local writefile = io.open(Misc.episodePath().."SPEEDLOG "..time.year.."-"..time.month.."-"..time.day.." - "..time.hour .."-".. time.min .."-".. time.sec.." "..string.match(Level.filename(), "(.+)%..+$")..".txt", "w")
		if not writefile then return end

		writefile:write(txt)
		writefile:close()
	end
	if settings.popout and not inEpisode then
		Misc.showRichDialog(title, txt, true)
	end
end


local function timeFinish(finType, finSec)
  finSec = finSec or -1

	-- Create run object
	local category = {type = finType, section = finSec, powerup = catPowerup, mult = catMult, starcoin = catStarcoins}
	local newLevelRun = {diff = levelWinTimeDiff, category = category, time = speeddata.timer, sectionsplit = logger.sectionsplit, date = os.date(), attempts = speeddata.attempt, smbxversion = SMBX_VERSION, startstate = speeddata.startState, levelName = Level.name(), episodeName = episodeName}

	-- Check if there is a run stored of the same category
	local oldLevelRun, oldLevelRunKey
	for k, v in ipairs(levelstat) do
		if sameTable(category, v.category) then
			oldLevelRunKey, oldLevelRun = k, v
			break
		end
	end
	-- If a run of the same category exists, then get the diff. time
	if oldLevelRun then levelWinTimeDiff = newLevelRun.time - oldLevelRun.time newLevelRun.diff = levelWinTimeDiff end

  hasLevelWon = true
  if finType == -1 or finType == LEVEL_END_STATE_GAMEEND then
    hasEpisodeWon = true
  end

  -- Show log
  displayPopout(finType, finSec)

  -- Save the run if its a new best time!
  if not oldLevelRun then
    table.insert(levelstat, newLevelRun)
  elseif newLevelRun.time < oldLevelRun.time then
		prevBestRun = oldLevelRun
		levelstat[oldLevelRunKey] = newLevelRun
	end
  levelstatLib.save()

  if inEpisode then
    -- When playing in an episode, log the level to the episode data
    table.insert(speeddata.log, newLevelRun)

    -- When the episode is beaten
    if hasEpisodeWon then
      local newEpisodeRun = {time = speeddata.etimer, date = os.date(), smbxversion = SMBX_VERSION, episodeName = episodeName, log = speeddata.log}
      local oldEpisodeRun = worldstat.best

      -- Get the time diff for an episode run
      if oldEpisodeRun then
        episodeWinTimeDiff = newEpisodeRun.time - oldEpisodeRun.time
      end

      -- Save the run if its a new best time!
      if not oldEpisodeRun or newEpisodeRun.time < oldEpisodeRun.time then
        worldstat.best = newEpisodeRun
      end

      -- Save the run into the run history
      table.insert(worldstat.runs, 1, newEpisodeRun)
      worldstat.runs[51] = nil -- Only save the latest 50 runs
      worldstatLib.save()
    end
  end
end



function lib.onStart()
	-- Keep track amount of attempts in the run
	speeddata.attempt = speeddata.attempt + 1

  -- Advantage start features the editor is missing
	if settings.enableas then
		-- Costume
		playerManager.setCostume(player.character, costumelist[settings.asCostume1])
		if player2 then playerManager.setCostume(player2.character, costumelist[settings.asCostume2]) end
    -- Reserve Box
		player.reservePowerup = settings.asBox1
		if player2 then player2.reservePowerup = settings.asBox2 end

    -- Health
		player:mem(0x16, FIELD_WORD, settings.asHealth1)
		if player2 then player2:mem(0x16,	FIELD_WORD, settings.asHealth2) end
	end

	-- Detect if the player begins with any powerups, monuts, etc
	catPowerup = checkadvantage(player)

  -- Detect if the level is being played in multiplayer
	if player2 then
		catMult = true
		if not catPowerup then catPowerup = checkadvantage(player2) end
	end

	-- Store initial player data
	-- character, costume, powerup, mount, reserveBox, health
	if not speeddata.startState[1] then
		local startState = speeddata.startState
    for k, p in ipairs(pList) do
			startState[k] = {
				character = p.character,
				costume = playerManager.getCostume(p.character),
				powerup = p.powerup,
				mount = p.mount,
				mountcolor = p.mountColor,
				reserveBox = p.reservePowerup,
				health = p:mem(0x16, FIELD_WORD)
			}
    end
	end

  -- Display the starting time for a bit as a fix tracking time when playing in an episode
  local startingTime = speeddata.timer
  if inEpisode then
    Routine.run(function()
      for i = 1, 30 do
        textplus.print{text = formatTime(startingTime).." ["..startingTime.."]", x = 8, y = 8, priority = 9.99, font = textfont}
        Routine.skip()
      end
    end)
  end
end

function lib.onTick()
	-- Check for inputs
	if settings.enablesavestate and not inEpisode then
		if menu.input.savestate.state == KEYS_PRESSED then
			SFX.play(menu.aSelect)
			savest = savestate.save()
			notif = {text = "Savestate Saved", timer = 0}
		elseif menu.input.loadstate.state == KEYS_PRESSED and savest then
			SFX.play(menu.aClose)
			savestate.load(savest)
			notif = {text = "Savestate Loaded", timer = 0}
		end
	end

	-- Log data for the logger
  for k, v in pairs(player.keys) do
    if v then
			logger.inputs[k] = logger.inputs[k] + 1
		end
	end

	if player.forcedState ~= 0 then
		logger.forcedState[player.forcedState] = (logger.forcedState[player.forcedState] or 0) + 1
	end

	if player:isGroundTouching() then
	  logger.onground = logger.onground + 1
	end

	if player:mem(0x3C, FIELD_BOOL) then -- is Sliding
		logger.sliding = logger.sliding + 1
	end

	if player:mem(0x50, FIELD_BOOL) then -- is Spinjumping
		logger.spinjump = logger.spinjump + 1
	end
end

function lib.onWorldDraw()
  speeddata.etimer = speeddata.etimer + 1
	lib.onCameraDraw(1)
end

function lib.onLevelDraw()
	-- Detection when the level has been finished
	if Level.winState() ~= 0 and not hasLevelWon then
    timeFinish(Level.winState(), player.section)
	end

	-- Count the level timer
  if not hasLevelWon then
		speeddata.timer = speeddata.timer + 1

    -- Section logger!
		if logger.prevSection ~= player.section then
			table.insert(logger.sectionsplit, {id = player.section, time = 0})
		end
		logger.sectionsplit[#logger.sectionsplit] = logger.sectionsplit[#logger.sectionsplit] or {id = player.section, time = 0}
		logger.sectionsplit[#logger.sectionsplit].time = logger.sectionsplit[#logger.sectionsplit].time + 1
		logger.prevSection = player.section
  end

  -- Count the episode timer
  if inEpisode and not hasEpisodeWon then
    speeddata.etimer = speeddata.etimer + 1
  end

  -- Fix to force exit by warp be detected
	for k, p in ipairs(Player.get()) do
		if p.prevWarp and p.prevWarp > 0 and p:mem(0x122, FIELD_WORD) > 0 then
			local warp = Warp.get()[p.prevWarp]
			if warp and (warp.toOtherLevel or warp.levelFilename ~= "") then
				forceExitWarp = k
			end
		end
		p.prevWarp = p:mem(0x5A, FIELD_WORD)
	end

end

local function formatOut(n)
	if settings.timerMode == 1 then
		return formatTime(n)
	elseif settings.timerMode == 2 then
		return tostring(n)
	elseif settings.timerMode == 3 then
		return formatTime(n).." ["..n.."]"
	end
end

local function formatFin(obj, diff)
	local sym = signSym(diff)

	if diff < 0 then
		obj.text = "<color rainbow>"..obj.text.."</color>"
	elseif diff > 0 then
		obj.color = Color.red*obj.color.a
	else
		obj.color = Color.gray*obj.color.a
	end

	obj.text = obj.text.." <color "..tostring(Color.white*obj.color.a)..">"..sym..formatOut(diff).."</color>"
end

local pos = {vector(0, 8, 9, 8), vector(8, 0, 8, 9), vector(8, 15, 8, 9), vector(15, 8, 9, 8), vector(32, 14, 8, 8), vector(39, 8, 8, 8), vector(25, 7, 8, 8), vector(32, 0, 8, 8), vector(16, 17, 8, 6), vector(24, 17, 8, 6)}
local function renderInputs(p, x, y)
  local opacity = 1
  if settings.transperent then opacity = 0.5 end
  Graphics.draw{image = iInputs, type = RTYPE_IMAGE, sourceWidth = 48, x = x, y = y, priority = 9.9, opacity = opacity, priority = 9.99}
	for k, v in ipairs(keyname) do
    if p.rawKeys[v] then
      local sourceX = pos[k].x
      local sourceY = pos[k].y
      Graphics.draw{image = iInputs, type = RTYPE_IMAGE, sourceX = sourceX + 48, sourceY = sourceY, sourceWidth = pos[k].z, sourceHeight = pos[k].w, x = x + sourceX, y = y + sourceY, priority = 9.9, priority = 9.99}
    end
	end
end


-- Draw the timer and inputs and attempts and section split
function lib.onCameraDraw(idx)
	-- These are the objects that will be printed onscreen
	local opacity = 1
	local timerObj = {x = timerX[settings.timerPosition], pivot = timerPivot[settings.timerPosition], priority = 9.99, font = textfont, xscale = timerSize[settings.timerSize], yscale = timerSize[settings.timerSize], color = Color.white, height = timerSize[settings.timerSize]*12}
  local attemptObj = {text = "#"..speeddata.attempt, x = timerX[settings.attemptsPosition], pivot = timerPivot[settings.attemptsPosition], priority = 9.99, font = textfont, xscale = 2, yscale = 2, color = Color.white, height = 16}
  local inputObj = {x = inputX[settings.inputPosition], height = 24}

  -- Change position if there is splitscreen
	if camera.width == 400 then
		timerObj.x = timerXSplit[settings.timerPosition]
		attemptObj.x = timerXSplit[settings.attemptsPosition]
		inputObj.x = inputXSplit[settings.inputPosition]
	end

	-- Print the text depending on the format needed
	timerObj.text = formatOut(speeddata.timer)

  -- Make text transperent
	if settings.transperent then
		opacity = 0.5
	end

	if inEpisode then
		timerObj.height = timerObj.height*2
	end

	if camera.width == 800 and camera.height == 600 and player2 then
		inputObj.height = inputObj.height*2
	end

	-- Change the y position if multiple objects overlap
	--[[
	    * attempt
			* input
			* time (level)
			* time (episode)
	--]]

	timerObj.y = 592

	if settings.timerPosition > 1 and settings.timerPosition == settings.inputPosition then
		inputObj.y = timerObj.y - timerObj.height
	else
		inputObj.y = 592
	end

	if settings.inputPosition > 1 and settings.inputPosition == settings.attemptsPosition then
		attemptObj.y = inputObj.y - inputObj.height - 4
	elseif settings.timerPosition > 1 and settings.timerPosition == settings.attemptsPosition then
		attemptObj.y = timerObj.y - timerObj.height
	else
		attemptObj.y = 592
	end

	if camera.height == 300 then
		attemptObj.y = attemptObj.y - 300
		inputObj.y = inputObj.y - 300
		timerObj.y = timerObj.y - 300
	end

	-- Print inputs
	if settings.inputPosition > 1 then
		if camera.width == 800 and camera.height == 600 and player2 then
			renderInputs(player, inputObj.x, inputObj.y - inputObj.height - 4)
			renderInputs(player2, inputObj.x, inputObj.y - inputObj.height*0.5)
		else
			renderInputs(pList[idx], inputObj.x, inputObj.y - inputObj.height)
		end
	end

	-- Print attempts
	if settings.attemptsPosition > 1 then
		attemptObj.color = attemptObj.color*opacity
		textplus.print(attemptObj)
	end

	-- Print timer (level and episode)
	if settings.timerPosition > 1 and timerObj.text then
    timerObj.color = timerObj.color*opacity

		if inEpisode then
      local etimerObj = table.clone(timerObj)
			timerObj.y = timerObj.y - etimerObj.height*0.5
			etimerObj.text = formatOut(speeddata.etimer)

			if hasEpisodeWon and episodeWinTimeDiff then
				formatFin(etimerObj, episodeWinTimeDiff, opacity)
			end

			textplus.print(etimerObj)
		end

    if hasLevelWon and levelWinTimeDiff then
      formatFin(timerObj, levelWinTimeDiff, opacity)
    end

    textplus.print(timerObj)
	end

	-- Print the category when the level is finished
	if hasLevelWon then
		for k, v in ipairs({catPowerup, catMult, catStarcoins}) do
			local xs, ys = 16*(k - 1), 0
			if v then ys = 16 end
			Graphics.draw{type = RTYPE_IMAGE, x = 16 + 18*(k - 1) - 4, y = 8 + 4, priority = 9.99, image = iCategories, sourceX = xs, sourceY = ys, sourceWidth = 16, sourceHeight = 16}
		end
	end

	-- Print the notification
	if notif.timer >= 0 then
		notif.timer = notif.timer + 1
		local off = 0
		if notif.timer < 10 then
			off = 32*math.sin(notif.timer*0.3)
		elseif notif.timer > 120 then
			notif.timer = -1
		end
		textplus.print{text = notif.text, x = 760  + off, y = 8, pivot = {1, 0}, priority = 9.99, font = textfont, xscale = 2, yscale = 2, plaintext = true, color = Color.red*opacity}
	end

	-- The splitter changes if in a world map
	if isOverworld then
    -- Print the episode log
		if settings.timerPosition > 1 and #speeddata.log > 0 then
			for i = 1, math.min(#speeddata.log, 10) do
				local v = speeddata.log[i]
				local s = formatTime(v.time)
				local d = formatTime(math.abs(v.diff or 0))
        local c = Color.white*opacity
				if v.diff and v.diff > 0 then d = "<color "..tostring(Color.red*opacity)..">+"..d.."</color>"
				elseif v.diff and v.diff < 0 then d = "<color rainbow>-"..d.."</color>"
				else d = " "..d end
				textplus.print{text = s.." "..d, x = 792, y = 8 + 10*i, pivot = {1, 0}, priority = 9.99, font = textfont, xscale = 1, yscale = 1, color = c}
			end
		end
	else
		-- Print the section splitter
		if settings.sectionsplit > 0 then
			local selectedRun = levelstat[settings.sectionsplit - 1]
			if not selectedRun then
				settings.sectionsplit = 1
				return
			end

			local selectedCat = selectedRun.category
			local secList = selectedRun.sectionsplit
			if prevBestRun then
				secList = prevBestRun.sectionsplit
			end

			-- Print exit name type and section
			local exitname = finTypes[selectedCat.type]
			if selectedCat.section ~= -1 then exitname = exitname.." @"..selectedCat.section end
			textplus.print{text = exitname, x = 800 - 8, y = 8, pivot = {1, 0}, priority = 9.99, font = textfont, color = Color.white*opacity}

			-- Print category icons
			for k, v in ipairs({"powerup", "mult", "starcoin"}) do
				local sourceX, sourceY = 16*(k - 1), 0
				if selectedCat[v] then sourceY = 16 end
				Graphics.draw{type = RTYPE_IMAGE, x = 800 - 6  - (3 - k + 1)*18, y = 8 + 10, priority = 9.99, image = iCategories, sourceX = sourceX, sourceY = sourceY, sourceWidth = 16, sourceHeight = 16, opacity = opacity}
			end

			-- Print timers
			for k, v in ipairs(secList) do
				local t = formatTime(v.time)
				local splitColor = Color.white
				if logger.sectionsplit[k] and logger.sectionsplit[k].id == v.id then
					local d = logger.sectionsplit[k].time - v.time
					t = signSym(d)..formatTime(d)
					if d < 0 then t = "<color rainbow>"..t.."</color>"
					elseif d > 0 then splitColor = Color.red
					else splitColor = Color.gray end
				end
        splitColor = splitColor*opacity

				textplus.print{text = t, x = 800 - 8, y = 8 + 18+10 + 8 + (k - 1)*10, pivot = {1, 0}, priority = 9.99, font = textfont, color = splitColor}
			end
		end
	end
end

function lib.onExitLevel(type)
  -- Fix for exit by warp
  if forceExitWarp ~= 0 then type = LEVEL_WIN_TYPE_WARP end

	if type ~= 0 then
    if not hasLevelWon then
      -- Detection when the level has been finished (for win types not accounted by Level.winState())
      hasLevelWon = true
      if type == LEVEL_WIN_TYPE_OFFSCREEN then
        timeFinish(8, player.section)
      elseif type == LEVEL_WIN_TYPE_WARP then
        timeFinish(9, player.section)
      end
    end
  end

  -- This means the level was "beat"
  if hasLevelWon then
		speeddata.logger = nil
    speeddata.timer = nil
    speeddata.starcoin = nil
    speeddata.attempt = nil
    speeddata.startState = nil
  end

  -- This means the episide was "beat"
  if hasEpisodeWon then
    speeddata.etimer = nil
    speeddata.log = nil
  end

	-- If checkpoints are disabled, force the level to reload as if it was loaded for the first time
	if settings.disableChecks and not inEpisode then
    Checkpoint.reset()
    mem(0x00B250B0, FIELD_STRING, "") -- Clear vanilla checkpoint
		mem(0x00B2C5A8,	FIELD_WORD, 0)	-- Clear coins
		mem(0x00B2C8E4,	FIELD_DWORD, 0) -- Clear score
		SaveData.clear()
		Misc.saveGame()
  end
end

-- For when the episode has a custom end game
function lib.onEvent(eventname)
  if customFinish[Level.filename()] == eventname then
    timeFinish(-1, player.section)
	end
end

Misc.cheatBuffer("SMBXSPEEDRUNNER")
function lib.onInputUpdate()
  if Misc.cheatBuffer() == "" then
		SFX.play(menu.aScroll)
    Misc.cheatBuffer("SPEEDRUNNER")
    notif = {text = "CHEAT DETECTED", timer = 0}
  end
end


function lib.onInitAPI()
	if not isOverworld then
		registerEvent(lib, "onStart", "onStart")
		registerEvent(lib, "onEvent", "onEvent")
		registerEvent(lib, "onInputUpdate", "onInputUpdate")
		registerEvent(lib, "onTick", "onTick")
		registerEvent(lib, "onExitLevel", "onExitLevel")
		registerEvent(lib, "onCameraDraw", "onCameraDraw")
	end

	if isOverworld then
		registerEvent(lib, "onDraw", "onWorldDraw")
	else
		registerEvent(lib, "onDraw", "onLevelDraw")
	end
end

return lib
