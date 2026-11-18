require 'managers/levelmanager'

require 'objects/cursor'

require 'objects/circle'
require 'objects/circle2'
require 'objects/square'
require 'objects/kite'
require 'objects/triangle'
require 'objects/laser'
require 'objects/laser2'

local effectcircle = require 'objects/effectcircle'

maingame = {}

levelSongs = {love.audio.newSource("songs/ParagonX9 - Chaoz Airflow.mp3", "stream"),
              love.audio.newSource("songs/Hinkik - Explorers.mp3", "stream"),
              love.audio.newSource("songs/Hinkik - Time Leaper.mp3", "stream"),
              love.audio.newSource("songs/Lchavasse - Lunar Abyss.mp3", "stream"),
              love.audio.newSource("songs/Xtrullor - Supernova.mp3", "stream"),
              love.audio.newSource("songs/Kurokotei - Galaxy Collapse.mp3", "stream")}

local hiddenBG = love.graphics.newImage("assets/hidden.png")
local level1BG = love.graphics.newImage("assets/level01.png")
local level2BG = love.graphics.newImage("assets/level02.png")
local level3BG = love.graphics.newImage("assets/level03.png")

local levelIndex
local timer
local paused
local lastX, lastY
local continueButton
local maxFrameTime = 0.1
local maxStep = 1 / 120

function maingame:load()
  continueButton = newButton(gw/2 - 200, gh*0.44, 400, 130, function() maingame:resume() end)
  restartButton = newButton(gw/2 - 200, gh*0.44, 400, 130, function() maingame:restart() end)
  exitButton = newButton(gw/2 - 200, gh*0.56, 400, 130, function() maingame:endLevel() end)

  failsound = love.audio.newSource("assets/failsound.wav", "static")
  failsound:setVolume(volumeValue * 0.001)
end

function maingame:pauseForInterruption()
  if isEndGame or paused then return end
  paused = true
  gamemusic:pause()
end

function maingame:resume()
  if not paused then return end
  paused = false
  lastX, lastY = nil, nil
  gamemusic:play()
end

function maingame:update(dt)
  if dt > maxFrameTime then
    self:pauseForInterruption()
    dt = 0
  end

  cursor:update(dt, isEndGame or paused, levelIndex)
  if paused then
    continueButton:update(dt)
    return
  end

  effectcircle:update(dt)
  if isEndGame then
    restartButton:update(dt)
    exitButton:update(dt)
    return
  end

  local x, y = cursor:getPositionX(), cursor:getPositionY()
  local fromX, fromY = lastX or x, lastY or y
  lastX, lastY = x, y
  local dx, dy = x - fromX, y - fromY
  local distance = math.sqrt(dx * dx + dy * dy)
  local angle, sweep
  if levelIndex == 3 then
    angle = math.atan2(fromY - gh / 2, fromX - gw / 2)
    local target = math.atan2(y - gh / 2, x - gw / 2)
    sweep = (target - angle + math.pi) % (2 * math.pi) - math.pi
    distance = math.abs(sweep) * (450 - 19)
  end

  -- Subdivide both elapsed time and cursor travel to cover fast crossings.
  local steps = math.max(1, math.ceil(dt / maxStep), math.ceil(distance / 8))
  local step = dt / steps
  for i = 1, steps do
    local fraction = i / steps
    local px, py = fromX + dx * fraction, fromY + dy * fraction
    if angle then
      local position = angle + sweep * fraction
      px = gw / 2 + math.cos(position) * (450 - 19)
      py = gh / 2 + math.sin(position) * (450 - 19)
    end

    circle:update(step)
    circle2:update(step)
    square:update(step)
    kite:update(step)
    triangle:update(step)
    laser:update(step)
    laser2:update(step)

    if cursor:collidesAt(px, py) then
      self:die()
      return
    end

    timer = timer + step
  end
  levelmanager:update(dt, timer, levelIndex)
end

