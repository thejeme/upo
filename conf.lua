function love.conf(t)
  t.window.width, t.window.height = 960, 540
  for _, option in ipairs(arg or {}) do
    local units = tonumber(option:match("^%-%-canvas%-units=(%d+)$"))
    if units and units >= 40 and units <= 120 then
      t.window.width, t.window.height = units * 16, units * 9
    end
  end
  t.window.title = "upo"
  t.window.icon = 'assets/window-icon.png'
end
