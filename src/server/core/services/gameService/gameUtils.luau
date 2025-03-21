local Players = game:GetService("Players")

local gameUtils = {}

function gameUtils.countdownCoroutineInit(seconds, increment, callback, cleanup, propertyCheck)
    local currentSecond
    local coro = coroutine.create(function()
        for i = seconds, 0, -increment do
            currentSecond = i
            if not propertyCheck:get() then break end
            if callback then task.spawn(callback, i) end
            task.wait(increment)
        end
        if cleanup then cleanup(false) end
    end)
    coroutine.resume(coro)
    
    return function()
        if coroutine.status(coro) == "dead" then return -1 end
        coroutine.close(coro)
        if cleanup then cleanup(true) end
        return currentSecond
    end
end

function gameUtils.getPlayers(allPlayersInfo, filterCallback)
    local players = {}
    for userId, playerInfo in allPlayersInfo do
        if filterCallback(userId, playerInfo) then
            table.insert(players, Players:GetPlayerByUserId(userId))
        end
    end
    return players
end

return gameUtils