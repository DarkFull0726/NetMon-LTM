#!/system/bin/sh
# NetMon-LTM - Monitor de red para Android/busybox
# Autor: DarkFull0726

LOGFILE="netmon.log"
HOSTS="8.8.8.8 1.1.1.1 google.com"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

show_interfaces() {
    echo "=== Interfaces de red ==="
    for iface in /sys/class/net/*; do
        name=$(basename "$iface")
        state=$(cat "$iface/operstate" 2>/dev/null || echo "unknown")
        echo "  $name: $state"
    done
    echo ""
}

do_ping() {
    echo "=== Ping a hosts ==="
    for h in $HOSTS; do
        printf "  %-20s" "$h"
        if ping -c 1 -W 2 "$h" >/dev/null 2>&1; then
            echo "OK"
        else
            echo "FAIL"
        fi
    done
    echo ""
}

check_port() {
    echo "=== Puerto TCP (ej: 22, 80, 443) ==="
    printf "Host: "; read -r phost
    printf "Puerto: "; read -r pport
    if [ -z "$phost" ] || [ -z "$pport" ]; then
        echo "Faltan datos."
        return
    fi
    printf "  Probando %s:%s ... " "$phost" "$pport"
    if busybox timeout 3 busybox nc "$phost" "$pport" </dev/null >/dev/null 2>&1; then
        echo "ABIERTO"
        log_msg "Puerto $phost:$pport ABIERTO"
    else
        echo "CERRADO / SIN RESPUESTA"
        log_msg "Puerto $phost:$pport cerrado"
    fi
    echo ""
}

menu() {
    while true; do
        echo "========== NetMon-LTM =========="
        echo "1) Ver interfaces"
        echo "2) Ping rápido"
        echo "3) Chequear puerto TCP"
        echo "4) Ver log"
        echo "5) Limpiar log"
        echo "0) Salir"
        echo "================================"
        printf "Opción: "
        read -r opt
        case "$opt" in
            1) show_interfaces ;;
            2) do_ping ;;
            3) check_port ;;
            4) cat "$LOGFILE" 2>/dev/null || echo "Sin log aún." ;;
            5) > "$LOGFILE"; echo "Log limpiado." ;;
            0) echo "Adiós."; break ;;
            *) echo "Opción inválida." ;;
        esac
        echo ""
    done
}

cd "$(dirname "$0")" || exit 1
[ -f "$LOGFILE" ] || touch "$LOGFILE"
menu