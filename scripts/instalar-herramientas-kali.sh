#!/usr/bin/env bash
# D4rk-Arch — instalar las herramientas de Kali más usadas, en Arch.
# Instala una lista curada de 94 herramientas de auditoría y pentesting
# (44 de los repos oficiales de Arch, 49 de BlackArch y 1 del AUR),
# agrupadas por categoría. NO instala todo Kali ni todo BlackArch
# (eso son decenas de GB): solo las más usadas.
# Además descarga linpeas y winpeas (scripts sueltos, no son paquetes)
# desde su GitHub oficial, a ~/herramientas/linpeas/.
#
# Uso (en tu Arch, desde el clon del repo):
#   cd ~/D4rk-Arch && sudo bash scripts/instalar-herramientas-kali.sh
# Para no confirmar nada a mano: sudo bash scripts/instalar-herramientas-kali.sh --si
#
# AVISO: tarda bastante (de 30 minutos a un par de horas según tu internet
# y tu disco) y ocupa varios GB. Burp Suite, OWASP ZAP, Ghidra y BloodHound
# son pesados (Java y Electron). Deja la laptop enchufada y no la apagues
# a la mitad. Si se corta el internet, vuelve a correr el script: es
# idempotente, lo que ya está instalado se salta solo (--needed).
#
# Metasploit y Armitage NO van aquí: ya vienen con el instalador de
# D4rk-Arch si lo corres con --con-blackarch
#   (sudo bash install-arch.sh --con-blackarch).
# Tampoco se repiten las que ya instala el paso 7/7 de seguridad
# (nmap, hydra, john, hashcat, aircrack-ng, wireshark-qt, zenmap,
# tcpdump, tor, torsocks).
#
# Solo para tu propia máquina y tu laboratorio, o un objetivo con permiso.
# Nunca contra terceros sin autorización.
set -euo pipefail

# ---------------------------------------------------------------------------
# Comprobaciones previas
# ---------------------------------------------------------------------------

# El script tiene que correrse con sudo: necesita root para pacman y para
# añadir BlackArch, pero los paquetes del AUR (yay) se instalan COMO TU
# USUARIO NORMAL, porque yay no corre como root. SUDO_USER es el usuario
# que puso el sudo (tú, am0nd4rk); si está vacío, es que se corrió como
# root directo y no se sabe a qué usuario bajarle el yay.
if [[ $EUID -ne 0 ]]; then
  echo "Corre el script con sudo: sudo bash scripts/instalar-herramientas-kali.sh"
  exit 1
fi
if [[ -z "${SUDO_USER:-}" ]]; then
  echo "Corre el script con sudo desde tu usuario, no como root directo (su)."
  echo "Así: sudo bash scripts/instalar-herramientas-kali.sh"
  exit 1
fi
if ! command -v pacman >/dev/null 2>&1; then
  echo "Esto no parece Arch Linux: no se encontró pacman."
  exit 1
fi

# La carpeta home de tu usuario (bajo sudo, $HOME es /root, así que se
# busca con getent para no guardar nada en /root por error).
HOME_USUARIO="$(getent passwd "$SUDO_USER" | cut -d: -f6)"

# --si / -y: no preguntar antes de empezar.
SIN_CONFIRMAR=false
for arg in "$@"; do
  case "$arg" in
    --si|-y|--yes) SIN_CONFIRMAR=true ;;
    --help|-h)
      echo "Uso: sudo bash scripts/instalar-herramientas-kali.sh [--si]"
      echo "  --si: no preguntar antes de empezar (para correrlo sin estar delante)."
      exit 0
      ;;
  esac
done

# Internet: sin internet no hay nada que instalar; mejor avisar ahora.
if ! curl -fsSI --max-time 10 https://archlinux.org >/dev/null 2>&1; then
  echo "No hay internet (no responde archlinux.org). Conéctate y vuelve a correr el script."
  exit 1
fi

echo "D4rk-Arch: herramientas de Kali más usadas (94 paquetes + linpeas/winpeas)."
echo "Tarda bastante y ocupa varios GB. Deja la laptop enchufada."
echo "Se instala de los repos oficiales (44), BlackArch (49) y el AUR (1)."
if ! $SIN_CONFIRMAR; then
  read -r -p "¿Seguir? [s/N] " RESPUESTA
  case "$RESPUESTA" in
    s|S|si|SI|sí|SÍ) ;;
    *) echo "Cancelado, no se instaló nada."; exit 0 ;;
  esac
fi

