local events = {}

events.active = {}

local NPCs
function events.setID(t)
  NPCs = t
end

local inputs2 = API.load("inputs2")
local colliders = API.load("colliders")
local eventu = API.load("eventu")
local animDraw = API.load("animDraw")
local textblox = API.load("l_textblox")
local rng = API.load("rng")
local lunajson = API.load("ext/lunajson")
local imagic = API.load("imagic")
local paralx = API.load("l_paralx")

local back = paralx.create{image = Graphics.loadImage("back-1.png"), y = 0, priority = -80, repeatY = false, repeatX = true, parallaxX = 0.25, parallaxY = 0}
local front = paralx.create{image = Graphics.loadImage("back-2.png"), y = 0, priority = -80, repeatY = false, repeatX = true, parallaxX = 0.30, parallaxY = 0}

inputs2.locked[1].altjump = true
inputs2.locked[1].down = true

local handler = {}
local playerinstate = false
local direction = -1

events.SECTION_BOTTOM = -200192
events.SECTION_TOP = -200794
events.SECTION_LEFT = -201894
events.SECTION_RIGHT = events.SECTION_LEFT

local FLAGPOS = {
  left = {x = 0, y = 0},
  right = {x = 0, y = 0}
}

local queque = {}
local quequePow = {}
local powNum = {[4] = true, [8] = true, [12] = true, [15] = true}


local hud = {}
hud.flag = 0
hud.flag_icon = Graphics.loadImage("hud-flag.png")
hud.flag_x = 10
hud.flag_y = 4
hud.timeM = 25
hud.time = hud.timeM
hud.time_icon = Graphics.loadImage("hud-time.png")
hud.time_cooldownM = 65
hud.time_cooldown = hud.time_cooldownM
hud.time_x = 700
hud.time_y = 4

local help = {}
help.active = false
help.placement = 1
help.box = Graphics.loadImage("box.png")
help.list = {}


local blocks = {}
blocks[054] = 42 -- Dirt Top
blocks[052] = 42 -- Dirt Mid
blocks[048] = 42 -- Dirt Mid Grass
blocks[125] = 84 -- Dirt Mid Big
blocks[610] = 42 -- Stone

local death = {}
death.timer = 0
death.effectImages = animDraw.load{"death-effect-1","death-effect-2"}
death.circle = Graphics.loadImage("death-circle.png")
death.effectPos = {}

function read_file(path)
  local file = io.open(path, "rb") -- r read mode and b binary mode
  if not file then return nil end
  local content = file:read "*a" -- *a or *all reads the whole file
  file:close()
  return content
end

local islandext = {}
local str = read_file(Misc.resolveFile("ext.json"))
str = str:gsub(" ", "")
str = str:gsub("\n", "")
str = str:gsub("\t", "")
str = str:gsub("\v", "")
-- Text.windowDebug(str)
islandext.list = lunajson.decode(str)
islandext.onLoop = false
islandext.remain = {}
islandext.insert = function(index)
  local myList = islandext.list[index]
  local myDir
  if direction == 1 then
    myDir = events.SECTION_LEFT
  else
    myDir = events.SECTION_RIGHT
    back.x = back.x + myList.width*back.parallaxX
    front.x = front.x + myList.width*front.parallaxX
  end
  for _, v in ipairs(Block.get()) do
    if v.x >= myDir then
      v.x = v.x + myList.width
    end
  end
  for _, v in ipairs(NPC.get()) do
    if v.x >= myDir then
      v.x = v.x + myList.width
    end
  end
  if player.x >= myDir then
    player.x = player.x + myList.width
  end
  events.SECTION_RIGHT = events.SECTION_RIGHT + myList.width
  FLAGPOS.right.x = FLAGPOS.right.x + myList.width
  for _, v in pairs(myList.blocks) do
     local b = Block.spawn(v[1], myDir + v[2], events.SECTION_TOP + v[3])
      b:mem(0x30, FIELD_DFLOAT, blocks[v[1]])
      b:mem(0x38, FIELD_DFLOAT, blocks[v[1]])
  end
  for _, v in pairs(myList.npcs) do
    NPC.spawn(v[1], myDir + v[2], events.SECTION_TOP + v[3], 0)
  end
end

