# 🎨 HyDE Theme Scripts

just some bash scripts i made for managing custom themes on HyDE (Arch + Hyprland). nothing serious, use it if you want.

supports **pywal** (auto accent from wallpaper) and **manual hex** colors.

---

## what it does

- set wallpaper via `swww` with smooth transition
- auto-generate accent colors from wallpaper using pywal
- or just use your own hex color
- waybar fully transparent with accent-colored modules
- window border off, rounding kept
- create proper HyDE themes that show up in `Super+T` switcher
- reset everything back to default

---

## requirements

```bash
paru -S swww hyprland waybar

# only if you want pywal mode
paru -S python-pywal
```

---

## scripts

| script | what it does |
|--------|-------------|
| `hyde-create-theme.sh` | create a new theme (shows in Super+T) |
| `hyde-theme.sh` | apply wallpaper + accent to current theme |
| `hyde-theme-reset.sh` | reset everything back to HyDE defaults |

---

## usage

### create a theme

```bash
# with name + wallpaper
./hyde-create-theme.sh "My Theme" ~/Pictures/wallpaper.jpg

# name only, add wallpaper later
./hyde-create-theme.sh "My Theme"
```

then hit `Super+T` and pick your theme.

### apply wallpaper + accent

```bash
# pywal auto accent
./hyde-theme.sh ~/Pictures/wallpaper.jpg

# manual hex
./hyde-theme.sh ~/Pictures/wallpaper.jpg "#89b4fa"
```

### reset to default

```bash
./hyde-theme-reset.sh
```

### delete a theme

```bash
rm -rf ~/.config/hyde/themes/'My Theme'
```

---

## notes

- waybar patches go into `user-style.css` so HyDE's own files stay untouched
- all modified configs are backed up as `.bak` before changes
- running scripts again will cleanly replace the previous patch

---

> feel free to use, break, or improve it
