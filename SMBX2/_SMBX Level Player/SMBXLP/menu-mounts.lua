local submenu = {}

-- This module allows you to set the mount of a character

local rng = require("rng")
local listgen = require(GameData.SMBXLP_dir.."listgenerator.lua")

local MOUNT_NONE = 1
local MOUNT_GREENSHOE = 2
local MOUNT_REDSHOE = 3
local MOUNT_BLUESHOE = 4
local MOUNT_GREENYOSHI = 5
local MOUNT_BLUEYOSHI = 6
local MOUNT_YELLOWYOSHI = 7
local MOUNT_REDYOSHI = 8
local MOUNT_BLACKYOSHI = 9
local MOUNT_PURPLEYOSHI = 10
local MOUNT_PINKYOSHI = 11
local MOUNT_CYANYOSHI = 12
local MOUNT_CLOWNCAR = 13

local MOUNTLIST_NONE = 0
local MOUNTLIST_ALL = 1
local MOUNTLIST_NOYOSHI = 2
local MOUNTLIST_CLOWNCAR = 3


local shoe = {MOUNT_GREENSHOE, MOUNT_REDSHOE, MOUNT_BLUESHOE}
local yoshi = {MOUNT_GREENYOSHI, MOUNT_BLUEYOSHI, MOUNT_YELLOWYOSHI, MOUNT_REDYOSHI, MOUNT_BLACKYOSHI, MOUNT_PURPLEYOSHI, MOUNT_PINKYOSHI, MOUNT_CYANYOSHI}
local getMountID = function(p)
  if p.mount == 0 then
    return MOUNT_NONE
  elseif p.mount == 1 then
    return shoe[p.mountColor]
  elseif p.mount == 2 then
    return MOUNT_CLOWNCAR
  elseif p.mount == 3 then
    return yoshi[p.mountColor]
  end
end

local id2mount = {{0,0},{1,1},{1,2},{1,3},{3,1},{3,2},{3,3},{3,4},{3,5},{3,6},{3,7},{3,8},{2,1}}
local setMountID = function(p, id)
  p.mount = id2mount[id][1]
  p.mountColor = id2mount[id][2]
end

local mounttype = {
  [0] = MOUNTLIST_ALL,
  [CHARACTER_MARIO] = MOUNTLIST_ALL,
  [CHARACTER_LUIGI] = MOUNTLIST_ALL,
  [CHARACTER_TOAD] = MOUNTLIST_NOYOSHI,
  [CHARACTER_PEACH] = MOUNTLIST_NOYOSHI,
  [CHARACTER_LINK] = MOUNTLIST_CLOWNCAR,
  [CHARACTER_MEGAMAN] = MOUNTLIST_NOYOSHI,
  [CHARACTER_WARIO] = MOUNTLIST_ALL,
  [CHARACTER_BOWSER] = MOUNTLIST_NONE,
  [CHARACTER_KLONOA] = MOUNTLIST_NOYOSHI,
  [CHARACTER_NINJABOMBERMAN] = MOUNTLIST_NOYOSHI,
  [CHARACTER_ROSALINA] = MOUNTLIST_NOYOSHI,
  [CHARACTER_SNAKE] = MOUNTLIST_NONE,
  [CHARACTER_ZELDA] = MOUNTLIST_ALL,
  [CHARACTER_ULTIMATERINKA] = MOUNTLIST_NOYOSHI,
  [CHARACTER_UNCLEBROADSWORD] = MOUNTLIST_ALL,
  [CHARACTER_SAMUS] = MOUNTLIST_NONE

}

local allMounts = {
  id = {MOUNT_NONE, MOUNT_GREENSHOE, MOUNT_REDSHOE, MOUNT_BLUESHOE, MOUNT_GREENYOSHI, MOUNT_BLUEYOSHI, MOUNT_YELLOWYOSHI, MOUNT_REDYOSHI, MOUNT_BLACKYOSHI, MOUNT_PURPLEYOSHI, MOUNT_PINKYOSHI, MOUNT_CYANYOSHI, MOUNT_CLOWNCAR},
  name = {"None", "Goomba Shoe", "Podoboo Shoe", "Lakitu Shoe", "Green Yoshi", "Blue Yoshi", "Yellow Yoshi", "Red Yoshi", "Black Yoshi", "Purple Yoshi", "Pink Yoshi", "Cyan Yoshi", "Clown Car"}
}

