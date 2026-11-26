import Gio from "gi://Gio"
import GLib from "gi://GLib"
import { createState, onCleanup } from "ags"
import { execAsync } from "ags/process"

export type WorkspaceSummary = { id: number; name: string }

const [workspaces, setWorkspaces] = createState<WorkspaceSummary[]>([])
const [focused, setFocused] = createState("")
const [title, setTitle] = createState("Desktop")
let consumers = 0
let stop: (() => void) | undefined

// Both older numeric IDs and newer workspace addresses are supported.
function workspaceId(workspace: any): number {
  return Number(workspace?.id ?? workspace?.address)
}

function start() {
  let disposed = false
  let connection: Gio.SocketConnection | null = null
  let stream: Gio.DataInputStream | null = null
  let cancellable: Gio.Cancellable | null = null
  let reconnectTimer = 0
  let refreshTimer = 0
  let refreshing = false
  let dirty = false

  async function refresh() {
    if (disposed) return
    if (refreshing) {
      dirty = true
      return
    }
    refreshing = true
    try {
      const [spaces, monitors, active, client] = await Promise.all(
        ["workspaces", "monitors", "activeworkspace", "activewindow"].map(
          async (command) => JSON.parse(await execAsync(["hyprctl", command, "-j"])),
        ),
      )
      if (disposed) return
      const visible = new Set(monitors.map((monitor: any) => workspaceId(monitor.activeWorkspace)))
      const next: WorkspaceSummary[] = spaces
        .map((space: any) => ({ ...space, id: workspaceId(space) }))
        .filter((space: any) => Number.isFinite(space.id) && space.id > 0 &&
          (space.windows > 0 || visible.has(space.id)))
        .map((space: any) => ({ id: space.id, name: String(space.name ?? space.id) }))
        .sort((a: WorkspaceSummary, b: WorkspaceSummary) => a.id - b.id)
      const previous = workspaces.peek()
      if (JSON.stringify(previous) !== JSON.stringify(next)) setWorkspaces(next)
      const id = workspaceId(active)
      setFocused(Number.isFinite(id) ? String(id) : "")
      setTitle(client.title || "Desktop")
    } catch (error) {
      if (!disposed) console.error("Could not refresh Hyprland state", error)
    } finally {
      refreshing = false
      if (dirty && !disposed) {
        dirty = false
        scheduleRefresh()
      }
    }
  }

  function scheduleRefresh() {
    if (disposed || refreshTimer) return
    // Coalesce event bursts (for example when swapping entire workspaces).
    refreshTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, () => {
      refreshTimer = 0
      void refresh()
      return GLib.SOURCE_REMOVE
    })
  }

  function disconnect() {
    cancellable?.cancel()
    cancellable = null
    try { stream?.close(null) } catch (_) { /* Already disconnected. */ }
    try { connection?.close(null) } catch (_) { /* Already disconnected. */ }
    stream = null
    connection = null
  }

  function retry(error?: unknown) {
    if (disposed) return
    if (error) console.error("Hyprland event socket disconnected", error)
    disconnect()
    if (reconnectTimer) return
    // This timer only runs while disconnected; state is never periodically polled.
    reconnectTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
      reconnectTimer = 0
      connect()
      return GLib.SOURCE_REMOVE
    })
  }

  function readLine(input: Gio.DataInputStream, token: Gio.Cancellable) {
    input.read_line_async(GLib.PRIORITY_DEFAULT, token, (_source, result) => {
      if (disposed || token.is_cancelled()) return
      try {
        const [line] = input.read_line_finish_utf8(result)
        if (line === null) {
          retry()
          return
        }
        const event = line.split(">>", 1)[0]
        if (/^(workspace|focusedmon|createworkspace|destroyworkspace|moveworkspace|renameworkspace|activespecial|openwindow|closewindow|movewindow|activewindow|windowtitle|monitoradded|monitorremoved|configreloaded)/.test(event)) {
          scheduleRefresh()
        }
        readLine(input, token)
      } catch (error) {
        retry(error)
      }
    })
  }

  function connect() {
    if (disposed) return
    const signature = GLib.getenv("HYPRLAND_INSTANCE_SIGNATURE")
    if (!signature) {
      retry("HYPRLAND_INSTANCE_SIGNATURE is not set")
      return
    }
    const path = GLib.build_filenamev([
      GLib.get_user_runtime_dir(), "hypr", signature, ".socket2.sock",
    ])
    const token = new Gio.Cancellable()
    cancellable = token
    const socket = new Gio.SocketClient()
    socket.connect_async(new Gio.UnixSocketAddress({ path }), token, (_source, result) => {
      try {
        const connected = socket.connect_finish(result)
        if (disposed || token.is_cancelled()) {
          connected.close(null)
          return
        }
        connection = connected
        stream = new Gio.DataInputStream({ base_stream: connected.get_input_stream() })
        readLine(stream, token)
        // Subscribe before fetching so changes during initialization aren't lost.
        scheduleRefresh()
      } catch (error) {
        if (!disposed && !token.is_cancelled()) retry(error)
      }
    })
  }

  connect()
  return () => {
    disposed = true
    if (refreshTimer) GLib.source_remove(refreshTimer)
    if (reconnectTimer) GLib.source_remove(reconnectTimer)
    disconnect()
  }
}

export function useHyprlandState() {
  if (consumers++ === 0) stop = start()
  onCleanup(() => {
    if (--consumers === 0) {
      stop?.()
      stop = undefined
    }
  })
  return { workspaces, focused, title }
}
