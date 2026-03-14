$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$targetHome = $HOME

Write-Host "Installing WezTerm config into $targetHome"

Copy-Item -Path (Join-Path $repoRoot '.wezterm.lua') -Destination (Join-Path $targetHome '.wezterm.lua') -Force

$targetLuaDir = Join-Path $targetHome 'lua'
if (Test-Path $targetLuaDir) {
  Remove-Item -Path $targetLuaDir -Recurse -Force
}

Copy-Item -Path (Join-Path $repoRoot 'lua') -Destination $targetLuaDir -Recurse -Force

Write-Host 'Done'
