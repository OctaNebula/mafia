local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
-- local Players = game:GetService("Players")

local sharedPackages = ReplicatedStorage.sharedPackages

local services = ServerStorage.server.services

local network = require(sharedPackages.network)
local Signal = require(sharedPackages.Signal)

local initializedPrompts = {}

local interactionService = {
    addPrompt = Signal.new(),
    editPrompt = Signal.new(),
    removePrompt = Signal.new(),
    client = {
        promptAdded = network.Server.RemoteSignal.new(),
        promptEdited = network.Server.RemoteSignal.new(),
        promptRemoved = network.Server.RemoteSignal.new(),
        globalPrompts = network.Server.RemoteProperty.new({}),
        exclusiveInteraction = network.Server.RemoteProperty.new()
    }
}

function interactionService.start()
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
end

function interactionService.setExclusiveInteraction(player: Player, instance: Instance, inputs): boolean
    local exclusiveInteractionProperty = interactionService.client.exclusiveInteraction
    local exclusiveInteractionClientValue = exclusiveInteractionProperty:clientValue(player)
    if exclusiveInteractionClientValue and exclusiveInteractionClientValue.instance ~= instance then
        warn("An object attempted to take over exclusive interaction but was refused")
        return false
    end
    if not inputs then
        exclusiveInteractionProperty:removeForClient(player)
        return true
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
        instance = instance,
        inputs = inputs
    })
    return true
end

function interactionService.setupPrompt(instance: Instance, players: {Player}?)
    initializedPrompts[instance] = {
        handler = require(script.Closet).new(instance, interactionService),
        players = players,
        properties = {
            requiresDirectLineOfSight = false,
            input = Enum.KeyCode.E,
            maxDistance = 10,
            enabled = true,
        }
    }
    if players then
        interactionService.client.promptAdded:fireClients(players, instance, initializedPrompts[instance].properties)
    else
        interactionService.client.promptAdded:fireAllClients(instance, initializedPrompts[instance].properties)
        local globalPrompts = interactionService.client.globalPrompts:get()
        globalPrompts[instance] = initializedPrompts[instance].properties
        interactionService.client.globalPrompts:set(table.clone(globalPrompts))
    end
end

function interactionService.editPrompt(instance: Instance, newProperties: {string: any})
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
        local globalPrompts = interactionService.client.globalPrompts:get()
        globalPrompts[instance] = initializedPrompts[instance].properties
        interactionService.client.globalPrompts:set(table.clone(globalPrompts))
    end
end

function interactionService.destroyPrompt(instance: Instance)
    local handler = initializedPrompts[instance].handler
    -- use handler:Destroy or equivalent
    local players = initializedPrompts[instance].players
    if players then
        interactionService.client.promptRemoved:fireClients(players, instance)
    else
        interactionService.client.promptRemoved:fireAllClients(instance)
        local globalPrompts = interactionService.client.globalPrompts:get()
        globalPrompts[instance] = nil
        interactionService.client.globalPrompts:set(table.clone(globalPrompts))
    end
    initializedPrompts[instance] = nil
end

function interactionService.destroyAllPrompts()
    for _, object in initializedPrompts do
        interactionService.destroyPrompt(object)
    end
end

function interactionService.client.interactWith(player: Player, instance: Instance, inputName: string)
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