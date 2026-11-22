#!/usr/bin/env bash
# ForgeOS para Arch — instalador
# Transforma un Arch Linux base ya instalado (con archinstall o a mano)
# en ForgeOS para Arch: Arch + i3, solo terminales en mosaico.
#
# ESTE SCRIPT NO INSTALA ARCH. Arch se instala antes, desde su ISO
# (arrancando desde el USB Ventoy), y NO se puede convertir un
# Kali/Debian en Arch con un script: son distros distintas, con otro
# gestor de paquetes y otros paquetes. Este script solo pone la
# personalización de ForgeOS encima de un Arch que ya existe.
#
# Uso (ya dentro de tu Arch, como usuario normal con sudo):
#   sudo bash install-arch.sh            # instalación completa
#   sudo bash install-arch.sh --dry-run  # solo muestra lo que haría
#   sudo bash install-arch.sh --no-infoforge  # sin clonar InfoForge
#   sudo bash install-arch.sh --no-seguridad  # sin el paso 7/7 de seguridad
#   sudo bash install-arch.sh --con-blackarch  # además, BlackArch + metasploit y armitage
#     --con-blackarch es OPCIONAL y aparte: añade el repositorio de
#     BlackArch (un repo de terceros, no oficial de Arch) con su script
#     strap.sh, y luego instala metasploit y armitage desde ahí.
#     Metasploit es pesado (cientos de MB) y solo sirve para tus pruebas
#     en tu propio laboratorio o con permiso. Sin ese flag, el paso 7/7
#     instala solo herramientas de los repos oficiales de Arch.
#   Tor sí va en el paso 7/7 por defecto: tor + torbrowser-launcher
#     (repos oficiales). La primera vez que corres torbrowser-launcher
#     descarga el Tor Browser oficial y lo verifica.
#
# Requiere: Arch Linux instalado, conexión a internet, sudo.
# Después: cierra sesión, en el login elige la sesión "i3" y entra.
set -euo pipefail
# set -euo pipefail: "si algo falla, para el script en seco".
# -e = si un comando da error, el script se detiene (no sigue a ciegas).
# -u = si se usa una variable que no existe, da error en vez de usarla vacía.
# -o pipefail = si algo falla dentro de una tubería (|), también cuenta como error.

DRY_RUN=false
NO_INFOFORGE=false
NO_SEGURIDAD=false
CON_BLACKARCH=false
# DRY_RUN=false: dos interruptores que empiezan apagados. DRY_RUN es el
# modo "ensayo": si se enciende con --dry-run, el script solo dice lo que
# haría, sin instalar nada. NO_INFOFORGE es "no clonar InfoForge".
# NO_SEGURIDAD es "saltarse el paso 7/7". CON_BLACKARCH es "añadir el
# repo BlackArch e instalar metasploit y armitage" (opcional, apagado).
for arg in "$@"; do
  # for arg in "$@": repasa cada argumento que le pasaste al script en la
  # terminal, por ejemplo "sudo bash install-arch.sh --dry-run". "$@" son
  # todos esos argumentos, y en cada vuelta arg vale uno distinto.
  case "$arg" in
    # case "$arg" in: mira qué vale arg y salta a la rama que coincida,
    # como el switch de C# o muchos if/else. ;; significa "fin de esta rama".
    --dry-run) DRY_RUN=true ;;
    --no-infoforge) NO_INFOFORGE=true ;;
    --no-seguridad) NO_SEGURIDAD=true ;;
    --con-blackarch) CON_BLACKARCH=true ;;
    *) echo "Opción desconocida: $arg"; exit 2 ;;
    # *: "cualquier otra cosa": si el argumento no es ninguno de los dos
    # conocidos, avisa y sale con código 2 (error).
  esac
done

