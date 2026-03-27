local M = {}

function M.apply(config)
  config.text_background_opacity = 1.0
  config.window_padding = {
    left = 12,
    right = 12,
    top = 10,
    bottom = 10,
  }

  config.window_background_opacity = 0.85
  config.animation_fps = 120
  config.cursor_blink_rate = 500
  config.default_cursor_style = 'BlinkingBlock'
  config.window_decorations = "RESIZE"
  config.hide_tab_bar_if_only_one_tab = true
  config.window_frame = {
    inactive_titlebar_bg = "none",
    active_titlebar_bg = "none",
  }
end

return M
