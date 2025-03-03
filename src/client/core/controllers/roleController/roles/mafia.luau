local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local mouse = LocalPlayer:GetMouse()

local sharedPackages = ReplicatedStorage.sharedPackages
local network = require(sharedPackages.network)

local shared = ReplicatedStorage.shared

local getCharacter = require(shared.modules.getCharacter)
local rolesConfig = require(shared.configurations.roles)

local assets = ReplicatedStorage.assets
local mafiaHighlight = assets.mafiaHighlight
local revealHighlight = assets.revealHighlight
local mafiaKillHighlight = assets.mafiaKillHighlight:Clone()
local killBillboard = assets.killBillboard:Clone()

local mafiaServer = network.client.fromParent("mafia", ReplicatedStorage.RoleNetworks):expect()

local canKillConnection

local killDebounce = false
local targetCharacter
local mafiaMembers = {}
local witchMembers = {}

local mafia = {}

-- should add disconnect function later
function mafia.start()
    mafiaServer.nightVisionToggled:observe(mafia.onNightVision)
    mafiaServer.canKill:observe(mafia.onCanKill)
    mafiaServer.teamMembers:observe(mafia.onTeamMembersUpdate)
    ContextActionService:BindActionAtPriority("mafiaKill", mafia.handleMafiaKill, true, 3, Enum.KeyCode.E) -- TODO: custom keybinds!
    CollectionService:GetInstanceAddedSignal("MafiaHighlighted"):Connect(function(object)
        local highlight = revealHighlight:Clone()
        highlight.Parent = object
    end)
    CollectionService:GetInstanceRemovedSignal("MafiaHighlighted"):Connect(function(object)
        local highlight = object:FindFirstChild("revealHighlight")
        if highlight then
            highlight:Destroy()
        end
    end)
end

function mafia.onNightVision(nightVisionToggled)
    Lighting.NV.Enabled = nightVisionToggled
end

function mafia.handleMafiaKill(_, inputState)
    if inputState ~= Enum.UserInputState.End then
        return Enum.ContextActionResult.Pass
    end
    if not targetCharacter then
        return Enum.ContextActionResult.Pass
    end
    local player = Players:GetPlayerFromCharacter(targetCharacter)
    if not player then
        return Enum.ContextActionResult.Pass
    end
    task.spawn(function()
        mafia.setTargetCharacter(nil)
        killDebounce = true
        mafiaServer.onKill(player)
        killDebounce = false
    end)
    return Enum.ContextActionResult.Sink
end

function mafia.setTargetCharacter(character, textToAdd)
    mafiaKillHighlight.Parent = character
    killBillboard.TextLabel.Text = `E to {textToAdd or "kill"}`
    killBillboard.Parent = character
    targetCharacter = character
end

function mafia.onCanKill(canKill)
    if canKill and not canKillConnection then
        canKillConnection = RunService.RenderStepped:Connect(function()
            if killDebounce then
                mafia.setTargetCharacter(nil)
                return
            end
            local currentCamera = workspace.CurrentCamera
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            local filteredInstances = {}
            for _, player in Players:GetPlayers() do
                local character = player.Character
                if not character then
                    continue
                end
                -- TODO: whole character should be filtered if they're dead/ghost/etc if that gets added
                for _, child in character:GetChildren() do
                    if child:IsA("Accessory") or child.Name == "HumanoidRootPart" then
                        table.insert(filteredInstances, child)
                    end
                end
            end
            raycastParams.FilterDescendantsInstances = filteredInstances
            local unitRay: Ray = currentCamera:ScreenPointToRay(mouse.X, mouse.Y)
            local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
            local target = raycastResult.Instance
            local map = workspace:FindFirstChild("Map")
            if map then
                for _, closet in map.Closets:GetChildren() do
                    local door = closet:FindFirstChild("Door")
                    if door then
                        table.insert(filteredInstances, door)
                        continue
                    end
                    local doorL = closet:FindFirstChild("DoorL")
                    local doorR = closet:FindFirstChild("DoorR")
                    if doorL and doorR then
                        table.insert(filteredInstances, doorL)
                        table.insert(filteredInstances, doorR)
                        continue
                    end
                end
            end
            if not target then
                mafia.setTargetCharacter(nil)
                return
            end
            local character = getCharacter(target)
            if not character then
                raycastParams.FilterDescendantsInstances = filteredInstances
                raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
                target = raycastResult.Instance
                character = getCharacter(target)
                if not character or not character:HasTag("MafiaHighlighted") then
                    mafia.setTargetCharacter(nil)
                    return
                end
            end
            if not character or character:GetAttribute("Ragdolled") then
                mafia.setTargetCharacter(nil)
                return
            end
            local magnitude = (LocalPlayer.Character:GetPivot().Position-character:GetPivot().Position).Magnitude
            local player = Players:GetPlayerFromCharacter(character)
            if table.find(mafiaMembers, player.UserId) or table.find(witchMembers, player.UserId) then
                mafia.setTargetCharacter(nil)
                return
            end
            mafia.setTargetCharacter(character, if magnitude > 7 then "shoot" else "stab")
        end)
    elseif not canKill and canKillConnection then
        canKillConnection:Disconnect()
        canKillConnection = nil
        mafia.setTargetCharacter(nil)
    end
end

function mafia.onTeamMembersUpdate(teamMembers)
    for _, player in Players:GetPlayers() do
        local character = player.Character
        if not character then
            continue
        end
        local characterMafiaHighlight = character:FindFirstChild("mafiaHighlight")
        if characterMafiaHighlight then
            characterMafiaHighlight:Destroy()
        end
    end
    if teamMembers == nil then
        return
    end
    mafiaMembers = teamMembers.mafia
    witchMembers = teamMembers.witches
    local allTeamMembers = {}
    for _, v in mafiaMembers do
        table.insert(allTeamMembers, v)
    end
    for _, v in witchMembers do
        table.insert(allTeamMembers, v)
    end
    
    for _, userId in allTeamMembers do
        if userId == LocalPlayer.UserId then
            continue
        end
        local player = Players:GetPlayerByUserId(userId)
        local character = player.Character or player.CharacterAdded:Wait()
        local highlight = mafiaHighlight:Clone()
        highlight.Parent = character
    end
end

-- add a disconnect function to clean up connections

return mafia