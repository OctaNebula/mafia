local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local sharedPackages = ReplicatedStorage.sharedPackages

local network = require(sharedPackages.network)
local Signal = require(sharedPackages.Signal)

local pointingService = {
    setCanPointArm = Signal.new(),
    client = {
        pointHead = network.Server.RemoteSignal.new(),
        pointArm = network.Server.RemoteSignal.new(),
    }
}

function pointingService.start()
    local canPointArm = false
    pointingService.setCanPointArm:Connect(function(newCanPointArm)
        canPointArm = newCanPointArm
        task.wait()
        if not canPointArm then
            for _, player in Players:GetPlayers() do
                -- set arms to default c0
                pointingService.pointArm(
                    player,
                    CFrame.new(1, 0.563, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
                    CFrame.new(0, -0.334, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
                    1
                )
            end
        end
    end)

    pointingService.client.pointHead:connect(function(player, targetC0, lerpValue)
        local character = player.Character
        if not character then
            return
        end
        character.Head.Neck.C0 = character.Head.Neck.C0:Lerp(targetC0, lerpValue)
    end)

    pointingService.client.pointArm:connect(function(player, shoulderC0, elbowC0, lerpValue)
        -- add sanity check, this should only be used for voting phase (use canVote) and flashlights(?)
        if not canPointArm then
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