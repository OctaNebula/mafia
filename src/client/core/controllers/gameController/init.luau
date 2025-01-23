local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGUI = game:GetService("StarterGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local shared = ReplicatedStorage.shared

local controllers = ReplicatedStorage.client.controllers
local soundController = require(controllers.soundController)
local uiController = require(controllers.uiController)

local serviceUtil = require(shared.utilities.serviceUtil)
local gameService = serviceUtil.service("gameService")

local gameController = {}

function gameController.start()
    task.spawn(gameController.disableResetButton)
    gameService.setTopbarText:connect(gameController.onSetTopbarText)
    gameService.setFadeProperty:connect(gameController.onSetFadeProperty)
    gameService.countdownTimer:connect(gameController.onCountdownTimer)
    gameService.toggleAudio:connect(gameController.onToggleAudio)

    gameService.gamePhase:observe(gameController.onGamePhaseUpdate)

    gameService.lightsToggled:observe(gameController.onLightsToggledUpdate)
    gameService.chatToggled:observe(gameController.onChatToggledUpdate)
    gameService.firstPersonForced:observe(gameController.onFirstPersonForcedUpdate)
end

function gameController.disableResetButton()
    repeat
        local success = pcall(function()
            StarterGUI:SetCore("ResetButtonCallback", false)
        end)
        task.wait()
    until success
end

function gameController.onSetTopbarText(props)
    if not props then
        uiController:setTopbarProps()
        return
    end
    uiController:setTopbarProps(props.targetText, props.initialText, props.typewriterDelay)
end

function gameController.onSetFadeProperty(props)
    if not props then
        uiController:setFadeProps()
        return
    end
    uiController:setFadeProps(props.transparency, props.duration, props.easing)
end

function gameController.onCountdownTimer(props)
    -- print(props)
end

function gameController.onToggleAudio(props)
    local sound = props.sound
    local playing = props.playing
    local duration = props.duration
    local volume = props.volume
    soundController.play2DAudio(sound, playing, duration, volume)
    -- print(sound)
end

function gameController.onGamePhaseUpdate(newPhase)
    -- print("New phase:", newPhase)
end

function gameController.onLightsToggledUpdate(newLightsToggled)
    -- print("New lights toggled:", newLightsToggled)
    local map = workspace:WaitForChild("Map", 10)
    
    if not map then
        return
    end
    local lights = map:WaitForChild("Lights"):GetDescendants()
    if not newLightsToggled then
        for _, light in lights do
            if light:IsA("PointLight") or light:IsA("SpotLight") or light:IsA("SurfaceLight") then
                if not light.Parent:IsA("Attachment") then
                    local sillygooberthing = nil
                    if light.Parent ~= nil and light.Parent:IsA("BasePart") then
                        if light.Parent.Material == Enum.Material.Neon then
                            sillygooberthing = light.Parent
                            light.Parent:SetAttribute("Sillied", true)
                        end
                    end
                    task.spawn(function()
                        task.wait(math.random(0, 10)/50)
                        light.Enabled = false
                        if sillygooberthing ~= nil then
                            sillygooberthing.Transparency = 1
                        end
                        task.wait(math.random(0, 10)/50)
                        light.Enabled = true
                        if sillygooberthing ~= nil then
                            sillygooberthing.Transparency = 0
                        end
                        task.wait(math.random(0, 10)/50)
                        light.Enabled = false
                        if sillygooberthing ~= nil then
                            sillygooberthing.Transparency = 1
                        end
                    end)
                end
            else
                if light:IsA("Beam") then
                    local oldtransparency = light.Transparency
                    light:SetAttribute("oldtransparency", oldtransparency)
                    task.spawn(function()
                        task.wait(math.random(0, 10)/50)
                        light.Transparency = NumberSequence.new(1)
                        task.wait(math.random(0, 10)/50)
                        light.Transparency = oldtransparency
                        task.wait(math.random(0, 10)/50)
                        light.Transparency = NumberSequence.new(1)
                    end)
                end
            end
        end
    else
        for _, light in lights do
            if light:IsA("PointLight") or light:IsA("SurfaceLight") or light:IsA("SpotLight") then
                if not light.Parent:IsA("Attachment") then
                    local sillygooberthing = nil
                    if light.Parent ~= nil and light.Parent:IsA("BasePart") then
                        if light.Parent.Material == Enum.Material.Neon then
                            sillygooberthing = light.Parent
                            light.Parent:SetAttribute("Sillied", true)
                        end
                    end
                    task.spawn(function()
                        light.Enabled = true
                        if sillygooberthing ~= nil then
                            sillygooberthing.Transparency = 0
                        end
                    end)
                end
            else
                if light:IsA("Beam") then
                    local oldtransparency = light:GetAttribute("oldtransparency")
                    if not oldtransparency then
                        continue
                    end
                    task.spawn(function()
                        light.Transparency = oldtransparency
                    end)
                end
            end
        end
    end
end

function gameController.onChatToggledUpdate(newChatToggled)
    -- print("New chat toggled:", newChatToggled)
    StarterGUI:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, newChatToggled or false)
end

function gameController.onFirstPersonForcedUpdate(newFirstPersonForced)
    -- print("New first person forced:", newFirstPersonForced)
    if newFirstPersonForced then
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    else
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = 30
        LocalPlayer.CameraMinZoomDistance = 10
    end
end

return gameController