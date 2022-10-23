local balloon = {}

-- balloon.lua v1.0
-- Created by SetaYoshi
-- GFX: AirShip
-- SFX: https://www.youtube.com/watch?v=WFJfSVPVJsA

balloon.ID = {}

-- The lower the number, the higher the boost
local standard = -10
local spinjump = -10
local peach_boost = -6
local klonoa_boost = -8
local wario_boost = -6
local rosalina_boost = -6
local ninjabommber_boost = -6
local bowser_boost = -6

local playerManager = require("playerManager")
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local klonoa = require("characters/klonoa")
local rosalina = require("rosalina")
local ninjabomberman = require("ninjabomberman")
local unclebroadsword = require("unclebroadsword")
local wario = require("wario")
local bowser = require("bowser")


playerManager.overrideCharacterLib(CHARACTER_ROSALINA, rosalina)
playerManager.overrideCharacterLib(CHARACTER_NINJABOMBERMAN, ninjabomberman)
playerManager.overrideCharacterLib(CHARACTER_WARIO, wario)
playerManager.overrideCharacterLib(CHARACTER_UNCLEBROADSWORD, unclebroadsword)
playerManager.overrideCharacterLib(CHARACTER_BOWSER, bowser)

local sfx_pop = Audio.SfxOpen("balloon-pop.wav")

local disableinputjump = function(p)
  Routine.run(function()
    local t = 0
    while true do
      t = t + 1
      if t > 5 and p.rawKeys.jump == KEYS_PRESSED or (p.character == CHARACTER_ROSALINA or p.character == CHARACTER_NINJABOMBERMAN) then
        break
      end
      p.jumpKeyPressing = false
      Routine.waitFrames(1)
    end
  end)

  Routine.run(function()
    local t = 0
    while true do
      t = t + 1
      if t > 5 and p.rawKeys.altJump == KEYS_PRESSED or ((p.character == CHARACTER_PEACH or p.character == CHARACTER_KLONOA or p.character == CHARACTER_ROSALINA or p.character == CHARACTER_NINJABOMBERMAN) and p.speedY >= 0) then
        break
      end
      p.altJumpKeyPressing = false
      Routine.waitFrames(1)
    end
  end)
end

local function pop_jump(p)
  disableinputjump(p)
  if p.character == CHARACTER_MARIO or p.character == CHARACTER_LUIGI or p.character == CHARACTER_TOAD or p.character == CHARACTER_ZELDA or p.character == CHARACTER_UNCLEBROADSWORD then
    p:mem(0x50, FIELD_BOOL, false)
    if p.character == CHARACTER_UNCLEBROADSWORD then
      unclebroadsword.stopGroundPound()
    end
  elseif p.character == CHARACTER_KLONOA then
    klonoa.forceJumped()
  elseif p.character == CHARACTER_WARIO then
    wario.stopGroundPound()
  end

  if CHARACTER_BOWSER and bowser.isGroundPounding() then
  else
    p.speedY = standard
  end

end

local function pop_altjump(p)
    disableinputjump(p)
    if p.character == CHARACTER_MARIO or p.character == CHARACTER_LUIGI or p.character == CHARACTER_TOAD or p.character == CHARACTER_ZELDA or p.character == CHARACTER_UNCLEBROADSWORD then
      p:mem(0x50, FIELD_BOOL, true)
      SFX.play(33)
      p.speedY = spinjump
      if p.character == CHARACTER_UNCLEBROADSWORD then
        unclebroadsword.stopGroundPound()
      end
    elseif p.character == CHARACTER_LINK then
      p:mem(0x0C,	FIELD_BOOL, true)
      p:mem(0x10, FIELD_WORD, 100)
      SFX.play(87)
    elseif p.character == CHARACTER_PEACH then
      p:mem(0x18,	FIELD_BOOL, true)
      p:mem(0x1C, FIELD_WORD, 0)
      p.speedY = peach_boost
    elseif p.character == CHARACTER_KLONOA then
      klonoa.resetFlutter()
      p.speedY = klonoa_boost
    elseif p.character == CHARACTER_WARIO then
      if p.powerup == 1 then
        p.speedY = standard
      else
        p.speedY = wario_boost
        Routine.setFrameTimer(8, wario.doGroundPound)
      end
    elseif p.character == CHARACTER_ROSALINA then
      p.speedY = rosalina_boost
      rosalina.resetjump()
    elseif p.character == CHARACTER_NINJABOMBERMAN then
      p.speedY = ninjabommber_boost
      ninjabomberman.resetjump()
    elseif p.character == CHARACTER_BOWSER then
      if not bowser.isGroundPounding() then
        if p.powerup == PLAYER_TANOOKIE then
          p.speedY = bowser_boost
          Routine.setFrameTimer(8, bowser.doGroundPound)
        else
          p.speedY = standard
        end
      end
    else
      p.speedY = standard
    end
