local theme = require('wezterm_config.theme')

local M = {}

function M.apply(config)
  local colors = theme.colors
  local ui = theme.ui

  config.text_background_opacity = 1.0
  config.window_padding = {
    left = 12,
    right = 12,
    top = 10,
    bottom = 8,
  }

  config.window_background_opacity = 0.92
  config.animation_fps = 120
  config.cursor_blink_rate = 500
  config.default_cursor_style = 'BlinkingBlock'
  config.window_decorations = 'RESIZE'
  config.tab_bar_at_bottom = false
  config.colors = {
    foreground = colors.fg,
    background = colors.bg,
    cursor_bg = colors.yellow,
    cursor_border = colors.yellow,
    cursor_fg = colors.bg,
    selection_bg = colors.selection,
    selection_fg = colors.fg,
    scrollbar_thumb = colors.muted,
    split = colors.muted,
    tab_bar = {
      background = ui.tab_bar_bg,
      active_tab = {
        bg_color = ui.tab_active,
        fg_color = colors.fg,
        intensity = 'Bold',
      },
      inactive_tab = {
        bg_color = ui.tab_inactive,
        fg_color = colors.fg_dim,
      },
      inactive_tab_hover = {
        bg_color = ui.tab_hover,
        fg_color = colors.fg,
        italic = false,
      },
      new_tab = {
        bg_color = ui.tab_bar_bg,
        fg_color = ui.status_muted,
      },
      new_tab_hover = {
        bg_color = ui.tab_inactive,
        fg_color = colors.fg,
        italic = false,
      },
    },
  }
  config.window_frame = {
    inactive_titlebar_bg = ui.window_frame,
    active_titlebar_bg = ui.window_frame,
  }
end

return M
