# My AGS 3 top bar

This is a GTK4 desktop bar written in TypeScript/TSX for Hyprland. It uses:

- **AGS 3** to build and run the project
- **Gnim** for TSX and reactive state
- **Astal** for Hyprland, audio, network, Bluetooth, battery, media, and tray data
- **GTK4** for widgets, popovers, the calendar, animation, and styling
- **GJS** as the JavaScript runtime (this is not Node.js)

The goal of this document is to explain how this specific setup works so it can be changed without blindly copying configuration.

## Install from the dotfiles repository

Install the required system packages first. From the repository root, preview and create the Stow links, then generate the local Astal definitions:

```bash
./scripts/stow.sh --simulate --verbose ags
./scripts/stow.sh --verbose ags
./scripts/ags/setup.sh --generate-types
```

The Stow wrapper links the tracked configuration into `~/.config/ags` without folding the whole writable directory into the repository. Stow refuses to overwrite conflicting regular files; compare and back those files up before retrying.

Managed files under `~/.config/ags` are symlinks into `packages/ags/.config/ags`, so editing them updates the repository directly. Review changes with `git diff`. Generated `node_modules/` links and `@girs/` definitions remain local and are intentionally not tracked.

After pulling updates on another machine, refresh links with `./scripts/stow.sh --restow ags`. The optional Intel/AMD CPU wattage helper requires privilege escalation and can be installed separately:

```bash
./scripts/ags/setup.sh --install-rapl-helper
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
- Empty Hyprland workspaces are hidden unless they are currently visible on a monitor.
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
│   ├── monitor-brightness.sh       Read/set backlight or DDC/CI brightness
│   ├── nightlight.sh               Toggle and adjust Hyprshade
│   ├── restart.sh                  Restart AGS after editing
│   └── system-stats.sh             Produce performance data as JSON
└── helpers/
    ├── ags-rapl-read.c              Minimal Intel/AMD CPU energy reader
    └── install-rapl-helper.sh       Install the reader with limited capabilities
```

Generated TypeScript definitions live in `@girs/`. They are useful for editor completion but are not application source.

## Dependencies

Package names vary significantly between distributions. The executable, library, typelib, and D-Bus service names below are the authoritative requirements; translate them to the packages supplied by the target distribution.

### Core graphical stack (required)

| Requirement | Used for | Common package/project name |
|---|---|---|
| Hyprland | Compositor, monitor/workspace/window IPC | `hyprland` |
| AGS **version 3** | Application runner, bundler, GTK4 TSX runtime | `aylurs-gtk-shell`, `aylurs-gtk-shell-git`, or AGS built from source |
| GJS | JavaScript runtime and GI loader | `gjs` |
| GTK 4 | Widgets and rendering | `gtk4` / `libgtk-4-*` |
| GTK4 Layer Shell | Anchored exclusive top-bar window | `gtk4-layer-shell` |
| GObject Introspection | Loading the Astal typelibs from GJS | `gobject-introspection` |
| Gnim/AGS TypeScript modules | TSX and reactive primitives imported from `ags` | normally installed or resolved by AGS 3 |
| Node.js/npm tooling | Resolving the AGS/Gnim modules during setup; the running app still uses GJS | `nodejs` and `npm` when not pulled in by AGS |
| Sass executable named `sass` | Compiling `style.scss` | `dart-sass` |

Do not install the unrelated package named only `ags` if it is Adventure Game Studio. Confirm that `ags --version` reports AGS 3.

### Astal libraries and typelibs (required)

Installing the Astal meta-package is easiest when the distribution provides one. Otherwise install the base GTK4/IO library and every service library listed here:

| GI namespace imported by this config | Astal component/package usually containing it |
|---|---|
| `Astal-4.0` | `libastal`, `libastal-4`, or Astal GTK4 base |
| `AstalHyprland-0.1` | `libastal-hyprland` |
| `AstalWp-0.1` | `libastal-wireplumber` |
| `AstalNetwork-0.1` | `libastal-network` |
| `AstalBluetooth-0.1` | `libastal-bluetooth` |
| `AstalBattery-0.1` | `libastal-battery` |
| `AstalPowerProfiles-0.1` | `libastal-powerprofiles` / `libastal-power-profiles` |
| `AstalMpris-0.1` | `libastal-mpris` |
| `AstalTray-0.1` | `libastal-tray` |

