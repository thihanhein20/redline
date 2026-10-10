# Contributing to Redline

Thanks for helping out! Bug reports, ideas and pull requests are all welcome.

## Reporting bugs and ideas

- **Bugs:** [open an issue](https://github.com/thihanhein20/redline/issues/new?labels=bug), or use **Report an Issue** in Redline's settings (it fills in your Mac details). Include the game, what you expected and what happened.
- **Ideas and feedback:** use the [feedback form](https://forms.gle/Gi6vb9GKv4Ars1xc8). No account needed.
- Please check existing issues first to avoid duplicates.

## Setting up

You need a Mac with Apple Silicon and **Xcode 26** (Swift 6.2).

```bash
git clone https://github.com/thihanhein20/redline.git
cd redline
swift build
swift test
swift run                 # overlay + settings
scripts/build-app.sh      # build/Redline.app
scripts/make-dmg.sh       # build/Redline-x.y.z.dmg
```

Open the project in Xcode with `open Package.swift`.

## Project layout

```
Sources/Redline/
  App/        app entry point and lifecycle
  Settings/   settings panel, settings window, global shortcut
  Overlay/    overlay window, its SwiftUI view and formatting
  Services/   one hardware source per file (CPU, GPU, memory, temperature, FPS);
              StatsMonitor polls them once per second
  Launch/     `redline run` command and game launcher
  Logging/    CSV output
  Support/    app info and web links
Sources/HIDSensors/   C wrapper for the chip temperature sensors
Sources/FrameCounter/ shared-memory frame counter (hook writes, Redline reads)
Sources/RedlineHook/  library loaded into games launched with `redline run`
Tests/RedlineTests/   unit tests
```

## Code guidelines

- **Small files, one job each.** One type per file, ideally under 100 lines.
- **Adding a stat?** Add `Services/<Name>Service.swift`, a field in `SystemStats`, and a row in `OverlayView`.
- **Never fake a reading.** Services return `nil` when a value isn't available; the overlay shows `--`.
- **Swift 6 with no warnings.** UI code and `StatsMonitor` run on the main actor.
- **Keep private or C APIs inside the C targets**, exposed to Swift as small, safe functions.
- **Test the logic.** Maths and parsing go in a `static func` with a unit test. Fixing a bug? Add a test that would have caught it.
- **No new dependencies** without discussing it in an issue first.
- **No permissions creep.** Redline needs no Screen Recording or Accessibility access; changes that would require them need discussion first.

## Pull requests

1. Fork the repo and branch off **`dev`**, e.g. `fix/fps-after-sleep` or `feature/cpu-gpu-temps`.
2. Make your change, then run `swift build && swift test`.
3. If it changes what users see, test it by hand: run Redline, open a game, and check the overlay and settings.
4. Open a pull request **into `dev`** (not `main`) with:
   - what changed and why
   - how you tested it
   - a screenshot for UI changes
5. CI runs build and tests automatically. It needs to be green before merging.

`main` holds released versions; `dev` is merged into `main` for each release.

## Commit messages

Short, imperative, describing the change: `Add GPU temperature sensor`, `Fix FPS not clearing after game exits`.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