function maingame:draw()
  love.graphics.setColor(58 / 255, 65 / 255, 81 / 255, 1)
    love.graphics.setLineWidth(4)
  love.graphics.circle("fill", gw / 2, gh / 2, 450)
  if not (isEndGame) then
    circle:draw()
    circle2:draw()
    square:draw()
    kite:draw()
    triangle:draw()
    laser:draw()
    laser2:draw()
  end

  love.graphics.setColor(White)
  love.graphics.setFont(scoreFont)

  if (levelIndex == 3) then
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.circle("fill", gw / 2, gh / 2, 120)
    love.graphics.setColor(White)
    love.graphics.circle("line", gw / 2, gh / 2, 120)
    love.graphics.draw(level1BG)
    love.graphics.circle("line", gw / 2, gh / 2, 450)
    love.graphics.printf(string.format("%0.1f", timer), 0, gh*0.2, gw, "center")
  elseif (levelIndex == 4) then
    love.graphics.draw(level3BG)
    love.graphics.circle("line", gw / 2, gh / 2, 225)
    love.graphics.printf(string.format("%0.1f", timer), 0, gh*0.4, gw, "center")
  elseif (levelIndex == 5) then
    love.graphics.draw(level2BG)
    love.graphics.draw(hiddenBG, cursor:getPositionX(), cursor:getPositionY(), 0, 1, 1, hiddenBG:getWidth() / 2, hiddenBG:getHeight() / 2)
    love.graphics.circle("line", gw / 2, gh / 2, 450)
    love.graphics.printf(string.format("%0.1f", timer), 0, gh*0.2, gw, "center")
  else
    love.graphics.draw(level1BG)
    love.graphics.circle("line", gw / 2, gh / 2, 450)
    love.graphics.printf(string.format("%0.1f", timer), 0, gh*0.2, gw, "center")
  end
  effectcircle:draw()
  cursor:draw(isEndGame, levelIndex)
  if paused then
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", 0, 0, gw, gh)
    love.graphics.setColor(White)
    love.graphics.setFont(bigScoreFont)
    love.graphics.printf("Paused", 0, gh * 0.30, gw, "center")
    love.graphics.setColor(continueButton:getHoverState() and White or {0.7, 0.7, 0.7, 1})
    love.graphics.printf("Continue", 0, gh * 0.44, gw, "center")
  elseif isEndGame then
    maingame:endScreen()
  end
end

function maingame:mousepressed(x, y, button)
  if paused then
    continueButton:mousepressed(x, y, button)
  elseif (isEndGame) then
    restartButton:mousepressed(x, y, button)
    exitButton:mousepressed(x, y, button)
  end
end

function maingame:gamepadpressed(joystick, button)
  if paused then
    if button == "start" or button == "a" then self:resume() end
    return
  end
  if (button == "start" or button == "back") then
    maingame:die()
  end
  if (isEndGame) then
    restartButton:gamepadpressed(joystick, button)
    exitButton:gamepadpressed(joystick, button)
  end
end

function maingame:keypressed(key)
  if paused then
    if key == "escape" or key == "return" or key == "space" then self:resume() end
  elseif key == "escape" then
    self:die()
  end
end

function maingame:loadLevel(index)
  levelIndex = index
  gamemusic = levelSongs[levelIndex]
  gamemusic:setVolume(volumeValue * 0.001)
  gamemusic:setLooping(true)
  maingame:restart()
end

function maingame:die()
  if isEndGame then return end
  isEndGame = true
  circle:clear()
  circle2:clear()
  square:clear()
  kite:clear()
  triangle:clear()
  laser:clear()
  laser2:clear()
  gamemusic:stop()
  failsound:play()

  if (timer > savemanager.highscores.levelScore[levelIndex]) then
    savemanager.highscores.levelScore[levelIndex] = tonumber(string.format("%0.1f", timer))
    savemanager:saveHighscores()
  end
end

function maingame:endScreen()
  love.graphics.setColor(0, 0, 0, 0.2)
  love.graphics.rectangle('fill', 0, 0, gw, gh)

  love.graphics.setFont(bigScoreFont)
  if (restartButton:getHoverState()) then
    love.graphics.setColor(White)
  else
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
  end
  love.graphics.printf("Restart", 0, gh*0.44, gw, "center")

  if (exitButton:getHoverState()) then
    love.graphics.setColor(White)
  else
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
  end
  love.graphics.printf(webBuild and "Levels" or "Exit", 0, gh*0.56, gw, "center")

  love.graphics.setFont(levelScoreFont)
  love.graphics.setColor(White)
  if (timer > savemanager.highscores.levelScore[levelIndex]) then
    if (levelIndex == 4) then
      love.graphics.printf("NEW PERSONAL BEST", 0, gh*0.37, gw, "center")
    else
      love.graphics.printf("NEW PERSONAL BEST", 0, gh*0.17, gw, "center")
    end
  end
end

function maingame:restart()
  timer = 0
  isEndGame = false
  paused = false
  lastX, lastY = nil, nil
  gamemusic:play()
  levelmanager:loadLevel(levelIndex)
end

function maingame:endLevel()
  statemanager:changeState("menu")
  gamemusic:stop()
  menumusic:play()
end

function maingame:getSong()
  if (levelIndex == 1) then
    return "Chaoz Airflow"
  elseif (levelIndex == 2) then
    return "Explorers"
  elseif (levelIndex == 3) then
    return "Time Leaper"
  elseif (levelIndex == 4) then
    return "Lunar Abyss"
  elseif (levelIndex == 5) then
    return "Supernova"
  elseif (levelIndex == 6) then
    return "Galaxy Collapse"
  end
end

function maingame:getArtist()
  if (levelIndex == 1) then
    return "ParagonX9"
  elseif (levelIndex == 2) then
    return "Hinkik"
  elseif (levelIndex == 3) then
    return "Hinkik"
  elseif (levelIndex == 4) then
    return "Lchavasse"
  elseif (levelIndex == 5) then
    return "Xtrullor"
  elseif (levelIndex == 6) then
    return "Kurokotei"
  end
end

return maingame
