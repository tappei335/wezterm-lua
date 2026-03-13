local wezterm = require('wezterm')

-- Allow require('wezterm_config...') from the local lua/ directory.
package.path = table.concat({
  package.path,
  wezterm.config_dir .. '/lua/?.lua',
  wezterm.config_dir .. '/lua/?/init.lua',
}, ';')

return require('wezterm_config')

