local submenu = {}

local textplus = require("textplus")

submenu.name = "Change Player"
submenu.type = "STATIC_FUNC"

submenu.activate = function(menu)
  SFX.play(menu.sfx_select)
  if menu.playeredit == player then
    menu.playeredit = player2 or player
  else
    menu.playeredit = player
  end
end

submenu.draw = function(menu)
  textplus.print{text = "Select to change the\nplayer being edited\n\nThe player that opened\nthe menu will stil be\nin control of the menu", x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2, plaintext = true}
end

return submenu
