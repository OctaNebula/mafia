local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedPackages = ReplicatedStorage.sharedPackages
local shared = ReplicatedStorage.shared

local remoteComponentExtension = require(shared.componentExtensions.remoteComponent)
local Component = require(sharedPackages.Component)
local Trove = require(sharedPackages.Trove)

local Balloon = Component.new({
	tag = "Balloon",
	extensions = { remoteComponentExtension },
	client = {},
})

function Balloon:construct()
	self._trove = Trove.new()
end

function Balloon.client:hello()
	return "test"
end

function Balloon:stop()
	self._trove:Destroy()
end

return Balloon
