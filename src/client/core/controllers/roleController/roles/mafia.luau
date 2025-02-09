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
local mafiaKillHighlight = assets.mafiaKillHighlight:Clone()
local killBillboard = assets.killBillboard:Clone()

local mafiaServer = network.client.fromParent("mafia", ReplicatedStorage.RoleNetworks):expect()

local canKillConnection

local targetCharacter
local mafiaMembers = {}
local witchMembers = {}

local mafia = {}

-- should add destroy function later
function mafia.start()
    mafiaServer.nightVisionToggled:observe(mafia.onNightVision)
    mafiaServer.canKill:observe(mafia.onCanKill)
    mafiaServer.teamMembers:observe(mafia.onTeamMembersUpdate)
    ContextActionService:BindAction("mafiaKill", mafia.handleMafiaKill, true, Enum.KeyCode.E) -- TODO: custom keybinds!
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
    mafiaServer.killTarget:fireServer(player)
    mafia.setTargetCharacter(nil)
end

function mafia.setTargetCharacter(character)
    mafiaKillHighlight.Parent = character
    killBillboard.Parent = character
    targetCharacter = character
end

function mafia.onCanKill(canKill)
    if canKillConnection then
        canKillConnection:Disconnect()
        mafia.setTargetCharacter(nil)
    end
    if canKill then
        canKillConnection = RunService.RenderStepped:Connect(function()
            local target = mouse.Target
            if not target then
                mafia.setTargetCharacter(nil)
                return
            end
            local character = getCharacter(target)
            if not character or character:GetAttribute("Ragdolled") then
                mafia.setTargetCharacter(nil)
                return
            end
            local magnitude = (LocalPlayer.Character:GetPivot().Position-character:GetPivot().Position).Magnitude
            if magnitude > 7 then
                mafia.setTargetCharacter(nil)
                return
            end
            local player = Players:GetPlayerFromCharacter(character)
            if table.find(mafiaMembers, player.UserId) or table.find(witchMembers, player.UserId) then
                return
            end
            mafia.setTargetCharacter(character)
        end)
    end
end

function mafia.onTeamMembersUpdate(teamMembers)
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
        highlight.Parent = character -- need to clean up when updated, although not actually necessary right now
    end
end

-- add a destroy function to clean up connections

return mafia