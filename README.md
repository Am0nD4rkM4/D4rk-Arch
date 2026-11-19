# ForgeOS para Arch — Arch Linux + i3

**ForgeOS para Arch · Personalización sobre Arch Linux · Escritorio i3 tiling con monitor a pantalla completa en el espacio 1 · Con InfoForge**

ForgeOS para Arch es lo mismo que ForgeOS, pero sobre Arch Linux de verdad: mínimo, solo terminales en mosaico, todo con teclado. Es tu meta a largo plazo: Arch como sistema de uso diario, con el escritorio que ya conoces de ForgeOS en Debian/Kali.

## Lo importante: esto NO convierte Kali en Arch

Kali es Debian, Arch es otra distro distinta: otro instalador, otro gestor de paquetes (`pacman` en vez de `apt`) y otros paquetes. **No existe un script que convierta Kali/Debian en Arch.** Para tener Arch hay que instalar Arch desde su ISO, y eso borra lo que haya en el disco o la partición que elijas. Este proyecto es solo la personalización que va **después** de instalar Arch.

## Pasos

### 1) Respalda Kali antes de nada

Copia a un USB o a otro disco todo lo que no quieras perder de Kali:

- Tus proyectos: `~/Proyectos/D4rkSploit`, `~/Proyectos/ForgeOS`, InfoForge, Mini InfoForge, tus temas de FL Studio Mobile.
- Tus archivos personales: fotos, documentos, la carpeta `~/Imágenes` (incluida tu foto de fondo).
- Anota tus contraseñas y tus Wi-Fi, que en Arch tendrás que volver a ponerlos.

Si no respaldas, al reemplazar Kali lo pierdes todo de ese disco.

### 2) Arranca la ISO de Arch desde Ventoy

1. Descarga la ISO de Arch Linux (archlinux.org/download) y cópiala a tu USB Ventoy.
2. Arranca la laptop desde el USB y elige la ISO de Arch.
3. Comprueba internet: `ping -c 3 archlinux.org`. Si usas Wi-Fi, conéctate con `iwctl` (ver la wiki de Arch) o por cable/USB tethering.

### 3) Instala Arch reemplazando Kali

Con `archinstall` (el instalador guiado que trae la ISO):

```bash
archinstall
```

- Elige tu idioma, teclado, zona horaria y tu usuario con contraseña.
- En **discos**, elige el disco o la partición donde está Kali y **reemplázala** (o borra todo el disco si Kali es lo único que hay). Esto **BORRA Kali** de ahí.
- Perfil: **minimal** (mínimo) o sin escritorio: la personalización de ForgeOS pone i3 después. No elijas GNOME ni KDE, que es lo que no quieres.
- Activa NetworkManager y el sonido si te lo ofrece.
- Cuando termine, reinicia y saca el USB.

Si prefieres instalar a mano (particiones, `pacstrap`, `grub`), sigue la guía oficial de Arch (wiki.archlinux.org/title/Installation_guide). Es más larga, pero es la forma de aprender cómo funciona Arch por dentro.

### 4) Instala ForgeOS para Arch

Ya dentro de tu Arch, con internet:

```bash
# Copia este proyecto a tu Arch (desde el USB, o clonándolo de GitHub
# cuando esté subido, o con scp desde otra máquina).
cd ~/forgeos-arch
sudo bash install-arch.sh
```

Prueba en seco, sin instalar nada:

```bash
sudo bash install-arch.sh --dry-run
```

El instalador actualiza pacman, instala Xorg, LightDM, i3, rofi, picom, nitrogen, feh, Alacritty, btop y el resto, copia las configs a `~/.config/` (con copia de seguridad si ya tenías una config de i3) e intenta clonar InfoForge.

### 5) Entra a i3

Cierra sesión, en el login elige la sesión **i3** y entra. La primera vez, Mod = Alt.

## Cómo se ve

Tema verde hacker sobre negro: bordes, barra, rofi y terminal en verde `#00ff41`, terminal Alacritty translúcida (opacity 0.80) con fondo negro.

