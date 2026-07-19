import Battery from "gi://AstalBattery"
import Bluetooth from "gi://AstalBluetooth"
import GLib from "gi://GLib"
import Network from "gi://AstalNetwork"
import PowerProfiles from "gi://AstalPowerProfiles"
import Wp from "gi://AstalWp"
import Gtk from "gi://Gtk?version=4.0"
import type { Accessor } from "ags"
import { createBinding, createComputed, For, onCleanup, With } from "ags"
import { execAsync } from "ags/process"
import { createPoll } from "ags/time"

const network = Network.get_default()
const bluetooth = Bluetooth.get_default()
const battery = Battery.get_default()
const powerProfiles = PowerProfiles.get_default()

function safeExec(command: string | string[]) {
  execAsync(command).catch((error) => console.error(error))
}

export function NetworkStatus() {
  const wifi = createBinding(network, "wifi")

  return (
    <box visible={wifi(Boolean)}>
      <With value={wifi}>
        {(device) =>
          device && (
            <menubutton class="network" tooltipText="Network">
              <box spacing={7}>
                <image iconName={createBinding(device, "iconName")} />
                <label
                  label={createBinding(device, "ssid")((ssid) => ssid || "Offline")}
                  maxWidthChars={16}
                  ellipsize={3}
                />
              </box>
              <popover>
                <box class="popover-content network-panel" orientation={Gtk.Orientation.VERTICAL} spacing={7}>
                  <box spacing={8}>
                    <label class="panel-title" label="Wi-Fi" hexpand xalign={0} />
                    <switch
                      active={createBinding(device, "enabled")}
                      onStateSet={(_switch, state: boolean) => {
                        device.enabled = state
                        return false
                      }}
                    />
                  </box>
                  <button onClicked={() => device.scan()}>
                    <label label="󰑐  Scan for networks" xalign={0} />
                  </button>
                  <box class="network-list" orientation={Gtk.Orientation.VERTICAL} spacing={3}>
                    <For
                      each={createBinding(device, "accessPoints")((points: Network.AccessPoint[]) =>
                        points
                          .filter((point) => Boolean(point.ssid))
                          .sort((a, b) => b.strength - a.strength)
                          .slice(0, 10),
                      )}
                    >
                      {(point: Network.AccessPoint) => (
                        <button
                          tooltipText="Connect; secured new networks may open the connection editor"
                          onClicked={() => {
                            if (point.requiresPassword && point.get_connections().length === 0) {
                              safeExec("nm-connection-editor")
                              return
                            }
                            point.activate(null, null)
                          }}
                        >
                          <box spacing={8}>
                            <image iconName={createBinding(point, "iconName")} />
                            <label label={point.ssid || "Hidden network"} xalign={0} hexpand />
                            <label label={`${point.strength}%`} class="dim" />
                            <label
                              label="󰌾"
                              visible={point.requiresPassword}
                              class="dim"
                            />
                          </box>
                        </button>
                      )}
                    </For>
                  </box>
                  <button onClicked={() => safeExec("nm-connection-editor")}>
                    <label label="󰒓  Advanced network settings" xalign={0} />
                  </button>
                </box>
              </popover>
            </menubutton>
          )
        }
      </With>
    </box>
  )
}

export function BluetoothStatus() {
  const devices = createBinding(bluetooth, "devices")
  const connected = createBinding(bluetooth, "isConnected")
  const powered = createBinding(bluetooth, "isPowered")
  const icon = createComputed(() => {
    if (connected()) return "󰂱"
    return powered() ? "󰂯" : "󰂲"
  })
  const status = createComputed(() => {
    if (connected()) return "Bluetooth connected"
    return powered() ? "Bluetooth disconnected" : "Bluetooth off"
  })

  return (
    <menubutton
      class={connected((value) =>
        value ? "bluetooth connected" : "bluetooth disconnected",
      )}
      tooltipText={status}
    >
      <label label={icon} />
      <popover>
        <box class="popover-content bluetooth-panel" orientation={Gtk.Orientation.VERTICAL} spacing={7}>
          <box spacing={8}>
            <label class="panel-title" label="Bluetooth" xalign={0} hexpand />
            <switch
              active={powered}
              onStateSet={() => {
                bluetooth.toggle()
                return false
              }}
            />
          </box>
          <box orientation={Gtk.Orientation.VERTICAL} spacing={3}>
            <For each={devices}>
              {(device) => (
                <button
                  onClicked={() => {
                    const action = device.connected
                      ? device.disconnect_device()
                      : device.connect_device()
                    action.catch(console.error)
                  }}
                >
                  <box spacing={8}>
                    <image iconName={device.icon || "bluetooth-symbolic"} />
                    <label label={device.alias} xalign={0} hexpand />
                    <label
                      class={createBinding(device, "connected")((value) =>
                        value ? "connected" : "dim",
                      )}
                      label={createBinding(device, "connected")((value) =>
                        value ? "Connected" : "Connect",
                      )}
                    />
                  </box>
                </button>
              )}
            </For>
          </box>
          <button onClicked={() => safeExec("blueman-manager")}>
            <label label="󰒓  Open Bluetooth settings" xalign={0} />
          </button>
        </box>
      </popover>
    </menubutton>
  )
}

