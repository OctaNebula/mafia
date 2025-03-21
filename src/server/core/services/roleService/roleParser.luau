local Players = game:GetService("Players")

function roleParser(newPlayersInfo, oldPlayersInfo, callback)
    local playersToRemove = {}
    local playersToAdd = {}
    for userId, playerInfo in newPlayersInfo do
        if not callback(userId, playerInfo) then
            continue
        end
        local player = Players:GetPlayerByUserId(userId)
        table.insert(playersToAdd, player)
    end
    if not oldPlayersInfo then
        return playersToAdd, {}
    end
    for userId, playerInfo in oldPlayersInfo do
        if not callback(userId, playerInfo) then
            continue
        end
        local player = Players:GetPlayerByUserId(userId)
        if table.find(playersToAdd, player) then
            continue
        end
        table.insert(playersToRemove, player)
    end
    return playersToAdd, playersToRemove
end

return roleParser