run() {
  # run() es una función auxiliar: "corre este comando, o solo dilo si
  # estamos en modo ensayo". "$@" son los argumentos que le pases a run,
  # y "$*" es lo mismo pero pegado en un solo texto.
  if $DRY_RUN; then echo "[dry-run] $*"; else "$@"; fi
  # Si DRY_RUN está encendido, solo imprime "[dry-run] comando...".
  # Si no, ejecuta el comando de verdad con "$@".
}
log() { echo "==> $*"; }
# log() es otra función auxiliar: imprime un título con ==> delante,
# para que se vean los pasos en la terminal.

if [[ $EUID -ne 0 && $DRY_RUN == false ]]; then
  # $EUID es el número de usuario que corre el script: 0 es root.
  # -ne 0 significa "distinto de 0", o sea, "no eres root".
  # && significa "y además". O sea: "si no eres root Y no es un ensayo".
  echo "Ejecuta con sudo: sudo bash install-arch.sh"
  exit 1
  # exit 1: sale del script con código 1, que significa "hubo un error".
  # Instalar paquetes necesita ser root, por eso se pide sudo.
fi

# Comprobación de que esto es Arch, no Debian/Kali: si existe apt, no es Arch.
# pacman -Q significa "¿pacman conoce este paquete?". Si pacman no existe,
# el script se equivoca de sistema y para, para no romper nada.
# En --dry-run no se exige pacman: el ensayo solo muestra lo que haría.
if [[ $DRY_RUN == false ]] && ! command -v pacman >/dev/null 2>&1; then
  echo "Esto no parece Arch Linux: no se encontró pacman."
  echo "Este script es solo para Arch. En Kali/Debian usa install-kali-i3.sh de ForgeOS."
  exit 1
fi

log "ForgeOS para Arch — Arch Linux + i3"

log "1/6 Actualizando pacman..."
# pacman -Syu: sincroniza la lista de paquetes (-y) y actualiza (-u) el sistema.
# --noconfirm es "sí a todo, no preguntes". En Arch hay que actualizar antes
# de instalar, porque instalar con la base vieja da errores de dependencias.
run pacman -Syu --noconfirm

log "2/6 Instalando Xorg, LightDM, i3 y utilidades..."
# La barra \ al final de cada línea significa "esta lista sigue en la
# línea siguiente": es un solo comando pacman -S, partido en varias líneas.
# Qué es cada cosa (nombres de Arch, verificados en archlinux.org):
# xorg-server/xorg-xinit = el sistema gráfico. lightdm (+ lightdm-gtk-greeter)
# = la pantalla de login, donde eliges la sesión i3. i3-wm = el escritorio
# en mosaico (en Arch 4.25 ya trae los gaps dentro). i3status = la barra de
# arriba. i3lock = bloquear pantalla. dmenu/rofi = lanzadores de programas.
# picom = transparencias y sombras. feh = fondo de pantalla (nitrogen ya
# no está en los repos oficiales de Arch: lo quitaron, como a neofetch).
# alacritty = la terminal. tmux = varias terminales en una. htop/btop = ver
# CPU y RAM. fastfetch = datos del sistema (neofetch ya no está en los
# repos de Arch: su proyecto se archivó en 2024 y lo quitaron).
# brightnessctl = brillo.
# xorg-xrandr = detectar la segunda pantalla. networkmanager +
# network-manager-applet = el Wi-Fi (nm-applet en la barra). blueman/bluez =
# Bluetooth. pavucontrol = volumen. pipewire, pipewire-pulse, pipewire-alsa,
# wireplumber = el sonido (en Arch no hay un paquete "pipewire-audio" como
# en Debian: se instalan estos por separado). flameshot = capturas.
# firefox = el navegador. thunar = el explorador de archivos.
# mpv = reproductor de vídeo (fondo animado v2). ffmpeg = genera el vídeo
# del fondo animado en tu máquina (aurora verde, 20 s en bucle).
# ttf-jetbrains-mono = la fuente de la terminal. lxqt-policykit = que te
# pida la contraseña cuando algo necesita permiso de administrador.
# base-devel = compilador y herramientas para construir paquetes de AUR si
# algún día hace falta (no instala nada de AUR por defecto). git = clonar repos.
run pacman -S --noconfirm --needed \
  xorg-server xorg-xinit lightdm lightdm-gtk-greeter \
  i3-wm i3status i3lock dmenu rofi picom feh \
  alacritty tmux htop btop fastfetch brightnessctl \
  xorg-xrandr networkmanager network-manager-applet \
  bluez bluez-utils blueman pavucontrol \
  pipewire pipewire-pulse pipewire-alsa wireplumber \
  flameshot firefox thunar mpv ffmpeg ttf-jetbrains-mono lxqt-policykit \
  base-devel git

