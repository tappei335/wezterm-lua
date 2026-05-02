param(
  [ValidateSet('Dynamic', 'Static')]
  [string]$Mode = 'Dynamic',
  [string]$Drive = 'C:'
)

if ($Mode -eq 'Static') {
  $memoryTotal = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory
  $cpuCores = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
  '{0}|{1}' -f $memoryTotal, $cpuCores
  exit
}

$cpuMeasure = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
$cpu = if ($cpuMeasure.Average -ne $null) {
  [int][math]::Round([double]$cpuMeasure.Average)
} else {
  ''
}

$os = Get-CimInstance Win32_OperatingSystem
$mem = if ($os.TotalVisibleMemorySize -gt 0) {
  [int][math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100)
} else {
  ''
}

$driveInfo = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $Drive)
$disk = if ($driveInfo -and $driveInfo.Size -gt 0) {
  [int][math]::Round((($driveInfo.Size - $driveInfo.FreeSpace) / $driveInfo.Size) * 100)
} else {
  ''
}

'{0}|{1}|{2}' -f $cpu, $mem, $disk
