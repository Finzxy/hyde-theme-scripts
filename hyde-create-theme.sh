#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║         HyDE Create + Apply Custom Theme             ║
# ║   Bikin theme baru yang proper di theme switcher     ║
# ║   Usage:                                             ║
# ║     ./hyde-create-theme.sh "Nama" wall.jpg           ║
# ║     ./hyde-create-theme.sh "Nama"      (tanpa wall)  ║
# ║     ./hyde-create-theme.sh             (default)     ║
# ╚══════════════════════════════════════════════════════╝

set -e

# ─── KONFIGURASI ─────────────────────────────────────────
THEME_NAME="${1:-My Theme}"
THEME_DIR="$HOME/.config/hyde/themes/$THEME_NAME"
WALLPAPER_ARG="${2:-}"   # opsional: path wallpaper

WAL_CACHE="$HOME/.cache/wal"
WAL_COLORS="$WAL_CACHE/colors"

RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RESET='\033[0m'

log_info()  { echo -e "${CYAN}[INFO]${RESET}  $1"; }
log_ok()    { echo -e "${GREEN}[OK]${RESET}    $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${RESET}  $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; exit 1; }

# ─── HELPER ──────────────────────────────────────────────
hex_to_hypr_gradient() {
    # Bikin gradient dari 1 warna: warna asli → sedikit lebih terang
    local hex="${1#\#}"
    echo "rgba(${hex}ff)"
}

# ─── CEK DEPS ────────────────────────────────────────────
check_deps() {
    local missing=()
    command -v hyprctl &>/dev/null || missing+=("hyprctl")
    command -v swww    &>/dev/null || missing+=("swww → paru -S swww")
    [[ -n "$WALLPAPER_ARG" ]] && \
        command -v wal &>/dev/null || missing+=("wal → paru -S python-pywal")

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}[ERROR]${RESET} Dependensi tidak ditemukan:"
        for m in "${missing[@]}"; do echo -e "  • $m"; done
        exit 1
    fi
}

# ─── 1. BUAT STRUKTUR FOLDER THEME ───────────────────────
create_theme_structure() {
    log_info "Bikin struktur theme '$THEME_NAME'..."

    mkdir -p "$THEME_DIR/wallpapers"
    mkdir -p "$THEME_DIR/logo"
    mkdir -p "$THEME_DIR/kvantum"

    # .sort → urutan di theme switcher (taruh di akhir)
    echo "99" > "$THEME_DIR/.sort"

    log_ok "Folder theme dibuat: $THEME_DIR"
}

# ─── 2. BUAT hypr.theme ──────────────────────────────────
create_hypr_theme() {
    log_info "Buat hypr.theme..."

    cat > "$THEME_DIR/hypr.theme" << 'EOF'
$HOME/.config/hypr/themes/theme.conf|> $HOME/.config/hypr/themes/colors.conf
#  // My Theme — Custom
$GTK_THEME=adw-gtk3-dark
$ICON_THEME=Tela-circle-dark
$COLOR_SCHEME=prefer-dark
exec = gsettings set org.gnome.desktop.interface icon-theme $ICON_THEME
exec = gsettings set org.gnome.desktop.interface gtk-theme $GTK_THEME
exec = gsettings set org.gnome.desktop.interface color-scheme $COLOR_SCHEME
general {
    gaps_in = 3
    gaps_out = 8
    border_size = 0
    col.active_border = rgba(cba6f7ff) rgba(89b4faff) 45deg
    col.inactive_border = rgba(45475acc) rgba(313244cc) 45deg
    layout = dwindle
    resize_on_border = true
}
group {
    col.border_active = rgba(cba6f7ff) rgba(89b4faff) 45deg
    col.border_inactive = rgba(45475acc) rgba(313244cc) 45deg
    col.border_locked_active = rgba(cba6f7ff) rgba(89b4faff) 45deg
    col.border_locked_inactive = rgba(45475acc) rgba(313244cc) 45deg
}
decoration {
    rounding = 10
    shadow:enabled = false
    blur {
        enabled = yes
        size = 6
        passes = 3
        new_optimizations = on
        ignore_opacity = on
        xray = false
    }
}
layerrule = blur,waybar
EOF

    log_ok "hypr.theme dibuat."
}

