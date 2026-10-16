# 👁️ Eye Break

A tiny native macOS menu-bar app that reminds you to look away from your screen
every 20 minutes — following the **20-20-20 rule** (every 20 minutes, look at
something 20 feet away for 20 seconds) to reduce eye strain and dry eye from
prolonged computer use.

No browser, no Electron, no dependencies. Just a ~200 KB Swift binary that lives
in your menu bar and runs in the background.

---

## Features

- 🕐 **Menu-bar countdown** — a live eye icon with a monospaced countdown to the
  next break (shows the eye + seconds remaining).
- ⏰ **20-20-20 reminders** — a break fires every 20 minutes by default.
- 🔔 **Time-sensitive notification** — uses macOS's *time-sensitive* interruption
  level with a sound so it cuts through Focus/notification settings.
- 🌑 **Full-screen overlay** — dims the screen and counts down the full 20-second
  break with a big "Look away 👀" prompt (toggleable).
- ⚙️ **Adjustable interval** — choose 10 / 15 / 20 / 30 / 45 / 60 minutes from the
  menu.
- 🎬 **Demo mode** — trigger an immediate break with `--demo` (great for showing
  what the break experience looks like).

---

## Requirements

- macOS **13.0 (Ventura)** or later
- Apple Silicon **or** Intel (the release build is a universal binary)

---

## Install (for users)

### Option 1 — DMG (easiest)

1. Download `EyeBreak-1.1.dmg` from the
   [Releases](https://github.com/ADeravi/EyeBreak/releases) page.
2. Double-click to mount it.
3. Drag **Eye Break** onto **Applications**.
4. On first launch, right-click the app → **Open** (this is the one-time
   Gatekeeper step for ad-hoc-signed apps), then allow notifications when asked.

### Option 2 — Terminal installer

```bash
bash install.sh
```

This copies the app to `/Applications`, clears the quarantine flag, and re-signs it.

---

## Build from source

```bash
# Build for the current architecture only (fast, for local testing)
./build.sh

# Build a distributable universal binary + DMG + ZIP + install.sh
./release.sh
```

Both scripts are self-contained and require only Xcode Command Line Tools
(`swiftc`, `sips`, `iconutil`, `hdiutil`).

### What `release.sh` produces

| Artifact | Description |
|---|---|
| `EyeBreak.app` | Universal app bundle (arm64 + x86_64) |
| `EyeBreak-1.1.dmg` | Drag-to-Applications disk image |
| `EyeBreak-1.1.zip` | Plain zip |
| `install.sh` | One-line installer (clears quarantine) |

---

## Usage

- Click the 👁️ menu-bar item to open the menu.
- The **interval** submenu sets how often breaks fire.
- **Full-screen break** toggles the screen-dimming overlay.
- **Quit** exits the app.

### Demo mode

```bash
./EyeBreak.app/Contents/MacOS/EyeBreak --demo
```

Triggers a break ~1 second after launch so you can see the full experience
without waiting 20 minutes.

---

## How it works

- `NSStatusItem` renders the eye icon + countdown in the menu bar.
- An `NSTimer` on `RunLoop.main` (`.common` mode) ticks every second so the
  countdown stays accurate even while menus are open.
- Notifications use `UNTimeIntervalNotificationTrigger` with
  `.timeSensitive` interruption level and a default sound.
- The overlay is a borderless `NSWindow` at the `.screenSaver` window level,
  shown on every connected display (`canJoinAllSpaces` +
  `fullScreenAuxiliary`).

---

## Project layout

```
main.swift        # App source (status item, timer, notifications, overlay)
makeicon.swift    # Generates the 1024×1024 app icon (teal→blue eye.fill)
build.sh          # Single-architecture build + icon + bundle + codesign
release.sh        # Universal build + DMG + ZIP + install.sh
```

---

## License

[MIT](LICENSE)
