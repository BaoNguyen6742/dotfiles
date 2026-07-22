import Gtk from "gi://Gtk?version=4.0"
import { createState } from "ags"
import NightLight from "./NightLight"
import SystemTray from "./Tray"

export default function StatusDrawer() {
  const [revealed, setRevealed] = createState(false)

  return (
    <box class="status-drawer" spacing={4}>
      <revealer
        revealChild={revealed}
        transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}
        transitionDuration={100}
      >
        <box class="drawer-content" spacing={4}>
          <NightLight />
          <SystemTray />
        </box>
      </revealer>

      <button
        class={revealed((open) =>
          open ? "drawer-toggle active" : "drawer-toggle",
        )}
        tooltipText={revealed((open) =>
          open ? "Hide system controls" : "Show system controls",
        )}
        onClicked={() => setRevealed((open) => !open)}
      >
        <label label="" />
      </button>
    </box>
  )
}
