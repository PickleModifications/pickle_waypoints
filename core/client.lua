function CreateBlip(data)
    local x,y,z = table.unpack(data.coords)
    local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, data.id or 1)
    SetBlipDisplay(blip, data.display or 4)
    SetBlipScale(blip, data.scale or 1.0)
    SetBlipColour(blip, data.color or 1)
    if (data.rotation) then 
        SetBlipRotation(blip, math.ceil(data.rotation))
    end
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(data.label)
    EndTextCommandSetBlipName(blip)
    return blip
end