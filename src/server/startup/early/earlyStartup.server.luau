local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverModules = ServerStorage.server
local sharedModules = ReplicatedStorage.shared

local animations = ReplicatedStorage.assets.animations

local startupUtil = require(sharedModules.utilities.startupUtil)

local function createPreviewAnimation(keyframeSequence)
    local hashId = KeyframeSequenceProvider:RegisterKeyframeSequence(keyframeSequence)
    local Animation = Instance.new("Animation")
    Animation.AnimationId = hashId
    return Animation
end

for _, keyframeSequence in animations:GetDescendants() do
    if keyframeSequence:IsA("KeyframeSequence") then
        local animation = createPreviewAnimation(keyframeSequence)
        animation.Name = keyframeSequence.Name
        animation.Parent = keyframeSequence.Parent
        keyframeSequence:Destroy()
    end
end

local SERVICE_NAME_FORMAT = "Service$"
local CONTROLLER_STARTUP_METHOD = "start"

require(sharedModules.utilities.serviceUtil)
startupUtil.startup({
	path = serverModules.services,
	nameFormat = SERVICE_NAME_FORMAT,
	startupMethod = CONTROLLER_STARTUP_METHOD,
}, serverModules.components)
