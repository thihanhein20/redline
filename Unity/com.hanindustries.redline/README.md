# Redline for Unity

Adds a **Redline** menu to the Unity Editor on macOS:

- **Build and Run with Redline**: makes a macOS development build in `Builds/Redline/` and runs it through Redline, with exact, uncapped FPS and a CSV log of every run.
- **Run Last Build with Redline**: runs the last build again without rebuilding.
- **Open Logs Folder**: one CSV per run in `Builds/Redline/Logs/`, plus a `.txt` with the game's output and a session summary (average FPS, 1% low, stutters, max temperature…).

Compare two runs in Terminal: `redline compare Builds/Redline/Logs/run1.csv Builds/Redline/Logs/run2.csv`

Requires [Redline](https://github.com/thihanhein20/redline/releases) in your Applications folder.

## Install

In Unity: **Window → Package Manager → + → Add package from git URL…**

```
https://github.com/thihanhein20/redline.git?path=/Unity/com.hanindustries.redline
```
