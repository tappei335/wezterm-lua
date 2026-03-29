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

  local previous_right = nil
  for _, column in ipairs(columns) do
    if previous_right ~= nil and column.left < previous_right then
      return {}
    end
    previous_right = column.left + column.width
  end

  return columns
end

local function collect_row_columns(panes, total_cols, target_row)
  local columns = {}

  for _, info in ipairs(panes) do
    if pane_covers_row(info, target_row) then
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

  local previous_right = nil
  for _, column in ipairs(columns) do
    if previous_right ~= nil and column.left < previous_right then
      return {}
    end
    previous_right = column.left + column.width
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

local function build_row_column_provider(target_row)
  return function(tab)
    local panes = tab:panes_with_info()
    local total_cols = get_tab_extent(panes)
    return collect_row_columns(panes, total_cols, target_row)
  end
end

local function collect_candidate_rows(panes)
  local row_boundaries = {}
  local row_candidates = {}

  for _, info in ipairs(panes) do
    row_boundaries[info.top] = true
    row_boundaries[info.top + info.height] = true
    row_candidates[info.top + math.floor((info.height - 1) / 2)] = true
  end

  local sorted_boundaries = {}
  for boundary in pairs(row_boundaries) do
    table.insert(sorted_boundaries, boundary)
  end

  table.sort(sorted_boundaries)

  local rows = {}
  for i = 1, #sorted_boundaries - 1 do
    local top = sorted_boundaries[i]
    local bottom = sorted_boundaries[i + 1]
    if bottom > top then
      row_candidates[top + math.floor((bottom - top - 1) / 2)] = true
    end
  end

  for row in pairs(row_candidates) do
    table.insert(rows, row)
  end

  table.sort(rows)

  return rows
end

local function select_primary_column_row(panes, total_cols, active)
  local best_row = nil
  local best_columns = {}

  for _, row in ipairs(collect_candidate_rows(panes)) do
    local columns = collect_row_columns(panes, total_cols, row)
    local should_replace = #columns > #best_columns

    if not should_replace and #columns == #best_columns and active and pane_covers_row(active, row) then
      should_replace = best_row == nil or not pane_covers_row(active, best_row)
    end

    if should_replace then
      best_row = row
      best_columns = columns
    end
  end

  return best_row, best_columns
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

local function build_target_prefixes(widths)
  local prefixes = {}
  local total = 0

  for i = 1, #widths - 1 do
    total = total + widths[i]
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

local function adjust_pane_size(window, act, wezterm, pane, direction, amount)
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

local function append_boundary_candidates(candidates, seen, panes, edge_getter, boundary_start, boundary_end, direction)
  for _, info in ipairs(panes) do
    local edge = edge_getter(info)
    if boundary_start <= edge and edge <= boundary_end then
      local pane_id = info.pane:pane_id()
      local key = string.format('%s:%s', pane_id, direction)
      if not seen[key] then
        table.insert(candidates, {
          pane = info.pane,
          direction = direction,
        })
        seen[key] = true
      end
    end
  end
end

local function build_boundary_candidates(tab, columns, boundary_index, increase_prefix)
  local panes = tab:panes_with_info()
  local leading = columns[boundary_index]
  local trailing = columns[boundary_index + 1]
  local boundary_start = leading.left + leading.width
  local boundary_end = math.max(boundary_start, trailing.left)
  local leading_direction = increase_prefix and 'Right' or 'Left'
  local trailing_direction = opposite_direction(leading_direction)
  local seen = {}
  local candidates = {}

  local function pane_right(info)
    return info.left + info.width
  end

  local function pane_left(info)
    return info.left
  end

  append_boundary_candidates(candidates, seen, panes, pane_right, boundary_start, boundary_end, leading_direction)
  append_boundary_candidates(candidates, seen, panes, pane_left, boundary_start, boundary_end, trailing_direction)
  append_boundary_candidates(candidates, seen, panes, pane_right, boundary_start, boundary_end, opposite_direction(leading_direction))
  append_boundary_candidates(candidates, seen, panes, pane_left, boundary_start, boundary_end, opposite_direction(trailing_direction))

  local fallback_candidates = {
    { pane = leading.pane, direction = leading_direction },
    { pane = trailing.pane, direction = trailing_direction },
    { pane = leading.pane, direction = opposite_direction(leading_direction) },
    { pane = trailing.pane, direction = opposite_direction(trailing_direction) },
  }

  for _, candidate in ipairs(fallback_candidates) do
    local key = string.format('%s:%s', candidate.pane:pane_id(), candidate.direction)
    if not seen[key] then
      table.insert(candidates, candidate)
      seen[key] = true
    end
  end

  return candidates