local tide = {}
tide.y = 42*1.5
tide.image = Graphics.loadImage("water.png")
tide.timer = 0
tide.func = function()
    tide.timer = tide.timer + 0.02
    tide.y = tide.y + math.sin(tide.timer)
end

local drawBox = {}
drawBox.text = ""
drawBox.icon = Graphics.loadImage("blank.png")
drawBox.texture = Graphics.loadImage("textbox.png")
drawBox.width = 462
drawBox.height = 63
drawBox.animationState = 0
drawBox.animationTimer = 0
drawBox.y = 600
drawBox.font = textblox.defaultSpritefont[7][2]

local doublejump = {}
doublejump.used = false
doublejump.radius = 108
doublejump.explosion = {}
doublejump.explosion.images = animDraw.load{"explosion-1","explosion-2","explosion-3","explosion-4","explosion-5","explosion-6", "explosion-7"}
doublejump.explosion.x = 0
doublejump.explosion.y = 0
doublejump.explosion.timer = 0
doublejump.draw = function()
  if doublejump.explosion.timer > 0 then
    local img = animDraw.get("explosion")
    doublejump.explosion.timer = doublejump.explosion.timer - 1
    Graphics.drawImageToSceneWP(img, doublejump.explosion.x - img.width/2, doublejump.explosion.y - img.height/2, 0)
  end
end
doublejump.func = function()
  if player:isGroundTouching() then
    doublejump.used = false
  else
    local jumpstate = inputs2.state[1].jump
    if not (playerinstate or doublejump.used) and (jumpstate == inputs2.PRESS or (jumpstate == inputs2.HOLD and player.speedY >= 0)) and doublejump.explosion.timer == 0 then
      doublejump.used = true
      playerinstate = "doublejump"
      Defines.earthquake = 15
      Audio.playSFX(43)
      eventu.setFrameTimer(1, function() Defines.earthquake = 10 end, 5)
      eventu.setFrameTimer(1, function() player.speedY = -0.4 end, 6)
      eventu.setFrameTimer(7, function()
        player.speedY = -10
        Defines.earthquake = 8
        if playerinstate == "doublejump" then
          playerinstate = false
        end
      end)
      doublejump.explosion.x = player.x + player.width/2
      doublejump.explosion.y = player.y + player.height
      doublejump.explosion.timer = #doublejump.explosion.images*2
      animDraw.new("explosion", doublejump.explosion.images, 2)
      local circ = colliders.Circle(doublejump.explosion.x, doublejump.explosion.y, doublejump.radius)
      for _, n in ipairs(NPC.get(NPCs.enemy)) do
        if not n.friendly and colliders.collide(circ, n) and n.id ~= 178 then
          n:harm(HARM_TYPE_PROJECTILE_USED)
        end
      end
    end
  end
end

local airdash = {}
airdash.inuse = false
airdash.direction = 1
airdash.imagesL = animDraw.load{"airdash-1L"}
airdash.imagesR = animDraw.load{"airdash-1R"}
animDraw.new("airdashL", airdash.imagesL, 2)
animDraw.new("airdashR", airdash.imagesR, 2)
airdash.draw = function()
  if playerinstate == "airdash" then
    local S
    if airdash.direction == 1 then
      S = "R"
    else
      S = "L"
    end
    Graphics.drawImageToSceneWP(animDraw.get("airdash"..S), player.x - 4, player.y, 0.1)
  end
end
airdash.func = function()
  if not (playerinstate or airdash.used) and inputs2.state[1].run == inputs2.PRESS then
    airdash.used = true
    airdash.direction = player:mem(0x106, FIELD_WORD)
    playerinstate = "airdash"
    player.y = player.y - 6
    Audio.playSFX(88)
    inputs2.locked[1].left = true
    inputs2.locked[1].right = true
    Defines.player_runspeed = 6
    Defines.player_walkspeed = 6
    eventu.setFrameTimer(1, function()
      player.speedX = 6*airdash.direction
      player.speedY = -0.48
      airdash.used = true
    end, 15)
    eventu.setFrameTimer(16, function()
    Defines.player_runspeed = 4
    Defines.player_walkspeed = 4
      player.speedX = 2.5*airdash.direction
      player.speedY = -6
      inputs2.locked[1].left = false
      inputs2.locked[1].right = false
    end)
    eventu.setFrameTimer(17, function()
      if playerinstate == "airdash" then
        playerinstate = false
      end
    end)
  end
  if player:isGroundTouching() then
    airdash.used = false
  end