function AudioDevice({
  speaker,
  speakers,
}: {
  speaker: Wp.Endpoint
  speakers: Accessor<Wp.Endpoint[]>
}) {
  const volume = createBinding(speaker, "volume")
  const muted = createBinding(speaker, "mute")
  const routes = createBinding(speaker, "routes")((items) => items || [])
  const activeRoute = createBinding(speaker, "route")

  return (
    <menubutton class="audio" tooltipText="Audio">
      <box spacing={7}>
        <image iconName={createBinding(speaker, "volumeIcon")} />
        <label label={volume((value) => `${Math.round(value * 100)}%`)} />
      </box>
      <popover>
        <box class="popover-content audio-panel" orientation={Gtk.Orientation.VERTICAL} spacing={9}>
          <label class="panel-title" label="Audio" xalign={0} />
          <box spacing={8}>
            <button
              class={muted((value) => (value ? "danger" : ""))}
              tooltipText="Toggle mute"
              onClicked={() => speaker.set_mute(!speaker.mute)}
            >
              <image iconName={createBinding(speaker, "volumeIcon")} />
            </button>
            <slider
              hexpand
              widthRequest={260}
              min={0}
              max={1.5}
              value={volume}
              onChangeValue={(_slider, _scrollType, value: number) =>
                speaker.set_volume(value)
              }
            />
            <label label={volume((value) => `${Math.round(value * 100)}%`)} />
          </box>

          <label class="panel-subtitle" label="Output device" xalign={0} />
          <box class="audio-device-list" orientation={Gtk.Orientation.VERTICAL} spacing={3}>
            <For each={speakers}>
              {(output) => {
                const selected = createBinding(output, "isDefault")
                return (
                  <button
                    class={selected((active) => (active ? "selected" : ""))}
                    onClicked={() => output.set_is_default(true)}
                  >
                    <box spacing={8}>
                      <image iconName={createBinding(output, "icon")} />
                      <label
                        label={createBinding(output, "description")((description) =>
                          description || output.name || "Audio output",
                        )}
                        xalign={0}
                        hexpand
                        maxWidthChars={34}
                        ellipsize={3}
                      />
                      <label label="󰄬" visible={selected} class="connected" />
                    </box>
                  </button>
                )
              }}
            </For>
          </box>

          <box
            class="audio-routes"
            orientation={Gtk.Orientation.VERTICAL}
            spacing={3}
            visible={routes((items) => items.length > 1)}
          >
            <label class="panel-subtitle" label="Port" xalign={0} />
            <For each={routes}>
              {(route) => {
                const selected = activeRoute(
                  (active) => active?.index === route.index,
                )
                return (
                  <button
                    class={selected((active) => (active ? "selected" : ""))}
                    onClicked={() => speaker.set_route(route)}
                  >
                    <box spacing={8}>
                      <label label={route.description || route.name} xalign={0} hexpand />
                      <label label="󰄬" visible={selected} class="connected" />
                    </box>
                  </button>
                )
              }}
            </For>
          </box>

          <button onClicked={() => safeExec("pavucontrol")}>
            <label label="󰒓  Open audio mixer" xalign={0} />
          </button>
        </box>
      </popover>
    </menubutton>
  )
}

