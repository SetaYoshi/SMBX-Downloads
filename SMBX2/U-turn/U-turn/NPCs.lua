local NPCs = {}

local events = API.load("events")

local eventu = API.load("eventu")
local pnpc = API.load("pnpc")

NPCs.ID = {}
NPCs.ID.scenery = {}
NPCs.ID.enemy = {}
NPCs.ID.bullet = {}
NPCs.ID.block = {}
NPCs.ID.effect = {}

local obj = {}
obj.scenery = {}
obj.enemy = {}
obj.bullet = {}
obj.block = {}
obj.effect = {}

local respawn = {}

function add(type, id, func)
  obj[type][id] = func or (function() end)
end


add("scenery", 82) -- Wire
add("scenery", 68) -- Left Handle
add("scenery", 69) -- Right Handle
add("scenery", 19) -- Right Rail
add("scenery", 20) -- Left Rail
add("scenery", 70) -- Flower
add("scenery", 58) -- Bush
add("scenery", 242) -- Dirt

add("effect", 015, {42, 26}) -- Bullet
add("effect", 033, {42, 42, 0}) -- Piranha
add("effect", 027, {42, 42}) -- Pangolin
add("effect", 146, {36, 32}) -- Armored Beetle
add("effect", 66, {42, 42, 0}) -- Potato Spitter
add("effect", 22, {36, 36, 0}) -- Potato
add("effect", 65, {42, 32}) -- Flying Drunkard
add("effect", 125, {84, 36}) -- Dust

-- Flag
add("block", 178, function(npc)
  if npc.data.aniTimer == nil then
    npc.data.aniTimer = 0
  end
  npc.data.aniTimer = npc.data.aniTimer + 1
  if npc.data.aniTimer <= 23 then
    npc.animationFrame = math.floor(npc.data.aniTimer/8)
  else
    npc.animationFrame = 2
    npc.data.aniTimer = 0
  end
end)

-- Bridge
add("block", 67, function(npc)
  if events.active["weakbridge"] then
    if not npc.data.timer then
      if player.NPCBeingStoodOnIndex - 1 == npc.idx then
        npc.data.timer = 0
        table.insert(respawn, {id = npc.id, x = npc.x, y = npc.y})
      end
    elseif npc.data.timer >= 25 then
      npc.speedY = npc.speedY + 1
    elseif npc.data.timer >= 0 then
      npc.data.timer = npc.data.timer + 1
      npc.speedY = 2*math.sin(npc.data.timer)
    end
  end
end)
-- Rusty Stone
add("block", 81, function(npc)
  if events.active["rustystone"] then
    if not npc.data.timer then
      for _, p in ipairs(Player.getIntersecting(npc.x, npc.y - 1, npc.x + npc.width, npc.y + 600)) do
        npc.data.timer = 0
        table.insert(respawn, {id = npc.id, x = npc.x, y = npc.y})
      end
    elseif npc.data.timer >= 25 then
      npc.speedY = npc.speedY + 1
    elseif npc.data.timer >= 0 then
      npc.data.timer = npc.data.timer + 1
      npc.speedY = 2*math.sin(npc.data.timer)
    end
  end
end)
-- Saw Disk
add("block", 156, function(npc)
  if events.active["sawdisk"] then
    if npc.data.aniTimer == nil then
      npc.data.aniTimer = 0
    end
    npc.data.aniTimer = npc.data.aniTimer + 1
    if npc.data.aniTimer <= 7 then
      npc.animationFrame = math.floor(npc.data.aniTimer/4)
    else
      npc.animationFrame = 1
      npc.data.aniTimer = 0
    end
    for _, p in ipairs(Player.getIntersecting(npc.x + 4, npc.y + 4, npc.x + npc.width - 8, npc.y + npc.height - 4)) do
      p:harm()
    end
  else
    npc.animationFrame = -2
  end
end)
-- Bullet Blocks
add("block", 155, function(npc)
  if events.active["doublesidedcannon"] then
    if npc.data.timer == nil then
      npc.data.timer = -1
      npc.data.direction = -1
    end
    npc.data.timer = npc.data.timer + 1
    npc.animationFrame = 1
    if npc.data.timer == 65 then
      npc.data.timer = 0
      npc.data.direction = -npc.data.direction
      for _, b in ipairs(Block.getIntersecting(npc.x + npc.data.direction*npc.width, npc.y, npc.x + npc.data.direction*2*npc.width, npc.y + npc.height)) do
        return
      end
      Audio.playSFX(22)
      local n = NPC.spawn(17, npc.x + npc.data.direction*42, npc.y, player.section)
      n.direction = npc.data.direction
      if npc.data.direction == 1 then
        npc.animationFrame = 2
      else
        npc.animationFrame = 3
      end
    end
  else
    npc.animationFrame = 0
  end
end)

