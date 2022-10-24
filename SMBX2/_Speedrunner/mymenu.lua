local mym  = {}

local textplus = require("textplus")
local textfont = textplus.loadFont("textplus/font/6.ini")

local inEpisode = Misc.saveSlot() > 0

-- Data table for settings
mym.data = {}
mym.input = {}

-- If the menu is on or off
mym.active = false

-- Options for main menu
mym.option = 1
mym.submenu = 0
mym.list = {}
mym.isNumBuffer = false
mym.maxBuffer = 0
mym.numBuffer = 0


local function on()
  mym.option = 1
  mym.suboption = 0
  SFX.play(mym.aOpen)
end

local function off()
  mym.save()
  SFX.play(mym.aClose)
end


mym.toggle = function()
  mym.active = not mym.active
  if mym.active then on()
  else off() end
end

local function mainInput()
  local input = mym.input

  if input.up.time == 1 or (input.up.time > 20 and input.up.time % 8 == 0) then
    mym.option = mym.option - 1
    SFX.play(mym.aScroll)
  elseif input.down.time == 1 or (input.down.time > 20 and input.down.time % 8 == 0) then
    mym.option = mym.option + 1
    SFX.play(mym.aScroll)
  end
  if mym.option <= 0 then
    mym.option = #mym.list
  elseif mym.option > #mym.list then
    mym.option = 1
  end
  if input.select.state == KEYS_PRESSED then
    local selection = mym.list[mym.option]
    if selection.type == "toggle" then
      mym.data[selection.var] = not mym.data[selection.var]
    elseif selection.type == "list" then
      mym.data[selection.var] = mym.data[selection.var] + 1
      if mym.data[selection.var] > #selection.list then mym.data[selection.var] = 1 end
    elseif selection.type == "func" then
      selection.func()
    elseif selection.type == "submenu" then
      mym.submenu = mym.option
    elseif selection.type == "numpad" then
      mym.isNumBuffer = not mym.isNumBuffer
      if mym.isNumBuffer then
        mym.numBuffer = 0
        mym.maxBuffer = selection.max
      else
        mym.data[selection.var] = mym.numBuffer
      end
    end
    SFX.play(mym.aSelect)
  end
end

mym.inputs = function()
  if mym.input.back.state == KEYS_PRESSED then
    if mym.submenu == 0 then
      mym.toggle()
      return
    else
      mym.submenu = 0
      SFX.play(mym.aClose)
    end
  end

  if mym.submenu == 0 then
    mainInput()
  else
    mym.list[mym.option].input(mym.list[mym.option].subdata)
  end
end

local function mainrender()
  textplus.print{text = "Speedrunner Menu", x = 8, y = 8, plaintext = true, priority = 9.99, xscale = 3, yscale = 3}
  for k, v in ipairs(mym.list) do
    local s = v.name
    local color
    -- Add cursor
    if k == mym.option then
      s = "> "..s
      color = Color.green
    else
      s = "  "..s
    end

    -- Add values
    if v.type == "toggle" then
      local d = "OFF"
      if mym.data[v.var] then d = "ON" end
      s = s..": "..d
    elseif v.type == "list" then
      s = s..": "..v.list[mym.data[v.var]]
    elseif v.type == "numpad" then
      if k == mym.option and mym.isNumBuffer then
        s = s..": "..mym.numBuffer
      else
        s = s..": "..mym.data[v.var]
      end
    end
    textplus.print{text = s, x = 8, y = 32 + 22*k, plaintext = true, priority = 9.99, xscale = 2, yscale = 2, color = color}
  end
end

local lightgray = Color(0.05, 0.05, 0.05, 0.7)
mym.render = function()
  Graphics.drawBox{x = 0, y = 0, width = 800, height = 600, priority = 9.99, color = lightgray}

  if mym.submenu == 0 then
    mainrender()
  else
    mym.list[mym.option].render(mym.list[mym.option].subdata)
  end
end

mym.register = function(t)
  if not ((t.episodeBanned and inEpisode) or (t.levelBanned and not inEpisode)) then
    table.insert(mym.list, t)
  end
end


-- Deactivate players' controls when the menu is active
function mym.onInputUpdate()
	if mym.active then
		for _, p in ipairs(Player.get()) do
			for k, v in pairs(p.keys) do
				p.keys[k] = false
			end
		end
	end
end

function mym.onDraw()
  -- When the menu is active, pass inputs here
  if mym.active then
    mym.inputs()
  end
  if mym.input.menu.state == KEYS_PRESSED then
    mym.toggle()
  end

  if isOverworld and mym.active then
    mym.render()
  end
end

function mym.onCameraDraw(idx)
  if mym.active and idx == 1 then
    mym.render()
  end
end

function mym.onKeyboardPressDirect(id)
  if mym.isNumBuffer then
    -- Number keys
    if mym.numBuffer < NPC_MAX_ID then
      if (id <= 57 and id >= 48 ) then
        mym.numBuffer = tonumber(tostring(mym.numBuffer)..(id - 48))
      elseif (id >= 96 and id <= 105 ) then
        mym.numBuffer = tonumber(tostring(mym.numBuffer)..(id - 96))
      end
    end
    -- Backspace
    if id == 8 then
      local s = tostring(mym.numBuffer)
      s = s:sub(1, -2)
      if s == "" then s = "0" end
      mym.numBuffer = tonumber(s)
    end
  end
end

function mym.onInitAPI()
	registerEvent(mym, "onInputUpdate", "onInputUpdate")
  registerEvent(mym, "onDraw", "onDraw")
	registerEvent(mym, "onCameraDraw", "onCameraDraw")
  registerEvent(mym, "onKeyboardPressDirect", "onKeyboardPressDirect")
end

return mym
