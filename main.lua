local METER = 64
local WINDOW_X = 640
local WINDOW_Y = 640

local force = 100
local grav_x = 0
local grav_y = 0
local current = "force"

local state = {}
state.drawing = false
state.shape = nil
state.body_type = "static"
state.origin = {}

Button = {}
Button.__index = Button
setmetatable(Button, {
  __call = function(cls, ...)
    return cls.new(...)
  end,
})

function Button.new(x, y, image, draw)
  local self = setmetatable({}, Button)
  self.x = x
  self.y = y
  self.w = 32
  self.h = 32
  if image ~= nil then self.image = image end
  if draw ~= nil then self.draw = draw end
  return self
end

function Button:collide(x, y)
  return x > self.x and y > self.y and x < self.x + self.w and y < self.y + self.h
end

function Button:draw()
  love.graphics.draw(self.image, self.x, self.y)
end

buttons = {}
buttons.rect_button = Button(10, 10, nil, function (self)
    love.graphics.setColor(216, 178, 33)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    if state.body_type == "dynamic" then
      love.graphics.setColor(100, 201, 55)
    else --static
      love.graphics.setColor(201, 33, 33)
    end
    love.graphics.rectangle("fill", self.x+4, self.y+4, self.w-8, self.h-8)
  end)
buttons.rect_button.state = "rect"

buttons.circ_button = Button(52, 10, nil, function (self)
    love.graphics.setColor(216, 178, 33)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    if state.body_type == "dynamic" then
      love.graphics.setColor(100, 201, 55)
    else --static
      love.graphics.setColor(201, 33, 33)
    end
    love.graphics.circle("fill", self.x + self.w/2, self.y + self.h/2, self.w/2 - 2, 300)
  end)
buttons.circ_button.state = "circle"

