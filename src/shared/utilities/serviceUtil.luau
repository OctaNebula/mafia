local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local sharedPackages = ReplicatedStorage.sharedPackages

local Sift = require(sharedPackages.Sift)
local network = require(sharedPackages.network)

local SERVICES_NETWORK_FOLDER_PARENT = ReplicatedStorage
local SERVICES_NETWORK_FOLDER_NAME = "ServiceNetworks"
local SERVICES_READY_ATTRIBUTE = "Ready"
local SERVICES_NETWORK_FOLDER_RETRIEVAL_TIMEOUT = 10

local NetworkServer = network.Server

local replicatedServices = {}

local serviceUtil = {}

if RunService:IsServer() then
	local serviceNetworksFolder = Instance.new("Folder")
	serviceNetworksFolder.Name = SERVICES_NETWORK_FOLDER_NAME
	serviceNetworksFolder.Parent = SERVICES_NETWORK_FOLDER_PARENT
end


--[=[
	Gets the network folder that is used by server and client
]=]
local function servicesNetworkFolder()
	if RunService:IsClient() then
		local folder = SERVICES_NETWORK_FOLDER_PARENT:WaitForChild(
			SERVICES_NETWORK_FOLDER_NAME,
			SERVICES_NETWORK_FOLDER_RETRIEVAL_TIMEOUT
		)

		assert(
			folder,
			string.format(
				'Service networks folder "%s" not found in %s. (%ds)',
				SERVICES_NETWORK_FOLDER_NAME,
				SERVICES_NETWORK_FOLDER_PARENT:GetFullName(),
				SERVICES_NETWORK_FOLDER_RETRIEVAL_TIMEOUT
			)
		)
		return folder
	end

	return SERVICES_NETWORK_FOLDER_PARENT[SERVICES_NETWORK_FOLDER_NAME]
end

--[=[
    Registers the given services for replication to the client (their `client` table if any).
]=]
function serviceUtil.registerServicesForReplicationToClient(services)
	local networkFolder = servicesNetworkFolder()

	for serviceName, service in services do
		if typeof(service.client) ~= "table" then
			continue
		end

		local serviceNetwork = NetworkServer.new(
			serviceName,
			Sift.Dictionary.merge({
				default = {
					NetworkServer.DefaultMiddleware.AutomaticArgumentSerializationAndDeserialization,
				},
			}, service.middlewares or {})
		)

		for key, value in service.client do
			serviceNetwork:append(key, value)
		end

		serviceNetwork:dispatch(networkFolder)
	end

	networkFolder:SetAttribute(SERVICES_READY_ATTRIBUTE, true)
end

--[=[
    Returns the service exposed to the client.
]=]
function serviceUtil.service(serviceName: string)
	assert(
		replicatedServices[serviceName],
		string.format('Service "%s" was not found!', serviceName)
	)

	return replicatedServices[serviceName]
end

--[=[
    Ensures all serverside services bound to be replicated to the client are fully
    replicated.
]=]
function serviceUtil.ensureServicesAreReplicatedAndSetup()
	assert(RunService:IsClient(), "Can only call this method on the client!")

	local networkFolder = servicesNetworkFolder()

	if not networkFolder:GetAttribute(SERVICES_READY_ATTRIBUTE) then
		networkFolder:GetAttributeChangedSignal(SERVICES_READY_ATTRIBUTE):Wait()
	end

	for serviceName, service in network.client.allFromParent(networkFolder) do
		replicatedServices[serviceName] = service
	end
end

return table.freeze(serviceUtil)