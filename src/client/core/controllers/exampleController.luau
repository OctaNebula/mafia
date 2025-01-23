local ReplicatedStorage = game:GetService("ReplicatedStorage")

local serviceUtil = require(ReplicatedStorage.shared.utilities.serviceUtil)

-- Get services using serviceUtil.service("serviceName")
local exampleService = serviceUtil.service("exampleService")

-- Modules in Controllers must end with "Controller" in order to be ran.
local exampleController = {}

-- Modules are given a start method that is run.
function exampleController.start()
	-- Get events in the service client table
	exampleService.exampleEvent:connect(function()
		print("Got example event.")
	end)

	-- Run methods in service that are in the client table
	-- print(exampleService.exampleMethod())
end

return exampleController
