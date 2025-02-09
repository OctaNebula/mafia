local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
-- local Players = game:GetService("Players")

local sharedPackages = ReplicatedStorage.sharedPackages

local services = ServerStorage.server.services

local network = require(sharedPackages.network)

local initializedObjects = {}

local interactionService = {
    client = {}
}

function interactionService.start()

end

function interactionService.setupObject(instance: Instance)
    initializedObjects[instance] = require(script.Closet).new(instance)
end

function interactionService.destroyObject(instance: Instance)
    -- disconnect the stuff i guess?
    initializedObjects[instance] = nil
end

function interactionService.destroyAllObjects()
    for _, object in initializedObjects do
        interactionService.destroyObject(object)
    end
end

function interactionService.setInteractable(instance: Instance, interactable: boolean)
    local isInteractable = instance:HasTag("Interactable")
    if isInteractable == interactable then
        return
    end
    if interactable then
        instance:AddTag("Interactable")
    elseif not interactable then
        instance:RemoveTag("Interactable")
    end
end

function interactionService.client.interactWith(player: Player, instance: Instance)
    print(player, instance)
    -- add line of sight and distance sanity checks
    local isInteractable = instance:HasTag("Interactable")
    if not isInteractable then
        return
    end
    local tags = instance:GetTags()
    if table.find(tags, "Closet") then
        print("Closet interacted with!")
        -- instance:RemoveTag("Interactable")
        initializedObjects[instance]:storeCharacter(player.Character)
    end
end

return interactionService