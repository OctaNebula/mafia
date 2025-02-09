local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local sharedPackages = ReplicatedStorage.sharedPackages

local network = require(sharedPackages.network)
local Loader = require(sharedPackages.loader)
local Sift = require(sharedPackages.Sift)

local roleModules = script.roles

local services = ServerStorage.server.services
local gameService = require(services.gameService)

local ROLES_NETWORK_FOLDER_PARENT = ReplicatedStorage
local ROLES_NETWORK_FOLDER_NAME = "RoleNetworks"

local roleService = {
    client = {
        getRoleNetwork = network.Server.RemoteSignal.new(),
        role = network.Server.RemoteProperty.new()
    }
}

function roleService.start()
    gameService.playersInfo:observe(function(playersInfo)
        for userId, playerInfo in playersInfo do
            local player = Players:GetPlayerByUserId(userId)
            roleService.client.role:setForClient(player, playerInfo.role)
        end
    end)

    local serviceNetworksFolder = Instance.new("Folder")
	serviceNetworksFolder.Name = ROLES_NETWORK_FOLDER_NAME
	serviceNetworksFolder.Parent = ROLES_NETWORK_FOLDER_PARENT
    local loadedRoleModules = Loader.LoadChildren(roleModules)
    for roleName, roleModule in loadedRoleModules do
        local roleNetwork = network.Server.new(
            roleName,
            Sift.Dictionary.merge({
                default = {
                    network.Server.DefaultMiddleware.AutomaticArgumentSerializationAndDeserialization,
                },
            } or {})
        )
        for i, v in roleModule.client do
            roleNetwork:append(i, v)
        end
        table.freeze(roleModule.client)
        table.freeze(roleModule)
        roleNetwork:dispatch(serviceNetworksFolder)
    end
    Loader.SpawnAll(loadedRoleModules, "start")
end

return roleService