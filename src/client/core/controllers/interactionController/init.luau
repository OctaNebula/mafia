local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local proximityPromptUI = ReplicatedStorage.assets.proximityPrompt

local shared = ReplicatedStorage.shared

local serviceUtil = require(shared.utilities.serviceUtil)
local interactionService = serviceUtil.service("interactionService")

local activePrompts = {}
local activeInputs = {}
local interactablePrompts = {}
local allPromptDistances = {}

local interactionController = {}

function interactionController.start()
    local globalPrompts = interactionService.globalPrompts:get()
    for instance, properties in globalPrompts do
        interactionController.setupPrompt(instance, properties)
    end
    interactionService.promptAdded:connect(function(instance: Instance, properties)
        interactionController.setupPrompt(instance, properties)
    end)
    interactionService.promptEdited:connect(function(instance: Instance, properties)
        interactionController.editPrompt(instance, properties)
    end)
    interactionService.promptRemoved:connect(function(instance: Instance)
        interactionController.removePrompt(instance)
    end)

    RunService.RenderStepped:Connect(function()
        local character = LocalPlayer.Character
        if not character then
            return
        end
        interactablePrompts = {}
        allPromptDistances = {}
        for instance, _ in activePrompts do
            local distance = (character:GetPivot().Position-instance:GetPivot().Position).Magnitude
            local promptDistanceInfo = {
                instance = instance,
                distance = distance
            }
            if #allPromptDistances <= 0 then
                allPromptDistances[1] = promptDistanceInfo
            else
                for i = 1, #allPromptDistances do
                    if distance < allPromptDistances[i].distance then
                        table.insert(allPromptDistances, i, promptDistanceInfo)
                        break
                    elseif i == #allPromptDistances then
                        allPromptDistances[i+1] = promptDistanceInfo
                        break
                    end
                end
            end
        end
        if #allPromptDistances <= 0 then
            return
        end
        for _, promptDistanceInfo in allPromptDistances do
            local promptInfo = activePrompts[promptDistanceInfo.instance]
            local properties = promptInfo.properties
            local withinDistance = promptDistanceInfo.distance <= promptInfo.properties.maxDistance
            if withinDistance and properties.input and properties.interactable then
                if not interactablePrompts[properties.input] then
                    interactablePrompts[properties.input] = {}
                end
                table.insert(interactablePrompts[properties.input], promptDistanceInfo)
            end
            promptInfo.UI.Enabled = withinDistance
        end
    end)
end

function interactionController.handleInput(_, inputState, inputObject)
    if inputState ~= Enum.UserInputState.End then
        return Enum.ContextActionResult.Pass
    end
    if not interactablePrompts[inputObject.KeyCode] then
        return Enum.ContextActionResult.Pass
    end
    local instance = interactablePrompts[inputObject.KeyCode][1].instance -- get closest prompt's instance
    local promptInfo = activePrompts[instance]
    interactionService.interactWith(instance)
    return Enum.ContextActionResult.Sink
end

function interactionController.updateActionBinds()
    local inputs = {}
    for input, numberOfInputs in activeInputs do
        if numberOfInputs > 0 then
            table.insert(inputs, input)
        end
    end
    if #inputs <= 0 then
        print("Unbinded interactionController")
        ContextActionService:UnbindAction("interactionController")
    else
        print("Binded interactionController,", table.unpack(inputs))
        ContextActionService:BindAction("interactionController", interactionController.handleInput, false, table.unpack(inputs))
    end
end

function interactionController.setupPrompt(instance: Instance, properties)
    local UIClone = proximityPromptUI:Clone()
    UIClone.MaxDistance = math.huge
    UIClone.Enabled = false
    UIClone.Parent = instance
    activePrompts[instance] = {
        properties = properties,
        instance = instance,
        UI = UIClone
    }
    if not activeInputs[properties.input] then
        activeInputs[properties.input] = 0
    end
    activeInputs[properties.input] += 1

    interactionController.updateActionBinds()
end

function interactionController.editPrompt(instance: Instance, properties)
    activePrompts[instance]:setProperties(properties)
end

function interactionController.removePrompt(instance: Instance)
    local promptInfo = activePrompts[instance]
    promptInfo.UI:Destroy()
    activeInputs[promptInfo.properties.input] -= 1
    activePrompts[instance] = nil

    interactionController.updateActionBinds()
end

return interactionController