log "3/6 Herramientas de red / seguridad (opcionales, para tus pruebas)..."
# nmap = escáner de puertos. whois = datos de un dominio. bind-tools = dig
# y nslookup (en Arch no se llama dnsutils como en Debian). openbsd-netcat
# = netcat (nc). curl = descargar y pedir cosas a webs. openssl = certificados
# TLS. python = Python 3. jq = leer JSON en la terminal. traceroute = ver por
# dónde va la conexión. iproute2 = el comando ip. iputils = el ping.
# 2>/dev/null significa "los errores, a la basura, no los muestres".
# || true significa "aunque este comando falle, no es error": como este paso
# es opcional, si un paquete no está, el script sigue igual.
run pacman -S --noconfirm --needed \
  nmap whois bind-tools openbsd-netcat curl openssl python jq \
  traceroute iproute2 iputils 2>/dev/null || true

log "4/6 Activando servicios..."
# systemctl enable: le dice a Arch "a partir de ahora, arranca este servicio
# al encender". NetworkManager para el Wi-Fi/red, bluetooth para la bocina,
# lightdm para la pantalla de login. || true porque si archinstall ya los
# activó, no pasa nada.
run systemctl enable NetworkManager.service 2>/dev/null || true
run systemctl enable bluetooth.service 2>/dev/null || true
run systemctl enable lightdm.service 2>/dev/null || true

