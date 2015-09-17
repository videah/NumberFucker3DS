local board = {}
local size_w = 3
local size_h = 3

local n
local min, max = 1, 9

local gameover = false

local biggest_x, biggest_y

local bigfont = love.graphics.newFont("Junction-bold.ttf", 54)
local smallfont = love.graphics.newFont("Junction-bold.ttf", 32)

local anim_from_x, anim_from_y
local anim_to_x, anim_to_y
local anim_from, anim_to
local anim_dt = 0
local anim_time = 0.35
local anim_after

math.randomseed(os.time())

-- tweening functions
local function inBack(a, b, t)
	if not s then s = 1.70158 end
	return (b - a) * t * t * ((s + 1) * t - s) + a
end
local function lerp(a, b, t)
	return (1 - t) * a + t * b
end
local function lerp2(a, b, t)
	return a + (b - a) * t
end
local function cerp(a, b, t)
	local f = (1 - math.cos(t * math.pi)) * 0.5
	return a * (1 - f) + b * f
end
local function getTileColor(n)
	local a = 60
	return 255, 255, 255, a
end

local function generate()
	n = math.random(min, max)

	biggest_x, biggest_y = nil, nil
	gameover = false

	for i = 1, size_h do
		board[i] = {}
		for j = 1, size_w do
			board[i][j] = 0
		end
	end

end

local function getField(x, y)

	x = x - 50
	y = y + 20

	x = math.floor((x - 4) / (64 + 4)) + 1
	y = math.floor((y - 4 - 40) / (64 + 4)) + 1

	print(x)

	return x, y
end

local update

local function launchAnim(x1, y1, x2, y2, from, to)
	anim_from_x, anim_from_y = x2, y2
	anim_to_x, anim_to_y = x1, y1
	anim_from, anim_to = from, to
	anim_dt = 0
end

local function merge(x1, y1, x2, y2)
	launchAnim(x1, y1, x2, y2, board[y2][x2], board[y1][x1])

	board[y1][x1] = board[y1][x1] + board[y2][x2]
	board[y2][x2] = 0

	anim_after = function()
		update(x1, y1)
	end
end

function update(x, y)
	if not biggest_x and not biggest_y then
		biggest_x, biggest_y = 1, 1
	end
	-- finds biggest
	for y, row in ipairs(board) do
		for x, field in ipairs(row) do
			if field > board[biggest_y][biggest_x] then
				biggest_x, biggest_y = x, y
			end
		end
	end

	-- find the biggest block around
	local maxval, maxx, maxy = math.huge
	local minval, minx, miny = 0
	for _, v in ipairs({{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}}) do
		local i, j = unpack(v)
		if board[j] and board[j][i] and board[j][i] ~= 0 then
			if board[j][i] < maxval and (board[j][i] % board[y][x]) == 0 then
				maxval, maxx, maxy = board[j][i], i, j
			end
		end
	end

	if maxval ~= math.huge then
		merge(maxx, maxy, x, y)
	end

	-- check if the board is all filled
	local occupied = 0
	for y, row in ipairs(board) do
		for x, field in ipairs(row) do
			if field ~= 0 then
				occupied = occupied + 1
			end
		end
	end

	if occupied == size_w * size_h then
		gameover = true
	end
end

local function place(x, y)
	if anim_from_x and anim_dt < anim_time then return end -- disable when the animation is running so can't bug combos
	if not board[y] or not board[y][x] then return end
	if not (board[y] and board[y][x] and board[y][x] ~= 0) then
		board[y][x] = n
	else
		return
	end

	n = math.random(min, max)

	update(x, y)
end

function love.load()
	io.stdout:setvbuf("no")

	generate()
end

