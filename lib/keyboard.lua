require("lib/event")

keyboard = { subjects = {}, keys = {} }

local function keypressed(key, unicode)
	keyboard.keys[key] = true
end

local function keyreleased(key, unicode)
	keyboard.keys[key] = false
end

local function update(dt)
	for key, isPressed in pairs(keyboard.keys) do
		if isPressed then
			for id, subject in pairs(keyboard.subjects) do
				local action = subject.controlKeys[key]
				if action then action(dt) end
			end
		end
	end
end

addEventHandler(love.keypressed, keypressed)
addEventHandler(love.keyreleased, keyreleased)
addEventHandler(love.update, update)

function keyboard:addSubject(subject)
	return table.insert(self.subjects, subject)
end

function keyboard:removeSubject(id)
	return table.remove(self.subjects, id)
end