Waypoints = {}

RegisterNetEvent("pickle_waypoints:sendAdminWaypoint", function(coords, label, target, blipId, blipColor, icon, color, clearEnter)
    local source = source
    if not CheckPermission(source, Config.AdminWaypointPermissions) then return ShowNotification(source, _L("no_permission")) end
    if tonumber(target) and tonumber(target) > 0 then
        TriggerClientEvent("pickle_waypoints:addWaypoint", tonumber(target), label, coords, {
            icon = icon,
            color = color,
            blipId = blipId,
            blipColor = blipColor,
            clearEnter = clearEnter
        })
    elseif target == "all" then
        TriggerClientEvent("pickle_waypoints:addWaypoint", -1, label, coords, {
            icon = icon,
            color = color,
            blipId = blipId,
            blipColor = blipColor,
            clearEnter = clearEnter
        })
    end
end)

RegisterCommand("adminwaypoint", function(source, args, raw)
    if not CheckPermission(source, Config.AdminWaypointPermissions) then return ShowNotification(source, _L("no_permission")) end
    TriggerClientEvent("pickle_waypoints:adminWaypointMenu", source)
end)