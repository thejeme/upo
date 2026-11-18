local trail = require("objects/cursortrail").new()
local cursortrail_array = {}

function cursortrail_array:draw()
  trail:draw(42 / 255, 49 / 255, 61 / 255)
end

function cursortrail_array:update(dt, x, y)
  trail:update(dt, x, y)
end

return cursortrail_array
