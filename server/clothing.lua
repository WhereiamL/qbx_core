-- Trajno čuvanje obučene item-odjeće (metadata 'wornClothing') + reapply na loginu.

RegisterNetEvent('qbx_core:server:syncClothing', function(list)
    local src = source
    if type(list) ~= 'table' then return end
    local player = exports.qbx_core:GetPlayer(src)
    if player then
        player.Functions.SetMetaData('wornClothing', list)
    end
end)

RegisterNetEvent('qbx_core:server:requestClothing', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local list = player and player.PlayerData.metadata.wornClothing or {}
    TriggerClientEvent('qbx_core:client:reapplyClothing', src, list)
end)
