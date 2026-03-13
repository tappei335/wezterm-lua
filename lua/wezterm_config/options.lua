local M = {}

function M.apply(config)
  config.automatically_reload_config = true
  config.check_for_updates = false
  config.adjust_window_size_when_changing_font_size = false
  config.window_close_confirmation = 'NeverPrompt'
  config.switch_to_last_active_tab_when_closing_tab = true

  config.scrollback_lines = 10000
  config.tab_max_width = 32
  config.use_fancy_tab_bar = false
  config.hide_tab_bar_if_only_one_tab = true
  config.show_new_tab_button_in_tab_bar = false

  config.inactive_pane_hsb = {
    saturation = 0.9,
    brightness = 0.8,
  }
end

return M

