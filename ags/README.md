# My AGS 3 top bar

This is a GTK4 desktop bar written in TypeScript/TSX for Hyprland. It uses:

- **AGS 3** to build and run the project
- **Gnim** for TSX and reactive state
- **Astal** for Hyprland, audio, network, Bluetooth, battery, media, and tray data
- **GTK4** for widgets, popovers, the calendar, animation, and styling
- **GJS** as the JavaScript runtime (this is not Node.js)

The goal of this document is to explain how this specific setup works so it can be changed without blindly copying configuration.

## Install from the dotfiles repository

Install the required system packages first, then run:

```bash
cd ~/git_packages/dotfiles/ags
./install.sh --dry-run
./install.sh --generate-types
```

The installer copies the tracked configuration to `${AGS_CONFIG_DIR:-$HOME/.config/ags}`, preserves executable permissions, skips unchanged files, and backs up changed destination files. It does not delete unrelated local files or restart the running bar.

The generated `node_modules/` links and `@girs/` definitions are intentionally not tracked. `--generate-types` recreates the definitions after AGS and Astal are installed.

The optional Intel CPU wattage helper requires privilege escalation and can be installed separately:

```bash
./install.sh --install-rapl-helper
```

To start the bar automatically, add this command to the target machine's Hyprland startup configuration:

```bash
ags run "$HOME/.config/ags/app.tsx" --log-file /tmp/ags.log
```

## Current layout

```text
LEFT                                                   RIGHT
[Power] [Date | Time] [Workspaces] [Window] [Media]    [Tray] [Network]
                                                       [Bluetooth] [Audio]
                                                       [Brightness] [Performance] [Battery]
```

- Power, clock, media, network, Bluetooth, audio, brightness, performance, and battery open clickable popovers.
- The system tray and Hyprshade warm-light control are hidden behind a left-facing drawer arrow.
- Empty Hyprland workspaces are hidden.
- The performance popover can switch between line and bar plots.
- A bar is created for every connected monitor.

## Project map

```text
~/.config/ags/
├── app.tsx                         Application entry point
├── style.scss                      All bar and popover styling
├── package.json                    AGS/Gnim editor dependencies
├── tsconfig.json                   TypeScript and TSX configuration
├── env.d.ts                        CSS/SCSS import declarations
├── widgets/
│   ├── Bar.tsx                     Layout and layer-shell window
│   ├── Clock.tsx                   Date, time, calendar, Today button
│   ├── Media.tsx                   MPRIS players and playback controls
│   ├── NightLight.tsx              Hyprshade status and controls
│   ├── Power.tsx                   Lock/suspend/logout/reboot/shutdown
│   ├── StatusDrawer.tsx            Click-to-reveal system tray
│   ├── SystemMonitor.tsx           Metrics, history, Cairo plots
│   ├── SystemStatus.tsx            Wi-Fi/Bluetooth/audio/brightness/battery
│   ├── Tray.tsx                    StatusNotifier tray items and menus
│   └── Workspaces.tsx              Occupied workspaces and active window
├── scripts/
│   ├── nightlight.sh               Toggle and adjust Hyprshade
│   ├── restart.sh                  Restart AGS after editing
│   └── system-stats.sh             Produce performance data as JSON
└── helpers/
    ├── ags-rapl-read.c              Minimal CPU energy reader
    └── install-rapl-helper.sh       Install the reader with one capability
```

Generated TypeScript definitions live in `@girs/`. They are useful for editor completion but are not application source.

## Required packages

This setup was created with the current AGS 3/Astal stack on Arch Linux:

```bash
yay -S aylurs-gtk-shell-git libastal-meta dart-sass
```

It also uses `jq`, `brightnessctl`, `radeontop`, NetworkManager, BlueZ, PipeWire/WirePlumber, UPower, and a Nerd Font. Some modules can still run when an optional tool is missing, but their corresponding data or action will be unavailable.

Do not install the AUR package named only `ags`; that package is Adventure Game Studio.

## How the application starts

`app.tsx` is the entry point:

