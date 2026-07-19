import GLib from "gi://GLib"
import Gtk from "gi://Gtk?version=4.0"
import type { Accessor } from "ags"
import { createState, onCleanup } from "ags"
import { createPoll } from "ags/time"

const SCRIPT = GLib.build_filenamev([
  GLib.get_home_dir(),
  ".config",
  "ags",
  "scripts",
  "system-stats.sh",
])

type PlotMode = "line" | "bar"

const [plotMode, setPlotMode] = createState<PlotMode>("line")

type Sample = {
  cpu: number
  cpuTemp: number | null
  cpuWatts: number | null
  gpu: number | null
  gpuTemp: number | null
  gpuWatts: number | null
  vram: number | null
  ram: number
  down: number
  up: number
  systemWatts: number | null
}

type Stats = Sample & {
  cpuHistory: number[]
  gpuHistory: number[]
  ramHistory: number[]
  downHistory: number[]
  upHistory: number[]
  cpuTempHistory: number[]
  gpuTempHistory: number[]
}

const empty: Stats = {
  cpu: 0,
  cpuTemp: null,
  cpuWatts: null,
  gpu: null,
  gpuTemp: null,
  gpuWatts: null,
  vram: null,
  ram: 0,
  down: 0,
  up: 0,
  systemWatts: null,
  cpuHistory: [],
  gpuHistory: [],
  ramHistory: [],
  downHistory: [],
  upHistory: [],
  cpuTempHistory: [],
  gpuTempHistory: [],
}

const history = (values: number[], value: number | null) =>
  value === null ? values : [...values, value].slice(-34)

const stats = createPoll(empty, 2000, [SCRIPT], (stdout, previous) => {
  try {
    const next = JSON.parse(stdout) as Sample
    return {
      ...next,
      cpuHistory: history(previous.cpuHistory, next.cpu),
      gpuHistory: history(previous.gpuHistory, next.gpu),
      ramHistory: history(previous.ramHistory, next.ram),
      downHistory: history(previous.downHistory, next.down),
      upHistory: history(previous.upHistory, next.up),
      cpuTempHistory: history(previous.cpuTempHistory, next.cpuTemp),
      gpuTempHistory: history(previous.gpuTempHistory, next.gpuTemp),
    }
  } catch (error) {
    console.error("Could not parse system stats", error)
    return previous
  }
})

function colorChannels(hex: string) {
  const value = Number.parseInt(hex.slice(1), 16)
  return [((value >> 16) & 255) / 255, ((value >> 8) & 255) / 255, (value & 255) / 255]
}

function LinePlot({
  values,
  ceiling,
  color,
}: {
  values: Accessor<number[]>
  ceiling?: number
  color: string
}) {
  let area: Gtk.DrawingArea | undefined
  const [red, green, blue] = colorChannels(color)
  const unsubscribeValues = values.subscribe(() => area?.queue_draw())
  const unsubscribeMode = plotMode.subscribe(() => area?.queue_draw())
  onCleanup(() => {
    unsubscribeValues()
    unsubscribeMode()
  })

  return (
    <drawingarea
      class="metric-plot"
      contentWidth={440}
      contentHeight={58}
      hexpand
      $={(widget) => {
        area = widget as Gtk.DrawingArea
        area.set_draw_func((_area, context, width, height) => {
          const points = values.peek()
          const padding = 5
          const plotWidth = width - padding * 2
          const plotHeight = height - padding * 2

          context.setLineWidth(1)
          context.setSourceRGBA(1, 1, 1, 0.08)
          for (let row = 1; row <= 3; row += 1) {
            const y = padding + (plotHeight * row) / 4
            context.moveTo(padding, y)
            context.lineTo(width - padding, y)
          }
          context.stroke()

          if (points.length === 0) return
          const maximum = Math.max(ceiling || 0, ...points, 1)
          const coordinates = points.map((value, index) => ({
            x:
              points.length === 1
                ? padding
                : padding + (index / (points.length - 1)) * plotWidth,
            y: height - padding - Math.min(1, Math.max(0, value / maximum)) * plotHeight,
          }))

          context.setSourceRGBA(red, green, blue, 0.95)

          if (plotMode.peek() === "bar") {
            const slotWidth = plotWidth / Math.max(34, points.length)
            const barWidth = Math.max(2, slotWidth * 0.68)
            coordinates.forEach(({ y }, index) => {
              const x = padding + index * slotWidth + (slotWidth - barWidth) / 2
              context.rectangle(x, y, barWidth, height - padding - y)
            })
            context.fill()
            return
          }

          context.setLineWidth(2)
          coordinates.forEach(({ x, y }, index) => {
            if (index === 0) context.moveTo(x, y)
            else context.lineTo(x, y)
          })
          context.stroke()

          coordinates.forEach(({ x, y }) => {
            context.arc(x, y, 2.4, 0, Math.PI * 2)
            context.fill()
          })
        })
      }}
    />
  )
}

function bytes(value: number) {
  const units = ["B/s", "KiB/s", "MiB/s", "GiB/s"]
  let amount = value
  let unit = 0
  while (amount >= 1024 && unit < units.length - 1) {
    amount /= 1024
    unit += 1
  }
  return `${amount >= 100 || unit === 0 ? amount.toFixed(0) : amount.toFixed(1)} ${units[unit]}`
}

