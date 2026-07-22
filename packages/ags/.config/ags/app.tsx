import { createBinding, For, This } from "ags"
import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widgets/Bar"

app.start({
  css: style,
  gtkTheme: "Adwaita",
  main() {
    const monitors = createBinding(app, "monitors")

    return (
      <For each={monitors}>
        {(gdkmonitor) => (
          <This this={app}>
            <Bar gdkmonitor={gdkmonitor} />
          </This>
        )}
      </For>
    )
  },
})
