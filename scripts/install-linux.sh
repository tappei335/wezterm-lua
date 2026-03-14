#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="${1:-${XDG_CONFIG_HOME:-${HOME}/.config}/wezterm}"

mkdir -p "${TARGET_DIR}"
mkdir -p "${TARGET_DIR}/lua"

cp "${REPO_ROOT}/.wezterm.lua" "${TARGET_DIR}/.wezterm.lua"
cp -R "${REPO_ROOT}/lua/." "${TARGET_DIR}/lua/"

printf 'Installed WezTerm config to %s\n' "${TARGET_DIR}"