log "5/6 Copiando la config de ForgeOS para Arch (con copia de seguridad si ya tenías i3)..."
# USER_NAME es tu usuario real, no root: SUDO_USER es el usuario que llamó
# a sudo. ${SUDO_USER:-${USER:-$(whoami)}} significa: "usa SUDO_USER si
# existe, si no USER, si no, lo que diga whoami". whoami dice "¿quién soy yo?".
USER_NAME="${SUDO_USER:-${USER:-$(whoami)}}"
USER_HOME="/home/$USER_NAME"
# USER_HOME es tu carpeta personal, por ejemplo /home/am0nd4rk.
[[ "$USER_NAME" == "root" ]] && USER_HOME="/root"
# Si el usuario es root, su casa no es /home/root, es /root.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# SCRIPT_DIR es la carpeta donde está este script: dirname "$0" dice
# "la carpeta del script" y cd + pwd la convierte en ruta completa.
# Así el script encuentra sus archivos config/ y scripts/ esté donde esté.
if [[ -n "$USER_HOME" && -d "$USER_HOME" ]]; then
  # mkdir -p crea las carpetas de configuración si no existen.
  run mkdir -p "$USER_HOME/.config/i3" "$USER_HOME/.config/i3status" \
    "$USER_HOME/.config/alacritty" "$USER_HOME/.config/rofi" "$USER_HOME/.config/picom" \
    "$USER_HOME/.config/forgeos"
  # Si ya tenías una config de i3, se guarda una copia de seguridad con la
  # fecha y hora en el nombre (config.bak-20261118-183000), antes de sobrescribirla.
  if [[ -f "$USER_HOME/.config/i3/config" ]]; then
    STAMP="$(date +%Y%m%d-%H%M%S)"
    if $DRY_RUN; then
      echo "[dry-run] copia de seguridad de $USER_HOME/.config/i3/config a config.bak-$STAMP"
    else
      cp "$USER_HOME/.config/i3/config" "$USER_HOME/.config/i3/config.bak-$STAMP"
      echo "Copia de seguridad: ~/.config/i3/config.bak-$STAMP"
    fi
  fi
  # cp copia cada archivo de config de ForgeOS para Arch a tu carpeta .config.
  # chmod +x hace ejecutables los scripts. chown -R les pone tu usuario
  # como dueño, para que puedas editarlos sin ser root.
  run cp "$SCRIPT_DIR/config/i3/config" "$USER_HOME/.config/i3/config"
  run cp "$SCRIPT_DIR/config/i3status/config" "$USER_HOME/.config/i3status/config"
  run cp "$SCRIPT_DIR/config/alacritty/alacritty.toml" "$USER_HOME/.config/alacritty/alacritty.toml"
  run cp "$SCRIPT_DIR/config/rofi/config.rasi" "$USER_HOME/.config/rofi/config.rasi"
  run cp "$SCRIPT_DIR/config/picom/picom.conf" "$USER_HOME/.config/picom/picom.conf"
  run cp "$SCRIPT_DIR/scripts/forgeos-quad" /usr/local/bin/forgeos-quad
  run chmod +x /usr/local/bin/forgeos-quad
  run cp "$SCRIPT_DIR/scripts/forgeos-monitor" /usr/local/bin/forgeos-monitor
  run chmod +x /usr/local/bin/forgeos-monitor
  run cp "$SCRIPT_DIR/scripts/forgeos-pantallas" /usr/local/bin/forgeos-pantallas
  run chmod +x /usr/local/bin/forgeos-pantallas
  run cp "$SCRIPT_DIR/scripts/forgeos-sysinfo" /usr/local/bin/forgeos-sysinfo
  run chmod +x /usr/local/bin/forgeos-sysinfo
  # forgeos-bienvenida: la pantalla de bienvenida que se abre al entrar a i3.
  run cp "$SCRIPT_DIR/scripts/forgeos-bienvenida" /usr/local/bin/forgeos-bienvenida
  run chmod +x /usr/local/bin/forgeos-bienvenida
  # forgeos-menu: el menú principal en rofi (Alt+Shift+N). forgeos-fondo:
  # el fondo animado (mpv + xwinwrap). forgeos-atajos: la chuleta de
  # atajos en rofi (Alt+Shift+A). Logo FORGEOS para la primera terminal.
  run cp "$SCRIPT_DIR/scripts/forgeos-menu" /usr/local/bin/forgeos-menu
  run chmod +x /usr/local/bin/forgeos-menu
  run cp "$SCRIPT_DIR/scripts/forgeos-fondo" /usr/local/bin/forgeos-fondo
  run chmod +x /usr/local/bin/forgeos-fondo
  run cp "$SCRIPT_DIR/scripts/forgeos-atajos" /usr/local/bin/forgeos-atajos
  run chmod +x /usr/local/bin/forgeos-atajos
  # instalar-herramientas-kali.sh: instala las herramientas de Kali más
  # usadas (repos oficiales + BlackArch + AUR). Se corre aparte con sudo.
  run cp "$SCRIPT_DIR/scripts/instalar-herramientas-kali.sh" /usr/local/bin/instalar-herramientas-kali.sh
  run chmod +x /usr/local/bin/instalar-herramientas-kali.sh
  run cp "$SCRIPT_DIR/config/forgeos/logo.txt" "$USER_HOME/.config/forgeos/logo.txt"
  run chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config" 2>/dev/null || true
  # tmux útil: si no tienes .tmux.conf, se crea uno básico.
  if [[ ! -f "$USER_HOME/.tmux.conf" ]]; then
    if $DRY_RUN; then
      echo "[dry-run] escribir $USER_HOME/.tmux.conf"
    else
      printf '%s\n' 'set -g mouse on' 'set -g history-limit 10000' \
        'bind | split-window -h' 'bind - split-window -v' > "$USER_HOME/.tmux.conf"
    fi
    run chown "$USER_NAME:$USER_NAME" "$USER_HOME/.tmux.conf" 2>/dev/null || true
  fi