Al entrar a i3 se abre una terminal de bienvenida con el banner del sistema y un resumen (usuario, fecha, RAM, disco, IP); pulsa Enter para cerrarla, o vuelve a abrirla con `Alt+Shift+B`. Después, el monitor está **a pantalla completa en el espacio 1** (btop arriba, tus datos abajo: usuario, equipo, uptime, RAM, disco, IP). Tú trabajas en las terminales del espacio 2.

- Para ver el monitor: `Alt+1` o `Alt+M`. Para trabajar: `Alt+2`, donde `Alt+T` abre 4 terminales en mosaico.
- Si cierras el monitor sin querer, `Alt+Shift+M` lo reabre en el espacio 1.

Con dos pantallas (laptop + monitor externo), al arrancar el espacio 1 con el monitor va a la **pantalla de la derecha**, y tú trabajas en la laptop (espacio 2).

## Espacios de trabajo

| Espacio | Para qué |
|---|---|
| `Alt+1` Monitor | Monitor a pantalla completa (btop + datos del sistema) |
| `Alt+2` Terminales | Aquí cae `Alt+T` con las 4 terminales |
| `Alt+3` | Libre, por ejemplo el navegador |
| `Alt+4` | Libre, por ejemplo InfoForge |
| `Alt+5` … `Alt+0` | Libres, hasta 10 espacios |

## Atajos de i3 (Mod = Alt)

| Atajo | Qué hace |
|---|---|
| `Alt+M` | **Ir al monitor (espacio 1, a pantalla completa)** |
| `Alt+Shift+M` | Reabrir el monitor en el espacio 1 si se cerró |
| `Alt+Return` | Nueva terminal |
| `Alt+Shift+Return` | Terminal con tmux |
| `Alt+T` | **4 terminales en mosaico** (espacio 2) |
| `Alt+D` | Lanzador rofi |
| `Alt+I` | InfoForge interactivo |
| `Alt+Shift+I` | InfoForge — sistema local |
| `Alt+H/J/K/L` o flechas | Moverse entre ventanas |
| `Alt+Shift+H/J/K/L` o flechas | Mover ventana (al llegar al borde, pasa a la otra pantalla) |
| `Alt+V` / `Alt+B` | Dividir vertical / horizontal |
| `Alt+F` | Pantalla completa |
| `Alt+Shift+F` | Ventana flotante |
| `Alt+1` … `Alt+0` | Espacios de trabajo 1-10 |
| `Alt+Shift+1` … | Mover ventana a ese espacio |
| `Alt+R` y luego `H/J/K/L` | Redimensionar |
| `Alt+Shift+Q` | Cerrar ventana |
| `Alt+Shift+C` / `Alt+Shift+R` | Recargar / reiniciar i3 |
| `Alt+Shift+E` | Salir de i3 (cerrar sesión) |
| `Alt+Control+L` | Bloquear pantalla |
| `Print` | Captura con flameshot |
| `Alt+Shift+B` | Bienvenida (banner + resumen del sistema) |
| `Alt+Shift+P` | Captura completa, guardada en `~/Imágenes` |
| `Alt+O` | Datos del sistema en una terminal |

¿Prefieres la tecla Super (Windows) como Mod? Cambia la primera línea de `config/i3/config`: `set $mod Mod4`.

## Fondo de pantalla

En Arch `nitrogen` **sí existe** (repo extra), así que no pasa lo de Kali:

```bash
nitrogen
```

Elige tu foto y nitrogen la guarda para el próximo arranque (`nitrogen --restore` ya está en la config de i3). Con `feh` también vale:

```bash
feh --bg-fill ~/Imágenes/tu-foto.png
```

## Tus herramientas de Kali en Arch

Las herramientas que usas en Kali están en los repos de Arch, con otros nombres de paquete en algún caso:

| En Kali/Debian | En Arch | Para qué |
|---|---|---|
| `nmap` | `nmap` | Escáner de puertos |
| `dig` (dnsutils) | `dig` (paquete `bind-tools`) | DNS |
| `whois` | `whois` | Datos de un dominio |
| `curl` | `curl` | Pedir cosas a webs |
| `openssl` | `openssl` | Certificados TLS |
| `nc` (netcat) | `nc` (paquete `openbsd-netcat`) | Banner / conexiones TCP |
| `python3` | `python` | Python |

