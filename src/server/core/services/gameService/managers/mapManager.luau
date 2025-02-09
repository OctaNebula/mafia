local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local uiManager = require(script.Parent.uiManager)

local services = ServerStorage.server.services
local interactionService = require(services.interactionService)

local mapManager = {
    currentMap = nil,
    events = {}
}

function mapManager.init(gameService)
    mapManager.events.sendMapDescendantsCount = gameService.client.sendMapDescendantsCount
    mapManager.events.mapLoaded = gameService.client.mapLoaded
    uiManager.init(gameService)
end

function mapManager.loadMap(mapName)
    if mapManager.currentMap then
        warn("There is already a loaded map, unloading current map")
        mapManager.unloadMap()
    end
    -- local Maps = ReplicatedStorage:WaitForChild("MAPS"):GetChildren()
    -- local map = Maps[math.random(1, #Maps)]:Clone()
    -- Test code for specific map
    local map = ReplicatedStorage.MAPS[mapName]:Clone()
    map.Name = "Map"
    map.Parent = workspace
    mapManager.currentMap = map

    -- Disable seats
    if map:FindFirstChild("Seats") then
        for _, seat in pairs(map.Seats:GetChildren()) do
            seat.Disabled = true
        end
    end

    -- Get spawn locations
    local spawnLocations = {}
    for _, spawnLocation in pairs(map:GetChildren()) do
        if spawnLocation:IsA('SpawnLocation') then
            table.insert(spawnLocations, spawnLocation)
        end
    end

    -- Setup interactable objects
    local closets = map.Closets:GetChildren()
    local doors = map.Doors:GetChildren()
    for _, closet in closets do
        interactionService.setupObject(closet)
    end
    -- for _, door in doors do
    --     interactionService.setInteractable(door, true)
    -- end

    return map, spawnLocations
end

function mapManager.unloadMap()
    if not mapManager.currentMap then
        return
    end
    mapManager.currentMap:Destroy()
    mapManager.currentMap = nil
end

function mapManager.waitForPlayersAsync(participatingPlayers)
    if not mapManager.currentMap then
        error("waitForPlayers was called, but there's no map currently loaded")
    end
    local allPlayersLoadedEvent = Instance.new("BindableEvent")
    local loadedPlayers = {}
    -- TODO: im too lazy to fix this rn, but there is an edge case if any of the participatingPlayers leave the game
    local mapLoadedConnection
    mapLoadedConnection = mapManager.events.mapLoaded:connect(function(player)
        if table.find(participatingPlayers, player) and not table.find(loadedPlayers, player) then
            table.insert(loadedPlayers, player.UserId)
        end
        if #participatingPlayers == #loadedPlayers then
            mapLoadedConnection:Disconnect()
            allPlayersLoadedEvent:Fire()
        end
    end)

    mapManager.events.sendMapDescendantsCount:fireAllClients(#mapManager.currentMap:GetDescendants())
    uiManager.setTopbarText("all", "Loading map...")

    allPlayersLoadedEvent.Event:Wait()
    uiManager.setTopbarText("all", nil)
end

return mapManager