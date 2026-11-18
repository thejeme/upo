simpleScale = {}
local scale, left, top = 1, 0, 0
local width, height = 0, 0

function simpleScale.resizeUpdate()
  width, height = love.graphics.getDimensions()
  if width <= 0 or height <= 0 then return end
  scale = math.min(width / gw, height / gh)
  left = (width - gw * scale) / 2
  top = (height - gh * scale) / 2
end

function simpleScale.set()
  love.graphics.push()
  love.graphics.translate(left, top)
  love.graphics.scale(scale)
end

function simpleScale.unSet()
  love.graphics.pop()
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(0, 0, 0, 1)
  if top > 0 then
    love.graphics.rectangle("fill", 0, 0, width, top)
    love.graphics.rectangle("fill", 0, height - top, width, top)
  elseif left > 0 then
    love.graphics.rectangle("fill", 0, 0, left, height)
    love.graphics.rectangle("fill", width - left, 0, left, height)
  end
  love.graphics.setColor(r, g, b, a)
end

function simpleScale.toGame(x, y)
  return (x - left) / scale, (y - top) / scale
end
