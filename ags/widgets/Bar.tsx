import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import { onCleanup } from "ags"
import Clock from "./Clock"
import Media from "./Media"
import PowerMenu from "./Power"
import StatusDrawer from "./StatusDrawer"
import SystemMonitor from "./SystemMonitor"
import { ActiveWindow, Workspaces } from "./Workspaces"
import {
  AudioStatus,
  BatteryStatus,
  BluetoothStatus,
  BrightnessStatus,
  NetworkStatus,
} from "./SystemStatus"

export default function Bar({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  let window: Astal.Window
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  onCleanup(() => window.destroy())

  return (
    <window
      $={(self) => (window = self as Astal.Window)}
      visible
      name={`bar-${gdkmonitor.connector}`}
      namespace="ags-topbar"
      class="Bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <box class="bar-content">
        <box class="bar-section left" spacing={5} hexpand>
          <PowerMenu />
          <Clock />
          <Workspaces />
          <ActiveWindow />
          <Media />
        </box>

        <box class="bar-section right" spacing={5}>
          <StatusDrawer />
          <NetworkStatus />
          <BluetoothStatus />
          <AudioStatus />
          <BrightnessStatus />
          <SystemMonitor />
          <BatteryStatus />
        </box>
      </box>
    </window>
  )
}
