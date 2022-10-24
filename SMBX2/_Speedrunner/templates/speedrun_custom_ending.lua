-- Using this file you can stop an episode run when an event is called.
-- This is meant for episodes that have a custom finish and do not use the 'Bowser - Dead' event
return {
  ['bowsers_castle.lvl'] = 'Boss Dead',
}

-- Here is an example. Make sure to have the '.lvlx' or '.lvl' extension in your level name
--[[
return {
  ['my level 1.lvl'] = 'some event 1',
  ['my level 2.lvl'] = 'some event 2',
  ['my level 3.lvl'] = 'some event 3',
}
]]

-- You can also just put in an event name and it'll assume its for all levels
--[[
return "some event name"
]]