end

local function try_adjust_boundary_step(window, act, wezterm, tab, column_provider, boundary_index, increase_prefix, amount)
  local columns = column_provider(tab)
  if #columns <= boundary_index then
    return false
  end

  local current_prefix = sum_column_widths(columns, boundary_index)
  local candidates = build_boundary_candidates(tab, columns, boundary_index, increase_prefix)

  for _, candidate in ipairs(candidates) do
    adjust_pane_size(window, act, wezterm, candidate.pane, candidate.direction, amount)
    wezterm.sleep_ms(1)

    local updated_columns = column_provider(tab)
    if #updated_columns ~= #columns then
      return false
    end

    local updated_prefix = sum_column_widths(updated_columns, boundary_index)
    local movement = updated_prefix - current_prefix

    if increase_prefix and movement > 0 then
      return true
    end

    if (not increase_prefix) and movement < 0 then
      return true
    end

    if movement ~= 0 then
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

        local reverted_prefix = sum_column_widths(reverted_columns, boundary_index)
        if reverted_prefix == current_prefix then
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

local function equalize_column_widths(window, act, wezterm, tab, column_provider)
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
  local target_prefixes = build_target_prefixes(target_widths)
  local max_passes = total_width * #columns

  for _ = 1, max_passes do
    local progressed = false

    for i = 1, #target_widths - 1 do
      columns = column_provider(tab)
      if #columns ~= #target_widths then
        restore_starting_pane()
        return false
      end

      local current_prefix = sum_column_widths(columns, i)
      local delta = target_prefixes[i] - current_prefix
      if delta ~= 0 then
        local amount = math.min(math.abs(delta), 8)
        if try_adjust_boundary_step(window, act, wezterm, tab, column_provider, i, delta > 0, amount) then
          progressed = true
        end
      end
    end

    columns = column_provider(tab)
    if #columns ~= #target_widths then
      restore_starting_pane()
      return false
    end

    if prefixes_match(build_prefix_widths(columns, #columns - 1), target_prefixes, #columns - 1) then
      restore_starting_pane()
      return true
    end

    if not progressed then
      restore_starting_pane()
      return false
    end
  end

  restore_starting_pane()
  return false
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

function M.equalize_layout_columns(window, pane, wezterm)
  local tab = pane:tab()
  if not tab then
    return false, 'Active pane is not attached to a tab'
  end

  local panes = tab:panes_with_info()
  local active = get_active_pane_info(panes)
  if not active then
    return false, 'Could not determine the active pane'
  end

  if active.is_zoomed then
    return false, 'Pane is zoomed; unzoom it before equalizing columns'
  end

  local total_cols = get_tab_extent(panes)
  local target_row, columns = select_primary_column_row(panes, total_cols, active)
  if #columns < 2 then
    return false, 'No columns in the current layout to equalize'
  end

  if columns_are_even(columns) then
    return true, 'Layout columns are already even'
  end

  local ok = equalize_column_widths(window, wezterm.action, wezterm, tab, build_row_column_provider(target_row))
  if not ok then
    return false, 'Failed to equalize layout columns'
  end

  return true, 'Equalized layout columns'
end

return M
