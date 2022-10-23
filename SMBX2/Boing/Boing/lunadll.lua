local animDraw = API.load("local_animDraw")
local lookOut = API.load("local_lookOut")
local inputs2 = API.load("local_inputs2")
local lunajson = API.load("ext/lunajson")
local colliders = API.load("local_colliders")
animDraw.new("portal",animDraw.load({"portal-1","portal-2"}),8)

if not GameData.checkX then
  GameData.checkX = -199580
  GameData.checkY = -199776
end

function rePlayer()
  player.x = GameData.checkX
  player.y = GameData.checkY
end

lookOut.speed = 8
lookOut.useCursor = false
lookOut.endCursor = false
lookOut.endPause = false

local isAlive = true
local deathCount = 0
local teleCount = 0
local telePoint = {}

local sm = {{-3,-3},{-3,0},{-3,3},{0,-3},{0,0},{0,3},{3,-3},{3,0},{3,3}}

function isTramAlive()
  for _,v in pairs(NPC.get(26,player.section)) do
    return
  end
  NPC.spawn(26,GameData.checkX,GameData.checkY,player.section)
end
function canTeleport()
  if (player.holdingNPC == nil or player.holdingNPC.id ~= 26) and isAlive then
    for _,v in pairs(NPC.get(26,player.section)) do
      if not v.collidesBlockUp then
        return true
      end
    end
  end
  return false
end

function onStart()
  player:mem(0x16,FIELD_WORD,1)
  Graphics.activateHud(false)
  Defines.jumpheight_bounce = 14
  Defines.jumpheight = 16
  Defines.player_grav = .4
  player.character = CHARACTER_PEACH
  player.powerup = PLAYER_SMALL
  rePlayer()
end

function onDraw()
  if teleCount > 0 then
    teleCount = teleCount - 1
    Graphics.drawImageToSceneWP(animDraw.get("portal"),telePoint[1],telePoint[2],-60)
  end
  if inputs2.state[1].dropitem == inputs2.PRESS then
    if lookOut.isActivated() then
      lookOut.deactivate()
    elseif not lookOut.isEnding() then
      lookOut.activate()
    end
  end
end

function onTick()
  isTramAlive()
  if player:mem(0x11C,FIELD_WORD) > 35 then
    player:mem(0x11C,FIELD_WORD,35)
  end
    -- Text.print(canTeleport(),0,0)
    -- Text.print(isTramAlive(),0,16)

  if player:mem(0x13E,FIELD_WORD) > 0 and isAlive then
    isAlive = false
  end

  if inputs2.state[1].altjump == inputs2.PRESS and canTeleport() then
    for i=1,9 do
      local smoke = Animation.spawn(74,player.x+(player.width/2),player.y+player.height)
      smoke.speedX = sm[i][1]
      smoke.speedY = sm[i][2]
    end
    for _,v in pairs(NPC.get(26)) do
      v.speedY = -1
      v.speedX = 0
      player.speedY = -1
      player.speedX = 0
      player.x = v.x
      player.y = v.y-34
      teleCount = 10
      telePoint = {player.x-16,player.y-16}
    end
  end

  if inputs2.state[1].altrun == inputs2.HOLD and canTeleport() and player:isGroundTouching() then
    for _,v in pairs(NPC.get(26)) do
      v.speedX = calcSpeed(player.x+player.width, v.x+v.width)
      v.speedY = calcSpeed(player.y,v.y+v.height)
    end
  end

  for _,v in pairs(NPC.get(273,0)) do
    if not v.friendly then v.friendly = true end
    if colliders.collide(player,v) and inputs2.state[1].up == inputs2.PRESS then
      for _,n in pairs(NPC.get(26,player.section)) do
        playSFX(58)
        n.x = v.x
        n.y = v.y
        n.speedX = 0
        n.speedY = 0
        GameData.checkX = player.x
        GameData.checkY = player.y-32
      end
    end
  end

end



function onNPCKill(ev,npc,reason)
  if npc.id == 97 and colliders.collide(npc,player) then GameData.checkX = 0 end
  if npc.id == 26 then NPC.spawn(26,npc.x,npc.y-32,player.section) end
end

function calcSpeed(a,b)
  local dist = a-b
  if math.abs(dist) < 32 then return sign(a-b) end
  local spd = dist/50
  if math.abs(spd) < 3 then
    spd = 3*sign(spd)
  end
  if math.abs(spd) > 10 then
    spd = 10*sign(spd)
  end
  return spd
end

function sign(n)
  if n < 0 then return -1
  elseif n > 0 then return 1
  else return 0
  end
end
