local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local shared = ReplicatedStorage.shared
local serviceUtil = require(shared.utilities.serviceUtil)
local effectsService = serviceUtil.service("effectsService")

local effects = script.effects
local requiredEffects = {}

local effectsController = {}

function effectsController.start()
    for _, effect in effects:GetChildren() do
        requiredEffects[effect.Name] = require(effect)
    end
    effectsService.playEffect:connect(function(effectToPlay, ...)
        local effect = requiredEffects[effectToPlay]
        if not effect then
            return
        end
        effect(...)
    end)
end

return effectsController