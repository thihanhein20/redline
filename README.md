<p align="center">
  <img src="Resources/AppIcon.png" width="128" alt="Redline icon">
</p>

<h1 align="center">Redline</h1>

<p align="center">
  A free, open-source performance overlay for Apple Silicon Macs.<br>
  See FPS, CPU, GPU, RAM and temperature on top of any game.
</p>

---

## Features

- **FPS for any Metal game**: App Store, Steam, iPhone/iPad games on Mac, and your own builds
- **CPU, GPU, RAM, chip temperature** and macOS thermal state, updated every second
- **Overlay in any corner**: transparent, click-through, stays on top of full-screen games
- **No permissions needed**: no Screen Recording, no Accessibility
- **Menu bar app**: no Dock icon, open settings anywhere with **⌃⌥R**
- **Developer mode**: exact, uncapped FPS and CSV logs for your own Unity/Metal builds

## Requirements

- Mac with Apple Silicon (M1 or newer)
- macOS 14 Sonoma or newer
- An administrator account (needed to read FPS; other stats work on any account)

## Install

1. Download the latest `Redline-x.y.z.dmg` from [Releases](https://github.com/thihanhein20/redline/releases).
2. Open the DMG and drag **Redline** onto **Applications**.
3. Open Redline. macOS will show:

   > *"Redline" Not Opened. Apple could not verify "Redline" is free of malware…*

   This happens because Redline isn't signed with a paid Apple Developer ID. The source code is all here if you want to check it. Click **Done** (not *Move to Trash*).
4. Open **System Settings → Privacy & Security**, scroll down to *"Redline" was blocked…* and click **Open Anyway**. Enter your password.

You only need to do this once.

<details>
<summary>Prefer Terminal?</summary>

After step 2, this removes the "downloaded from the internet" flag so macOS opens it directly:

```bash
xattr -dr com.apple.quarantine /Applications/Redline.app
```
</details>

## How to use

1. **Open Redline first**, then open your game. Games that were already running need a restart.
2. The overlay appears in the top-left corner and shows FPS a few seconds after the game starts.
3. Press **⌃⌥R** (Control + Option + R) or click the gauge icon in the menu bar to:
   - show or hide the overlay
   - move it to another corner
   - send feedback or report an issue
   - quit Redline

Redline gets FPS from Apple's built-in Metal Performance HUD, running hidden in the background, so nothing extra is drawn in your game. It's switched off again when you quit Redline.

> **Can't see the menu bar icon?** On MacBooks with a notch, a crowded menu bar can hide it behind the notch. Use **⌃⌥R** instead, or hold **⌘** and drag other menu bar icons to make room.

## For developers: exact FPS and CSV logs

Testing your own Unity or Metal build? Run it through Redline to count every frame directly, with no screen refresh cap, and log the stats to a CSV file.

### Terminal (preview)

> **Preview:** the Terminal command is new and still being tested. Please [report anything that doesn't work](https://github.com/thihanhein20/redline/issues/new?labels=bug).

1. In Redline's settings (**⌃⌥R**), click **Install Terminal Command** and enter your Mac password.
2. From your project folder:

```bash
redline run ./Builds/MyGame.app > run.csv
```

- Logs one CSV row per second: `timestamp, fps, cpu_pct, gpu_pct, ram_gb, soc_temp_c, thermal_state`
- Arguments after the app path go to the game, for example `-screen-fullscreen 0`
- Redline quits when the game exits

### Unity Editor

Install the Redline package: **Window → Package Manager → + → Add package from git URL…**

```
https://github.com/thihanhein20/redline.git?path=/Unity/com.hanindustries.redline
```

Then use the new **Redline** menu:

- **Build and Run with Redline**: makes a macOS development build in `Builds/Redline/` and runs it through Redline
- **Run Last Build with Redline**: runs it again without rebuilding
- **Open Logs Folder**: one CSV per run in `Builds/Redline/Logs/`

> Works only for builds **without** Hardened Runtime (Unity development builds are fine). Steam/App Store games and iPhone/iPad apps can't be launched this way; open them normally instead.

## How it works

| Stat | Source |
|---|---|
| FPS (any game) | Apple's Metal Performance HUD, which Redline turns on (hidden) while running and reads from the system log |
| FPS (`redline run`) | a small library loaded into your game that counts each frame it draws |
| CPU | per-core CPU time from the macOS kernel |
| GPU | GPU driver utilisation statistics |
| RAM | same formula as Activity Monitor's "Memory Used" |
| Temperature | hottest chip die sensor (the same sensors the open-source Stats app reads) |

Redline makes no network requests and collects no data.

## Build from source

Needs Xcode 26 (Swift 6.2).

```bash
git clone https://github.com/thihanhein20/redline.git
cd redline
swift build && swift test
scripts/build-app.sh     # → build/Redline.app
scripts/make-dmg.sh      # → build/Redline-x.y.z.dmg
```

## Known limitations

- Temperature is the hottest chip sensor; separate CPU and GPU temperatures are planned.
- Some games capture the whole keyboard, so **⌃⌥R** may not work inside them. Use the menu bar icon instead.

## Feedback

- **Ideas or feedback:** use **Send Feedback** in Redline's settings, or fill in the [feedback form](https://forms.gle/Gi6vb9GKv4Ars1xc8). No account needed.
- **Bugs:** use **Report an Issue** in Redline's settings, or [open an issue](https://github.com/thihanhein20/redline/issues) on GitHub. Your Mac details are filled in for you.

## Contributing

Pull requests are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, code guidelines and how to open a PR.

## License

Redline is open source under the [MIT License](LICENSE).

---

<p align="center">Developed by <a href="https://www.hanindustries.net/">Han Industries</a></p>
