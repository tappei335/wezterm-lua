[CmdletBinding()]
param(
    [string]$TargetDir = (Join-Path $HOME ".config/wezterm")
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $TargetDir "lua") -Force | Out-Null

Copy-Item -Path (Join-Path $RepoRoot ".wezterm.lua") -Destination (Join-Path $TargetDir ".wezterm.lua") -Force
Copy-Item -Path (Join-Path $RepoRoot "lua\\*") -Destination (Join-Path $TargetDir "lua") -Recurse -Force

Write-Host "Installed WezTerm config to $TargetDir"