El instalador ya instala `nmap`, `whois`, `bind-tools`, `openbsd-netcat`, `curl`, `openssl` y `python` en el paso 3/6.

Para más herramientas de pentest, en Arch existe el repositorio **BlackArch** (opcional, no se instala por defecto): es un repositorio aparte con miles de herramientas de seguridad para Arch. Si algún día lo quieres, se añade siguiendo su guía oficial (blackarch.org), pero no hace falta para empezar.

## Qué lleva preinstalado

- **Escritorio:** i3, i3status, i3lock, rofi, picom, nitrogen, feh, LightDM
- **Monitor:** btop, fastfetch, `forgeos-monitor`, `forgeos-sysinfo`
- **Terminal:** Alacritty (JetBrains Mono), verde `#00ff41` sobre negro, translúcida (opacity 0.80), tmux
- **Sistema:** htop, btop, NetworkManager, Bluetooth, PipeWire, brightnessctl
- **Archivos y web:** Thunar, Firefox, flameshot
- **Red / seguridad:** nmap, whois, bind-tools (dig), openbsd-netcat, curl, openssl, python, jq

## Estructura

```
forgeos-arch/
├── README.md
├── install-arch.sh       # Arch base -> ForgeOS para Arch
├── LICENSE               # licencia exclusiva de Luis Antonio Angel Alencastro
├── config/
│   ├── i3/config
│   ├── i3status/config
│   ├── alacritty/alacritty.toml
│   ├── rofi/config.rasi
│   └── picom/picom.conf
├── scripts/
│   ├── forgeos-quad      # abre 4 terminales en mosaico (espacio 2)
│   ├── forgeos-monitor   # monitor a pantalla completa en el espacio 1
│   ├── forgeos-pantallas # dos pantallas: espacio 1 a la pantalla derecha
│   ├── forgeos-sysinfo   # usuario, uptime, RAM, disco, IP
│   └── forgeos-bienvenida # banner + resumen al entrar a i3
└── tests/test_forgeos_arch.py
```

## Pruebas

```bash
python3 tests/test_forgeos_arch.py
bash -n install-arch.sh
sudo bash install-arch.sh --dry-run
```

## Diferencias con ForgeOS en Debian/Kali

- **Gestor de paquetes:** `pacman` en vez de `apt`. No hay `apt-get`, `dpkg` ni paquetes `.deb`.
- **Nombres de paquete:** `i3-wm` (no `i3`), `network-manager-applet` (no `network-manager-gnome`), `bind-tools` (no `dnsutils`), `openbsd-netcat` (no `netcat`), `xorg-xrandr` (no `x11-xserver-utils`).
- **Sonido:** en Arch no hay un paquete `pipewire-audio` como en Debian: se instalan `pipewire`, `pipewire-pulse`, `pipewire-alsa` y `wireplumber` por separado.
- **nitrogen sí existe** en Arch (repo extra), así que el fondo funciona sin el apaño de Kali.
- **i3-wm 4.25 ya trae los gaps dentro** (antes era el paquete aparte `i3-gaps`), así que la config de gaps funciona tal cual.
- **Arch no tiene versiones fijas:** es rolling release, se actualiza con `pacman -Syu` cuando quieras, sin cambiar de versión como Debian 12 a 13.
- **El login es LightDM**, igual que en Debian, y se elige la sesión i3 en el login.

## Advertencias honestas

- Esto es una **personalización sobre Arch Linux**, no una distro desde cero. No tiene gestor de paquetes propio ni repositorios propios: usa los de Arch.
- **Instalar Arch borra Kali** del disco o la partición que elijas. Respalda antes.
- No instales esto en tu PC principal sin haber probado antes el instalador con `--dry-run` y, si puedes, Arch en una máquina de pruebas.
- Arch es rolling release y a veces un paquete cambia de nombre o de repo: si `pacman` dice que un paquete no existe, busca su nombre actual en archlinux.org/packages antes de forzarlo.

## Licencia

Licencia exclusiva de Luis Antonio Angel Alencastro (ver `LICENSE`). ForgeOS para Arch usa Arch Linux y i3, con sus propias licencias.
