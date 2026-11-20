#!/usr/bin/env bash
# D4rk-Arch v2 — actualizador para un Arch con D4rk-Arch v1 ya instalado.
# Lo corres DESPUÉS de bajar la última versión del repo:
#   cd ~/D4rk-Arch && git pull
#   bash update-d4rk-arch.sh
# Es idempotente: se puede correr varias veces; lo que ya está hecho se
# salta solo (paquetes, xwinwrap, vídeo, atajos, prompt). NO reinstala
# todo lo de install-arch.sh: solo añade lo nuevo de la v2.
# Necesita internet y sudo (para pacman y para copiar a /usr/local/bin).
# No hace falta ser root para correrlo: el sudo se pide dentro.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# SCRIPT_DIR es la carpeta del repo, por ejemplo ~/D4rk-Arch.

log() { echo "==> $*"; }

if ! command -v pacman >/dev/null 2>&1; then
  echo "Esto no parece Arch Linux: no se encontró pacman."
  exit 1
fi

if [[ ! -f "$SCRIPT_DIR/install-arch.sh" ]]; then
  echo "No encuentro install-arch.sh en $SCRIPT_DIR."
  echo "Corre el actualizador desde tu clon de D4rk-Arch: cd ~/D4rk-Arch && bash update-d4rk-arch.sh"
  exit 1
fi

# sudo -v pide tu contraseña una vez y la recuerda un rato, para que
# los sudo de abajo no te la pidan a cada rato.
sudo -v || true

log "1/6 Paquetes nuevos de la v2 (mpv y ffmpeg, repos oficiales)..."
# --needed: si ya están, no los baja de nuevo. Sin 2>/dev/null: si falla,
# el error real tiene que verse, no un "Aviso" genérico.
sudo pacman -S --noconfirm --needed mpv ffmpeg \
  || echo "Aviso: no se pudieron instalar mpv/ffmpeg; el fondo animado quedará apagado (el resto sigue)."

log "2/6 xwinwrap (AUR) solo si falta..."
# xwinwrap NO está en los repos oficiales, solo en el AUR. Se compila
# con makepkg, que NO se puede correr como root: se corre como tu usuario.
# makepkg necesita base-devel; el instalador v1 ya lo trae, pero si por
# lo que sea falta, se instala aquí antes de compilar. Sin 2>/dev/null:
# si el clon o la compilación fallan, el error real tiene que verse.
if command -v xwinwrap >/dev/null 2>&1; then
  echo "xwinwrap ya está instalado, lo salto."
else
  if ! command -v makepkg >/dev/null 2>&1; then
    sudo pacman -S --noconfirm --needed base-devel git \
      || echo "Aviso: no se pudo instalar base-devel; el fondo animado quedará apagado."
  fi
  rm -rf /tmp/forgeos-xwinwrap
  if git clone https://aur.archlinux.org/xwinwrap.git /tmp/forgeos-xwinwrap; then
    (cd /tmp/forgeos-xwinwrap && makepkg -si --noconfirm) \
      || echo "Aviso: no se pudo compilar xwinwrap; el fondo animado quedará apagado (el resto sigue)."
  else
    echo "Aviso: no se pudo bajar xwinwrap del AUR; revisa tu internet y corre el actualizador de nuevo."
  fi
fi

log "3/6 Copiando los scripts nuevos a /usr/local/bin..."
sudo cp "$SCRIPT_DIR/scripts/forgeos-menu" /usr/local/bin/forgeos-menu
sudo cp "$SCRIPT_DIR/scripts/forgeos-fondo" /usr/local/bin/forgeos-fondo
sudo cp "$SCRIPT_DIR/scripts/forgeos-atajos" /usr/local/bin/forgeos-atajos
sudo chmod +x /usr/local/bin/forgeos-menu /usr/local/bin/forgeos-fondo /usr/local/bin/forgeos-atajos

log "4/6 Logo FORGEOS y vídeo del fondo animado..."
mkdir -p "$HOME/.config/forgeos"
cp "$SCRIPT_DIR/config/forgeos/logo.txt" "$HOME/.config/forgeos/logo.txt"
# El vídeo solo se genera si no existe: tarda un poco (ffmpeg) y no hace
# falta repetirlo. Si falla, el fondo animado queda apagado y sigue feh.
if command -v forgeos-fondo >/dev/null 2>&1; then
  forgeos-fondo generar || echo "Aviso: no se pudo generar el vídeo; el fondo animado quedará apagado."
else
  echo "Aviso: forgeos-fondo no está en el PATH todavía; genera el vídeo luego con 'forgeos-fondo generar'."