fi

log "Fondo animado y prompt multicolor (v2)..."
# xwinwrap NO está en los repos oficiales, y el paquete `xwinwrap` del
# AUR ya no existe (su repo git viene vacío: git clone avisa "repositorio
# sin contenido" y makepkg dice "PKGBUILD no existe"). Se compila desde
# el fork de GitHub ujjwal96/xwinwrap con make + make install, como tu
# usuario (sudo -u "$USER_NAME"); el make install lo corre el instalador
# como root. base-devel ya se instaló en el paso 2/6.
# Si falla el clonado o la compilación, el fondo animado queda apagado y
# sigue el fondo estático con feh: nada de esto rompe la instalación.
if command -v xwinwrap >/dev/null 2>&1; then
  echo "xwinwrap ya está instalado."
else
  rm -rf /tmp/forgeos-xwinwrap
  if $DRY_RUN; then
    echo "[dry-run] git clone https://github.com/ujjwal96/xwinwrap.git /tmp/forgeos-xwinwrap && make && make install (como $USER_NAME)"
  elif sudo -u "$USER_NAME" git clone https://github.com/ujjwal96/xwinwrap.git /tmp/forgeos-xwinwrap; then
    sudo -u "$USER_NAME" bash -c 'cd /tmp/forgeos-xwinwrap && make' && make install \
      || echo "Aviso: no se pudo compilar xwinwrap; el fondo animado quedará apagado (el resto sigue)."
  else
    echo "Aviso: no se pudo bajar xwinwrap de GitHub; el fondo animado quedará apagado (el resto sigue)."
  fi
fi
# Vídeo del fondo animado: se genera en tu máquina con ffmpeg, solo si
# no existe. Tarda un poco; si falla, queda el fondo estático con feh.
# env HOME="$USER_HOME": que forgeos-fondo escriba en tu casa, no en /root.
if $DRY_RUN; then
  echo "[dry-run] forgeos-fondo generar (como $USER_NAME)"
else
  sudo -u "$USER_NAME" env HOME="$USER_HOME" forgeos-fondo generar 2>/dev/null \
    || echo "Aviso: no se pudo generar el vídeo del fondo; queda el fondo estático con feh."
fi
# Prompt multicolor en ~/.bashrc, solo si no está ya (por el marcador).
# Usuario en verde, @ en amarillo, host en cian, ruta en azul, $ en verde.
if $DRY_RUN; then
  echo "[dry-run] añadir prompt ForgeOS a $USER_HOME/.bashrc (si no tiene el marcador)"
else
  if ! grep -q "ForgeOS prompt multicolor" "$USER_HOME/.bashrc" 2>/dev/null; then
    cat >> "$USER_HOME/.bashrc" <<'BASHRC_EOF'

# ForgeOS prompt multicolor
# Usuario en verde, @ en amarillo, host en cian, ruta en azul, $ en verde.
# \[...\] es "esto es color, no texto": sin eso, bash cuenta mal el largo
# del prompt y la línea se rompe al escribir. \u = usuario, \h = equipo,
# \w = carpeta actual, \$ = $ (o # si eres root).
if [[ $- == *i* ]]; then
  PS1='\[\e[1;32m\]\u\[\e[1;33m\]@\[\e[1;36m\]\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[1;32m\]\$ \[\e[0m\]'
fi
BASHRC_EOF
    chown "$USER_NAME:$USER_NAME" "$USER_HOME/.bashrc" 2>/dev/null || true
  fi
fi
# Logo FORGEOS + fastfetch en la primera terminal de cada arranque.
if $DRY_RUN; then
  echo "[dry-run] añadir logo de la primera terminal a $USER_HOME/.bashrc (si no tiene el marcador)"
else
  if ! grep -q "ForgeOS primera terminal" "$USER_HOME/.bashrc" 2>/dev/null; then
    cat >> "$USER_HOME/.bashrc" <<'BASHRC_EOF'

