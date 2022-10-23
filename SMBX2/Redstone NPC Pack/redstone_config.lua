local redAI = {}
local redstoneconfig = {}
local redstone = {}

local expandedDefines = require("expandedDefines")

local min, max, abs, clamp = math.min, math.max, math.abs, math.clamp
local insert, map, unmap, append = table.insert, table.map, table.unmap, table.append
local gmatch, find, sub = string.gmatch, string.find, string.sub

local blockConfigCache = {}
local function configCacheBlock(id)
  if not blockConfigCache[id] then
    blockConfigCache[id] = Block.config[id]
  end

  return blockConfigCache[id]
end

function redAI.loadconfig(redstone)
  local component = redstone.component

  -- Set this to false and the script will no longer stop NPCs from despawning. This will reduce lag in your level! I reccomend you set this to false and install spawnzones into your level
  redstoneconfig.disabledespawn = true


  -- ===============
  -- === PISTONS ===
  -- ===============

  -- Determines if a block is immovable by a piston
  local immovableblock = map({})
  redstoneconfig.blockImmovable = function(b)
    if immovableblock[b.id] then
      return true
    end
  end

  -- Determines if an NPC is immovable by a piston
  redstoneconfig.npcImmovable = function(n)
    if (n and n.data and n.data.pistImmovable) then
      return true
    end
  end

  -- Determines if a player is immovable by a piston
  redstoneconfig.playerImmovable = function(p)
    if p:mem(0x4A, FIELD_BOOL) then
      return true
    end
  end

  -- Determines if a block is intangible
  local intangibleBlock = map(expandedDefines.BLOCK_SEMISOLID..expandedDefines.BLOCK_SIZEABLE..expandedDefines.BLOCK_NONSOLID)
  redstoneconfig.blockIgnore = function(b)
    if intangibleBlock[b.id] then
      return true
    end
  end

  -- Determines if an NPC is intangible
  redstoneconfig.npcIgnore = function(n)
    if (n and n.data and n.data.pistIgnore) or redstone.isDust(n.id) or n:mem(0x12C, FIELD_WORD) ~= 0 then
      return true
    end
  end

  -- Determines if an player is intangible
  redstoneconfig.playerIgnore = function(p)
    return false
  end


  -- ====================
  -- === REAPER BLOCK ===
  -- ====================

  -- Determines if the killed NPC had a soul
  local soullessNPC = map({component.operator.id}) -- Add IDs of NPCs here to make them soulless!
  redstoneconfig.hasSoul = function(n)
    if not soullessNPC[n.id] then
      return true
    end
  end


  -- ===========
  -- === TNT ===
  -- ===========

  local tnt_component = component.tnt

  -- What should an NPC do when hit by an explosion
  local function npctntfilter(v)
  	return not v.isGenerator and not v.isHidden and not v.friendly and v:mem(0x124, FIELD_BOOL) and v.id ~= 13 and v.id ~= 291 and not NPC.config[v.id].isinteractable
  end
  redstoneconfig.explosionNPCAI = function(n, tnt)
    if npctntfilter(n) then
      n:harm(HARM_TYPE_NPC)
    end

    if redstone.isSickblock(n.id) then
      redstone.setEnergy(n, 15)
    else
      local c = NPC.config[n.id]
      if not c.nogravity then
        local t = vector.v2(n.x + 0.5*n.width - tnt.data.explosionhitbox.x, n.y + 0.5*n.height - tnt.data.explosionhitbox.y)
        t = 6*t:normalise()
        n.speedX, n.speedY = clamp(n.speedX + t.x, -8, 8), clamp(1.1*(n.speedY + t.y), -8, 8)
      end
    end
  end

  -- What should a player do when hit by an explosion
  redstoneconfig.explosionPlayerAI = function(p, tnt)
    if not p:mem(0x4A, FIELD_BOOL) then -- In statue form
      p:harm()
      local t = vector.v2(p.x + 0.5*p.width - tnt.data.explosionhitbox.x, p.y + 0.5*p.height - tnt.data.explosionhitbox.y)
      t = 8*t:normalise()
      if p:isGroundTouching() and t.y < 0 then
        p.y = p.y - 4
        p:mem(0x146, FIELD_WORD, 0)
      end
      p.speedX, p.speedY = clamp(p.speedX + t.x, -12, 12), clamp(1.1*(p.speedY + t.y), -15, 15)
    end
  end

  -- What should a block do when hit by an explosion
  redstoneconfig.explosionBlockAI = function(b, tnt)
    if (expandedDefines.BLOCK_SOLID_MAP[b.id] or expandedDefines.BLOCK_SEMISOLID_MAP[b.id]) and not expandedDefines.BLOCK_SIZEABLE_MAP[b.id] then
      if tnt_component.config.destroyblock then
        b:remove(true)
      else
        if configCacheBlock(b.id).smashable ~= 3 then
          b:hit()
        else
          b:remove(true)
        end
      end
    end
  end

  -- Dispenser behavior
  redstone.npcAI[tnt_component.id] = {}
  -- redstone.npcAI[tnt_component.id].enabled = true
  redstone.npcAI[tnt_component.id].onDispense = function(n)
    n.data.isFused = true
    n.data.timer = tnt_component.config.explosiontimer
  end

  -- ==========================
  -- === FLAMETHROWER/FLAME ===
  -- ==========================


  -- A table of block IDs and the "melting" behavior
  redstoneconfig.iceBlock = {}

  -- Frozen coin block turns into a SMB3 coin
  redstoneconfig.iceBlock[620] = function(b, n)
    NPC.spawn(10, b.x, b.y, n.section)
    redstone.spawnEffect(10, b)
    b:remove()
  end

  -- Frozen muncher block turns into a muncher
  redstoneconfig.iceBlock[621] = function(b, n)
    b.id = 109
    redstone.spawnEffect(10, b)
  end

  -- Ice block melts
  redstoneconfig.iceBlock[633] = function(b, n)
    b:remove()
    redstone.spawnEffect(10, b)
  end

  -- Large ice blocks takes two flame hits to melt
  redstoneconfig.iceBlock[634] = function(b, n)
    if b.data.flame_metling then
      b:remove()
      redstone.spawnEffect(10, b)
    else
      b.data.flame_metling = true
    end
  end

  -- List of ice blocks to scan
  redstoneconfig.iceBlock_MAP = unmap(redstoneconfig.iceBlock)


  -- ===================
  -- === BEAM SOURCE ===
  -- ===================

  -- Defines when a npc is transparent
  local transparentNPCList = {component.dust.id}  -- Add here the IDs of the blocks you want to be transparent by default includes clear pipes, insisible blocks, npc filters, and player filters
  transparentNPCList = append(transparentNPCList, expandedDefines.NPC_VINE) -- Default list

  transparentNPCList = map(transparentNPCList)

  redstoneconfig.transparentNPC = function(n, dir)
    return (n.data.beamTransparent or transparentNPCList[n.id])
  end


  -- Defines when a block is transparent
  local transparentBlockList = {658, 1282, 687, 1283, 1284, 1285, 1286, 1287, 1288, 1289, 1290, 1291, 701, 702, 703, 704, 705, 706, 707, 708, 709, 710, 711, 712, 713, 714, 715, 716, 717, 718, 719, 720, 721, 722, 723, 1102, 1103, 1104, 1105, 1006, 1007}  -- Add here the IDs of the blocks you want to be transparent by default includes clear pipes, insisible blocks, npc filters, and player filters
  local semisolidTopList = {}

  transparentBlockList = append(transparentBlockList, expandedDefines.BLOCK_NONSOLID) -- Default list
  semisolidTopList = append(semisolidTopList, expandedDefines.BLOCK_SEMISOLID..expandedDefines.BLOCK_SIZEABLE)

  transparentBlockList = map(transparentBlockList)
  semisolidTopList = map(semisolidTopList)

  redstoneconfig.transparentBlock = function(b, dir)

    if Block.PLAYER_MAP[b.id] then  -- filter blocks
      local pvals = {}
      for k, p in ipairs(Player.get()) do
        pvals[p.character] = true
      end
      return pvals[configCacheBlock(b.id).playerfilter]
    elseif (b.id == 1277 or b.id == 1278) then -- beat blocks
      return configCacheBlock(b.id).passthrough
    elseif transparentBlockList[b.id] or (semisolidTopList[b.id] and dir.y < 0) then
      return true
    end
  end

  -- Defines when a player is transparent
  redstoneconfig.transparentPlayer = function(p, dir)
    return p.deathTimer > 0
  end

  -- ====================
  -- == OPERATOR BLOCK ==
  -- ====================

  -- List of NPCs the operator block can interact with
  local operator_component = component.operator
  redstoneconfig.operatorNPC_mouth,     redstoneconfig.operatorNPC_plus,     redstoneconfig.operatorNPC_minus     = {}, {}, {}
  redstoneconfig.operatorNPC_mouth_MAP, redstoneconfig.operatorNPC_plus_MAP, redstoneconfig.operatorNPC_minus_MAP = {}, {}, {}
  local operatorNPC = {}

  operatorNPC[component.repeater.id] = {
    -- AND GATE
    ["plus"] = function(n, c, power, dir, hitbox)
      if c:powerSide('eyes') > 0 and c:powerSide('minus') > 0 then
        return 15
      else
        return 0
      end
    end,

    -- XOR GATR
    ["minus"] = function(n, c, power, dir, hitbox)
      local power_eyes = c:powerSide('eyes') > 0
      local power_plus = c:powerSide('plus') > 0
      if (power_eyes or power_plus) and not (power_eyes and power_plus) then
        return 15
      else
        return 0
      end
    end,
  }

  operatorNPC[component.alternator.id] = {
    -- TURNOUT
    ["mouth"] = function(n, c, power, dir, hitbox)
      if c.data.powerPrev == 0 and c.data.power > 0 then
        n.data.facing = -n.data.facing
      end
      return 15
    end
  }

  operatorNPC[component.capacitor.id] = {
    -- EQUAL TO
    ["mouth"] = function(n, c, power, dir, hitbox)
      if power == n.data.maxcapacitance then
        n.data.unlocked = true
        return power
      else
        return 0
      end
    end,

    -- GREATER THAN
    ["plus"] = function(n, c, power, dir, hitbox)
      if power > n.data.maxcapacitance then
        n.data.unlocked = true
        return power
      else
        return 0
      end
    end,

    -- LESS THAN
    ["minus"] = function(n, c, power, dir, hitbox)
      if power < n.data.maxcapacitance then
        n.data.unlocked = true
        return power
      else
        return 0
      end
    end,
  }

  operatorNPC[component.spyblock.id] = {
    -- ALL DIFF
    ["mouth"] = function(n, c, power, dir, hitbox)
      -- MEDIAN COMPARE
      if n.data.type == 0 then
        if (c:powerSide('eyes') > c:powerSide('plus') and c:powerSide('plus') > c:powerSide('minus')) or (c:powerSide('minus') > c:powerSide('plus') and c:powerSide('plus') > c:powerSide('eyes')) then
          return c:powerSide('plus')
        elseif (c:powerSide('eyes') > c:powerSide('minus') and c:powerSide('minus') > c:powerSide('plus')) or (c:powerSide('plus') > c:powerSide('minus') and c:powerSide('minus') > c:powerSide('eyes')) then
          return c:powerSide('minus')
        else
          return c:powerSide('eyes')
        end
      -- POS DIFF
      elseif n.data.type == 2 then
        return abs(c.data.diff)
      end
      return 0
    end,

    ["plus"] = function(n, c, power, dir, hitbox)
      -- MAX COMPARE
      if n.data.type == 0 then
        return max(c:powerSide('eyes'), c:powerSide('minus'))

      -- POS DIFF
      elseif n.data.type == 2 then
        if c.data.diff > 0 then
          return c.data.diff
        end
      end
      return 0
    end,

    ["minus"] = function(n, c, power, dir, hitbox)
      -- MIN COMPARE
      if n.data.type == 0 then
        return min(c:powerSide('eyes'), c:powerSide('plus'))

      -- NEG DIFF
      elseif n.data.type == 2 then
        if c.data.diff < 0 then
          return -c.data.diff
        end
      end
      return 0
    end
  }

  operatorNPC[component.reaper.id] = {
    ["mouth"] = function(n, c, power, dir, hitbox)
      return 15 - power
    end
  }

  for k, v in pairs(operatorNPC) do
    if v.mouth then redstoneconfig.operatorNPC_mouth[k] = v.mouth; insert(redstoneconfig.operatorNPC_mouth_MAP, k) end
    if v.plus then redstoneconfig.operatorNPC_plus[k] = v.plus; insert(redstoneconfig.operatorNPC_plus_MAP, k) end
    if v.minus then redstoneconfig.operatorNPC_minus[k] = v.minus; insert(redstoneconfig.operatorNPC_minus_MAP, k) end
  end

  return redstoneconfig
