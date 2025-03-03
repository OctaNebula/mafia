local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local shared = ReplicatedStorage.shared
local serviceUtil = require(shared.utilities.serviceUtil)
local effectsService = serviceUtil.service("effectsService")

local effects = script.effects

local effectsController = {}

function effectsController.start()
    effectsService.playEffect:connect(function(effectToPlay, ...)
        local effect = effects:FindFirstChild(effectToPlay)
        if not effect then
            return
        end
        require(effect)(...)
    end)
end

return effectsController