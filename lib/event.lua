--[[

EventList structure:
	{
		[event_1] = { EventHandler_1, EventHandler_2, ..., EventHandler_m1 },
		[event_2] = { EventHandler_1, EventHandler_2, ..., EventHandler_m2 },
		...
		[event_n] = { EventHandler_1, EventHandler_2, ..., EventHandler_m3 },
	}

--]]

local eventList = {}

function addEventHandler( event, eventHandler )
	if not eventList[event] then eventList[event] = {} end
	table.insert( eventList[event], eventHandler )
end

function removeEventHandler( event, eventHandler )
	if eventList[event] then
		for i = 1, #eventList[event], 1 do
			if eventList[event][i] == eventHandler then
				table.remove(eventList[event], i)
			end
		end
	end
end

function love.keypressed( ... )
	local this = eventList[love.keypressed]

	for eventHandlerId = 1, #this, 1 do
		this[eventHandlerId]( ... )
	end
end

function love.keyreleased( ... )
	local this = eventList[love.keyreleased]

	for eventHandlerId = 1, #this, 1 do
		this[eventHandlerId]( ... )
	end
end

function love.update( ... )
	local this = eventList[love.update]

	for eventHandlerId = 1, #this, 1 do
		this[eventHandlerId]( ... )
	end
end

function love.draw( ... )
	local this = eventList[love.draw]

	for eventHandlerId = 1, #this, 1 do
		this[eventHandlerId]( ... )
	end
end