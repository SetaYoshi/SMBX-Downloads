local lib = {}

----------------
-- commander.lua v1.0
-- By SetaYoshi
----------------

--[[
  commander.register{
  -- you can have as many indexes as you want, make sure to not skip a number!
  [INDEX] = {
    name = KEYBOARD_VK
    name = {ID = PLAYER_IDX, name = KEY_NAME}
  }
}
]]

lib.TYPE_KEYBOARD = "keyboard"
lib.TYPE_PLAYERKEY = "playerkey"

lib.lookup = {}
lib.alias = {}

local plist = {player, player2}

function lib.register(data)
  -- Save the lookup table
  local t = table.clone(data)

  -- Initialize the command table
  for k, v in ipairs(data) do
    lib[k] = {}
    for p, q in pairs(v) do
      if type(q) == "number" then
        t[k][p] = {type = lib.TYPE_KEYBOARD, ID = q}
      else
        t[k][p] = {type = (q.type or lib.TYPE_PLAYERKEY), ID = (q.ID or 1), mode = (v.mode or "rawKeys"), name = q.name}
      end
      lib[k][p] = {state = KEYS_UP, time = -2, prevstate = KEYS_UP, time = -2}
    end
  end

  lib.lookup = t
end

function lib.registerAlias(id, key, alias)
  table.insert(lib.alias, {id, key, alias})
  lib[id][alias] = lib[id][key]
end

local function getKeyState(t)
  if t.type == lib.TYPE_PLAYERKEY then
    local p = plist[t.ID]
    if p then return p[t.mode][t.name] end
  elseif t.type == lib.TYPE_KEYBOARD then
    return Misc.GetKeyState(t.ID)
  end
end

-- Update the command table
function lib.onInputUpdate()
  -- Update commando keys
  for k, v in pairs(lib.lookup) do
    for p, q in pairs(v) do
      local key = lib[k][p]
      key.prevstate = key.state
      key.prevtime = key.time
      key.state = getKeyState(q)
      if key.state then
        if key.prevstate then
          key.state = KEYS_DOWN
          key.time = key.time + 1
        else
          key.state = KEYS_PRESSED
          key.time = 1
        end
      else
        if key.prevstate then
          key.state = KEYS_RELEASED
          key.time = -1
        else
          key.state = KEYS_UP
          key.time = key.time - 1
        end
      end
    end
  end

  -- Add alias
  for k, v in ipairs(lib.alias) do
    lib[v[1]][v[3]] = lib[v[1]][v[2]]
  end
end

function lib.onInitAPI()
  registerEvent(lib,"onInputUpdate", "onInputUpdate")
end

return lib
