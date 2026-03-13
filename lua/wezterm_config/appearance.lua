local M = {}

function M.apply(config, wezterm)
  config.color_scheme = 'Tokyo Night'
  config.window_background_opacity = 0.92
  config.text_background_opacity = 1.0
  config.window_padding = {
    left = 12,
    right = 12,
    top = 10,
    bottom = 10,
  }

  config.animation_fps = 120
  config.cursor_blink_rate = 500
  config.default_cursor_style = 'BlinkingBlock'

  if wezterm.target_triple:find('darwin') then
    config.macos_window_background_blur = 20
  end
end

return M

