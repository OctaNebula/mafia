local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local services = ServerStorage.server.services
local pointingService = require(services.pointingService)

local votingManager = {
    connections = {},
    skipVotes = {},
    votes = {},

    properties = {},
    events = {},
}

function votingManager.init(gameService)
    votingManager.properties.canSkipVote = gameService.client.canSkipVote
    votingManager.properties.canVote = gameService.client.canVote
    votingManager.events.votePlayer = gameService.client.votePlayer
    votingManager.events.skipVote = gameService.client.skipVote
end

function votingManager.startVoting(players, skipTimer)
    votingManager.votes = {}
    votingManager.skipVotes = {}
    votingManager.clearConnections()

    local voteSkipped = Instance.new("BindableEvent")

    votingManager.properties.canSkipVote:set(true)
    votingManager.properties.canVote:set(true)
    pointingService.setCanPointArm:Fire(true)

    votingManager.connections.vote = votingManager.events.votePlayer:connect(function(player, targetVote)
        if not votingManager.isValidVote(player, targetVote, players) then
            return
        end
        votingManager.votes[player.UserId] = targetVote.UserId
    end)

    if skipTimer then
        local skipped = false
        votingManager.connections.skip = votingManager.events.skipVote:connect(function(player)
            if table.find(votingManager.skipVotes, player.UserId) then
                return
            end
            table.insert(votingManager.skipVotes, player.UserId)

            -- Check for majority skip vote
            if #votingManager.skipVotes > #players/2 then
                skipped = true
                votingManager.finishVoting()
            end
        end)

        task.delay(skipTimer, function()
            if not skipped and votingManager.connections.skip then
                votingManager.properties.canSkipVote:set(false)
                votingManager.connections.skip:Disconnect()
                votingManager.connections.skip = nil
            end
        end)
    end

    return voteSkipped
end

function votingManager.finishVoting()
    votingManager.properties.canSkipVote:set(false)
    votingManager.properties.canVote:set(false)
    pointingService.setCanPointArm:Fire(false)
    votingManager.clearConnections()
end

function votingManager.isValidVote(voter, target, validPlayers)
    return table.find(validPlayers, voter)
        and table.find(validPlayers, target)
        and not votingManager.votes[voter.UserId]
end

function votingManager.tallyVotes()
    local talliedVotes = {}
    local mostVotes = {
        count = 0,
        players = {}
    }

    -- Count votes
    for _, votedId in votingManager.votes do
        talliedVotes[votedId] = (talliedVotes[votedId] or 0) + 1

        if talliedVotes[votedId] > mostVotes.count then
            mostVotes.count = talliedVotes[votedId]
            mostVotes.players = {Players:GetPlayerByUserId(votedId)}
        elseif talliedVotes[votedId] == mostVotes.count then
            table.insert(mostVotes.players, Players:GetPlayerByUserId(votedId))
        end
    end

    return {
        votes = talliedVotes,
        mostVoted = mostVotes,
        skips = #votingManager.skipVotes
    }
end

function votingManager.clearConnections()
    for _, connection in votingManager.connections do
        connection:Disconnect()
    end
    votingManager.connections = {}
end

return votingManager