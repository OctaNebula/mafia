local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local sharedPackages = ReplicatedStorage.sharedPackages

local ReactSpring = require(sharedPackages.ReactSpring)

local services = ServerStorage.server.services
local interactionService = require(services.interactionService)
local spectatingService = require(services.spectatingService)
local flashlightService = require(services.flashlightService)
local pointingService = require(services.pointingService)
local ragdollService = require(services.ragdollService)

local assets = ReplicatedStorage.assets
local slashDecal = assets.slashDecal

local gameUtils = require(script.Parent.gameUtils)

local managers = script.Parent.managers
local votingManager = require(managers.votingManager)
local soundManager = require(managers.soundManager)
local uiManager = require(managers.uiManager)

local phaseHandler = {
    properties = {},
    events = {}
}

function phaseHandler.init(gameService)
    phaseHandler.events.playDeathCutscene = gameService.client.playDeathCutscene
    phaseHandler.events.vigilanteInterrupt = gameService.vigilanteInterrupt
    phaseHandler.events.killPlayer = gameService.killPlayer

    phaseHandler.properties.firstPersonForced = gameService.client.firstPersonForced
    phaseHandler.properties.abilitiesEnabled = gameService.client.abilitiesEnabled
    phaseHandler.properties.lightsToggled = gameService.client.lightsToggled
    phaseHandler.properties.talliedVotes = gameService.client.talliedVotes
    phaseHandler.properties.chatToggled = gameService.client.chatToggled
    phaseHandler.properties.playersInfo = gameService.client.playersInfo
    phaseHandler.properties.spectating = gameService.client.spectating
    phaseHandler.properties.isDead = gameService.client.isDead

    votingManager.init(gameService)
    soundManager.init(gameService)
    uiManager.init(gameService)
end