```tsx
app.start({
  css: style,
  gtkTheme: "Adwaita",
  main() {
    const monitors = createBinding(app, "monitors")

    return (
      <For each={monitors}>
        {(gdkmonitor) => <Bar gdkmonitor={gdkmonitor} />}
      </For>
    )
  },
})
```

`createBinding(app, "monitors")` tracks monitor changes. `<For>` creates a `Bar` for each monitor and removes it when that monitor disappears.

Hyprland starts the project from:

```text
~/.config/hypr/lua_conf/Startup_and_Shutdown/core.lua
```

with the equivalent of:

```bash
ags run ~/.config/ags/app.tsx --log-file /tmp/ags.log
```

## Understanding TSX widgets

A component is a TypeScript function that returns a GTK object:

```tsx
function Greeting() {
  return (
    <box spacing={8}>
      <label label="Hello" />
      <button onClicked={() => print("clicked")}>
        <label label="Click me" />
      </button>
    </box>
  )
}
```

Lowercase elements such as `<box>`, `<label>`, and `<button>` are GTK intrinsic widgets provided by AGS/Gnim. Components you write start with uppercase letters, such as `<Greeting />`.

GTK properties become TSX properties:

```tsx
<label
  label="Text"
  xalign={0}
  hexpand
  maxWidthChars={30}
/>
```

GTK signals use callback properties such as `onClicked`, `onStateSet`, and `onChangeValue`.

A critical detail is that signal callbacks receive the widget first and then the signal arguments:

```tsx
<slider
  onChangeValue={(_slider, _scrollType, newValue) => {
    print(newValue)
  }}
/>
```

Using `_slider.value` inside this callback can read the previous value rather than the requested new value.

## Reactive state

### Local writable state: `createState`

The tray drawer uses writable state:

```tsx
const [revealed, setRevealed] = createState(false)

<button onClicked={() => setRevealed((open) => !open)}>
  <label label={revealed((open) => (open ? "Open" : "Closed"))} />
</button>
```

- `revealed()` reads the current value.
- `revealed(transform)` creates a derived reactive value.
- `setRevealed(value)` updates it.

### Bind a GObject property: `createBinding`

Astal services expose GObject properties. The Bluetooth widget tracks them with bindings:

```tsx
const connected = createBinding(bluetooth, "isConnected")
const powered = createBinding(bluetooth, "isPowered")
```

A label can use a binding directly:

```tsx
<label label={connected((value) => (value ? "Connected" : "Disconnected"))} />
```

When Astal reports a change, GTK updates the label automatically.

### Combine values: `createComputed`

Use `createComputed` when output depends on multiple accessors:

```tsx
const icon = createComputed(() => {
  if (connected()) return "connected-icon"
  return powered() ? "bluetooth-icon" : "bluetooth-off-icon"
})
```

Calling an accessor inside `createComputed` registers it as a dependency.

### Poll external data: `createPoll`

Use polling only when an event-driven Astal service is unavailable:

```tsx
const title = createPoll(
  "Desktop",
  1000,
  ["bash", "-c", "hyprctl activewindow -j | jq -r '.title'"],
  (output) => output.trim() || "Desktop",
)
```

Prefer an argument array over one heavily quoted command string. It avoids shell-parsing mistakes.

### Render reactive lists: `<For>`

Occupied workspaces and tray items use `<For>`:

```tsx
<For each={occupiedWorkspaces}>
  {(workspace) => (
    <button onClicked={() => workspace.focus()}>
      <label label={workspace.name} />
    </button>
  )}
</For>
```

### Handle nullable values: `<With>`

The current Wi-Fi interface and default speaker can change or temporarily be missing. `<With>` safely unwraps them:

```tsx
<With value={speaker}>
  {(device) => device && <AudioDevice speaker={device} />}
</With>
```

## Popovers and dropdowns

A GTK `menubutton` can contain its visible content and a popover:

```tsx
<menubutton tooltipText="Calendar">
  <label label="Open calendar" />
  <popover>
    <box orientation={Gtk.Orientation.VERTICAL}>
      <Gtk.Calendar />
    </box>
  </popover>
</menubutton>
```

