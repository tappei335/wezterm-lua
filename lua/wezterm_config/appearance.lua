local theme = require('wezterm_config.theme')

local M = {}

function M.apply(config)
  local colors = theme.colors

  config.text_background_opacity = 1.0
  config.window_padding = {
    left = 10,
    right = 10,
    top = 8,
    bottom = 8,
  }

  config.window_background_opacity = 0.92
  config.animation_fps = 120
  config.cursor_blink_rate = 500
  config.default_cursor_style = 'BlinkingBlock'
  config.window_decorations = 'RESIZE'
  config.hide_tab_bar_if_only_one_tab = true
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
      background = colors.bg_dark,
      active_tab = {
        bg_color = colors.bg_visual,
        fg_color = colors.fg,
        intensity = 'Bold',
      },
      inactive_tab = {
        bg_color = colors.bg_highlight,
        fg_color = colors.fg_dim,
      },
      inactive_tab_hover = {
        bg_color = colors.bg_visual,
        fg_color = colors.fg,
        italic = false,
      },
      new_tab = {
        bg_color = colors.bg_dark,
        fg_color = colors.muted,
      },
      new_tab_hover = {
        bg_color = colors.bg_highlight,
        fg_color = colors.fg,
        italic = false,
      },
    },
  }
  config.window_frame = {
    inactive_titlebar_bg = colors.bg_dark,
    active_titlebar_bg = colors.bg_dark,
  }
end

return M
