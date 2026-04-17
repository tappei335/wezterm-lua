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

local function append_segment(elements, label, value, colors)
  if not value or value == '' then
    return
  end

  if #elements > 0 then
    table.insert(elements, { Foreground = { Color = colors.separator } })
    table.insert(elements, { Text = ' | ' })
  end

  table.insert(elements, { Foreground = { Color = colors.label } })
  table.insert(elements, { Text = label .. ':' })
  table.insert(elements, { Foreground = { Color = colors.text } })
  table.insert(elements, { Text = value })
end

local function format_status(wezterm, segments, colors)
  local elements = {}

  for _, segment in ipairs(segments) do
    append_segment(elements, segment.label, segment.value, colors)
  end

  return wezterm.format(elements)
end

function M.apply(config, wezterm)
  config.status_update_interval = 500
  config.hide_tab_bar_if_only_one_tab = false

  local left_colors = {
    label = '#7e9cd8',
    text = '#dcd7ba',
    separator = '#54546d',
  }
  local right_colors = {
    label = '#98bb6c',
    text = '#dcd7ba',
    separator = '#54546d',
  }

  wezterm.on('update-status', function(window, pane)
    local mode = active_mode(window)
    local left_segments = {
      { label = 'ws', value = window:active_workspace() },
      { label = 'mode', value = mode },
    }

    local cwd = current_directory_name(pane)
    local process = foreground_process_name(pane)
    local domain = domain_name(pane)
    local right_segments = {
      { label = 'dir', value = cwd },
      { label = 'proc', value = process },
      { label = 'dom', value = domain },
      { label = 'time', value = wezterm.strftime('%H:%M') },
    }

    window:set_left_status(' ' .. format_status(wezterm, left_segments, left_colors) .. ' ')
    window:set_right_status(' ' .. format_status(wezterm, right_segments, right_colors) .. ' ')
  end)
end

return M