fi

log "5/6 Atajos nuevos en ~/.config/i3/config (con copia de seguridad)..."
I3CONFIG="$HOME/.config/i3/config"
if [[ -f "$I3CONFIG" ]]; then
  # Solo se añade cada línea si no está ya: así se puede correr el
  # actualizador varias veces sin duplicar atajos. La copia de seguridad
  # se hace una sola vez, antes del primer cambio.
  FALTA_MENU=false
  FALTA_ATAJOS=false
  FALTA_FONDO=false
  grep -q "forgeos-menu" "$I3CONFIG" || FALTA_MENU=true
  grep -q "forgeos-atajos" "$I3CONFIG" || FALTA_ATAJOS=true
  grep -q "forgeos-fondo on" "$I3CONFIG" || FALTA_FONDO=true
  if $FALTA_MENU || $FALTA_ATAJOS || $FALTA_FONDO; then
    cp "$I3CONFIG" "$I3CONFIG.bak-$(date +%Y%m%d-%H%M%S)"
    echo "Copia de seguridad de la config de i3 hecha."
  fi
  if $FALTA_MENU; then
    {
      echo ""
      echo "# Menú ForgeOS (v2)"
      echo "bindsym \$mod+Shift+n exec forgeos-menu"
    } >> "$I3CONFIG"
    echo "Atajo del menú añadido (Alt+Shift+N)."
  else
    echo "El atajo del menú ya está en la config, lo salto."
  fi
  if $FALTA_ATAJOS; then
    {
      echo ""
      echo "# Chuleta de atajos (v2)"
      echo "bindsym \$mod+Shift+a exec forgeos-atajos"
    } >> "$I3CONFIG"
    echo "Atajo de la chuleta añadido (Alt+Shift+A)."
  else
    echo "El atajo de la chuleta ya está en la config, lo salto."
  fi
  if $FALTA_FONDO; then
    {
      echo ""
      echo "# Fondo animado al entrar (v2; si falla, queda el fondo con feh)"
      echo "exec --no-startup-id forgeos-fondo on 2>/dev/null || true"
    } >> "$I3CONFIG"
    echo "Arranque del fondo animado añadido."
  else
    echo "El arranque del fondo animado ya está en la config, lo salto."
  fi
else
  echo "Aviso: no hay ~/.config/i3/config; los atajos se añaden al instalar de nuevo con install-arch.sh."
fi

log "6/6 Prompt multicolor en ~/.bashrc..."
# Marcador: si ya está el bloque, no se añade otra vez.
if grep -q "ForgeOS prompt multicolor" "$HOME/.bashrc" 2>/dev/null; then
  echo "El prompt multicolor ya está en ~/.bashrc, lo salto."
else
  cat >> "$HOME/.bashrc" <<'BASHRC_EOF'

# ForgeOS prompt multicolor
# Usuario en verde, @ en amarillo, host en cian, ruta en azul, $ en verde.
# \[...\] es "esto es color, no texto": sin eso, bash cuenta mal el largo
# del prompt y la línea se rompe al escribir. \u = usuario, \h = equipo,
# \w = carpeta actual, \$ = $ (o # si eres root).
if [[ $- == *i* ]]; then
  PS1='\[\e[1;32m\]\u\[\e[1;33m\]@\[\e[1;36m\]\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[1;32m\]\$ \[\e[0m\]'
fi
BASHRC_EOF
  echo "Prompt multicolor añadido a ~/.bashrc."
fi

if grep -q "ForgeOS primera terminal" "$HOME/.bashrc" 2>/dev/null; then
  echo "El logo de la primera terminal ya está en ~/.bashrc, lo salto."
else
  cat >> "$HOME/.bashrc" <<'BASHRC_EOF'

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
  echo "Logo de la primera terminal añadido a ~/.bashrc."
fi

log "Recargando i3 y encendiendo el fondo animado..."
if command -v i3-msg >/dev/null 2>&1; then
  i3-msg reload 2>/dev/null || true
fi
if [[ -n "${DISPLAY:-}" ]]; then
  forgeos-fondo on 2>/dev/null || true
fi

echo
echo "Listo: D4rk-Arch v2."
echo "- Menú ForgeOS: Alt+Shift+N"
echo "- Prompt multicolor: abre una terminal nueva para verlo."
echo "- Fondo animado: se enciende al entrar; on/off desde el menú o con 'forgeos-fondo toggle'."
echo "- Si algo del fondo falla, queda el fondo estático con feh, sin romper nada."
