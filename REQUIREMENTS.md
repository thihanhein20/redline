# Redline (Project Canary) — Requirements

External performance monitor for Unity builds on Apple Silicon Macs.
Measures FPS and hardware stats from **outside** the game (no Unity code changes).

## 1. Goals
- Independent FPS measurement to cross-check Unity's built-in profiler.
- Live overlay while testing.
- Log runs to CSV so builds can be compared.

## 2. Functional requirements

### 2.1 Metrics
| Metric | Source | Rate |
|---|---|---|
| FPS, frame time (avg / 1% low / max) | Injected dylib hooking `CAMetalLayer` drawable present | per frame, aggregated 1 s |
| CPU usage % (total, P-cores / E-cores) | `host_processor_info` | 1 s |
| GPU usage % | IOKit `IOAccelerator` → `PerformanceStatistics` | 1 s |
| CPU / GPU temperature °C | `IOHIDEventSystemClient` (private API) | 1 s |
| RAM used / total | `host_statistics64` | 1 s |
| Thermal state | `ProcessInfo.thermalState` | on change |

### 2.2 Overlay
- Transparent, always-on-top, click-through window.
- Visible over full-screen Unity games (`.fullScreenAuxiliary`).
- Corner position selectable; global hotkey to show/hide.

### 2.3 Logging
- One CSV per run: `timestamp, fps, frametime_ms, cpu_pct, gpu_pct, cpu_temp, gpu_temp, ram_mb, thermal_state`.
- Start/stop with the game launch; file named `<game>_<datetime>.csv`.

### 2.4 Launch
- CLI: `redline run /path/MyGame.app` → launches game with dylib injected, opens overlay, starts CSV.

## 3. Non-functional requirements
- Overhead: < 1% CPU, no measurable FPS impact.
- Readings accurate within ±1 FPS vs. Metal HUD.
- No admin/sudo needed.

## 4. Environment (checked on this Mac, 2026-10-10)
| Item | Required | This Mac | OK |
|---|---|---|---|
| Chip | Apple Silicon | Apple M2 | ✅ |
| macOS | 14+ | 26.5.2 | ✅ |
| Xcode | 15+ | 26.2 | ✅ |
| Swift | 5.9+ | 6.2.3 | ✅ |
| Unity | any Metal build | 6000.5.4f1, 6000.6.3f1 | ✅ |
| SIP | can stay enabled | enabled | ✅ |

## 5. Constraints
- Game build must **not** use Hardened Runtime (or must have
  `com.apple.security.cs.allow-dyld-environment-variables`), else `DYLD_INSERT_LIBRARIES` is ignored.
  Unity development builds are fine by default.
- Temperature uses a private API → no Mac App Store; distribute as direct download.
- Only works on games we launch ourselves (no attaching to arbitrary apps).

## 6. Out of scope (v1)
- Windows / Intel Mac support.
- Attaching to already-running or third-party games.
- Charts / graphs UI (use the CSV in a spreadsheet).
- Power draw (needs `sudo powermetrics`).

## 7. Deliverables
1. `RedlineHook.dylib` — frame counter injected into the game.
2. `Redline.app` — overlay + sensor reader + CSV logger.
3. `redline` CLI launcher.
