local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local sharedPackages = ReplicatedStorage.sharedPackages
local debugLoggerUtil = require(sharedPackages.debugLoggerUtil)
local network = require(sharedPackages.network)
local Sift = require(sharedPackages.Sift)

local COMPONENTS_NETWORK_FOLDER_PARENT = ReplicatedStorage
local COMPONENTS_NETWORK_FOLDER_NAME = "RemoteComponentNetworks"
local COMPONENTS_NETWORK_FOLDER_RETRIEVAL_TIMEOUT = 10
local SERVER_COMPONENT_NETWORK_RETRIEVAL_TIMEOUT = 10
local SERVER_COMPONENT_INITIALIZATION_TIMEOUT = 5

local NetworkServer = network.Server

local remoteComponent = {}

if RunService:IsServer() then
	local networksFolder = Instance.new("Folder")
	networksFolder.Name = COMPONENTS_NETWORK_FOLDER_NAME
	networksFolder.Parent = COMPONENTS_NETWORK_FOLDER_PARENT
end

local function componentsNetworkFolder()
	if RunService:IsClient() then
		local folder = COMPONENTS_NETWORK_FOLDER_PARENT:WaitForChild(
			COMPONENTS_NETWORK_FOLDER_NAME,
			COMPONENTS_NETWORK_FOLDER_RETRIEVAL_TIMEOUT
		)

		assert(
			folder,
			string.format(
				'Remote component networks folder "%s" was not found in %s. (%ds)',
				COMPONENTS_NETWORK_FOLDER_NAME,
				COMPONENTS_NETWORK_FOLDER_PARENT:GetFullName(),
				COMPONENTS_NETWORK_FOLDER_RETRIEVAL_TIMEOUT
			)
		)
		return folder
	end

	return COMPONENTS_NETWORK_FOLDER_PARENT[COMPONENTS_NETWORK_FOLDER_NAME]
end

function remoteComponent.constructing(component)
	local networkFolder = componentsNetworkFolder()

	if RunService:IsServer() then
		if typeof(component.client) ~= "table" then
			return
		end

		if NetworkServer.fromName(component.tag) then
			return
		end

		local componentServerNetwork =
			NetworkServer.new(component.tag, Sift.Dictionary.merge({}, component.middlewares or {}))

		for key, value in component.client do
			componentServerNetwork:append(key, value)
		end

		networkFolder:SetAttribute(component.tag, true)
		componentServerNetwork:dispatch(networkFolder)
	else
		if typeof(component.requiredServerComponents) ~= "table" then
			return
		end

		local serverComponentInitializationCheckThread = task.delay(
			SERVER_COMPONENT_INITIALIZATION_TIMEOUT,
			function()
				if not networkFolder:GetAttribute(component.tag) then
					debugLoggerUtil.log(
						warn,
						string.format(
							'[%s]: Server component "%s" was not initialized for networking. (%ds)',
							tostring(component),
							component.tag,
							SERVER_COMPONENT_INITIALIZATION_TIMEOUT
						)
					)
				end
			end
		)

		-- Handle race condition where the client runs before the server initializes,
		-- for networking, to avoid bugs.
		if not networkFolder:GetAttribute(component.tag) then
			networkFolder:GetAttributeChangedSignal(component.tag):Wait()
		end

		component.server = {}
		task.cancel(serverComponentInitializationCheckThread)

		for _, serverComponentIdentifier in component.requiredServerComponents do
			local wasSuccessful, response = network.client
				.fromParent(
					serverComponentIdentifier,
					networkFolder,
					SERVER_COMPONENT_NETWORK_RETRIEVAL_TIMEOUT
				)
				:await()

			if not wasSuccessful then
				debugLoggerUtil.log(
					warn,
					string.format(
						'[%s]: Network for server component "%s" could not be retrieved',
						tostring(component),
						serverComponentIdentifier
					)
				)

				continue
			end

			component.server[serverComponentIdentifier] = response
		end
	end
end

function remoteComponent.stopped(component)
	if RunService:IsClient() then
		return
	end

	local componentNetwork = NetworkServer.fromName(component.tag)

	if not componentNetwork then
		return
	end

	componentNetwork:destroy()
end

return remoteComponent
