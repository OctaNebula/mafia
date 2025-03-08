-- this module is not intended to be require'd more than once so dont do that pls
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local animations = ReplicatedStorage.assets.animations
local closetAnimations = animations.closet
local player1Animations = animations.player1
local player2Animations = animations.player2

local sharedPackages = ReplicatedStorage.sharedPackages
local Signal = require(sharedPackages.Signal)

local shared = ReplicatedStorage.shared

local mafiaHighlightTimer = require(script.Parent.components.mafiaHighlightTimer).init(10, 10, 5)

local services = ServerStorage.server.services
local ragdollService = require(services.ragdollService)
local gameService = require(services.gameService)

local configurations = shared.configurations
local animationOffsets = require(configurations.animationOffsets)

local loadAnimation = require(shared.modules.loadAnimation)

local Closet = {}

Closet.__index = Closet

function Closet.new(instance, interactionService)
    local self = setmetatable({}, Closet)
    self.characterChecking = nil
    self.characterStored = nil
    self.interactionService = interactionService
    self.instance = instance
    self.characterConnections = {}
    self:init()
    return self
end

function Closet:init()
    local animationController = Instance.new("AnimationController")
    animationController.Parent = self.instance
    self.animator = Instance.new("Animator")
    self.animator.Parent = animationController

    self.closetEnterAnimation = loadAnimation(self.animator, closetAnimations["Entering Closet"])
    self.closetEnterAnimation.Priority = Enum.AnimationPriority.Action
    self.closetCheckingIdleAnimation = loadAnimation(self.animator, closetAnimations["Checking Closet Idle"])
    self.closetCheckingIdleAnimation.Priority = Enum.AnimationPriority.Idle
    self.closetCheckingIdleAnimation.Looped = true
    self.closetExitAnimation = loadAnimation(self.animator, closetAnimations["Exiting Closet"])
    self.closetExitAnimation.Priority = Enum.AnimationPriority.Action
end

function Closet:cleanup()
    print("Resetting Closet", self.instance)
    for _, character in {self.characterChecking, self.characterStored} do
        if character then
            local humanoid: Humanoid = character.Humanoid
            local animator: Animator = humanoid:FindFirstChildWhichIsA("Animator")
            for _, animation in animator:GetPlayingAnimationTracks() do
                animation:Stop()
            end
            character.HumanoidRootPart.Anchored = false
            if self.characterStored == character then
                character:SetAttribute("RagdollImmune", false)
                ragdollService.setRagdoll:Fire(character, true)
            end
        end
    end

    self.characterChecking = nil
    self.characterStored = nil
    mafiaHighlightTimer.disableAllTimers()
end

function Closet:updateCharacter(player: Player, character: Model)
    local connections = self.characterConnections[character]
    if not connections then
        connections = {}
        self.characterConnections[character] = connections
    end
    for _, connection in connections do
        connection:Disconnect()
    end
    if character == self.characterStored then
        character:SetAttribute("RagdollImmune", true)
        connections.downed = character:GetAttributeChangedSignal("Downed"):Connect(function()
            local downed = character:GetAttribute("Downed")
            if not downed then
                return
            end
            gameService.setCameraLockedToHead:Fire(player, false)
            local animator: Animator = character.Humanoid:FindFirstChildWhichIsA("Animator")
            local characterIdleAnimation = loadAnimation(animator, player1Animations["Idle Closet"])
            characterIdleAnimation.Priority = Enum.AnimationPriority.Idle
            characterIdleAnimation.Looped = true
            characterIdleAnimation:Play(nil, nil, 0.2)
        end)
        connections.death = character:GetAttributeChangedSignal("Dead"):Connect(function()
            local dead = character:GetAttribute("Dead")
            if not dead then
                return
            end
            local animator: Animator = character.Humanoid:FindFirstChildWhichIsA("Animator")
            local characterIdleAnimation = loadAnimation(animator, player1Animations["Idle Closet"])
            characterIdleAnimation.Priority = Enum.AnimationPriority.Idle
            characterIdleAnimation.Looped = true
            characterIdleAnimation:Play(nil, nil, 0)
        end)
    else
        character:SetAttribute("RagdollImmune", false)
    end
end

