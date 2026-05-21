# Startup Delayer Mac

A minimal macOS app that delays app launches at login. No separate launcher app needed — this app registers itself and runs headlessly at boot.

## How it works

- When launched **normally** (double-click, Spotlight, Dock) → shows the GUI to manage your app list
- When launched **at login** (via SMAppService) → runs silently with no window or dock icon, fires your delayed launches, then exits

The `--login` argument is what distinguishes the two modes. macOS passes it automatically when the app is registered as a Login Item.

## Build

```bash
xcode-select --install   # if not already done
chmod +x build.sh
./build.sh
```

## Install

```bash
cp -r "build/Startup Delayer.app" /Applications/
open /Applications/Startup\ Delayer.app
```

The app **must** be in `/Applications` for `SMAppService` (Login Item registration) to work.

## Setup

1. Open the app
2. Add the apps you want to delay (drag & drop or Add App button)
3. Set a delay in seconds for each one
4. Choose **Sequence** or **Parallel** mode (see below)
5. Toggle **Run at Login** — done

## Launch modes

**Sequence** — delays are cumulative. App A at 5s, App B at 10s means: wait 5s → launch A → wait 5s → launch B.

**Parallel** — all timers start simultaneously from boot. App A at 1s, App B at 3s means: at t+1s launch A, at t+3s launch B, independently.

## Requirements

- macOS 13 Ventura or later
- Xcode Command Line Tools (for building only)
