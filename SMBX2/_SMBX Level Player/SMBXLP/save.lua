local save = {}

--[[
       SAVE.LUA
      BY YOSHI021
        v 1.0.0
       -
      save.filepath: filepath it will be saved on (ex. save.filepath .. {save.filepath} .. .txt)
       -
      save.data_default: A table containing the data that should be set  when reseted/default
       -
      save.data: A table containing the data
       -
      save.save(): A function that will save the data in 'save.data'.
       -
      save.reset(): A function that will set save.data_default to save.data
       -
      save.load(): A function that will load save.data (Use this function after 'save.filepath' and 'save.data_default' is set)
       -
       -
      =============================
      Example:
      local save = API.load("save")
      save.data_default = {a = 0}
      save.filepath = "mySaveData-"
      save.load()

      function onTick()
        if myVar then
          save.data.a = save.data.a + 1
        elseif myVar2 then
          save.reset()
        end
      end
      =============================
]]


local lunajson = API.load("ext/lunajson")

save.filepath = "savedata-"
save.data_default = {}
save.data = {}

save.menufilepath = "menusavedata-"
save.menudata_default = {}
save.menudata = {}

local function read_file(path)
  local file = io.open(path, "r") -- r read mode and b binary mode
  if not file then return nil end
  local content = file:read("*all") -- *a or *all reads the whole file
  file:close()
  return content
end



function save.save()
  local path = save.filepath..".txt"
  local writefile = io.open(path, "w")
  if not writefile then return nil end
  save.data = save.data or {}
  save.data[Misc.saveSlot()] = save.data[Misc.saveSlot()] or table.clone(save.data_default)
  writefile:write(lunajson.encode(save.data))
  writefile:close()
end

function save.reset()
  save.data = save.data or {}
  for i = 1, Misc.saveSlot() do
    save.data[i] = save.data[i] or table.clone(save.data_default)
  end
  save.save()
end


function save.load()
  local savedata = read_file(save.filepath..".txt")
  if savedata == nil or savedata == "" or savedata == "null" then
    save.reset()
  else
    save.data = lunajson.decode(savedata)
    if save.data[Misc.saveSlot()] == nil then
      save.reset()
    end
  end
end

function save.menusave()
  local path = save.menufilepath..".txt"
  local writefile = io.open(path, "w")
  if not writefile then return nil end
  save.menudata[Misc.saveSlot()] = save.menudata[Misc.saveSlot()] or save.menudata_default
  writefile:write(lunajson.encode(save.menudata))
  writefile:close()
end

function save.menureset()
  save.menudata = save.menudata or {}
  for i = 1, Misc.saveSlot() do
    save.menudata[i] = save.menudata[i] or table.clone(save.menudata_default)
  end
  save.menusave()
end


function save.menuload()
  local savedata = read_file(save.menufilepath..".txt")
  if savedata == nil or savedata == "" or savedata == "null" then
    save.menureset()
  else
    save.menudata = lunajson.decode(savedata)
    if save.menudata[Misc.saveSlot()] == nil then
      save.menureset()
    end
  end
end

return save
