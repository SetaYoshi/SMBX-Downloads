local lectern = {}

local redstone = require("redstone")
local npcManager = require("npcManager")
local textplus = require("textplus")

local clamp, ceil, min, max = math.clamp, math.ceil, math.min, math.max
local split = string.split

lectern.name = "lectern"
lectern.id = NPC_ID
lectern.order = 0.70

lectern.onRedPower = function(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

lectern.onRedInventory = function(n, c, inv, dir, hitbox)
  local data = n.data
  data.page = clamp(inv, 1, #data.pagetext)
end

lectern.config = npcManager.setNpcSettings({
	id = lectern.id,

  width = 32,
  height = 32,

	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 1,
	framespeed = 8,
	framestyle = 0,
  invisible = false,
  mute = false,

	jumphurt = true,
  notcointransformable = true,
	nohurt = true,
	noyoshi = true,
  playerblocktop = true,
  npcblocktop = true,

  textboxwidth = 620  -- Determines the width of the textbox shown
})

local sfxflip = Audio.SfxOpen(Misc.resolveFile("lectern-flip.ogg"))
local font = textplus.loadFont("npc-"..lectern.id.."-font.ini")
local textbox = {animation = 0, layout = {}, color = Color(0.1, 0.1, 0.1, 0.8), found = false, lectern = {}}

function lectern.prime(n)
  local data = n.data

  data.animFrame = data.animFrame or 0
  data.animTimer = data.animTimer or 0

  data.frameX = data._settings.type or 0
  data.frameY = data.frameY or 0

  data.text = data._settings.text or ""
  data.cooldown = data.cooldown or 0
  data.pagetext = split(data.text, "|")
  data.page = clamp(data._settings.page or 1, 1, #data.pagetext)

  data.layout = {}
  for k, v in ipairs(data.pagetext) do
    v = v:gsub("<pipe>", "|")
    data.layout[k] = textplus.layout(v, lectern.config.textboxwidth, {xscale = 2, yscale = 2, font = font})
  end

  if data._settings.texture and data._settings.texture ~= "" then
    data.texture = Graphics.loadImage(Misc.multiResolveFile(data._settings.texture, data._settings.texture..".png"))
  end

  data.redhitbox = redstone.basicDirectionalRedHitBox(n, 3)
  data.observ = true
  data.invspace = true
end

local function updateTextBox(n)
  textbox.layout = n.data.layout[n.data.page]
  textbox.lectern = n
  textbox.texture = n.data.texture
  textbox.found = true
end

local function updatePage(n, amount)
  local data = n.data
  local prevpage = data.page

  data.page = clamp(data.page + amount, 1, #data.pagetext)
  if data.page ~= prevpage then
    data.cooldown = 6
    data.observpower = ceil(15*data.page/#data.pagetext)
    if not redstone.isMuted(n) then
      SFX.play(sfxflip)
    end
  end
end

function lectern.onRedTick(n)
  local data = n.data

  redstone.applyFriction(n)
  data.observpower = ceil(15*data.page/#data.pagetext)

  redstone.updateDirectionalRedHitBox(n, 3)
  local passed = redstone.passInventory{source = n, npcList = redstone.id.hopper, inventory = data.page, hitbox = data.redhitbox}

  if data.cooldown ~= 0 then
    data.cooldown = data.cooldown - 1
  end

  if not textbox.found and data.power > 0 then
    updateTextBox(n)
  end

  redstone.resetPower(n)
end

function lectern.onTick()
  if not textbox.found then
    for _, p in ipairs(Player.get()) do
      local list = Colliders.getColliding{a = p, b = lectern.id, btype = Colliders.NPC, filter = redstone.nothidden}
      if list[1] then
        local n, data = list[1], list[1].data

        if data.cooldown == 0 then
          if p.keys.down == KEYS_PRESSED then
            updatePage(n, 1)
          elseif p.keys.up == KEYS_PRESSED then
            updatePage(n, -1)
          end
        end

        updateTextBox(n)
        break
      end
    end
  end

  if textbox.found and textbox.animation < 1 then
    textbox.animation = min(1, textbox.animation + 0.07)
  elseif not textbox.found and textbox.animation > 0 then
    textbox.animation = max(0, textbox.animation - 0.12)
  end
end

lectern.onRedDraw = redstone.drawNPC


-- Big thanks to MDA for supplying this function
local function drawSegmentedBox(args)
  local texture = args.texture or args.image
  local target = args.target or nil

  local priority = args.priority or 0
  local sceneCoords = args.sceneCoords or false
  local color = args.color or Color.white

  local x = args.x
  local y = args.y
  local width = args.width
  local height = args.height

  local segmentWidth = texture.width / 3
  local segmentHeight = texture.height / 3

  local segmentCountX = ceil(width / segmentWidth)
  local segmentCountY = ceil(height / segmentHeight)


  local vertexCoords = {}
  local textureCoords = {}
  local vertexCount = 0

  for segmentX = 1,segmentCountX do
    for segmentY = 1,segmentCountY do
      local thisX = x
      local thisY = y
      local thisWidth = min(width*0.5,segmentWidth)
      local thisHeight = min(height*0.5,segmentHeight)
      local thisSourceX = 0
      local thisSourceY = 0

      if segmentX == segmentCountX then
        thisX = thisX + width - thisWidth
        thisSourceX = texture.width - thisWidth
      elseif segmentX > 1 then
        thisX = thisX + thisWidth + (segmentX-2)*segmentWidth
        thisWidth = min(width - segmentWidth - (thisX - x),segmentWidth)
        thisSourceX = segmentWidth
      end

      if segmentY == segmentCountY then
        thisY = thisY + height - thisHeight
        thisSourceY = texture.height - thisHeight
      elseif segmentY > 1 then
        thisY = thisY + thisHeight + (segmentY-2)*segmentHeight
        thisHeight = min(height - segmentHeight - (thisY - y),segmentHeight)
        thisSourceY = segmentHeight
      end


      if thisWidth > 0 and thisHeight > 0 then
        -- Add to vertexCoords
        local x1 = thisX
        local y1 = thisY
        local x2 = thisX + thisWidth
        local y2 = thisY + thisHeight

        vertexCoords[vertexCount+1 ] = x1 -- top left
        vertexCoords[vertexCount+2 ] = y1
        vertexCoords[vertexCount+3 ] = x1 -- bottom left
        vertexCoords[vertexCount+4 ] = y2
        vertexCoords[vertexCount+5 ] = x2 -- top right
        vertexCoords[vertexCount+6 ] = y1
        vertexCoords[vertexCount+7 ] = x1 -- bottom left
        vertexCoords[vertexCount+8 ] = y2
        vertexCoords[vertexCount+9 ] = x2 -- top right
        vertexCoords[vertexCount+10] = y1
        vertexCoords[vertexCount+11] = x2 -- bottom right
        vertexCoords[vertexCount+12] = y2

        -- Add to textureCoords
        local x1 = thisSourceX / texture.width
        local y1 = thisSourceY / texture.height
        local x2 = (thisSourceX + thisWidth) / texture.width
        local y2 = (thisSourceY + thisHeight) / texture.height

        textureCoords[vertexCount+1 ] = x1 -- top left
        textureCoords[vertexCount+2 ] = y1
        textureCoords[vertexCount+3 ] = x1 -- bottom left
        textureCoords[vertexCount+4 ] = y2
        textureCoords[vertexCount+5 ] = x2 -- top right
        textureCoords[vertexCount+6 ] = y1
        textureCoords[vertexCount+7 ] = x1 -- bottom left
        textureCoords[vertexCount+8 ] = y2
        textureCoords[vertexCount+9 ] = x2 -- top right
        textureCoords[vertexCount+10] = y1
        textureCoords[vertexCount+11] = x2 -- bottom right
        textureCoords[vertexCount+12] = y2

        vertexCount = vertexCount + 12
      end
    end
  end

  Graphics.glDraw{
    texture = texture,target = target,
    priority = priority,sceneCoords = sceneCoords,color = color,
    vertexCoords = vertexCoords,
    textureCoords = textureCoords,
  }
end


function lectern.onDraw()
  if textbox.found or textbox.animation > 0 then
    textbox.found = false
    local width, animation, layout, n = lectern.config.textboxwidth, textbox.animation, textbox.layout, textbox.lectern

    local color
    if textbox.texture then
      drawSegmentedBox{texture = textbox.texture, x = 400 - width*0.5*animation, y = 100, width = width*animation, height = layout.height + 24, priority = 0}
    else
      Graphics.drawBox{x = 400 - width*0.5*animation, y = 100, width = width*animation, height = layout.height + 24, priority = 0, color = textbox.color}
    end


    -- local w, h = vector(width*animation, 0), vector(0, layout.height + 24)
    -- local z1 = vector(, )
    -- local z2, z3, z4 = z1 + w, z1 + h, z1 + w + h
    --
    -- Graphics.glDraw{}
    -- texture = textbox.texture, priority = 0, color = color, vertexCoords = {z1.x, z1.y, z2.x, z2.y, z4.x, z4.y, z1.x, z1.y, z3.x, z3.y, z4.x, z4.y}, textureCoords = {0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1}}

    if animation > 0.95 then
      textplus.render{layout = layout, x = 400 - layout.width*0.5, y = 116, priority = 0}
      if #n.data.pagetext > 1 then
        textplus.print{text = n.data.page.."/"..#n.data.pagetext, x = 396 + 0.5*width, y = 100 + layout.height + 24, pivot = {1, 1}, font = font}
      end
    end
  end
end

function lectern.onInitAPI()
  registerEvent(lectern, "onTick", "onTick")
  registerEvent(lectern, "onDraw", "onDraw")
end

redstone.register(lectern)


return lectern
