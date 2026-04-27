local M = {}

local function clamp(value)
  if value < 0 then
    return 0
  end

  if value > 255 then
    return 255
  end

  return math.floor(value + 0.5)
end

local function hex_to_rgb(hex)
  local normalized = hex:gsub('^#', '')
  return tonumber(normalized:sub(1, 2), 16), tonumber(normalized:sub(3, 4), 16), tonumber(normalized:sub(5, 6), 16)
end

local function rgb_to_hex(r, g, b)
  return string.format('#%02x%02x%02x', clamp(r), clamp(g), clamp(b))
end

local function mix(left, right, ratio)
  local lr, lg, lb = hex_to_rgb(left)
  local rr, rg, rb = hex_to_rgb(right)
  return rgb_to_hex(
    lr + (rr - lr) * ratio,
    lg + (rg - lg) * ratio,
    lb + (rb - lb) * ratio
  )
end

local function lighten(hex, amount)
  return mix(hex, '#ffffff', amount)
end

local function darken(hex, amount)
  return mix(hex, '#000000', amount)
end

M.colors = {
  bg = '#262624',
  bg_dark = '#1f1f1d',
  bg_highlight = '#30302c',
  bg_visual = '#3a3934',
  selection = '#3a4a55',
  fg = '#dcd7ba',
  fg_dim = '#c8c093',
  muted = '#727169',
  blue = '#7e9cd8',
  cyan = '#7aa89f',
  green = '#98bb6c',
  orange = '#ffa066',
  red = '#e46876',
  yellow = '#e6c384',
}

local colors = M.colors

M.ui = {
  chrome_bg = darken(colors.bg_dark, 0.18),
  tab_bar_bg = darken(colors.bg_dark, 0.22),
  tab_edge = lighten(colors.bg_dark, 0.16),
  tab_inactive = mix(colors.bg_highlight, colors.bg_dark, 0.35),
  tab_hover = mix(colors.bg_visual, colors.blue, 0.16),
  tab_active = mix(colors.bg_visual, colors.blue, 0.22),
  status_bg = darken(colors.bg_dark, 0.28),
  status_surface = mix(colors.bg_highlight, colors.bg_dark, 0.18),
  status_surface_alt = mix(colors.bg_visual, colors.bg_dark, 0.25),
  status_separator = lighten(colors.bg_dark, 0.24),
  status_text = colors.fg,
  status_muted = mix(colors.muted, colors.fg_dim, 0.28),
  window_frame = darken(colors.bg_dark, 0.18),
}

M.mix = mix
M.lighten = lighten
M.darken = darken

return M
