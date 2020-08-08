local physicbody = require "lib/physicbody"

local function new(x, y, shape, draw)
	local object = {}

	object.physicbody = physicbody.new(x, y, {1, 0, 0}, shape or {0, 0, 20, 0, 20, 20, 0, 20, 0, 0})
	object.draw = draw or function(g)
		g.push()
		g.translate(object.physicbody.pos[1], object.physicbody.pos[2])
		g.line(object.physicbody.shape)
		g.pop()
	end

	return object
end

return {
	new = new
}