end

local function pop(p, n)
  SFX.play(sfx_pop)
  local e = Effect.spawn(n.id, n.x + 0.5*n.width, n.y)
  e.x = e.x - 0.5*e.width
  local e = Effect.spawn(930, n.x + 0.5*n.width, n.y + n.height)
  e.x, e.y = e.x - 0.5*e.width, e.y - 0.5*e.height
  local e = Effect.spawn(75, n.x + 0.5*n.width, n.y + 0.25*n.height)
  e.x = e.x - 0.5*e.width
  n.data.respawntimer = n.data.respawntimerMax
  n.data.popped = true

  if p then
    if n.id == balloon.ID.red then
      if p:mem(0x50, FIELD_BOOL) then
        pop_altjump(p)
      else
        pop_jump(p)
      end
    elseif n.id == balloon.ID.green then
      if p.rawKeys.altJump then
        pop_altjump(p)
      elseif p.rawKeys.jump then
        pop_jump(p)
      elseif p:mem(0x50, FIELD_BOOL) then
        pop_jump(p)
      else
        pop_altjump(p)
      end
    elseif n.id == balloon.ID.blue then
      pop_jump(p)
    elseif n.id == balloon.ID.purple then
      pop_altjump(p)
    end
  end
end

local head_iniNPC = function(n)
  if not n.data.ini then
    n.data.ini = true
		n.data.popped = false
    n.data.respawntimer = 1
    n.data.respawntimerMax = NPC.config[n.id].respawn
  end
end

function balloon.onTickNPC(n)
  if Defines.levelFreeze or n:mem(0x12A, FIELD_WORD) <= 0 or n:mem(0x12C, FIELD_WORD) ~= 0 or n:mem(0x136, FIELD_BOOL) or n:mem(0x138, FIELD_WORD) > 0 then return end
  head_iniNPC(n)
  local data = n.data

  if data.popped then
    n.friendly = true
    data.respawntimer = data.respawntimer - 1
    if data.respawntimer <= 0 then
      local e = Effect.spawn(10, n.x + 0.5*n.width, n.y)
      e.x = e.x - 0.5*e.width
      data.popped = false
    end
  else
    n.friendly = false
    for _, p in ipairs(Player.getIntersecting(n.x, n.y, n.x + n.width, n.y + n.height)) do
      pop(p, n)
    end
  end

end

function balloon.onDrawNPC(n)
  if n.data.popped then
    n.animationFrame = -1
  end
end

function balloon.onNPCKill(eventObj, n, r)
  if table.contains(balloon.ID, n.id) then
    eventObj.cancelled = true
    if r == HARM_TYPE_NPC or r == HARM_TYPE_PROJECTILE_USED or r == HARM_TYPE_SWORD or r == HARM_TYPE_EXT_ICE or r == HARM_TYPE_EXT_FIRE or r == HARM_TYPE_EXT_HAMMER then
      pop(nil, n)
      n.speedX = 0
    end
  end
end

function balloon.onInitAPI()
  registerEvent(balloon, "onNPCKill", "onNPCKill")
end

return balloon
