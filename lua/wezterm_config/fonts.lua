local M = {}

function M.apply(config, wezterm)
  config.font = wezterm.font_with_fallback({
    'JetBrainsMono Nerd Font',
    'Noto Sans Mono CJK JP',
    'Symbols Nerd Font Mono',
  })
  config.font_size = 13.0
  config.line_height = 1.05
  config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }
end

return M

