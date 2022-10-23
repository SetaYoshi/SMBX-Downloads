function onEvent(name)
  if name == "spawnCannon" then
    local n = NPC.spawn(87, -199472, -200736, 0)
	n.speedX = -5
	n.friendly = true
  end
 end