end

function string.startswith(str, start)
  return str:sub(1, #start) == start
end

function string.endswith(str, ending)
	return ending == "" or str:sub(-#ending) == ending
end


local function split(str, delim)
	local ret = {}
	if not str then
		return ret
	end
	if not delim or delim == '' then
		for c in gmatch(str, '.') do
			insert(ret, c)
		end
		return ret
	end
	local n = 1
	while true do
		local i, j = find(str, delim, n)
		if not i then break end
		insert(ret, sub(str, n, i - 1))
		n = j + 1
	end
	insert(ret, sub(str, n))
	return ret
end

local function getNameID(name)
  local id = ''
  for k, v in ipairs(split(name)) do
    if k > 7 and k < #name - 3 then
      if tonumber(v) then
        id = id..v
      else
        break
      end
    end
  end
  return tonumber(id)
end

local filepaths = {"", "../", "/RedstoneAI", "../RedstoneAI"}
local requirepaths = {"", "", "RedstoneAI/", "RedstoneAI/"}
function redAI.loadAI(redstone)
  local redfiles = {}

  for k, p in ipairs(filepaths) do
    for _, v in ipairs(Misc.listLocalFiles(p)) do
      if string.startswith(v, "rednpc-") and string.endswith(v, ".lua") then
        insert(redfiles, {p, requirepaths[k], v})
      end
    end
  end

  for k, v in ipairs(redfiles) do
    local path, name = v[2], v[3]
    local id = getNameID(name)
    if id then
      _G.NPC_ID = id
      local t = require(string.sub(path..name, 1, -5))
      redstone.registerNPC(id, t)
    else
      require(sub(path..name, 1, -5))
    end
  end
  _G.NPC_ID = nil
end

return redAI