function Closet:interact(player: Player, actionName: string?)
    local character = player.Character
    local hasExclusiveInteraction = self.interactionService.hasExclusiveInteraction(player, self.instance)
    if not character or character:GetAttribute("Downed") or self.busy or hasExclusiveInteraction == false then
        return false
    end
    self.busy = true
    self.interactionService.editPrompt(self.instance, { enabled = false })
    if character == self.characterChecking then
        if actionName == "enter" then
            if self.characterStored then
                self.busy = false
                return false
            end
            self.interactionService.setExclusiveInteraction(player, self.instance, nil)
            gameService.setCameraLockedToHead:Fire(player, true)
            self.characterChecking = nil
            self.characterStored = character
            self:updateCharacter(player, character)
            self:playStoreCharacterAnim(character)
            self.interactionService.setExclusiveInteraction(player, self.instance, {
                began = {
                    exit = {
                        Enum.KeyCode.W,
                        Enum.KeyCode.A,
                        Enum.KeyCode.S,
                        Enum.KeyCode.D
                    }
                },
                ended = {
                    exit = Enum.KeyCode.E
                }
            }, {
                instance = self.instance.Base,
                image = "rbxassetid://17368931705",
                key = "E",
            })
            mafiaHighlightTimer.toggleTimer(player, true)
        elseif actionName == "cancel" then
            self.interactionService.setExclusiveInteraction(player, self.instance, nil)
            self.characterChecking = nil
            self:updateCharacter(player, character)
            self:stopCharacterCheckAnim(character)
            gameService.setCameraLockedToHead:Fire(player, false)
        else
            warn(`actionName "enter" or "cancel" expected, got {actionName}`)
        end
    elseif character == self.characterStored then
        if self.characterChecking or character:GetAttribute("Downed") then
            self.busy = false
            return false
        end
        mafiaHighlightTimer.toggleTimer(player, false)
        self.interactionService.setExclusiveInteraction(player, self.instance, nil)
        self.characterStored = nil
        self:updateCharacter(player, character)
        self:playUnstoreCharacterAnim(character)
        gameService.setCameraLockedToHead:Fire(player, false)
    else
        if self.characterChecking then
            self.busy = false
            return false
        end
        self.interactionService.setExclusiveInteraction(player, self.instance, nil)
        gameService.setCameraLockedToHead:Fire(player, true)
        self.characterChecking = character
        self:updateCharacter(player, character)
        self:playCharacterCheckAnim(character)
        self.interactionService.setExclusiveInteraction(player, self.instance, {
            began = {
                cancel = {
                    Enum.KeyCode.W,
                    Enum.KeyCode.A,
                    Enum.KeyCode.S,
                    Enum.KeyCode.D
                }
            },
            ended = {
                enter = Enum.KeyCode.E
            }
        }, {
            instance = self.instance.Base,
            image = "rbxassetid://17368931705",
            key = "E",
        })
    end

    if self.characterChecking then
        self.interactionService.editPrompt(self.instance, { enabled = false })
    else
        self.interactionService.editPrompt(self.instance, { enabled = true })
    end

    self.busy = false
    return true
end

function Closet:playCharacterCheckAnim(character: Model)
    local animator: Animator = character.Humanoid:FindFirstChildWhichIsA("Animator")

    local closetEnterAnimation: AnimationTrack = loadAnimation(self.animator, closetAnimations["Entering Closet"])
    closetEnterAnimation.Priority = Enum.AnimationPriority.Action

    local closetCheckingIdleAnimation: AnimationTrack = loadAnimation(self.animator, closetAnimations["Checking Closet Idle"])
    closetCheckingIdleAnimation.Priority = Enum.AnimationPriority.Idle
    closetCheckingIdleAnimation.Looped = true

    local characterEnterAnimation: AnimationTrack = loadAnimation(animator, player1Animations["Entering Closet"])
    characterEnterAnimation.Priority = Enum.AnimationPriority.Action

    local characterCheckingIdleAnimation: AnimationTrack = loadAnimation(animator, player1Animations["Checking Closet Idle"])
    characterCheckingIdleAnimation.Priority = Enum.AnimationPriority.Idle
    characterCheckingIdleAnimation.Looped = true

    character.HumanoidRootPart.Anchored = true
    character.Humanoid.AutoRotate = false
    animationOffsets.closet(self.instance, character)
    characterEnterAnimation:Play(nil, nil, 0.6)
    closetEnterAnimation:Play(nil, nil, 0.6)
    task.wait(0.1)
    characterCheckingIdleAnimation:Play()
    closetCheckingIdleAnimation:Play()
    closetEnterAnimation:GetMarkerReachedSignal("Checking"):Wait()
    characterEnterAnimation:AdjustWeight(0.01)
    closetEnterAnimation:AdjustWeight(0.01)
    characterEnterAnimation:AdjustSpeed(0)
    closetEnterAnimation:AdjustSpeed(0)
