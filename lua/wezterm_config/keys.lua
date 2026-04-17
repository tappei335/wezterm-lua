local M = {}
local pane_equalize = require('wezterm_config.pane_equalize')

function M.apply(config, wezterm)
  local act = wezterm.action
  local function switch_to_named_workspace()
    return act.PromptInputLine({
      description = wezterm.format({
        { Attribute = { Intensity = 'Bold' } },
        { Text = 'Workspace name' },
      }),
      action = wezterm.action_callback(function(window, pane, line)
        if not line then
          return
        end

        local name = line:match('^%s*(.-)%s*$')
        if name == '' then
          return
        end

        window:perform_action(act.SwitchToWorkspace({ name = name }), pane)
      end),
    })
  end

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

    { key = 'c', mods = 'LEADER', action = act.SpawnTab('CurrentPaneDomain') },
    { key = ';', mods = 'LEADER', action = act.ActivateLastTab },
    { key = 'n', mods = 'LEADER', action = act.SwitchWorkspaceRelative(1) },
    { key = 'p', mods = 'LEADER', action = act.SwitchWorkspaceRelative(-1) },
    {
      key = 's',
      mods = 'LEADER',
      action = act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES', title = 'Workspaces' }),
    },
    { key = 'w', mods = 'LEADER', action = switch_to_named_workspace() },
    { key = '[', mods = 'LEADER', action = act.ActivateCopyMode },
    { key = 'Space', mods = 'LEADER', action = act.QuickSelect },
    {
      key = 'P',
      mods = 'LEADER|SHIFT',
      action = act.PaneSelect({ alphabet = '1234567890', mode = 'Activate', show_pane_ids = true }),
    },
    {
      key = 'a',
      mods = 'LEADER',
      action = act.ActivateKeyTable({ name = 'activate_pane', timeout_milliseconds = 1000 }),
    },
    {
      key = 'r',
      mods = 'LEADER',
      action = act.ActivateKeyTable({ name = 'resize_pane', one_shot = false }),
    },
    { key = ':', mods = 'LEADER|SHIFT', action = act.ActivateCommandPalette },
    { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane({ confirm = true }) },
    { key = 'q', mods = 'LEADER|SHIFT', action = act.CloseCurrentTab({ confirm = true }) },
    { key = 'r', mods = 'LEADER|SHIFT', action = act.ReloadConfiguration },
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

  for i = 1, 9 do
    table.insert(config.keys, {
      key = tostring(i),
      mods = 'LEADER',
      action = act.ActivateTab(i - 1),
    })
  end

  config.key_tables = config.key_tables or {}
  config.key_tables.activate_pane = {
    { key = 'LeftArrow', action = act.ActivatePaneDirection('Left') },
    { key = 'h', action = act.ActivatePaneDirection('Left') },
    { key = 'RightArrow', action = act.ActivatePaneDirection('Right') },
    { key = 'l', action = act.ActivatePaneDirection('Right') },
    { key = 'UpArrow', action = act.ActivatePaneDirection('Up') },
    { key = 'k', action = act.ActivatePaneDirection('Up') },
    { key = 'DownArrow', action = act.ActivatePaneDirection('Down') },
    { key = 'j', action = act.ActivatePaneDirection('Down') },
  }
  config.key_tables.resize_pane = {
    { key = 'LeftArrow', action = act.AdjustPaneSize({ 'Left', 3 }) },
    { key = 'h', action = act.AdjustPaneSize({ 'Left', 3 }) },
    { key = 'RightArrow', action = act.AdjustPaneSize({ 'Right', 3 }) },
    { key = 'l', action = act.AdjustPaneSize({ 'Right', 3 }) },
    { key = 'UpArrow', action = act.AdjustPaneSize({ 'Up', 3 }) },
    { key = 'k', action = act.AdjustPaneSize({ 'Up', 3 }) },
    { key = 'DownArrow', action = act.AdjustPaneSize({ 'Down', 3 }) },
    { key = 'j', action = act.AdjustPaneSize({ 'Down', 3 }) },
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'Enter', action = 'PopKeyTable' },
    { key = 'q', action = 'PopKeyTable' },
    { key = 'c', mods = 'CTRL', action = 'PopKeyTable' },
  }
end

return M
