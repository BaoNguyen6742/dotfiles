import Gtk from "gi://Gtk?version=4.0"
import { execAsync } from "ags/process"

function run(command: string | string[]) {
  execAsync(command).catch((error) => console.error(error))
}

function Action({
  icon,
  label,
  command,
  danger = false,
}: {
  icon: string
  label: string
  command: string | string[]
  danger?: boolean
}) {
  return (
    <button class={danger ? "power-action danger" : "power-action"} onClicked={() => run(command)}>
      <box spacing={10}>
        <label label={icon} />
        <label label={label} xalign={0} />
      </box>
    </button>
  )
}

export default function PowerMenu() {
  return (
    <menubutton class="power" tooltipText="Session and power">
      <label label="󰐥" />
      <popover>
        <box class="popover-content power-panel" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
          <label class="panel-title" label="Session" xalign={0} />
          <Action icon="󰌾" label="Lock" command="hyprlock" />
          <Action icon="󰤄" label="Suspend" command={["systemctl", "suspend"]} />
          <Action icon="󰍃" label="Log out" command={["hyprctl", "dispatch", "exit"]} />
          <Action icon="󰜉" label="Reboot" command={["systemctl", "reboot"]} danger />
          <Action icon="󰐥" label="Shut down" command={["systemctl", "poweroff"]} danger />
        </box>
      </popover>
    </menubutton>
  )
}
