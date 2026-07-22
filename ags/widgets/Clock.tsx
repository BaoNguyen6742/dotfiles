import GLib from "gi://GLib"
import Gtk from "gi://Gtk?version=4.0"
import { createComputed, createState, For, type Accessor } from "ags"
import { createPoll } from "ags/time"

type CalendarMonth = {
  year: number
  month: number
}

type CalendarDay = {
  day: number | null
  className: string
}

const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

function CalendarWeek({
  days,
  offset,
  selectDay,
}: {
  days: Accessor<CalendarDay[]>
  offset: number
  selectDay: (day: number) => void
}) {
  return (
    <box class="calendar-week" homogeneous spacing={2}>
      <For each={days((items) => items.slice(offset, offset + 7))}>
        {(item) => (
          <button
            class={item.className}
            sensitive={item.day !== null}
            onClicked={() => item.day !== null && selectDay(item.day)}
          >
            <label label={item.day?.toString() ?? ""} />
          </button>
        )}
      </For>
    </box>
  )
}

export default function Clock() {
  const now = new Date()
  const [month, setMonth] = createState<CalendarMonth>({
    year: now.getFullYear(),
    month: now.getMonth(),
  })
  const [selectedDate, setSelectedDate] = createState({
    year: now.getFullYear(),
    month: now.getMonth(),
    day: now.getDate(),
  })
  const time = createPoll("", 1000, () =>
    GLib.DateTime.new_now_local().format("%I:%M:%S %p")!,
  )
  const date = createPoll("", 30000, () =>
    GLib.DateTime.new_now_local().format("%A %Y-%m-%d")!,
  )
  const monthTitle = month(({ year, month }) =>
    GLib.DateTime.new_local(year, month + 1, 1, 0, 0, 0).format("%B %Y")!,
  )
  const calendarDays = createComputed(() => {
    const shownMonth = month()
    const selected = selectedDate()
    const current = new Date()
    const firstDay = new Date(shownMonth.year, shownMonth.month, 1)
    const mondayOffset = (firstDay.getDay() + 6) % 7
    const daysInMonth = new Date(
      shownMonth.year,
      shownMonth.month + 1,
      0,
    ).getDate()

    return Array.from({ length: 42 }, (_, index): CalendarDay => {
      const day = index - mondayOffset + 1
      if (day < 1 || day > daysInMonth) {
        return { day: null, className: "calendar-day empty" }
      }

      const isToday =
        shownMonth.year === current.getFullYear() &&
        shownMonth.month === current.getMonth() &&
        day === current.getDate()
      const isSelected =
        shownMonth.year === selected.year &&
        shownMonth.month === selected.month &&
        day === selected.day
      const states = [isToday && "today", isSelected && "selected"]
        .filter(Boolean)
        .join(" ")

      return {
        day,
        className: `calendar-day${states ? ` ${states}` : ""}`,
      }
    })
  })

  const changeMonth = (offset: number) => {
    const shownMonth = month()
    const next = new Date(shownMonth.year, shownMonth.month + offset, 1)
    setMonth({ year: next.getFullYear(), month: next.getMonth() })
  }

  const selectDay = (day: number) => {
    const shownMonth = month()
    setSelectedDate({ ...shownMonth, day })
  }

  const showToday = () => {
    const current = new Date()
    const today = {
      year: current.getFullYear(),
      month: current.getMonth(),
      day: current.getDate(),
    }
    setMonth({ year: today.year, month: today.month })
    setSelectedDate(today)
  }

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
          <box class="calendar-header" spacing={6}>
            <button tooltipText="Previous month" onClicked={() => changeMonth(-1)}>
              <label label="‹" />
            </button>
            <label label={monthTitle} hexpand />
            <button tooltipText="Next month" onClicked={() => changeMonth(1)}>
              <label label="›" />
            </button>
          </box>
          <box class="calendar-weekdays" homogeneous spacing={2}>
            {weekdays.map((weekday) => (
              <label label={weekday} />
            ))}
          </box>
          <box class="calendar-grid" orientation={Gtk.Orientation.VERTICAL} spacing={2}>
            {[0, 7, 14, 21, 28, 35].map((offset) => (
              <CalendarWeek days={calendarDays} offset={offset} selectDay={selectDay} />
            ))}
          </box>
          <button
            class="today-button"
            tooltipText="Jump to the current date"
            onClicked={showToday}
          >
            <label label="󰃭  Today" />
          </button>
        </box>
      </popover>
    </menubutton>
  )
}