end

local groundpound = {}
groundpound.images = animDraw.load{"groundpound-1"}
animDraw.new("groundpound", groundpound.images, 2)
groundpound.draw = function()
  if playerinstate == "groundpound" and player.speedY > 0 then
    Graphics.drawImageToSceneWP(animDraw.get("groundpound"), player.x - 4, player.y, 0)
  end
end
groundpound.func = function()
  if player:isGroundTouching() then
    if groundpound.used then
      Defines.cheat_donthurtme = false
      Defines.earthquake = 15
      Defines.gravity = 8
      Audio.playSFX(37)
      Animation.spawn(125, player.x + 12, player.y + 42)
      eventu.setFrameTimer(1, function() player.speedX = 0 end, 15)
      eventu.setFrameTimer(16, function() playerinstate = false end)
      local sqr = colliders.Box(player.x - 32, player.y + player.width/2, player.width + 64, player.height/2)
      for _, n in ipairs(NPC.get(NPCs.enemy)) do
        if not n.friendly and colliders.collide(sqr, n) and n.id ~= 178 then
          n:harm(HARM_TYPE_PROJECTILE_USED)
        end
      end
    end
    groundpound.used = false
  elseif playerinstate and groundpound.used then
    player.speedX = player.speedX*0.95
    if player.speedY <= 0 then
      player.speedY = player.speedY + 0.5
    else
      player.speedY = player.speedY*1.2
    end
    local sqr = colliders.Box(player.x - 2, player.y - 2, player.width + 4, player.height + player.speedY + 16)
    for _, n in ipairs(NPC.get(NPCs.enemy)) do
      if not n.friendly and colliders.collide(sqr, n) and n.id ~= 178 then
        n:harm(HARM_TYPE_PROJECTILE_USED)
      end
    end
  else
    if not (playerinstate or groundpound.used) and inputs2.state[1].altjump == inputs2.HOLD then
      groundpound.used = true
      playerinstate = "groundpound"
      Defines.cheat_donthurtme = true
      player.speedY = -10
      Defines.gravity = 45
      Audio.playSFX(26)
    end
  end
end

local glide = {}
glide.used = false
glide.timer = 0
glide.onDown = false
glide.images = animDraw.load{"glide-1"}
animDraw.new("glide", glide.images, 2)
glide.draw = function()
  if playerinstate == "glide" then
    Graphics.drawImageToSceneWP(animDraw.get("glide"), player.x - 4, player.y + 16, 0)
  end
end
glide.func = function()
  if player:isGroundTouching() then
    glide.onDown = false
    glide.timer = 0
    if playerinstate == "glide" then
      playerinstate = false
    end
  else
    if not playerinstate and inputs2.state[1].up == inputs2.PRESS then
      playerinstate = "glide"
      glide.used = true
      if glide.timer == 0 then
        Audio.playSFX(33)
      end
    elseif playerinstate == "glide" then
      if glide.onDown then
        player.speedY = player.speedY - 0.36
      else
        player.speedY = player.speedY/2 - 0.8
        glide.timer = glide.timer + 1
        if glide.timer == 60 then
          glide.onDown = true
          Audio.playSFX(34)
        end
      end
      if inputs2.state[1].up == inputs2.RELEASE then
        playerinstate = false
      end
    end
  end
end

local shield = {}
shield.used = false
shield.images = {
  [-1] = Graphics.loadImage("shield-L.png"),
  [1] = Graphics.loadImage("shield-R.png")
}
shield.draw = function()
  if not shield.used then
    local dir = player:mem(0x106, FIELD_WORD)
    Graphics.drawImageToSceneWP(shield.images[dir], player.x + dir*16, player.y + 2, -2)
  end
end
shield.func = function()
  if not shield.used and events.active["shield"] and player.powerup == PLAYER_SMALL then
    player.powerup = PLAYER_BIG
    shield.used = true
    player:mem(0x122, FIELD_WORD, 0)
    player:mem(0x140, FIELD_WORD, 150)
  end
end


