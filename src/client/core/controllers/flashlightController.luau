local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local controllers = ReplicatedStorage.client.controllers
local armController = require(controllers.armController)

local assets = ReplicatedStorage.assets
local animations = assets.animations.player1
local flashlightToggleAnim = animations.FlashlightToggle
local flashlightEquipAnim = animations.FlashlightEquip
local flashlightHoldAnim = animations.FlashlightHold

local shared = ReplicatedStorage.shared

local serviceUtil = require(shared.utilities.serviceUtil)
local flashlightService = serviceUtil.service("flashlightService")

local flashlightController = {}

function flashlightController.start()
    local character
    local loadedAnimations
    local flashlightToggled
    local function characterAdded(newCharacter)
        loadedAnimations = nil
        character = newCharacter
        local humanoid = character:WaitForChild("Humanoid")
        local animator = humanoid:FindFirstChildWhichIsA("Animator")
        loadedAnimations = {
            toggle = animator:LoadAnimation(flashlightToggleAnim),
            equip = animator:LoadAnimation(flashlightEquipAnim),
            hold = animator:LoadAnimation(flashlightHoldAnim),
        }
        loadedAnimations.toggle.Priority = Enum.AnimationPriority.Action
        loadedAnimations.equip.Priority = Enum.AnimationPriority.Action
        loadedAnimations.hold.Priority = Enum.AnimationPriority.Idle
        loadedAnimations.hold.Looped = true
    end
    LocalPlayer.CharacterAdded:Connect(characterAdded)
    if LocalPlayer.Character then
        characterAdded(LocalPlayer.Character)
    end
    LocalPlayer.CharacterRemoving:Connect(function()
        loadedAnimations = nil
    end)
    flashlightService.flashlightEquipped:observe(function(newFlashlightEquipped, oldFlashlightEquipped)
        -- check if it's equipping (false -> true)
        if not newFlashlightEquipped or oldFlashlightEquipped or not loadedAnimations then
            return
        end
        flashlightToggled = true
        loadedAnimations.hold:Play()
        armController.setIsPointing:Fire("flashlightController", true)
    end)
    ContextActionService:BindAction("flashlightToggle", function(_, inputState)
        if inputState ~= Enum.UserInputState.End then
            return Enum.ContextActionResult.Pass
        end
        if not loadedAnimations then
            return Enum.ContextActionResult.Pass
        end
        print("Flashlight toggle input received!")
        loadedAnimations.toggle:Play()
        print(not flashlightToggled)
        flashlightToggled = not flashlightToggled
        local flashlight = character:WaitForChild("Flashlight")
        local attachment = flashlight.Light.light1.LightAttachment
        attachment.SpotLight.Enabled = flashlightToggled
        attachment.SpotLight1.Enabled = flashlightToggled
        flashlightService.toggleFlashlight:fireServer(flashlightToggled)
    end, true, Enum.KeyCode.F)
end

return flashlightController