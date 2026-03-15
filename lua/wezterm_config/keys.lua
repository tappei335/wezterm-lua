local M = {}

local function get_active_pane_info(panes)
  for _, info in ipairs(panes) do
    if info.is_active then
      return info
    end
  end
end

local function get_tab_extent(panes)
  local total_cols = 0
  local total_rows = 0

  for _, info in ipairs(panes) do
    total_cols = math.max(total_cols, info.left + info.width)
    total_rows = math.max(total_rows, info.top + info.height)
  end

  return total_cols, total_rows
end

local function collect_full_height_columns(panes, total_cols, total_rows)
  local groups = {}

  for _, info in ipairs(panes) do
    local key = string.format('%d:%d', info.left, info.width)
    local group = groups[key]

    if not group then
      group = {
        left = info.left,
        width = info.width,
        height = 0,
        pane = info.pane,
      }
      groups[key] = group
    end

    group.height = group.height + info.height
  end

  local columns = {}
  for _, group in pairs(groups) do
    if group.height == total_rows then
      table.insert(columns, group)
    end
  end

  table.sort(columns, function(a, b)
    return a.left < b.left
  end)

  local expected_left = 0
  for _, column in ipairs(columns) do
    if column.left ~= expected_left then
      return {}
    end
    expected_left = expected_left + column.width
  end

  if expected_left ~= total_cols then
    return {}
  end

  return columns
end

local function collect_row_columns(panes, active)
  if not active then
    return {}
  end

  local columns = {}
  for _, info in ipairs(panes) do
    if info.top == active.top and info.height == active.height then
      table.insert(columns, {
        left = info.left,
        width = info.width,
        pane = info.pane,
      })
    end
  end

  table.sort(columns, function(a, b)
    return a.left < b.left
  end)

  return columns
end

local function collect_full_width_rows(panes, total_cols, total_rows)
  local groups = {}

  for _, info in ipairs(panes) do
    local key = string.format('%d:%d', info.top, info.height)
    local group = groups[key]

    if not group then
      group = {
        top = info.top,
        height = info.height,
        width = 0,
        pane = info.pane,
      }
      groups[key] = group
    end

    group.width = group.width + info.width
  end

  local rows = {}
  for _, group in pairs(groups) do
    if group.width == total_cols then
      table.insert(rows, group)
    end
  end

  table.sort(rows, function(a, b)
    return a.top < b.top
  end)

  local expected_top = 0
  for _, row in ipairs(rows) do
    if row.top ~= expected_top then
      return {}
    end
    expected_top = expected_top + row.height
  end

  if expected_top ~= total_rows then
    return {}
  end

  return rows
end

local function collect_column_rows(panes, active)
  if not active then
    return {}
  end

  local rows = {}
  for _, info in ipairs(panes) do
    if info.left == active.left and info.width == active.width then
      table.insert(rows, {
        top = info.top,
        height = info.height,
        pane = info.pane,
      })
    end
  end

  table.sort(rows, function(a, b)
    return a.top < b.top
  end)

  return rows
end

local function build_target_lengths(total_length, count)
  local lengths = {}
  local base = math.floor(total_length / count)
  local remainder = total_length % count

  for i = 1, count do
    lengths[i] = base
    if i <= remainder then
      lengths[i] = lengths[i] + 1
    end
  end

  return lengths
end

local function equalize_columns(window, act, columns)
  if #columns < 2 then
    return false
  end

  local total_width = 0
  local current_widths = {}
  for i, column in ipairs(columns) do
    total_width = total_width + column.width
    current_widths[i] = column.width
  end

  local target_widths = build_target_lengths(total_width, #columns)
  local current_prefix = 0
  local target_prefix = 0

  for i = 1, #columns - 1 do
    current_prefix = current_prefix + current_widths[i]
    target_prefix = target_prefix + target_widths[i]

    local delta = target_prefix - current_prefix
    if delta > 0 then
      window:perform_action(act.AdjustPaneSize({ 'Right', delta }), columns[i].pane)
      current_widths[i] = current_widths[i] + delta
      current_widths[i + 1] = current_widths[i + 1] - delta
      current_prefix = target_prefix
    elseif delta < 0 then
      window:perform_action(act.AdjustPaneSize({ 'Left', -delta }), columns[i].pane)
      current_widths[i] = current_widths[i] + delta
      current_widths[i + 1] = current_widths[i + 1] - delta
      current_prefix = target_prefix
    end
  end

  return true
end

local function equalize_rows(window, act, rows)
  if #rows < 2 then
    return false
  end

  local total_height = 0
  local current_heights = {}
  for i, row in ipairs(rows) do
    total_height = total_height + row.height
    current_heights[i] = row.height
  end

  local target_heights = build_target_lengths(total_height, #rows)
  local current_prefix = 0
  local target_prefix = 0

  for i = 1, #rows - 1 do
    current_prefix = current_prefix + current_heights[i]
    target_prefix = target_prefix + target_heights[i]

    local delta = target_prefix - current_prefix
    if delta > 0 then
      window:perform_action(act.AdjustPaneSize({ 'Down', delta }), rows[i].pane)
      current_heights[i] = current_heights[i] + delta
      current_heights[i + 1] = current_heights[i + 1] - delta
      current_prefix = target_prefix
    elseif delta < 0 then
      window:perform_action(act.AdjustPaneSize({ 'Up', -delta }), rows[i].pane)
      current_heights[i] = current_heights[i] + delta
      current_heights[i + 1] = current_heights[i + 1] - delta
      current_prefix = target_prefix
    end
  end

  return true
end

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
    { key = 'q', mods = 'LEADER', action = act.CloseCurrentPane({ confirm = false }) },
    { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane({ confirm = false }) },
    { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
    { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection('Left') },
    { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection('Down') },
    { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection('Up') },
    { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection('Right') },
    {
      key = '=',
      mods = 'LEADER',
      action = wezterm.action_callback(function(window, pane)
        local tab = pane:tab()
        if not tab then
          return
        end

        local panes = tab:panes_with_info()
        local active = get_active_pane_info(panes)
        if not active or active.is_zoomed then
          return
        end

        local total_cols, total_rows = get_tab_extent(panes)
        local columns = collect_full_height_columns(panes, total_cols, total_rows)

        if #columns < 2 then
          columns = collect_row_columns(panes, active)
        end

        if not equalize_columns(window, act, columns) then
          window:toast_notification('wezterm', 'No horizontal pane group to equalize', nil, 2000)
        end
      end),
    },
    {
      key = '=',
      mods = 'LEADER|SHIFT',
      action = wezterm.action_callback(function(window, pane)
        local tab = pane:tab()
        if not tab then
          return
        end

        local panes = tab:panes_with_info()
        local active = get_active_pane_info(panes)
        if not active or active.is_zoomed then
          return
        end

        local total_cols, total_rows = get_tab_extent(panes)
        local rows = collect_full_width_rows(panes, total_cols, total_rows)

        if #rows < 2 then
          rows = collect_column_rows(panes, active)
        end

        if not equalize_rows(window, act, rows) then
          window:toast_notification('wezterm', 'No vertical pane group to equalize', nil, 2000)
        end
      end),
    },
    { key = 'H', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Left', 5 }) },
    { key = 'J', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Down', 5 }) },
    { key = 'K', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Up', 5 }) },
    { key = 'L', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Right', 5 }) },
    { key = 'p', mods = 'LEADER', action = act.ActivateCommandPalette },
    { key = 'Space', mods = 'CTRL|SHIFT', action = act.QuickSelect },
  }
end

return M
