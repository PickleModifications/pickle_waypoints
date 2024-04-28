if GetResourceState('qb-core') ~= 'started' then return end

QBCore = exports['qb-core']:GetCoreObject()

function ShowNotification(target, text)
	TriggerClientEvent(GetCurrentResourceName()..":showNotification", target, text)
end

function CheckPermission(source, permission)
    local xPlayer = QBCore.Functions.GetPlayer(source).PlayerData
    local name = xPlayer.job.name
    local rank = xPlayer.job.grade.level
    if permission.jobs[name] and permission.jobs[name] <= rank then 
        return true
    end
    for i=1, #permission.groups do 
        if QBCore.Functions.HasPermission(source, permission.groups[i]) then 
            return true 
        end
    end
    for i=1, #permission.ace do 
        if IsPlayerAceAllowed(source, permission.ace[i]) then 
            return true 
        end
    end
end