# ---------------------------------------------------------------------------
# Listas curadas (nombres verificados el 2026-11-22 en archlinux.org,
# la lista de paquetes de BlackArch y el RPC del AUR; prioridad:
# oficial > BlackArch > AUR, para instalar binarios y no compilar).
# ---------------------------------------------------------------------------

# Reconocimiento: buscar subdominios, hosts y servicios.
PAQ_RECON_OFICIAL=(masscan rustscan zmap)
PAQ_RECON_BLACKARCH=(theharvester dnsrecon dnsenum fierce subfinder amass
  httpx naabu sherlock holehe recon-ng spiderfoot)

# Web: escáner web, fuerza bruta de rutas, fuzzing e inyección.
PAQ_WEB_OFICIAL=(sqlmap nikto gobuster wpscan testssl.sh sslscan zaproxy)
PAQ_WEB_BLACKARCH=(ffuf dirb dirsearch feroxbuster wfuzz nuclei whatweb
  wafw00f commix xsstrike dalfox burpsuite)

# Explotación: exploits, C2 y túneles.
# (metasploit y armitage van con --con-blackarch, ver arriba.)
PAQ_EXPLOT_OFICIAL=(exploitdb routersploit)
PAQ_EXPLOT_BLACKARCH=(beef veil empire sliver chisel ligolo-ng)

# Contraseñas: fuerza bruta de logins y de hashes, y listas de palabras.
PAQ_PASS_OFICIAL=(medusa ncrack hashcat-utils)
PAQ_PASS_BLACKARCH=(crunch cewl cupp hashid)

# Red: sniffing, MITM y análisis de tráfico.
PAQ_RED_OFICIAL=(socat proxychains-ng kismet ettercap bettercap mitmproxy
  dsniff ngrep termshark)
PAQ_RED_BLACKARCH=(mitm6 responder)

# Wi-Fi: auditoría de redes inalámbricas.
# (aircrack-ng ya va en el paso 7/7.)
PAQ_WIFI_OFICIAL=(hcxtools hcxdumptool cowpatty reaver bully pixiewps
  mdk4 wifite)

# Forense: analizar discos, memoria, binarios y malware.
PAQ_FORENSE_OFICIAL=(binwalk foremost perl-image-exiftool volatility3
  sleuthkit yara ghidra radare2 gdb)
PAQ_FORENSE_BLACKARCH=(scalpel steghide)

# Active Directory y Windows: enumerar dominios, credenciales y sesiones.
# (ldapdomaindump no existe como paquete en Arch, BlackArch ni AUR.)
PAQ_AD_OFICIAL=(impacket smbclient)
PAQ_AD_BLACKARCH=(netexec bloodhound bloodhound-python certipy coercer
  enum4linux-ng smbmap evil-winrm kerbrute)

# Wordlists: listas de usuarios y contraseñas para fuerza bruta.
PAQ_WORDLISTS_BLACKARCH=(seclists)
PAQ_WORDLISTS_AUR=(rockyou)

# Miscelánea: enumeración local y secretos en repos.
PAQ_MISC_OFICIAL=(gitleaks)
PAQ_MISC_BLACKARCH=(pspy)

PAQ_OFICIAL=("${PAQ_RECON_OFICIAL[@]}" "${PAQ_WEB_OFICIAL[@]}"
  "${PAQ_EXPLOT_OFICIAL[@]}" "${PAQ_PASS_OFICIAL[@]}"
  "${PAQ_RED_OFICIAL[@]}" "${PAQ_WIFI_OFICIAL[@]}"
  "${PAQ_FORENSE_OFICIAL[@]}" "${PAQ_AD_OFICIAL[@]}"
  "${PAQ_MISC_OFICIAL[@]}")
PAQ_BLACKARCH=("${PAQ_RECON_BLACKARCH[@]}" "${PAQ_WEB_BLACKARCH[@]}"
  "${PAQ_EXPLOT_BLACKARCH[@]}" "${PAQ_PASS_BLACKARCH[@]}"
  "${PAQ_RED_BLACKARCH[@]}" "${PAQ_FORENSE_BLACKARCH[@]}"
  "${PAQ_AD_BLACKARCH[@]}" "${PAQ_WORDLISTS_BLACKARCH[@]}"
  "${PAQ_MISC_BLACKARCH[@]}")
PAQ_AUR=("${PAQ_WORDLISTS_AUR[@]}")

# Todas, para la verificación del final.
TODAS=("${PAQ_OFICIAL[@]}" "${PAQ_BLACKARCH[@]}" "${PAQ_AUR[@]}")