# ForgeOS primera terminal
# Al abrir la primera terminal de cada arranque, muestra el logo FORGEOS
# y los datos del sistema con fastfetch. El archivo /tmp/forgeos-... es
# la marca de "ya se mostró": /tmp se vacía al reiniciar, así que cada
# arranque lo muestra una sola vez y las demás terminales abren limpias.
if [[ $- == *i* && ! -f /tmp/forgeos-fastfetch-mostrado ]]; then
  if [[ -f "$HOME/.config/forgeos/logo.txt" ]]; then
    printf '\033[1;32m'
    cat "$HOME/.config/forgeos/logo.txt"
    printf '\033[0m\n'
  fi
  command -v fastfetch >/dev/null 2>&1 && fastfetch --logo none 2>/dev/null || true
  touch /tmp/forgeos-fastfetch-mostrado 2>/dev/null || true
fi
BASHRC_EOF
    chown "$USER_NAME:$USER_NAME" "$USER_HOME/.bashrc" 2>/dev/null || true
  fi
fi

log "6/6 InfoForge y Server-C (opcional)..."
# Paso 6: bajar InfoForge y Server-C de GitHub con git clone, en tu
# carpeta personal, para no tener que bajarlos a mano después.
# InfoForge solo si NO_INFOFORGE está apagado (o sea, si no pasaste
# --no-infoforge). Server-C se baja siempre en este paso, salvo que la
# carpeta ya exista: es tu servidor de laboratorio en C (solo 127.0.0.1,
# puerto 4444), para probarlo con nmap/nc/Metasploit desde la misma laptop.
# Si una carpeta ya existe, no se clona de nuevo.
# git clone descarga una copia de un repo. sudo -u "$USER_NAME" lo hace
# como tu usuario, no como root, para que los archivos sean tuyos.
# Si falla el clonado, avisa y sigue: no rompe la instalación.
if [[ "$NO_INFOFORGE" == false ]]; then
  if [[ -d "$USER_HOME/InfoForge" || -d "$USER_HOME/infoforge-linux" ]]; then
    log "InfoForge ya existe en tu home, no lo clono de nuevo."
  else
    if $DRY_RUN; then
      echo "[dry-run] git clone https://github.com/Am0nD4rkM4/InfoForge.git $USER_HOME/InfoForge (como $USER_NAME)"
    elif [[ "$USER_NAME" == "root" ]]; then
      git clone https://github.com/Am0nD4rkM4/InfoForge.git "$USER_HOME/InfoForge" 2>/dev/null || echo 'No se pudo clonar InfoForge (repo privado: usa tu SSH/token y clónalo a mano)'
    else
      sudo -u "$USER_NAME" git clone https://github.com/Am0nD4rkM4/InfoForge.git "$USER_HOME/InfoForge" 2>/dev/null || echo 'No se pudo clonar InfoForge (repo privado: usa tu SSH/token y clónalo a mano)'
    fi
  fi
fi
if [[ -d "$USER_HOME/Server-C" ]]; then
  log "Server-C ya existe en tu home, no lo clono de nuevo."
else
  if $DRY_RUN; then
    echo "[dry-run] git clone https://github.com/Am0nD4rkM4/Server-C.git $USER_HOME/Server-C (como $USER_NAME)"
  elif [[ "$USER_NAME" == "root" ]]; then
    git clone https://github.com/Am0nD4rkM4/Server-C.git "$USER_HOME/Server-C" 2>/dev/null || echo 'No se pudo clonar Server-C (revisa tu internet y clónalo a mano)'
  else
    sudo -u "$USER_NAME" git clone https://github.com/Am0nD4rkM4/Server-C.git "$USER_HOME/Server-C" 2>/dev/null || echo 'No se pudo clonar Server-C (revisa tu internet y clónalo a mano)'
  fi
fi

