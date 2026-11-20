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

El instalador actualiza pacman, instala Xorg, LightDM, i3, rofi, picom, feh, Alacritty, btop y el resto, copia las configs a `~/.config/` (con copia de seguridad si ya tenías una config de i3), endurece la seguridad (paso 7/7, ver abajo) e intenta clonar InfoForge **y Server-C** (tu servidor de laboratorio en C, en `~/Server-C`, para probarlo en local con `nmap`, `nc` y Metasploit desde la misma laptop).

Para saltarte la seguridad:

```bash
sudo bash install-arch.sh --no-seguridad
```

Para añadir además BlackArch con Metasploit y Armitage:

```bash
sudo bash install-arch.sh --con-blackarch
```

### 5) Entra a i3

Cierra sesión, en el login elige la sesión **i3** y entra. La primera vez, Mod = Alt.

## Cómo se ve

Tema verde hacker sobre negro: bordes, barra, rofi y terminal en verde `#00ff41`, terminal Alacritty translúcida (opacity 0.80) con fondo negro.

Al entrar a i3 se abre una terminal de bienvenida con el banner del sistema y un resumen (usuario, fecha, RAM, disco, IP); pulsa Enter para cerrarla, o vuelve a abrirla con `Alt+Shift+B`. Después, el monitor está **a pantalla completa en el espacio 1** (btop arriba, tus datos abajo: usuario, equipo, uptime, RAM, disco, IP). Tú trabajas en las terminales del espacio 2.

- Para ver el monitor: `Alt+1` o `Alt+M`. Para trabajar: `Alt+2`, donde `Alt+T` abre 4 terminales en mosaico.
- Si cierras el monitor sin querer, `Alt+Shift+M` lo reabre en el espacio 1.

Con dos pantallas (laptop + monitor externo), al arrancar el espacio 1 con el monitor va a la **pantalla de la derecha**, y tú trabajas en la laptop (espacio 2).

## Novedades v2

Si ya tienes la v1 instalada, no hace falta reinstalar nada: actualiza con el actualizador (ver abajo).

- **Menú ForgeOS** con `Alt+Shift+N`: terminal, Firefox, archivos, InfoForge, Server-C, Metasploit, Armitage, Wi-Fi, Bluetooth, volumen, fondo animado, bienvenida, monitor, bloquear y salir de i3. Todo en español, en rofi con el tema verde.
- **Prompt multicolor** en la terminal: el usuario en verde, el `@` en amarillo, el host en cian, la ruta en azul y el `$` en verde. Se ve al abrir una terminal nueva.
- **Fondo animado**: un vídeo en bucle de aurora verde oscura, generado en tu máquina con ffmpeg, que se mueve detrás de las ventanas con mpv + xwinwrap. Se enciende solo al entrar a i3. Se apaga y se enciende desde el menú, o con `forgeos-fondo toggle` (también `forgeos-fondo on` y `forgeos-fondo off`). Si algo falla (xwinwrap, mpv o el vídeo), queda el fondo estático con `feh`, sin romper nada.
- **Actualizador**: si ya tienes la v1, no reinstales todo. En tu clon del repo:

```bash
cd ~/D4rk-Arch && git pull
bash update-d4rk-arch.sh
```

El actualizador instala solo lo nuevo (mpv, ffmpeg, xwinwrap del AUR, los scripts nuevos), genera el vídeo si falta, añade los atajos nuevos a tu config de i3 sin borrar lo que tengas, pone el prompt multicolor en `~/.bashrc` y recarga i3. Se puede correr varias veces: lo que ya está hecho se salta solo.

Y algún detalle más por descubrir.

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
| `Alt+Shift+N` | **Menú ForgeOS** (terminal, Firefox, InfoForge, Server-C, Metasploit, Wi-Fi, fondo animado...) |
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

En Arch `nitrogen` **ya no existe** (lo quitaron de los repos oficiales, igual que `neofetch`), así que el fondo va con `feh`, como en Kali:

```bash
feh --bg-fill ~/Imágenes/tu-foto.png
```

Esa línea ya está en la config de i3, así que el fondo se pone solo al entrar. Si cambias de foto, corre ese comando con el nombre nuevo.

### Fondo animado (v2)

Además del fondo estático, la v2 trae un fondo animado: un vídeo en bucle de aurora verde oscura (generado en tu máquina con `ffmpeg`, `~/.config/forgeos/fondo-animado.mp4`), que se mueve detrás de las ventanas con `mpv` + `xwinwrap` (este último solo está en el AUR y se compila al instalar o actualizar).

- Se enciende solo al entrar a i3. Para apagarlo o encenderlo: menú ForgeOS (`Alt+Shift+N`, "Fondo animado (on/off)") o en terminal: `forgeos-fondo toggle` (también `on`, `off` y `status`).
- Si el vídeo no existe, se genera con `forgeos-fondo generar` (tarda un poco).
- Si falta xwinwrap, mpv o el vídeo, el script avisa y deja el fondo estático con `feh`: nunca rompe el inicio de sesión.

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

## Seguridad (paso 7/7, por defecto)

El instalador endurece el sistema y pone herramientas de seguridad, todo de los repos oficiales de Arch salvo Metasploit y Armitage (ver BlackArch abajo):

