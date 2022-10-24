local submenu = {}

-- This module allows you to set the powerup and reserve NPC to the currently selected player

local rng = require("rng")
local click = require("click")
local textplus = require("textplus")
local textfont = textplus.loadFont("textplus/font/6.ini")
local listgen = require(GameData.SMBXLP_dir.."listgenerator.lua")

-- Data for all the current existing powerups
local powerupData = {
  id = {PLAYER_SMALL, PLAYER_BIG, PLAYER_FIREFLOWER, PLAYER_ICE, PLAYER_LEAF, PLAYER_TANOOKIE, PLAYER_HAMMER, PLAYER_SMALL},
  name = {"Random", "Small", "Mushroom", "Fire Flower", "Ice Flower", "Super Leaf", "Tanooki Suit", "Hammer Suit", "Frog Suit", "Reserve NPC"},
  npcid = {"9", "14", "264", "34", "169", "170", "???"}
}

-- Generate a list for options
local poweruplist = listgen.create{
  list = powerupData.name,
  textscale = 2,
  textspacing = 24,
  maxlines = 12
}

-- Data for the reserve NPC option
local reservestate = false
local reservetext = 0
local hasreserve = {
  [CHARACTER_MARIO] = true,
  [CHARACTER_LUIGI] = true,
  [CHARACTER_WARIO] = true,
  [CHARACTER_UNCLEBROADSWORD] = true
}

-- from basegame code, used when setting a powerup to a player
local function resetStatue(p)
	p:mem(0x4A, FIELD_BOOL, false)
end
local function resetFlight(p)
	if p.powerup == 4 or p.powerup == 5 then
		p:mem(0x16E, FIELD_BOOL, false)
		p:mem(0x164, FIELD_WORD, 0)
		p:mem(0x164, FIELD_WORD, 0)
		resetStatue(p)
	end
end

-- Set the reserve powerup based on the reservetext variable
-- If a character does not have a reserve boc, instead spawn it similiar to when toad and peach pick up the stop watch
local function applyreserve(p)
  if reservetext and reservetext <= NPC_MAX_ID and reservetext > 0 and Graphics.sprites.npc[reservetext] and Graphics.sprites.npc[reservetext].img then
    if hasreserve[p.character] then
      p.reservePowerup = reservetext
    else
      local n = NPC.spawn(reservetext, p.x + p.width*0.5, camera.y + 32, p.section)
      n.x = n.x - n.width*0.5
      n:mem(0x138, FIELD_WORD, 2)
    end
  else
    p.reservePowerup = 0
  end
end

submenu.name = "Power-ups"
submenu.type = "STATIC_LIST"

-- Handle the inputs
submenu.input = function(menu, p)
  poweruplist.basiccontrol(p)
  local validclick
  if not reservestate then
    validclick = poweruplist.basiccursor(menu.mx(0), menu.my(0))
  end

  -- Disable the reserve picker, if the player is not selecting that option
  if poweruplist.option ~= 10 then
    reservestate = false
    reservetext = 0
  end

  -- An option is selected
  if p.rawKeys.jump == KEYS_PRESSED or validclick and not menu.playeredit.isMega and menu.playeredit:mem(0x122, FIELD_WORD) then
    SFX.play(menu.sfx_select)

    -- If selecting the reserve NPC option, either enable the reserve NPC picker, or set the reserve NPC if it is already on
    if poweruplist.option == 10 then
      reservestate = not reservestate
      if reservestate then
        reservetext = 0
      else
        GameData.SMBXLP_invalid = true
        applyreserve(menu.playeredit)
      end
    else
      -- If any other option is selected, set the current powerup
      reservestate = false
      reservetext = 0
      local x
      -- Option 1 is the random button
      if poweruplist.option == 1 then
        x = menu.betterrng(powerupData.id, menu.playeredit.powerup)
      else
        x = powerupData.id[poweruplist.option - 1]
      end
      -- If a mushroom is selected, add a heart to the character's health
      if x == 2 then
        menu.playeredit:mem(0x16,	FIELD_WORD, menu.playeredit:mem(0x16,	FIELD_WORD) + 1)
      end
      menu.playeredit.powerup = x
      resetFlight(menu.playeredit)
      GameData.SMBXLP_invalid = true
    end
  end
