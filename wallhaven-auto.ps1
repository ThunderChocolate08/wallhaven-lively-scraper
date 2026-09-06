# Auto-rotacion Wallhaven cada N minutos (para Tarea Programada) - replicable
param([int]$IntervalMinutes = 15)
while ($true) {
  & "powershell" -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "wallhaven-random.ps1")
  Start-Sleep -Seconds ($IntervalMinutes * 60)
}
