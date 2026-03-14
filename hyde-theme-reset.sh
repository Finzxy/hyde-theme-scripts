#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║           HyDE Theme RESET / Cleanup Script          ║
# ║   Hapus semua patch, restore ke default HyDE         ║
# ╚══════════════════════════════════════════════════════╝

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RESET='\033[0m'

log_info()  { echo -e "${CYAN}[INFO]${RESET}  $1"; }
log_ok()    { echo -e "${GREEN}[OK]${RESET}    $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${RESET}  $1"; }

WAYBAR_STYLE="$HOME/.config/waybar/style.css"
WAYBAR_USER_STYLE="$HOME/.config/waybar/user-style.css"
HYPR_CONFIG="$HOME/.config/hypr/hyprland.conf"

clean_patch() {
    local file="$1"
    local pattern_start="$2"
    local pattern_end="$3"

    if [[ ! -f "$file" ]]; then
        log_warn "File tidak ditemukan, skip: $file"
        return
    fi

    if grep -q "$pattern_start" "$file"; then
        python3 -c "
import re
with open('$file') as f: c = f.read()
c = re.sub(r'$pattern_start.*?$pattern_end', '', c, flags=re.DOTALL)
c = c.rstrip() + '\n'
with open('$file', 'w') as f: f.write(c)
"
        log_ok "Patch dihapus dari: $file"
    else
        log_info "Tidak ada patch di: $file"
    fi
}

echo ""
echo -e "${CYAN}╔══════════════════════════════════╗${RESET}"
echo -e "${CYAN}║     HyDE Theme Reset Script      ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════╝${RESET}"
echo ""

# ─── 1. BERSIHIN style.css ───────────────────────────────
log_info "Bersihin style.css..."
clean_patch "$WAYBAR_STYLE" "/\\\* hyde-theme-patch \\\*/" "/\\\* end-hyde-patch \\\*/"
# Hapus juga @import pywal yang mungkin ke-inject
if grep -q "colors-waybar.css" "$WAYBAR_STYLE"; then
    python3 -c "
with open('$WAYBAR_STYLE') as f: lines = f.readlines()
lines = [l for l in lines if 'colors-waybar.css' not in l]
with open('$WAYBAR_STYLE', 'w') as f: f.writelines(lines)
"
    log_ok "Import pywal dihapus dari style.css"
fi

# ─── 2. RESET user-style.css ─────────────────────────────
log_info "Reset user-style.css..."
if [[ -f "$WAYBAR_USER_STYLE" ]]; then
    # Kosongkan isinya, jangan dihapus biar HyDE gak error
    > "$WAYBAR_USER_STYLE"
    log_ok "user-style.css dikosongkan."
else
    log_info "user-style.css tidak ada, skip."
fi

# ─── 3. RESTORE BACKUP style.css (kalau ada) ─────────────
if [[ -f "${WAYBAR_STYLE}.bak" ]]; then
    log_info "Ketemu backup style.css, mau restore? (y/n)"
    read -r ans
    if [[ "$ans" == "y" ]]; then
        cp "${WAYBAR_STYLE}.bak" "$WAYBAR_STYLE"
        log_ok "style.css direstore dari backup."
    else
        log_info "Skip restore backup."
    fi
fi

# ─── 4. BERSIHIN hyprland.conf ───────────────────────────
log_info "Bersihin hyprland config..."
for f in \
    "$HOME/.config/hypr/hyprland.conf" \
    "$HOME/.config/hypr/themes/theme.conf" \
    "$HOME/.config/hypr/userprefs.conf"
do
    clean_patch "$f" "# hyde-theme-patch" "# end-hyde-patch"
    clean_patch "$f" "# hyde-pywal-patch" "# end-hyde-pywal-patch"
done

# Reset hyprland border & rounding ke default via hyprctl
if command -v hyprctl &>/dev/null; then
    hyprctl keyword general:border_size 1
    hyprctl keyword decoration:rounding 0
    log_ok "Hyprland border & rounding direset ke default."
fi

# ─── 5. RESTART WAYBAR ───────────────────────────────────
log_info "Restart waybar..."
pkill -x waybar 2>/dev/null || true
while pgrep -x waybar &>/dev/null; do
    pkill -9 -x waybar 2>/dev/null || true
    sleep 0.2
done

if systemctl --user is-active --quiet waybar.service 2>/dev/null; then
    systemctl --user restart waybar.service
elif command -v hyde-waybar &>/dev/null; then
    hyde-waybar &>/dev/null & disown
else
    waybar &>/dev/null & disown
fi
log_ok "Waybar direstart."

# ─── 6. RELOAD HYPRLAND ──────────────────────────────────
hyprctl reload &>/dev/null && log_ok "Hyprland direload." \
    || log_warn "hyprctl reload gagal, coba manual."

echo ""
echo -e "${GREEN}✔ Reset selesai! Semua patch dihapus.${RESET}"
echo ""
echo -e "${YELLOW}Backup tersedia di:${RESET}"
[[ -f "${WAYBAR_STYLE}.bak" ]]  && echo -e "  • ${WAYBAR_STYLE}.bak"
for f in "$HOME/.config/hypr/hyprland.conf" \
         "$HOME/.config/hypr/themes/theme.conf" \
         "$HOME/.config/hypr/userprefs.conf"; do
    [[ -f "${f}.bak" ]] && echo -e "  • ${f}.bak"
done
echo ""
