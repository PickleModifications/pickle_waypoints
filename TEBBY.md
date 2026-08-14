# TEBBY.md - pickle_waypoints

## Overview

`pickle_waypoints` is a lightweight FiveM (GTA V multiplayer) resource that adds a
custom HUD waypoint display. It renders waypoint markers on-screen (as NUI overlay
icons with distance labels) and as in-world 3D markers. It supports personal
waypoints that mirror the player's in-game map waypoint, and admin-dispatched
waypoints that can target a single player or all players at once. Other resources
can create and manage waypoints through the exported Lua API.

## Code design

The resource follows the standard Pickle Mods bridge pattern used across the
pickle_* product family:

- **Framework bridge** (`bridge/<framework>/`): Each bridge file early-returns if its
  framework is not running, so all three bridge files (ESX, QBCore, custom) are
  loaded by `fxmanifest.lua` and only one becomes active. The bridge exposes
  `ShowNotification(text)` on the client and `ShowNotification(target, text)` +
  `CheckPermission(source, permissionTable)` on the server.

- **Locale system** (`locales/`): `locale.lua` defines `_L(name, ...)` which looks up
  a string in `Language[Config.Language]`. Translation tables live in
  `locales/translations/*.lua`. Missing keys return `"ERR_TRANSLATE_<name>_404"`.

- **Config** (`config.lua`): Single shared config table (`Config`). Settings cover
  language, unit system (imperial/metric), render/enter distances, default waypoint
  appearance, and the permission table for admin waypoints.

- **Core utilities** (`core/shared.lua`, `core/client.lua`): Shared math helpers
  (`v3`, `lerp`, `GetRandomInt`, `round`) and a client-side `CreateBlip` helper.

- **Waypoint engine** (`modules/main/client.lua`): Owns the `Waypoints` table.
  Two always-running threads update all active waypoints every tick:
  1. Position thread (10 ms when waypoints exist, 1 s idle): projects world coords to
     screen space with `GetScreenCoordFromWorldCoord` / `GetHudScreenPositionFromWorldPosition`,
     sends NUI messages of type `updateWaypointPosition`.
  2. Marker thread (0 ms when in render range, 1 s idle): calls `DrawMarker` at each
     waypoint and auto-removes waypoints with `clearEnter = true` when the player
     walks within `Config.EnterDistance`.
  Public functions exported for other resources: `AddWaypoint`, `RemoveWaypoint`,
  `GetWaypoint`, `UpdateWaypointCoords`, `UpdateWaypointSettings`.

- **Player waypoint listener** (`modules/waypoint/client.lua`): Polls the GTA map
  waypoint blip (blip type 8) every second. When a waypoint is set and
  `WaypointSettings.enabled` is true it creates a managed waypoint; when the map
  waypoint is cleared it removes it. Player preferences (color, enabled state) are
  persisted with `SetResourceKvp` / `GetResourceKvpString` under the key
  `pickle_waypoints:settings`. Exposes `/waypointsettings` command via `ox_lib`
  input dialog.

- **Admin waypoint** (`modules/main/server.lua` + `modules/main/client.lua`):
  The `/adminwaypoint` server command opens an `ox_lib` input dialog on the
  triggering client. The client fires `pickle_waypoints:sendAdminWaypoint` to the
  server which permission-checks the sender and then fires
  `pickle_waypoints:addWaypoint` to the target client(s).

- **NUI** (`nui/`): A minimal HTML/CSS/JS overlay. `main.js` receives NUI messages
  (`addWaypoint`, `removeWaypoint`, `updateWaypointPosition`, `updateWaypointSettings`)
  and renders waypoint icons (inline SVG colored via CSS `color`) with screen-space
  `left`/`top` positioning and a distance label.

## Important files

| Path | Purpose |
|---|---|
| `fxmanifest.lua` | FiveM manifest — declares all script/file lists, `lua54 'yes'`, and the NUI page |
| `config.lua` | All operator-editable settings (language, distances, default waypoint look, admin permission table) |
| `locales/locale.lua` | `_L()` helper; do not edit |
| `locales/translations/en.lua` | English strings; copy to add a new language |
| `core/shared.lua` | Shared math utilities (`v3`, `lerp`, `round`, `GetRandomInt`) |
| `core/client.lua` | Client-only `CreateBlip` helper |
| `modules/main/client.lua` | Core waypoint engine: `Waypoints` table, render threads, public exports, net event handlers, `/clearwaypoints` command |
| `modules/main/server.lua` | Server side: `sendAdminWaypoint` net event, `/adminwaypoint` command, permission checking |
| `modules/waypoint/client.lua` | Personal map-waypoint listener, KVP-backed settings persistence, `/waypointsettings` command |
| `bridge/esx/client.lua` | ESX client bridge (`ShowNotification`) |
| `bridge/esx/server.lua` | ESX server bridge (`ShowNotification`, `CheckPermission` with job/group/ACE) |
| `bridge/qb/client.lua` | QBCore client bridge |
| `bridge/qb/server.lua` | QBCore server bridge (`CheckPermission` with job/group/ACE) |
| `bridge/custom/client.lua` | Fallback client bridge (plain GTA notification) |
| `bridge/custom/server.lua` | Fallback server bridge (ACE-only permission check) |
| `nui/index.html` | NUI shell — loads `main.js` and `main.css` |
| `nui/assets/js/main.js` | NUI logic — receives messages from Lua and manipulates DOM waypoint elements |
| `nui/assets/css/main.css` | NUI styling for the waypoints container and individual waypoint elements |

