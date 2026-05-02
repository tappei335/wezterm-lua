local theme = require('wezterm_config.theme')
local system_metrics = require('wezterm_config.system_metrics')

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

local function current_directory_path(pane)
  local cwd_uri = pane:get_current_working_dir()
  return decode_uri_path(cwd_uri)
end

local function current_directory_name(pane)
  local cwd = current_directory_path(pane)
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

local function raw_domain_name(pane)
  local ok, domain = pcall(function()
    return pane:get_domain_name()
  end)

  if not ok or not domain or domain == '' then
    return nil
  end

  return domain
end

local function domain_name(pane)
  local domain = raw_domain_name(pane)
  if not domain then
    return nil
  end

  local _, suffix = domain:match('^([^:]+):(.*)$')
  if suffix and suffix ~= '' then
    return suffix
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

local function format_percent(value)
  if value == nil then
    return nil
  end

  return string.format('%d%%', value)
end

local function usage_accent(value, palette, ok_color)
  if value == nil then
    return ok_color
  end

  if value >= 85 then
    return palette.red
  end

  if value >= 65 then
    return palette.orange
  end

  return ok_color
end

local function append_text(elements, background, foreground, text, intensity)
  table.insert(elements, { Background = { Color = background } })
  table.insert(elements, { Foreground = { Color = foreground } })
  table.insert(elements, { Attribute = { Intensity = intensity or 'Normal' } })
  table.insert(elements, { Text = text })
end

local function append_separator(elements, left_background, right_background)
  append_text(elements, left_background, right_background, '>', 'Normal')
end

local function format_segments(wezterm, segments, opts)
  local elements = {}
  local current_background = opts.background
  local use_alt_surface = false

  for _, segment in ipairs(segments) do
    if segment.value and segment.value ~= '' then
      local surface = use_alt_surface and opts.surface_alt or opts.surface
      local accent = segment.accent or opts.accent

      append_text(elements, accent, opts.accent_text, ' ' .. segment.label .. ' ', 'Bold')
      append_text(elements, surface, opts.text, ' ' .. segment.value .. ' ', 'Normal')

      current_background = surface
      use_alt_surface = not use_alt_surface
    end
  end

  if #elements == 0 then
    return ''
  end

  append_separator(elements, current_background, opts.background)
  return wezterm.format(elements)
end

function M.apply(config, wezterm)
  config.status_update_interval = 500

  local palette = theme.colors
  local ui = theme.ui
  local left_status = {
    background = ui.status_bg,
    surface = ui.status_surface,
    surface_alt = ui.status_surface_alt,
    accent = palette.blue,
    accent_text = palette.bg_dark,
    text = ui.status_text,
  }
  local right_status = {
    background = ui.status_bg,
    surface = ui.status_surface,
    surface_alt = ui.status_surface_alt,
    accent = palette.green,
    accent_text = palette.bg_dark,
    text = ui.status_text,
  }

  wezterm.on('format-tab-title', function(tab, _, _, _, hover, max_width)
    local is_active = tab.is_active
    local index = tostring(tab.tab_index + 1)
    local title = truncate_right(tab_title(tab), math.max(1, max_width - #index - 7))
    local label_background = theme.mix(ui.tab_inactive, palette.fg_dim, 0.15)
    local label_foreground = palette.fg_dim
    local body_background = ui.tab_inactive
    local body_foreground = palette.fg_dim
    local intensity = 'Normal'

    if hover then
      label_background = theme.mix(ui.tab_hover, palette.blue, 0.28)
      label_foreground = palette.fg
      body_background = ui.tab_hover
      body_foreground = palette.fg
    end

    if is_active then
      label_background = palette.blue
      label_foreground = palette.bg_dark
      body_background = ui.tab_active
      body_foreground = palette.fg
      intensity = 'Bold'
    end

    return {
      { Background = { Color = ui.tab_bar_bg } },
      { Foreground = { Color = label_background } },
      { Attribute = { Intensity = 'Normal' } },
      { Background = { Color = label_background } },
      { Foreground = { Color = label_foreground } },
      { Attribute = { Intensity = intensity } },
      { Text = ' ' .. index .. ' ' },
      { Background = { Color = label_background } },
      { Foreground = { Color = body_background } },
      { Attribute = { Intensity = 'Normal' } },
      { Background = { Color = body_background } },
      { Foreground = { Color = body_foreground } },
      { Attribute = { Intensity = intensity } },
      { Text = ' ' .. title .. ' ' },
      { Background = { Color = body_background } },
      { Foreground = { Color = ui.tab_bar_bg } },
      { Attribute = { Intensity = 'Normal' } },
      { Background = { Color = ui.tab_bar_bg } },
      { Foreground = { Color = ui.tab_bar_bg } },
      { Text = ' ' },
    }
  end)

  wezterm.on('update-status', function(window, pane)
    local mode = active_mode(window)
    local left_segments = {
      { label = 'WS', value = window:active_workspace(), accent = palette.blue },
      { label = 'MODE', value = mode, accent = palette.orange },
    }

    local cwd_path = current_directory_path(pane)
    local cwd = current_directory_name(pane)
    local process = foreground_process_name(pane)
    local domain = domain_name(pane)
    local raw_domain = raw_domain_name(pane)
    local metrics = system_metrics.snapshot(wezterm, pane, cwd_path, raw_domain)
    local right_segments = {
      { label = 'CPU', value = format_percent(metrics.cpu), accent = usage_accent(metrics.cpu, palette, palette.cyan) },
      { label = 'MEM', value = format_percent(metrics.memory), accent = usage_accent(metrics.memory, palette, palette.blue) },
      { label = 'DSK', value = format_percent(metrics.disk), accent = usage_accent(metrics.disk, palette, palette.green) },
      { label = 'DIR', value = cwd, accent = palette.green },
      { label = 'PROC', value = process, accent = palette.cyan },
      { label = 'DOM', value = domain, accent = palette.yellow },
      { label = 'TIME', value = wezterm.strftime('%H:%M'), accent = palette.blue },
    }

    local left = format_segments(wezterm, left_segments, left_status)
    local right = format_segments(wezterm, right_segments, right_status)

    window:set_left_status(left ~= '' and (' ' .. left) or '')
    window:set_right_status(right ~= '' and (right .. ' ') or '')
  end)
end

return M
