local M = {}

function M.apply(config)
  config.use_ime = true
  config.color_scheme = 'Tokyo Night'
  config.window_background_opacity = 0.85
  config.macos_window_background_blur = 20
  config.disable_default_key_bindings = true
  -- bell
  config.audible_bell = "Disabled"
end

return M
