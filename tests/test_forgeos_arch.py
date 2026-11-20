#!/usr/bin/env python3
# Pruebas de ForgeOS para Arch.
# Comprueban que los archivos existen, que los scripts pasan bash -n,
# que la config de i3 pone el fondo con feh y no menciona apt, y que los scripts
# son ejecutables. También comprueban la v2: menú en rofi, prompt multicolor,
# fondo animado y actualizador idempotente. No instalan nada ni tocan el sistema.
# Uso: python3 tests/test_forgeos_arch.py
import os
import subprocess
import sys

# La raíz del proyecto es la carpeta padre de tests/.
RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PASADAS = 0
FALLADAS = []


def comprobar(nombre, condicion, detalle=""):
    # comprobar(): una prueba pequeña. Si condicion es verdad, suma una
    # pasada; si no, guarda el fallo para contarlo al final.
    global PASADAS
    if condicion:
        PASADAS += 1
        print(f"[OK] {nombre}")
    else:
        FALLADAS.append(nombre)
        print(f"[FALLO] {nombre} {detalle}")


def leer(ruta):
    with open(ruta, encoding="utf-8") as f:
        return f.read()


def main():
    # 1. Archivos que tienen que existir.
    esperados = [
        "install-arch.sh",
        "update-d4rk-arch.sh",
        "README.md",
        "LICENSE",
        "config/i3/config",
        "config/i3status/config",
        "config/alacritty/alacritty.toml",
        "config/rofi/config.rasi",
        "config/picom/picom.conf",
        "config/forgeos/logo.txt",
        "scripts/forgeos-monitor",
        "scripts/forgeos-pantallas",
        "scripts/forgeos-quad",
        "scripts/forgeos-sysinfo",
        "scripts/forgeos-bienvenida",
        "scripts/forgeos-menu",
        "scripts/forgeos-fondo",
        "scripts/forgeos-atajos",
    ]
    for ruta in esperados:
        comprobar(f"existe {ruta}", os.path.isfile(os.path.join(RAIZ, ruta)))

    # 2. Los scripts de bash pasan la comprobación de sintaxis (bash -n).
    for ruta in ["install-arch.sh", "update-d4rk-arch.sh",
                 "scripts/forgeos-monitor",
                 "scripts/forgeos-pantallas", "scripts/forgeos-quad",
                 "scripts/forgeos-sysinfo", "scripts/forgeos-bienvenida",
                 "scripts/forgeos-menu", "scripts/forgeos-fondo",
                 "scripts/forgeos-atajos"]:
        completo = os.path.join(RAIZ, ruta)
        resultado = subprocess.run(["bash", "-n", completo],
                                   capture_output=True, text=True)
        comprobar(f"bash -n {ruta}",
                  resultado.returncode == 0, resultado.stderr.strip())

    # 3. Los scripts son ejecutables.
    for ruta in ["install-arch.sh", "update-d4rk-arch.sh",
                 "scripts/forgeos-monitor",
                 "scripts/forgeos-pantallas", "scripts/forgeos-quad",
                 "scripts/forgeos-sysinfo", "scripts/forgeos-bienvenida",
                 "scripts/forgeos-menu", "scripts/forgeos-fondo",
                 "scripts/forgeos-atajos"]:
        completo = os.path.join(RAIZ, ruta)
        comprobar(f"ejecutable {ruta}", os.access(completo, os.X_OK))

    # 4. La config de i3 pone el fondo con feh (nitrogen y neofetch ya no
    # están en los repos oficiales de Arch) y Mod = Alt.
    config_i3 = leer(os.path.join(RAIZ, "config/i3/config"))
    comprobar("config i3 pone el fondo con feh --bg-fill",
              "feh --bg-fill" in config_i3)
    comprobar("config i3 no usa nitrogen",
              "nitrogen" not in config_i3)
    comprobar("config i3 Mod = Alt (Mod1)", "set $mod Mod1" in config_i3)
    comprobar("config i3 tiene el monitor en el espacio 1",
              "forgeos-monitor" in config_i3)
    comprobar("config i3 tiene dos pantallas",
              "forgeos-pantallas" in config_i3)
    comprobar("config i3 abre la bienvenida al entrar",
              "forgeos-bienvenida" in config_i3)
    comprobar("config i3 tiene atajo Alt+Shift+B para la bienvenida",
              "forgeos-bienvenida" in config_i3
              and "$mod+Shift+b" in config_i3)
    comprobar("config i3 tiene atajo Alt+Shift+P para captura completa",
              "$mod+Shift+p" in config_i3
              and "flameshot full" in config_i3)
    comprobar("config i3 tiene atajo Alt+O para datos del sistema",
              "$mod+o" in config_i3 and "forgeos-sysinfo" in config_i3)
    comprobar("config i3 pone el fondo con feh (tu foto)",
              "feh --bg-fill ~/Imágenes/tu-foto.png" in config_i3)
    comprobar("config i3 tema verde hacker (#00ff41)",
              "#00ff41" in config_i3)
    comprobar("config i3 fondo negro",
              "#000000" in config_i3)

    # 5. Nada de Debian en el instalador ni en la config: ni apt ni dpkg.
    instalador = leer(os.path.join(RAIZ, "install-arch.sh"))
    comprobar("install-arch.sh usa pacman, no apt",
              "pacman" in instalador and "apt-get" not in instalador
              and "apt " not in instalador)
    comprobar("install-arch.sh no menciona dpkg",
              "dpkg" not in instalador)
    comprobar("config i3 no menciona apt como comando",
              "apt-get" not in config_i3.lower()
              and " apt " not in config_i3.lower()
              and "apt\n" not in config_i3.lower())

    # 6. El instalador instala los paquetes clave de Arch (nombres
    # verificados en archlinux.org/packages).
    for paquete in ["i3-wm", "i3status", "i3lock", "rofi", "picom",
                    "feh", "alacritty", "btop", "htop",
                    "fastfetch", "xorg-xrandr", "networkmanager",
                    "network-manager-applet", "flameshot", "blueman",
                    "pavucontrol", "pipewire", "pipewire-pulse",
                    "wireplumber", "git", "base-devel",
                    "xorg-server", "lightdm", "mpv", "ffmpeg"]:
        comprobar(f"install-arch.sh instala {paquete}",
                  paquete in instalador)

    # 7. El instalador tiene --dry-run y respaldo de la config de i3.
    comprobar("install-arch.sh acepta --dry-run",
              "--dry-run" in instalador and "DRY_RUN" in instalador)
    comprobar("install-arch.sh respalda la config de i3",
              "config.bak-" in instalador)

    # 8. El README explica que Kali no se convierte en Arch.
    readme = leer(os.path.join(RAIZ, "README.md"))
    comprobar("README avisa que hay que respaldar Kali",
              "Respalda" in readme or "respalda" in readme)
    comprobar("README dice que Arch se instala desde su ISO",
              "archinstall" in readme)
    comprobar("README menciona BlackArch como opcional",
              "BlackArch" in readme)

    # 9. Tema verde hacker en Alacritty, rofi, i3status y picom.
    alacritty = leer(os.path.join(RAIZ, "config/alacritty/alacritty.toml"))
    comprobar("alacritty fondo negro y letras #00ff41",
              '"#000000"' in alacritty and '"#00ff41"' in alacritty)
    comprobar("alacritty opacity 0.80 (translúcida)",
              "opacity = 0.80" in alacritty)
    rofi = leer(os.path.join(RAIZ, "config/rofi/config.rasi"))
    comprobar("rofi tema verde hacker",
              "#00ff41" in rofi and "#000000" in rofi)
    # El parser de rofi NO acepta el atajo CSS "border: 2px solid @color":
    # el ancho va en "border:" y el color en "border-color:" por separado.
    # (En la laptop de Luis esto tumbaba rofi y con él Alt+D y Alt+Shift+N.)
    comprobar("rofi sin border CSS con referencia (@color)",
              "solid @" not in rofi)
    comprobar("rofi color de borde en border-color",
              "border-color: @selected;" in rofi)
    i3status = leer(os.path.join(RAIZ, "config/i3status/config"))
    comprobar("i3status color bueno #00ff41",
              '#00ff41' in i3status)
    picom = leer(os.path.join(RAIZ, "config/picom/picom.conf"))
    comprobar("picom deja ver la transparencia (active-opacity < 1)",
              "active-opacity = 0.85" in picom)

    # 10. El instalador copia el script de bienvenida.
    comprobar("install-arch.sh copia forgeos-bienvenida",
              "forgeos-bienvenida" in instalador)

    # 11. La licencia es la exclusiva de Luis.
    licencia = leer(os.path.join(RAIZ, "LICENSE"))
    comprobar("LICENSE a nombre de Luis Antonio Angel Alencastro",
              "Luis Antonio Angel Alencastro" in licencia)
    comprobar("LICENSE dice Arch Linux, no Debian",
              "Arch Linux" in licencia and "Debian" not in licencia)

    # 12. Paso 7/7 de seguridad: paquetes, cortafuegos, sysctl, Tor
    # y BlackArch opt-in para metasploit/armitage.
    for paquete in ["ufw", "fail2ban", "lynis", "arch-audit", "clamav",
                    "rkhunter", "tcpdump", "wireshark-qt", "zenmap",
                    "hydra", "john", "hashcat", "aircrack-ng",
                    "tor", "torsocks", "torbrowser-launcher",
                    "obfs4proxy"]:
        comprobar(f"install-arch.sh instala {paquete} (paso 7/7)",
                  paquete in instalador)
    comprobar("install-arch.sh tiene paso 7/7 de seguridad",
              "7/7 Seguridad" in instalador)
    comprobar("install-arch.sh acepta --no-seguridad",
              "--no-seguridad" in instalador and "NO_SEGURIDAD" in instalador)
    comprobar("install-arch.sh acepta --con-blackarch",
              "--con-blackarch" in instalador and "CON_BLACKARCH" in instalador)
    comprobar("install-arch.sh instala metasploit solo con BlackArch",
              "metasploit" in instalador and "strap.sh" in instalador)
    comprobar("install-arch.sh instala armitage solo con BlackArch",
              "armitage" in instalador and "CON_BLACKARCH" in instalador)
    comprobar("install-arch.sh no añade BlackArch por defecto",
              "BlackArch NO añadido" in instalador)
    comprobar("install-arch.sh configura ufw deny incoming",
              "ufw default deny incoming" in instalador)
    comprobar("install-arch.sh escribe sysctl de endurecimiento",
              "99-forgeos-seguridad.conf" in instalador
              and "tcp_syncookies" in instalador)
    comprobar("install-arch.sh activa tor.service",
              "tor.service" in instalador)
    comprobar("README menciona Tor Browser",
              "Tor Browser" in readme)
    comprobar("README menciona metasploit y armitage",
              "metasploit" in readme and "armitage" in readme)

    # 13. Paso 6/6 clona también Server-C, el servidor de laboratorio.
    comprobar("install-arch.sh clona Server-C en el paso 6/6",
              "Server-C" in instalador
              and "github.com/Am0nD4rkM4/Server-C.git" in instalador)
    comprobar("install-arch.sh no clona Server-C dos veces si ya existe",
              "Server-C ya existe en tu home" in instalador)
    comprobar("README menciona Server-C",
              "Server-C" in readme)

    # 14. v2: menú ForgeOS en rofi con sus entradas en español.
    menu = leer(os.path.join(RAIZ, "scripts/forgeos-menu"))
    for entrada in ["Terminal", "Firefox", "Archivos", "InfoForge",
                    "Server-C", "Metasploit", "Armitage", "Wi-Fi",
                    "Bluetooth", "Volumen", "Fondo animado (on/off)",
                    "Bienvenida", "Monitor", "Bloquear", "Salir de i3"]:
        comprobar(f"menú tiene entrada '{entrada}'",
                  f'"{entrada}"' in menu)
    comprobar("menú usa rofi -dmenu",
              "rofi -dmenu" in menu)
    comprobar("menú lanza terminales con alacritty -e",
              "alacritty" in menu and "-e" in menu)
    comprobar("menú tiene Thunar para Archivos",
              "thunar" in menu)
    comprobar("menú tiene nmtui para Wi-Fi",
              "nmtui" in menu)
    comprobar("menú tiene i3lock para Bloquear",
              "i3lock" in menu)
    comprobar("menú llama a forgeos-fondo toggle",
              "forgeos-fondo toggle" in menu)
    comprobar("config i3 tiene atajo Alt+Shift+N para el menú",
              "forgeos-menu" in config_i3 and "$mod+Shift+n" in config_i3)
    comprobar("README documenta el menú (Alt+Shift+N)",
              "Alt+Shift+N" in readme and "Menú ForgeOS" in readme)

    # 15. v2: prompt multicolor en bash (usuario verde, @ amarillo,
    # host cian, ruta azul, $ verde) con marcador idempotente.
    comprobar("install-arch.sh añade el prompt multicolor a .bashrc",
              "ForgeOS prompt multicolor" in instalador
              and ".bashrc" in instalador)
    comprobar("prompt: usuario verde (32), @ amarillo (33)",
              "[1;32m" in instalador and "[1;33m" in instalador)
    comprobar("prompt: host cian (36), ruta azul (34)",
              "[1;36m" in instalador and "[1;34m" in instalador)
    comprobar("prompt usa \\u, \\h y \\w",
              "\\u" in instalador and "\\h" in instalador
              and "\\w" in instalador)
    comprobar("prompt solo se añade si no existe el marcador",
              'grep -q "ForgeOS prompt multicolor"' in instalador)
    actualizador = leer(os.path.join(RAIZ, "update-d4rk-arch.sh"))
    comprobar("actualizador también añade el prompt multicolor",
              "ForgeOS prompt multicolor" in actualizador)

    # 16. v2: fondo animado con mpv + xwinwrap y vídeo generado con ffmpeg.
    fondo = leer(os.path.join(RAIZ, "scripts/forgeos-fondo"))
    comprobar("forgeos-fondo usa xwinwrap y mpv",
              "xwinwrap" in fondo and "mpv" in fondo)
    comprobar("forgeos-fondo genera el vídeo con ffmpeg (gradients)",
              "ffmpeg" in fondo and "gradients" in fondo)
    comprobar("forgeos-fondo apaga solo su instancia (pkill -f del vídeo)",
              'pkill -f "fondo-animado.mp4"' in fondo)
    comprobar("forgeos-fondo cae a feh si falta algo",
              "fondo_estatico" in fondo and "feh --bg-fill" in fondo)
    comprobar("forgeos-fondo tiene on/off/toggle/status/generar",
              all(p in fondo for p in ["on)", "off)", "toggle)", "status)",
                                          "generar)"]))
    # El paquete xwinwrap del AUR ya no existe (su repo git viene vacío:
    # "repositorio sin contenido", makepkg dice "PKGBUILD no existe").
    # Se compila desde el fork de GitHub ujjwal96/xwinwrap con make.
    comprobar("install-arch.sh compila xwinwrap de GitHub (make)",
              "github.com/ujjwal96/xwinwrap.git" in instalador
              and "make install" in instalador
              and "aur.archlinux.org/xwinwrap" not in instalador)
    comprobar("config i3 arranca el fondo animado al entrar",
              "forgeos-fondo on" in config_i3)
    comprobar("README documenta el fondo animado",
              "Fondo animado" in readme and "forgeos-fondo toggle" in readme)

    # 17. v2: actualizador idempotente, sin reinstalar todo.
    comprobar("actualizador instala solo mpv y ffmpeg",
              "mpv ffmpeg" in actualizador)
    comprobar("actualizador compila xwinwrap solo si falta",
              "command -v xwinwrap" in actualizador)
    # xwinwrap de GitHub (el del AUR ya no existe); si make falta, el
    # actualizador instala base-devel antes de compilar; y los errores
    # del clon y de make se ven, no se tragan con 2>/dev/null (en la
    # laptop de Luis la compilación falló en silencio y el fondo quedó
    # apagado sin saberse por qué).
    comprobar("actualizador compila xwinwrap de GitHub (make)",
              "github.com/ujjwal96/xwinwrap.git" in actualizador
              and "sudo make install" in actualizador
              and "aur.archlinux.org/xwinwrap" not in actualizador)
    comprobar("actualizador instala base-devel si falta make",
              "command -v make" in actualizador
              and "base-devel git" in actualizador)
    comprobar("actualizador no traga los errores de xwinwrap",
              "xwinwrap.git /tmp/forgeos-xwinwrap 2>/dev/null" not in actualizador
              and "make install) 2>/dev/null" not in actualizador)
    comprobar("actualizador genera el vídeo solo si falta",
              "forgeos-fondo generar" in actualizador)
    comprobar("actualizador añade el atajo solo si no existe",
              'grep -q "forgeos-menu"' in actualizador)
    comprobar("actualizador hace copia de seguridad de la config de i3",
              ".bak-" in actualizador and "cp \"$I3CONFIG\"" in actualizador)
    comprobar("actualizador recarga i3 al final",
              "i3-msg reload" in actualizador)
    comprobar("actualizador NO reinstala todo (no ejecuta install-arch.sh)",
              "bash install-arch.sh" not in actualizador
              and "sudo bash install-arch.sh" not in actualizador)
    comprobar("README documenta el actualizador",
              "update-d4rk-arch.sh" in readme and "git pull" in readme)

    # 18. v2: sorpresas extra discretas y que no vuelvan nitrogen/neofetch.
    atajos = leer(os.path.join(RAIZ, "scripts/forgeos-atajos"))
    comprobar("chuleta de atajos usa rofi -dmenu",
              "rofi -dmenu" in atajos)
    comprobar("chuleta de atajos lista el menú y la bienvenida",
              "Alt+Shift+N" in atajos and "Alt+Shift+B" in atajos)
    comprobar("config i3 tiene atajo Alt+Shift+A para la chuleta",
              "forgeos-atajos" in config_i3 and "$mod+Shift+a" in config_i3)
    logo = leer(os.path.join(RAIZ, "config/forgeos/logo.txt"))
    comprobar("logo FORGEOS existe (banner ASCII)",
              "|  ____/ _" in logo and "|_|" in logo)
    comprobar("primera terminal: logo + fastfetch solo una vez por arranque",
              "ForgeOS primera terminal" in instalador
              and "forgeos-fastfetch-mostrado" in instalador
              and "fastfetch --logo none" in instalador)
    for ruta in ["scripts/forgeos-menu", "scripts/forgeos-fondo",
                 "scripts/forgeos-atajos", "update-d4rk-arch.sh"]:
        texto = leer(os.path.join(RAIZ, ruta))
        comprobar(f"{ruta} no trae de vuelta nitrogen ni neofetch",
                  "nitrogen" not in texto and "neofetch" not in texto)

    # Resumen final.
    print(f"\n{PASADAS} pasadas, {len(FALLADAS)} falladas")
    if FALLADAS:
        print("Falladas:")
        for nombre in FALLADAS:
            print(f"  - {nombre}")
        return 1
    print("Todo bien.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
