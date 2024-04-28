Config = {}

Config.Language = "en" -- Language to use.

Config.UseImperial = true -- Use imperial units (feet/miles) instead of metric units (meters/kilometers).

Config.RenderDistance = 300.0 -- When to render markers from waypoints.

Config.EnterDistance = 5.0 -- Distance from the waypoint to trigger the clear event (used when enabled for admin waypoints).

Config.WaypointSettings = { -- These are the default settings for the waypoint display. Players can change them on their end using the /waypointsettings command.
    icon = nil, -- Icon to use for the waypoint marker, set to nil to use the built-in waypoint icon. Using alternative images will prevent the color from being applied.
    enabled = true, -- Enable waypoint display.
    color = {255, 255, 255, 200}, -- Color of the waypoint marker.
}

Config.AdminWaypointPermissions = { -- These are the permissions required to set a waypoint for another player.
    jobs = {["eventmanager"] = 0}, -- Jobs that can set waypoints for other players.
    groups = {"admin", "god"}, -- Groups that can set waypoints for other players.
    ace = {"pickle_waypoints.set"} -- ACE permissions that can set waypoints for other players.
}