local Waypoints = {}

function UpdateWaypointPosition(index, scaleX, scaleY, distanceText, settings)
    SendNUIMessage({
        type = "updateWaypointPosition",
        index = index,
        scaleX = scaleX,
        scaleY = scaleY,
        distanceText = distanceText,
        color = settings.color
    })
end

function GetDistanceText(meters)
    if Config.UseImperial then 
        local feet = math.floor(meters * 3.28084)
        if feet < 500 then 
            return feet .. " ft"
        else 
            return round(meters * 0.000621371, 1) .. "mi"
        end
    else 
        if meters < 1000 then 
            return meters .. "m"
        else 
            return round(meters / 1000, 1) .. "km"
        end
    end
end

function RemoveWaypoint(index)
    if Waypoints[index].blip then 
        RemoveBlip(Waypoints[index].blip)
    end
    Waypoints[index] = nil
    SendNUIMessage({
        type = "removeWaypoint",
        index = index
    })
end

function AddWaypoint(label, coords, settings)
    local index = nil
    local settings = settings or {}
    repeat
        index = math.random(1, 999999) .. "_" .. math.random(1, 999999)
    until not Waypoints[index]
    Waypoints[index] = {
        label = label,
        coords = coords,
        icon = settings.icon or Config.WaypointSettings.icon,
        color = settings.color or Config.WaypointSettings.color,
        clearEnter = settings.clearEnter,
    }
    if settings.blipId ~= nil then 
        Waypoints[index].blip = CreateBlip({
            label = label,
            coords = coords,
            id = settings.blipId,
            color = settings.blipColor
        })
    end
    SendNUIMessage({
        type = "addWaypoint",
        index = index,
        label = label,
        icon = settings.icon or Config.WaypointSettings.icon,
        color = settings.color or Config.WaypointSettings.color
    })
    return index
end

function GetWaypoint(index)
    return Waypoints[index]
end

function UpdateWaypointCoords(index, coords)
    Waypoints[index].coords = coords
end

function UpdateWaypointSettings(index, settings)
    Waypoints[index].icon = settings.icon or Config.WaypointSettings.icon
    Waypoints[index].color = settings.color or Config.WaypointSettings.color
    SendNUIMessage({
        type = "updateWaypointSettings",
        index = index,
        icon = settings.icon or Config.WaypointSettings.icon,
        color = settings.color or Config.WaypointSettings.color
    })
end

function OpenAdminWaypointMenu() 
    local coords = GetSetWaypoint()
    if not coords then 
        return ShowNotification(_L("no_waypoint"))
    end
    local input = lib.inputDialog(_L("admin_title"), {
        {type = 'input', label = _L("admin_label"), default=_L("admin_label_default"), required = true},
        {type = 'input', label = _L("admin_target"), description = _L("admin_target_desc"), default=_L("admin_target_default"), required = true},
        {type = 'number', label = _L("admin_blip"), default=38, min=0, required = true},
        {type = 'number', label = _L("admin_blip_color"), default=0, min=0, required = true},
        {type = 'input', label = _L("admin_icon"), description = _L("admin_icon_desc"), default="default", required = true},
        {type = 'color', format = "rgba", label = _L("admin_color"), default = GetColorString(Config.WaypointSettings.color)},
        {type = 'checkbox', label = _L("admin_clear_enter"), checked=true},
    })
    if not input then return end
    local rgb = lib.math.torgba(input[6])
    if input[5] == "default" then input[5] = nil end
    SetWaypointOff()
    TriggerServerEvent("pickle_waypoints:sendAdminWaypoint", 
        coords, 
        input[1], input[2], input[3], input[4], input[5], {math.ceil(rgb.x), math.ceil(rgb.y), math.ceil(rgb.z), math.ceil(rgb.w * 255)}, input[7]
    )
end

CreateThread(function()
    Wait(1000)
    local settings = {
        color = Config.WaypointSettings.color
    }
    while true do
        local wait = 1000
        local pcoords = GetEntityCoords(PlayerPedId())
        for k,v in pairs(Waypoints) do
            wait = 10
            targetCoords = v.coords
            RequestAdditionalCollisionAtCoord(targetCoords.x, targetCoords.y, targetCoords.z)
            local _, z = GetGroundZFor_3dCoord(targetCoords.x, targetCoords.y, 10000.0, false)
            if #(vector3(targetCoords.x, targetCoords.y, z) - targetCoords) > 1.0 then 
                targetCoords = vector3(targetCoords.x, targetCoords.y, z)
                UpdateWaypointCoords(k, targetCoords)
            end
            local onScreen, scaleX, scaleY = GetScreenCoordFromWorldCoord(targetCoords.x, targetCoords.y, targetCoords.z + 5.0)
            local dist = #(targetCoords-pcoords)
            local meters = math.ceil(dist * 1)
            local cameraRotation = GetGameplayCamRot(2)
            if not onScreen then 
                onScreen, scaleX, scaleY = GetHudScreenPositionFromWorldPosition(targetCoords.x, targetCoords.y, targetCoords.z + 5.0)
                scaleX = lerp(-0.1, 1.1, scaleX)
                scaleY = lerp(-0.1, 1.1, scaleY)
            end
            UpdateWaypointPosition(k, scaleX, scaleY, GetDistanceText(meters), settings)
        end
        Wait(wait)
    end
end)

CreateThread(function()
    Wait(1000)
    while true do
        local wait = 1000
        local pcoords = GetEntityCoords(PlayerPedId())
        for k,v in pairs(Waypoints) do
            local targetCoords = v.coords
            local dist = #(targetCoords-pcoords)
            local color = v.color

            if dist < Config.RenderDistance then 
                wait = 0
                DrawMarker(1, targetCoords.x, targetCoords.y, targetCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 5.0, color[1], color[2], color[3], color[4], false, true, 2, false, false, false, false)
                if dist < Config.EnterDistance and v.clearEnter then 
                    RemoveWaypoint(k)
                end
            end
        end
        Wait(wait)
    end
end)

RegisterNetEvent("pickle_waypoints:addWaypoint", function(label, coords, settings)
    AddWaypoint(label, coords, settings)
end)

RegisterNetEvent("pickle_waypoints:adminWaypointMenu", function()
    OpenAdminWaypointMenu()
end)

RegisterNetEvent(GetCurrentResourceName()..":showNotification", function(message)
    ShowNotification(message)
end)

RegisterCommand("clearwaypoints", function()
    for k,v in pairs(Waypoints) do
        RemoveWaypoint(k)
    end
    ShowNotification(_L("waypoints_cleared"))
end)

exports("AddWaypoint", AddWaypoint)
exports("RemoveWaypoint", RemoveWaypoint)
exports("GetWaypoint", GetWaypoint)
exports("UpdateWaypointCoords", UpdateWaypointCoords)
exports("UpdateWaypointSettings", UpdateWaypointSettings)