-- Starving Piranha
add("enemy", 53, function(npc)
  if events.active["starvingpiranha"] then
    npc.friendly = false
  else
    npc.friendly = true
    npc.animationFrame = -1
  end
  if npc.data.timer == nil then
    npc.data.timer = 0
    npc.y = events.SECTION_BOTTOM
  end
  if npc.y >= events.SECTION_BOTTOM then
    npc.y = events.SECTION_BOTTOM
    npc.data.timer = npc.data.timer + 1
    if npc.data.timer == 120 then
      npc.speedY = -8
      npc.data.timer = 0
    end
  else
    npc.speedY = npc.speedY + 0.09
  end
  if not npc.data.orig then
    npc.data.orig = {x = npc.x, y = npc.y}
  end
end)

--Flying Drunkard
add("enemy", 130, function(npc)
  npc.ai1 = 0
  if events.active["flyingdrunkard"] then
    if not npc.data.timer then
      npc.data.speedX = 0
      npc.data.speedY = 0
      npc.data.timer = 0
      npc.data.direction = -1
      npc.friendly = false
      npc.dontMove = false
    end

    if npc.animationFrame == 3 then
      npc.animationFrame = 0
    end
    npc.data.timer = npc.data.timer + 1
    if npc.data.timer == 180 then
      npc.data.timer = 0
      npc.animationFrame = 3
      local n = NPC.spawn(89, npc.x + 42*npc.data.direction, npc.y, player.section)
      n.direction = npc.data.direction
      n.speedX = n.direction*5
      n.speedY = -3
      npc.data.direction =  -npc.data.direction
    elseif npc.data.timer > 150 then
      npc.animationFrame = 3
    end

    local dx = player.x - npc.x
    local dy = events.SECTION_TOP - (events.SECTION_TOP-player.y)*0.2 - npc.y


    npc.data.speedX = npc.data.speedX + sign(dx)/3
    if math.abs(npc.data.speedX) > 3.5 then
      npc.data.speedX = 3.5*sign(npc.data.speedX)
    end
    npc.x = npc.x + npc.data.speedX
    npc.data.speedY = npc.data.speedY + sign(dy)
    if math.abs(npc.data.speedY) > 1 then
      npc.data.speedY = 1*sign(npc.data.speedY)
    end
    npc.y = npc.y + npc.data.speedY
  else
    npc.animationFrame = -1
    npc.friendly = true
    npc.dontMove = true
  end
  if not npc.data.orig then
    npc.data.orig = {x = npc.x, y = npc.y}
  end
end)
-- Carefree Pangolins
add("enemy", 36, function(npc)
  if events.active["carefreepangolins"] then
    if not npc.data.o then
      npc.data.o = true
      npc.friendly = false
      npc.dontMove = false
    end
  else
    npc.animationFrame = -1
    npc.friendly = true
    npc.dontMove = true
  end
  if not npc.data.orig then
    npc.data.orig = {x = npc.x, y = npc.y}
  end
end)
-- Armored Beetle
add("enemy", 285, function(npc)
  if events.active["armoredbeetle"] then
    if not npc.data.o then
      npc.data.o = true
      npc.friendly = false
      npc.dontMove = false
    end
  else
    npc.animationFrame = -1
    npc.friendly = true
    npc.dontMove = true
  end
  if not npc.data.orig then
    npc.data.orig = {x = npc.x, y = npc.y}
  end
end)
-- Potato Spitter
add("enemy", 131, function(npc)
  npc.ai1 = 0
  if events.active["potatospitter"] then
    if npc.data.timer == nil then
      npc.data.timer = -1
      npc.friendly = false
      npc.dontMove = false
    end
    if npc.animationFrame == 2 then
      npc.animationFrame = 0
    end
    if npc.animationFrame == 6 then
      npc.animationFrame = 4
    end

    npc.data.timer = npc.data.timer + 1
    if npc.data.timer == 190 then
      npc.data.timer = 0
      npc.animationFrame = 3 + (npc.direction + 1)/2*4
      local n = NPC.spawn(27, npc.x + 42*npc.direction, npc.y, player.section)
      n.direction = npc.direction
    elseif npc.data.timer > 170 and npc.data.timer < 185 then
      npc.dontMove = true
      npc.animationFrame = 2 + (npc.direction + 1)/2*4
    elseif npc.data.timer >= 185 or npc.data.timer < 5 then
      npc.dontMove = true
      npc.animationFrame = 3 + (npc.direction + 1)/2*4
    elseif npc.data.timer == 5 then
      npc.dontMove = false
    end
  else
    npc.animationFrame = -1
    npc.friendly = true
    npc.dontMove = true
  end
  if not npc.data.orig then
    npc.data.orig = {x = npc.x, y = npc.y}
  end
end)

