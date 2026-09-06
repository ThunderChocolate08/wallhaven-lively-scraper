# Wallhaven Toplist -> D:\Carlos\Pictures\Wallhaven\Toplist -> Lively
# Scrappea https://wallhaven.cc/toplist (via API) y asigna uno por default
param(
  [string]$TopRange = "1M",      # 1d,3d,1w,1M,3M,6M,1y
  [int]$Page = 0,                # 0=aleatorio entre 1,3,4 (etc.), o 1..85 fijo
  [string]$Category = "111",
  [string]$Purity = "100",
  [int]$HistoryKeep = 500
)

$ErrorActionPreference = "Stop"
$dst = "D:\Carlos\Pictures\Wallhaven\Toplist"
$log = "D:\Carlos\Pictures\Wallhaven\wallhaven.log"
if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst -Force | Out-Null }
function Log($m){ $t=Get-Date -Format "yyyy-MM-dd HH:mm:ss"; "$t $m" | Out-File $log -Append; Write-Output $m }

try {
  if ($Page -eq 0) { $Page = Get-Random -Minimum 1 -Maximum 11 } # random entre 1-10 (3,4,1 etc.)
  $api = "https://wallhaven.cc/api/v1/search?categories=$Category&purity=$Purity&sorting=toplist&topRange=$TopRange&order=desc&page=$Page"
  Log "Toplist API: $api"
  $r = Invoke-RestMethod -Uri $api -TimeoutSec 20
  if (-not $r.data) { throw "Toplist sin resultados" }
  Log "Toplist p$Page : $($r.data.Count) imgs"

  $downloaded = 0
  foreach ($img in $r.data) {
    $ext = [IO.Path]::GetExtension($img.path)
    $out = Join-Path $dst "toplist-p$Page-$($img.id)$ext"
    if (-not (Test-Path $out)) {
      try {
        Invoke-WebRequest -Uri $img.path -OutFile $out -TimeoutSec 30 -UseBasicParsing
        $downloaded++
      } catch { Log "FAIL $($img.id) $_" }
    }
  }
  Log "Descargados nuevos: $downloaded"

  # Limpiar historial si excede
  $all = Get-ChildItem $dst -File -Filter "toplist-p*.jpg" -ErrorAction SilentlyContinue
  $all += Get-ChildItem $dst -File -Filter "toplist-p*.png" -ErrorAction SilentlyContinue
  $all = $all | Sort-Object LastWriteTime -Descending
  if ($all.Count -gt $HistoryKeep) {
    $all | Select-Object -Skip $HistoryKeep | Remove-Item -Force -ErrorAction SilentlyContinue
    Log "Historial Toplist limpiado"
  }

  # Modo solo descarga (Windows Presentación se encarga del slideshow)
  # No se asigna wallpaper aquí para no interferir con Presentación de Windows (Toplist cada 10 min aleatorio)
  Log "Modo solo descarga: no se asigna wallpaper (Windows Presentación activo)"
  $allFiles = Get-ChildItem $dst -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match "jpg|png" }
  Log "Toplist total: $($allFiles.Count) archivos en $dst"
  Write-Output "OK Toplist p$Page ($downloaded nuevos) - solo descarga, Windows Presentación activo"
} catch {
  Log "ERROR Toplist: $_"
  exit 1
}
