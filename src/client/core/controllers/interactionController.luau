local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local proximityPromptUI = ReplicatedStorage.assets.proximityPrompt

local shared = ReplicatedStorage.shared

local serviceUtil = require(shared.utilities.serviceUtil)
local interactionService = serviceUtil.service("interactionService")

local interactionController = {}

function interactionController.start()
    for _, instance in CollectionService:GetTagged("Interactable") do
        interactionController.setupPrompt(instance)
    end
    CollectionService:GetInstanceAddedSignal("Interactable"):Connect(function(instance)
        interactionController.setupPrompt(instance)
    end)
end

function interactionController.setupPrompt(instance: Instance)
    print(instance)
    interactionController.createPrompt(instance, 20, "Closet", function()
        print("Interacted with!")
        interactionService.interactWith(instance)
    end)
end

function interactionController.createPrompt(instance: Instance, maxDistance: number, type: string, callback: () -> ())
    local prompt: ProximityPrompt = Instance.new("ProximityPrompt")
    prompt.Style = Enum.ProximityPromptStyle.Custom
    prompt.MaxActivationDistance = maxDistance
    prompt.RequiresLineOfSight = true
    local billboardUI: BillboardGui = proximityPromptUI:Clone()
    billboardUI.MaxDistance = maxDistance
    billboardUI.Enabled = false

    prompt.PromptShown:Connect(function()
        billboardUI.Enabled = true
        print("Enabled!")
    end)
    prompt.PromptHidden:Connect(function()
        billboardUI.Enabled = false
        print("Disabled!")
    end)
    prompt.Triggered:Connect(callback)
    prompt.Parent = instance
    billboardUI.Parent = instance
end

return interactionController
