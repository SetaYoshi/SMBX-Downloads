local listgen = {}

local textplus = require("textplus")
local click = require("click")

local arrowright = Graphics.loadImage(Misc.resolveFile("arrow-right.png"))
local arrowup = Graphics.loadImage(Misc.resolveFile("arrow-up.png"))
local arrowdown = Graphics.loadImage(Misc.resolveFile("arrow-down.png"))
local arrowuph = Graphics.loadImage(Misc.resolveFile("arrow-up-h.png"))
local arrowdownh = Graphics.loadImage(Misc.resolveFile("arrow-down-h.png"))

local folder = Graphics.loadImage(Misc.resolveFile("icon-folder.png"))
local file = Graphics.loadImage(Misc.resolveFile("icon-level.png"))

local scroll = Audio.SfxOpen(Misc.resolveFile("scroll.wav"))
local usingcursor = false

local FILE_FOLDER = 1
local FILE_LEVEL = 2

listgen.create = function(p)
  local t = table.clone(p)
	t.width = t.width or 170
  t.option = 1
  t.listoffset = 0
  t.arrowoffset = 0
  t.movetimer = 0
	t.cursortimer = 0
	t.wrapcooldown = false
  t.textoffset = 0
  t.texttimer = 0
  t.textcooldown = 0
  t.update = function()
    t.maxarrowoffset = math.min(t.maxlines, #t.list) - 1
    t.maxlistoffset = math.max(0, #t.list - t.maxlines)
    t.arrowoffset = math.clamp(0, t.arrowoffset, t.maxarrowoffset)
    t.listoffset = math.clamp(0, t.listoffset, t.maxlistoffset)
    t.textoffset = 0
    t.texttimer = 0
    t.option = t.arrowoffset + t.listoffset + 1
  end
  t.draw = function(x, y, z, pref)
		if t.listoffset ~= 0 then
		  Graphics.drawImageWP(arrowup, x + t.width*0.5 - arrowup.width*0.5, y + 6, z)
		else
			Graphics.drawImageWP(arrowuph, x + t.width*0.5 - arrowup.width*0.5, y + 6, z)
	  end
		if t.listoffset ~= t.maxlistoffset then
		  Graphics.drawImageWP(arrowdown, x + t.width*0.5 - arrowdown.width*0.5, y + t.textspacing*(t.maxlines) + 18, z)
		else
			Graphics.drawImageWP(arrowdownh, x + t.width*0.5 - arrowdown.width*0.5, y + t.textspacing*(t.maxlines) + 18, z)
	  end
		Graphics.drawImageWP(arrowright, x + 6, y + t.textspacing*(t.arrowoffset + 1) + 2, z)
    for i = 1, t.maxarrowoffset + 1 do
			local args = {}
      args.text = t.list[i + t.listoffset] or "ERROR"
			args.x = x + 54
			args.y = y + t.textspacing*(i - 1) + 22
			args.priority = z
			args.xscale = t.textscale
			args.yscale = t.textscale
      args.font = t.font
      if t.icon[i + t.listoffset] == FILE_FOLDER and not t.drawonlyoption then
        Graphics.drawImageWP(folder, x + 22, y + t.textspacing*(i - 1) + 22, z)
      elseif t.icon[i + t.listoffset] == FILE_LEVEL and (t.drawonlyoption and t.listoffset + i == t.option or not t.drawonlyoption) then
        Graphics.drawImageWP(file, x + 22, y + t.textspacing*(i - 1) + 22, z)
      end
      if t.listoffset + i == t.option then
        args.color = Color.green
      elseif t.drawonlyoption then
        args.color = Color(0, 0, 0, 0)
      end
      if string.len(args.text) > 36 then
        if t.listoffset + i == t.option then
          t.texttimer = t.texttimer + 1
          if t.texttimer == 60 or (t.texttimer > 60 and t.texttimer%20 == 0) then
            if 36 + t.textoffset >= string.len(args.text) then
              t.textcooldown = t.textcooldown + 1
              if t.textcooldown > 3 then
                t.textcooldown = 0
                t.textoffset = 0
                t.texttimer = 0
              end
            else
              t.textoffset = t.textoffset + 1
            end
          end
          args.text = string.sub(args.text, 1 + t.textoffset, 36 + t.textoffset)
        else
          args.text = string.sub(args.text, 1, 33).."..."
        end
      end
      args.plaintext = true
      textplus.print(args)
    end
  end
  t.move = function(n, allowloop, allowsound)
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
      t.textcooldown = 0
    else
      local newarrowoffset = t.arrowoffset + n
      t.arrowoffset = math.clamp(newarrowoffset, 0, t.maxarrowoffset)
      if newarrowoffset ~= t.arrowoffset then
        t.listoffset = math.clamp(t.listoffset + newarrowoffset - t.arrowoffset, 0, t.maxlistoffset)
      end
    end
    if not allowsound then
      SFX.play(scroll)
    end
    t.textoffset = 0
    t.texttimer = 0
    t.textcooldown = 0
    t.option = t.arrowoffset + t.listoffset + 1
  end
  t.basiccontrol = function(p)
    if click.click or click.speedX ~= 0 or click.speedY ~= 0 then usingcursor = true end
    if p.rawKeys.up then
			t.wrapcooldown = true
      usingcursor = false
      t.movetimer = t.movetimer + 1
      if t.movetimer == 1 then
        t.move(-1, true)
      elseif (t.movetimer > 20 and t.movetimer%5 == 0) then
        t.move(-1, false)
      end
    elseif p.rawKeys.down then
			t.wrapcooldown = true
      usingcursor = false
      t.movetimer = t.movetimer + 1
      if t.movetimer == 1 then
        t.move(1, true)
      elseif (t.movetimer > 20 and t.movetimer%5 == 0) then
        t.move(1, false)
      end
    elseif p.rawKeys.left then
      t.wrapcooldown = true
      usingcursor = false
      t.movetimer = t.movetimer + 1
      if t.movetimer == 1 then
        t.move(-17, true)
      elseif (t.movetimer > 20 and t.movetimer%5 == 0) then
        t.move(-17, false)
      end
    elseif p.rawKeys.right then
      t.wrapcooldown = true
      usingcursor = false
      t.movetimer = t.movetimer + 1
      if t.movetimer == 1 then
        t.move(17, true)
      elseif (t.movetimer > 20 and t.movetimer%5 == 0) then
        t.move(17, false)
      end
    else
      t.movetimer = 0
    end
	end
	t.basiccursor = function(x, y)
		local rv
		if click.box{x = x, y = y - 6, width = t.width, height = t.textspacing*(t.maxarrowoffset + 1) + 44} and usingcursor then
			local cx = click.x - x
			local cy = click.y - y - 18
      if (cy < 0 or cy > t.textspacing*(t.maxarrowoffset + 1)) and t.maxlistoffset > 0 then
        t.cursortimer = t.cursortimer + 1
        if click.click then t.wrapcooldown = false end
        if not t.wrapcooldown and (t.cursortimer > 10 and t.cursortimer%5 == 0) then
          local m = 1
          if click.hold then m = 3 end
          if cy < 0 then
            t.move(-m, false)
            t.arrowoffset = 0
          else
            t.move(m, false)
            t.arrowoffset = t.maxarrowoffset
          end
        elseif click.click and (t.listoffset == 0 or t.listoffset == t.maxlistoffset) and (t.arrowoffset == 0 or t.arrowoffset == t.maxarrowoffset) then
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
        if click.speedX ~= 0 or click.speedY ~= 0 or usingcursor then
          local prev = t.arrowoffset
          t.arrowoffset = math.clamp(math.floor(cy/t.textspacing), 0, t.maxarrowoffset)
          if prev ~= t.arrowoffset then
            SFX.play(scroll)
            t.textoffset = 0
            t.texttimer = 0
            t.textcooldown = 0
          end
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
