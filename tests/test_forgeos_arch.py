#!/usr/bin/env python3
# Pruebas de ForgeOS para Arch.
# Comprueban que los archivos existen, que los scripts pasan bash -n,
# que la config de i3 usa nitrogen y no menciona apt, y que los scripts
# son ejecutables. No instalan nada ni tocan el sistema.
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
        "README.md",
        "LICENSE",
        "config/i3/config",
        "config/i3status/config",
        "config/alacritty/alacritty.toml",
        "config/rofi/config.rasi",
        "config/picom/picom.conf",
        "scripts/forgeos-monitor",
        "scripts/forgeos-pantallas",
        "scripts/forgeos-quad",
        "scripts/forgeos-sysinfo",
        "scripts/forgeos-bienvenida",
    ]
    for ruta in esperados:
        comprobar(f"existe {ruta}", os.path.isfile(os.path.join(RAIZ, ruta)))

    # 2. Los scripts de bash pasan la comprobación de sintaxis (bash -n).
    for ruta in ["install-arch.sh", "scripts/forgeos-monitor",
                 "scripts/forgeos-pantallas", "scripts/forgeos-quad",
                 "scripts/forgeos-sysinfo", "scripts/forgeos-bienvenida"]:
        completo = os.path.join(RAIZ, ruta)
        resultado = subprocess.run(["bash", "-n", completo],
                                   capture_output=True, text=True)
        comprobar(f"bash -n {ruta}",
                  resultado.returncode == 0, resultado.stderr.strip())

    # 3. Los scripts son ejecutables.
    for ruta in ["install-arch.sh", "scripts/forgeos-monitor",
                 "scripts/forgeos-pantallas", "scripts/forgeos-quad",
                 "scripts/forgeos-sysinfo", "scripts/forgeos-bienvenida"]:
        completo = os.path.join(RAIZ, ruta)
        comprobar(f"ejecutable {ruta}", os.access(completo, os.X_OK))

    # 4. La config de i3 usa nitrogen (en Arch sí existe) y Mod = Alt.
    config_i3 = leer(os.path.join(RAIZ, "config/i3/config"))
    comprobar("config i3 usa nitrogen --restore",
              "nitrogen --restore" in config_i3)
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
    comprobar("config i3 tiene la alternativa feh comentada",
              "feh --bg-fill" in config_i3)
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
                    "feh", "nitrogen", "alacritty", "btop", "htop",
                    "neofetch", "xorg-xrandr", "networkmanager",
                    "network-manager-applet", "flameshot", "blueman",
                    "pavucontrol", "pipewire", "pipewire-pulse",
                    "wireplumber", "git", "base-devel",
                    "xorg-server", "lightdm"]:
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
