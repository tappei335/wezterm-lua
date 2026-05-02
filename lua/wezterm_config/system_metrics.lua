local wezterm = require('wezterm')
local platform = require('wezterm_config.platform')

local M = {}

local SYSTEM_REFRESH_SECONDS = {
  windows = 20,
  macos = 15,
  linux = 5,
  unknown = 15,
}

local DISK_REFRESH_SECONDS = 30

local state = {
  platform_name = nil,
  system = {
    cpu = nil,
    memory = nil,
    updated_at = 0,
  },
  disk = {
    key = nil,
    value = nil,
    updated_at = 0,
  },
  linux_cpu_sample = nil,
}

local function now()
  return os.time()
end

local function clamp_percent(value)
  if not value then
    return nil
  end

  if value < 0 then
    return 0
  end

  if value > 100 then
    return 100
  end

  return value
end

local function round(value)
  if not value then
    return nil
  end

  return math.floor(value + 0.5)
end

local function trim(value)
  if not value then
    return nil
  end

  local trimmed = value:gsub('%s+$', '')
  if trimmed == '' then
    return nil
  end

  return trimmed
end

local function read_file(path)
  local handle = io.open(path, 'r')
  if not handle then
    return nil
  end

  local ok, content = pcall(function()
    return handle:read('*a')
  end)
  handle:close()

  if not ok then
    return nil
  end

  return content
end

local function run_command(command)
  local handle = io.popen(command, 'r')
  if not handle then
    return nil
  end

  local ok, output = pcall(function()
    return handle:read('*a')
  end)
  handle:close()

  if not ok then
    return nil
  end

  return trim(output)
end