export function AudioStatus() {
  const wp = Wp.get_default()
  const speaker = createBinding(wp, "defaultSpeaker")
  const speakers = createBinding(wp.audio, "speakers")((items) => items || [])

  return (
    <box>
      <With value={speaker}>
        {(device) =>
          device && <AudioDevice speaker={device} speakers={speakers} />
        }
      </With>
    </box>
  )
}

const BRIGHTNESS_SCRIPT = GLib.build_filenamev([
  GLib.get_home_dir(),
  ".config",
  "ags",
  "scripts",
  "monitor-brightness.sh",
])

export function BrightnessStatus({ connector }: { connector: string }) {
  let brightnessReady = false
  const brightness = createPoll(
    -1,
    2000,
    [BRIGHTNESS_SCRIPT, connector],
    (value) => {
      const parsed = Number(value.trim())
      brightnessReady = Number.isFinite(parsed) && parsed >= 0
      return brightnessReady ? parsed : -1
    },
  )
  const available = brightness((value) => value >= 0)
  let pendingUpdate = 0

  const setBrightness = (value: number) => {
    if (!brightnessReady || brightness.peek() < 0) return
    if (pendingUpdate) GLib.source_remove(pendingUpdate)
    pendingUpdate = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 150, () => {
      safeExec([
        BRIGHTNESS_SCRIPT,
        connector,
        `${Math.round(value * 100)}`,
      ])
      pendingUpdate = 0
      return GLib.SOURCE_REMOVE
    })
  }

  onCleanup(() => {
    if (pendingUpdate) GLib.source_remove(pendingUpdate)
  })

  return (
    <menubutton
      class="brightness"
      visible={available}
      tooltipText={`Brightness: ${connector}`}
    >
      <box spacing={7}>
        <label label="󰃠" />
        <label
          label={brightness((value) =>
            value < 0 ? "—" : `${Math.round(value * 100)}%`,
          )}
        />
      </box>
      <popover>
        <box class="popover-content brightness-panel" orientation={Gtk.Orientation.VERTICAL} spacing={9}>
          <label class="panel-title" label={`Brightness · ${connector}`} xalign={0} />
          <box spacing={8}>
            <label label="󰃞" />
            <slider
              hexpand
              widthRequest={260}
              min={0.01}
              max={1}
              value={brightness((value) => (value < 0 ? 0.5 : value))}
              onChangeValue={(_slider, _scrollType, value: number) =>
                setBrightness(value)
              }
            />
            <label label="󰃠" />
          </box>
        </box>
      </popover>
    </menubutton>
  )
}

export function BatteryStatus() {
  const percentage = createBinding(battery, "percentage")
  const charging = createBinding(battery, "charging")
  const activeProfile = createBinding(powerProfiles, "activeProfile")

  return (
    <menubutton
      class={percentage((value) =>
        value <= 0.15 ? "battery critical" : "battery",
      )}
      visible={createBinding(battery, "isPresent")}
      tooltipText={createBinding(battery, "state")((state) => `Battery: ${state}`)}
    >
      <box spacing={7}>
        <image iconName={createBinding(battery, "batteryIconName")} />
        <label label={percentage((value) => `${Math.round(value * 100)}%`)} />
      </box>
      <popover>
        <box class="popover-content battery-panel" orientation={Gtk.Orientation.VERTICAL} spacing={7}>
          <label class="panel-title" label="Power" xalign={0} />
          <label
            xalign={0}
            label={charging((value) => (value ? "Charging" : "On battery"))}
          />
          <label
            class="power-profile-current"
            xalign={0}
            label={activeProfile((profile) => `Active profile: ${profile}`)}
          />
          <box class="power-profile-list" orientation={Gtk.Orientation.VERTICAL} spacing={3}>
            {powerProfiles.get_profiles().map(({ profile }) => {
              const selected = activeProfile((active) => active === profile)
              return (
                <button
                  class={selected((active) => (active ? "selected" : ""))}
                  onClicked={() => powerProfiles.set_active_profile(profile)}
                >
                  <box spacing={8}>
                    <label label={profile} xalign={0} hexpand />
                    <label label="󰄬" visible={selected} class="connected" />
                  </box>
                </button>
              )
            })}
          </box>
        </box>
      </popover>
    </menubutton>
  )
}
