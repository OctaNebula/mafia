local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local clientModules = ReplicatedStorage.client
local sharedModules = ReplicatedStorage.shared

local serviceUtil = require(sharedModules.utilities.serviceUtil)
local startupUtil = require(sharedModules.utilities.startupUtil)

local CONTROLLER_STARTUP_METHOD = "start"
local CONTROLLER_NAME_FORMAT = "Controller$"

task.spawn(function()
    ContentProvider:PreloadAsync(ReplicatedStorage.assets:GetDescendants())
end)

serviceUtil.ensureServicesAreReplicatedAndSetup()

startupUtil.startup({
	path = clientModules.controllers,
	nameFormat = CONTROLLER_NAME_FORMAT,
	startupMethod = CONTROLLER_STARTUP_METHOD,
}, clientModules.components)