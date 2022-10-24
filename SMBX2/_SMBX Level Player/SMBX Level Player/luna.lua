-- NOTE: this code is very messy and the code is pretty much wrapped with scotch tape. Dont look until I make the code look pretty

if Misc.inEditor() then
  Misc.showRichDialog("SMBX Level Player", "Hello!\n\nYou are trying to access the level player through the editor. The level player is meant to\nbe played as an episode.\nYou cannot load levels while in the edtior so there is not much you can do here.\n\nPlease open the level player as an episode in the launcher :)", true)
end

local t = string.split(Misc.getFullPath(Level.filename()), "\\")
GameData.SMBXLP_foldername = t[#t - 1]
GameData.SMBXLP_leveldir = getSMBXPath().."/worlds/"..GameData.SMBXLP_foldername.."/SMBXLP_SMBX Level Player.lvl"
GameData.SMBXLP_dir = getSMBXPath().."\\worlds\\"..GameData.SMBXLP_foldername.."\\SMBXLP\\"
GameData.SMBXLP_activated = false
GameData.SMBXLP_firstload = GameData.SMBXLP_notfirstload or false

local SMBXLP = require(getSMBXPath().."\\worlds\\"..GameData.SMBXLP_foldername.."\\SMBXLP.lua")

local textplus = require("textplus")
local keys = require("SMBXLP/keys")
local menugen = require("menugenerator")
local eventu = require("eventu")
local click = require("click")
local pnpc = require("pnpc")
local rng = require("rng")

function string.endswith(String,End)
  return End == '' or string.sub(String, -string.len(End)) == End
end

click.loadCursor{{nil, 9.999}}
click.setCursorID(1)

local FILE_FOLDER = 1
local FILE_LEVEL = 2
local firstload = not GameData.SMBXLP_notfirstload
GameData.SMBXLP_notfirstload = true

local menu = {}
menu.offsethist = {}
menu.logox = -800
menu.isHelp = false
menu.playerinput = player
menu.introFrozen = true
menu.validclick = true
menu.logo = Graphics.loadImage(Misc.resolveFile("logo.png"))
menu.help = Graphics.loadImage(Misc.resolveFile("help.png"))
menu.sign = Graphics.loadImage(Misc.resolveFile("sign.png"))
menu.sfx_select = Audio.SfxOpen(Misc.resolveFile("select.wav"))
menu.sfx_back = Audio.SfxOpen(Misc.resolveFile("back.wav"))
menu.sfx_rng = Audio.SfxOpen(Misc.resolveFile("rand.wav"))
menu.sfx_load = Audio.SfxOpen(Misc.resolveFile("open.wav"))
menu.img = Graphics.loadImage(Misc.resolveFile("box.png"))
menu.font = textplus.loadFont("textplus/font/6.ini")
menu.coroutineloading = false
menu.loadingtimer = 0

menu.x, menu.y, menu.z = 76, 78, -80
menu.mx = function(x) return x + menu.x end
menu.my = function(y) return y + menu.y end
menu.mz = function(z) return z + menu.z  end

local filedata = {}
local filelist = menugen.create{
  list = filedata,
  textscale = 2,
  textspacing = 20,
  width = menu.img.width,
  height = menu.img.height,
  font = menu.font,
  maxlines = 17
}

local load_level = ""
local load_episode = ""

local shaketimer = 0
local prevsong = ""
local musicprevpos = 0

local printplus = function(text, x, y, z, color, pivot)
  textplus.print{text = text, x = x, y = y, priority = z, xscale = 2, yscale = 2, color = color, font = menu.font, plaintext = true, pivot = pivot}
end

local fixplayer2 = function()
  if player2 then
    player2.x = -179926 - 0.5*player2.width
  end
end

local function loadlevel(filename, episodename)
  Level.load(filename, episodename)
  -- local EP_LIST_COUNT = mem(0x00B250E8, FIELD_WORD)
  -- local EP_LIST_PTR = mem(0x00B250FC, FIELD_DWORD)
  -- local hasFound = false
  -- for indexer = 1, EP_LIST_COUNT do
  --   local name = tostring(mem(EP_LIST_PTR + (indexer - 1) * 0x18 + 0x4, FIELD_STRING))
  --   if name == episodename then
  --     episodeindex = indexer
  --     hasFound = true
  --     break
  --   end
  -- end
  -- if hasFound then
  --   mem(0x00B25720, FIELD_STRING, filename) -- GM_NEXT_LEVEL_FILENAME
  --   mem(0x00B2C628, FIELD_WORD, episodeindex) -- Index of the episode
  -- else
  --   Misc.dialog("Episode of name '" ..episodename.."' could not be found. Aborting.")
  --   return
  -- end
  --
  -- mem(0x00B250B4, FIELD_WORD, 0)  -- GM_IS_EDITOR_TESTING_NON_FULLSCREEN
  -- mem(0x00B25134, FIELD_WORD, 0)  -- GM_ISLEVELEDITORMODE
  -- mem(0x00B2C89C, FIELD_WORD, 0)  -- GM_CREDITS_MODE
  -- mem(0x00B2C620, FIELD_WORD, 0)  -- GM_INTRO_MODE
  -- mem(0x00B2C5B4, FIELD_WORD, -1) -- GM_EPISODE_MODE (set to leave level)
end

local randomsong = function()
  local files = Misc.listLocalFiles("../Music/")
  local musicfiles = {}
  for i = 1, #files do
    if string.endswith(files[i], ".mp3") or string.endswith(files[i], ".ogg") then
      table.insert(musicfiles, files[i])
    end
  end
  if #musicfiles ~= 0 then
    local songname
    if #musicfiles == 1 then
      songname = musicfiles[1]
    else
      songname = SMBXLP.menu.betterrng(musicfiles, prevsong)
    end
    Audio.MusicOpen(Misc.resolveFile("../Music/"..songname))
    Audio.MusicPlay()
    eventu.setFrameTimer(1, function() printplus("Playing song: "..songname, 792, 8, 6, Color.purple, vector.v2(1, 0)) end, 300)
    prevsong = songname
  end
end

local birdsfx = Misc.resolveFile("sound/extended/birdflap.ogg")
local birdspawner = function()
  local birds = NPC.get({501, 502, 503, 504, 505, 506, 507, 508}, 1)
  if #birds < 5 then
    local isFlying = rng.random()
    if isFlying <= 0.085 then
      SFX.play(birdsfx)
      local max = rng.randomInt(4, 12)
      if rng.random() <= 0.05 then
        max = rng.randomInt(20, 40)
        if rng.random() <= 0.1 then
          SFX.play(15)
          max = rng.randomInt(80, 100)
        end
      end
      local left = Section(1).boundary.left
      for i = 1, max do
        local bird = NPC.spawn(rng.irandomEntry({505, 506, 507, 508}), left + rng.random(-16, 800), Section(1).boundary.bottom + 16, 1)
        local dist = (left + 400) - (bird.x + 8)
        if math.abs(dist) > 300 then
          bird.direction = math.sign(dist)
          bird.speedX = bird.speedX*math.sign(dist)
        else
          bird.direction = rng.irandomEntry({-1, 1})
          bird.speedX = bird.speedX*rng.irandomEntry({-1, 1})
        end
        Animation.spawn(10, bird.x - 8, bird.y - 8)
        eventu.waitFrames(rng.randomInt(2, 8))
      end
    elseif isFlying <= 0.091 then
      local left = Section(1).boundary.left
      for i = 1, rng.randomInt(1, 3) do
        local heart = NPC.spawn(rng.irandomEntry({462, 559}), left + rng.random(200, 600), Section(1).boundary.bottom + 16, 1)
        heart.friendly = true
        eventu.waitFrames(rng.randomInt(2, 8))
      end
    elseif isFlying <= 0.0925 then
      SFX.play(13)
      Layer.get("her"):show(false)
      eventu.waitFrames(150)
      Layer.get("her"):hide(false)
    elseif isFlying <= 0.1 then
      local left = Section(1).boundary.left
      local eerie = NPC.spawn(42, left + 800, camera.y + 36, 1)
      eerie.direction = -1
      eerie.friendly = true
    elseif isFlying <= 0.115 then
      local left = Section(1).boundary.left
      local bubble = NPC.spawn(283, left - 32, camera.y + 36, 1)
      bubble.ai1 = rng.randomInt(1, 500)
      bubble.direction = 1
      bubble.speedX = 3
      bubble.friendly = true
    else
      local spawner = rng.irandomEntry(NPC.get({465}, 1))
      local bird = NPC.spawn(rng.irandomEntry({501, 502, 503, 504}), spawner.x + rng.random(16), spawner.y + 16, 1)
      Animation.spawn(10, bird.x - 8, bird.y - 8)
    end
  end
end

local birdscare = function()
  for _, n in ipairs(Colliders.getColliding{a = Colliders.Circle(click.sceneX, click.sceneY, 16), b = {42, 501, 502, 503, 504}, btype = Colliders.NPC, filter = function() return true end}) do
    if n.id == 42 then
      n.id = 507
    else
      n.id = n.id + 4
    end
    n.speedY = -1
    n.dontMove = false
    n.direction = DIR_LEFT
    n.data._basegame.moveState = 3
    SFX.play(birdsfx)
  end
end

local function clickmanager()
  if click.click then
    for _, p in ipairs(Player.get()) do
      if click.box{x = p.x, y = p.y, width = p.width, height = p.height, scene = true} then
        menu.validclick = false
        SFX.play(1)
        local v = (vector.v2(p.x + p.width*0.5 - click.sceneX, p.y + p.height*0.5 - click.sceneY):normalize())
        p.speedX = 2*v.x
        p.speedY = -6*math.abs(v.y)
      end
    end

    for _, b in ipairs(Block.get(149)) do
      if click.box{x = b.x, y = b.y, width = b.width, height = b.height, scene = true} then
        menu.validclick = false
        Layer.get("livespawn"):show(false)
        eventu.setFrameTimer(280, function() Layer.get("livespawn"):hide(false) end)
      end
    end

    for _, n in ipairs(Colliders.getColliding{a = Colliders.Circle(click.sceneX, click.sceneY, 4), b = {151}, btype = Colliders.NPC, filter = function() return true end}) do
      menu.isHelp = not menu.isHelp
      SFX.play(menu.sfx_select)
      menu.validclick = false
    end
    for _, n in ipairs(Colliders.getColliding{a = Colliders.Circle(click.sceneX, click.sceneY, 4), b = {283}, btype = Colliders.NPC, filter = function() return true end}) do
      NPC.config[n.ai1].noblockcollision = true
      n.ai3 = 1
    end
  end
end

local disableinputs = function()
  for _, p in ipairs(Player.get()) do
    p.keys.jump = false
    p.keys.altJump = false
    p.keys.run = false
    p.keys.altRun = false
    p.keys.up = false
    p.keys.down = false
    p.keys.left = false
    p.keys.right = false
    p.keys.jump = false
    p.keys.dropItem = false
  end
end

function menu.updateList()
  local directories = Misc.listLocalDirectories("../../"..GameData.SMBXLP_filedir)
  local files = Misc.listLocalFiles("../../"..GameData.SMBXLP_filedir)

  filelist.list = {}
  filelist.icon = {}
  for _, v in ipairs(directories) do
    table.insert(filelist.list, v)
    table.insert(filelist.icon, FILE_FOLDER)
  end
  for _, v in ipairs(files) do
    if string.endswith(v, ".lvl") or string.endswith(v, ".lvlx") then
      table.insert(filelist.list, v)
      table.insert(filelist.icon, FILE_LEVEL)
    end
  end

  filelist.update()
end

function menu.goback()
  local t = string.split(GameData.SMBXLP_filedir, "/")
  table.remove(t)
  GameData.SMBXLP_filedir = table.concat(t, "/")
  menu.updateList()
  filelist.arrowoffset = GameData.SMBXLP_menuhist[#GameData.SMBXLP_menuhist][1]
  filelist.listoffset = GameData.SMBXLP_menuhist[#GameData.SMBXLP_menuhist][2]
  filelist.option = filelist.listoffset + filelist.arrowoffset + 1
  table.remove(GameData.SMBXLP_menuhist)
  SFX.play(menu.sfx_back)
end

function menu.activatefolder()
  GameData.SMBXLP_filedir = GameData.SMBXLP_filedir.."/"..filelist.list[filelist.option]
  table.insert(GameData.SMBXLP_menuhist, {filelist.arrowoffset, filelist.listoffset})
  filelist.arrowoffset = 0
  filelist.listoffset = 0
  menu.updateList()
  SFX.play(menu.sfx_select)
end

function menu.activatefile()
  SFX.play(menu.sfx_load)
  filelist.drawonlyoption = true
  load_level = "../"..GameData.SMBXLP_filedir.."/"..filelist.list[filelist.option]
  -- load_episode = getSMBXPath().."/worlds"..GameData.SMBXLP_filedir
  load_episode = "SMBX Level Player"
  GameData.SMBXLP_leveldir = getSMBXPath().."/worlds"..GameData.SMBXLP_filedir.."/".."SMBXLP_"..filelist.list[filelist.option]
  -- Misc.dialog(GameData.SMBXLP_leveldir)
  menu.loadingtimer = 0
  menu.coroutineloading = eventu.setFrameTimer(1, function()
    menu.loadingtimer = menu.loadingtimer + 1/65
    if menu.loadingtimer >= 1 then
      table.insert(GameData.SMBXLP_menuhist, {filelist.arrowoffset, filelist.listoffset, true})
      loadlevel(load_level, load_episode)
    end
  end, 66)

end

menu.input = function()
  if #filelist.list > 0 then
    filelist.basiccontrol(menu.playerinput)
  end
  local validclick = filelist.basiccursor(menu.mx(0), menu.my(0))
  if menu.playerinput.rawKeys.jump == KEYS_PRESSED or validclick then
    if filelist.icon[filelist.option] == FILE_FOLDER then
      menu.activatefolder()
    elseif filelist.icon[filelist.option] == FILE_LEVEL then
      menu.activatefile()
    end
  elseif (menu.playerinput.rawKeys.run == KEYS_PRESSED or (menu.validclick and click.click and not click.box{x = menu.mx(0), y = menu.my(0), width = menu.img.width, height = menu.img.height})) and GameData.SMBXLP_filedir ~= "" then
    menu.goback()
  elseif menu.playerinput.rawKeys.dropItem == KEYS_PRESSED then
    filelist.arrowoffset = 0
    filelist.listoffset = 0
    filelist.option = 1
    filelist.move(rng.randomInt(1, #filelist.list), true, true)
    SFX.play(menu.sfx_rng)
  end
end

menu.draw = function()
  Graphics.drawImageWP(menu.img, menu.mx(0), menu.my(0), menu.mz(0))
  if #filelist.list > 0 then
    filelist.draw(menu.mx(0), menu.my(0), menu.mz(0))
  else
    if GameData.SMBXLP_filedir == "/"..GameData.SMBXLP_foldername.."/SMBXLP" then
      printplus("Nothing to see here :/", menu.mx(325), menu.my(32), menu.mz(0), Color.red, vector.v2(0.5, 0))
    elseif GameData.SMBXLP_filedir == "/"..GameData.SMBXLP_foldername.."/SMBX Level Player" then
      printplus("Looking for something?", menu.mx(325), menu.my(32), menu.mz(0), Color.red, vector.v2(0.5, 0))
    elseif GameData.SMBXLP_filedir == "/"..GameData.SMBXLP_foldername.."/Music" then
      printplus("Nothing to see here, except\nsome sweet tunes :)", menu.mx(325), menu.my(32), menu.mz(0), Color.red, vector.v2(0.5, 0))
    elseif GameData.SMBXLP_filedir == "/"..GameData.SMBXLP_foldername.."/launcher" then
      printplus("Making a launcher is hard... :(", menu.mx(325), menu.my(32), menu.mz(0), Color.red, vector.v2(0.5, 0))
    else
      printplus("No levels or folders were found", menu.mx(325), menu.my(32), menu.mz(0), Color.red, vector.v2(0.5, 0))
    end
  end
  if filelist.drawonlyoption then
    Graphics.drawScreen{priority = 10, color = Color.black .. menu.loadingtimer}
  end
end

function onStart()
  fixplayer2()

  eventu.setFrameTimer(300, birdspawner, true)
  eventu.setTimer(5, menu.updateList, true)

  if firstload then
    local signx, signy = NPC.get(151)[1].x - 24, NPC.get(151)[1].y + 38
    eventu.setFrameTimer(1, function() Graphics.drawImageToSceneWP(menu.sign, signx, signy, 5.1) end, 500)
  end

  menu.updateList()
  eventu.setFrameTimer(10, function() menu.introFrozen = false  randomsong() end)

  if GameData.SMBXLP_menuhist[#GameData.SMBXLP_menuhist] and GameData.SMBXLP_menuhist[#GameData.SMBXLP_menuhist][3] then
    filelist.arrowoffset = GameData.SMBXLP_menuhist[#GameData.SMBXLP_menuhist][1]
    filelist.listoffset = GameData.SMBXLP_menuhist[#GameData.SMBXLP_menuhist][2]
    filelist.option = filelist.listoffset + filelist.arrowoffset + 1
    table.remove(GameData.SMBXLP_menuhist)
  end
end

function onTick()
  menu.validclick = true
  if menu.isHelp then
    Graphics.drawImageWP(menu.help, 0, 0, 6)
    Graphics.drawScreen{color = {.250980392157, .250980392157, .250980392157, .588235294118}, priority = 5}
    if click.click then SFX.play(menu.sfx_select) menu.isHelp = false end
    for _, p in ipairs({player, player2}) do
      if p and p.rawKeys.run == KEYS_PRESSED then
        menu.isHelp = false
        SFX.play(menu.sfx_select)
      end
    end
  else
    if SMBXLP.menu.isMenu then return end
    birdscare()
    clickmanager()
    if not (menu.introFrozen or filelist.drawonlyoption) then
      menu.input()
    elseif filelist.drawonlyoption then
      if player.rawKeys.run == KEYS_PRESSED then
        filelist.drawonlyoption = false
        eventu.abort(menu.coroutineloading)
        SFX.play(menu.sfx_back)
      elseif player.rawKeys.jump == KEYS_PRESSED then
        table.insert(GameData.SMBXLP_menuhist, {filelist.arrowoffset, filelist.listoffset, true})
        loadlevel(load_level, load_episode)
      end
    end

    menu.draw()
  end
  disableinputs()

  local cspeed = click.speedX^2 + click.speedY^2
  if cspeed > 800 then
    shaketimer = math.min(shaketimer + 1, 500)
  else
    shaketimer = math.max(0, shaketimer - 1)
  end
  if shaketimer >= 100 then
    Defines.earthquake = (shaketimer - 100)*20/400
    if shaketimer == 500 then
      SFX.play(69)
      shaketimer = 0
      SFX.play(birdsfx)
      local max = rng.randomInt(10, 20)
      local left = Section(1).boundary.left
      for _, n in ipairs(NPC.get({42, 501, 502, 503, 504})) do
        if n.id == 42 then
          n.id = 507
        else
          n.id = n.id + 4
        end
        n.speedY = -1
        n.dontMove = false
        n.direction = DIR_LEFT
        n.data._basegame.moveState = 3
        SFX.play(birdsfx)
      end
      eventu.run(function()
        for i = 1, max do
          local bird = NPC.spawn(rng.irandomEntry({505, 506, 507, 508}), left + rng.random(-16, 800), Section(1).boundary.bottom + 16, 1)
          local dist = (left + 400) - (bird.x + 8)
          if math.abs(dist) > 300 then
            bird.direction = math.sign(dist)
            bird.speedX = bird.speedX*math.sign(dist)
          else
            bird.direction = rng.irandomEntry({-1, 1})
            bird.speedX = bird.speedX*rng.irandomEntry({-1, 1})
          end
          Animation.spawn(10, bird.x - 8, bird.y - 8)
          eventu.waitFrames(rng.randomInt(1, 5))
        end
      end)
    end
  end

  for _, n in ipairs(NPC.get({462, 559})) do
    n.y = n.y - 3
  end
  for _, n in ipairs(NPC.get(283)) do
    n.x = n.x + 2
  end

  Graphics.drawImageWP(menu.logo, menu.logox, 0, 5)
end

local orange = Color(0.906, 0.537, 0.047)
function onDraw()
  if musicprevpos > Audio.MusicGetPos() then
    randomsong()
  end
  musicprevpos = Audio.MusicGetPos()

  local filedir = GameData.SMBXLP_filedir
  if string.len(filedir) > 32 then filedir = "..."..string.sub(filedir, -29) end
  printplus("File Directory: "..filedir, 8, 576, 5, orange)
  printplus("Menu Key: "..GameData.SMBXLP_set.menukeyname.." ("..GameData.SMBXLP_set.menukey..")", 8, 554, 5, orange)
  if menu.isHelp then
    if math.abs(menu.logox) < 15 then
      menu.logox = 0
    elseif menu.logox < -15 then
      menu.logox = menu.logox + 15
    else
      menu.logox = menu.logox - 15
    end
  else
    if menu.logox < 800 and menu.logox ~= -800 then
      menu.logox = menu.logox + 35
    else
      menu.logox = -800
    end
  end

  if SMBXLP.menu.isMenu then
    printplus("Playing song: "..prevsong, 792, 8, 6, Color.purple, vector.v2(1, 0))
  end
end

function onKeyboardPressDirect(id, b)
  if id == 9 and b and not SMBXLP.menu.isMenu then
    randomsong()
    GameData.SMBXLP_filedir = ""
    GameData.SMBXLP_menuhist = {}
    menu.updateList()
    GameData.SMBXLP_set.menukeytype = 0
    GameData.SMBXLP_set.menukey = 0
    GameData.SMBXLP_set.menukeyname = "Pause Key"
    SMBXLP.menu.toggle()
    for _, n in ipairs(NPC.get()) do
      if n.id ~= 151 and n.id ~= 465 then
        n.x = 0
      end
    end
  end
end

function onCameraUpdate(idx)
  if idx == 1 and not SMBXLP.menu.customcamera then
      camera.x = -180000
      camera.y = -180608+8
      camera.renderX = 0
      camera.renderY = 0
      camera.width = 800
      camera.height = 600
  else
    camera2.renderY = 800
  end
end

function onExitLevel()
	if filelist.drawonlyoption then
    GameData.SMBXLP_activated = true
    GameData.SMBXLP_restart = {type = 2}
	end
end
