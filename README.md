# Wallhaven Scrapper — Documentación pública

> **Repo informativo** para replicar el flujo de wallpapers de wallhaven.cc usado en Windows 11 + Lively Wallpaper / Presentación nativa. No contiene imágenes, solo **cómo usar la app del scrapper, endpoints, y configuración de rutas de almacenaje** para que cualquiera pueda replicarlo.

## Qué hace

Scrapper en PowerShell que consulta la **API pública de Wallhaven** y guarda wallpapers en disco. El fondo de pantalla lo gestiona **Windows Presentación** (slideshow) o **Lively Wallpaper**, el scrapper **solo descarga y almacena**.

## Endpoints (Wallhaven API v1)

Base: `https://wallhaven.cc/api/v1`

| Uso | Endpoint | Ejemplo |
|-----|----------|---------|
| **Toplist** (más populares) | `/search?categories=111&purity=100&sorting=toplist&topRange=1M&order=desc&page=<n>` | `.../search?sorting=toplist&topRange=1M&page=3` |
| **Random** por tema | `/search?categories=111&purity=100&sorting=random&q=<query>&atleast=1920x1080&ratios=16x9` | `.../search?q=spiderman&sorting=random` |
| **Detalle wallpaper** | `/w/<id>` | `/w/lydkg2` → `path`, `tags[]`, `resolution` |
| **Tags** | `/tag/<id>` | `/tag/879` (Berserk) |

- `categories`: `100`=General `010`=Anime `001`=People → `111`=todos
- `purity`: `100`=SFW `010`=Sketchy `001`=NSFW
- `sorting`: `toplist`, `random`, `date_added`, `views`, `favorites`, `hot`
- `topRange`: `1d,3d,1w,1M,3M,6M,1y` (solo con `toplist`)
- `atleast`: `1920x1080` | `ratios`: `16x9`

**HTML scrapping alternativo:** `https://wallhaven.cc/toplist?page=3` (thumbs `https://th.wallhaven.cc/small/...`, full `https://w.wallhaven.cc/full/.../wallhaven-<id>.jpg`)

No requiere API key para SFW. Respuesta JSON: `{ data: [{ id, url, path, resolution, category, tags[] }], meta: { current_page, last_page } }`

## Rutas de almacenaje (configuración replicable)

| Ruta | Contenido | Notas |
|------|-----------|-------|
| `D:\Carlos\Pictures\Wallhaven\Toplist\` | `toplist-p<page>-<id>.jpg/png` | **Almacenaje principal**. Windows Presentación apunta aquí. `HistoryKeep=500`. Sincronizada a **GDrive** `G:\` (retención, `.tmp.drivedownload`). |
| `D:\Carlos\Pictures\Wallhaven\topics.txt` | 1 tema por línea (47 por defecto: superheroes, programming, nature, Berserk...) | El scrapper random elige uno al azar si no se pasa `-Query`. Sincronizado a GDrive. |
| `D:\Carlos\Pictures\Wallhaven\tags-berserk-*.txt` | Captura de 23 tags del sidebar (`anime, minimalism, Berserk...` con `id` y `https://wallhaven.cc/tag/<id>`) | Solo estadística, no se usa para búsqueda fija. |
| `D:\Carlos\Pictures\Wallhaven\current.jpg` | Copia del último aplicado (legacy, hoy no se usa) | Antes `Lively setwp --file current.jpg`, hoy solo descarga. |

> **Para replicar en otro disco:** cambia `$dst` en `wallhaven-toplist.ps1` y la carpeta elegida en `Personalizar > Tema > Presentación > Examinar`.

## App del scrapper

### Scripts

| Archivo | Descripción |
|---------|-------------|
| `wallhaven-toplist.ps1` | **Scrapper principal**: `param TopRange, Page (0=random 1,3,4), Category, Purity, HistoryKeep`. Solo descarga, **no asigna wallpaper** (respeta Presentación). |
| `wallhaven-random.ps1` | Random por `topics.txt` o `-Query "spiderman"` → `current.jpg` + `Lively setwp` (uso manual). |
| `wallhaven-auto.ps1` | Loop `while(true){ wallhaven-random; sleep N }` para tarea. |
| `Wallhaven-Random.bat` | Doble click manual. |
| `wallhaven-termux.sh` | Equivalente Android (Termux + termux-api). |

### Uso

```powershell
# Toplist random 1,3,4 (recomendado)
powershell -ExecutionPolicy Bypass -File wallhaven-toplist.ps1
powershell -File wallhaven-toplist.ps1 -Page 3 -TopRange 1M

# Tema específico
powershell -File wallhaven-random.ps1 -Query "cyberpunk"
powershell -File wallhaven-random.ps1 -Query "design system"

# Editar temas
notepad D:\Carlos\Pictures\Wallhaven\topics.txt
```

## Configuración Windows para replicar

1. **Carpeta:** crea `D:\Wallhaven\Toplist` (o tu ruta) y dale permiso a tu usuario (si `D:\` pide admin, crea dentro de `D:\TuUsuario\`).
2. **Presentación:** `Configuración > Personalización > Tema > Presentación` → `Examinar` → elige `Toplist` → `Cambiar imagen cada 10 min` → `Aleatorio Activado` → `Rellenar`.
3. **Tarea programada `WallhavenRandom`:**
   ```powershell
   $action = New-ScheduledTaskAction -Execute powershell.exe -Argument '-NoProfile -ExecutionPolicy Bypass -File "D:\...\wallhaven-toplist.ps1"'
   $t1 = New-ScheduledTaskTrigger -AtStartup; $t2 = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
   $t3 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 30) -RepetitionDuration (New-TimeSpan -Days 365)
   Register-ScheduledTask -TaskName WallhavenRandom -Action $action -Trigger @($t1,$t2,$t3) -Force
   ```
   + acceso directo escritorio `Wallhaven Random.lnk` → `schtasks /run /tn WallhavenRandom`
4. **GDrive retención (opcional):** con **Google Drive para escritorio**, elige `Toplist` y `topics.txt` para sincronizar a `G:\My Drive\Wallhaven`.

## Android (open source)

- **WallYou** (`Bnyro/WallYou` GPL-3.0, F-Droid) — fuente Wallhaven Toplist directa.
- **Muzei** (`romannurik/muzei` Apache 2.0) + plugin Wallhaven.
- **Termux + Termux:API** → `wallhaven-termux.sh` (ver repo) + `termux-job-scheduler --period-ms 1800000`.

## Requisitos

- Windows 11, PowerShell 5.1+, `Invoke-RestMethod`/`Invoke-WebRequest`, conexión a `wallhaven.cc`
- Instalación previa: `winget install Git.Git`, `winget install --id GitHub.cli`, Lively Wallpaper opcional.

Licencia MIT — solo documentación, sin imágenes.
