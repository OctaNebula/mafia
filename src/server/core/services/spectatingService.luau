local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local sharedPackages = ReplicatedStorage.sharedPackages

local network = require(sharedPackages.network)
local Signal = require(sharedPackages.Signal)

local services = ServerStorage.server.services

local spectators = {}
local spectatableTargets = {}

local spectatingService = {
    addSpectatorSignal = Signal.new(),
    removeSpectatorSignal = Signal.new(),
    removeAllSpectatorsSignal = Signal.new(),
    client = {
        spectatableTargets = network.Server.RemoteProperty.new(nil),
    }
}

function spectatingService.start()
    local gameService = require(services.gameService)
    gameService.playersInfo:observe(function(newPlayersInfo)
        if not newPlayersInfo then
            spectatingService.removeAllSpectators()
            spectatableTargets = {}
            return
        end
        local newSpectatableTargets = {}
        for userId, playerInfo in newPlayersInfo do
            if playerInfo.alive then
                table.insert(newSpectatableTargets, userId)
            end
        end
        spectatableTargets = newSpectatableTargets
        spectatingService.client.spectatableTargets:setForClients(spectators, table.clone(newSpectatableTargets))
    end)

    Players.PlayerRemoving:Connect(spectatingService.removeSpectator)

    spectatingService.addSpectatorSignal:Connect(spectatingService.addSpectator)
    spectatingService.removeSpectatorSignal:Connect(spectatingService.removeSpectator)
    spectatingService.removeAllSpectatorsSignal:Connect(spectatingService.removeAllSpectators)
end

function spectatingService.addSpectator(player)
    spectatingService.client.spectatableTargets:setForClient(player, table.clone(spectatableTargets))
    table.insert(spectators, player)
end

function spectatingService.removeSpectator(player)
    spectatingService.client.spectatableTargets:setForClient(player, nil)
    table.remove(spectators, table.find(spectators, player))
end

function spectatingService.removeAllSpectators()
    spectatingService.client.spectatableTargets:setForClients(spectators, nil)
    spectators = {}
end

return spectatingService