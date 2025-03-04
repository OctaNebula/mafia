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
local exclusiveInteraction
local exclusiveInteractionPrompt

local inputDebounce = false

local interactionController = {}

function interactionController.start()
    interactionService.promptAdded:connect(function(instance: Instance, properties)
        -- print(instance, properties)
        interactionController.setupPrompt(instance, properties)
    end)
    interactionService.promptEdited:connect(function(instance: Instance, properties)
        interactionController.editPrompt(instance, properties)
    end)
    interactionService.promptRemoved:connect(function(instance: Instance)
        interactionController.removePrompt(instance)
    end)

    interactionService.exclusiveInteraction:observe(function(newExclusiveInteraction)
        if exclusiveInteractionPrompt then
            exclusiveInteractionPrompt:Destroy()
        end
        if not newExclusiveInteraction then
            exclusiveInteraction = nil
            interactionController.updateActionBinds()
            return
        end
        exclusiveInteraction = newExclusiveInteraction
        interactionController.updateActionBinds()
    end)

    RunService.RenderStepped:Connect(function()
        interactablePrompts = {}
        allPromptDistances = {}
        if exclusiveInteraction then
            for _, promptInfo in activePrompts do
                promptInfo.UI.Enabled = false
            end
            return
        end
        local character = LocalPlayer.Character
        if not character then
            return
        end
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
            local interactable = withinDistance and properties.input and properties.enabled
            if interactable then
                if not interactablePrompts[properties.input] then
                    interactablePrompts[properties.input] = {}
                end
                table.insert(interactablePrompts[properties.input], promptDistanceInfo)
            end
            promptInfo.UI.Enabled = interactable
        end
    end)
end

function interactionController.handleInput(_, inputState, inputObject)
    if inputDebounce then
        return Enum.ContextActionResult.Pass
    end
    if exclusiveInteraction then
        if inputState ~= Enum.UserInputState.Begin and inputState ~= Enum.UserInputState.End then
            return Enum.ContextActionResult.Pass
        end
        local inputs = table.clone(exclusiveInteraction.inputs)
        local beganInputs = inputs.began or {}
        local endedInputs = inputs.ended or {}

        local exclusiveInputName

        for inputName, input in if inputState == Enum.UserInputState.Begin then beganInputs else endedInputs do
            if typeof(input) == "table" then
                for _, inputChild in input do
                    if inputObject.KeyCode == inputChild or inputObject.UserInputType == inputChild then
                        exclusiveInputName = inputName
                        break
                    end
                end
            end
            if inputObject.KeyCode == input or inputObject.UserInputType == input then
                exclusiveInputName = inputName
                break
            end
        end

        if not exclusiveInputName then
            return Enum.ContextActionResult.Pass
        end

        task.spawn(function()
            inputDebounce = true
            interactionService.interactWith(exclusiveInteraction.instance, exclusiveInputName) -- yields
            inputDebounce = false
        end)

        if table.find({
            Enum.KeyCode.W,
            Enum.KeyCode.A,
            Enum.KeyCode.S,
            Enum.KeyCode.D,
        }, inputObject.KeyCode) then
            return Enum.ContextActionResult.Pass
        end

        return Enum.ContextActionResult.Sink
    else
        if inputState ~= Enum.UserInputState.End then
            return Enum.ContextActionResult.Pass
        end
        local prompts = interactablePrompts[inputObject.KeyCode]
        if not prompts then
            return Enum.ContextActionResult.Pass
        end
        local instance = prompts[1].instance -- get closest prompt's instance
        task.spawn(function()
            inputDebounce = true
            interactionService.interactWith(instance) -- yields
            inputDebounce = false
        end)
        return Enum.ContextActionResult.Sink
    end
end

function interactionController.updateActionBinds()
    local inputs = {}
    if exclusiveInteraction then
        for _, newInputs in exclusiveInteraction.inputs do
            for _, input in newInputs do
                local newInputsArray = {}
                if typeof(input) == "table" then
                    for _, inputChild in input do
                        if table.find(newInputsArray, inputChild) then
                            error("Duplicate inputs are not allowed for exclusiveInteractions")
                        end
                        table.insert(newInputsArray, inputChild)
                        table.insert(inputs, inputChild)
                    end
                    continue
                end
                if table.find(newInputsArray, input) then
                    error("Duplicate inputs are not allowed for exclusiveInteractions")
                end
                table.insert(newInputsArray, input)
                table.insert(inputs, input)
            end
        end
        local promptInfo = exclusiveInteraction.promptInfo
        if promptInfo then
            exclusiveInteractionPrompt = interactionController.setupPrompt(promptInfo.instance, promptInfo, true)
        end
    else
        for input, numberOfInputs in activeInputs do
            if numberOfInputs > 0 then
                table.insert(inputs, input)
            end
        end
    end
    if #inputs <= 0 then
        ContextActionService:UnbindAction("interactionController")
    else
        ContextActionService:BindActionAtPriority("interactionController", interactionController.handleInput, false, 2, table.unpack(inputs))
    end
end

function interactionController.setupPrompt(instance: Instance, properties, isExclusivePrompt)
    local UIClone = proximityPromptUI:Clone()
    UIClone.MaxDistance = math.huge
    UIClone.body.image.Image = properties.image or "rbxassetid://17368931552"
    UIClone.Enabled = isExclusivePrompt or false
    UIClone.Parent = instance:FindFirstChild("Base") or instance
    print(instance:FindFirstChild("Base"))
    if isExclusivePrompt then
        return UIClone
    end
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
    return UIClone
end

function interactionController.editPrompt(instance: Instance, properties)
    activePrompts[instance].properties = properties
end

function interactionController.removePrompt(instance: Instance)
    local promptInfo = activePrompts[instance]
    promptInfo.UI:Destroy()
    activeInputs[promptInfo.properties.input] -= 1
    activePrompts[instance] = nil

    interactionController.updateActionBinds()
end

return interactionController
