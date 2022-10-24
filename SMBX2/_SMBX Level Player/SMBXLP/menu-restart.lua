local submenu = {}

-- This module allows you to restart a level from different position. Including: last checkpoint, level start, any checkpoint, and any warp.

local eventu = require("eventu")
local textplus = require("textplus")
local listgen = require(GameData.SMBXLP_dir.."listgenerator.lua")
local save = require(GameData.SMBXLP_dir.."listgenerator.lua")

local function getStartingPosition(idx)
    local GM_PLAYER_POS = mem(0xB25148, FIELD_DWORD)
    local x = mem(GM_PLAYER_POS+idx*48 + 0x0, FIELD_DFLOAT)
    local y = mem(GM_PLAYER_POS+idx*48 + 0x8, FIELD_DFLOAT)
    local h = mem(GM_PLAYER_POS+idx*48 + 0x10, FIELD_DFLOAT)
    local w = mem(GM_PLAYER_POS+idx*48 + 0x18, FIELD_DFLOAT)
    return x, y, w, h
end

submenu.name = "Restart"
submenu.type = "STATIC_LIST"

local TYPE_LASTCH = 1
local TYPE_START = 2
local TYPE_CHN = 3
local TYPE_CHV = 4
local TYPE_WARP = 5

local restartdata = {"From Last Checkpoint", "From Level Start"}

local checkpointnum = 0
local hasvanillacheck
local warpnum

-- Generate a list for options
local restartlist = listgen.create{
  list = restartdata,
  textscale = 2,
  textspacing = 24,
  maxlines = 10
}

submenu.input = function(menu, p)
  restartlist.basiccontrol(p)
  local validclick = restartlist.basiccursor(menu.mx(0), menu.my(48))
  if p.rawKeys.jump == KEYS_PRESSED or validclick then
      local type
      local id
      if restartlist.option == 1 then
        type = TYPE_LASTCH
        for _, p in ipairs(Player.get()) do
          p.powerup = PLAYER_SMALL
          p.mount = 0
          p.mountColor = 0
          p:mem(0x16,	FIELD_WORD, 0)
        end
      elseif restartlist.option == 2 then
        type = TYPE_START
        Checkpoint.reset()
        mem(0x00B250B0, FIELD_STRING, "")
      elseif restartlist.option > 2 and restartlist.option < checkpointnum + 3 then
        id = restartlist.option - 2
        if hasvanillacheck then
          type = TYPE_CHV
          mem(0x00B250B0, FIELD_STRING, mem(0x00B2C618, FIELD_STRING))
        else
          type = TYPE_CHN
          Checkpoint.reset()
          mem(0x00B250B0, FIELD_STRING, "")
          Checkpoint.get(id):collect()
        end
      else
        type = TYPE_WARP
        id = restartlist.option - checkpointnum - 2
        Checkpoint.reset()
        mem(0x00B250B0, FIELD_STRING, "")
        if GameData.SMBXLP_activated then
          Level.load(".."..GameData.SMBXLP_filedir.."/"..Level.filename(), "SMBX Level Player", id)
        else
          Level.load(Level.filename(), "SMBX Level Player", id)
        end
      end
      GameData.SMBXLP_restart = {type = type, id = id}
      if type ~= TYPE_WARP then
        for _, p in ipairs(Player.get()) do
          p:mem(0x13C,	FIELD_BOOL, true)
          p:mem(0x13E,	FIELD_BOOL, 100)
        end
        mem(0x00B2C5AC, FIELD_FLOAT, mem(0x00B2C5AC, FIELD_FLOAT) + 1)
      end
      menu.toggle()
      eventu.setFrameTimer(1, function() menu.playerinput.jumpKeyPressing = false Graphics.drawBox{x = 0, y = 0, width = 800, height = 600, color = Color.black, priority = 10} end, true)
  end
end

function submenu.draw(menu)
  textplus.print{text = "WARNING\nProgress may be lost", x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2, color = Color.red, plaintext = true}
  restartlist.draw(menu.mx(0), menu.my(48), menu.mz(0))
end

local function countList()
  local newchcheck = NPC.get({400, 430}, -1)
  if #newchcheck > 0 then
    checkpointnum = #newchcheck
  elseif #NPC.get(192) > 0 then
    checkpointnum = 1
    hasvanillacheck = true
  end
  if checkpointnum == 1 then
    table.insert(restartlist.list, "Midpoint")
  elseif checkpointnum > 0 then
    for i = 1, checkpointnum do
      table.insert(restartlist.list, "Checkpoint "..i)
    end
  end
  warpnum = Warp.count()
  for i = 1, warpnum do
    table.insert(restartlist.list, "Warp "..i)
  end
  restartlist.update()
end

function submenu.onStart()
  countList()

  if GameData.SMBXLP_restart then
    GameData.SMBXLP_restart = false
  end
end

function submenu.camera(idx, menu)
  if menu.activatedmodule ~= 0 then
    if restartlist.option == 1 then
    elseif restartlist.option == 2 then
      camera.x, camera.y = getStartingPosition(0)
      camera.x = camera.x - 400
      camera.y = camera.y - 300
    elseif restartlist.option > 2 and restartlist.option < checkpointnum + 3 then
      id = restartlist.option - 2
      local ch
      if hasvanillacheck then
        ch = NPC.get(192)[1]
      else
        ch = Checkpoint.get(id)
      end
      if ch then
        camera.x = ch.x - 400
        camera.y = ch.y - 300
      end
    else
      id = restartlist.option - checkpointnum - 2
      local w = Warp.get()[id]
      camera.x = w.exitX - 400
      camera.y = w.exitY - 300
    end
  end
end

function submenu.onInitAPI()
  registerEvent(submenu, "onStart", "onStart", false)
end

return submenu