events.list = {}
events.list["doublejump"] = {
  name = "Bomb Jump",
  icon = Graphics.loadImage("icon-doublejump.png"),
  desc =  "Jump in the air to create an explosion that will launch you into the air",
  powerup = true,
  tick = doublejump.func,
  draw = doublejump.draw
}
events.list["airdash"] = {
  name = "Air Dash",
  icon = Graphics.loadImage("icon-airdash.png"),
  desc = "Use your run key to dash foward at a high speed",
  powerup = true,
  tick = airdash.func,
  draw = airdash.draw
}
events.list["groundpound"] = {
  name = "Ground Quake",
  icon = Graphics.loadImage("icon-groundpound.png"),
  desc = "Use your alt-jump key to slam into the ground stomping everything in your path",
  powerup = true,
  tick = groundpound.func,
  draw = groundpound.draw
}
events.list["glide"] = {
  name = "Cloud Nine",
  icon = Graphics.loadImage("icon-glide.png"),
  desc = "Hold the up key in the air to float in the air",
  powerup = true,
  tick = glide.func,
  draw = glide.draw
}
events.list["shield"] = {
  name = "Shield",
  icon = Graphics.loadImage("icon-shield.png"),
  desc = "Hold a shield that will grant you an extra hit",
  powerup = true,
  tick = shield.func,
  draw = shield.draw
}
events.list["weakbridge"] = {
  name = "Weak Bridges",
  icon = Graphics.loadImage("icon-weakbridge.png"),
  desc = "Bridge pieces will now fall when stpped on"
}
events.list["rustystone"] = {
  name = "Rusty Stones",
  icon = Graphics.loadImage("icon-rustystone.png"),
  desc = "Stones will now fall when you are below them or stepping on them"
}
events.list["sawdisk"] = {
  name = "Saw Disks",
  icon = Graphics.loadImage("icon-sawdisk.png"),
  desc = "Indestructible spiky saws"
}
events.list["carefreepangolins"] = {
  name = "Carefree Pangolins",
  icon = Graphics.loadImage("icon-carefreepangolins.png"),
  desc = "A simple enemy that walks foward"
}
events.list["starvingpiranha"] = {
  name = "Starving Piranha",
  icon = Graphics.loadImage("icon-starvingpiranha.png"),
  desc = "A piranha that will hop out of the water periodically"
}
events.list["armoredbeetle"] = {
  name = "Armored Beetles",
  icon = Graphics.loadImage("icon-armoredbeetle.png"),
  desc = "A spiky beetle that walks foward"
}
events.list["doublesidedcannon"] = {
  name = "Double-sided Cannon",
  icon = Graphics.loadImage("icon-doublesidedcannon.png"),
  desc = "A cannon that will shoot bullets in alternating directions"
}
events.list["potatospitter"] = {
  name = "Potato Spitters",
  icon = Graphics.loadImage("icon-potatospitter.png"),
  desc = "A mystical penguin that will shoot steamy potatos towards you"
}
events.list["flyingdrunkard"] = {
  name = "Flying Drunkard",
  icon = Graphics.loadImage("icon-flyingdrunkard.png"),
  desc = "A lakitu in its natural state",
  func = function()
    NPC.spawn(130, events.SECTION_RIGHT, events.SECTION_TOP + 42*4, 0)
  end
}
events.list["tide"] = {
  name = "High Tide",
  icon = Graphics.loadImage("icon-tide.png"),
  desc = "The tide will now slowly move up and down",
  tick = tide.func
}
events.list["islandext"] = {
  name = "Island Extension",
  icon = Graphics.loadImage("icon-islandext.png"),
  loop = true,
  desc = "The island will now expand",
  func = function()
    islandext.onLoop = true
  end
}

for k, v in pairs(events.list) do
  table.insert(help.list, {name = v.name, desc = v.desc, icon = v.icon, codename = k})
end
table.insert(help.list, 1, {name = "HELP", desc = "Use the up and down arrow keys to navigate. When an event is active, it will be listed with a [X]", icon = Graphics.loadImage("icon-help.png"), codename = "_"})
table.insert(help.list, 2, {name = "Objective", desc = "Run back and forth collecting flags before the timer runs out. Collecting 15 flags will finish the level", icon = Graphics.loadImage("icon-star.png"), codename = "objective"})

function shuffle(tbl)
  size = #tbl
  for i = size, 1, -1 do
    local rand = rng.randomInt(1, size)
    tbl[i], tbl[rand] = tbl[rand], tbl[i]
  end
  return tbl