log "7/7 Seguridad, Tor y herramientas de pentest..."
# Paso 7: endurecer el sistema y poner herramientas de seguridad.
# Solo si NO_SEGURIDAD está apagado (por defecto va activado; se salta
# con --no-seguridad). Todo esto es SOLO para tu propia máquina y tu
# laboratorio, o un objetivo con permiso. Nunca contra terceros.
# Qué es cada cosa (nombres de Arch, repos oficiales salvo BlackArch):
# ufw = cortafuegos fácil (por encima de nftables/iptables). fail2ban =
# banea IPs que fallan muchos logins (útil si algún día abres SSH).
# lynis = auditoría de seguridad, te da nota y recomendaciones.
# arch-audit = revisa tus paquetes instalados contra la base de CVEs de Arch.
# clamav = antivirus (fresco con freshclam, no se corre solo aquí).
# rkhunter = busca rootkits conocidos. tcpdump = capturar paquetes.
# wireshark-qt = analizar red con ventana (tshark es su versión terminal).
# zenmap = la ventana gráfica de nmap (repo extra, no AUR).
# hydra = auditar contraseñas de servicios (solo tus servicios).
# john = John the Ripper, auditar hashes de contraseñas (solo tuyas).
# hashcat = lo mismo, con GPU. aircrack-ng = auditar Wi-Fi (solo tu red).
# tor = el demonio Tor (proxy SOCKS en 127.0.0.1:9050). torsocks = correr
# un programa por Tor. torbrowser-launcher = descarga, verifica y lanza
# el Tor Browser oficial (no es el navegador en sí: lo baja la primera vez).
# obfs4proxy = puentes ofuscados de Tor, por si Tor está bloqueado en una red.
if [[ "$NO_SEGURIDAD" == false ]]; then
  # 7a. Paquetes de seguridad y pentest de los repos oficiales.
  # || true: si un paquete cambió de nombre o de repo, el resto sigue.
  run pacman -S --noconfirm --needed \
    ufw fail2ban lynis arch-audit clamav rkhunter tcpdump \
    wireshark-qt zenmap hydra john hashcat aircrack-ng \
    tor torsocks torbrowser-launcher obfs4proxy 2>/dev/null || true

  # 7b. Cortafuegos: denegar todo lo que entra, permitir lo que sale.
  # ufw default deny incoming = "nada entra si no lo abro yo".
  # ufw --force enable = encenderlo sin preguntar. Si algún día abres
  # un servicio (por ejemplo tu servidor en C en el 4444, solo en local),
  # ese puerto NO se abre solo: tendrías que hacer "sudo ufw allow 4444/tcp".
  # Ojo: esto no abre nada hacia internet; el servidor en C escucha solo
  # en 127.0.0.1, así que ni siquiera llega al cortafuegos desde fuera.
  run ufw default deny incoming 2>/dev/null || true
  run ufw default allow outgoing 2>/dev/null || true
  run ufw --force enable 2>/dev/null || true
  run systemctl enable ufw.service 2>/dev/null || true
  run systemctl enable fail2ban.service 2>/dev/null || true
  run systemctl enable tor.service 2>/dev/null || true

  # 7c. Endurecimiento del kernel y la red, en /etc/sysctl.d/.
  # net.ipv4.tcp_syncookies = 1: protege contra inundación SYN.
  # rp_filter = 1: descarta paquetes con origen falso (spoofing).
  # accept_redirects / send_redirects = 0: no aceptar ni mandar
  # redirecciones ICMP (alguien redirigiendo tu tráfico).
  # icmp_echo_ignore_broadcasts = 1: no responder a pings de broadcast.
  # log_martians = 1: registrar paquetes con origen imposible.
  # kernel.kptr_restrict = 2 y kernel.dmesg_restrict = 1: que un usuario
  # normal no vea direcciones del kernel ni el registro del kernel.
  # fs.protected_hardlinks / protected_symlinks = 1: que nadie cree
  # enlaces para robar o sobreescribir archivos de otro usuario.
  if $DRY_RUN; then
    echo "[dry-run] escribir /etc/sysctl.d/99-forgeos-seguridad.conf"
    echo "[dry-run] sysctl --system"
  else
    cat > /etc/sysctl.d/99-forgeos-seguridad.conf <<'EOF'
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.log_martians = 1
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
EOF
    sysctl --system 2>/dev/null || true
  fi

  # 7d. BlackArch (OPCIONAL, solo con --con-blackarch).
  # Metasploit y Armitage NO están en los repos oficiales de Arch:
  # están en BlackArch. Añadir BlackArch es añadir un repositorio de
  # terceros: su script oficial strap.sh mete el repo y sus claves en
  # /etc/pacman.conf. Por eso NO se hace solo: solo si pasas el flag.
  # metasploit = framework de explotación (msfconsole). armitage = su
  # ventana gráfica (necesita metasploit y Java). Son pesados y tardan.
  # Después: "msfconsole" para arrancar Metasploit, "armitage" para su GUI.
  if [[ "$CON_BLACKARCH" == true ]]; then
    log "BlackArch: añadiendo el repositorio (solo porque pasaste --con-blackarch)..."
    if $DRY_RUN; then
      echo "[dry-run] cd /tmp && curl -O https://blackarch.org/strap.sh && chmod +x strap.sh && ./strap.sh"
      echo "[dry-run] pacman -Sy && pacman -S metasploit armitage"
    else
      (cd /tmp && curl -O https://blackarch.org/strap.sh \
        && chmod +x strap.sh && ./strap.sh) 2>/dev/null \
        || echo 'No se pudo añadir BlackArch; revisa tu internet y blackarch.org'
      run pacman -Sy --noconfirm 2>/dev/null || true
      run pacman -S --noconfirm --needed metasploit armitage 2>/dev/null \
        || echo 'No se pudo instalar metasploit/armitage; prueba a mano: sudo pacman -S metasploit armitage'
    fi
  else
    echo "BlackArch NO añadido (por defecto). Para metasploit y armitage, corre el instalador con --con-blackarch."
  fi
  echo "Seguridad lista: ufw encendido (deny incoming), fail2ban y tor activados, sysctl endurecido."
  echo "Tor Browser: la primera vez corre 'torbrowser-launcher' en una terminal y descarga el navegador oficial."
  echo "Auditoría: 'sudo lynis audit system' y 'arch-audit' para revisar tu sistema."
