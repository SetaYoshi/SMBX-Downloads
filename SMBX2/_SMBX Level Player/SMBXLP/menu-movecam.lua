local submenu = {}

local textplus = require("textplus")
local click = require("click")
local repl = require("base/game/repl")

local arrowUp = Graphics.loadImage(GameData.SMBXLP_dir.."arrow-up.png")
local arrowDown = Graphics.loadImage(GameData.SMBXLP_dir.."arrow-down.png")
local arrowLeft = Graphics.loadImage(GameData.SMBXLP_dir.."arrow-left.png")
local arrowRight = Graphics.loadImage(GameData.SMBXLP_dir.."arrow-right.png")
local arrowOffset = 0
local arrowDir = 1
local usingCursor = false
local playerinput = player
local playeredit = player

local cammove = {}
cammove.x = 0
cammove.y = 0
cammove.activated = false
cammove.border = 50
cammove.speed = 5

submenu.name = "Camera Pan"
submenu.type = "STATIC_LIST"

local caminput = function()
  arrowOffset = arrowOffset + arrowDir
  if math.abs(arrowOffset) == 8 then
    arrowDir = arrowDir*(-1)
  end
  if playerinput.rawKeys.left or playerinput.rawKeys.right or playerinput.rawKeys.up or playerinput.rawKeys.down then
    usingCursor = false
  end
  if click.speedX ~= 0 or click.speedY ~= 0 then
    usingCursor = true
  end

  if (click.x <= cammove.border and usingCursor) or playerinput.rawKeys.left then
    cammove.x = cammove.x - cammove.speed
  elseif (click.x >= 800 - cammove.border and usingCursor) or playerinput.rawKeys.right then
    cammove.x = cammove.x + cammove.speed
  end
  if (click.y <= cammove.border and usingCursor) or playerinput.rawKeys.up then
    cammove.y = cammove.y - cammove.speed
  elseif (click.y >= 600 - cammove.border and usingCursor) or playerinput.rawKeys.down then
    cammove.y = cammove.y + cammove.speed
  end
  local sec = Section(playeredit.section).boundary
  cammove.x = math.clamp(sec.left, cammove.x, sec.right - 800)
  cammove.y = math.clamp(sec.top, cammove.y, sec.bottom - 600)
  camera.x = cammove.x
  camera.y = cammove.y
end

local camdraw = function()
  if cammove.activated then
    local sec = Section(playeredit.section).boundary
    if camera.x > sec.left then
      Graphics.drawImageWP(arrowLeft, 16 + arrowOffset,292,5)
    end
    if camera.x + 800 < sec.right then
      Graphics.drawImageWP(arrowRight, 768 - arrowOffset,292,5)
    end
    if camera.y > sec.top then
      Graphics.drawImageWP(arrowUp, 392, 16 + arrowOffset,5)
    end
    if camera.y + 600 < sec.bottom then
      Graphics.drawImageWP(arrowDown,392, 568 - arrowOffset,5)
    end
  end
end

submenu.input = function(menu)
end

submenu.draw = function(menu)
  if cammove.activated then
    textplus.print{text = "Use the arrow keys, or\nthe mouse to move\naround\n\nPress run or click\noutside the menu to\ngo back", x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2, plaintext = true}
  else
    textplus.print{text = "Select to move the\ncamera around", x = menu.mx(0), y = menu.my(0), priority = menu.mz(0), xscale = 2, yscale = 2, plaintext = true}
  end
end

submenu.start = function(menu)
  GameData.SMBXLP_invalid = true
  menu.disablesidekeys = true
  cammove.activated = true
  cammove.x = camera.x
  cammove.y = camera.y
  playerinput = menu.playerinput
  playeredit = menu.playeredit
end

submenu.exit = function(menu)
  menu.disablesidekeys = false
  cammove.activated = false
  usingCursor = false
end

function submenu.camera(idx)
  if cammove.activated and idx == 1 then
    Misc.pause()
    caminput()
    camdraw()
  end
end

local premod
submenu.tablist = {}
submenu.tablist[1] = {
  name = "Pan Camera",
  func = function(menu)
    if cammove.activated then
      SFX.play(menu.sfx_close)
      menu.unlockcamera()
      Misc.unpause()
      menu.disable = false
      menu.activatedmodule = premod
      submenu.exit(menu)
   else
     SFX.play(menu.sfx_select)
     menu.lockcamera()
     Misc.pause()
     menu.disable = true
     premod = menu.activatedmodule
     menu.activatedmodule = menu.findmodule("Camera Pan")
     submenu.start(menu)
    end
  end
}

function submenu.onInitAPI()
  registerEvent(submenu, "onDraw", "onDraw", true)
end

return submenu
