-- This library will be released in the future as a stand alone library. Currrently there is a lot of hardcoded data in this Library
-- It also needs optimizations and the such (like for example, how do you do "myList:draw()""? That might be a cool way to format the library)

local listgen = {}

local textplus = require("textplus")
local click = require("click")

local arrowright = Graphics.loadImage(GameData.SMBXLP_dir.."arrow-right.png")
local arrowup = Graphics.loadImage(GameData.SMBXLP_dir.."arrow-up.png")
local arrowdown = Graphics.loadImage(GameData.SMBXLP_dir.."arrow-down.png")
local arrowuph = Graphics.loadImage(GameData.SMBXLP_dir.."arrow-up-h.png")
local arrowdownh = Graphics.loadImage(GameData.SMBXLP_dir.."arrow-down-h.png")

local scroll = Audio.SfxOpen(GameData.SMBXLP_dir.."scroll.wav")

listgen.create = function(p)
  local t = table.clone(p)
	t.width = t.width or 170
  t.option = 1
  t.listoffset = 0
  t.arrowoffset = 0
  t.movetimer = 0
	t.cursortimer = 0
	t.wrapcooldown = false
  t.update = function()
    t.maxarrowoffset = math.min(t.maxlines, #t.list) - 1
    t.maxlistoffset = math.max(0, #t.list - t.maxlines)
  end
  t.draw = function(x, y, z, pref, data)
		if t.listoffset ~= 0 then
		  Graphics.drawImageWP(arrowup, x + t.width*0.5 - arrowup.width*0.5, y + 4, z)
		else
			Graphics.drawImageWP(arrowuph, x + t.width*0.5 - arrowup.width*0.5, y + 4, z)
	  end
		if t.listoffset ~= t.maxlistoffset then
		  Graphics.drawImageWP(arrowdown, x + t.width*0.5 - arrowdown.width*0.5, y + t.textspacing*(t.maxarrowoffset + 1) + 18, z)
		else
			Graphics.drawImageWP(arrowdownh, x + t.width*0.5 - arrowdown.width*0.5, y + t.textspacing*(t.maxarrowoffset + 1) + 18, z)
	  end
		Graphics.drawImageWP(arrowright, x, y + t.textspacing*(t.arrowoffset + 1), z)
    for i = 1, t.maxarrowoffset + 1 do
			local args = {}
      args.text = t.list[i + t.listoffset] or "ERROR"
			if pref then
				args.text, args.color, args.plaintext = pref(t.listoffset + i, args.text, data)
			end
      if args.plaintext == nil then args.plaintext = true end
			args.x = x + 18
			args.y = y + t.textspacing*(i - 1) + 22
			args.priority = z
			args.xscale = t.textscale
			args.yscale = t.textscale
      textplus.print(args)
    end
  end
  t.move = function(n, allowloop)
    local listsize = #t.list
    if t.arrowoffset == 0 and t.listoffset == 0 and  n < 0 then
			if not allowloop then return end
			SFX.play(scroll)
      t.arrowoffset = t.maxarrowoffset
      t.listoffset = t.maxlistoffset
    elseif t.arrowoffset == t.maxarrowoffset and t.listoffset == t.maxlistoffset and n > 0 then
			if not allowloop then return end
			SFX.play(scroll)
      t.arrowoffset = 0
      t.listoffset = 0
    else
      local newarrowoffset = t.arrowoffset + n
      t.arrowoffset = math.clamp(newarrowoffset, 0, t.maxarrowoffset)
      if newarrowoffset ~= t.arrowoffset then
        t.listoffset = math.clamp(t.listoffset + newarrowoffset - t.arrowoffset, 0, t.maxlistoffset)
      end
    end

		SFX.play(scroll)
    t.option = t.arrowoffset + t.listoffset + 1
  end
  t.basiccontrol = function(p)
    if p.rawKeys.up then
			t.wrapcooldown = true
      t.movetimer = t.movetimer + 1
      if t.movetimer == 1 then
        t.move(-1, true)
      elseif (t.movetimer > 20 and t.movetimer%5 == 0) then
        t.move(-1, false)
      end
    elseif p.rawKeys.down then
			t.wrapcooldown = true
      t.movetimer = t.movetimer + 1
      if t.movetimer == 1 then
        t.move(1, true)
      elseif (t.movetimer > 20 and t.movetimer%5 == 0) then
        t.move(1, false)
      end
    else
      t.movetimer = 0
    end
	end
	t.basiccursor = function(x, y)
		local rv
		if click.box{x = x, y = y - 6, width = t.width, height = t.textspacing*(t.maxarrowoffset + 1) + 44} then
			local cx = click.x - x
			local cy = click.y - y - 18
			if cy < 0 or cy > t.textspacing*(t.maxarrowoffset + 1) then
				t.cursortimer = t.cursortimer + 1
				if click.click and t.maxlistoffset > 0 and (t.listoffset == 0 or t.listoffset == t.maxlistoffset) and not t.wrapcooldown then
          local m = 1
          if click.hold then m = 2 end
					if cy < 0 then
						t.move(-m, true)
					else
						t.move(m, true)
					end
					t.wrapcooldown = true
				elseif not t.wrapcooldown and (t.cursortimer == 1 or (t.cursortimer > 10 and t.cursortimer%5 == 0)) then
					if cy < 0 then
						t.move(-1, false)
					else
						t.move(1, false)
					end
				end
			else
				t.cursortimer = 0
				t.wrapcooldown = false
				if click.speedX ~= 0 or click.speedY ~= 0 then
					local prev = t.arrowoffset
					t.arrowoffset = math.clamp(math.floor(cy/t.textspacing), 0, t.maxarrowoffset)
					if prev ~= t.arrowoffset then SFX.play(scroll) end
				end
				if click.click then
					rv = true
				end
			end
      t.option = t.arrowoffset + t.listoffset + 1
		else
			t.cursortimer = 0
			t.wrapcooldown = false
		end
		return rv
	end
  t.basiccursor = function(x, y)
    local rv
    if click.box{x = x, y = y - 6, width = t.width, height = t.textspacing*(t.maxarrowoffset + 1) + 44} then
      local cx = click.x - x
      local cy = click.y - y - 18
      if (cy < 0 or cy > t.textspacing*(t.maxarrowoffset + 1)) and t.maxlistoffset > 0 then
        t.cursortimer = t.cursortimer + 1
        if click.click then t.wrapcooldown = false end
        if not t.wrapcooldown and (t.cursortimer > 10 and t.cursortimer%5 == 0) then
          local m = 1
          if click.hold then m = 2 end
          if cy < 0 then
            t.move(-m, false)
            t.arrowoffset = 0
          else
            t.move(m, false)
            t.arrowoffset = t.maxarrowoffset
          end
        end
        if click.click and (t.listoffset == 0 or t.listoffset == t.maxlistoffset) and (t.arrowoffset == 0 or t.arrowoffset == t.maxarrowoffset) then
          if cy < 0 and t.listoffset == 0 and t.arrowoffset == 0 then
            t.move(-1, true)
            t.wrapcooldown = true
          elseif cy > 0 and t.listoffset == t.maxlistoffset and t.arrowoffset == t.maxarrowoffset then
            t.move(1, true)
            t.wrapcooldown = true
          end
        end
      else
        t.cursortimer = 0
        t.wrapcooldown = false
        if click.speedX ~= 0 or click.speedY ~= 0 then
          local prev = t.arrowoffset
          t.arrowoffset = math.clamp(math.floor(cy/t.textspacing), 0, t.maxarrowoffset)
          if prev ~= t.arrowoffset then SFX.play(scroll) end
        end
        if click.click then
          rv = true
        end
      end
      t.option = t.arrowoffset + t.listoffset + 1
    else
      t.cursortimer = 0
      t.wrapcooldown = false
    end
    return rv
  end
  t.update()
  return t
end

return listgen
