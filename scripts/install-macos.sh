#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_HOME="${HOME}"

echo "Installing WezTerm config into ${TARGET_HOME}"

cp "${REPO_ROOT}/.wezterm.lua" "${TARGET_HOME}/.wezterm.lua"
rm -rf "${TARGET_HOME}/lua"
cp -R "${REPO_ROOT}/lua" "${TARGET_HOME}/lua"

echo "Done"