# BINARIO: ejecutable que hay que buscar para cada paquete cuyo comando
# no se llama igual que el paquete. "dir:/ruta" es una carpeta de datos
# (las wordlists no tienen ejecutable). Si no está en la lista, el
# ejecutable se llama igual que el paquete.
declare -A BINARIO=(
  [exploitdb]=searchsploit
  [perl-image-exiftool]=exiftool
  [impacket]=impacket-secretsdump
  [pspy]=pspy64
  [seclists]="dir:/usr/share/seclists"
  [rockyou]="dir:/usr/share/wordlists"
)

# ---------------------------------------------------------------------------
# Paso 1/7: actualizar el sistema antes de instalar nada.
# ---------------------------------------------------------------------------
echo
echo "==> 1/7 Actualizando el sistema (pacman -Syu)..."
pacman -Syu --noconfirm \
  || { echo "Aviso: falló pacman -Syu; revisa tu internet y vuelve a correr el script."; exit 1; }

# ---------------------------------------------------------------------------
# Paso 2/7: BlackArch (solo si no está ya en /etc/pacman.conf).
# ---------------------------------------------------------------------------
echo
echo "==> 2/7 Repositorio BlackArch..."
if grep -q "^\[blackarch\]" /etc/pacman.conf 2>/dev/null; then
  echo "BlackArch ya está en /etc/pacman.conf, lo salto."
else
  echo "Añadiendo BlackArch con su script oficial strap.sh de blackarch.org..."
  # strap.sh mete el repo y sus claves en pacman.conf. Se descarga a /tmp
  # y se corre ahí; si falla, el resto sigue pero sin los 49 de BlackArch.
  if (cd /tmp && curl -O https://blackarch.org/strap.sh \
      && chmod +x strap.sh && ./strap.sh); then
    echo "BlackArch añadido; sincronizando su base de datos..."
    pacman -Sy --noconfirm || echo "Aviso: no se pudo sincronizar BlackArch."
  else
    echo "Aviso: no se pudo añadir BlackArch; revisa tu internet y blackarch.org."
    echo "Los paquetes de BlackArch se saltan; el resto sigue."
    PAQ_BLACKARCH=()
  fi
fi

# ---------------------------------------------------------------------------
# Paso 3/7: yay (solo si falta), para los paquetes del AUR.
# ---------------------------------------------------------------------------
echo
echo "==> 3/7 yay (para el AUR)..."
if command -v yay >/dev/null 2>&1; then
  echo "yay ya está instalado, lo salto."
else
  echo "Instalando base-devel y git (hacen falta para compilar yay-bin)..."
  pacman -S --noconfirm --needed base-devel git \
    || echo "Aviso: no se pudo instalar base-devel/git; el AUR quedará fuera."
  # yay-bin es el yay ya compilado: makepkg solo lo instala, no compila
  # nada pesado. Se clona y se compila COMO TU USUARIO, nunca como root:
  # makepkg se niega a correr como root.
  rm -rf /tmp/forgeos-yay-bin
  if sudo -u "$SUDO_USER" git clone https://aur.archlinux.org/yay-bin.git /tmp/forgeos-yay-bin; then
    sudo -u "$SUDO_USER" bash -c 'cd /tmp/forgeos-yay-bin && makepkg -si --noconfirm' \
      || echo "Aviso: no se pudo instalar yay; el AUR quedará fuera."
  else
    echo "Aviso: no se pudo bajar yay-bin del AUR; el AUR quedará fuera."
  fi
fi

