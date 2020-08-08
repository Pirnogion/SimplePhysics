-- ICLUDE LIBRARIES --
local physicworld = require "lib/physicworld"
require "lib/vector"

-- MODULE --
function new(x, y, color, shape)
	local object = {}

	object.color = color
	object.isFrozen = false

	-- Vector variables --
	object.force = createVector(0, 0)
	object.impulse = createVector(0, 0)
	object.acceleration = createVector(0, 0)
	object.velocity = createVector(0, 0)
	object.pos = createVector(x, y)
	object.angle = 0

	-- Scalar variables --
	object.kineticEnergy = 0
	object.mass = 100
	object.friction = 0.9
	object.elasticity = 0

	-- Others --
	object.forces = {}

	object.shape = shape or {0, 0, 20, 0, 20, 20, 15, 20, 10, 30, 5, 20, 0, 20}
	object.center = {0, 0}
	object.boundingRadius = 0

	--calculate barycenter and bounding radius--
	for i=1, #object.shape, 2 do
		object.center[1] = object.center[1] + object.shape[i+0]
		object.center[2] = object.center[2] + object.shape[i+1]

		object.boundingRadius = object.boundingRadius + length({math.abs(object.shape[i+0]), math.abs(object.shape[i+1])})
	end

	object.boundingRadius = object.boundingRadius / (#object.shape/2)

	object.center[1] = object.center[1] / (#object.shape/2)
	object.center[2] = object.center[2] / (#object.shape/2)

	function object.update(dt)
		if object.isFrozen then
			return
		end

		local newForce = createVector(0, 0)
		for id, force in ipairs(object.forces) do
			if (force[1] > 0) then
				force[1] = force[1] - 1
				newForce = newForce + force[2](object)
			else
				table.remove(object.forces, id)
			end
		end

		object.force = newForce
		object.acceleration = (1/object.mass) * object.force

		object.velocity = object.velocity + object.acceleration * (1/60) * 0.5
		object.impulse = object.mass * object.velocity
		object.velocity = object.velocity + object.acceleration * (1/60) * 0.5

		object.pos = object.pos + object.velocity * (1/60)

		object.kineticEnergy = 0.5 * object.mass * length(object.velocity)^2
	end

	function object.applyForce(time, force, applPoint)
		return table.insert(object.forces, {time, force, applPoint})
	end

	function object.cancelForce(id)
		return table.remove(object.forces, id)
	end

	function object.editForce(id, time, force, applPoint)
		if (object.forces[id]) then
			object.forces[id][1] = time and time or object.forces[id][1]
			object.forces[id][2] = force and force or object.forces[id][2]
			object.forces[id][3] = applPoint and applPoint or object.forces[id][3]

			return true
		end

		return false
	end

	function object.applyImpulse(impulse)
		object.impulse = object.impulse + impulse
		object.velocity = object.impulse/object.mass
	end

	function object.setForce(newForce)
		object.force = newForce
		object.acceleration = object.force/object.mass
		object.velocity = object.velocity + object.acceleration
	end

	function object.setAcceleration(newAcceleration)
		object.acceleration = newAcceleration
		object.velocity = object.velocity + object.acceleration
	end

	function object.setImpulse(newImpulse)
		object.impulse = newImpulse
		object.velocity = object.impulse/object.mass
	end

	function object.setVelocity(newVelocity)
		object.velocity = newVelocity
	end

	function object.setPosition(newPosition)
		object.pos = newPosition
	end

	physicworld.register(object)

	return object
end

return {
	new = new
}