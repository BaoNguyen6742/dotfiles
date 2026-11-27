import Tray from "gi://AstalTray"
import Gdk from "gi://Gdk?version=4.0"
import Gio from "gi://Gio"
import Gtk from "gi://Gtk?version=4.0"
import { createBinding, createComputed, For } from "ags"

const tray = Tray.get_default()

export default function SystemTray() {
  const items = createBinding(tray, "items")
  const display = Gdk.Display.get_default()
  const iconTheme = display ? Gtk.IconTheme.get_for_display(display) : null

  const trayIcon = (item: Tray.TrayItem) => {
    const name = createBinding(item, "iconName")
    const gicon = createBinding(item, "gicon")

    return createComputed(() => {
      const iconName = name()
      if (!iconName || iconName.includes("/")) return gicon()

      // nm-applet can request a dark full-color icon even when it ships a symbolic variant.
      const symbolicName =
        item.id === "nm-applet" && !iconName.endsWith("-symbolic")
          ? `${iconName}-symbolic`
          : iconName

      // Themed symbolic icons follow the tray's foreground color.
      if (symbolicName.endsWith("-symbolic") && iconTheme?.has_icon(symbolicName)) {
        return Gio.ThemedIcon.new(symbolicName)
      }
      return gicon()
    })
  }

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
            <image gicon={trayIcon(item)} pixelSize={18} />
          </menubutton>
        )}
      </For>
    </box>
  )
}