else
  log "Paso 7/7 saltado (--no-seguridad)."
fi

log "Listo."
echo "Ahora: cierra sesión, en el login elige la sesión 'i3' y entra."
echo "Primera vez en i3: Mod = Alt, acepta generar la config si te lo pregunta."
echo "Atajos: Alt+Return terminal · Alt+T 4 terminales · Alt+M ir al monitor (espacio 1) · Alt+D lanzador · Alt+I InfoForge · Alt+Shift+B bienvenida · Alt+Shift+P captura completa"
echo "Fondo de pantalla: con feh (nitrogen ya no está en los repos de Arch)."
echo "Para poner tu foto: feh --bg-fill ~/Imágenes/tu-foto.png"
if [[ "$NO_SEGURIDAD" == false ]]; then
  echo "Seguridad: revisa el cortafuegos con 'sudo ufw status verbose' y abre Tor Browser con 'torbrowser-launcher'."
fi
echo "Menú ForgeOS: Alt+Shift+N (terminal, Firefox, InfoForge, Server-C, Metasploit, Wi-Fi, fondo animado, salir...)."
echo "Prompt multicolor: abre una terminal nueva y verás usuario en verde, @ en amarillo, host en cian y ruta en azul."
echo "Fondo animado: se enciende al entrar a i3; on/off desde el menú o con 'forgeos-fondo toggle'."
echo "Server-C ya quedó en ~/Server-C: entra ahí y corre 'gcc -Wall -o servidor servidor.c && ./servidor' para probarlo en local."
