# Wallhaven Random -> Lively Wallpaper (replicable)
# Uso: powershell -ExecutionPolicy Bypass -File "%USERPROFILE%\Pictures\Wallhaven\wallhaven-random.ps1"
#      con parametros: -Category 111 -Purity 100 -Ratios 16x9 -Query "spiderman"
# Si no pasas -Query, lee uno aleatorio de topics.txt - replicable para cualquier usuario
param(
  [string]$Category = "111",   # 100=General 010=Anime 001=People -> 111=todos
  [string]$Purity = "100",      # 100=SFW 010=Sketchy 001=NSFW
  [string]$Ratios = "16x9",     # vacio para todos, o 16x9,16x10,21x9 etc
  [string]$Query = "",          # ej "spiderman", "nature", "programming", "design system"
  [int]$HistoryKeep = 20,       # cuantos wallpapers guardar en historial
  [string]$WallhavenDir = (Join-Path ([Environment]::GetFolderPath("MyPictures")) "Wallhaven")
)

$ErrorActionPreference = "Stop"
$wallhavenDir = $WallhavenDir
$logFile = Join-Path $wallhavenDir "wallhaven.log"
if (-not (Test-Path $wallhavenDir)) { New-Item -ItemType Directory -Path $wallhavenDir -Force | Out-Null }

function Log($m){ $t=Get-Date -Format "yyyy-MM-dd HH:mm:ss"; "$t $m" | Out-File $logFile -Append; Write-Output $m }

try {
  # Si no se paso Query, elige uno aleatorio de topics.txt
  if (-not $Query) {
    $topicsFile = Join-Path $wallhavenDir "topics.txt"
    if (Test-Path $topicsFile) {
      $topics = Get-Content $topicsFile | Where-Object { $_.Trim() -ne "" -and -not $_.StartsWith("#") }
      if ($topics) { $Query = ($topics | Get-Random).Trim() }
    }
  }
  $seed = -join ((48..57)+(65..90)+(97..122) | Get-Random -Count 6 | ForEach-Object {[char]$_})
  $api = "https://wallhaven.cc/api/v1/search?categories=$Category&purity=$Purity&sorting=random&order=desc&seed=$seed"
  if ($Ratios) { $api += "&ratios=$Ratios" }
  # Top 24, 1920x1080+ preferencia
  $api += "&atleast=1920x1080"
  if ($Query) {
    $qEnc = [Uri]::EscapeDataString($Query)
    $api += "&q=$qEnc"
    Log "Tema elegido: $Query"
  }

  Log "API: $api"
  $resp = Invoke-RestMethod -Uri $api -TimeoutSec 20
  if (-not $resp.data -or $resp.data.Count -eq 0) { throw "Wallhaven sin resultados (revisa filtros)" }

  $pick = $resp.data | Get-Random
  $id = $pick.id
  $url = $pick.path  # ej https://w.wallhaven.cc/full/vq/wallhaven-vqg5kp.jpg
  $ext = [IO.Path]::GetExtension($url)
  if (-not $ext) { $ext = ".jpg" }
  $fileName = "wallhaven-$id$ext"
  $dest = Join-Path $wallhavenDir $fileName
  $current = Join-Path $wallhavenDir "current$ext"
  $currentJpg = Join-Path $wallhavenDir "current.jpg"

  if (Test-Path $dest) {
    Log "Ya existe $fileName, usando cache"
  } else {
    Log "Descargando $id -> $dest"
    Invoke-WebRequest -Uri $url -OutFile $dest -TimeoutSec 30 -UseBasicParsing
  }

  # actualizar current para Lively (copia)
  Copy-Item -LiteralPath $dest -Destination $current -Force
  # asegurar extension .jpg para Lively si es png -> convertir copia a .jpg link no necesario, Lively acepta ambos; mantenemos current con extension original y tambien current.jpg
  if ($current -ne $currentJpg) {
    try { Copy-Item -LiteralPath $dest -Destination $currentJpg -Force } catch {}
  }

  # Limpiar historial
  $all = Get-ChildItem $wallhavenDir -File -Filter "wallhaven-*.jpg" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  if ($all.Count -gt $HistoryKeep) { $all | Select-Object -Skip $HistoryKeep | Remove-Item -Force -ErrorAction SilentlyContinue; Log "Historial limpiado" }

  # Set con Lively (ruta genérica para cualquier usuario)
  $lively = Join-Path $env:LOCALAPPDATA "Programs\Lively Wallpaper\Lively.exe"
  if (Test-Path $lively) {
    $target = if (Test-Path $currentJpg) { $currentJpg } else { $current }
    Log "Set Lively: $target"
    & $lively setwp --file $target 2>&1 | Out-File $logFile -Append
    Log "Wallpaper aplicado: $id ($($pick.resolution) $($pick.category)) query='$Query'"
  } else {
    # Fallback Windows wallpaper
    Add-Type @"
using System.Runtime.InteropServices;
public class Wallpaper { [DllImport("user32.dll",CharSet=CharSet.Auto)] public static extern int SystemParametersInfo(int a,int b,string c,int d); }
"@
    [Wallpaper]::SystemParametersInfo(20,0,$current,3) | Out-Null
    Log "Wallpaper aplicado via Windows (sin Lively): $id"
  }

  Write-Output "OK $id"

} catch {
  Log "ERROR: $_"
  Write-Output "ERROR $_"
  exit 1
}