function love.draw()
	love.graphics.setScreen('top')
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()

	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", 0, 0, w, h)

	love.graphics.setColor(255, 255, 255, 60)
	love.graphics.rectangle("fill", 0, 0, w, h)

	local font = bigfont
	local text = gameover and ("SCORE: " .. board[biggest_y][biggest_x]) or tostring(n)
	love.graphics.setFont(font)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.print(text, (w - font:getWidth(text)) / 2, (h / 2) - (font:getHeight() / 2))

	love.graphics.setScreen('bottom')

	love.graphics.push()

	love.graphics.translate(50, -20)

	for y, row in ipairs(board) do
		for x, field in ipairs(row) do
			if anim_from_x == x and anim_from_y == y and anim_dt < anim_time then
				field = 0
			end

			if field == 0 then
				love.graphics.setColor(255, 255, 255, 30)
			else
				love.graphics.setColor(getTileColor(field))
			end

			if x == biggest_x and y == biggest_y then
				love.graphics.setColor(255, 255, 255,  255)
			end

			local rx, ry = 4 + (x - 1) * (64 + 4), 4 + (y - 1) * (64 + 4) + 40
			love.graphics.rectangle("fill", rx, ry, 64, 64)

			if x == biggest_x and y == biggest_y then
				love.graphics.setColor(0, 0, 0)
			else
				love.graphics.setColor(255, 255, 255, 255)
			end

			if field ~= 0 then
				local font = smallfont
				local text = tostring(field)
				love.graphics.setFont(smallfont)
				love.graphics.print(text, rx + (64 - font:getWidth(text)) / 2, ry + (64 - font:getHeight()) / 2)
			end
		end
	end

	-- anim around the biggest
	if biggest_x then
		local rx, ry = 4 + (biggest_x - 1) * (64 + 4), 4 + (biggest_y - 1) * (64 + 4) + 40
		
		love.graphics.setColor(255, 255, 255, 15)
		love.graphics.circle("fill", rx + 64 / 2, ry + 64 / 2, 48 + math.cos(love.timer.getTime() * 2) * 8)
	end

	-- animations
	if anim_from_x and anim_dt < anim_time then
		-- draw the TO field
		local x, y = anim_to_x, anim_to_y

		local rx, ry = 4 + (x - 1) * (64 + 4), 4 + (y - 1) * (64 + 4) + 40
		-- under the transparent tile
		love.graphics.setColor(0, 0, 0)
		love.graphics.rectangle("fill", rx, ry, 64, 64)

		love.graphics.setColor(getTileColor(anim_to))

		if x == biggest_x and y == biggest_y then
			love.graphics.setColor(255, 255, 255)
		end

		love.graphics.rectangle("fill", rx, ry, 64, 64)
		
		if x == biggest_x and y == biggest_y then
			love.graphics.setColor(0, 0, 0)
		else
			love.graphics.setColor(255, 255, 255)
		end

		local font = smallfont
		local text = tostring(anim_to)
		love.graphics.setFont(smallfont)
		love.graphics.print(text, rx + (64 - font:getWidth(text)) / 2, ry + (64 - font:getHeight()) / 2)

		-- draw the flying tile

		local x = inBack(anim_from_x, anim_to_x, anim_dt / anim_time)
		local y = inBack(anim_from_y, anim_to_y, anim_dt / anim_time)

		local rx, ry = 4 + (x - 1) * (64 + 4), 4 + (y - 1) * (64 + 4) + 40

		love.graphics.setColor(0, 0, 0)
		love.graphics.rectangle("fill", rx, ry, 64, 64)

		love.graphics.setColor(getTileColor(anim_from))
		if anim_to_x == biggest_x and anim_to_y == biggest_y then
			love.graphics.setColor(255, 255, 255)
		end
		love.graphics.rectangle("fill", rx, ry, 64, 64)
		
		if anim_to_x == biggest_x and anim_to_y == biggest_y then
			love.graphics.setColor(0, 0, 0)
		else
			love.graphics.setColor(255, 255, 255)
		end

		local font = smallfont
		local text = tostring(anim_from)
		love.graphics.setFont(smallfont)
		love.graphics.print(text, rx + (64 - font:getWidth(text)) / 2, ry + (64 - font:getHeight()) / 2)
	end

	love.graphics.pop()

end

function love.update(dt)

	if love.keyboard.isDown('start') then love.event.quit() end

	anim_dt = anim_dt + dt

	if anim_dt - dt < anim_time and anim_dt > anim_time and anim_after then
		anim_after()
	end
end

function love.mousepressed(x, y, button)
	if gameover then
		generate()
		return
	end

	local x, y = getField(x, y)
	place(x, y)
end

