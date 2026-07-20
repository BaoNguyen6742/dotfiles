import Hyprland from "gi://AstalHyprland"
import { createBinding, For } from "ags"
import { execAsync } from "ags/process"
import { createPoll } from "ags/time"

const hyprland = Hyprland.get_default()

type WorkspaceSummary = {
  id: number
  name: string
}

export function Workspaces() {
  const focused = createBinding(hyprland, "focusedWorkspace")

  // Astal's workspace client lists can briefly stay stale after swap_ws.sh
  // moves several clients in one batch. Use Hyprland's JSON to show occupied
  // workspaces plus every workspace currently visible on a monitor.
  const shown = createPoll<WorkspaceSummary[]>(
    [],
    500,
    [
      "bash",
      "-c",
      `jq -sc '.[0] as $workspaces | (.[1] | map(.activeWorkspace.id)) as $visible | [$workspaces[] | . as $workspace | select(.id > 0 and (.windows > 0 or ($visible | index($workspace.id)))) | {id, name}] | sort_by(.id)' <(hyprctl workspaces -j) <(hyprctl monitors -j)`,
    ],
    (output, previous) => {
      try {
        const next = JSON.parse(output) as WorkspaceSummary[]
        const unchanged =
          next.length === previous.length &&
          next.every(
            (workspace, index) =>
              workspace.id === previous[index]?.id &&
              workspace.name === previous[index]?.name,
          )
        return unchanged ? previous : next
      } catch (error) {
        console.error("Could not read Hyprland workspaces", error)
        return previous
      }
    },
  )

  return (
    <box class="workspaces" spacing={2} visible={shown((items) => items.length > 0)}>
      <For each={shown}>
        {(workspace) => (
          <button
            class={focused((active) =>
              active?.id === workspace.id ? "workspace active" : "workspace",
            )}
            tooltipText={`Workspace ${workspace.name}`}
            onClicked={() =>
              execAsync([
                "hyprctl",
                "eval",
                `hl.dispatch(hl.dsp.focus({ workspace = ${workspace.id} }))`,
              ]).catch(console.error)
            }
          >
            <label label={workspace.name} />
          </button>
        )}
      </For>
    </box>
  )
}

export function ActiveWindow() {
  // AstalHyprland's focusedClient getter can be null while the desktop is
  // focused, so poll Hyprland's JSON here instead of dereferencing it.
  const title = createPoll(
    "Desktop",
    1000,
    ["bash", "-c", `hyprctl activewindow -j | jq -r '.title // "Desktop"'`],
    (value) => value.trim() || "Desktop",
  )

  return (
    <button
      class="active-window"
      tooltipText={title}
      onClicked={() =>
        execAsync(["hyprctl", "dispatch", "cyclenext"]).catch(console.error)
      }
    >
      <label label={title} maxWidthChars={24} ellipsize={3} />
    </button>
  )
}
