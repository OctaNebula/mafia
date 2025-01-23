local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local sharedPackages = ReplicatedStorage.sharedPackages
local sharedModules = ReplicatedStorage.shared

local Loader = require(sharedPackages.loader)
local serviceUtil = require(sharedModules.utilities.serviceUtil)

local startupUtil = {}

function startupUtil.startup(servicesOrControllersConfig, components)
	local loadedServicesOrControllers

	if RunService:IsServer() then
		loadedServicesOrControllers = Loader.LoadDescendants(
			servicesOrControllersConfig.path,
			Loader.MatchesName(servicesOrControllersConfig.nameFormat)
		)

		serviceUtil.registerServicesForReplicationToClient(
			Loader.LoadDescendants(
				servicesOrControllersConfig.path,
				Loader.MatchesName(servicesOrControllersConfig.nameFormat)
			)
		)
	else
		serviceUtil.ensureServicesAreReplicatedAndSetup()
	end

	if RunService:IsClient() then
		loadedServicesOrControllers = Loader.LoadDescendants(
			servicesOrControllersConfig.path,
			Loader.MatchesName(servicesOrControllersConfig.nameFormat)
		)
	end

	for _, module in loadedServicesOrControllers do
		if RunService:IsServer() then
			if module.client then
				table.freeze(module.client)
			end
		end

		table.freeze(module)
	end

	Loader.SpawnAll(loadedServicesOrControllers, servicesOrControllersConfig.startupMethod)
	Loader.LoadDescendants(components)
end

return table.freeze(startupUtil)