# ─── 3. BUAT waybar.theme (transparan) ───────────────────
create_waybar_theme() {
    log_info "Buat waybar.theme (transparan)..."

    # Accent sementara pakai warna netral dulu
    # Akan di-update otomatis pas pywal jalan
    cat > "$THEME_DIR/waybar.theme" << 'EOF'
$HOME/.config/waybar/theme.css|${scrDir}/wbarconfgen.sh

/* My Theme — Transparan, accent dari pywal */
@define-color bar-bg rgba(0, 0, 0, 0);

@define-color main-bg rgba(0, 0, 0, 0.45);
@define-color main-fg #cdd6f4;

@define-color wb-act-bg rgba(203, 166, 247, 0.75);
@define-color wb-act-fg #1e1e2e;

@define-color wb-hvr-bg rgba(137, 180, 250, 0.40);
@define-color wb-hvr-fg #cdd6f4;
EOF

    log_ok "waybar.theme dibuat (bar-bg transparan penuh)."
}

# ─── 4. BUAT kvantum theme ───────────────────────────────
create_kvantum_theme() {
    log_info "Buat kvantum config..."

    # Salin dari Catppuccin Mocha kalau ada, fallback ke minimal
    local src_kv="$HOME/.config/hyde/themes/Catppuccin Mocha/kvantum"
    if [[ -d "$src_kv" ]]; then
        cp -r "$src_kv/." "$THEME_DIR/kvantum/"
        log_ok "Kvantum disalin dari Catppuccin Mocha."
    else
        # Minimal kvantum config
        cat > "$THEME_DIR/kvantum/kvantum.theme" << 'EOF'
[%General]
theme=KvGnomeDark
EOF
        cat > "$THEME_DIR/kvantum/kvconfig.theme" << 'EOF'
[General]
theme=KvGnomeDark
EOF
        log_ok "Kvantum minimal config dibuat."
    fi
}

# ─── 5. BUAT rofi.theme ──────────────────────────────────
create_rofi_theme() {
    log_info "Buat rofi.theme..."

    # Salin dari theme yang ada kalau tersedia
    local src_rofi="$HOME/.config/hyde/themes/Catppuccin Mocha/rofi.theme"
    if [[ -f "$src_rofi" ]]; then
        cp "$src_rofi" "$THEME_DIR/rofi.theme"
        log_ok "rofi.theme disalin dari Catppuccin Mocha."
    else
        touch "$THEME_DIR/rofi.theme"
        log_warn "rofi.theme kosong, edit manual kalau perlu."
    fi
}

# ─── 6. BUAT kitty.theme ─────────────────────────────────
create_kitty_theme() {
    log_info "Buat kitty.theme..."

    local src_kitty="$HOME/.config/hyde/themes/Catppuccin Mocha/kitty.theme"
    if [[ -f "$src_kitty" ]]; then
        cp "$src_kitty" "$THEME_DIR/kitty.theme"
        log_ok "kitty.theme disalin dari Catppuccin Mocha."
    else
        touch "$THEME_DIR/kitty.theme"
        log_warn "kitty.theme kosong, edit manual kalau perlu."
    fi
}