- **Cortafuegos:** `ufw` con `default deny incoming` (nada entra si no lo abres tú) y `allow outgoing`. Se enciende solo. Compruébalo con `sudo ufw status verbose`. Si algún día abres un servicio, ábrelo a mano, por ejemplo `sudo ufw allow 4444/tcp`. Tu servidor en C escucha solo en `127.0.0.1`, así que no necesita abrir nada.
- **Kernel y red:** `/etc/sysctl.d/99-forgeos-seguridad.conf` con `tcp_syncookies`, `rp_filter`, sin redirecciones ICMP, `kptr_restrict` y enlaces protegidos.
- **Servicios:** `fail2ban` (banea IPs que fallan logins, útil si abres SSH) y `tor` activados al arrancar.
- **Auditoría:** `lynis` (`sudo lynis audit system`), `arch-audit` (revisa tus paquetes contra CVEs de Arch), `clamav` y `rkhunter`.
- **Pentest (repos oficiales):** `wireshark-qt`, `zenmap` (la ventana de nmap), `hydra`, `john`, `hashcat`, `aircrack-ng`, `tcpdump`. Todo solo para tu propia máquina y tu laboratorio, o un objetivo con permiso. Nunca contra terceros.

Para saltarte este paso: `sudo bash install-arch.sh --no-seguridad`.

## Tor y Tor Browser

Sí se puede, y va en el paso 7/7 por defecto, de los repos oficiales:

```bash
sudo pacman -S tor torbrowser-launcher
```

- `tor` es el demonio Tor (proxy en `127.0.0.1:9050`, activado al arrancar).
- `torbrowser-launcher` descarga, verifica y lanza el **Tor Browser** oficial la primera vez que lo corres. No es el navegador en sí, es el lanzador que lo baja de torproject.org.

```bash
torbrowser-launcher
```

La primera vez tarda porque descarga el navegador. Después lo abres igual. Tor es más lento que Firefox normal porque tu tráfico pasa por varios relevos, y algunas páginas bloquean las salidas de Tor. Es para navegar con privacidad, no para el día a día.

## BlackArch: Metasploit y Armitage (opcional, solo con `--con-blackarch`)

Metasploit y Armitage **no están en los repos oficiales de Arch**, están en BlackArch. Por eso el instalador **no** añade BlackArch por defecto: añadirlo es meter un repositorio de terceros con su script oficial `strap.sh`, y Metasploit es pesado (cientos de MB). Solo se hace si corres el instalador con:

```bash
sudo bash install-arch.sh --con-blackarch
```

Eso añade BlackArch y luego instala `metasploit` (`msfconsole`) y `armitage` (su ventana gráfica, necesita Metasploit y Java). Sin ese flag, no se instala nada de BlackArch.

Para más herramientas de pentest, en Arch existe el repositorio **BlackArch** (opcional, no se instala por defecto): es un repositorio aparte con miles de herramientas de seguridad para Arch. Si algún día lo quieres, se añade siguiendo su guía oficial (blackarch.org), pero no hace falta para empezar.

## Qué lleva preinstalado

- **Escritorio:** i3, i3status, i3lock, rofi, picom, feh, LightDM
- **Menú y fondo (v2):** `forgeos-menu` (Alt+Shift+N), `forgeos-fondo` (fondo animado con mpv + xwinwrap del AUR, vídeo generado con ffmpeg), prompt multicolor en bash
- **Monitor:** btop, fastfetch, `forgeos-monitor`, `forgeos-sysinfo`
- **Terminal:** Alacritty (JetBrains Mono), verde `#00ff41` sobre negro, translúcida (opacity 0.80), tmux
- **Sistema:** htop, btop, NetworkManager, Bluetooth, PipeWire, brightnessctl
- **Archivos y web:** Thunar, Firefox, flameshot
- **Red / seguridad:** nmap, whois, bind-tools (dig), openbsd-netcat, curl, openssl, python, jq
- **Seguridad (paso 7/7):** ufw (deny incoming), fail2ban, lynis, arch-audit, clamav, rkhunter, sysctl endurecido, wireshark-qt, zenmap, hydra, john, hashcat, aircrack-ng, tcpdump
- **Tor:** tor, torsocks, torbrowser-launcher (descarga el Tor Browser oficial), obfs4proxy
- **BlackArch (solo con `--con-blackarch`):** metasploit, armitage
- **Laboratorio:** Server-C clonado en `~/Server-C` (servidor en C, solo 127.0.0.1:4444); ahí dentro, `gcc -Wall -o servidor servidor.c && ./servidor`, y en otra terminal `nc 127.0.0.1 4444`

## Estructura

```
forgeos-arch/
├── README.md
├── install-arch.sh       # Arch base -> ForgeOS para Arch
├── update-d4rk-arch.sh   # Actualiza una v1 ya instalada a la v2 (sin reinstalar todo)
├── LICENSE               # licencia exclusiva de Luis Antonio Angel Alencastro
├── config/
│   ├── i3/config
│   ├── i3status/config
│   ├── alacritty/alacritty.toml
│   ├── rofi/config.rasi
│   ├── picom/picom.conf
│   └── forgeos/logo.txt  # logo FORGEOS de la primera terminal (v2)
├── scripts/
│   ├── forgeos-quad      # abre 4 terminales en mosaico (espacio 2)
│   ├── forgeos-monitor   # monitor a pantalla completa en el espacio 1
│   ├── forgeos-pantallas # dos pantallas: espacio 1 a la pantalla derecha
│   ├── forgeos-sysinfo   # usuario, uptime, RAM, disco, IP
│   ├── forgeos-bienvenida # banner + resumen al entrar a i3
│   ├── forgeos-menu      # menú principal en rofi (v2, Alt+Shift+N)
│   ├── forgeos-fondo     # fondo animado on/off (v2)
│   └── forgeos-atajos    # chuleta de atajos en rofi (v2, Alt+Shift+A)
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
- **El fondo va con `feh`**, porque `nitrogen` ya no está en los repos oficiales de Arch.
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
