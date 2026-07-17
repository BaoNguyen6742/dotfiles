import GLib from "gi://GLib"
import Gtk from "gi://Gtk?version=4.0"
import { execAsync } from "ags/process"
import { createPoll } from "ags/time"

type NightLightState = {
  active: boolean
  level: number
}

const SCRIPT = GLib.build_filenamev([
  GLib.get_home_dir(),
  ".config",
  "ags",
  "scripts",
  "nightlight.sh",
])

const state = createPoll<NightLightState>(
  { active: false, level: 3 },
  1000,
  [SCRIPT, "status"],
  (output, previous) => {
    try {
      return JSON.parse(output) as NightLightState
    } catch (error) {
      console.error("Could not read Hyprshade state", error)
      return previous
    }
  },
)

function run(action: "toggle" | "up" | "down") {
  execAsync([SCRIPT, action]).catch(console.error)
}

export default function NightLight() {
  return (
    <button
      class={state((value) =>
        value.active ? "nightlight active" : "nightlight inactive",
      )}
      tooltipText={state((value) =>
        value.active
          ? `Warm light enabled · level ${value.level}/5\nClick to disable · scroll to adjust`
          : "Warm light disabled · click to enable",
      )}
      onClicked={() => run("toggle")}
    >
      <Gtk.EventControllerScroll
        flags={Gtk.EventControllerScrollFlags.VERTICAL}
        onScroll={(_controller, _dx, dy) => {
          run(dy < 0 ? "up" : "down")
          return true
        }}
      />
      <label
        label={state((value) => (value.active ? "󰽢" : "󰖨"))}
        xalign={0.5}
      />
    </button>
  )
}
