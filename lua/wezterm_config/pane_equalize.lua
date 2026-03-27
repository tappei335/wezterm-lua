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

local function pane_covers_row(info, row)
  if row == nil then
    return false
  end

  return info.top <= row and row < (info.top + info.height)
end

local function collect_full_height_columns(panes, total_cols, total_rows, target_row)
  local groups = {}

  for _, info in ipairs(panes) do
    local key = string.format('%d:%d', info.left, info.width)
    local group = groups[key]

    if not group then
      group = {
        left = info.left,
        width = info.width,
        height = 0,
        pane = nil,
      }
      groups[key] = group
    end

    if pane_covers_row(info, target_row) then
      group.pane = info.pane
    elseif not group.pane then
      group.pane = info.pane
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

local function build_full_height_column_provider(target_row)
  return function(tab)
    local panes = tab:panes_with_info()
    local total_cols, total_rows = get_tab_extent(panes)
    return collect_full_height_columns(panes, total_cols, total_rows, target_row)
  end
end

local function columns_are_even(columns)
  if #columns < 2 then
    return true
  end

  local min_width = columns[1].width
  local max_width = columns[1].width

  for i = 2, #columns do
    min_width = math.min(min_width, columns[i].width)
    max_width = math.max(max_width, columns[i].width)
  end

  return (max_width - min_width) <= 1
end

local function build_equal_column_split_args(tab, active)
  if not active then
    return nil
  end

  local panes = tab:panes_with_info()
  local total_cols, total_rows = get_tab_extent(panes)
  local target_row = active.top + math.floor(active.height / 2)
  local columns = collect_full_height_columns(panes, total_cols, total_rows, target_row)
  if #columns == 0 or not columns_are_even(columns) then
    return nil
  end

  local active_right = active.left + active.width
  local is_left_edge = active.left == 0
  local is_right_edge = active_right == total_cols
  if not is_left_edge and not is_right_edge then
    return nil
  end

  local direction = 'Right'
  if is_left_edge and not is_right_edge then
    direction = 'Left'
  end

  return {
    direction = direction,
    domain = 'CurrentPaneDomain',
    size = 1 / (#columns + 1),
    top_level = true,
  }
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

local function build_prefix_widths(columns, last_index)
  local prefixes = {}
  local total = 0

  for i = 1, last_index do
    total = total + columns[i].width
    prefixes[i] = total
  end

  return prefixes
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
  local cli_path = get_wezterm_cli_path(wezterm)
  local pane_id = tostring(pane:pane_id())

  local activated, _, activate_stderr = wezterm.run_child_process({
    cli_path,
    'cli',
    'activate-pane',
    '--pane-id',
    pane_id,
  })

  if not activated and activate_stderr and activate_stderr ~= '' then
    wezterm.log_warn(activate_stderr)
  end

  local ok, _, stderr = wezterm.run_child_process({
    cli_path,
    'cli',
    'adjust-pane-size',
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

local function prefixes_match(actual, expected, last_index)
  for i = 1, last_index do
    if actual[i] ~= expected[i] then
      return false
    end
  end

  return true
end

local function try_adjust_boundary_step(window, act, wezterm, tab, column_provider, boundary_index, increase_prefix, locked_prefixes, amount)
  local columns = column_provider(tab)
  if #columns <= boundary_index then
    return false
  end

  local current_prefixes = build_prefix_widths(columns, boundary_index)
  local current_prefix = current_prefixes[boundary_index]
  local leading_pane = columns[boundary_index].pane
  local trailing_pane = columns[boundary_index + 1].pane
  local primary_direction = increase_prefix and 'Right' or 'Left'
  local secondary_direction = opposite_direction(primary_direction)
  local candidates = {
    increase_prefix and { pane = leading_pane, direction = primary_direction } or { pane = trailing_pane, direction = primary_direction },
    increase_prefix and { pane = trailing_pane, direction = primary_direction } or { pane = leading_pane, direction = primary_direction },
    increase_prefix and { pane = leading_pane, direction = secondary_direction } or { pane = trailing_pane, direction = secondary_direction },
    increase_prefix and { pane = trailing_pane, direction = secondary_direction } or { pane = leading_pane, direction = secondary_direction },
  }

  for _, candidate in ipairs(candidates) do
    adjust_pane_size(window, act, wezterm, candidate.pane, candidate.direction, amount)
    wezterm.sleep_ms(1)

    local updated_columns = column_provider(tab)
    if #updated_columns ~= #columns then
      return false
    end

    local updated_prefixes = build_prefix_widths(updated_columns, boundary_index)
    local movement = updated_prefixes[boundary_index] - current_prefix
    local previous_boundaries_unchanged = prefixes_match(updated_prefixes, locked_prefixes, boundary_index - 1)

    if previous_boundaries_unchanged and increase_prefix and movement > 0 then
      return true
    end

    if previous_boundaries_unchanged and (not increase_prefix) and movement < 0 then
      return true
    end

    if movement ~= 0 or not previous_boundaries_unchanged then
      local reverted = false
      local revert_amount = amount
      if movement ~= 0 then
        revert_amount = math.max(1, math.abs(movement))
      end
      for _ = 1, 4 do
        adjust_pane_size(window, act, wezterm, candidate.pane, opposite_direction(candidate.direction), revert_amount)
        wezterm.sleep_ms(1)

        local reverted_columns = column_provider(tab)
        if #reverted_columns ~= #columns then
          return false
        end

        local reverted_prefixes = build_prefix_widths(reverted_columns, boundary_index)
        if prefixes_match(reverted_prefixes, current_prefixes, boundary_index) then
          reverted = true
          break
        end
      end

      if not reverted then
        return false
      end
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
  local locked_prefixes = {}

  for i = 1, #columns - 1 do
    target_prefix = target_prefix + target_widths[i]
    locked_prefixes[i] = target_prefix
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

      local amount = math.min(math.abs(delta), 8)
      if not try_adjust_boundary_step(window, act, wezterm, tab, column_provider, i, delta > 0, locked_prefixes, amount) then
        restore_starting_pane()
        return false
      end
    end

    columns = column_provider(tab)
    if #columns ~= #target_widths or not prefixes_match(build_prefix_widths(columns, i), locked_prefixes, i) then
      restore_starting_pane()
      return false
    end
  end

  restore_starting_pane()
  return true
end

function M.split_horizontally(pane)
  local tab = pane:tab()
  if not tab then
    return pane:split({
      direction = 'Right',
      domain = 'CurrentPaneDomain',
    })
  end

  local panes = tab:panes_with_info()
  local active = get_active_pane_info(panes)
  local split_args = build_equal_column_split_args(tab, active)
  if split_args then
    return pane:split(split_args)
  end

  return pane:split({
    direction = 'Right',
    domain = 'CurrentPaneDomain',
  })
end

function M.equalize_full_height_columns(window, pane, wezterm)
  local tab = pane:tab()
  if not tab then
    return false
  end

  local panes = tab:panes_with_info()
  local active = get_active_pane_info(panes)
  if not active or active.is_zoomed then
    return false
  end

  local total_cols, total_rows = get_tab_extent(panes)
  local target_row = active.top + math.floor(active.height / 2)
  local columns = collect_full_height_columns(panes, total_cols, total_rows, target_row)
  if #columns < 2 then
    return false, 'No full-height pane columns to equalize'
  end

  local ok = equalize_columns(window, wezterm.action, wezterm, tab, build_full_height_column_provider(target_row))
  if not ok then
    return false, 'Failed to equalize full-height pane columns'
  end

  return true
end

return M
