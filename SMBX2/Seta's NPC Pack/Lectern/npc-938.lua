local lectern = {}

-- lectern.lua v1.0
-- Created by SetaYoshi

local npcManager = require("npcManager")
local textplus = require("textplus")
local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
  invisible = false,

	frames = 1,
	framespeed = 8,
	framestyle = 0,

	width = 32,
	height = 32,

	jumphurt = true,
  notcointransformable = true,
	nohurt = true,
	noyoshi = true,
  playerblocktop = true,
  npcblocktop = true,

  textboxwidth = 620
})

local sfxflip = Audio.SfxOpen(Misc.resolveFile("lectern-flip.wav"))
local font = textplus.loadFont("npc-"..npcID.."-font.ini")
local disabled = false

local function dataCheck(n)
  local data = n.data
  if not data.ini then
    data.ini = true

    data.page = data._settings.page or 1
    data.text = data._settings.text or ""
    data.animation = 0
    data.cooldown = 0

    data.pagetext = string.split(data.text, "|")
    data.layout = {}
    data.page = math.min(data.page, #data.pagetext)

    for k, v in ipairs(data.pagetext) do
      v = v:gsub("<vl>", "|")
      data.layout[k] = textplus.layout(v, config.textboxwidth, {xscale = 2, yscale = 2, font = font})
    end
  end
end

function lectern.onTickNPC(n)
  dataCheck(n)
  local data = n.data

  if data.cooldown ~= 0 then
    data.cooldown = data.cooldown - 1
  end
  data.on = false

	if not n.isHidden then
		for _, p in ipairs(Player.getIntersecting(n.x, n.y, n.x + n.width, n.y + n.height)) do
			data.on = true
			if data.cooldown == 0 then
				if p.keys.down == KEYS_PRESSED then
					if data.page < #data.pagetext then
						data.page = data.page + 1
						data.cooldown = 6
						SFX.play(sfxflip)
					end
				elseif p.keys.up == KEYS_PRESSED then
					if data.page > 1 then
						data.page = data.page - 1
						data.cooldown = 6
						SFX.play(sfxflip)
					end
				end
			end
		end
	end

  if data.on and data.animation < 1 then
    data.animation = math.min(1, data.animation + 0.07)
  elseif not data.on and data.animation > 0 then
    data.animation = math.max(0, data.animation - 0.12)
  end

  disabled = false
end



local color = Color(0.1, 0.1, 0.1, 0.8)
function lectern.onDrawNPC(n)
  local data = n.data
  if disabled then return end
  if data.on or data.animation > 0 then
    disabled = true
    local w = config.textboxwidth
    local layout = data.layout[data.page]
    Graphics.drawBox{x = 400 - w*0.5*data.animation, y = 100, width = w*data.animation, height = layout.height + 24, priority = 0, color = color}
    if data.animation > 0.95 then
      textplus.render{layout = layout, x = 400 - layout.width*0.5, y = 116, priority = 0}
      if #data.pagetext > 1 then
        textplus.print{text = data.page.."/"..#data.pagetext, x = 396 + 0.5*w, y = 100 + layout.height + 24, pivot = {1, 1}, font = font}
      end
    end
  end
end

function lectern.onInitAPI()
  npcManager.registerEvent(npcID, lectern, "onTickNPC")
  npcManager.registerEvent(npcID, lectern, "onDrawNPC")
end

return lectern