## Intended behaviors

- **All bridge files load simultaneously**: `fxmanifest.lua` globs
  `bridge/**/**/client.lua` and `bridge/**/**/server.lua`. Each file starts with
  a guard (`if GetResourceState(...) ~= 'started' then return end` or its inverse).
  This means all three bridge files are always included; only one survives past its
  guard. This is **not a bug** — it is the standard Pickle Mods bridge pattern.

- **Random waypoint index**: `AddWaypoint` generates its index by concatenating two
  `math.random(1, 999999)` calls. The collision loop (`repeat ... until not
  Waypoints[index]`) is deliberate — it guarantees a unique key without requiring a
  sequential counter.

- **Ground-snapping**: The position thread calls `GetGroundZFor_3dCoord` to snap
  waypoints to terrain. If the snapped Z differs from the stored Z by more than 1.0
  the stored coords are updated via `UpdateWaypointCoords`. This is intentional
  terrain-following, not a coordinate drift bug.

- **`clearEnter` auto-removal**: When an admin dispatches a waypoint with the
  "Clear waypoint upon arrival?" checkbox ticked, the marker thread calls
  `RemoveWaypoint` as soon as the player enters `Config.EnterDistance`. This is
  intended behavior, not a race condition.

- **Custom bridge ACE-only**: `bridge/custom/server.lua` only checks ACE permissions
  (`permission.ace`); it does not check jobs or groups. When neither ESX nor QBCore
  is running this is the expected minimal fallback.

- **No server-side Waypoints table persistence**: `Waypoints = {}` in
  `modules/main/server.lua` is declared but never populated server-side; waypoint
  state lives entirely on each client. The server only routes events.

## Common issues & fixes

| Symptom | Likely cause | Fix |
|---|---|---|
| Locale strings show as `ERR_TRANSLATE_<key>_404` | `Config.Language` does not match the key in `locales/translations/en.lua` (`Language["en"]`), or the resource folder is mis-named (e.g. `pickle_waypoint` instead of `pickle_waypoints`) | Confirm resource folder name matches `ensure` line; confirm `Config.Language = "en"` |
| `/adminwaypoint` command gives "no permission" | Caller's job/group/ACE is not in `Config.AdminWaypointPermissions` | Add the job, group name, or ACE string to `config.lua` |
| Waypoints visible but distance text wrong units | `Config.UseImperial` is set to the wrong value | Set `Config.UseImperial = false` for metres/km |
| Personal waypoint doesn't appear | `WaypointSettings.enabled` was saved as `false` via `/waypointsettings` and persisted in KVP | Player runs `/waypointsettings` and re-enables, or server clears the KVP |
| NUI waypoint icon has no color applied | A custom `icon` URL was provided; the SVG color tinting only works with the built-in SVG (`icon = nil`) | Use `nil` for the icon field or style the custom image independently |
| `ox_lib` not found errors on start | `ox_lib` is not started before `pickle_waypoints` | Ensure `ensure ox_lib` appears before `ensure pickle_waypoints` in `server.cfg` |
| Admin waypoint dialog never opens | `ox_lib` missing or `pickle_waypoints:adminWaypointMenu` net event not reaching client | Check `ox_lib` is running; check for Lua errors in server console |

## Conventions

- **Lua 5.4** (`lua54 'yes'` in manifest). Use `<const>` and `<close>` where appropriate; avoid 5.1-only idioms.
- **Tables over OOP**: State is kept in plain Lua tables (`Waypoints`, `Config`, `Language`). No class/metatables.
- **Global functions**: Bridge functions (`ShowNotification`, `CheckPermission`) and core helpers (`AddWaypoint`, `RemoveWaypoint`, etc.) are declared as globals, not `local`. This is intentional to allow cross-file calls without `exports` overhead.
- **NUI messaging**: All Lua→NUI communication uses `SendNUIMessage({type = "...", ...})`. The `type` field must match a handler in `main.js`. Add new message types in both places.
- **Locale keys**: snake_case strings (`"waypoints_cleared"`, `"no_permission"`). Placeholders use `%s` / `%d` via `string.format`.
- **Config keys**: PascalCase under the `Config` table (`Config.UseImperial`, `Config.RenderDistance`). Sub-tables also PascalCase (`Config.WaypointSettings`, `Config.AdminWaypointPermissions`).
- **Net event names**: prefixed with `pickle_waypoints:` (e.g. `pickle_waypoints:addWaypoint`).
- **File structure**: new game features go in `modules/<feature>/client.lua` and/or `modules/<feature>/server.lua`; the manifest glob picks them up automatically.
- **Bridge guard pattern**: every bridge file must early-return if its framework is not active, matching the existing `if GetResourceState(...) then return end` style.
