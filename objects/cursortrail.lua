local trail = {}
trail.__index = trail

local interval = 1 / 60
local capacity = math.ceil((1 / 13) / interval) + 1

function trail.new()
  local samples = {}
  for i = 1, capacity do samples[i] = {} end
  return setmetatable({samples = samples, next = 1, elapsed = 0, time = 0}, trail)
end

function trail:update(dt, x, y)
  local lastX, lastY = self.x or x, self.y or y
  self.x, self.y = x, y
  self.time = self.time + dt
  self.elapsed = self.elapsed + dt
  -- Skip samples that would already have expired after a long frame.
  if self.elapsed > (1 / 13) + interval then
    self.elapsed = (1 / 13) + self.elapsed % interval
  end
  while self.elapsed + 1e-9 >= interval do
    self.elapsed = math.max(0, self.elapsed - interval)
    local age = self.elapsed
    local fraction = dt > 0 and math.max(0, 1 - age / dt) or 1
    local sample = self.samples[self.next]
    sample.x = lastX + (x - lastX) * fraction
    sample.y = lastY + (y - lastY) * fraction
    sample.time = self.time - age
    self.next = self.next % capacity + 1
  end
end

function trail:draw(r, g, b)
  for offset = 0, capacity - 1 do
    local sample = self.samples[(self.next - 1 + offset) % capacity + 1]
    if sample.time then
      local age = self.time - sample.time
      local alpha = 1 - age * 13
      if alpha > 0 then
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.circle("fill", sample.x, sample.y, 15 - age * 7)
      end
    end
  end
end

return trail
