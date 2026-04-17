local util = require('wezterm_config.util')

local M = {}

local function default_ssh_domains(wezterm)
  local ok, domains = pcall(function()
    return wezterm.default_ssh_domains()
  end)

  if not ok or not domains then
    return {}
  end

  for _, domain in ipairs(domains) do
    if type(domain.name) == 'string' and domain.name:match('^SSH:') then
      domain.assume_shell = domain.assume_shell or 'Posix'
    end
  end

  return domains
end

local function plain_ssh_host_name(domain_name)
  if type(domain_name) ~= 'string' then
    return nil
  end

  return domain_name:match('^SSH:(.+)$')
end

local function plain_ssh_choices(domains)
  local choices = {}

  for _, domain in ipairs(domains or {}) do
    local host = plain_ssh_host_name(domain.name)
    if host then
      table.insert(choices, {
        id = domain.name,
        label = host,
      })
    end
  end

  table.sort(choices, function(a, b)
    return a.label < b.label
  end)

  return choices
end

local function append_ssh_launch_menu(config, domains)
  config.launch_menu = config.launch_menu or {}

  for _, choice in ipairs(plain_ssh_choices(domains)) do
    table.insert(config.launch_menu, {
      label = 'SSH: ' .. choice.label,
      domain = { DomainName = choice.id },
    })
  end
end

local function ssh_host_selector(wezterm, act, domains)
  return wezterm.action_callback(function(window, pane)
    local choices = plain_ssh_choices(domains)

    if #choices == 0 then
      window:toast_notification(
        'SSH hosts',
        'No literal Host entries were found in your ssh config',
        nil,
        3000
      )
      return
    end

    window:perform_action(
      act.InputSelector({
        title = 'SSH hosts',
        description = 'Select a host and press Enter = open SSH tab, Esc = cancel, / = filter',
        fuzzy = true,
        choices = choices,
        action = wezterm.action_callback(function(selected_window, selected_pane, id)
          if not id then
            return
          end

          selected_window:perform_action(act.SpawnTab({ DomainName = id }), selected_pane)
        end),
      }),
      pane
    )
  end)
end

function M.apply(config, wezterm)
  local act = wezterm.action
  local domains = default_ssh_domains(wezterm)

  config.ssh_domains = domains
  append_ssh_launch_menu(config, domains)

  util.append_keys(config, {
    {
      key = 'S',
      mods = 'LEADER|SHIFT',
      action = ssh_host_selector(wezterm, act, domains),
    },
  })
end

return M
