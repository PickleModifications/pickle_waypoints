local WaypointSettings = nil

local waypointId = nil
local waypointListenerActive = false

function GetWaypointSettings()
    return json.decode(GetResourceKvpString("pickle_waypoints:settings") or json.encode(Config.WaypointSettings))
end

WaypointSettings = GetWaypointSettings()

function SetWaypointSettings(settings)
    WaypointSettings = settings
    SetResourceKvp("pickle_waypoints:settings", json.encode(settings))
    if waypointId then
        UpdateWaypointSettings(waypointId, settings)
    end
end

function GetSetWaypoint()
    local pcoords = GetEntityCoords(PlayerPedId())
    local blip = GetFirstBlipInfoId(8)
    if blip ~= 0 then
        local coords = GetBlipInfoIdCoord(blip)
        return coords
    else
        return nil
    end
end

function StartWaypointListener()
    if waypointListenerActive then return end
    waypointListenerActive = true
    CreateThread(function()
        while waypointListenerActive do
            if waypointId then
                local waypoint = GetWaypoint(waypointId)
                local coords = GetSetWaypoint()
                if not WaypointSettings.enabled or not coords or not waypoint or #(vector3(waypoint.coords.x, waypoint.coords.y, 0.0) - vector3(coords.x, coords.y, 0.0)) > 1.0 then
                    RemoveWaypoint(waypointId)
                    waypointId = nil
                end
            else
                local coords = GetSetWaypoint()
                if coords and WaypointSettings.enabled then
                    waypointId = AddWaypoint(_L("waypoint"), coords, WaypointSettings)
                end
            end
            Wait(1000)
        end
    end)
end

function GetColorString(color)
    return "rgba(" .. color[1] .. ", " .. color[2] .. ", " .. color[3] .. ", " .. round(color[4] / 255, 2) .. ")"
end

function GetAlphaFromString(color)
    local alpha = color:match("rgba%(.+, .+, .+, (.+)%)")
    return tonumber(alpha)
end

function OpenWaypointSettings() 
    local enabled = WaypointSettings.enabled
    if enabled == nil then enabled = Config.WaypointSettings.enabled end
    local input = lib.inputDialog(_L("settings_title"), {
        {type = 'checkbox', label = _L("settings_enable"), checked = enabled},
        {type = 'color', format = "rgba", label = _L("settings_color"), default = WaypointSettings.color and GetColorString(WaypointSettings.color) or GetColorString(Config.WaypointSettings.color)},
    })
    if not input then return end    
    local enabled = input[1]
    local rgb = lib.math.torgba(input[2])
    local alpha = GetAlphaFromString(input[2])
    ShowNotification(_L("settings_saved"))
    SetWaypointSettings({
        icon = Config.WaypointSettings.icon,
        enabled = enabled,
        color = {math.ceil(rgb.x), math.ceil(rgb.y), math.ceil(rgb.z), alpha * 255}
    })
end

RegisterCommand("waypointsettings", function()
    OpenWaypointSettings()
end)

CreateThread(function()
    StartWaypointListener()
end)
