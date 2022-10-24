local NPCs = API.load("NPCs")
-- local secmaker = API.load("secmaker")
local events = API.load("events")
local textblox = API.load("l_textblox")

events.setID(NPCs.ID)

Graphics.activateHud(false)
player.character = CHARACTER_MARIO
player.powerup = PLAYER_BIG
player:mem(0x108,FIELD_WORD, 0)
player:mem(0x10A,FIELD_WORD, 0)
Defines.player_runspeed = 4
Defines.player_walkspeed = 4
Defines.jumpheight = 18
Defines.jumpheight_bounce = 20
Defines.gravity = 8

Audio.sounds[5].muted = true
Audio.sounds[8].muted = true

function onStart()
  textblox.Block (280, 750, "Open the menu using the \"drop item\" key <pause 40>", {boxType = 3, boxAnchorX = textblox.HALIGN_LEFT, boxAnchorY = textblox.VALIGN_TOP, autoClose = true})
end
