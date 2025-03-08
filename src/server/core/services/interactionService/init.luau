local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local sharedPackages = ReplicatedStorage.sharedPackages

local network = require(sharedPackages.network)
local Signal = require(sharedPackages.Signal)

local initializedPrompts = {}
local globalPrompts = {}

local objects

local isMain = false

local objectImages = {
    interact = "rbxassetid://17368931552",
    closet = "rbxassetid://17368931705",
    door = "rbxassetid://17368928352",
}

local interactionService = {
    cleanupObjects = Signal.new(),
    funcSignals = {
        editPrompt = Signal.new(),
        setupPrompt = Signal.new(),
        removePrompt = Signal.new(),
    },
    client = {
        promptAdded = network.Server.RemoteSignal.new(),
        promptEdited = network.Server.RemoteSignal.new(),
        promptRemoved = network.Server.RemoteSignal.new(),
        exclusiveInteraction = network.Server.RemoteProperty.new()
    }
}

function interactionService.start()
    objects = {}
    for _, module in script:GetChildren() do
        if not module:IsA("ModuleScript") then
            continue
        end
        local name = string.lower(module.Name)
        if not objects[name] then
            objects[name] = require(module)
        end
    end
    isMain = true

    Players.PlayerAdded:Connect(function(player)
        for instance, properties in globalPrompts do
            interactionService.client.promptAdded:fireClient(player, instance, properties)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        for _, object in initializedPrompts do
            local players = object.players
            if not players then
                continue
            end
            local playerIndex = table.find(players, player)
            if playerIndex then
                table.remove(object.players, playerIndex)
            end
        end
    end)

    interactionService.funcSignals.editPrompt:Connect(function(...)
        interactionService.editPrompt(...)
    end)
    interactionService.funcSignals.setupPrompt:Connect(function(...)
        interactionService.setupPrompt(...)
    end)
    interactionService.funcSignals.removePrompt:Connect(function(...)
        interactionService.removePrompt(...)
    end)
    interactionService.cleanupObjects:Connect(function()
        for _, object in initializedPrompts do
            if object.handler.cleanup then
                object.handler:cleanup()
            end
        end
    end)
end

function interactionService.hasExclusiveInteraction(player: Player, instance: Instance)
    local exclusiveInteractionProperty = interactionService.client.exclusiveInteraction
    local exclusiveInteractionClientValue = exclusiveInteractionProperty:clientValue(player)
    if exclusiveInteractionClientValue and exclusiveInteractionClientValue.instance ~= instance then
        return false
    end
    return true
end

function interactionService.setExclusiveInteraction(player: Player, instance: Instance, inputs, promptInfo): boolean
    local exclusiveInteractionProperty = interactionService.client.exclusiveInteraction
    local exclusiveInteractionClientValue = exclusiveInteractionProperty:clientValue(player)
    if exclusiveInteractionClientValue and exclusiveInteractionClientValue.instance ~= instance then
        warn("An object attempted to take over exclusive interaction but was refused")
        return false
    end
    if not inputs then
        exclusiveInteractionProperty:removeForClient(player)
        return exclusiveInteractionClientValue
    end
    local inputsArray = {}
    for _, newInputs in inputs do
        local newInputsArray = {}
        for _, input in newInputs do
            if typeof(input) == "table" then
                for _, inputChild in input do
                    if table.find(newInputsArray, inputChild) then
                        error("Duplicate inputs are not allowed for exclusiveInteractions")
                    end
                    table.insert(newInputsArray, inputChild)
                    table.insert(inputsArray, inputChild)
                end
                continue
            end
            if table.find(inputsArray, input) then
                error("Duplicate inputs are not allowed for exclusiveInteractions")
            end
            table.insert(newInputsArray, input)
            table.insert(inputsArray, input)
        end
    end
    exclusiveInteractionProperty:setForClient(player, {
        promptInfo = promptInfo,
        instance = instance,
        inputs = inputs
    })
    return exclusiveInteractionClientValue
end

function interactionService.editPrompt(instance: Instance, newProperties: {string: any})
    if not isMain then
        interactionService.funcSignals.editPrompt:Fire(instance, newProperties)
    end
    local prompt = initializedPrompts[instance]
    local edited = false
    for index, property in newProperties do
        local currentProperty = prompt.properties[index]
        if currentProperty == nil then
            continue
        end
        if currentProperty ~= property then
            edited = true
            prompt.properties[index] = property
            continue
        end
    end
    if not edited then
        return
    end
    if prompt.players then
        interactionService.client.promptEdited:fireClients(prompt.players, instance, table.clone(prompt.properties))
    else
        interactionService.client.promptEdited:fireAllClients(instance, table.clone(prompt.properties))
        globalPrompts[instance] = initializedPrompts[instance].properties
    end
end

function interactionService.setupPrompt(instance: Instance, objectType: string, players: {Player}?)
    if not isMain then
        interactionService.funcSignals.setupPrompt:Fire(instance, players)
    end
    initializedPrompts[instance] = {
        handler = objects[string.lower(objectType)].new(instance, interactionService),
        objectType = objectType,
        players = players,
        properties = {
            requiresDirectLineOfSight = false,
            input = Enum.KeyCode.E,
            maxDistance = 10,
            enabled = true,
            image = objectImages[string.lower(objectType)] or objectImages.interact
        }
    }
    if players then
        interactionService.client.promptAdded:fireClients(players, instance, initializedPrompts[instance].properties)
    else
        interactionService.client.promptAdded:fireAllClients(instance, initializedPrompts[instance].properties)
        globalPrompts[instance] = initializedPrompts[instance].properties
    end
end

function interactionService.destroyPrompt(instance: Instance)
    if not isMain then
        interactionService.funcSignals.destroyPrompt:Fire(instance)
    end
    local handler = initializedPrompts[instance].handler
    -- use handler:Destroy or equivalent
    local players = initializedPrompts[instance].players
    if players then
        interactionService.client.promptRemoved:fireClients(players, instance)
    else
        interactionService.client.promptRemoved:fireAllClients(instance)
        globalPrompts[instance] = nil
    end
    initializedPrompts[instance] = nil
end

function interactionService.destroyAllPrompts()
    for _, object in initializedPrompts do
        interactionService.destroyPrompt(object)
    end
end

function interactionService.client.interactWith(player: Player, instance: string, inputName: string)
    -- TODO: add line of sight and distance sanity checks
    local exclusiveInteraction = interactionService.client.exclusiveInteraction:clientValue(player)
    local prompt = initializedPrompts[instance]
    if prompt.players and not table.find(prompt.players, player) then
        return
    end
    local handler = initializedPrompts[instance].handler
    return handler:interact(player, inputName)
end

return interactionService