# ─── 7. SET WALLPAPER + PYWAL ────────────────────────────
apply_wallpaper_pywal() {
    if [[ -z "$WALLPAPER_ARG" ]]; then
        log_warn "Tidak ada wallpaper diberikan, skip pywal."
        log_warn "Tambah wallpaper ke: $THEME_DIR/wallpapers/"
        log_warn "Lalu jalanin: ./hyde-create-theme.sh /path/ke/wall.jpg"
        return
    fi

    if [[ ! -f "$WALLPAPER_ARG" ]]; then
        log_error "File wallpaper tidak ditemukan: $WALLPAPER_ARG"
    fi

    # Copy wallpaper ke folder theme
    local WALL_FILENAME=$(basename "$WALLPAPER_ARG")
    cp "$WALLPAPER_ARG" "$THEME_DIR/wallpapers/$WALL_FILENAME"
    echo "$WALL_FILENAME" > "$THEME_DIR/wall.set"
    log_ok "Wallpaper disalin: $THEME_DIR/wallpapers/$WALL_FILENAME"

    # Set wallpaper via swww
    log_info "Set wallpaper..."
    if ! pgrep -x swww-daemon &>/dev/null; then
        swww-daemon & sleep 1
    fi
    swww img "$WALLPAPER_ARG" \
        --transition-type wipe \
        --transition-duration 1.5 \
        --transition-fps 60
    log_ok "Wallpaper diset."

    # Jalanin pywal
    log_info "Generate accent color via pywal..."
    wal -i "$WALLPAPER_ARG" -n -q
    [[ ! -f "$WAL_COLORS" ]] && log_error "Pywal gagal."

    local ACCENT=$(sed -n '2p' "$WAL_COLORS")   # color1
    local ACCENT_HEX="${ACCENT#\#}"
    log_ok "Accent dari pywal: $ACCENT"

    # Update waybar.theme dengan warna pywal
    cat > "$THEME_DIR/waybar.theme" << EOF
\$HOME/.config/waybar/theme.css|\${scrDir}/wbarconfgen.sh

/* My Theme — Transparan, accent dari pywal */
/* Generated from: $WALLPAPER_ARG */
@define-color bar-bg rgba(0, 0, 0, 0);

@define-color main-bg rgba(0, 0, 0, 0.45);
@define-color main-fg #cdd6f4;

@define-color wb-act-bg rgba($((16#${ACCENT_HEX:0:2})), $((16#${ACCENT_HEX:2:2})), $((16#${ACCENT_HEX:4:2})), 0.75);
@define-color wb-act-fg #1e1e2e;

@define-color wb-hvr-bg rgba($((16#${ACCENT_HEX:0:2})), $((16#${ACCENT_HEX:2:2})), $((16#${ACCENT_HEX:4:2})), 0.40);
@define-color wb-hvr-fg #cdd6f4;
EOF

    # Update hypr.theme dengan accent pywal
    sed -i "s/col.active_border = .*/col.active_border = rgba(${ACCENT_HEX}ff)/" "$THEME_DIR/hypr.theme"
    sed -i "s/col.inactive_border = .*/col.inactive_border = rgba(${ACCENT_HEX}44)/" "$THEME_DIR/hypr.theme"

    log_ok "waybar.theme + hypr.theme diupdate dengan accent $ACCENT"
}

# ─── 8. SWITCH KE THEME ──────────────────────────────────
switch_to_theme() {
    log_info "Switch ke theme '$THEME_NAME'..."

    if command -v hyde-theme &>/dev/null; then
        hyde-theme set "$THEME_NAME" && log_ok "Theme di-switch via hyde-theme." && return
    fi

    # Fallback: pakai themeswitch.sh bawaan HyDE
    local switch_script="$HOME/.local/share/bin/themeswitch.sh"
    if [[ -f "$switch_script" ]]; then
        bash "$switch_script" "$THEME_NAME" && log_ok "Theme di-switch." && return
    fi

    log_warn "Auto-switch gagal. Switch manual via Super+T lalu pilih '$THEME_NAME'."
}

# ─── MAIN ────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║    HyDE Create Custom Theme      ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════╝${RESET}"
    echo ""

    check_deps
    create_theme_structure
    create_hypr_theme
    create_waybar_theme
    create_kvantum_theme
    create_rofi_theme
    create_kitty_theme
    apply_wallpaper_pywal
    switch_to_theme

    echo ""
    echo -e "${GREEN}✔ Theme '$THEME_NAME' berhasil dibuat!${RESET}"
    echo ""
    echo -e "${YELLOW}Lokasi theme:${RESET} $THEME_DIR"
    echo -e "${YELLOW}Isi folder:${RESET}"
    ls "$THEME_DIR"
    echo ""
    echo -e "${YELLOW}Cara pakai:${RESET}"
    echo -e "  • Switch theme  : Super+T → pilih '$THEME_NAME'"
    echo -e "  • Ganti wallpaper + update accent:"
    echo -e "    ./hyde-create-theme.sh /path/ke/wallpaper.jpg"
    echo ""
}

main "$@"
