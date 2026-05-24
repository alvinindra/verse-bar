# Verse Bar

> **Landing page:** [alvinindra.github.io/verse-bar](https://alvinindra.github.io/verse-bar/) · **Download:** [latest release](https://github.com/alvinindra/verse-bar/releases/latest)

A macOS menu bar app that displays **synced lyrics** of whatever you're playing on YouTube Music (Safari, Chrome, Arc, or the YouTube Music Desktop app) — in the menu bar, in a popover, and on the **MacBook Pro Touch Bar**.

Powered by [LRCLIB](https://lrclib.net) for lyrics and AppleScript for browser introspection.

---

## Features

- Real-time synced lyrics scroll in a glassmorphic popover
- Current lyric line in the **menu bar** (lyric on left, music icon on right)
- Current lyric line in the **MacBook Pro Touch Bar** (shown while the popover is open)
- Source detection across Safari, Chrome, Arc, and the YouTube Music Desktop App (port 9863)
- Local lyric cache (`~/Library/Application Support/com.versebar.VerseBar/LyricsCache`)
- Manual sync offset (+/- 0.5s) for tracks whose timing drifts
- Native track-change notifications
- Offline mode that serves cached lyrics only

## Requirements

- macOS 11.0 (Big Sur) or later
- Swift toolchain (`swiftc`) — ships with Xcode Command Line Tools
- A MacBook Pro with a Touch Bar (2016–2021) for the Touch Bar feature; the app still runs fine without one

## Install

**Easiest:** download the latest `.dmg` from the [releases page](https://github.com/alvinindra/verse-bar/releases/latest), double-click it, and drag **Verse Bar** onto the **Applications** shortcut.

The app is ad-hoc signed but not notarized, so on first launch macOS will warn "developer cannot be verified." Right-click the app in `/Applications` and choose **Open** to allow it once.

## Build from source

```bash
git clone https://github.com/alvinindra/verse-bar.git
cd verse-bar
./build.sh
open "Verse Bar.app"
```

The script invokes `swiftc` directly — no Xcode project needed.

## First-Run Setup

1. Launch `Verse Bar.app`.
2. macOS will prompt for **Automation** permission the first time the app tries to talk to your browser. Grant it:
   - **System Settings → Privacy & Security → Automation → Verse Bar** → enable Safari / Google Chrome / Arc.
3. macOS will prompt for **Notifications** permission for now-playing alerts (optional).
4. Play a track on `music.youtube.com` in a supported browser. The lyric should appear in the menu bar within ~1.5 s.

If you're using the YouTube Music Desktop App, enable its **Remote Control / Companion Server** on port `9863`. No AppleScript permission is needed in that case.

### Touch Bar

Click the menu bar icon to open the popover; while the popover is open, the lyric is shown in the app region of the Touch Bar (left side, with the music-note icon on the right via a flexible space). It uses the public `NSTouchBar` API attached to the popover's hosting controller.

> **Why not the always-visible Control Strip?** Earlier prototypes used the private `addSystemTrayItem:` + `DFRElementSetControlStripPresenceForIdentifier` SPIs. On macOS Sequoia (15.x) the OS silently ignores third-party Control Strip items even when the SPI reports success — Apple effectively closed third-party ambient Touch Bar integration. Tools that still pull this off (Pock, MTMR) replace `TouchBarServer` outright, which is outside this app's scope.

## Settings

Right-click the menu bar icon → **Preferences…** to toggle:

- Per-browser tracking (Safari, Chrome, Arc, YTM Desktop)
- Display title / artist / lyric in the menu bar
- Manual sync offset

## How It Works

- `PlaybackEngine` polls each enabled browser every 1.5 s via AppleScript, running a tiny JS snippet inside the YouTube Music tab to extract title / artist / current time / duration / paused state.
- `LyricsService` queries LRCLIB's `/api/get` endpoint (exact match by artist + title + duration), falling back to `/api/search` if no exact match exists. Results are cached on disk.
- A 100 ms timer interpolates the active lyric line against the polled playback position plus the user's manual offset.
- `StatusItemManager` renders the active lyric in the menu bar.
- `TouchBarController` registers a `NSCustomTouchBarItem` in the Touch Bar system tray via the private `addSystemTrayItem:` selector and `DFRElementSetControlStripPresenceForIdentifier` (resolved at runtime via `dlsym`).

## Project Layout

```
Sources/
├── AppDelegate.swift
├── main.swift
├── Models/         # Track, LyricLine, AppSettings
├── Services/       # PlaybackEngine, LyricsService
├── UI/             # StatusItemManager, PopoverView, SettingsView, TouchBarController, Components/
└── Utilities/      # AppleScriptRunner, Logger
Resources/Info.plist
build.sh
```

## Releases

Tagged commits on `main` (`v1.0.0`, `v1.1.0`, …) trigger the GitHub Actions workflow at `.github/workflows/release.yml`, which builds the app, zips it, and attaches the archive to a new GitHub Release.

To cut a release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Contributing

Issues and pull requests welcome. Keep PRs focused — one fix or feature per PR. Run `./build.sh` and exercise the app before requesting review.

## Credits

- Lyrics by [LRCLIB](https://lrclib.net)
- Inspired by [Lyricfier](https://github.com/emilioastarita/lyricfier) and [SpotMenu](https://github.com/kmikiy/SpotMenu)

## License

MIT — see [LICENSE](LICENSE).
