local wezterm = require('wezterm')

local modules = {
  require('wezterm_config.options'),
  require('wezterm_config.appearance'),
  require('wezterm_config.fonts'),
  require('wezterm_config.keys'),
  require('wezterm_config.workspaces'),
}

local config = wezterm.config_builder and wezterm.config_builder() or {}

for _, module in ipairs(modules) do
  module.apply(config, wezterm)
end

return config

