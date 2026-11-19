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
# DRY_RUN=false: dos interruptores que empiezan apagados. DRY_RUN es el
# modo "ensayo": si se enciende con --dry-run, el script solo dice lo que
# haría, sin instalar nada. NO_INFOFORGE es "no clonar InfoForge".
for arg in "$@"; do
  # for arg in "$@": repasa cada argumento que le pasaste al script en la
  # terminal, por ejemplo "sudo bash install-arch.sh --dry-run". "$@" son
  # todos esos argumentos, y en cada vuelta arg vale uno distinto.
  case "$arg" in
    # case "$arg" in: mira qué vale arg y salta a la rama que coincida,
    # como el switch de C# o muchos if/else. ;; significa "fin de esta rama".
    --dry-run) DRY_RUN=true ;;
    --no-infoforge) NO_INFOFORGE=true ;;
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
# picom = transparencias y sombras. nitrogen = fondo de pantalla (en Arch
# sí existe, en el repo extra, a diferencia de Kali). feh = fondo alternativo.
# alacritty = la terminal. tmux = varias terminales en una. htop/btop = ver
# CPU y RAM. fastfetch/neofetch = datos del sistema. brightnessctl = brillo.
# xorg-xrandr = detectar la segunda pantalla. networkmanager +
# network-manager-applet = el Wi-Fi (nm-applet en la barra). blueman/bluez =
# Bluetooth. pavucontrol = volumen. pipewire, pipewire-pulse, pipewire-alsa,
# wireplumber = el sonido (en Arch no hay un paquete "pipewire-audio" como
# en Debian: se instalan estos por separado). flameshot = capturas.
# firefox = el navegador. thunar = el explorador de archivos.
# ttf-jetbrains-mono = la fuente de la terminal. lxqt-policykit = que te
# pida la contraseña cuando algo necesita permiso de administrador.
# base-devel = compilador y herramientas para construir paquetes de AUR si
# algún día hace falta (no instala nada de AUR por defecto). git = clonar repos.
run pacman -S --noconfirm --needed \
  xorg-server xorg-xinit lightdm lightdm-gtk-greeter \
  i3-wm i3status i3lock dmenu rofi picom nitrogen feh \
  alacritty tmux htop btop fastfetch neofetch brightnessctl \
  xorg-xrandr networkmanager network-manager-applet \
  bluez bluez-utils blueman pavucontrol \
  pipewire pipewire-pulse pipewire-alsa wireplumber \
  flameshot firefox thunar ttf-jetbrains-mono lxqt-policykit \
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
    "$USER_HOME/.config/alacritty" "$USER_HOME/.config/rofi" "$USER_HOME/.config/picom"
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

log "6/6 InfoForge (opcional)..."
# Paso 6: bajar InfoForge de GitHub con git clone, en tu carpeta personal.
# Solo si NO_INFOFORGE está apagado (o sea, si no pasaste --no-infoforge).
# Si la carpeta InfoForge ya existe, no se clona de nuevo.
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

log "Listo."
echo "Ahora: cierra sesión, en el login elige la sesión 'i3' y entra."
echo "Primera vez en i3: Mod = Alt, acepta generar la config si te lo pregunta."
echo "Atajos: Alt+Return terminal · Alt+T 4 terminales · Alt+M ir al monitor (espacio 1) · Alt+D lanzador · Alt+I InfoForge · Alt+Shift+B bienvenida · Alt+Shift+P captura completa"
echo "Fondo de pantalla: nitrogen --restore ya funciona en Arch (nitrogen sí está en el repo extra)."
echo "Si quieres cambiar el fondo, corre 'nitrogen' y elige tu foto; con feh también vale: feh --bg-fill ~/Imágenes/tu-foto.png"
