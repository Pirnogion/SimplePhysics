require "lib/vector"

local bodies = {}
local forces = {
	--980
	gravity = {math.huge, function() return createVector(0, 0) end, createVector(0, 0)}
}

local function direction(pi, pj, pk)
	return (pk[1] - pi[1])*(pj[2] - pi[2]) - (pk[2] - pi[2])*(pj[1] - pi[1])
end

local function onSegment(pi, pj, pk)
	if (math.min(pi[1], pj[1]) <= pk[1] and pk[1] <= math.max(pi[1], pj[1])) and (math.min(pi[2], pj[2]) <= pk[2] and pk[2] <= math.max(pi[2], pj[2])) then
		return true
	end

	return false
end

local function hasCollision(pa1, pa2, pb1, pb2)
	local d1 = direction(pb1, pb2, pa1)
	local d2 = direction(pb1, pb2, pa2)
	local d3 = direction(pa1, pa2, pb1)
	local d4 = direction(pa1, pa2, pb2)

	if ((d1 > 0 and d2 < 0) or (d1 < 0 and d2 > 0)) and ((d3 > 0 and d4 < 0) or (d3 < 0 and d4 > 0)) then
		return true
	end

	if d1 == 0 and onSegment(pb1, pb2, pa1) then return true end
	if d2 == 0 and onSegment(pb1, pb2, pa2) then return true end
	if d3 == 0 and onSegment(pa1, pa2, pb1) then return true end
	if d4 == 0 and onSegment(pa1, pa2, pb2) then return true end

	return false
end

local function register(physicbody)
	for name, force in pairs(forces) do
		physicbody.applyForce(force[1], force[2], force[3])
	end

	table.insert(bodies, physicbody)
end

local function update(dt)
	for j = 1, #bodies-1, 1 do
		local body1 = bodies[j]

		for i = j+1, #bodies, 1 do
			local body2 = bodies[i]

			--if math.ceil(body1.pos[1] / sectorSize) == math.ceil(body2.pos[1] / sectorSize) and math.ceil(body1.pos[2] / sectorSize) == math.ceil(body2.pos[2] / sectorSize) then
			if length(body1.pos - body2.pos) < body1.boundingRadius + body2.boundingRadius then
				for p1 = 1, #body1.shape, 2 do
					local fix1 = (p1 == #body1.shape-1) and #body1.shape or 0

					for p2 = 1, #body2.shape, 2 do
						local fix2 = (p2 == #body2.shape-1) and #body2.shape or 0

						if hasCollision(
							{body1.pos[1]+body1.shape[p1+0], body1.pos[2]+body1.shape[p1+1]}, 
							{body1.pos[1]+body1.shape[p1+2-fix1], body1.pos[2]+body1.shape[p1+3-fix1]}, 
							{body2.pos[1]+body2.shape[p2+0], body2.pos[2]+body2.shape[p2+1]}, 
							{body2.pos[1]+body2.shape[p2+2-fix2], body2.pos[2]+body2.shape[p2+3-fix2]})
						then
							local tgeneral = 2*(body1.mass*body1.velocity+body2.mass*body2.velocity)/(body1.mass+body2.mass)

							body1.setVelocity((-body1.velocity + tgeneral) * 0.98)
							body2.setVelocity((-body2.velocity + tgeneral) * 0.98)

							goto BREAK2
						end
					end
				end
			end
			::BREAK2::
		end
	end

	for _, body in ipairs(bodies) do
		body.update(dt)
	end
end

return {
	register = register,
	update = update
}