local function quote_posix(value)
  return "'" .. tostring(value):gsub("'", [['"'"']]) .. "'"
end

local function quote_cmd(value)
  return '"' .. tostring(value):gsub('"', '""') .. '"'
end

local function platform_name(wezterm)
  if not state.platform_name then
    state.platform_name = platform.detect(wezterm)
  end

  return state.platform_name
end

local function disk_key_for(platform_id, cwd_path)
  if platform_id == 'windows' then
    local drive = cwd_path and cwd_path:match('^/?([A-Za-z]:)')
    return drive or os.getenv('SystemDrive') or 'C:'
  end

  if cwd_path and cwd_path ~= '' then
    return cwd_path
  end

  return '/'
end

local function collect_windows_metrics(drive)
  local script_path = wezterm.config_dir .. '/lua/wezterm_config/system_metrics_windows.ps1'
  local drive_name = drive or 'C:'
  local shells = { 'pwsh.exe', 'powershell.exe' }

  local output
  for _, shell in ipairs(shells) do
    local command = table.concat({
      shell,
      '-NoLogo',
      '-NoProfile',
      '-NonInteractive',
      '-File',
      quote_cmd(script_path),
      '-Drive',
      quote_cmd(drive_name),
      '2>nul',
    }, ' ')
    output = run_command(command)
    if output then
      break
    end
  end

  if not output then
    return nil, nil, nil
  end

  local cpu_text, memory_text, disk_text = output:match('^(%d*)|(%d*)|(%d*)$')
  local cpu = tonumber(cpu_text)
  local memory = tonumber(memory_text)
  local disk = tonumber(disk_text)

  return round(clamp_percent(cpu)), round(clamp_percent(memory)), round(clamp_percent(disk))
end

local function collect_macos_metrics(path)
  local script = ([[
cpu=$(top -l 2 -n 0 | awk '/CPU usage/ { idle=$(NF-1) } END { gsub("%%","",idle); printf "%%d", 100 - idle }')
total=$(sysctl -n hw.memsize)
page_size=$(vm_stat | awk '/page size of/ { gsub("\\.","",$8); print $8 }')
free_pages=$(vm_stat | awk '/Pages free/ { gsub("\\.","",$3); print $3 }')
spec_pages=$(vm_stat | awk '/Pages speculative/ { gsub("\\.","",$3); print $3 }')
mem=$(awk -v total="$total" -v free="$free_pages" -v spec="$spec_pages" -v page="$page_size" 'BEGIN { avail = (free + spec) * page; if (total > 0) printf "%%d", ((total - avail) / total) * 100; }')
disk=$(df -P %s | awk 'NR==2 { gsub("%%","",$5); print $5 }')
printf "%%s|%%s|%%s" "$cpu" "$mem" "$disk"
]]):format(quote_posix(path or '/'))
  local command = '/bin/sh -lc ' .. quote_posix(script) .. ' 2>/dev/null'
  local output = run_command(command)
  if not output then
    return nil, nil, nil
  end

  local cpu_text, memory_text, disk_text = output:match('^(%d+)|(%d+)|(%d+)$')
  return tonumber(cpu_text), tonumber(memory_text), tonumber(disk_text)
end

local function parse_linux_cpu()
  local content = read_file('/proc/stat')
  if not content then
    return nil
  end

  local first_line = content:match('([^\r\n]+)')
  if not first_line or not first_line:match('^cpu%s') then
    return nil
  end

  local fields = {}
  local total = 0
  for value in first_line:gmatch('(%d+)') do
    local number = tonumber(value)
    table.insert(fields, number)
    total = total + number
  end

  local idle = (fields[4] or 0) + (fields[5] or 0)
  local previous = state.linux_cpu_sample
  state.linux_cpu_sample = {
    total = total,
    idle = idle,
  }

  if not previous then
    return nil
  end

  local delta_total = total - previous.total
  local delta_idle = idle - previous.idle
  if delta_total <= 0 then
    return nil
  end

  local usage = (1 - (delta_idle / delta_total)) * 100
  return round(clamp_percent(usage))
end

local function parse_linux_memory()
  local content = read_file('/proc/meminfo')
  if not content then
    return nil
  end

  local total = tonumber(content:match('MemTotal:%s+(%d+)'))
  local available = tonumber(content:match('MemAvailable:%s+(%d+)'))

  if not total or total <= 0 then
    return nil
  end

  if not available then
    local free = tonumber(content:match('MemFree:%s+(%d+)')) or 0
    local buffers = tonumber(content:match('Buffers:%s+(%d+)')) or 0
    local cached = tonumber(content:match('Cached:%s+(%d+)')) or 0
    available = free + buffers + cached
  end

  local usage = ((total - available) / total) * 100
  return round(clamp_percent(usage))
end

local function parse_linux_disk(path)
  local command = 'df -P ' .. quote_posix(path or '/') .. " 2>/dev/null"
  local output = run_command(command)
  if not output then
    return nil
  end

  local last_line
  for line in output:gmatch('[^\r\n]+') do
    last_line = line
  end

  if not last_line then
    return nil
  end

  local usage = tonumber(last_line:match('(%d+)%%%s*$'))
  return round(clamp_percent(usage))
end

local function refresh_command_metrics(platform_id, disk_key, timestamp)
  local previous_disk_key = state.disk.key
  local cpu
  local memory
  local disk

  if platform_id == 'windows' then
    cpu, memory, disk = collect_windows_metrics(disk_key)
  elseif platform_id == 'macos' then
    cpu, memory, disk = collect_macos_metrics(disk_key)
  end

  if cpu ~= nil then
    state.system.cpu = cpu
  end

  if memory ~= nil then
    state.system.memory = memory
  end

  state.system.updated_at = timestamp

  state.disk.key = disk_key
  state.disk.updated_at = timestamp

  if disk ~= nil then
    state.disk.value = disk
  elseif previous_disk_key ~= disk_key then
    state.disk.value = nil
  end
end

local function refresh_linux_metrics(disk_key, timestamp)
  local previous_disk_key = state.disk.key
  local cpu = parse_linux_cpu()
  local memory = parse_linux_memory()
  local disk = parse_linux_disk(disk_key)

  if cpu ~= nil then
    state.system.cpu = cpu
  end

  if memory ~= nil then
    state.system.memory = memory
  end

  state.system.updated_at = timestamp

  state.disk.key = disk_key
  state.disk.updated_at = timestamp

  if disk ~= nil then
    state.disk.value = disk
  elseif previous_disk_key ~= disk_key then
    state.disk.value = nil
  end
end

function M.snapshot(wezterm, cwd_path)
  local current_platform = platform_name(wezterm)
  local timestamp = now()
  local disk_key = disk_key_for(current_platform, cwd_path)
  local system_refresh = SYSTEM_REFRESH_SECONDS[current_platform] or SYSTEM_REFRESH_SECONDS.unknown
  local needs_system_refresh = (timestamp - state.system.updated_at) >= system_refresh
  local needs_disk_refresh = state.disk.key ~= disk_key or (timestamp - state.disk.updated_at) >= DISK_REFRESH_SECONDS

  if current_platform == 'linux' then
    if needs_system_refresh or needs_disk_refresh then
      refresh_linux_metrics(disk_key, timestamp)
    end
  elseif needs_system_refresh or needs_disk_refresh then
    refresh_command_metrics(current_platform, disk_key, timestamp)
  end

  local disk = state.disk.key == disk_key and state.disk.value or nil

  return {
    cpu = state.system.cpu,
    memory = state.system.memory,
    disk = disk,
  }
end

return M
