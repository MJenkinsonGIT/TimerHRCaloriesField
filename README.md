# TimerHRCaloriesField

A data field for the Garmin Venu 3 that packs seven activity metrics into a single slot — current heart rate (large, zone-coloured), session timer, daily active minutes, session calories, daily total calories, average heart rate, and max heart rate.

---

## About This Project

This app was built through **vibecoding** — a development approach where the human provides direction, intent, and testing, and an AI (in this case, Claude by Anthropic) writes all of the code. I have no formal programming background; this is an experiment in what's possible when curiosity and AI assistance meet.

Every line of Monkey C in this project was written by Claude. My role was to describe what I wanted, test each iteration on a real Garmin Venu 3, report back what worked and what didn't, and keep pushing until the result was something I was happy with.

As part of this process, I've been building a knowledge base — a growing collection of Markdown documents that capture the real-world lessons Claude and I have uncovered together: non-obvious API behaviours, compiler quirks, layout constraints specific to the Venu 3's circular display, and fixes for bugs that aren't covered anywhere in the official SDK documentation. These files are fed back into Claude at the start of each new session so the knowledge carries forward rather than being rediscovered from scratch every time.

The knowledge base is open source. If you're building Connect IQ apps for the Venu 3 and want to skip some of the trial and error, you're welcome to use it:

