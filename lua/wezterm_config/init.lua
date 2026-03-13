local wezterm = require('wezterm')
local platform = require('wezterm_config.platform')

local module_names = {
  'wezterm_config.options',
  'wezterm_config.appearance',
  'wezterm_config.fonts',
  'wezterm_config.keys',
  'wezterm_config.workspaces',
}

for _, module_name in ipairs(platform.module_names(wezterm)) do
  table.insert(module_names, module_name)
end

local config = wezterm.config_builder and wezterm.config_builder() or {}

for _, module_name in ipairs(module_names) do
  local module = require(module_name)
  module.apply(config, wezterm)
end

return config
