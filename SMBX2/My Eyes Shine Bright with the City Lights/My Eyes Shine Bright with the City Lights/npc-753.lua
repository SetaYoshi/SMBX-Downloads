local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local ai = require("car_ai")


local car = {}
local npcID = NPC_ID

local deathEffectID = (npcID)

local carSettings = table.join(ai.sharedSettings,{
	id = npcID,
	deathEffectID = deathEffectID,
})

npcManager.setNpcSettings(carSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_LAVA,
		HARM_TYPE_OFFSCREEN,
	},
	{
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
)

ai.register(npcID)

return car