local M = {}

function M.detect(wezterm)
  local target = wezterm.target_triple or ''

  if target:find('windows') then
    return 'windows'
  end

  if target:find('darwin') then
    return 'macos'
  end

  if target:find('linux') then
    return 'linux'
  end

  return 'unknown'
end

function M.module_names(wezterm)
  local platform = M.detect(wezterm)
  local module_names = {
    windows = { 'wezterm_config.platforms.windows' },
    macos = { 'wezterm_config.platforms.macos' },
    linux = { 'wezterm_config.platforms.linux' },
  }

  return module_names[platform] or {}
end

return M
