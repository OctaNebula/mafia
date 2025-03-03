local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedPackages = ReplicatedStorage.sharedPackages

local network = require(sharedPackages.network)
local Signal = require(sharedPackages.Signal)

local effectsService = {
    playOnClient = Signal.new(),
    playOnClients = Signal.new(),
    client = {
        playEffect = network.Server.RemoteSignal.new()
    }
}

function effectsService.start()
    effectsService.playOnClient:Connect(function(player, effectToPlay, ...)
        effectsService.client.playEffect:fireClient(player, effectToPlay, ...)
    end)
    effectsService.playOnClients:Connect(function(players, effectToPlay, ...)
        effectsService.client.playEffect:fireClients(players, effectToPlay, ...)
    end)
end

return effectsService