This is how most modules provide dropdown functionality without launching a separate application.

The tray drawer uses `Gtk.Revealer` instead:

```tsx
<revealer
  revealChild={revealed}
  transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}
  transitionDuration={250}
>
  <SystemTray />
</revealer>
```

## Astal services in this setup

| Import | Purpose |
|---|---|
| `gi://AstalHyprland` | Workspaces, windows, dispatchers |
| `gi://AstalWp` | PipeWire/WirePlumber audio |
| `gi://AstalNetwork` | NetworkManager and access points |
| `gi://AstalBluetooth` | BlueZ adapters and devices |
| `gi://AstalBattery` | UPower battery data |
| `gi://AstalPowerProfiles` | Performance/balanced/power-saver modes |
| `gi://AstalMpris` | Media players |
| `gi://AstalTray` | StatusNotifier tray items |

The common pattern is:

```tsx
import Network from "gi://AstalNetwork"

const network = Network.get_default()
const wifi = createBinding(network, "wifi")
```

Use the generated files under `@girs/` to discover available classes, methods, properties, and signals.

## How the performance monitor works

There are three layers:

1. `scripts/system-stats.sh` reads Linux interfaces such as `/proc/stat`, `/proc/meminfo`, sysfs, `radeontop`, and network byte counters.
2. It prints one JSON object:

   ```json
   {
     "cpu": 15.2,
     "cpuTemp": 57,
     "cpuWatts": 4.8,
     "gpu": 2,
     "gpuTemp": 55,
     "ram": 43.1,
     "down": 12500,
     "up": 820
   }
   ```

3. `SystemMonitor.tsx` polls that script every two seconds and keeps the last 34 samples.

History is kept with ordinary TypeScript:

```ts
const history = (values: number[], value: number) =>
  [...values, value].slice(-34)
```

At a two-second interval, 34 samples represent about 68 seconds.

### Drawing the plots

The charts are `Gtk.DrawingArea` widgets. Their draw function receives a Cairo context:

```tsx
area.set_draw_func((_area, context, width, height) => {
  context.moveTo(x1, y1)
  context.lineTo(x2, y2)
  context.stroke()
})
```

The line mode draws connected coordinates and a circle at each sample. Bar mode draws a rectangle for every sample. The plot-mode state is shared by all charts so one selector updates the whole dashboard.

If a drawing area depends on an accessor, subscribe to it and request redraws:

```ts
const unsubscribe = values.subscribe(() => area?.queue_draw())
onCleanup(unsubscribe)
```

`onCleanup` is important: it prevents old subscriptions from remaining after a monitor or widget is removed.

## CPU wattage helper

Intel RAPL energy counters are root-readable on this system. Giving capabilities to `gjs` would be unsafe because every GJS program would inherit them.

Instead, this setup uses:

```text
/usr/local/libexec/ags-rapl-read
```

The helper:

- Accepts no arguments
- Opens one hard-coded RAPL energy file
- Drops its capability immediately after opening it
- Prints only the energy counter
- Is installed root-owned so the unprivileged user cannot replace it

Reinstall it after changing its C source:

```bash
pkexec ~/.config/ags/helpers/install-rapl-helper.sh \
  ~/.config/ags/helpers/ags-rapl-read.c
```

The shell script compares consecutive energy readings:

```text
watts = energy difference / elapsed time
```

The AMD GPU does not expose a power sensor, so its wattage remains unavailable. Intel iGPU wattage would be a separate metric and should not be labelled as AMD GPU power.

## Styling with GTK CSS/SCSS

All styling is in `style.scss`. The main color variables are at the top:

```scss
$bg: #0f111a;
$surface: #1a1c25;
$cyan: #89ddff;
$red: #ff5370;
```

TSX `class` values map to selectors:

```tsx
<menubutton class="power">
  <label label="power icon" />
  <popover>...</popover>
</menubutton>
```

A GTK `menubutton` owns an internal button, which is why the stylesheet selects its child:

```scss
.power > button {
  background: $red;
  border-radius: 7px;
}
```

Reactive classes are useful for state:

