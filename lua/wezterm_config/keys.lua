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

local function build_target_widths(total_width, count)
  local widths = {}
  local base = math.floor(total_width / count)
  local remainder = total_width % count

  for i = 1, count do
    widths[i] = base
    if i <= remainder then
      widths[i] = widths[i] + 1
    end
  end

  return widths
end

local function sum_column_widths(columns, last_index)
  local total = 0
  for i = 1, last_index do
    total = total + columns[i].width
  end
  return total
end

local function opposite_direction(direction)
  if direction == 'Left' then
    return 'Right'
  end
  return 'Left'
end

local function get_wezterm_cli_path(wezterm)
  if wezterm.target_triple:find('windows') then
    return wezterm.executable_dir .. '\\wezterm.exe'
  end
  return wezterm.executable_dir .. '/wezterm'
end

local function adjust_pane_size(window, act, wezterm, pane, direction, amount)
  local ok, _, stderr = wezterm.run_child_process({
    get_wezterm_cli_path(wezterm),
    'cli',
    'adjust-pane-size',
    '--pane-id',
    tostring(pane:pane_id()),
    '--amount',
    tostring(amount),
    direction,
  })

  if ok then
    return true
  end

  if stderr and stderr ~= '' then
    wezterm.log_warn(stderr)
  end

  pane:activate()
  wezterm.sleep_ms(1)
  window:perform_action(act.AdjustPaneSize({ direction, amount }), pane)
  return true
end

local function try_adjust_boundary_step(window, act, wezterm, tab, column_provider, boundary_index, increase_prefix)
  local columns = column_provider(tab)
  if #columns <= boundary_index then
    return false
  end

  local current_prefix = sum_column_widths(columns, boundary_index)
  local direction = increase_prefix and 'Right' or 'Left'
  local candidates = {
    {
      pane = columns[boundary_index].pane,
      direction = direction,
    },
    {
      pane = columns[boundary_index + 1].pane,
      direction = direction,
    },
  }

  for _, candidate in ipairs(candidates) do
    candidate.pane:activate()
    wezterm.sleep_ms(1)
    adjust_pane_size(window, act, wezterm, candidate.pane, candidate.direction, 1)
    wezterm.sleep_ms(1)

    local updated_columns = column_provider(tab)
    if #updated_columns ~= #columns then
      return false
    end

    local movement = sum_column_widths(updated_columns, boundary_index) - current_prefix
    if increase_prefix and movement > 0 then
      return true
    end

    if (not increase_prefix) and movement < 0 then
      return true
    end

    if movement ~= 0 then
      adjust_pane_size(window, act, wezterm, candidate.pane, opposite_direction(candidate.direction), math.abs(movement))
      wezterm.sleep_ms(1)
    end
  end

  return false
end

local function equalize_columns(window, act, wezterm, tab, column_provider)
  local columns = column_provider(tab)
  if #columns < 2 then
    return false
  end

  local starting_pane = tab:active_pane()
  local function restore_starting_pane()
    if starting_pane then
      starting_pane:activate()
    end
  end

  local total_width = sum_column_widths(columns, #columns)
  local target_widths = build_target_widths(total_width, #columns)
  local target_prefix = 0

  for i = 1, #columns - 1 do
    target_prefix = target_prefix + target_widths[i]
    local max_steps = total_width

    for _ = 1, max_steps do
      columns = column_provider(tab)
      if #columns ~= #target_widths then
        restore_starting_pane()
        return false
      end

      local current_prefix = sum_column_widths(columns, i)
      local delta = target_prefix - current_prefix
      if delta == 0 then
        break
      end

      if not try_adjust_boundary_step(window, act, wezterm, tab, column_provider, i, delta > 0) then
        restore_starting_pane()
        return false
      end
    end

    columns = column_provider(tab)
    if #columns ~= #target_widths or sum_column_widths(columns, i) ~= target_prefix then
      restore_starting_pane()
      return false
    end
  end

  restore_starting_pane()
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
        local column_provider

        if #columns >= 2 then
          column_provider = function(current_tab)
            local current_panes = current_tab:panes_with_info()
            local current_total_cols, current_total_rows = get_tab_extent(current_panes)
            return collect_full_height_columns(current_panes, current_total_cols, current_total_rows)
          end
        else
          column_provider = function(current_tab)
            local current_panes = current_tab:panes_with_info()
            local current_active = get_active_pane_info(current_panes)
            return collect_row_columns(current_panes, current_active)
          end
        end

        if not equalize_columns(window, act, wezterm, tab, column_provider) then
          window:toast_notification('wezterm', 'No horizontal pane group to equalize', nil, 2000)
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
