local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedPackages = ReplicatedStorage.sharedPackages
local shared = ReplicatedStorage.shared

local Component = require(sharedPackages.Component)
local Trove = require(sharedPackages.Trove)

local remoteComponentExtension = require(shared.componentExtensions.remoteComponent)

local balloon = Component.new({
	tag = "Balloon",
	extensions = { remoteComponentExtension },
	requiredServerComponents = { "Balloon" },
})

function balloon:construct()
	self._trove = Trove.new()
end

function balloon:start()
	warn(self.server.Balloon:hello())
end

function balloon:stop()
	self._trove:Destroy()
end

return balloon
