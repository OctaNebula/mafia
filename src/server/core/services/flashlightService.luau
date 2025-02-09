local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local sharedPackages = ReplicatedStorage.sharedPackages

local network = require(sharedPackages.network)

local assets = ReplicatedStorage.assets
local flashlight = assets.models.Flashlight

local flashlightService = {
    client = {
        toggleFlashlight = network.Server.RemoteSignal.new(),

        flashlightEquipped = network.Server.RemoteProperty.new(false)
    }
}

function flashlightService.start()
    flashlightService.client.toggleFlashlight:connect(function(player, toggled)
        local character = player.Character
        if not character then
            return
        end
        local characterFlashlight = character:FindFirstChild("Flashlight")
        if not characterFlashlight then
            return
        end
        local attachment = characterFlashlight.Light.light1.LightAttachment
        attachment.SpotLight.Enabled = toggled
        attachment.SpotLight1.Enabled = toggled
    end)
end

function flashlightService.equipFlashlight(player)
    local character = player.Character
    if not character then
        return
    end
    local rightHand = character:FindFirstChild("RightHand")
    if not rightHand then
        return
    end
    flashlightService.client.flashlightEquipped:setForClient(player, true)
    local newFlashlight = flashlight:Clone()
    newFlashlight.Parent = character
    newFlashlight:PivotTo(rightHand.CFrame * CFrame.fromEulerAnglesXYZ(math.rad(180),0,0))

    local weldinstance = Instance.new("WeldConstraint", newFlashlight.Base)
    weldinstance.Part0, weldinstance.Part1 = newFlashlight.Base, rightHand
    return true
end

function flashlightService.unequipFlashlight(player)
    local character = player.Character
    if not character then
        return
    end
    local oldFlashlight = character:FindFirstChild("Flashlight")
    if not oldFlashlight then
        return
    end
    oldFlashlight:Destroy()
    return true
end

return flashlightService