function love.load()
  love.physics.setMeter(METER)
  world = love.physics.newWorld(grav_x, grav_y, true)

  objects = {}

  --let's create the ground
  objects.ground = {}
  objects.ground.body = love.physics.newBody(world, 640/2, 640-50/2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
  objects.ground.shape = love.physics.newRectangleShape(640, 50) --make a rectangle with a width of 650 and a height of 50
  objects.ground.fixture = love.physics.newFixture(objects.ground.body, objects.ground.shape); --attach shape to body
  objects.ground.fixture:setRestitution(0.5)
  objects.wall_left = {}
  objects.wall_left.body = love.physics.newBody(world, 0, 640/2)
  objects.wall_left.shape = love.physics.newRectangleShape(0, 640)
  objects.wall_left.fixture = love.physics.newFixture(objects.wall_left.body, objects.wall_left.shape);
  objects.wall_left.fixture:setRestitution(1)
  objects.wall_right = {}
  objects.wall_right.body = love.physics.newBody(world, 640, 640/2)
  objects.wall_right.shape = love.physics.newRectangleShape(0, 640)
  objects.wall_right.fixture = love.physics.newFixture(objects.wall_right.body, objects.wall_right.shape);
  objects.wall_right.fixture:setRestitution(1)
  objects.ceiling = {}
  objects.ceiling.body = love.physics.newBody(world, 640/2, 0)
  objects.ceiling.shape = love.physics.newRectangleShape(640, 0)
  objects.ceiling.fixture = love.physics.newFixture(objects.ceiling.body, objects.ceiling.shape);
  objects.ceiling.fixture:setRestitution(1)

  --let's create a ball
  objects.ball = {}
  objects.ball.body = love.physics.newBody(world, 640/2, 640/2, "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
  objects.ball.shape = love.physics.newRectangleShape(20, 20) --the ball's shape has a radius of 20
  objects.ball.fixture = love.physics.newFixture(objects.ball.body, objects.ball.shape, 1) -- Attach fixture to body and give it a density of 1.
  objects.ball.fixture:setRestitution(0.9) --let the ball bounce

  --let's create a couple blocks to play around with
  objects.block1 = {}
  objects.block1.body = love.physics.newBody(world, 200, 550, "dynamic")
  objects.block1.shape = love.physics.newRectangleShape(0, 0, 50, 100)
  objects.block1.fixture = love.physics.newFixture(objects.block1.body, objects.block1.shape, 5) -- A higher density gives it more mass.

  objects.block2 = {}
  objects.block2.body = love.physics.newBody(world, 200, 400, "dynamic")
  objects.block2.shape = love.physics.newRectangleShape(0, 0, 100, 50)
  objects.block2.fixture = love.physics.newFixture(objects.block2.body, objects.block2.shape, 2)

  --initial graphics setup
  love.graphics.setBackgroundColor(104, 136, 248) --set the background color to a nice blue

  love.window.setMode(WINDOW_X, WINDOW_Y)
end

function love.update(dt)
  world:update(dt)
  if love.keyboard.isDown("right") then
    objects.ball.body:applyForce(force, 0)
  elseif love.keyboard.isDown("left") then
    objects.ball.body:applyForce(-force, 0)
  end

  if love.keyboard.isDown("up") then
    objects.ball.body:applyForce(0, -force)
  elseif love.keyboard.isDown("down") then
    objects.ball.body:applyForce(0, force)
  end

  if love.keyboard.isDown("q") then
    objects.ball.body:applyTorque(-force)
  elseif love.keyboard.isDown("e") then
    objects.ball.body:applyTorque(force)
  end

  if love.keyboard.isDown("pagedown") then
    if current == "force" then
      force = force + 1
    elseif current == "grav_x" then
      grav_x = grav_x + 1
      world:setGravity(grav_x, grav_y)
    elseif current == "grav_y" then
      grav_y = grav_y + 1
      world:setGravity(grav_x, grav_y)
    end
  elseif love.keyboard.isDown("pageup") then
    if current == "force" then
      force = force - 1
      if force < 0 then
        force = 0
      end
    elseif current == "grav_x" then
      grav_x = grav_x - 1
      world:setGravity(grav_x, grav_y)
    elseif current == "grav_y" then
      grav_y = grav_y - 1
      world:setGravity(grav_x, grav_y)
    end
  end

end

function love.mousepressed(x, y, button)
  if button == 'l' then
    local buttonclick = false
    for i, b in pairs(buttons) do
      if b:collide(love.mouse.getPosition()) then
        state.shape = b.state
        buttonclick = true
      end
    end

    if not buttonclick and state.shape then
      state.color = {love.math.random(255), love.math.random(255), love.math.random(255)}
      state.drawing = true
      print("drawing!")
      state.origin.x, state.origin.y = x, y
    end
  elseif button == 'r' then
    if state.body_type == "static" then
      state.body_type = "dynamic"
    else
      state.body_type = "static"
    end
  end
end

function love.mousereleased()
  if state.drawing then
    state.drawing = false
    local w = state.origin.x - love.mouse.getX()
    local h = state.origin.y - love.mouse.getY()
    local new_object = {}
    new_object.body = love.physics.newBody(world, state.origin.x - w/2, state.origin.y - h/2, state.body_type)
    new_object.type = state.shape
    new_object.color = {love.graphics.getColor()}
    if state.shape == "rect" then
      new_object.shape = love.physics.newRectangleShape(math.abs(w), math.abs(h))
    elseif state.shape == "circle" then
      new_object.shape = love.physics.newCircleShape(math.sqrt((love.mouse.getX() - state.origin.x) ^ 2 + (love.mouse.getY() - state.origin.y) ^ 2))
    end
    new_object.fixture = love.physics.newFixture(new_object.body, new_object.shape)
    table.insert(objects, new_object)
  end
end

function love.keypressed(key, isrepeat)
  if key == "end" and not isrepeat then
    if current == "force" then
      current = "grav_x"
    elseif current == "grav_x" then
      current = "grav_y"
    elseif current == "grav_y" then
      current = "force"
    end
  elseif key == "home" and not isrepeat then
    if current == "force" then
      current = "grav_y"
    elseif current == "grav_y" then
      current = "grav_x"
    elseif current == "grav_x" then
      current = "force"
    end
  end
end

function love.draw()
  love.graphics.setColor(100, 201, 55)
  love.graphics.polygon("fill", objects.ground.body:getWorldPoints(objects.ground.shape:getPoints())) -- draw a "filled in" polygon using the ground's coordinates
  love.graphics.setColor(193, 47, 14) --set the drawing color to red for the ball
  --love.graphics.circle("fill", objects.ball.body:getX(), objects.ball.body:getY(), objects.ball.shape:getRadius())
  love.graphics.polygon("fill", objects.ball.body:getWorldPoints(objects.ball.shape:getPoints())) -- draw a "filled in" polygon using the ground's coordinates
  love.graphics.setColor(50, 50, 50) -- set the drawing color to grey for the blocks
  love.graphics.polygon("fill", objects.block1.body:getWorldPoints(objects.block1.shape:getPoints()))
  love.graphics.polygon("fill", objects.block2.body:getWorldPoints(objects.block2.shape:getPoints()))

  love.graphics.print("force: " .. force, WINDOW_X - 100, 20)
  love.graphics.print("grav_x: " .. grav_x, WINDOW_X - 100, 40)
  love.graphics.print("grav_y: " .. grav_y, WINDOW_X - 100, 60)

  for i, v in ipairs(objects) do
    love.graphics.setColor(unpack(v.color))
    if v.type == "rect" then
      love.graphics.polygon("fill", v.body:getWorldPoints(v.shape:getPoints()))
    elseif v.type == "circle" then
      love.graphics.circle("fill", v.body:getX(), v.body:getY(), v.shape:getRadius())
    end
  end

  local locatory_y = 0
  if current == "force" then
    locatory_y = 20
  elseif current == "grav_x" then

    locatory_y = 40
  elseif current == "grav_y" then
    locatory_y = 60
  end

  -- draw the buttons
  for i, button in pairs(buttons) do
    button:draw()
  end

  -- when mousedown, draw corresponding shape on top
  if state.drawing then
    love.graphics.setColor(state.color)
    if state.shape == "rect" then
      love.graphics.rectangle("fill", state.origin.x, state.origin.y, love.mouse.getX() - state.origin.x, love.mouse.getY() - state.origin.y)
    elseif state.shape == "circle" then
      love.graphics.circle("fill", state.origin.x, state.origin.y, math.sqrt((love.mouse.getX() - state.origin.x) ^ 2 + (love.mouse.getY() - state.origin.y) ^ 2) ,300)
    end
  end

  love.graphics.print(">", WINDOW_X - 110, locatory_y)
end

