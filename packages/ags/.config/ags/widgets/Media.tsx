import Mpris from "gi://AstalMpris"
import Gtk from "gi://Gtk?version=4.0"
import { createBinding, For } from "ags"

const mpris = Mpris.get_default()
const players = createBinding(mpris, "players")

function MediaButton({ player }: { player: Mpris.Player }) {
  const playbackStatus = createBinding(player, "playbackStatus")

  return (
    <menubutton
      class="media"
      visible={playbackStatus((status) => status === Mpris.PlaybackStatus.PLAYING)}
      tooltipText="Media controls"
    >
      <box spacing={7}>
        <label label="󰎈" />
        <label
          label={createBinding(player, "title")((title) => title || "Media")}
          maxWidthChars={18}
          ellipsize={3}
        />
      </box>
      <popover>
        <box class="popover-content media-panel" orientation={Gtk.Orientation.VERTICAL} spacing={10}>
          <For each={players}>
            {(panelPlayer) => (
              <box class="media-player" spacing={12}>
                <image
                  class="cover-art"
                  pixelSize={72}
                  file={createBinding(panelPlayer, "coverArt")}
                  visible={createBinding(panelPlayer, "coverArt")(Boolean)}
                />
                <box orientation={Gtk.Orientation.VERTICAL} spacing={4} hexpand>
                  <label
                    class="media-title"
                    xalign={0}
                    label={createBinding(panelPlayer, "title")((title) => title || "Unknown title")}
                    maxWidthChars={30}
                    ellipsize={3}
                  />
                  <label
                    class="dim"
                    xalign={0}
                    label={createBinding(panelPlayer, "artist")((artist) => artist || "Unknown artist")}
                    maxWidthChars={30}
                    ellipsize={3}
                  />
                  <box class="media-controls" spacing={4}>
                    <button
                      tooltipText="Previous"
                      visible={createBinding(panelPlayer, "canGoPrevious")}
                      onClicked={() => panelPlayer.previous()}
                    >
                      <label label="󰒮" />
                    </button>
                    <button
                      tooltipText="Play / pause"
                      visible={createBinding(panelPlayer, "canControl")}
                      onClicked={() => panelPlayer.play_pause()}
                    >
                      <label
                        label={createBinding(panelPlayer, "playbackStatus")((status) =>
                          status === Mpris.PlaybackStatus.PLAYING ? "󰏤" : "󰐊",
                        )}
                      />
                    </button>
                    <button
                      tooltipText="Next"
                      visible={createBinding(panelPlayer, "canGoNext")}
                      onClicked={() => panelPlayer.next()}
                    >
                      <label label="󰒭" />
                    </button>
                  </box>
                </box>
              </box>
            )}
          </For>
        </box>
      </popover>
    </menubutton>
  )
}

export default function Media() {
  return (
    <box class="media-slot">
      <For each={players}>
        {(player) => <MediaButton player={player} />}
      </For>
    </box>
  )
}
