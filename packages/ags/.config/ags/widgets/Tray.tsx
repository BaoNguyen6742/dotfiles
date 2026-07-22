import Tray from "gi://AstalTray"
import Gtk from "gi://Gtk?version=4.0"
import { createBinding, For } from "ags"

const tray = Tray.get_default()

export default function SystemTray() {
  const items = createBinding(tray, "items")

  const setup = (button: Gtk.MenuButton, item: Tray.TrayItem) => {
    button.menuModel = item.menuModel
    button.insert_action_group("dbusmenu", item.actionGroup)
    item.connect("notify::action-group", () => {
      button.insert_action_group("dbusmenu", item.actionGroup)
    })
  }

  return (
    <box class="tray" spacing={2} visible={items((value) => value.length > 0)}>
      <For each={items}>
        {(item) => (
          <menubutton
            class="tray-item"
            tooltipMarkup={createBinding(item, "tooltipMarkup")}
            $={(button) => setup(button as Gtk.MenuButton, item)}
          >
            <image gicon={createBinding(item, "gicon")} pixelSize={18} />
          </menubutton>
        )}
      </For>
    </box>
  )
}
