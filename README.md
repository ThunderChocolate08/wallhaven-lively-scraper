# Wallhaven + Lively Wallpaper — Scrapper Windows

Implementación usada en `D:\Carlos\Pictures\Wallhaven` para descargar wallpapers de **wallhaven.cc** y usarlos con **Lively Wallpaper** (Windows 11) y **Windows Presentación**. Creado para el flujo de `ThunderChocolate08`.

## Estructura
```
wallhaven-random.ps1      # API random por query (topics.txt) -> Lively
wallhaven-toplist.ps1     # Scrapping https://wallhaven.cc/toplist (TopRange 1M, random p1,3,4) -> D:\Carlos\Pictures\Wallhaven\Toplist (solo descarga)
wallhaven-auto.ps1        # Loop cada N minutos (para tarea programada)
Wallhaven-Random.bat      # Doble click manual
topics.txt                # 47 temas (superheroes, spiderman, programming, nature, cars, design system, office, trends, Berserk...)
tags-berserk-*.txt        # Captura de 23 tags de Berserk (HTML sidebar) con IDs
```

## Flujo actual (Windows)
- **Windows Presentación** (`Personalizar > Tema > Presentación`): carpeta `Toplist` cada **10 min aleatorio** (`Rellenar`) — es quien muestra el fondo.
- **Scrapper** (`wallhaven-toplist.ps1`): solo **descarga** de `https://wallhaven.cc/api/v1/search?sorting=toplist&topRange=1M&page=<random 1,3,4>` a `Toplist/` (sin `Lively setwp` para no pisar la Presentación). `HistoryKeep=500`.
- **Tarea programada `WallhavenRandom`**: al **iniciar Windows + al iniciar sesión + cada 30 min** + a demanda con `C:\Users\Carlos\Desktop\Wallhaven Random.lnk` (`schtasks /run /tn WallhavenRandom`).

## Uso
```powershell
# Manual con tema específico
powershell -ExecutionPolicy Bypass -File wallhaven-random.ps1 -Query "spiderman"
powershell -ExecutionPolicy Bypass -File wallhaven-toplist.ps1 -Page 3

# Cambiar temas: edita topics.txt (una línea por tema)
# GDrive: Wallhaven/ está vinculado a G:\ para retención (.tmp.drivedownload)
```

## Android (open source)
- **Termux + Termux:API** con el mismo API (`termux-wallpaper -f ...` + `termux-job-scheduler`)
- **WallYou** (`Bnyro/WallYou` GPL-3.0) y **Muzei** (`romannurik/muzei`) + plugin Wallhaven

## Instalación
```powershell
winget install --id GitHub.cli --location "D:\Program Files\GitHub CLI"
winget install --id Git.Git --location "D:\Program Files\Git"
# Lively Wallpaper 2.2.1.0 ya instalado en C:\Users\Carlos\AppData\Local\Programs\Lively Wallpaper
```

Licencia MIT
