require 'lib/simpleScale'
local display = require 'lib/display'

require 'globals'
require 'colors'

require 'managers/statemanager'
require 'managers/savemanager'

webBuild = love.system.getOS() == "Web"
for _, value in ipairs(arg or {}) do
  if value == "--web" then webBuild = true end
end
local discordRPC
if love.system.getOS() == "Windows" and not webBuild then
  local ok, rpc = pcall(require, "lib/discordRPC")
  if ok then discordRPC = rpc end
end
local pointerMode = "mouse"
local touchId
local appId = require 'applicationId'

function love.load()
  savemanager:load()
  volumeValue = savemanager.settings.volume or 100
  display.load(savemanager.settings)
  statemanager:load()
  math.randomseed(os.time())
  cursor:load()
  love.graphics.setBackgroundColor(0.1, 0.1, 0.1, 1)
  love.mouse.setVisible(false)

  joystick = love.joystick.getJoysticks()[1]

  isJoystickMove = joystick ~= nil and joystick:isGamepad()
  joystickNoticeTextOpacity = 0

  if discordRPC then discordRPC.initialize(appId, true) end
  now = os.time(os.date("*t"))
  nextPresenceUpdate = 0
end

function discordApplyPresence()
  if statemanager:getState() == "game" then
    detailsNow = "Playing " .. maingame:getSong()
    stateNow = "By " .. maingame:getArtist()
  else
    detailsNow = "In Mainmenu"
    stateNow = ""
  end

  presence = {
    largeImageKey = "icon",
    largeImageText = "upo",
    details = detailsNow,
    state = stateNow,
    startTimestamp = now,
  }

  return presence
end

function love.update(dt)
  if pointerMode == "mouse" then
    mx, my = simpleScale.toGame(love.mouse.getPosition())
  end

  statemanager:update(dt)

  if discordRPC and nextPresenceUpdate < love.timer.getTime() then
      discordRPC.updatePresence(discordApplyPresence())
      nextPresenceUpdate = love.timer.getTime() + 2.0
  end
  if discordRPC then discordRPC.runCallbacks() end
end

function love.draw()
	simpleScale.set()
    statemanager:draw()
	simpleScale.unSet()
end

function love.mousemoved(x, y, dx, dy, istouch)
  if not istouch and (dx ~= 0 or dy ~= 0) then pointerMode = "mouse" end
end

function love.resize() simpleScale.resizeUpdate() end

function love.mousepressed(x, y, button, istouch)
  if istouch then return end
  pointerMode = "mouse"
  mx, my = simpleScale.toGame(x, y)
  statemanager:mousepressed(mx, my, button)
end

function love.gamepadpressed(joystick, button)
  statemanager:gamepadpressed(joystick, button)
  if (button == "y" and statemanager:getState() == "menu" and joystick ~= nil) then
    isJoystickMove = not isJoystickMove
    joystickNoticeTextOpacity = 1
  end
end

function love.keypressed(key)
  statemanager:keypressed(key)
  if (key == "y" and statemanager:getState() == "menu" and joystick ~= nil) then
    isJoystickMove = not isJoystickMove
    joystickNoticeTextOpacity = 1
  end
end

function love.joystickadded(jstick)
  if not jstick:isGamepad() then return end
  joystick = jstick
  isJoystickMove = true
end

function love.joystickremoved(jstick)
  if (joystick == jstick) then
    joystick = nil
    if (isJoystickMove) then
      isJoystickMove = false
      joystickNoticeTextOpacity = 1
    end
  end
end

function love.quit()
  if discordRPC then discordRPC.shutdown() end
end

function love.touchpressed(id, x, y)
  if touchId then return end
  touchId, pointerMode, isJoystickMove = id, "touch", false
  mx, my = simpleScale.toGame(x, y)
  statemanager:mousepressed(mx, my, 1)
end

function love.touchmoved(id, x, y)
  if id == touchId then mx, my = simpleScale.toGame(x, y) end
end

function love.touchreleased(id)
  if id == touchId then touchId = nil end
end