function phaseHandler.Night(gameState)
        --[[
    entry actions
        teleport all players to random spawnLocations
        first person should be enabled
        start 15 second countdown to night time "Night starts in X seconds."
        turn off chat
        dim all lights
    phase actions
        allow relevant roles to use their abilities
        start a 90 second countdown which will skip to the clean up if it reaches 0
        if a mafia kills someone, stop the previous timer and start a 15 second timer which skips to clean up after reaching 0
    clean up
        all players should have their screen fade to black completely before changing to the next phase
    ]]
    -- entry actions
    local previousDayDeaths = gameState.deaths[gameState.currentDay-1]
    if previousDayDeaths then
        for userId, _ in previousDayDeaths do
            local player = Players:GetPlayerByUserId(userId)
            local character = player.Character
            if character then
                character:Destroy()
            end
        end
    end

    phaseHandler.properties.firstPersonForced:set(true)
    for _, seat in workspace.Map.Seats:GetChildren() do
        local seatWeld = seat:FindFirstChild("SeatWeld")
        if seatWeld then
            seatWeld:Destroy()
        end
    end
    task.wait()
    local allAlivePlayers = gameUtils.getPlayers(gameState.players, function(_, playerInfo)
        return playerInfo.alive
    end)
    for _, player in allAlivePlayers do
        local character = player.Character
        character:PivotTo(gameState.spawnLocations[math.random(1,#gameState.spawnLocations)].CFrame * CFrame.new(0, 5, 0))
    end
    uiManager.fade(1)
    for i = gameState.GAME_CONFIG.NIGHT_START_TIMER, 0, -1 do
        uiManager.setTopbarText("all", `Night starts in {i}`, true)
        task.wait(1)
    end
    uiManager.setTopbarText("all", nil)
    -- phaseHandler.properties.lightsToggled:set(false)
    phaseHandler.properties.chatToggled:set(false)
    -- pointingService.setCanPointArm:Fire(true)
    -- for _, player in allAlivePlayers do
    --     flashlightService.equipFlashlight(player)
    -- end

    -- phase actions
    -- allow relevant roles to use their abilities
    phaseHandler.properties.abilitiesEnabled:set(true)

    local phaseFinished = Instance.new("BindableEvent")
    local allMafia = gameUtils.getPlayers(gameState.players, function(_, playerInfo)
        return playerInfo.role == "mafia"
    end)

    -- i hope this works (it's probably not gonna work) (it worked)
    local mafiaCountdownCancel = gameUtils.countdownCoroutineInit(gameState.GAME_CONFIG.MAFIA_KILL_TIMER, 1, function(i)
        uiManager.setTopbarText(allMafia, `Eliminate a player within {i} seconds.`, true)
    end, function(cancelled)
        if cancelled then
            return
        end
        uiManager.setTopbarText(allMafia, nil)
        phaseFinished:Fire()
    end)

    -- could probably get refactored
    local killPlayerConnection = phaseHandler.events.killPlayer:Connect(function(killer, victim, reason)
        local killerInfo = gameState.players[killer.UserId]
        local victimInfo = gameState.players[victim.UserId]
        if not victimInfo.alive or victimInfo.downed then
            return
        end
        if killerInfo.role == "mafia" then -- players should be downed before dying
            if mafiaCountdownCancel() <= -1 then
                return
            end
            victim.Character:SetAttribute("Downed", true)
            ragdollService.setRagdoll:Fire(victim.Character, true)
            phaseHandler.properties.firstPersonForced:setForClient(victim, false)
            local deathTimer = math.min(gameState.GAME_CONFIG.DOCTOR_REVIVE_TIMER, gameState.GAME_CONFIG.NIGHT_END_TIMER)
            slashDecal:Clone().Parent = victim.Character:FindFirstChild("UpperTorso") or victim.Character:FindFirstChild("Torso")
            task.delay(deathTimer, function()
                if not victim.Character:GetAttribute("Downed") then
                    return
                end
                victim.Character:SetAttribute("Dead", true)
                -- should be managed by a different manager, but this works for now.
                phaseHandler.properties.spectating:setForClient(victim, true) -- note that they could have this disabled if they're a jester
                phaseHandler.properties.isDead:setForClient(victim, true)
                -- phaseHandler.events.playDeathCutscene:fireClient(victim) -- could be merged into 'isDead' property
                gameState:registerDeath(killer, victim, reason)
                spectatingService.addSpectatorSignal:Fire(victim)
            end)
            -- TODO: figure out how to properly 'kill' someone off the game
            -- also add spectating for dead players
            if killerInfo.role == "mafia" then
                gameUtils.countdownCoroutineInit(gameState.GAME_CONFIG.NIGHT_END_TIMER, 1, function(i)
                    uiManager.setTopbarText(allMafia, `The night will end in {i} seconds.`, true)
                end, function()
                    uiManager.setTopbarText(allMafia, nil)
                    phaseFinished:Fire()
                end)
            end
        else
            print("Role other than mafia tried killing someone")
        end
    end)

    phaseFinished.Event:Wait()

    killPlayerConnection:Disconnect()
    phaseHandler.properties.abilitiesEnabled:set(false)
    pointingService.setCanPointArm:Fire(false)
    for _, player in allAlivePlayers do
        flashlightService.unequipFlashlight(player)
    end
    -- clean up
    uiManager.fade(0)
    task.wait(1)
    return
end

function phaseHandler.Day(gameState)
        --[[
    entry actions
        lights are turned back on
        if nobody died just skip this lol
        all players should have their screen fade out from black
        The death cutscene will play for 9 seconds
        whoDied audio will play
        Chat will turn ON
        Everyone"s screen will show the corpse of the player on the floor, slowly zooming in above the
        player who died
        "[Player Name] died tonight." (3 seconds)
        "Cause of Death: [Gunshot/Knife Wound]" (3 seconds)
        "Found by: [Player Name]" (3 seconds) (If the body wasn't found by anyone, it will just say "No
        one found the body.") (also no cutscene if nobody found it)

    clean up
        fade to black
    ]]
    -- entry actions
    local objects = interactionService.cleanupObjects:Fire("Closet")
    phaseHandler.properties.lightsToggled:set(true)
    phaseHandler.properties.firstPersonForced:set(false)
    local seatIndex = 1
    local seats = workspace.Map.Seats:GetChildren()
    for userId, userInfo in gameState.players do
        if not userInfo.alive then
            continue
        end
        local seat: Seat = seats[seatIndex]
        local character = Players:GetPlayerByUserId(userId).Character
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        character:PivotTo(seat:GetPivot())
        seat:Sit(humanoid)
        seatIndex += 1
    end

    uiManager.fade(1)

    task.wait(1)

    local deaths = gameState:getAllDeathsOnCurrentDay()
    local totalDeaths = 0
    for _, _ in deaths do
        totalDeaths += 1
    end
    if totalDeaths <= 0 then
        uiManager.setTopbarText("all", "No one died.", nil, true)
        task.wait(1)
    else
        soundManager.playMusic(SoundService.whoDied)
        for userId, deathInfo in deaths do
            local player = Players:GetPlayerByUserId(userId)
            uiManager.setTopbarText("all", `{player.Name} died tonight.`, nil, true)
            task.wait(3)
            uiManager.setTopbarText("all", `Cause of death: {deathInfo.reason}`, nil, true)
            task.wait(3)
            if deathInfo.bodyFinder then
                uiManager.setTopbarText("all", `Found by: {deathInfo.bodyFinder}`, nil, true)
            else
                uiManager.setTopbarText("all", "No one found the body.", nil, true)
            end
            task.wait(3)
        end
        soundManager.stopSound(SoundService.whoDied)
    end
end

function phaseHandler.Discussion(gameState)
        --[[
    entry actions
        fade back in
        chat turned on
        camera set to third person
        topbar should say "Discuss who you think the Mafia is."
        mafiaDiscussion audio should play now

    phase actions
        this phase should be interruptable by vigilante
        relevant roles are given abilities

    clean up
        all roles should have their abilities disabled
        mafiaDiscussion audio is turned off now
    ]]
    -- entry actions
    uiManager.fade(1)
    -- task.wait(1)
    phaseHandler.properties.chatToggled:set(true)
    phaseHandler.properties.abilitiesEnabled:set(true)
    local randomDiscussionSound = SoundService[`discussionMusic{math.random(1,3)}`]
    soundManager.playMusic(randomDiscussionSound)

    -- phase actions
    -- this phase should be interruptable by vigilante
    -- relevant roles are given abilities
    local discussionFinished = false
    local secondsToDiscuss = gameState.GAME_CONFIG.DISCUSSION_TIMER
    repeat
        local breakLoopEvent = Instance.new("BindableEvent")
        local discussionCountdownCancel = gameUtils.countdownCoroutineInit(secondsToDiscuss, 1, function(i)
            uiManager.setTopbarText("all", `Discuss who you think the Mafia is. ({i})`, true)
        end, function(cancelled)
            uiManager.setTopbarText("all", nil)
            breakLoopEvent:Fire()
            if cancelled then
                return
            end
            discussionFinished = true
        end)

        local vigilanteInterruptConnection
        vigilanteInterruptConnection = phaseHandler.events.vigilanteInterrupt:Connect(function(player)
            print(`{player.Name} (probably vigilante) is interrupting discussion`)
            secondsToDiscuss = discussionCountdownCancel()
            if secondsToDiscuss <= -1 then
                discussionFinished = true
                breakLoopEvent:Fire()
                return
            end
            -- do cutscene stuff
            -- other roles shouldnt be able to do anything during this cutscene

            -- give roles access to their abilities now
            breakLoopEvent:Fire()
        end)

        breakLoopEvent.Event:Wait()
        vigilanteInterruptConnection:Disconnect()
    until discussionFinished

    -- clean up
    -- all roles should have their abilities disabled at this point
    phaseHandler.properties.abilitiesEnabled:set(false)
    uiManager.setTopbarText("all", nil)
    soundManager.stopSound(randomDiscussionSound)
end

function phaseHandler.Voting(gameState)
        --[[
    entry actions
        topbar should say "Vote on who you believe the Mafia is."
        mafiaVoting audio should play now

    phase actions
        players get the ability to vote
        tldr players can choose to vote someone
        there will be a skip voting button which will skip if majority votes to skip (>50%) after 20 seconds
            if there are enough votes, skip immediately to clean up
            if not enough votes, the button will disappear
        after a 30 second timer (unless skipped), server should say "Votes are in."
        mafiaVoting audio is turned off now
        mafiaVotes audio should play now
        The number of votes everyone had will show up above their heads. After 3 seconds, the camera
            will move in front of the player with the most votes for a total of 4 seconds. The server will say
            "[Player Name] had X votes" for 4 seconds. Everyone's screens will go black after these 4
            seconds, and there will be a gunshot sound. Everyone's screens will go back to normal, and the
            player with the most votes will have disappeared off their chair. Once this happens, everyone's
            screens will fade black, and the next night will begin.
        If the votes are tied, AND a Judge is present, the camera won"t go anywhere. The server will say "The votes have tied",
            "The Judge has to make a decision on who to vote out", and a countdown of 15 seconds will begin.
        For the Judge it will say, "Make a vote on who you think should be voted out."
        The Judge will bring up the Voting UI with the tied players on the list. The Judge has to vote for
            a player who they think should be voted out. If the Judge does not want to vote for anyone, they
            can click the button that says "Skip Voting" on the bottom left of their screen, that only they can see.
        If the Judge votes for one of the players, the game will say "The Judge has decided on a verdict.", and then play the same voting out cutscene
        If the judge doesn"t vote for anyone, the game will say
            "The Judge has decided to not vote for anyone.", then skip to clean up
        
        IF the person voted out was a Jester, after the Jester gets voted out, the server will say "The
            player eliminated was a Jester. They will strike the next night."
    clean up
        mafiaVoting audio is turned off now if it hasnt already been
    ]]
    -- entry actions
    -- mafiaVoting should be played here but uhh it doesnt exist lol

    -- phase actions
    local votingPhaseFinished = Instance.new("BindableEvent")

    local allAlivePlayers = gameUtils.getPlayers(gameState.players, function(_, playerInfo)
        return playerInfo.alive
    end)

    local voteSkippedEvent = votingManager.startVoting(allAlivePlayers,
        if gameState.GAME_CONFIG.SKIP_VOTE_TIMER < gameState.GAME_CONFIG.VOTING_TIMER
            then gameState.GAME_CONFIG.SKIP_VOTE_TIMER
            else nil
        )

    local votingCountdownCancel = gameUtils.countdownCoroutineInit(gameState.GAME_CONFIG.VOTING_TIMER, 1, function(i)
        uiManager.setTopbarText("all", `Vote on who you believe the Mafia is. ({i})`, true)
    end, function(cancelled)
        uiManager.setTopbarText("all", nil)
        votingPhaseFinished:Fire(cancelled or false)
    end)

    voteSkippedEvent.Event:Connect(votingCountdownCancel)

    local voteSkipped = votingPhaseFinished.Event:Wait()

    votingManager.finishVoting()

    if voteSkipped then
        uiManager.setTopbarText("all", "The vote has been skipped.", nil, true)
        task.wait(2)
    else
        local talliedVotes = votingManager.tallyVotes()

        phaseHandler.properties.talliedVotes:set(talliedVotes)

        uiManager.setTopbarText("all", "The votes are in.", nil, true)
        task.wait(2)

        -- vote someone out

        phaseHandler.properties.talliedVotes:set(nil)

        -- handle ties (try just killing all players in a tie lol)
    end

    -- clean up
    -- mafiaVoting should be stopped here but uhh it doesnt exist lol
    uiManager.setTopbarText("all", nil)
    uiManager.fade(0)
    task.wait(1)
end

return phaseHandler