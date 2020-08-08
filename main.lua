-- ICLUDE LIBRARIES --
local drawFeatures = require("lib/drawFeatures")
local plr = require("lib/player")
local physbody = require("lib/physicbody")

require("lib/event")
require("lib/vector")
require("lib/keyboard")

-- RENAME NATIVE MODULES --
local gpu = love.graphics

-- CONSTANTS AND ETC. --
local screenWidth, screenHeight = gpu.getWidth(), gpu.getHeight()

local zoom = 1.0
local shift = {0.0, 0.0}
local zoomDelta = 0.0271
local shiftDelta = -0.05

local isForcing = false
local isDragging = false
local mousePrevPos = {0.0, 0.0}

local sectorSize = 200
local space = {}

local p1joystick = nil

-- UTILS --
local function randomPos()
	math.randomseed(love.timer.getTime())

	return createVector(math.random(-screenWidth/2, screenWidth/2), math.random(-screenHeight/2, screenHeight/2))
end

local function randomRGBColor()
	math.randomseed(love.timer.getTime())

	return {math.random(), math.random(), math.random()}
end

local function bound(v, min, max)
	return (v > max) and max or (v < min) and min or v
end

-- COLLISION --
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

-- CONTROLS --
function love.wheelmoved(dx, dy)
    if dy > 0 then
    	zoom = bound(zoom - zoomDelta, zoomDelta, 1.0)
    elseif dy < 0 then
    	zoom = bound(zoom + zoomDelta, zoomDelta, 1.0)
    end
end

function love.mousepressed(x, y, button)
	if button == 3 then
		mousePrevPos[1] = x
		mousePrevPos[2] = y
		isDragging = true
	elseif button == 1 then
		isForcing = true
		mousePrevPos[1] = x
		mousePrevPos[2] = y
	end
end

function love.mousereleased(x, y, button)
	if button == 3 then
		isDragging = false
	elseif button == 1 then
		isForcing = false
	end
end

function love.joystickadded(joystick)
    p1joystick = joystick
end

-- BODIES --
local ps = drawFeatures.generateNgon(20, 7)

local player = physbody.new(-100, 0, {1, 0, 0}, ps)
player.controlKeys = {
	w = function(dt)
		return player.applyForce(1, function() return {0, -1000} end, {0, 0})
	end,
	a = function(dt)
		return player.applyForce(1, function() return {-1000, -0} end, {0, 0})
	end,
	s = function(dt)
		return player.applyForce(1, function() return {0, 1000} end, {0, 0})
	end,
	d = function(dt)
		return player.applyForce(1, function() return {1000, 0} end, {0, 0})
	end,
}
keyboard:addSubject(player)

local bodies = {player}

for i = 1, 20, 1 do
	local size = love.math.random(10, 20)

	local sh = drawFeatures.generateNgon(size, love.math.random(3, 16))
	local body = physbody.new(0, 0, randomRGBColor(), sh)

	body.mass = 10 * size
	table.insert( bodies, body )
end

for id, obj in ipairs(bodies) do
	local newPos = randomPos()

	::LOOP::
	for i = 1, id, 1 do
		if (length2(newPos - bodies[i].pos) < 50^2) then
			newPos = randomPos()
			goto LOOP
		end
	end

	obj.pos = newPos
end

-- MAIN LOGIC --
function love.load()
	gpu.setBackgroundColor(1.0, 1.0, 1.0)
	gpu.setColor(0.0, 0.0, 0.0)
end

addEventHandler(love.update, function(dt)
	if isForcing then
		player.applyForce(1, function()
			local toCursor = normalize(createVector(love.mouse.getX() - screenWidth/2 - shift[1], love.mouse.getY() - screenHeight/2 - shift[2]) - player.pos) 
			return {10000 * toCursor[1], 10000 * toCursor[2]}
		end, {0, 0})
	end

	if (p1joystick) then
		if (p1joystick:isDown(12)) then
			shift = {0, 0}
		elseif (p1joystick:isDown(11)) then
			shift = {-player.pos[1]*zoom, -player.pos[2]*zoom}
		end

		if (not p1joystick:isDown(7)) then
			shift = shift - 10*createVector(p1joystick:getAxis(3), p1joystick:getAxis(4))
		else
			zoom = bound(zoom - zoomDelta * p1joystick:getAxis(4) , zoomDelta, 1.0)
		end

		player.applyForce(1, function()
			return {10000 * p1joystick:getAxis(1), 10000 * p1joystick:getAxis(2)}
		end, {0, 0})
	end

	if isDragging then
		shift[1] = shift[1] - (love.mouse.getX() - mousePrevPos[1]) * zoom
		shift[2] = shift[2] - (love.mouse.getY() - mousePrevPos[2]) * zoom

		mousePrevPos[1] = love.mouse.getX()
		mousePrevPos[2] = love.mouse.getY()
	end

	for i = 1, #bodies, 1 do
		bodies[i].update(dt)
	end

	for j = 1, #bodies-1, 1 do
		local body1 = bodies[j]

		for i = j+1, #bodies, 1 do
			local body2 = bodies[i]

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
end)

addEventHandler(love.draw, function()
	local zoomedSectorSize = sectorSize*zoom
	local verticalLines = math.floor((0.5*screenWidth+math.abs(shift[1]))/zoomedSectorSize)
	local horizontalLines = math.floor((0.5*screenHeight+math.abs(shift[2]))/zoomedSectorSize)

	local shiftX = screenWidth/2+shift[1]

	gpu.push()
	gpu.translate(screenWidth/2+shift[1], screenHeight/2+shift[2])

	gpu.setColor(0.9, 0.9, 0.9)
	for i = -verticalLines, verticalLines, 1 do
		gpu.line(zoomedSectorSize*i, -screenHeight/2-shift[2], zoomedSectorSize*i, screenHeight/2-shift[2])
	end
	for i = -horizontalLines, horizontalLines, 1 do
		gpu.line(-screenWidth/2-shift[1], zoomedSectorSize*i, screenWidth/2-shift[1], zoomedSectorSize*i)
	end
	
	gpu.pop()

	-- BOUNDING BOX AND OTHER GRAPHICS --
	gpu.push()
	gpu.translate(screenWidth/2+shift[1], screenHeight/2+shift[2])
	gpu.scale(zoom, zoom)
	
	for i = 1, #bodies, 1 do
		gpu.setColor(bodies[i].color)
		gpu.push()
		gpu.translate(bodies[i].pos[1], bodies[i].pos[2])
		gpu.line(bodies[i].shape)
		gpu.pop()
	end

	gpu.push()
	gpu.translate(player.pos[1], player.pos[2])
	drawFeatures.drawVector(player.force/100, "F", {1, 0, 0})
	drawFeatures.drawVector(player.impulse/100, "I", {0.8, 0, 0})
	gpu.pop()

	gpu.translate(-screenWidth/2, -screenHeight/2)
	gpu.setColor(1, 0, 0)
	gpu.line(0, 0, screenWidth, 0)
	gpu.line(screenWidth, 0, screenWidth, screenHeight)
	gpu.line(screenWidth, screenHeight, 0, screenHeight)
	gpu.line(0, screenHeight, 0, 0)

	gpu.pop()

	-- DEBUG INFORMATION --
	gpu.setColor(1, 0, 0)
	gpu.print("FPS: " .. love.timer.getFPS(), 0, 0)
end)