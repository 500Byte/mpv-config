# mpv-config

Configuracion personal de mpv para Linux. Optimizada para AMD Ryzen 7 5800XT + RX 580 a 1440p en CachyOS (Wayland).

## Instalacion

1. Elimina cualquier configuracion anterior de mpv (o muevela a otro lado):
```bash
rm -rf ~/.config/mpv
```

2. Clona este repositorio directamente en la carpeta de configuracion:
```bash
git clone https://github.com/500Byte/mpv-config.git ~/.config/mpv
```

Alternativamente, si ya lo descargaste (por ejemplo, en `~/mpv-config`), copia el contenido:
```bash
cp -r ~/mpv-config ~/.config/mpv
```

## Requisitos

- mpv (compilado con soporte Vulkan y VapourSynth)
- Mesa con driver radv (Vulkan para AMD)
- PipeWire (audio)


## Video

- VO: gpu-next con Vulkan (waylandvk)
- HW decode: auto-copy (H.264, HEVC, VP8, VP9, AV1)
- Dithering: error-diffusion (Floyd-Steinberg)
- Escalado luma: ewa_lanczossharp
- Escalado croma: catmull_rom
- Downscale: mitchell
- Interpolacion: sphinx (tscale-blur=0.65, display-resample)

## Shaders

Cargados por defecto (perfil NNEDI3+):
- FSRCNNX x2 16-0-4-1 (escalado luma, balance calidad/rendimiento para RX 580)
- Adaptive Sharpen Lite Luma RT (nitidez post-escalado)

Disponibles via numpad (toggle):
- KP1: Ani4Kv2 (ArtCNN)
- KP2: AniSD (ArtCNN)
- KP3: FSRCNNX
- KP4: NNEDI3 nns64
- KP5: Anime4K Restore CNN
- KP6: Anime4K Upscale GAN
- KP7: Anime4K AIO
- KP8: QCOM SGEDS (sharpen post-kernel)
- KP9: Adaptive Sharpen Lite (post-escalado)
- KP+: Adaptive Sharpen Lite Luma (luma)
- KP0: limpiar shaders

## Filtros VapourSynth

Disponibles via Alt+numpad:
- Alt+KP1: MVTools (interpolacion rapida)
- Alt+KP2: RIFE DX12
- Alt+KP3: DRBA DX12
- Alt+KP4: RIFE RTX
- Alt+KP5: DRBA RTX
- Alt+KP6: UAI DX12 (upscale IA)
- Alt+KP7: UAI RTX
- Alt+KP0: limpiar filtros

## Perfiles condicionales

- Shaders solo para contenido <= 1080p (low-res), sin shaders para 4K+ (high-res)
- Deband automatico para fuentes < 24bpp (YUV420P10)
- HDR: tone mapping automatico (bt.2390, passthrough, SDR-gamut)
- Fix para contenido 8K (cambia a hwdec auto-safe)
- Fix para FPS alto o refresh > 120Hz (desactiva display-resample)
- Pausa automatica al minimizar
- Desanclar ventana al pausar
- Salir de fullscreen cuando termina la playlist

## Scripts

- uosc: interfaz moderna (timeline, controles, menu)
- thumbfast: previsualizacion de thumbnails en la timeline
- evafast: aceleracion progresiva al mantener Right (hasta 5x)
- dynamic-crop: recorte automatico de barras negras
- dyn_menu: menu contextual con click derecho
- file-browser: explorador de archivos OSD
- clipshot: copiar screenshots al clipboard
- dialog: dialogos nativos para abrir archivo/carpeta
- inputevent: eventos click/press/release para el mouse y teclado
- recentmenu: menu de archivos recientes
- select: menu de seleccion (tracks, perfiles, configs)
- stats: estadisticas de rendimiento
- sub-assrt: buscar subtitulos online
- uosc_danmaku: soporte de danmaku (comentarios flotantes)

## Atajos principales

| Tecla | Accion |
|---|---|
| Space / p | Pausa |
| Enter / f | Fullscreen |
| Right | Seek +5s (mantener = evafast) |
| Left | Seek -5s |
| Up / Down | Volumen +/- 5% |
| Wheel | Volumen +/- 2% |
| Click derecho | Menu contextual |
| s / S | Screenshot (con/sin subs) |
| c / C | Screenshot al clipboard |
| j / J | Cambiar subtitulo |
| m | Mute |
| I | Estadisticas |
| Tab | Explorador de archivos |
| Ctrl+o | Abrir archivo |
| Ctrl+v | Pegar URL desde clipboard |
| q / Q | Salir / Salir guardando posicion |
| Ctrl+f | Buscar subtitulos (assrt) |
| Ctrl+d | Buscar danmaku |
| b | Toggle deband |
| d | Toggle deinterlace |
| e | Recorte de barras negras |
| l | A-B loop |
| T | On top |
| BS | Reset velocidad |
| KP0-KP9 | Toggle shaders |
| Alt+KP0-KP7 | Filtros VapourSynth |

## Estructura

```
mpv.conf            Config principal
input.conf          Atajos de teclado
fonts/              Fuentes (uosc, Material Design, Fluent)
scripts/            Scripts lua
script-opts/        Config de scripts
script-modules/     Modulos compartidos
shaders/            Shaders GLSL
vs/                 Scripts VapourSynth
```
