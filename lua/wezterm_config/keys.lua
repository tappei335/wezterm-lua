local M = {}
local pane_equalize = require('wezterm_config.pane_equalize')

function M.apply(config, wezterm)
  local act = wezterm.action
  local copy_or_sigtstp = wezterm.action_callback(function(window, pane)
    if window:get_selection_text_for_pane(pane) ~= '' then
      window:perform_action(act.CopyTo('Clipboard'), pane)
      return
    end

    window:perform_action(act.SendKey({ key = 'z', mods = 'CTRL' }), pane)
  end)
  local equalize_layout_columns = wezterm.action_callback(function(window, pane)
    local ok, message = pane_equalize.equalize_layout_columns(window, pane, wezterm)
    -- local title = ok and 'layout-equalize' or 'layout-equalize failed'
    -- window:toast_notification(title, message or 'No message', nil, 2000)
  end)

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
    { key = 'c', mods = 'CTRL', action = copy_or_sigtstp },
    { key = 'v', mods = 'CTRL', action = act.PasteFrom('Clipboard') },

    { key = 'LeftArrow', mods = 'CTRL', action = act.ActivatePaneDirection('Left') },
    { key = 'DownArrow', mods = 'CTRL', action = act.ActivatePaneDirection('Down') },
    { key = 'UpArrow', mods = 'CTRL', action = act.ActivatePaneDirection('Up') },
    { key = 'RightArrow', mods = 'CTRL', action = act.ActivatePaneDirection('Right') },
    { key = 'LeftArrow', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
    { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(1) },

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
      mods = 'LEADER',
      action = wezterm.action_callback(function(_, pane)
        local new_pane = pane_equalize.split_horizontally(pane)
        if new_pane then
          new_pane:activate()
        end
      end),
    },
    { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
    { key = '=', mods = 'LEADER', action = equalize_layout_columns },
    { key = '=', mods = 'LEADER|SHIFT', action = equalize_layout_columns },
    -- { key = 'H', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Left', 5 }) },
    -- { key = 'J', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Down', 5 }) },
    -- { key = 'K', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Up', 5 }) },
    -- { key = 'L', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Right', 5 }) },
    -- { key = 'p', mods = 'LEADER', action = act.ActivateCommandPalette },
    -- { key = 'Space', mods = 'CTRL|SHIFT', action = act.QuickSelect },
  }
end

return M
