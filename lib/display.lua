local display = {}
local sizes = {
  {640, 360}, {800, 450}, {960, 540}, {1024, 576}, {1152, 648}, {1280, 720},
  {1366, 768}, {1600, 900}, {1920, 1080}, {2560, 1440}, {3200, 1800}, {3840, 2160},
}
local choices, index, monitor

-- A zero width means borderless fullscreen at the desktop's native size.
-- All other choices are window sizes. Leave space for borders and the taskbar.
function display.refresh(wanted)
  wanted = tonumber(wanted) or 0
  choices, index = {}, 1
  if webBuild then
    choices[1] = {0, 0}
    return
  end
  local _, _, current = love.window.getPosition()
  monitor = current
  local width, height = love.window.getDesktopDimensions(monitor)
  for _, size in ipairs(sizes) do
    if size[1] <= width - 16 and size[2] <= height - 64 then
      choices[#choices + 1] = size
      if size[1] <= wanted then index = #choices end
    end
  end
  if #choices == 0 then
    local unit = math.floor(math.min((width - 16) / 16, (height - 64) / 9))
    if unit > 0 then choices[1] = {16 * unit, 9 * unit} end
  end
  choices[#choices + 1] = {0, 0}
  if wanted <= 0 then index = #choices end
end

function display.load(settings)
  display.refresh(settings.windowWidth)
  display.apply()
end

function display.width() return choices[index][1] end

function display.label()
  if webBuild then return "Auto (browser)" end
  local size = choices[index]
  if size[1] == 0 then return "Fullscreen" end
  return size[1] .. " x " .. size[2]
end

function display.cycle(step)
  display.refresh(display.width())
  index = (index - 1 + step) % #choices + 1
end

function display.apply()
  display.refresh(display.width())
  local size = choices[index]
  if not webBuild then
    local function set(candidate)
      return love.window.setMode(candidate[1], candidate[2], {
        display = monitor, fullscreen = candidate[1] == 0,
        fullscreentype = "desktop", centered = true, vsync = 1,
      })
    end
    if not set(size) then
      index = 1
      assert(set(choices[index]), "Unable to open a window on this display")
    end
  end
  simpleScale.resizeUpdate()
end

return display
