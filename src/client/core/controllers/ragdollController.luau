local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local shared = ReplicatedStorage.shared

local serviceUtil = require(shared.utilities.serviceUtil)
local ragdollService = serviceUtil.service("ragdollService")

local ragdollController = {}

function ragdollController.start()
    ragdollService.ragdoll:connect(ragdollController.ragdoll)
    ragdollService.unragdoll:connect(ragdollController.unragdoll)
end

function ragdollController.ragdoll()
    local character = LocalPlayer.Character
    if not character then
        return
    end
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.AutoRotate = false
    humanoid.PlatformStand = true
end

function ragdollController.unragdoll()
    local character = LocalPlayer.Character
    if not character then
        return
    end
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.AutoRotate = true
    humanoid.PlatformStand = false
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

return ragdollController