function compactBytes(value: number) {
  if (value >= 1024 ** 3) return `${(value / 1024 ** 3).toFixed(1)}G`
  if (value >= 1024 ** 2) return `${(value / 1024 ** 2).toFixed(1)}M`
  if (value >= 1024) return `${(value / 1024).toFixed(1)}K`
  return `${Math.round(value)}B`
}

function percent(value: number | null) {
  return value === null ? "—" : `${value.toFixed(0)}%`
}

function temperature(value: number | null) {
  return value === null ? "—" : `${value.toFixed(0)}°C`
}

function watts(value: number | null) {
  return value === null ? "— W" : `${value.toFixed(1)} W`
}

function MetricRow({
  icon,
  title,
  value,
  plotValues,
  ceiling,
  color,
  className,
}: {
  icon: string
  title: string
  value: Accessor<string>
  plotValues: Accessor<number[]>
  ceiling?: number
  color: string
  className: string
}) {
  return (
    <box class={`metric-row ${className}`} orientation={Gtk.Orientation.VERTICAL} spacing={4}>
      <box spacing={8}>
        <label class="metric-icon" label={icon} />
        <label class="metric-title" label={title} xalign={0} hexpand />
        <label class="metric-value" label={value} />
      </box>
      <LinePlot values={plotValues} ceiling={ceiling} color={color} />
    </box>
  )
}

export default function SystemMonitor() {
  const summary = stats((value) => {
    const cpu = `${Math.round(value.cpu)}%`.padStart(4)
    const ram = `${Math.round(value.ram)}%`.padStart(4)
    // Right-align upload and left-align download around the separator so the
    // two speed fields stay visually balanced as their values change.
    const upload = `↑ ${compactBytes(value.up)}`.padStart(8)
    const download = `↓ ${compactBytes(value.down)}`.padEnd(8)

    return `󰍛 ${cpu}   ${ram}  ${upload} | ${download}`
  })

  return (
    <menubutton class="system-monitor" tooltipText="System performance">
      <label
        label={summary}
        xalign={0.5}
        justify={Gtk.Justification.CENTER}
      />
      <popover>
        <box class="popover-content monitor-panel" orientation={Gtk.Orientation.VERTICAL} spacing={10}>
          <box spacing={8}>
            <label class="panel-title" label="Performance" xalign={0} hexpand />
            <label class="dim" label="~68 seconds" />
          </box>

          <box class="plot-mode" spacing={4} halign={Gtk.Align.CENTER}>
            <label class="dim" label="Plot" />
            <button
              class={plotMode((mode) => (mode === "line" ? "active" : ""))}
              onClicked={() => setPlotMode("line")}
            >
              <label label="󰈀  Line" />
            </button>
            <button
              class={plotMode((mode) => (mode === "bar" ? "active" : ""))}
              onClicked={() => setPlotMode("bar")}
            >
              <label label="󰓫  Bars" />
            </button>
          </box>

          <scrolledwindow
            hscrollbarPolicy={Gtk.PolicyType.NEVER}
            vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
            propagateNaturalHeight
            maxContentHeight={650}
          >
            <box orientation={Gtk.Orientation.VERTICAL} spacing={10}>
              <MetricRow
                icon="󰍛"
                title="CPU"
                className="cpu-metric"
                value={stats(
                  (value) => `${value.cpu.toFixed(0)}%  ${watts(value.cpuWatts)}`,
                )}
                plotValues={stats((value) => value.cpuHistory)}
                ceiling={100}
                color="#ffcb6b"
              />

              <MetricRow
                icon="󰢮"
                title="CPU temperature"
                className="temp-metric"
                value={stats((value) => temperature(value.cpuTemp))}
                plotValues={stats((value) => value.cpuTempHistory)}
                ceiling={100}
                color="#f78c6c"
              />

              <MetricRow
                icon="󰢮"
                title="GPU"
                className="gpu-metric"
                value={stats(
                  (value) => `${percent(value.gpu)}  ${watts(value.gpuWatts)}`,
                )}
                plotValues={stats((value) => value.gpuHistory)}
                ceiling={100}
                color="#82aaff"
              />

              <MetricRow
                icon="󰔏"
                title="GPU temperature"
                className="gpu-temp-metric"
                value={stats((value) => temperature(value.gpuTemp))}
                plotValues={stats((value) => value.gpuTempHistory)}
                ceiling={120}
                color="#ff5370"
              />

              <MetricRow
                icon=""
                title="RAM"
                className="ram-metric"
                value={stats((value) => `${value.ram.toFixed(0)}%`)}
                plotValues={stats((value) => value.ramHistory)}
                ceiling={100}
                color="#c792ea"
              />

              <MetricRow
                icon="󰓅"
                title="Download"
                className="download-metric"
                value={stats((value) => bytes(value.down))}
                plotValues={stats((value) => value.downHistory)}
                color="#89ddff"
              />

              <MetricRow
                icon="󰓇"
                title="Upload"
                className="upload-metric"
                value={stats((value) => bytes(value.up))}
                plotValues={stats((value) => value.upHistory)}
                color="#c3e88d"
              />
            </box>
          </scrolledwindow>

        </box>
      </popover>
    </menubutton>
  )
}
