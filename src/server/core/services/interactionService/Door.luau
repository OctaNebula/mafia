-- this module is not intended to be require'd more than once so dont do that pls
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local animations = ReplicatedStorage.assets.animations
local doorAnimations = animations.door

local shared = ReplicatedStorage.shared

local services = ServerStorage.server.services
local gameService = require(services.gameService)

local configurations = shared.configurations
local animationOffsets = require(configurations.animationOffsets)

local loadAnimation = require(shared.modules.loadAnimation)

local Door = {}

Door.__index = Door

function Door.new(instance, interactionService)
    local self = setmetatable({}, Door)
    self.interactionService = interactionService
    self.instance = instance
    self.opened = false
    self:init()
    return self
end

function Door:init()
    self.instance.Base.Anchored = true

    local animationController = Instance.new("AnimationController")
    animationController.Parent = self.instance
    self.animator = Instance.new("Animator")
    self.animator.Parent = animationController

    self.DoorOpeningAnimation = loadAnimation(self.animator, doorAnimations["Opening Door"])
    self.DoorOpeningAnimation.Priority = Enum.AnimationPriority.Action
    self.DoorClosingAnimation = loadAnimation(self.animator, doorAnimations["Closing Door"])
    self.DoorClosingAnimation.Priority = Enum.AnimationPriority.Action
    self.DoorIdleAnimation = loadAnimation(self.animator, doorAnimations["Idle Door"])
    self.DoorIdleAnimation.Priority = Enum.AnimationPriority.Idle
    self.DoorIdleAnimation.Looped = true
end

function Door:cleanup()
    print("Resetting Door", self.instance)
    for _, animationTrack in self.animator:GetPlayingAnimationTracks() do
        animationTrack:Stop()
    end
    self.opened = false
end

function Door:interact(player: Player)
    local character = player.Character
    local hasExclusiveInteraction = self.interactionService.hasExclusiveInteraction(player, self.instance)
    if not character or character:GetAttribute("Downed") or self.busy or hasExclusiveInteraction == false then
        return false
    end
    self.busy = true
    self.interactionService.editPrompt(self.instance, { enabled = false })
    if not self.opened then
        self.DoorOpeningAnimation:Play()
        task.wait(self.DoorOpeningAnimation.Length * 0.8)
        self.DoorIdleAnimation:Play()
    else
        self.DoorClosingAnimation:Play()
        task.wait(self.DoorClosingAnimation.Length * 0.8)
        self.DoorIdleAnimation:Stop()
    end
    self.opened = not self.opened
    self.interactionService.editPrompt(self.instance, { enabled = true })
    self.busy = false
    return true
end

return Door