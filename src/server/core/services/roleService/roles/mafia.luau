local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local sharedPackages = ReplicatedStorage.sharedPackages

local network = require(sharedPackages.network)

local services = ServerStorage.server.services
local effectsService = require(services.effectsService)
local gameService = require(services.gameService)

local roleParser = require(script.Parent.Parent.roleParser)

local shared = ReplicatedStorage.shared
local loadAnimation = require(shared.modules.loadAnimation)

local assets = ReplicatedStorage.assets
local animations = assets.animations
local player1Animations = animations.player1
local player2Animations = animations.player2
local models = assets.models
local knife = models.Knife
local gun = models.Gun

local currentPlayersInTeam = {}
local connections = {}
local killDebounce = false

local mafia = {
    client = {
        nightVisionToggled = network.Server.RemoteProperty.new(false),
        canKill = network.Server.RemoteProperty.new(false),
        teamMembers = network.Server.RemoteProperty.new(nil),
    }
}

function mafia.start()
    gameService.playersInfo:observe(mafia.onPlayersInfoChanged)
    gameService.client.gamePhase:observe(mafia.onGameStateChanged)
    gameService.client.abilitiesEnabled:observe(mafia.onGameStateChanged)
end

function mafia.characterAdded(character)
    local animator = character.Humanoid:FindFirstChildWhichIsA("Animator")
    local knifeTrack: AnimationTrack = loadAnimation(animator, player1Animations.KnifeSwing)
    knifeTrack.Priority = Enum.AnimationPriority.Action
    local gunTrack: AnimationTrack = loadAnimation(animator, player1Animations.Glock)
    gunTrack.Priority = Enum.AnimationPriority.Action
end

function mafia.onPlayersInfoChanged(newPlayersInfo, oldPlayersInfo)
    for _, connection in connections do
        connection:Disconnect()
    end
    local mafiaMembers = {}
    local witchMembers = {}
    if newPlayersInfo then
        for userId, playerInfo in newPlayersInfo do
            if not playerInfo.alive then
                continue
            end
            if playerInfo.role == "mafia" then
                table.insert(mafiaMembers, userId)
                local player = Players:GetPlayerByUserId(userId)
                local character = player.Character
                if character then
                    mafia.characterAdded(character)
                end
                if connections[userId] then
                    connections[userId]:Disconnect()
                    connections[userId] = nil
                end
                connections[userId] = player.CharacterAdded:Connect(mafia.characterAdded)
            elseif playerInfo.role == "witch" then -- check if the witch is on mafia or civilian side
                table.insert(witchMembers, userId)
            end
        end
    end

    local playersToAdd, playersToRemove = roleParser(newPlayersInfo or {}, oldPlayersInfo, function(_, playerInfo)
        return playerInfo.role == "mafia" --or playerInfo.role == "witch"
    end)

    print(playersToAdd, playersToRemove, mafiaMembers, witchMembers)

    currentPlayersInTeam = playersToAdd

    -- remove for old mafia members
    mafia.client.teamMembers:setForClients(playersToRemove, nil)
    mafia.client.canKill:setForClients(playersToRemove, nil)
    mafia.client.teamMembers:setForClients(playersToAdd, {
        mafia = mafiaMembers,
        witches = witchMembers
    })

end

function mafia.onGameStateChanged()
    local gamePhase = gameService.client.gamePhase:get()
    local abilitiesEnabled = gameService.client.abilitiesEnabled:get()

    if gamePhase == "Night" and abilitiesEnabled then
        killDebounce = false
        mafia.client.nightVisionToggled:setForClients(currentPlayersInTeam, true)
        mafia.client.canKill:setForClients(currentPlayersInTeam, true)
    else
        mafia.client.nightVisionToggled:setForClients(currentPlayersInTeam, false)
        mafia.client.canKill:setForClients(currentPlayersInTeam, false)
    end
end

function mafia.client.onKill(killer, victim)
    if killDebounce then
        return
    end

    if not table.find(currentPlayersInTeam, killer) then
        return
    end

    -- TODO: check if the victim is a witch (im lazy to do it rn)
    if table.find(currentPlayersInTeam, victim) then
        return
    end

    local killerCharacter = killer.Character
    local victimCharacter = victim.Character

    local magnitude = (killerCharacter:GetPivot().Position-victimCharacter:GetPivot().Position).Magnitude

    killDebounce = true
    mafia.client.canKill:setForClients(currentPlayersInTeam, false)
    if magnitude <= 7 then
        print("animation should be playing here")
        local knifeClone = knife:Clone()
        knifeClone.RightHand.Part1 = killerCharacter.RightHand
        knifeClone.Parent = killerCharacter
        local animationTrack: AnimationTrack = loadAnimation(killerCharacter.Humanoid:FindFirstChildWhichIsA("Animator"), player1Animations.KnifeSwing)
        animationTrack:Play()
        task.wait(0.1)
        gameService.killPlayer:Fire(killer, victim, "Knife Wound")
        effectsService.playOnClients:Fire(Players:GetPlayers(), "knifeWound", killerCharacter, victimCharacter)
        animationTrack.Ended:Wait()
        knifeClone:Destroy()
    elseif magnitude > 7 then
        local gunClone = gun:Clone()
        gunClone.RightHand.Part1 = killerCharacter.RightHand
        gunClone.Parent = killerCharacter
        killerCharacter.HumanoidRootPart.Anchored = true
        local animationTrack: AnimationTrack = loadAnimation(killerCharacter.Humanoid:FindFirstChildWhichIsA("Animator"), player1Animations.Glock)
        animationTrack:Play(nil, nil, 0)
        -- effectsService.playOnClient:Fire(killer, "orbitalCamera", true)
        task.wait(2)
        animationTrack:AdjustSpeed(1)
        gameService.killPlayer:Fire(killer, victim, "Gun Shot")
        effectsService.playOnClients:Fire(Players:GetPlayers(), "gunShot", killerCharacter, victimCharacter)
        animationTrack.Ended:Wait()
        -- effectsService.playOnClient:Fire(killer, "orbitalCamera", false)
        killerCharacter.HumanoidRootPart.Anchored = false
        gunClone:Destroy()
    end
    -- TODO: need los sanity check, should go from the head to any point of the character
    -- tip: use shapecasting here
end

return mafia