-- Potato
add("bullet", 27, function(npc)
  if npc.data.direction == nil then
    npc.data.direction = npc.direction
  end
  if npc.data.direction ~= npc.direction then
    npc:kill(HARM_TYPE_PROJECTILE_USED)
  end
  npc.speedX = npc.data.direction*3
end)
-- Bullet
add("bullet", 17, function(npc)
  if npc.data.x == nil then
    npc.data.x = 0
  else
    if npc.data.x == npc.x then
      npc:kill()
    end
  end
  npc.data.x = npc.x
end)
-- Bottle
add("bullet", 89, function(npc)
  if npc.data.y == nil then
    npc.data.y = 0
    npc.data.speedX = 1
  else
    npc.x = npc.x + npc.data.speedX*npc.direction
    if npc.data.y == npc.y then
      Animation.spawn(13, npc.x, npc.y)
      npc:kill()
    end
  end
  npc.data.y = npc.y
end)

function NPCs.onStart()
  for k, v in pairs(obj) do
    for n in pairs(v) do
      table.insert(NPCs.ID[k], n)
    end
  end
end


for _, v in ipairs(NPCs.ID.bullet) do
  table.insert(NPCs.ID.enemy, v)
end
for k, v in pairs(obj.bullet) do
  obj.enemy[k] = v
end

NPCs.ID.merge = NPCs.ID.enemy
for _, v in ipairs(NPCs.ID.block) do
  table.insert(NPCs.ID.merge, v)
end
obj.merge = {}
for k, v in pairs(obj.block) do
  obj.merge[k] = v
end
for k, v in pairs(obj.enemy) do
  obj.merge[k] = v
end

function NPCs.onTickEnd()
  for _, v in ipairs(Animation.get(NPCs.ID.effect)) do
    v.width = obj.effect[v.id][1]
    v.height = obj.effect[v.id][2]
    v.animationFrame = obj.effect[v.id][3] or v.animationFrame
  end
  for _, v in ipairs(NPC.get(NPCs.ID.merge)) do
    v = pnpc.wrap(v)
    if v:mem(0x12A, FIELD_WORD) == 170 then
      v:mem(0x12A, FIELD_WORD, 180)
    end
    v:mem(0x128, FIELD_BOOL, false)
    obj.merge[v.id](v)
  end
  for _, v in ipairs(NPC.get(NPCs.ID.scenery)) do
    v.friendly = true
    v:mem(0x128, FIELD_BOOL, false)
    if v:mem(0x12A, FIELD_WORD) == 170 then
      v:mem(0x12A, FIELD_WORD, 180)
    end
  end
end

function NPCs.onNPCKill(eventObj, npc, reason)
  npc = pnpc.wrap(npc)
  if npc.id == 178 then
    for _, v in ipairs(respawn) do
      NPC.spawn(v.id, v.x, v.y, player.section)
    end
    respawn = {}
  elseif npc.data.orig then
    table.insert(respawn, {id = npc.id, x = npc.data.orig.x, y = npc.data.orig.y})
  end
end

function NPCs.onInitAPI()
  registerEvent(NPCs, "onTickEnd", "onTickEnd")
  registerEvent(NPCs, "onStart", "onStart")
  registerEvent(NPCs, "onNPCKill", "onNPCKill")
end


function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function sign(n)
  if n > 0 then
    return 1
  elseif n == 0 then
    return 0
  else
    return -1
  end
end

return NPCs