Arch-based distributions commonly provide all of these through `libastal-meta`. On distributions without packaged AGS 3/Astal, build both from their upstream projects; installing only GTK and GJS is not sufficient.

### Required command-line utilities

These commands are used directly by the tracked scripts:

| Executable | Typical package | Purpose |
|---|---|---|
| `bash` | `bash` | Installer and helper scripts |
| `awk` | `gawk`, `mawk`, or another POSIX awk | Numeric calculations and parsing |
| `jq` | `jq` | Performance JSON and Hyprland JSON parsing |
| `ip` | `iproute2` | Selecting the default network interface |
| `timeout` | `coreutils` | Bounding GPU probe execution |
| `find`, `sort` | `findutils`, `coreutils` | Installation and powercap discovery |
| `hyprctl` | normally shipped with Hyprland | Workspaces, active window, logout, and night-light control |
| `systemctl` | `systemd` | Suspend, reboot, and shutdown buttons |

The power menu currently assumes systemd. On a non-systemd distribution, change the commands in `widgets/Power.tsx` to that system's equivalents.

### Runtime services

The libraries need the corresponding system/session services, not just client packages:

| Feature | Service/backend needed |
|---|---|
| Wi-Fi and wired networking | NetworkManager |
| Bluetooth | BlueZ system service |
| Audio | PipeWire plus WirePlumber |
| Battery | UPower |
| Power-profile selector | power-profiles-daemon or another service implementing `net.hadess.PowerProfiles` |
| Media controls | MPRIS-compatible media players on the session bus |
| System tray | StatusNotifierItem-compatible applications |
| All Astal services | A working user D-Bus session |

Network, Bluetooth, battery, media, tray, and power-profile widgets may be empty when their hardware or service is absent.

### Hardware-specific and optional utilities

| Utility | When it is needed | Typical package |
|---|---|---|
| `brightnessctl` | Internal laptop-panel brightness | `brightnessctl` |
| `ddcutil` | External monitor DDC/CI brightness | `ddcutil`; also requires the kernel `i2c-dev` module and user access to `/dev/i2c-*` |
| `nvidia-smi` | NVIDIA utilization, temperature, VRAM, and power | NVIDIA driver utilities, commonly `nvidia-utils` |
| `radeontop` | AMD GPU utilization fallback when DRM does not expose `gpu_busy_percent` | `radeontop` |
| `hyprlock` | Lock button | `hyprlock` |
| `nm-connection-editor` | Advanced network button and secured-network setup | often `network-manager-applet` or `network-manager-gnome` |
| `blueman-manager` | Advanced Bluetooth button | `blueman` |
| `pavucontrol` | Advanced audio mixer button | `pavucontrol` |
| Nerd Font | Icons used as label glyphs | JetBrains Mono Nerd Font or another current Nerd Font |

Missing GPU or sensor tools do not prevent the bar from starting: unavailable metrics display `—`. Brightness controls hide when neither a usable kernel backlight nor DDC/CI display is found.

The night-light drawer action additionally expects `warm_1.glsl` through `warm_5.glsl` under `~/.config/hypr/hypr_conf/shaders/`. Its current `hyprctl eval` command targets this dotfiles setup's Lua Hyprland configuration provider; replace `scripts/nightlight.sh` with `hyprshade` or a normal `hyprctl keyword decoration:screen_shader ...` implementation on a stock Hyprland configuration.

### Optional CPU wattage helper build dependencies

`./scripts/ags/setup.sh --install-rapl-helper` additionally needs:

- A C compiler available as `cc` (`gcc` or `clang`)
- Linux userspace kernel headers providing `linux/capability.h` (often `linux-api-headers` or part of libc development headers)
- `install` from coreutils
- `setcap` and `getcap` from libcap tools (`libcap`, `libcap2-bin`, or an equivalent package)
- `pkexec` plus a running polkit authentication agent, or run `helpers/install-rapl-helper.sh` through `sudo`
- `/dev/cpu/0/msr` for the Intel/AMD MSR fallback; the kernel `msr` module may need to be loaded