# ---------------------------------------------------------------------------
# Paso 4/7: repos oficiales de Arch (44 paquetes, binarios).
# ---------------------------------------------------------------------------
echo
echo "==> 4/7 Repos oficiales de Arch (${#PAQ_OFICIAL[@]} paquetes)..."
if [[ ${#PAQ_OFICIAL[@]} -gt 0 ]]; then
  pacman -S --noconfirm --needed "${PAQ_OFICIAL[@]}" \
    || echo "Aviso: alguno de los oficiales falló; la verificación del final dice cuál falta."
fi

# ---------------------------------------------------------------------------
# Paso 5/7: BlackArch (49 paquetes, binarios).
# ---------------------------------------------------------------------------
echo
echo "==> 5/7 BlackArch (${#PAQ_BLACKARCH[@]} paquetes)..."
if [[ ${#PAQ_BLACKARCH[@]} -gt 0 ]]; then
  pacman -S --noconfirm --needed "${PAQ_BLACKARCH[@]}" \
    || echo "Aviso: alguno de BlackArch falló; la verificación del final dice cuál falta."
else
  echo "Sin lista de BlackArch (no se pudo añadir el repo), lo salto."
fi

# ---------------------------------------------------------------------------
# Paso 6/7: AUR con yay, COMO TU USUARIO NORMAL (yay no corre como root).
# ---------------------------------------------------------------------------
echo
echo "==> 6/7 AUR (${#PAQ_AUR[@]} paquete)..."
if [[ ${#PAQ_AUR[@]} -gt 0 ]]; then
  if command -v yay >/dev/null 2>&1; then
    sudo -u "$SUDO_USER" yay -S --noconfirm --needed "${PAQ_AUR[@]}" \
      || echo "Aviso: alguno del AUR falló; la verificación del final dice cuál falta."
  else
    echo "Aviso: no hay yay, no se puede instalar el AUR."
  fi
fi

# ---------------------------------------------------------------------------
# Paso 7/7: linpeas y winpeas (scripts sueltos, no son paquetes).
# Se descargan de su GitHub oficial (PEASS-ng) a ~/herramientas/linpeas/.
# Si GitHub no responde, se avisa y se sigue: no rompen nada.
# ---------------------------------------------------------------------------
echo
echo "==> 7/7 linpeas y winpeas (descarga de GitHub, opcional)..."
DIR_LPEAS="$HOME_USUARIO/herramientas/linpeas"
sudo -u "$SUDO_USER" mkdir -p "$DIR_LPEAS"
if curl -fsSL --max-time 60 -o "$DIR_LPEAS/linpeas.sh" \
    https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh; then
  chmod +x "$DIR_LPEAS/linpeas.sh"
  echo "linpeas.sh descargado en $DIR_LPEAS/linpeas.sh"
else
  echo "Aviso: no se pudo descargar linpeas.sh de GitHub."
fi
if curl -fsSL --max-time 60 -o "$DIR_LPEAS/winPEASx64.exe" \
    https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx64.exe; then
  echo "winPEASx64.exe descargado en $DIR_LPEAS/winPEASx64.exe"
else
  echo "Aviso: no se pudo descargar winPEASx64.exe de GitHub."
fi
sudo -u "$SUDO_USER" bash -c "chown -R $SUDO_USER:$SUDO_USER \"$DIR_LPEAS\"" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Verificación final: cada herramienta con command -v, y resumen.
# ---------------------------------------------------------------------------
echo
echo "==> Verificando cada herramienta (command -v)..."

# verificar(): 0 si la herramienta quedó instalada, 1 si falta.
# Primero busca su ejecutable; si no está en el PATH, pregunta a pacman
# si el paquete está instalado (algunas herramientas se llaman distinto
# al paquete, y las wordlists son datos, no ejecutables).
verificar() {
  local paquete="$1" binario="${BINARIO[$1]:-$1}"
  if [[ "$binario" == dir:* ]]; then
    [[ -d "${binario#dir:}" ]] && return 0
    pacman -Q "$paquete" >/dev/null 2>&1
    return $?
  fi
  if command -v "$binario" >/dev/null 2>&1; then return 0; fi
  pacman -Q "$paquete" >/dev/null 2>&1
}

INSTALADAS=0
FALTANTES=()
for paquete in "${TODAS[@]}"; do
  if verificar "$paquete"; then
    INSTALADAS=$((INSTALADAS + 1))
  else
    FALTANTES+=("$paquete")
  fi
done
# linpeas/winpeas se cuentan aparte (no son paquetes).
for script in linpeas.sh winPEASx64.exe; do
  if [[ -f "$DIR_LPEAS/$script" ]]; then
    INSTALADAS=$((INSTALADAS + 1))
  else
    FALTANTES+=("$script")
  fi
done
TOTAL=$(( ${#TODAS[@]} + 2 ))

echo
echo "Resumen: $INSTALADAS/$TOTAL herramientas instaladas."
if [[ ${#FALTANTES[@]} -gt 0 ]]; then
  echo "Faltan (${#FALTANTES[@]}): ${FALTANTES[*]}"
  echo "Para reintentar solo esas, corre el script otra vez (salta lo que ya está)"
  echo "o instálalas a mano con pacman/yay."
else
  echo "Todo instalado."
fi
echo
echo "Listo. Notas:"
echo "- Metasploit y Armitage van aparte: sudo bash install-arch.sh --con-blackarch"
echo "- Las wordlists están en /usr/share/seclists y /usr/share/wordlists/rockyou.txt"
echo "- linpeas/winpeas están en ~/herramientas/linpeas/"
echo "- BloodHound (la ventana) necesita una base neo4j para funcionar."
echo "- Todo esto es solo para tu máquina y tu laboratorio, o un objetivo con permiso."