local mountdata = {}
local mountlist = {}

-- NONE
mountdata[MOUNTLIST_NONE] = {}
mountdata[MOUNTLIST_NONE].id = {MOUNT_NONE}
mountdata[MOUNTLIST_NONE].name = {"Random", "None"}
mountlist[MOUNTLIST_NONE] = listgen.create{
  list = mountdata[MOUNTLIST_NONE].name,
  textscale = 2,
  textspacing = 24,
  maxlines = 12
}

-- ALL
mountdata[MOUNTLIST_ALL] = {}
mountdata[MOUNTLIST_ALL].id = allMounts.id
mountdata[MOUNTLIST_ALL].name = table.clone(allMounts.name)
table.insert(mountdata[MOUNTLIST_ALL].name, 1, "Random")
mountlist[MOUNTLIST_ALL] = listgen.create{
  list = mountdata[MOUNTLIST_ALL].name,
  textscale = 2,
  textspacing = 24,
  maxlines = 12
}

-- NOYOSHI
mountdata[MOUNTLIST_NOYOSHI] = {}
mountdata[MOUNTLIST_NOYOSHI].id = {}
mountdata[MOUNTLIST_NOYOSHI].name = {"Random"}
for _, v in ipairs({1, 2, 3, 4, 13}) do
  table.insert(mountdata[MOUNTLIST_NOYOSHI].id,  allMounts.id[v])
  table.insert(mountdata[MOUNTLIST_NOYOSHI].name,  allMounts.name[v])
end
mountlist[MOUNTLIST_NOYOSHI] = listgen.create{
  list = mountdata[MOUNTLIST_NOYOSHI].name,
  textscale = 2,
  textspacing = 24,
  maxlines = 12
}

-- CLOWNCAR
mountdata[MOUNTLIST_CLOWNCAR] = {}
mountdata[MOUNTLIST_CLOWNCAR].id = {}
mountdata[MOUNTLIST_CLOWNCAR].name = {"Random"}
for _, v in ipairs({1, 13}) do
  table.insert(mountdata[MOUNTLIST_CLOWNCAR].id,  allMounts.id[v])
  table.insert(mountdata[MOUNTLIST_CLOWNCAR].name,  allMounts.name[v])
end
mountlist[MOUNTLIST_CLOWNCAR] = listgen.create{
  list = mountdata[MOUNTLIST_CLOWNCAR].name,
  textscale = 2,
  textspacing = 24,
  maxlines = 12
}

submenu.name = "Mounts"
submenu.type = "STATIC_LIST"

submenu.input = function(menu, p)
  local type = mounttype[menu.playeredit.character] or mounttype[0]
  local mountlistsp = mountlist[type]
  mountlistsp.basiccontrol(p)
  local validclick = mountlistsp.basiccursor(menu.mx(0), menu.my(0))
  if p.rawKeys.jump == KEYS_PRESSED or validclick then
    local x
    if mountlistsp.option == 1 then
      x = menu.betterrng(mountdata[type].id, getMountID(menu.playeredit))
    else
      x = mountdata[type].id[mountlistsp.option - 1]
    end
    if getMountID(menu.playeredit) ~= MOUNT_CLOWNCAR and x == MOUNT_CLOWNCAR then
      menu.playeredit.y = menu.playeredit.y - 100
    end
    setMountID(menu.playeredit, x)
    SFX.play(menu.sfx_select)
    GameData.SMBXLP_invalid = true
  end
end

local colorAI = function(option, text, menu)
  local type = mounttype[menu.playeredit.character] or mounttype[0]
  if option == 1 then
    return text, "rainbow"
  elseif mountdata[type].id[option - 1] == getMountID(menu.playeredit) then
    return text, Color.green
  end
  return text
end

submenu.draw = function(menu)
  local type = mounttype[menu.playeredit.character] or mounttype[0]
  mountlist[type].draw(menu.mx(0), menu.my(0), menu.mz(0), colorAI, menu)
end

return submenu
