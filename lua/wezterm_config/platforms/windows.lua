local util = require('wezterm_config.util')

local M = {}

function M.apply(config, wezterm)
  config.default_prog = { 'pwsh.exe', '-NoLogo' }
  config.use_ime = true
  config.color_scheme = 'Kanagawa (Gogh)'
  config.window_background_opacity = 0.7

  util.append_keys(config, {
    {
      key = 'Enter',
      mods = 'SHIFT',
      action = wezterm.action.SendString('\x1b[13;2u'),
    },
    {
      key = 'Enter',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.SendString('\x1b[13;2u'),
    },
  })
end

return M
