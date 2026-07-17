import GLib from "gi://GLib"
import Gtk from "gi://Gtk?version=4.0"
import { createPoll } from "ags/time"

export default function Clock() {
  let calendar: Gtk.Calendar
  const time = createPoll("", 1000, () =>
    GLib.DateTime.new_now_local().format("%I:%M:%S %p")!,
  )
  const date = createPoll("", 30000, () =>
    GLib.DateTime.new_now_local().format("%A %Y-%m-%d")!,
  )

  return (
    <menubutton class="clock" tooltipText="Calendar">
      <box spacing={7}>
        <label label="󰃭" />
        <label class="date" label={date} />
        <label class="separator" label="|" />
        <label label="󰥔" />
        <label label={time} />
      </box>
      <popover>
        <box class="popover-content calendar-panel" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
          <label class="panel-title" label="Calendar" xalign={0} />
          <Gtk.Calendar
            $={(widget) => (calendar = widget)}
            showDayNames
            showHeading
            showWeekNumbers
          />
          <button
            class="today-button"
            tooltipText="Jump to the current date"
            onClicked={() => calendar.select_day(GLib.DateTime.new_now_local())}
          >
            <label label="󰃭  Today" />
          </button>
        </box>
      </popover>
    </menubutton>
  )
}
