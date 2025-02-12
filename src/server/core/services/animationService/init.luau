local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local sharedPackages = ReplicatedStorage.sharedPackages

local network = require(sharedPackages.network)
local Signal = require(sharedPackages.Signal)

local animations = ReplicatedStorage.assets.animations
local playerAnimations = {table.unpack(animations.player1:GetChildren()), table.unpack(animations.player2:GetChildren())}

local animationService = {}

function animationService.start()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            local humanoid = character.Humanoid
            local animator = humanoid:FindFirstChildWhichIsA("Animator")
            for _, animation in playerAnimations do
                animator:LoadAnimation(animation)
            end
        end)
    end)
end

return animationService