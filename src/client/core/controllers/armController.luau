local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local sharedPackages = ReplicatedStorage.sharedPackages
local Signal = require(sharedPackages.Signal)

local shared = ReplicatedStorage.shared

local serviceUtil = require(shared.utilities.serviceUtil)
local gameService = serviceUtil.service("gameService")

local solveArm = require(shared.modules.solveArm)

local armController = {
    getPointingTarget = Instance.new("BindableFunction"),
    setPointingLerpValue = Signal.new(),
    setPointingTarget = Signal.new(),
    setIsPointing = Signal.new()
}

function armController.start()
    local mouse = LocalPlayer:GetMouse()

    local isPointing = false
    local forcedTarget
    local lerpValue = 0.2

    armController.setPointingLerpValue:Connect(function(newPointingLerpValue)
        lerpValue = newPointingLerpValue or 0.2
    end)

    armController.setPointingTarget:Connect(function(newPointingTarget)
        if typeof(newPointingTarget) ~= "Vector3" and newPointingTarget ~= nil then
            error(`setPointingTarget got incorrect type (expected Vector3, got {typeof(newPointingTarget)}`)
        end
        forcedTarget = newPointingTarget
    end)

    armController.setIsPointing:Connect(function(newIsPointing)
        isPointing = newIsPointing or false
    end)

    RunService.RenderStepped:Connect(function()
        if not isPointing then
            return
        end
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local rightShoulder = character:WaitForChild("RightUpperArm"):WaitForChild("RightShoulder")
        local rightElbow = character:WaitForChild("RightLowerArm"):WaitForChild("RightElbow")

        local target = forcedTarget or mouse.Hit.Position

        local shoulderCF = character.UpperTorso.CFrame * CFrame.new()
        local plane, shoulderAngle, elbowAngle = solveArm(shoulderCF, target)

        local goalRightShoulderC0CFrame = character.UpperTorso.CFrame:toObjectSpace(plane) * CFrame.Angles(shoulderAngle, 0, 0)
        
        local shoulderC0, elbowC0 = goalRightShoulderC0CFrame.Rotation + rightShoulder.C0.Position, CFrame.new() * CFrame.Angles(elbowAngle, 0, 0)
        
        rightShoulder.C0 = rightShoulder.C0:Lerp(shoulderC0, lerpValue)
        rightElbow.C0 = rightElbow.C0:Lerp(elbowC0, lerpValue)
        gameService.pointArm:fireServer(shoulderC0, elbowC0, lerpValue)
    end)
end

return armController