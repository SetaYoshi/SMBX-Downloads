local save = {}

local serializer = require("ext/serializer")

local table2string = serializer.serialize
local string2table = serializer.deserialize

save.data = {}
save.path = getSMBXPath().."/logs/_speedrun_settings.txt"

save.default = {
  timerSize = 2,
  timerMode = 1,
  timerPosition = 3,
  inputPosition = 4,
  attemptsPosition = 2,
  printlog = false,
  sectionsplit = 1,
  disableChecks = false,
  popout = false,
  enablesavestate = true,
  enableas = false,
  asCostume1 = 1,
  asCostume2 = 1,
  asBox1 = 0,
  asBox2 = 0,
  asHealth1 = 1,
  asHealth2 = 1
}


function save.save()
  -- Open setting file
  local writefile = io.open(save.path, "w")
  if not writefile then return end

  -- Serialize settings and save
  writefile:write(table2string(save.data))
  writefile:close()
end

function save.load()
  -- Open setting file
  local readfile = io.open(save.path, "r")

  -- If file is empty or not found, then use default data
  if not readfile then save.data = save.default return end

  -- Read file and store contents
  save.data = string2table(readfile:read("*all"))
  readfile:close()

  -- Validate data, ensure every setting value is valid
  for k, v in pairs(save.default) do
    if save.data[k] == nil then save.data[k] = v end
  end
end

-- Load settings!
save.load()

return save
