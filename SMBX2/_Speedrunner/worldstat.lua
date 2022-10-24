local save = {}

local lunajson = API.load("ext/lunajson")

save.data = {}
save.path = Misc.episodePath().."world.spdwld"
save.default = {
  runs = {}
}


local function read_file(path)
  local file = io.open(path, "r") -- r read mode
  if not file then return nil end
  local content = file:read("*all") -- *a or *all reads the whole file
  file:close()
  return content
end

function save.save()
  local writefile = io.open(save.path, "w")
  if not writefile then return end

  writefile:write(lunajson.encode(save.data))
  writefile:close()
end

function save.reset()
  save.data = table.clone(save.default)
  save.save()
end

function save.load()
  local savedata = read_file(save.path)
  if savedata == nil or savedata == "" then
    save.reset()
  else
    save.data = lunajson.decode(savedata) --or {}
  end
end

-- Load settings!
save.load()

return save
