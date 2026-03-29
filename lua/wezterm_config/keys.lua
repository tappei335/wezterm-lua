local M = {}
local pane_equalize = require('wezterm_config.pane_equalize')

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
    { key = 'c', mods = 'CTRL', action = act.CopyTo('Clipboard') },
    { key = 'v', mods = 'CTRL', action = act.PasteFrom('Clipboard') },

    { key = 'LeftArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Left') },
    { key = 'DownArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Down') },
    { key = 'UpArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Up') },
    { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Right') },

    { key = '\'', mods = 'CTRL', action = act.SplitHorizontal({ domain="CurrentPaneDomain" }) },
    { key = 't', mods = 'CTRL', action = act.SplitHorizontal({ domain="CurrentPaneDomain" }) },

    { key = '¥', mods = 'CTRL', action = act.SplitVertical({ domain="CurrentPaneDomain" }) },
    { key = 'g', mods = 'CTRL', action = act.SplitVertical({ domain="CurrentPaneDomain" }) },

    { key = '/', mods = 'CTRL', action = act.CloseCurrentPane({ confirm = false }) },
    { key = 'q', mods = 'CTRL', action = act.CloseCurrentPane({ confirm = false }) },
    
    { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab('CurrentPaneDomain') },
    { key = 'q', mods = 'CTRL|SHIFT', action = act.CloseCurrentTab({ confirm = false }) },

    { key = 'r', mods = 'LEADER', action = act.ReloadConfiguration },
    { key = '-', mods = 'LEADER', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
    {
      key = 'h',
      mods = 'CTRL|SHIFT',
      action = wezterm.action_callback(function(_, pane)
        local new_pane = pane_equalize.split_horizontally(pane)
        if new_pane then
          new_pane:activate()
        end
      end),
    },
    { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
    {
      key = '=',
      mods = 'LEADER',
      action = wezterm.action_callback(function(window, pane)
        local ok, message = pane_equalize.equalize_full_height_columns(window, pane, wezterm)
        if not ok and message then
          window:toast_notification('wezterm', message, nil, 2000)
        end
      end),
    },
    -- { key = 'H', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Left', 5 }) },
    -- { key = 'J', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Down', 5 }) },
    -- { key = 'K', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Up', 5 }) },
    -- { key = 'L', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Right', 5 }) },
    { key = 'p', mods = 'LEADER', action = act.ActivateCommandPalette },
    { key = 'Space', mods = 'CTRL|SHIFT', action = act.QuickSelect },
  }
end

return M