end

function events.onStart()
  islandext.insert(1, 0)
  islandext.insert(2, 0)

  events.SECTION_LEFT = events.SECTION_LEFT + islandext.list[1].width
  events.SECTION_RIGHT = events.SECTION_LEFT
  FLAGPOS = {
    left = {x = events.SECTION_LEFT - 42*15, y = events.SECTION_BOTTOM - 42*6},
    right = {x = events.SECTION_RIGHT + 42*10, y = events.SECTION_BOTTOM - 42*12}
  }
  player.x = FLAGPOS.left.x
  player.y = FLAGPOS.left.y - 2

  table.remove(islandext.list, 2)
  table.remove(islandext.list, 1)
  for i = 1, #islandext.list do
    islandext.remain[i] = i
  end
  islandext.remain = shuffle(islandext.remain)
  direction = 1

  back.x = back.x + 800
  front.x = front.x + 800
end


handler.tick = {}
handler.draw = {}
for k, v in pairs(events.list) do
  if v.powerup then
    table.insert(quequePow, k)
  else
    table.insert(queque, k)
  end
  if v.tick then
    handler.tick[k] = v.tick
  end
  if v.draw then
    handler.draw[k] = v.draw
  end
  if not v.func then
    events.list[k].func = function() end
  end
end
shuffle(queque)
shuffle(quequePow)

function events.trigger(name)
  Audio.playSFX(12)
  events.list[name].func()
  events.active[name] = true
  drawBox.animationState = 2
  drawBox.icon = events.list[name].icon
  drawBox.text = events.list[name].name
end

function events.onLoop()
  if islandext.onLoop then
    islandext.onLoop = false
    islandext.insert(islandext.remain[1])
    table.remove(islandext.remain, 1)
    if islandext.remain[1] == nil then
      for i = 1, #islandext.list do
        islandext.remain[i] = i
      end
      islandext.remain = shuffle(islandext.remain)
    end
  end
end

function events.onTick()
  hud.time_cooldown = hud.time_cooldown - 1
  if hud.time > 0 and hud.time_cooldown == 0 and playerinstate ~= "dead" then
    hud.time = hud.time - 1
    hud.time_cooldown = hud.time_cooldownM
    if hud.time == 0 then
      shield.used = true
      player:harm()
    elseif hud.time <= 5 then
      Audio.playSFX(29)
      Defines.earthquake = 15 - 2*hud.time
    end
  end

  for k, v in pairs(handler.tick) do
    if events.active[k] then
      v()
    end
  end

  if player.powerup == PLAYER_SMALL and playerinstate ~= "dead" then
    playerinstate = "dead"
    death.timer = 1
    Audio.playSFX(57)
    eventu.setFrameTimer(25, function()
      player:kill()
    end)
  end

  if player.y + player.height >= events.SECTION_BOTTOM - tide.y then
    player.speedX = player.speedX*0.9
    player.speedY = player.speedY*0.9
  end

  if drawBox.animationState == 2 then
    if drawBox.y <= 520 then
      drawBox.animationState = 1
      drawBox.animationTimer = 116
    else
      drawBox.y = drawBox.y - 2
    end
  elseif drawBox.animationState == 1 then
    if drawBox.animationTimer == 0 then
      if drawBox.y >= 600 then
        drawBox.animationState = 0
      else
        drawBox.y = drawBox.y + 6
      end
    else
      drawBox.animationTimer = drawBox.animationTimer - 1
    end
  end
end

