local theme = require('wezterm_config.theme')

local M = {}

local function basename(path)
  if not path or path == '' then
    return nil
  end

  local normalized = path:gsub('\\', '/'):gsub('/+$', '')
  if normalized == '' then
    return '/'
  end

  return normalized:match('([^/]+)$') or normalized
end

local function decode_uri_path(value)
  if not value then
    return nil, nil
  end

  if type(value) == 'userdata' then
    return value.file_path, value.host
  end

  local uri = tostring(value)
  local without_scheme = uri:gsub('^file://', '')
  local slash = without_scheme:find('/')
  local host = ''
  local path = without_scheme

  if slash then
    host = without_scheme:sub(1, slash - 1)
    path = without_scheme:sub(slash)
  end

  path = path:gsub('%%(%x%x)', function(hex)
    return string.char(tonumber(hex, 16))
  end)

  return path, host
end

local function current_directory_name(pane)
  local cwd_uri = pane:get_current_working_dir()
  local cwd = decode_uri_path(cwd_uri)
  return basename(cwd)
end

local function foreground_process_name(pane)
  local ok, process = pcall(function()
    return pane:get_foreground_process_name()
  end)

  if not ok then
    return nil
  end

  return basename(process)
end

local function domain_name(pane)
  local ok, domain = pcall(function()
    return pane:get_domain_name()
  end)

  if not ok or not domain or domain == '' then
    return nil
  end

  return domain
end

local function active_mode(window)
  local key_table = window:active_key_table()
  if key_table then
    return key_table:gsub('_', '-')
  end

  if window:leader_is_active() then
    return 'leader'
  end

  return nil
end

local function append_segment(elements, label, value, colors, accent)
  if not value or value == '' then
    return
  end

  if #elements > 0 then
    table.insert(elements, { Background = { Color = colors.background } })
    table.insert(elements, { Foreground = { Color = colors.separator } })
    table.insert(elements, { Text = ' ' })
  end

  table.insert(elements, { Background = { Color = colors.segment } })
  table.insert(elements, { Foreground = { Color = accent or colors.label } })
  table.insert(elements, { Attribute = { Intensity = 'Bold' } })
  table.insert(elements, { Text = ' ' .. label .. ' ' })
  table.insert(elements, { Foreground = { Color = colors.text } })
  table.insert(elements, { Attribute = { Intensity = 'Normal' } })
  table.insert(elements, { Text = value .. ' ' })
end

local function format_status(wezterm, segments, colors)
  local elements = {}

  for _, segment in ipairs(segments) do
    append_segment(elements, segment.label, segment.value, colors, segment.accent)
  end

  return wezterm.format(elements)
end

local function truncate_right(value, max_width)
  if not value then
    return ''
  end

  if #value <= max_width then
    return value
  end

  if max_width <= 1 then
    return value:sub(1, max_width)
  end

  return value:sub(1, max_width - 1) .. '~'
end

local function tab_title(tab)
  local title = tab.tab_title
  if title and title ~= '' then
    return title
  end

  if tab.active_pane and tab.active_pane.title then
    return tab.active_pane.title
  end

  return 'tab'
end

function M.apply(config, wezterm)
  config.status_update_interval = 500
  config.hide_tab_bar_if_only_one_tab = false

  local palette = theme.colors
  local left_colors = {
    background = palette.bg_dark,
    segment = palette.bg_highlight,
    label = palette.blue,
    text = palette.fg,
    separator = palette.muted,
  }
  local right_colors = {
    background = palette.bg_dark,
    segment = palette.bg_highlight,
    label = palette.green,
    text = palette.fg,
    separator = palette.muted,
  }

  wezterm.on('format-tab-title', function(tab, _, _, _, hover, max_width)
    local is_active = tab.is_active
    local background = palette.bg_highlight
    local foreground = palette.fg_dim

    if hover then
      background = palette.bg_visual
      foreground = palette.fg
    end

    if is_active then
      background = palette.bg_visual
      foreground = palette.fg
    end

    local index = tostring(tab.tab_index + 1)
    local title = truncate_right(tab_title(tab), math.max(1, max_width - #index - 4))
    local index_foreground = is_active and palette.yellow or palette.muted

    return {
      { Background = { Color = palette.bg_dark } },
      { Foreground = { Color = background } },
      { Text = ' ' },
      { Background = { Color = background } },
      { Foreground = { Color = index_foreground } },
      { Attribute = { Intensity = is_active and 'Bold' or 'Normal' } },
      { Text = index .. ':' },
      { Foreground = { Color = foreground } },
      { Text = title .. ' ' },
      { Background = { Color = palette.bg_dark } },
      { Foreground = { Color = palette.bg_dark } },
      { Attribute = { Intensity = 'Normal' } },
      { Text = ' ' },
    }
  end)

  wezterm.on('update-status', function(window, pane)
    local mode = active_mode(window)
    local left_segments = {
      { label = 'WS', value = window:active_workspace(), accent = palette.blue },
      { label = 'MODE', value = mode, accent = palette.orange },
    }

    local cwd = current_directory_name(pane)
    local process = foreground_process_name(pane)
    local domain = domain_name(pane)
    local right_segments = {
      { label = 'DIR', value = cwd, accent = palette.green },
      { label = 'PROC', value = process, accent = palette.cyan },
      { label = 'DOM', value = domain, accent = palette.yellow },
      { label = 'TIME', value = wezterm.strftime('%H:%M'), accent = palette.blue },
    }

    window:set_left_status(' ' .. format_status(wezterm, left_segments, left_colors) .. ' ')
    window:set_right_status(' ' .. format_status(wezterm, right_segments, right_colors) .. ' ')
  end)
end

return M
