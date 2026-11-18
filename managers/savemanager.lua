local savemanager = {}
local levelCount = 6
local settingsFile = "settings-v1.dat"
local scoresFile = "highscores-v1.dat"

local function readNumbers(filename, limits)
  local info = love.filesystem.getInfo(filename, "file")
  if not info or info.size > 512 then return nil end

  local ok, data = pcall(love.filesystem.read, filename)
  if not ok or not data or #data > 512 then return nil end

  local values = {}
  for token in data:gmatch("%S+") do
    local limit = limits[#values + 1]
    local value = tonumber(token)
    if not limit or not value or value ~= value or value == math.huge or value < 0 or value > limit then
      return nil
    end
    values[#values + 1] = value
  end
  if #values == #limits then return values end
end

local function write(filename, values)
  local ok, written, err = pcall(love.filesystem.write, filename, table.concat(values, "\n") .. "\n")
  if not ok or not written then
    print("Could not save " .. filename .. ": " .. tostring(ok and err or written))
    return false
  end
  return true
end

function savemanager:load()
  local settings = readNumbers(settingsFile, {16384, 200}) or {0, 100}
  self.settings = {windowWidth = math.floor(settings[1]), volume = settings[2]}

  local defaults, limits = {}, {}
  for i = 1, levelCount do
    defaults[i], limits[i] = 0, math.huge
  end
  self.highscores = {levelScore = readNumbers(scoresFile, limits) or defaults}
end

function savemanager:saveHighscores()
  return write(scoresFile, self.highscores.levelScore)
end

function savemanager:saveSettings(windowWidth, volume)
  self.settings = {windowWidth = windowWidth, volume = volume}
  return write(settingsFile, {windowWidth, volume})
end

_G.savemanager = savemanager
return savemanager
