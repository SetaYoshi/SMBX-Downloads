local submenu = {}

local textplus = require("textplus")
local eventu = require("eventu")
local rng = require("rng")
local listgen = require(GameData.SMBXLP_dir.."listgenerator.lua")

local characterlist = listgen.create{
  list = {"Level Select", "Exit Game"},
  textscale = 2,
  textspacing = 24,
  maxlines = 12
}

submenu.name = "Exit Level"
submenu.type = "STATIC_LIST"

submenu.input = function(menu, p)
  characterlist.basiccontrol(p)
  local validclick = characterlist.basiccursor(menu.mx(0), menu.my(48))
  if p.rawKeys.jump == KEYS_PRESSED or validclick then
    SFX.play(menu.sfx_select)
    menu.toggle()
    eventu.setFrameTimer(1, function()
      Graphics.drawBox{x = 0, y = 0, width = 800, height = 600, color = Color.black, priority = 10}
      menu.playerinput.jumpKeyPressing = false
    end, 6)
    if characterlist.option == 1 then
      GameData.SMBXLP_restart = {type = 2}
      eventu.setFrameTimer(5, function() Level.load("SMBX Level Player.lvlx", "SMBX Level Player", 1) end)
    else
      GameData.SMBXLP_restart = {type = 6}
      GameData.SMBXLP_activated = false
      eventu.setFrameTimer(5, function() Misc.exitGame() end)
    end
  end
end

submenu.draw = function(menu)
  textplus.print{text = "WARNING<br>Progress may be lost", x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2, color = Color.red}
  characterlist.draw(menu.mx(0), menu.my(48), menu.mz(0))
end

return submenu
