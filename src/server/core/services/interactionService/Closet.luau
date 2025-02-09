local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local animations = ReplicatedStorage.assets.animations
local closetAnimations = animations.closet
local dummy1Animations = animations.dummy1
local dummy2Animations = animations.dummy2

local configurations = ReplicatedStorage.shared.configurations
local animationOffsets = require(configurations.animationOffsets)

local Closet = {}
Closet.__index = Closet

local previewAnimationsCache = {}

local function createPreviewAnimation(keyframeSequence)
    local previewAnimation = previewAnimationsCache[keyframeSequence]
    if not previewAnimation then
        local hashId = KeyframeSequenceProvider:RegisterKeyframeSequence(keyframeSequence)
        local Animation = Instance.new("Animation")
        Animation.AnimationId = hashId
        previewAnimationsCache[keyframeSequence] = Animation
        return Animation
    end
	return previewAnimation
end

function Closet.new(closet)
    local self = setmetatable({}, Closet)
    self.closet = closet
    self.storingCharacter = false
    self:init()
    return self
end

function Closet:init()
    local animationController = Instance.new("AnimationController")
    animationController.Parent = self.closet
    self.animator = Instance.new("Animator")
    self.animator.Parent = animationController
    self.closet:AddTag("Interactable")

    self.closetEnterAnimation = self.animator:LoadAnimation(closetAnimations["Entering Closet"])
    self.closetEnterAnimation.Priority = Enum.AnimationPriority.Action
    self.closetIdleAnimation = self.animator:LoadAnimation(closetAnimations["Idle Closet"])
    self.closetIdleAnimation.Looped = true
    self.closetIdleAnimation.Priority = Enum.AnimationPriority.Idle
end

function Closet:storeCharacter(character: Model)
    print("sdjifgiasdjhng")
    if self.debounce then
        return
    end
    if self.storingCharacter then
        self:unstoreCharacter(character)
        return
    end
    self.debounce = true
    self.storingCharacter = true
    local animator: Animator = character.Humanoid:FindFirstChildWhichIsA("Animator")

    local characterEnterAnimation = animator:LoadAnimation(dummy1Animations["Entering Closet"])
    characterEnterAnimation.Priority = Enum.AnimationPriority.Action

    self.characterIdleAnimation = animator:LoadAnimation(dummy1Animations["Idle Closet"])
    self.characterIdleAnimation.Looped = true
    self.characterIdleAnimation.Priority = Enum.AnimationPriority.Idle

    character.HumanoidRootPart.Anchored = true
    animationOffsets.closet(self.closet, character)
    characterEnterAnimation:Play()
    self.closetEnterAnimation:Play()
    task.wait(characterEnterAnimation.Length * 0.9)
    self.characterIdleAnimation:Play()
    self.closetIdleAnimation:Play()
    self.debounce = false
end

function Closet:unstoreCharacter(character: Model)
    print("sdjifgiasdjhng")
    if self.debounce then
        return
    end
    if not self.storingCharacter then
        self:storeCharacter(character)
        return
    end
    self.debounce = true
    self.storingCharacter = false
    local animator: Animator = character.Humanoid:FindFirstChildWhichIsA("Animator")

    local characterExitAnimation = animator:LoadAnimation(dummy1Animations["Exiting Closet"])
    local closetExitAnimation = self.animator:LoadAnimation(closetAnimations["Exiting Closet"])
    characterExitAnimation.Priority = Enum.AnimationPriority.Action
    closetExitAnimation.Priority = Enum.AnimationPriority.Action

    character.HumanoidRootPart.Anchored = true
    animationOffsets.closet(self.closet, character)
    characterExitAnimation:Play()
    closetExitAnimation:Play()
    task.wait(characterExitAnimation.Length * 0.9)
    self.characterIdleAnimation:Stop()
    self.closetIdleAnimation:Stop()
    character.HumanoidRootPart.Anchored = false
    self.debounce = false
end

return Closet