local M = {}

function M.apply(config, wezterm)
  local act = wezterm.action

  config.leader = {
    key = 'a',
    mods = 'CTRL',
    timeout_milliseconds = 1000,
  }

  config.keys = {
    {
      key = 'a',
      mods = 'LEADER|CTRL',
      action = act.SendKey({ key = 'a', mods = 'CTRL' }),
    },
    { key = 'r', mods = 'LEADER', action = act.ReloadConfiguration },
    { key = 'c', mods = 'LEADER', action = act.SpawnTab('CurrentPaneDomain') },
    { key = '-', mods = 'LEADER', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
    { key = '\\', mods = 'LEADER', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
    { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane({ confirm = false }) },
    { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
    { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection('Left') },
    { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection('Down') },
    { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection('Up') },
    { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection('Right') },
    { key = 'H', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Left', 5 }) },
    { key = 'J', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Down', 5 }) },
    { key = 'K', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Up', 5 }) },
    { key = 'L', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Right', 5 }) },
    { key = 'p', mods = 'LEADER', action = act.ActivateCommandPalette },
    { key = 'Space', mods = 'CTRL|SHIFT', action = act.QuickSelect },
  }
end

return M

