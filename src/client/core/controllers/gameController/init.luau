local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local StarterGUI = game:GetService("StarterGui")

local shared = ReplicatedStorage.shared

local serviceUtil = require(shared.utilities.serviceUtil)
local gameService = serviceUtil.service("gameService")

local configurations = ReplicatedStorage.shared.configurations
local roles = require(configurations.roles)

local gameController = {}

function gameController.start()
    task.spawn(gameController.disableResetButton)
end

function gameController.disableResetButton()
    repeat
        local success = pcall(function() 
            StarterGUI:SetCore("ResetButtonCallback", false)
        end)
        task.wait()
    until success
end

return gameController