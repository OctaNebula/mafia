local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local animations = ReplicatedStorage.assets.animations
local closetAnimations = animations.closet
local player1Animations = animations.player1
local player2Animations = animations.player2

local configurations = ReplicatedStorage.shared.configurations
local animationOffsets = require(configurations.animationOffsets)

local Closet = {}
Closet.__index = Closet

function Closet.new(instance, interactionService)
    local self = setmetatable({}, Closet)
    self.storedCharacter = false
    self.interactionService = interactionService
    self.instance = instance
    self:init()
    return self
end

function Closet:init()
    local animationController = Instance.new("AnimationController")
    animationController.Parent = self.instance
    self.animator = Instance.new("Animator")
    self.animator.Parent = animationController

    self.closetEnterAnimation = self.animator:LoadAnimation(closetAnimations["Entering Closet"])
    self.closetEnterAnimation.Priority = Enum.AnimationPriority.Action
    self.closetIdleAnimation = self.animator:LoadAnimation(closetAnimations["Idle Closet"])
    self.closetIdleAnimation.Priority = Enum.AnimationPriority.Idle
    self.closetIdleAnimation.Looped = true
    self.closetExitAnimation = self.animator:LoadAnimation(closetAnimations["Exiting Closet"])
    self.closetExitAnimation.Priority = Enum.AnimationPriority.Action
end

function Closet:interact(player: Player)
    local character = player.Character
    if not character or self.debounce or self.interactionService.setExclusiveInteraction(player, self.instance, nil) == false then
        return false
    end
    self.debounce = true
    self.interactionService.editPrompt(self.instance, { enabled = false })
    if not self.storedCharacter then
        self:storeCharacter(character)
        self.storedCharacter = character
    else
        self:unstoreCharacter(character)
        self.storedCharacter = false
    end
    if not self.storedCharacter then
        self.interactionService.editPrompt(self.instance, { enabled = true })
    else
        self.interactionService.setExclusiveInteraction(player, self.instance, {
            exit = Enum.KeyCode.E
        })
    end
    self.debounce = false
    return true
end

function Closet:enter(player: Player)
    
end

function Closet:exit(player: Player)
    local character = player.Character
    if not character or self.debounce or self.interactionService.setExclusiveInteraction(player, self.instance, nil) == false then
        return false
    end
    print("Valid Exit input received!")
    self.debounce = true
    self:unstoreCharacter(character)
    self.storedCharacter = false
    self.interactionService.editPrompt(self.instance, { enabled = true })
    self.debounce = false
    return true
end

function Closet:storeCharacter(character: Model)
    local animator: Animator = character.Humanoid:FindFirstChildWhichIsA("Animator")

    local characterEnterAnimation = animator:LoadAnimation(player1Animations["Entering Closet"])
    characterEnterAnimation.Priority = Enum.AnimationPriority.Action

    self.characterIdleAnimation = animator:LoadAnimation(player1Animations["Idle Closet"])
    self.characterIdleAnimation.Looped = true
    self.characterIdleAnimation.Priority = Enum.AnimationPriority.Idle

    character.HumanoidRootPart.Anchored = true
    animationOffsets.closet(self.instance, character)
    characterEnterAnimation:Play()
    self.closetEnterAnimation:Play()
    task.wait(self.closetEnterAnimation.Length * 0.9)
    self.characterIdleAnimation:Play()
    self.closetIdleAnimation:Play()
    character.Humanoid.AutoRotate = false
end

function Closet:unstoreCharacter(character: Model)
    local animator: Animator = character.Humanoid:FindFirstChildWhichIsA("Animator")

    local characterExitAnimation = animator:LoadAnimation(player1Animations["Exiting Closet"])
    characterExitAnimation.Priority = Enum.AnimationPriority.Action

    character.HumanoidRootPart.Anchored = true
    animationOffsets.closet(self.instance, character)
    characterExitAnimation:Play()
    self.closetExitAnimation:Play()
    task.wait(self.closetExitAnimation.Length * 0.9)
    self.characterIdleAnimation:Stop()
    self.closetIdleAnimation:Stop()
    character.HumanoidRootPart.Anchored = false
    character.Humanoid.AutoRotate = true
end

return Closet