# Verse Bar

> **Landing page:** [alvinindra.github.io/verse-bar](https://alvinindra.github.io/verse-bar/) · **Download:** [latest release](https://github.com/alvinindra/verse-bar/releases/latest)

A macOS menu bar app that displays **synced lyrics** of whatever you're playing in **any browser** (Safari, Chrome, Arc, Dia, Brave, Vivaldi…) or in the YouTube Music Desktop app — in the menu bar, in a popover, on the **MacBook Pro Touch Bar**, and in a Dynamic-Island-style **Music Island** under the notch.

Powered by [LRCLIB](https://lrclib.net) for lyrics and the macOS Now Playing system (MediaRemote) for browser-agnostic playback detection.

---

## Features

- Real-time synced lyrics scroll in a glassmorphic popover
- Current lyric line in the **menu bar** (lyric on left, music icon on right)
- Current lyric line in the **MacBook Pro Touch Bar** (shown while the popover is open)
- **Music Island** — Dynamic-Island-style pill under the notch that shows the live lyric and expands on hover for track info + media controls
- **Browser-agnostic detection** via the macOS Now Playing system — works with any browser that supports the Media Session API (Safari, Chrome, Arc, Dia, Brave, Vivaldi, Edge, …) plus the YouTube Music Desktop App
- **Album art** pulled straight from the Now Playing source, rendered in the popover and the expanded Music Island
- **Romanization** for Korean, Japanese, and Chinese lyrics — Hangul / Hiragana / Katakana / Han characters are transliterated to Latin (pinyin with tones) and shown under the original line, in the menu bar, and on the Touch Bar
- **Guided first-run setup** — a built-in window walks you through install location, Automation, and Notification permissions
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

### Bypassing the "Verse Bar was blocked" warning

The app is ad-hoc signed but **not notarized** (notarization requires a paid Apple Developer account), so on first launch macOS Gatekeeper shows:

> *"Verse Bar" was blocked to protect your Mac.*
> *Apple could not verify "Verse Bar" is free of malware…*

Pick whichever bypass you prefer — both are safe and give the same result:

**Option A — terminal one-liner (recommended, works everywhere):**

```bash
xattr -dr com.apple.quarantine "/Applications/Verse Bar.app"
```

That removes the download-quarantine attribute so macOS stops warning. Double-click the app afterwards and it opens normally.

**Option B — System Settings (GUI):**

1. Try to open the app once and dismiss the warning.
2. Open **System Settings → Privacy & Security**.
3. Scroll to the security section and click **Open Anyway** next to *"Verse Bar" was blocked…*.
4. Confirm with your password.

After either option, every future launch is silent — you only do this once.

## Build from source

```bash
git clone https://github.com/alvinindra/verse-bar.git
cd verse-bar
./build.sh
open "Verse Bar.app"
```

The script invokes `swiftc` directly — no Xcode project needed.

## First-Run Setup

The app opens a **guided setup window** the first time you launch it. It walks you through three checks:

1. **Install location** — confirms the app is running from `/Applications` (move it there first if not, so macOS doesn't reset permissions on each launch).
2. **Automation** — one tap per browser (Safari / Chrome / Arc) fires the macOS Automation consent prompt. If you accidentally denied it, the window deep-links you to **System Settings → Privacy & Security → Automation**.
3. **Notifications (optional)** — banner when the track changes.

Then play a track on `music.youtube.com` in a supported browser; the lyric appears in the menu bar within ~1.5 s.

You can re-open the guide any time from **Preferences → Re-run Setup Guide**.

If you're using the YouTube Music Desktop App, enable its **Remote Control / Companion Server** on port `9863`. No AppleScript permission is needed in that case.

### Touch Bar

Click the menu bar icon to open the popover. While the popover is open, the Touch Bar shows the current lyric on the left and tappable Previous / Play-Pause / Next buttons on the right.

**Keep the Touch Bar lyric visible across app switches** — click the pin icon in the popover header. When pinned, the popover stays open even when you switch apps, so the Touch Bar lyric (and controls) remain visible. Unpin to return to the default transient behavior.

### Music Island (Dynamic-Island-style overlay)

A floating black pill that docks under the notch (or top-center on non-notch Macs) and shows the current synced lyric line. Hover the pill to expand it — it grows to reveal the track title / artist and tappable previous / play-pause / next controls.

The Music Island is off by default. Enable it under **Preferences → Menu Bar Render Options → Show Music Island**. The pill auto-hides whenever nothing is playing.

> **Why not an always-visible Control Strip icon?** macOS Sequoia (15.x) silently filters third-party tray items registered with `addSystemTrayItem:` + `DFRElementSetControlStripPresenceForIdentifier` unless the binary is signed with an Apple Developer ID and notarized. This project ships ad-hoc signed (no paid Apple Developer account), so the ambient Control Strip path is not viable here. Apps that achieve persistent Touch Bar lyrics — LyricsX, BetterTouchTool, Pock — all rely on either Developer ID signing + notarization or a TouchBarServer replacement. The Pin toggle is the supported workaround inside this project's scope.

## Settings

Right-click the menu bar icon → **Preferences…** to toggle:

- Display title / artist / lyric in the menu bar
- Music Island under the notch
- **Romanize Korean / Japanese / Chinese lyrics** (Latin transliteration shown under each line)
- Per-browser AppleScript fallback (Safari, Chrome, Arc) and YTM Desktop polling
- Manual sync offset

## How It Works

- `NowPlayingService` spawns a small Apple-signed helper script under `/usr/bin/swift` that streams the system Now Playing state (title, artist, elapsed, duration, album artwork) as JSON lines. The helper signature is required because macOS 15.4+ restricts `MRMediaRemoteGetNowPlayingInfo` to Apple-signed callers.
- `PlaybackEngine` consumes that stream every 1.5 s. Browser-specific AppleScript paths exist as a fallback, but they're skipped automatically while Now Playing is live — so the app stays out of `execute javascript` calls that can stall on suspended tabs.
- `LyricsService` queries LRCLIB's `/api/get` endpoint (exact match by artist + title + duration), falling back to `/api/search` if no exact match exists. Each line is run through `CFStringTransform "Any-Latin"` to attach a Latin romanization when CJK characters are detected. Results are cached on disk with both the original and romanized text.
- A 100 ms timer interpolates the active lyric line against the polled playback position plus the user's manual offset.
- `StatusItemManager`, `NotchIslandView`, and the Touch Bar all prefer the romanized line when the toggle is on and a romanization exists; otherwise they fall back to the original text.
- `PopoverHostingController` vends an `NSTouchBar` whenever the popover is on screen; the bar shows the current lyric on the left and three media-control buttons on the right.

## Project Layout

```
Sources/
├── AppDelegate.swift
├── main.swift
├── Models/         # Track, LyricLine, AppSettings
├── Services/       # PlaybackEngine, LyricsService, NowPlayingService
├── UI/             # StatusItemManager, PopoverView, SettingsView, TouchBarController,
│                   # NotchIslandController/View, OnboardingController/View, Components/
└── Utilities/      # AppleScriptRunner, Logger, MediaKeys, PermissionHelper
Resources/
├── Info.plist
└── now_playing_helper.swift   # Apple-signed swift helper invoked by NowPlayingService
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