The helper is optional when CPU package power is already readable through hwmon or `/sys/class/powercap`. Without any supported source, only CPU watts display as `—`.

### Convenience packages for Arch Linux

A broad Arch installation matching every supported feature is:

```bash
yay -S --needed \
  hyprland aylurs-gtk-shell libastal-meta nodejs npm dart-sass \
  jq networkmanager bluez pipewire wireplumber upower power-profiles-daemon \
  brightnessctl ddcutil radeontop \
  network-manager-applet blueman pavucontrol hyprlock \
  ttf-jetbrains-mono-nerd polkit gcc libcap
```

Install `nvidia-utils` only on NVIDIA systems. Depending on the repository snapshot, the AGS and Astal package names may use a `-git` suffix.

### Verification on a new distribution

After translating the package names, verify the important commands and generate the GI definitions:

```bash
for command in ags gjs sass bash awk jq ip timeout hyprctl; do
  command -v "$command" || echo "MISSING: $command"
done

./scripts/ags/setup.sh --generate-types
find "${AGS_CONFIG_DIR:-$HOME/.config/ags}/@girs" \
  -maxdepth 1 -iname 'astal*.d.ts' -print
```

The generated list should include the Astal namespaces in the table above. Then test the hardware helpers independently:

```bash
~/.config/ags/scripts/system-stats.sh | jq .
~/.config/ags/scripts/monitor-brightness.sh DP-1
ags run ~/.config/ags/app.tsx --log-file /tmp/ags.log
```

Replace `DP-1` with a connector reported by `hyprctl monitors`. A brightness result of `-1` means that connector has no usable backlight/DDC backend, which is valid on unsupported displays.

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
~/.config/hypr/hypr_lua/Startup_and_Shutdown/core.lua
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

Shown workspaces and tray items use `<For>`:

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

1. `scripts/system-stats.sh` auto-detects Linux interfaces such as `/proc`, hwmon, DRM, powercap, `nvidia-smi`, or `radeontop` and reads network byte counters.
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
const history = (values: number[], value: number | null) =>
  value === null ? values : [...values, value].slice(-34)
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

## Hardware portability

The scripts prefer standard kernel interfaces and degrade gracefully:

- CPU temperature: `k10temp`, `zenpower`, `coretemp`, or `cpu_thermal`
- CPU power: hwmon, readable powercap, then the optional fixed-purpose helper
- GPU selection: the DRM `boot_vga` card, avoiding a sleeping discrete GPU on most hybrid laptops
- GPU metrics: card-specific DRM/hwmon, `nvidia-smi` for NVIDIA, or `radeontop` as an AMD fallback
- Internal-panel brightness: the kernel backlight interface through `brightnessctl`
- External-monitor brightness: per-connector DDC/CI through `ddcutil`

Unsupported metrics show `—`; an unavailable brightness control is hidden. Unusual machines can override detection with `AGS_GPU_CARD=cardN`, `AGS_GPU_VENDOR=amd|intel|nvidia`, `AGS_CPU_TEMP_PATH`, `AGS_CPU_POWER_PATH`, `AGS_CPU_ENERGY_PATH`, `AGS_BRIGHTNESS_BACKEND=backlight|ddc`, or `AGS_BACKLIGHT_DEVICE`.

### CPU wattage helper

Root-only package-energy counters must not be exposed by giving capabilities to `gjs`. This setup instead installs a small root-owned helper at:

```text
/usr/local/libexec/ags-rapl-read
```

The helper accepts no arguments, opens only fixed Linux powercap paths or fixed Intel/AMD package-energy MSRs, drops its capabilities immediately after opening the source, and prints the energy counter plus its wrap range. Install or reinstall it with:

```bash
./scripts/ags/setup.sh --install-rapl-helper
```

The shell script compares consecutive readings and handles counter wrap:

```text
watts = energy difference / elapsed time
```

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
