local secmaker = {}
local lunajson = API.load("ext/lunajson")

local width = 0
local blocks = {}
local npcs = {}

local output = {}

function secmaker.onStart()
  for _,v in pairs(Block.get()) do
    if v.x > -100 then
      blocks[#blocks+1] = {v.id,v.x,v.y}
      if v.x + v.width > width then
        width = v.x + v.width
      end
    end
  end
  for _,v in pairs(NPC.get()) do
    if v.x > -100 then
      npcs[#npcs+1] = {v.id,v.x,v.y}
    end
  end
  output = {
    width = width,
    blocks = blocks,
    npcs = npcs
  }

  local writefile = io.open(Misc.resolveFile("output.txt"), "w")
  writefile:write(lunajson.encode(output))
  writefile:close()
end

function secmaker.onInitAPI()
  registerEvent(secmaker, "onStart", "onStart", true)
end

return secmaker
