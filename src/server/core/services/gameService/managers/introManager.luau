local Players = game:GetService("Players")

local introManager = {
    connections = {},
    properties = {},
    events = {}
}

function introManager.init(gameService)
    introManager.properties.introSkippedInfo = gameService.client.introSkippedInfo
    introManager.properties.introSkipped = gameService.client.introSkipped

    introManager.events.introCompleted = gameService.client.introCompleted
    introManager.events.explainRules = gameService.client.explainRules
    introManager.events.skipIntro = gameService.client.skipIntro
end

function introManager.playIntro(assignedRoles)
    local numberOfPlayers = 0
    for _, _ in assignedRoles do
        numberOfPlayers += 1
    end
    -- Reset intro state
    introManager.properties.introSkipped:set(false)
    introManager.properties.introSkippedInfo:set({
        playersSkippedIntro = 0,
        participatingPlayers = numberOfPlayers
    })
    
    -- Send role explanations
    for userId, playerInfo in assignedRoles do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            introManager.events.explainRules:fireClient(player, playerInfo.role)
        end
    end
    
    -- Track ready and skip states
    local readyPlayers = {}
    local skippedPlayers = {}
    
    introManager.connections.completed = introManager.events.introCompleted:connect(function(player)
        if assignedRoles[player.UserId] and not table.find(readyPlayers, player.UserId) then
            table.insert(readyPlayers, player.UserId)
        end
    end)
    
    introManager.connections.skipped = introManager.events.skipIntro:connect(function(player)
        if assignedRoles[player.UserId] and not table.find(skippedPlayers, player.UserId) then
            table.insert(skippedPlayers, player.UserId)
            introManager.properties.introSkippedInfo:set({
                playersSkippedIntro = #skippedPlayers,
                participatingPlayers = numberOfPlayers
            })
            
            -- Check for majority skip
            if #skippedPlayers >= numberOfPlayers * (2/3) then
                introManager.properties.introSkipped:set(true)
            end
        end
    end)
    
    -- Wait for all players
    while #readyPlayers < numberOfPlayers and introManager.properties.introSkipped:get() ~= true do
        task.wait()
    end
    
    introManager.clearConnections()
end

function introManager.clearConnections()
    for _, connection in introManager.connections do
        connection:Disconnect()
    end
    introManager.connections = {}
end

return introManager