local submenu = {}

-- Set different filters

local rng = require("rng")
local playerManager = require("playerManager")
local listgen = require(GameData.SMBXLP_dir.."listgenerator.lua")

local colorfilter = Shader()
local filterBuffer = Graphics.CaptureBuffer(800,600)

-- Data gotten from testmodemenu.lua
local effectData = {
  name = {
    "None",
    "Protanopia",
    "Protanomaly",
    "Deuteranopia",
    "Deuteranomaly",
    "Tritanopia",
    "Tritanomaly",
    "Achromatopsia",
    "Achromatomaly"
  },
  mat = {
    vector.mat3(0.56667, 0.55833, 0,  		0.43333, 0.44167, 0.24167, 		0,     0,       0.75833),
    vector.mat3(0.81667, 0.33333, 0,  		0.18333, 0.66667, 0.125, 		0,     0,       0.875),
    vector.mat3(0.625,   0.70,    0,  		0.375,   0.30,    0.30, 		0,     0,       0.70),
    vector.mat3(0.80,    0.25833, 0,  		0.20,    0.74167, 0.14167, 		0,     0,       0.85833),
    vector.mat3(0.95,    0,       0,  		0.05,    0.43333, 0.475, 		0,     0.56667, 0.525),
    vector.mat3(0.96667, 0,       0,  		0.03333, 0.73333, 0.18333, 		0,     0.26667, 0.81667),
    vector.mat3(0.299,   0.299,   0.299,   0.587,   0.587,   0.587, 		0.114, 0.114,   0.114),
    vector.mat3(0.618,   0.163,   0.163,   0.32,    0.775,   0.32, 		0.062, 0.062,   0.516)
  }
}

local effectlist = listgen.create{
  list = effectData.name,
  textscale = 2,
  textspacing = 24,
  maxlines = 12
}

submenu.name = "Filters"
submenu.type = "STATIC_LIST"

submenu.input = function(menu, p)
  effectlist.basiccontrol(p)
  local validclick = effectlist.basiccursor(menu.mx(0), menu.my(0))
  if p.rawKeys.jump == KEYS_PRESSED or validclick then
    SFX.play(menu.sfx_select)
    GameData.SMBXLP_set.filter = effectlist.option - 1
  end
end


local colorAI = function(option, text, menu)
  if option == GameData.SMBXLP_set.filter + 1 then
    return text, Color.green
  end
  return text
end

submenu.draw = function(menu)
  effectlist.draw(menu.mx(0), menu.my(0), menu.mz(0), colorAI)
end

function submenu.onCameraDraw(idx)
  if GameData.SMBXLP_set.filter > 0 then
    if not colorfilter._isCompiled then
      colorfilter:compileFromFile(nil, "shaders/colormatrix.frag")
    end
    filterBuffer:captureAt(10)
    Graphics.drawScreen{texture = filterBuffer, shader = colorfilter, uniforms = {matrix = effectData.mat[GameData.SMBXLP_set.filter]}, priority = 10}
  end
end

function submenu.onInitAPI()
  registerEvent(submenu, "onCameraDraw", "onCameraDraw", false)
end

return submenu