**[Venu 3 Claude Coding Knowledge Base](https://github.com/MJenkinsonGIT/Venu3ClaudeCodingKnowledge)**

---

## What It Displays

Seven values are arranged across the slot in three columns:

```
  Act Cals          Active Min          Avg Hr
    312                 45               141
          Total Cal   Timer    Max Hr
            2,104     32:17      158
                    Heart Rate
                       147
```

| Field | Position | Description |
|-------|----------|-------------|
| **Heart Rate** | Centre, large | Current heart rate in bpm |
| **Timer** | Centre | Elapsed activity time |
| **Active Min** | Centre | Daily active minutes (moderate + vigorous combined) |
| **Act Cals** | Left outer | Calories burned during the current activity session |
| **Total Cal** | Left inner | Total calories burned today (all-day, not just the session) |
| **Avg Hr** | Right outer | Average heart rate for the current activity session |
| **Max Hr** | Right inner | Maximum heart rate recorded during the current activity session |

### Heart rate zone colouring

The three heart rate fields — **Heart Rate**, **Avg Hr**, and **Max Hr** — are each coloured according to which training zone that value falls in. Zone thresholds are read directly from your Garmin profile and automatically use sport-specific zones where applicable.

| Zone | Colour |
|------|--------|
| Zone 1 (very light) | Light grey |
| Zone 2 (light) | Blue |
| Zone 3 (moderate) | Green |
| Zone 4 (hard) | Orange |
| Zone 5 (maximum) | Red |

Values below Zone 1 or unavailable display in the default foreground colour (white on dark background, black on light).

### How each value is calculated

**Heart Rate** — live reading from the optical sensor, updated each compute cycle via `Activity.Info.currentHeartRate`.

**Timer** — elapsed activity time from `Activity.Info.timerTime` (in milliseconds). Displays as `M:SS` under one hour, `H:MM:SS` for longer sessions.

**Active Min** — today's cumulative active minutes from `ActivityMonitor.Info.activeMinutesDay`, calculated as `moderate + vigorous`. This is the all-day total, not just the current session. Displays as a plain number under 60 minutes, or as `1h30` style for 90+ minutes.

**Act Cals** — calories burned during the current activity, from `Activity.Info.calories`. Resets when a new activity starts.

**Total Cal** — total calories burned today from `ActivityMonitor.Info.calories`. This is your full daily energy expenditure including resting metabolic rate, not just exercise calories.

**Avg Hr** — average heart rate for the current activity session, from `Activity.Info.averageHeartRate`.

**Max Hr** — highest heart rate recorded during the current activity session, from `Activity.Info.maxHeartRate`.

---

## Layout

This field was designed and tested exclusively in the **2-data-field layout**, where the screen is split into a top slot and a bottom slot. The field works correctly in **either position** — it detects which slot it occupies and adjusts the arrangement of all seven elements accordingly, keeping the large heart rate value closest to the centre of the watch face in both cases.

Due to the number of elements that had to be individually positioned to fit within the Venu 3's circular bezel, this layout is highly specific to the 2-field slot dimensions. **It is very unlikely to display correctly in any other layout** (1-field full screen, 4-field quarter screen, or others). Using it outside the 2-field layout is not supported and has not been tested.

---

## Installation

### Which file should I download?

Each release includes three files. All three contain the same app — the difference is how they were compiled:

| File | Size | Best for |
|------|------|----------|
| `TimerHRCaloriesField-release.prg` | Smallest | Most users — just install and run |
| `TimerHRCaloriesField-debug.prg` | ~4× larger | Troubleshooting crashes — includes debug symbols |
| `TimerHRCaloriesField.iq` | Small (7-zip archive) | Developers / advanced users |

**Release `.prg`** is a fully optimised build with debug symbols and logging stripped out. This is what you want if you just want to use the app.

**Debug `.prg` + `.prg.debug.xml`** — these two files must be kept together. The `.prg` is the app binary; the `.prg.debug.xml` is the symbol map that translates raw crash addresses into source file names and line numbers. If the app crashes, the watch writes a log to `GARMIN\APPS\LOGS\CIQ_LOG.YAML` — cross-referencing that log against the `.prg.debug.xml` tells you exactly which line of code caused the crash. Without the `.prg.debug.xml`, the crash addresses in the log are unreadable hex. The app behaves identically to the release build; there is no difference in features or behaviour.

**`.iq` file** is a 7-zip archive containing the release `.prg` plus metadata (manifest, settings schema, signature). It is the format used for Connect IQ Store submissions. You can extract the `.prg` from it by renaming it to `.7z` and extracting — Windows 11 (22H2 and later) supports 7-zip natively via File Explorer's right-click menu. On older Windows versions you will need [7-Zip](https://www.7-zip.org/) (free).

---

**Option A — direct `.prg` download (simplest)**
1. Download the `.prg` file from the [Releases](#) section
2. Connect your Venu 3 via USB
3. Copy the `.prg` to `GARMIN\APPS\` on the watch
4. Press the **Back button** on the watch — it will show "Verifying Apps"
5. Unplug once the watch finishes

**Option B — debug build (for crash analysis)**
1. Download both `TimerHRCaloriesField-debug.prg` and `TimerHRCaloriesField.prg.debug.xml` — keep them together in the same folder on your PC
2. Copy `TimerHRCaloriesField-debug.prg` to `GARMIN\APPS\` on the watch
3. Press the **Back button** on the watch — it will show "Verifying Apps"
4. If the app crashes, retrieve `GARMIN\APPS\LOGS\CIQ_LOG.YAML` from the watch and cross-reference it against the `.prg.debug.xml` to identify the crash location

**Option C — extracting from the `.iq` file**
1. Rename `TimerHRCaloriesField.iq` to `TimerHRCaloriesField.7z`
2. Right-click it → **Extract All** (Windows 11 22H2+) or use [7-Zip](https://www.7-zip.org/) on older Windows
3. Inside the extracted folder, find the `.prg` file inside the device ID subfolder
4. Copy the `.prg` to `GARMIN\APPS\` on the watch
5. Press the **Back button** on the watch — it will show "Verifying Apps"
6. Unplug once the watch finishes

To add the field to an activity data screen: start an activity, long-press the lower button, navigate to **Data Screens**, and add the field to a slot. Configure the screen for **2 data fields** and place this field in either the top or bottom position.

> **To uninstall:** Use Garmin Express. Sideloaded apps cannot be removed directly from the watch or the Garmin Connect phone app.

---

## Device Compatibility

Built and tested on: **Garmin Venu 3**
SDK Version: **8.4.1 / API Level 5.2**

Compatibility with other devices has not been tested.

---

## Notes

- All values display `--` before the activity timer starts or if the sensor data is unavailable.
- Heart rate zone colours are read from your Garmin profile each update cycle. If you have sport-specific zones configured, the correct set is used automatically.
- **Act Cals** and **Total Cal** are different values. Act Cals counts only what was burned during this session; Total Cal is your full day's energy expenditure including resting metabolic rate.
- Active Min is a daily running total, not a per-session count. It does not reset when a new activity starts.