end

function Closet:stopCharacterCheckAnim(character: Model)
    local animator: Animator = character.Humanoid:FindFirstChildWhichIsA("Animator")

    local closetEnterAnimation = loadAnimation(self.animator, closetAnimations["Entering Closet"])
    closetEnterAnimation.Priority = Enum.AnimationPriority.Action

    local closetCheckingIdleAnimation = loadAnimation(self.animator, closetAnimations["Checking Closet Idle"])
    closetCheckingIdleAnimation.Priority = Enum.AnimationPriority.Idle
    closetCheckingIdleAnimation.Looped = true

    local characterCheckingIdleAnimation = loadAnimation(animator, player1Animations["Checking Closet Idle"])
    characterCheckingIdleAnimation.Priority = Enum.AnimationPriority.Idle
    characterCheckingIdleAnimation.Looped = true

    local characterEnterAnimation = loadAnimation(animator, player1Animations["Entering Closet"])
    characterEnterAnimation.Priority = Enum.AnimationPriority.Action

    animationOffsets.closet(self.instance, character)
    characterEnterAnimation:Stop()
    closetEnterAnimation:Stop()
    characterCheckingIdleAnimation:Stop()
    closetCheckingIdleAnimation:Stop()
    character.HumanoidRootPart.Anchored = false
    character.Humanoid.AutoRotate = true
end

function Closet:playStoreCharacterAnim(character: Model)
    local animator: Animator = character.Humanoid:FindFirstChildWhichIsA("Animator")

    local closetEnterAnimation = loadAnimation(self.animator, closetAnimations["Entering Closet"])
    closetEnterAnimation.Priority = Enum.AnimationPriority.Action

    local closetCheckingIdleAnimation = loadAnimation(self.animator, closetAnimations["Checking Closet Idle"])
    closetCheckingIdleAnimation.Priority = Enum.AnimationPriority.Idle
    closetCheckingIdleAnimation.Looped = true

    local characterEnterAnimation = loadAnimation(animator, player1Animations["Entering Closet"])
    characterEnterAnimation.Priority = Enum.AnimationPriority.Action

    local characterIdleAnimation = loadAnimation(animator, player1Animations["Idle Closet"])
    characterIdleAnimation.Priority = Enum.AnimationPriority.Idle
    characterIdleAnimation.Looped = true

    local characterCheckingIdleAnimation = loadAnimation(animator, player1Animations["Checking Closet Idle"])
    characterCheckingIdleAnimation.Priority = Enum.AnimationPriority.Idle
    characterCheckingIdleAnimation.Looped = true

    character.HumanoidRootPart.Anchored = true
    character.Humanoid.AutoRotate = false
    animationOffsets.closet(self.instance, character)
    characterCheckingIdleAnimation:Stop()
    closetCheckingIdleAnimation:Stop()
    characterEnterAnimation:AdjustSpeed(1)
    characterEnterAnimation:AdjustWeight(1)
    closetEnterAnimation:AdjustSpeed(1)
    closetEnterAnimation:AdjustWeight(1)
    task.wait((closetEnterAnimation.Length - closetEnterAnimation.TimePosition) * 0.9)
    characterIdleAnimation:Play()
    closetEnterAnimation.Ended:Wait()
end

function Closet:playUnstoreCharacterAnim(character: Model)
    local animator: Animator = character.Humanoid:FindFirstChildWhichIsA("Animator")

    local closetExitAnimation = loadAnimation(self.animator, closetAnimations["Exiting Closet"])
    closetExitAnimation.Priority = Enum.AnimationPriority.Action

    local characterIdleAnimation = loadAnimation(animator, player1Animations["Idle Closet"])
    characterIdleAnimation.Priority = Enum.AnimationPriority.Idle
    characterIdleAnimation.Looped = true

    local characterExitAnimation = loadAnimation(animator, player1Animations["Exiting Closet"])
    characterExitAnimation.Priority = Enum.AnimationPriority.Action

    animationOffsets.closet(self.instance, character)
    characterExitAnimation:Play()
    closetExitAnimation:Play()
    task.wait(closetExitAnimation.Length * 0.9)
    characterIdleAnimation:Stop()
    closetExitAnimation.Ended:Wait()
    character.HumanoidRootPart.Anchored = false
    character.Humanoid.AutoRotate = true
end

return Closet