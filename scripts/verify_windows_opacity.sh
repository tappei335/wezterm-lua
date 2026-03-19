#!/usr/bin/env bash
set -euo pipefail

cd /workspace

grep -Fqx "  config.window_background_opacity = 0.75" lua/wezterm_config/platforms/windows.lua
grep -Fqx "    windows = { 'wezterm_config.platforms.windows' }," lua/wezterm_config/platform.lua

matches="$(grep -R -n "window_background_opacity" lua/wezterm_config || true)"

if printf '%s\n' "$matches" | grep -F "windows.lua:" >/dev/null; then
  :
else
  echo "missing windows opacity assignment" >&2
  exit 1
fi

if printf '%s\n' "$matches" | grep -F "windows" | grep -Fv "platforms/windows.lua:" >/dev/null; then
  echo "found unexpected windows-specific opacity override outside windows.lua" >&2
  exit 1
fi
