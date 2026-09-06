# Auto-rotacion Wallhaven cada N minutos (para Tarea Programada)
param([int]$IntervalMinutes = 15)
while ($true) {
  & "powershell" -ExecutionPolicy Bypass -File "D:\Carlos\Pictures\Wallhaven\wallhaven-random.ps1"
  Start-Sleep -Seconds ($IntervalMinutes * 60)
}
