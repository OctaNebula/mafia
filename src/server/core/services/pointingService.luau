local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local sharedPackages = ReplicatedStorage.sharedPackages

local network = require(sharedPackages.network)
local Signal = require(sharedPackages.Signal)

local pointingService = {
    setCanPointArm = Signal.new(),
    setCanPointHead = Signal.new(),
    client = {
        pointHead = network.Server.RemoteSignal.new(),
        pointArm = network.Server.RemoteSignal.new(),
    }
}

function pointingService.start()
    local canPointArm = {}
    local canPointHead = {}

    Players.PlayerAdded:Connect(function(player)
        canPointArm[player] = false
        canPointHead[player] = true
    end)

    pointingService.setCanPointArm:Connect(function(newCanPointArm, players: {Player}?)
        if players then
            for _, player in players do
                canPointArm[player] = newCanPointArm
            end
        else
            for player, _ in canPointArm do
                canPointArm[player] = newCanPointArm
            end
        end
        task.wait()
        for _, player in players or Players:GetPlayers() do
            if canPointArm[player] then
                continue
            end
            -- set arms to default c0
            pointingService.pointArm(
                player,
                CFrame.new(1, 0.563, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
                CFrame.new(0, -0.334, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
                1
            )
        end
    end)

    pointingService.setCanPointHead:Connect(function(newCanPointHead, players: {Player}?)
        if players then
            for _, player in players do
                canPointHead[player] = newCanPointHead
            end
        else
            for player, _ in canPointHead do
                canPointHead[player] = newCanPointHead
            end
        end
        task.wait()
        for _, player in players or Players:GetPlayers() do
            if canPointHead[player] then
                continue
            end
            local character = player.Character
            if character then
                character.Head.Neck.C0 = CFrame.new(0, 0.8, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
            end
        end
    end)

    pointingService.client.pointHead:connect(function(player, targetC0, lerpValue)
        if not canPointHead[player] then
            return
        end
        local character = player.Character
        if not character then
            return
        end
        character.Head.Neck.C0 = character.Head.Neck.C0:Lerp(targetC0, lerpValue)
    end)

    pointingService.client.pointArm:connect(function(player, shoulderC0, elbowC0, lerpValue)
        if not canPointArm[player] then
            return
        end
        pointingService.pointArm(player, shoulderC0, elbowC0, lerpValue)
    end)
end

function pointingService.pointArm(player, shoulderC0, elbowC0, lerpValue)
    local character = player.Character
    if not character then
        return
    end
    local rightShoulder = character.RightUpperArm.RightShoulder
    local rightElbow = character.RightLowerArm.RightElbow

    rightShoulder.C0 = rightShoulder.C0:Lerp(shoulderC0, lerpValue)
    rightElbow.C0 = rightElbow.C0:Lerp(elbowC0, lerpValue)
end

return pointingService