local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local sharedPackages = ReplicatedStorage.sharedPackages

local network = require(sharedPackages.network)

local services = ServerStorage.server.services
local gameService = require(services.gameService)

local roleParser = require(script.Parent.Parent.roleParser)

local currentPlayersInTeam = {}
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

function mafia.onPlayersInfoChanged(newPlayersInfo, oldPlayersInfo)
    local mafiaMembers = {}
    local witchMembers = {}
    for userId, playerInfo in newPlayersInfo do
        if not playerInfo.alive then
            continue
        end
        if playerInfo.role == "mafia" then
            table.insert(mafiaMembers, userId)
        elseif playerInfo.role == "witch" then -- check if the witch is on mafia or civilian side
            table.insert(witchMembers, userId)
        end
    end

    local playersToAdd, playersToRemove = roleParser(newPlayersInfo, oldPlayersInfo, function(_, playerInfo)
        return playerInfo.role == "mafia" --or playerInfo.role == "witch"
    end)

    currentPlayersInTeam = playersToAdd

    -- remove for old mafia members
    mafia.client.teamMembers:removeForClients(playersToRemove)
    mafia.client.canKill:removeForClients(playersToRemove)
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

    if magnitude <= 7 then
        killDebounce = true
        mafia.client.canKill:setForClients(currentPlayersInTeam, false)
        gameService.killPlayer:Fire(killer, victim, "Knife Wound")
    elseif magnitude > 7 then
        killDebounce = true
        mafia.client.canKill:setForClients(currentPlayersInTeam, false)
        gameService.killPlayer:Fire(killer, victim, "Gun Shot")
    end
    -- TODO: need los sanity check, should go from the head to any point of the character
    -- tip: use shapecasting here
end

return mafia