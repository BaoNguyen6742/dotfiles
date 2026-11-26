import { For } from "ags"
import { execAsync } from "ags/process"
import { useHyprlandState } from "../helpers/hyprland"

export function Workspaces() {
  const { workspaces: shown, focused } = useHyprlandState()

  return (
    <box class="workspaces" spacing={2} visible={shown((items) => items.length > 0)}>
      <For each={shown}>
        {(workspace) => (
          <button
            focusOnClick={false}
            class={focused((active) =>
              active === String(workspace.id) ? "workspace active" : "workspace",
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
  const { title } = useHyprlandState()

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
