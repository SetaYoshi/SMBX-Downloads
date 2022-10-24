local speedrunner = {}

if isOverworld then
-- When playing in a world map

-- When in the intro level
elseif mem(0x00B2C620, FIELD_WORD) == -1 then

-- When playing a level
else

end

require(getSMBXPath().."\\worlds\\_Speedrunner\\speedrunner.lua")

return speedrunner
