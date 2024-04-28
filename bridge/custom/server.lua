if GetResourceState('es_extended') == 'started' then return end
if GetResourceState('qb-core') == 'started' then return end

function ShowNotification(target, text)
	TriggerClientEvent(GetCurrentResourceName()..":showNotification", target, text)
end

function CheckPermission(source, permission)
    for i=1, #permission.ace do 
        if IsPlayerAceAllowed(source, permission.ace[i]) then 
            return true 
        end
    end
end