```tsx
class={connected((value) =>
  value ? "bluetooth connected" : "bluetooth disconnected"
)}
```

```scss
.bluetooth.connected > button {
  color: $green;
}
```

GTK CSS resembles browser CSS but is not browser CSS. Not every web property exists. When a selector does not work:

```bash
ags inspect
```

The GTK inspector shows the actual widget and CSS-node hierarchy.

## Adding a new module

Start with a minimal component:

```tsx
// widgets/MyModule.tsx
import Gtk from "gi://Gtk?version=4.0"
import { createState } from "ags"

export default function MyModule() {
  const [enabled, setEnabled] = createState(false)

  return (
    <menubutton class="my-module">
      <label label={enabled((value) => (value ? "ON" : "OFF"))} />
      <popover>
        <box class="popover-content" orientation={Gtk.Orientation.VERTICAL}>
          <button onClicked={() => setEnabled((value) => !value)}>
            <label label="Toggle" />
          </button>
        </box>
      </popover>
    </menubutton>
  )
}
```

Import and place it in `widgets/Bar.tsx`:

```tsx
import MyModule from "./MyModule"

<MyModule />
```

Add styling:

```scss
.my-module > button {
  color: $cyan;
}
```

Then build and restart.

## Development workflow

A safe edit loop is:

```bash
# 1. Build first; this catches TSX and bundling errors
ags bundle ~/.config/ags/app.tsx /tmp/ags-shell

# 2. Restart the live bar
~/.config/ags/scripts/restart.sh

# 3. Watch runtime messages
tail -f /tmp/ags.log
```

Other useful commands:

```bash
# List AGS instances
ags list

# Stop AGS
ags quit

# Open GTK inspector
ags inspect

# Regenerate GI TypeScript definitions after installing Astal libraries
ags types 'Astal*' --ignore Astal3 -d ~/.config/ags
```

The current AGS/Gnim package may produce TypeScript diagnostics inside `/usr/share/ags` even when this project's own source is valid. `ags bundle` plus a clean runtime log are the authoritative practical checks for this installed version.

## Troubleshooting

### Bar disappeared after an edit

Run:

```bash
ags bundle ~/.config/ags/app.tsx /tmp/ags-shell
```

Fix the reported syntax/import error, then run:

```bash
~/.config/ags/scripts/restart.sh
```

### Check the runtime log

```bash
tail -100 /tmp/ags.log
```

The Adwaita preference warning currently shown at startup is harmless.

### Icons render as boxes

The bar expects a Nerd Font, currently:

```scss
font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", sans-serif;
```

Confirm that the Nerd Font is installed and that the glyph exists in it.

### A service module is empty

Check its backend:

```bash
systemctl status NetworkManager
systemctl --user status pipewire wireplumber
systemctl status bluetooth
```

MPRIS only appears when a compatible media player is running. Tray items only appear when applications export StatusNotifier items.

### Restore Waybar temporarily

```bash
ags quit
waybar &
```

To restore Waybar permanently, change the startup command in the Hyprland startup file back to `waybar`.

## Good experiments for learning

1. Change the palette variables in `style.scss`.
2. Change `transitionDuration` in `StatusDrawer.tsx`.
3. Add seconds or switch to 24-hour time in `Clock.tsx`.
4. Add another `MetricRow` backed by a field from `system-stats.sh`.
5. Add a third plot mode that draws dots without connecting lines.
6. Add a new Astal-backed module using `createBinding` rather than polling.
7. Move components around in `Bar.tsx` and observe how `centerbox` behaves.

Change one thing at a time, build, restart, and inspect the log. That makes GTK and reactive UI behavior much easier to understand.

## References

- AGS guide: <https://aylur.github.io/ags/guide/quick-start.html>
- Astal documentation: <https://aylur.github.io/astal/>
- Gnim documentation: <https://aylur.github.io/gnim/>
- GJS guide: <https://gjs.guide/>
- GTK4 widgets: <https://docs.gtk.org/gtk4/>
- GTK4 CSS: <https://docs.gtk.org/gtk4/css-overview.html>