end

-- Formula for the color pattern for menu
local lightgray = Color(0.48, 0.48, 0.48)
local colorAI = function(option, text, menu)
  if option == 1 or (option == 10 and reservestate) then
    return text, "rainbow"
  elseif poweruplist.option == 10 and option > 2 and option < 10 then
    local c
    if reservestate then c = lightgray end
    return text.." <color green>"..powerupData.npcid[option - 2].."</color>", c, false
  elseif powerupData.id[option - 1] == menu.playeredit.powerup and option ~= 9 then
    return text, Color.green
  end
  return text
end

submenu.draw = function(menu)
  -- draw the list
  poweruplist.draw(menu.mx(0), menu.my(0), menu.mz(0), colorAI, menu)

  -- If currently selecting the reserve NPC option, display the IDs of NPCs that are being hovered by the mouse
  if poweruplist.option == 10 then
    local clickpoint = Colliders.Circle(click.sceneX, click.sceneY, 2)
    local offx
    local offy
    for k, n in ipairs(Colliders.getColliding{a = clickpoint, b = NPC.ALL, btype = Colliders.NPC, filter = function() return true end}) do
      offx = offx or n.x
      offy = offy or n.y
      textplus.print{text = tostring(n.id), x = offx, y = offy + 16*(k - 1), priority = 9.9999, sceneCoords = true, xscale = 2, yscale = 2, color = Color.green, font = textfont}
    end
  end

  -- Draw the current reservetext and a preview of the NPC while the reserve NPC picker is actve
  if reservestate then
    if reservetext == 0 then
      textplus.print{text = "Type the NPC ID\nusing the keyboard", x = menu.mx(0), y = menu.my(288), priority = menu.mz(0), xscale = 2, yscale = 2}
    else
      textplus.print{text = tostring(reservetext), x = menu.mx(0), y = menu.my(288), priority = menu.mz(0), xscale = 2, yscale = 2}
      local npc = Graphics.sprites.npc[reservetext]
      if npc and npc.img then
        local w = NPC.config[reservetext].gfxwidth
        if w == 0 then w = NPC.config[reservetext].width end
        local h = NPC.config[reservetext].gfxheight
        if h == 0 then h = NPC.config[reservetext].height end
        Graphics.draw{type = RTYPE_IMAGE, image = npc.img, priority = menu.mz(0), isSceneCoords = false, x = menu.mx(64), y = menu.my(288), sourceWidth = w, sourceHeight = h}
      end
    end
  end
end

-- Disable the NPC picker if the menu is closed mid action
submenu.exit = function(menu)
  -- if reservestate then
    -- SFX.play(menu.sfx_select)
    -- applyreserve(menu.playeredit)
  -- end
  reservestate = false
end

-- Listen for number keys and backspace when the reerve NPC picker is activated
function submenu.onKeyboardPressDirect(id, b)
  if reservestate then
    -- Number keys
    if reservetext < NPC_MAX_ID then
      if (id <= 57 and id >= 48 ) then
        reservetext = tonumber(tostring(reservetext)..(id - 48))
      elseif (id >= 96 and id <= 105 ) then
        reservetext = tonumber(tostring(reservetext)..(id - 96))
      end
    end
    -- Backspace
    if id == 8 then
      local s = tostring(reservetext)
      s = s:sub(1, -2)
      if s == "" then s = "0" end
      reservetext = tonumber(s)
    end
  end
end

-- Register listener functions
function submenu.onInitAPI()
  registerEvent(submenu, "onKeyboardPressDirect", "onKeyboardPressDirect")
end

return submenu
