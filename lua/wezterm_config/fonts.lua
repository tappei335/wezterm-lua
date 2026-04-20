local M = {}

local function font_stack(wezterm, weight, style)
  return wezterm.font_with_fallback({
    {
      family = 'JetBrains Mono',
      weight = weight or 'Medium',
      style = style or 'Normal',
    },
    {
      family = 'BIZ UDGothic',
      weight = 'Regular',
    },
    {
      family = 'Noto Sans JP',
      weight = 'Regular',
    },
    'Symbols Nerd Font Mono',
    'Noto Color Emoji',
  })
end

function M.apply(config, wezterm)
  config.font = font_stack(wezterm)
  config.font_rules = {
    {
      intensity = 'Bold',
      italic = false,
      font = font_stack(wezterm, 'Bold'),
    },
    {
      intensity = 'Bold',
      italic = true,
      font = font_stack(wezterm, 'Bold', 'Italic'),
    },
    {
      intensity = 'Normal',
      italic = true,
      font = font_stack(wezterm, 'Medium', 'Italic'),
    },
    {
      intensity = 'Half',
      italic = false,
      font = font_stack(wezterm, 'Regular'),
    },
    {
      intensity = 'Half',
      italic = true,
      font = font_stack(wezterm, 'Regular', 'Italic'),
    },
  }
  config.font_size = 13.0
  config.line_height = 1.08
  config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }
end

return M