function events.onDraw()

  if death.timer > 0 then
    death.timer = death.timer + 1
    if death.timer < 30 then
      local s = 900*(30 - death.timer)/30
      imagic.Draw{width = s, height = s, x = player.x + player.width/2 - s/2, y = player.y + player.height/2 - s/2, texture = death.circle, scene = true}
    elseif death.timer == 30 then
      Audio.playSFX(35)
      animDraw.new("death", death.effectImages, 8)
      local x = player.x + 5
      local y = player.y + 5
      for i = 1, 8 do
        death.effectPos[i] = {x = x, y = y, a = (i - 1)*math.pi/4}
      end
    elseif death.timer > 30 then
      local img = animDraw.get("death")
      local r = 100/((death.timer - 10) + 8)
      for k, v in ipairs(death.effectPos) do
        Graphics.drawImageToSceneWP(img, v.x, v.y, 0)
        death.effectPos[k].x = v.x + r*math.cos(v.a)
        death.effectPos[k].y = v.y + r*math.sin(v.a)
      end
    end
  end

  if inputs2.state[1].dropitem == inputs2.PRESS and playerinstate ~= "dead" then
    help.active = not help.active
    if help.active then
      Misc.pause()
    else
      Misc.unpause()
      help.placement = 1
    end
  end

  if help.active then
    Graphics.drawImage(help.box, 25, 25)
    for i = 0, 5 do
      j = i + help.placement
      if help.list[j] ~= nil then
        if events.active[help.list[j].codename] then
          textblox.printExt("<color red>[X]"..help.list[j].name.."<color default>:<br>"..help.list[j].desc, {x = 100, y = 50 + 84*i, width = 600})
        else
          textblox.printExt("<color green>"..help.list[j].name.."<color default>:<br>"..help.list[j].desc, {x = 100, y = 50 + 84*i, width = 600})
        end
        Graphics.drawImageWP(help.list[j].icon, 35, 50 + 84*(i), 6)
      end
    end
    if inputs2.state[1].up == inputs2.PRESS and help.placement ~= 1 then
      help.placement = help.placement - 1
      Audio.playSFX(29)
    elseif inputs2.state[1].down == inputs2.PRESS and help.list[help.placement + 6] ~= nil then
      help.placement = help.placement + 1
      Audio.playSFX(29)
    end
  else

    Graphics.drawImageWP(drawBox.texture, 168, drawBox.y, 0)
    Graphics.drawImageWP(drawBox.icon, 180, drawBox.y + 8, 6)
    textblox.printExt(drawBox.text, {x = 240, y = drawBox.y + 8, font = drawBox.font})

    Graphics.drawImage(hud.flag_icon, hud.flag_x, hud.flag_y)
    Graphics.drawImage(hud.time_icon, hud.time_x, hud.time_y)
    textblox.printExt(string.format("%02d", hud.flag), {x = hud.flag_x + 42, y = hud.flag_y + 1, font = drawBox.font})
    local str = string.format("%02d", hud.time)
    if hud.time <= 5 then
      str = "<color red><tremble "..(1 - hud.time/5)..">"..str
    end
    textblox.printExt(str, {x = hud.time_x + 42, y = hud.time_y + 1, font = drawBox.font})
  end
  Graphics.drawImageWP(tide.image, 0, 600 - tide.y, -1)

  for k, v in pairs(handler.draw) do
    if events.active[k] then
      v()
    end
  end
end

function events.onNPCKill(eventObj, npc, reason)
  if npc.id == 178 then --and colliders.collide(npc, player) then
    hud.flag = hud.flag + 1
    hud.time = hud.timeM
    hud.time_cooldown = hud.time_cooldownM
    direction = -direction

    if direction == -1 then
      NPC.spawn(178, FLAGPOS.left.x, FLAGPOS.left.y, 0)
    else
      NPC.spawn(178, FLAGPOS.right.x, FLAGPOS.right.y, 0)
    end

    if events.active["shield"] then
      shield.used = false
    end

    if powNum[hud.flag] then
      if hud.flag == 15 then
        NPC.spawn(97, player.x, player.y, player.section)
          drawBox.animationState = 2
          drawBox.icon = Graphics.loadImage("icon-star.png")
          drawBox.text = "Finished"
          events.active["objective"] = true
          playerinstate = "happy"
      else
        local name = table.remove(quequePow, 1)
        if name then
          events.trigger(name)
        end
      end
    else
      local name = queque[1]
      if hud.flag == 1 or hud.flag == 3 then
        events.trigger("islandext")
      else
        if events.list[name].loop then
          shuffle(queque)
        else
          table.remove(queque, 1)
        end
        events.trigger(name)
      end
    end
  end
end

function events.onInitAPI()
  registerEvent(events, "onTick", "onTick")
  registerEvent(events, "onDraw", "onDraw")
  registerEvent(events, "onLoop", "onLoop")
  registerEvent(events, "onStart", "onStart", false)
  registerEvent(events, "onNPCKill", "onNPCKill", false)
end

return events
