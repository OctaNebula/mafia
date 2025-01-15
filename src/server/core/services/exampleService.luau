local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Players = game:GetService("Players")

local sharedPackages = ReplicatedStorage.sharedPackages

-- Networking handling package
local network = require(sharedPackages.network)
-- Get other services by requiring them.
-- local gameService = require(script.Parent.gameService)

local exampleService = {
    -- Anything in the client table is accessible to the client.
    client = {
        exampleEvent = network.Server.RemoteSignal.new()
    }
}

local SOME_DATA = {
    Level = 1,
    Color = 2
}

-- Modules are given a start method that is run.
function exampleService.start()
    -- Players.PlayerAdded:Connect(function(player)
    --     exampleService.client.exampleEvent:fireClient(player)

    --     -- Need to waitForPlayerState incase state hasn't been created yet
    --     --  (this is mostly only needed inside of PlayerAdded)
    --     local playerState = playerStateService.waitForPlayerState(player)
    --     if playerState then
    --         playerState.exampleState = true
    --         -- Must setPlayerState after each change for it to apply
    --         playerStateService.setPlayerState(player, playerState)
    --     end
    -- end)
end

-- Make server functions that are accessible to the client like this
function exampleService.client.exampleMethod()
    return `Here's some data from the server: {SOME_DATA}`
end

return exampleService