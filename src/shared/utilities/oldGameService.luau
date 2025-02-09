local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local sharedPackages = ReplicatedStorage.sharedPackages
local serverModules = ServerStorage.server.modules

local network = require(sharedPackages.network)
local ReactSpring = require(sharedPackages.ReactSpring)
local Signal = require(sharedPackages.Signal)

local roleAssigner = require(serverModules.roleAssigner)

local services = ServerStorage.server.services
local pointingService = require(services.pointingService)
local ragdollService = require(services.ragdollService)

-- misc instance variables that are likely to be moved out of gameService
local Maps = ServerStorage:WaitForChild("MAPS"):GetChildren()

local gameService = {
    playersInfo = network.Server.RemoteProperty.new({}),
    vigilanteInterrupt = Signal.new(),
    killPlayer = Signal.new(),
    client = {
        -- server -> client
        playDeathCutscene = network.Server.RemoteSignal.new(),
        explainRules = network.Server.RemoteSignal.new(),
        skipIntro = network.Server.RemoteSignal.new(),
        setTopbarText = network.Server.RemoteSignal.new(),
        setFadeProperty = network.Server.RemoteSignal.new(),
        toggleAudio = network.Server.RemoteSignal.new(),
        sendMapDescendantsCount = network.Server.RemoteSignal.new(),

        -- client -> server
        introCompleted = network.Server.RemoteSignal.new(),
        votePlayer = network.Server.RemoteSignal.new(),
        skipVote = network.Server.RemoteSignal.new(),
        gameLoaded = network.Server.RemoteSignal.new(),
        mapLoaded = network.Server.RemoteSignal.new(),

        -- intro properties
        introSkipped = network.Server.RemoteProperty.new(false),
        introSkippedInfo = network.Server.RemoteProperty.new({
            playersSkippedIntro = 0,
            participatingPlayers = 0
        }),
        
        -- game states
        gameStarted = network.Server.RemoteProperty.new(false),
        abilitiesEnabled = network.Server.RemoteProperty.new(false),
        gamePhase = network.Server.RemoteProperty.new(nil),

        -- client states
        lightsToggled = network.Server.RemoteProperty.new(true),
        chatToggled = network.Server.RemoteProperty.new(true),
        firstPersonForced = network.Server.RemoteProperty.new(false),
        canVote = network.Server.RemoteProperty.new(false),
    }
}

local gameConfig = {
    gameStartTimer = 5, -- 15

    shouldPlayIntro = false,

    nightStartTimer = 5, -- 15
    mafiaKillTimer = 90, -- 90
    doctorReviveTimer = 10, -- unused -- 10
    nightEndTimer = 15, -- 15 -- time until the night ends after a mafia kill

    discussionTimer = 5, -- 60
    skipVoteTimer = 30, -- unused -- 20
    votingTimer = 15, -- 30
}

local function countdownCoroutineInit(seconds, increment, callback, cleanup)
    local finishedEvent = Instance.new("BindableEvent")
    local currentSecond
    local coro = coroutine.create(function()
        for i = seconds, 0, -increment do
            currentSecond = i
            if callback then
                task.spawn(callback, i)
            end
            task.wait(1)
        end
        if cleanup then
            cleanup(false)
        end
    end)
    coroutine.resume(coro)
    return function()
        if coroutine.status(coro) == "dead" then
            return -1
        end
        coroutine.close(coro)
        if cleanup then
            cleanup(true)
        end
        return currentSecond
    end, finishedEvent
end

local function getPlayers(allPlayersInfo, callback)
    local players = {}
    for userId, playerInfo in allPlayersInfo do
        if callback(userId, playerInfo) then
            table.insert(players, Players:GetPlayerByUserId(userId))
        end
    end
    return players
end

local function setTopbarTextWithTick(targetPlayers, text)
    if targetPlayers == "all" then
        gameService.client.setTopbarText:fireAllClients({
            targetText = text,
            initialText = #text == 0 and "" or string.sub(text, 1, -2)
        })
    else
        gameService.client.setTopbarText:fireClients(targetPlayers, {
            targetText = text,
            initialText = #text == 0 and "" or string.sub(text, 1, -2)
        })
    end
end

function gameService.start()
    -- testing code
    local gameStarted = false
    gameService.client.gameLoaded:connect(function(player)
        local allPlayers = Players:GetPlayers()
        if (#allPlayers >= 3 and not gameStarted) or (player.UserId > 0 and not gameStarted) then
            gameStarted = true
            for i = gameConfig.gameStartTimer, 0, -1 do
                setTopbarTextWithTick("all", `Game starting in: {i}`)
                task.wait(1)
            end
            gameService.client.setTopbarText:fireAllClients()
            gameService.startGame()
        end
    end)
end

function gameService.assignRoles(participatingPlayers)
    local assignedRoles
    if #participatingPlayers == 1 and RunService:IsStudio() then
        assignedRoles = roleAssigner.assignRoles({
            roles = {
                default = {"mafia"}
            }
        }, participatingPlayers)
    elseif #participatingPlayers < 3 then
        error(`There are only {#participatingPlayers}/3 of required players.`)
    elseif #participatingPlayers >= 15 then
        assignedRoles = roleAssigner.assignRoles({
            roles = {
                guaranteed = {
                    mafia = 3,
                    doctor = 1,
                    detective = 1
                },
                special = {
                    detainer = {
                        maxPlayers = 1,
                        baseChance = 1
                    },
                    jester = {
                        maxPlayers = 1,
                        baseChance = 1
                    },
                    vigilante = {
                        maxPlayers = 1,
                        baseChance = 1
                    },
                    witch = {
                        maxPlayers = 1,
                        baseChance = 1
                    }
                },
                default = {"civilian"}
            }
        }, participatingPlayers)
    elseif #participatingPlayers >= 3 then
        assignedRoles = roleAssigner.assignRoles({
            roles = {
                guaranteed = {
                    mafia = 2,
                    doctor = 1,
                    detective = nil
                },
                special = {
                    detainer = {
                        maxPlayers = 1,
                        baseChance = 1
                    },
                    jester = {
                        maxPlayers = 1,
                        baseChance = 1
                    },
                    vigilante = {
                        maxPlayers = 1,
                        baseChance = 1
                    },
                    witch = {
                        maxPlayers = 1,
                        baseChance = 1
                    }
                },
                default = {"civilian"}
            }
        }, participatingPlayers)
    end
    return assignedRoles
end

function gameService.killPlayer()
    
end

function gameService.NightPhase(phasesData, allPlayersInfo, spawnLocations)
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
    gameService.client.firstPersonForced:set(true)
    for _, seat in workspace.Map.Seats:GetChildren() do
        local seatWeld = seat:FindFirstChild("SeatWeld")
        if seatWeld then
            seatWeld:Destroy()
        end
    end
    task.wait()
    local allAlivePlayers = getPlayers(allPlayersInfo, function(_, playerInfo)
        return playerInfo.alive
    end)
    for _, player in allAlivePlayers do
        local character = player.Character
        character:PivotTo(spawnLocations[math.random(1,#spawnLocations)].CFrame * CFrame.new(0, 5, 0))
    end
    gameService.client.setFadeProperty:fireAllClients({
        transparency = 1,
        duration = 1,
        easing = ReactSpring.easings.easeInQuad
    })
    for i = gameConfig.nightStartTimer, 0, -1 do
        setTopbarTextWithTick("all", `Night starts in {i}`)
        task.wait(1)
    end
    gameService.client.setTopbarText:fireAllClients(nil)
    -- gameService.client.lightsToggled:set(false)
    gameService.client.chatToggled:set(false)
    -- turn on flashlights pointing
    pointingService.setCanPointArm:Fire(true)
    
    -- phase actions
    -- allow relevant roles to use their abilities
    gameService.client.abilitiesEnabled:set(true)
    
    local phaseFinished = Instance.new("BindableEvent")
    local allMafia = getPlayers(allPlayersInfo, function(_, playerInfo)
        return playerInfo.role == "mafia"
    end)
    local deaths = {}

    -- i hope this works (it's probably not gonna work) (it worked)
    local mafiaCountdownCancel = countdownCoroutineInit(gameConfig.mafiaKillTimer, 1, function(i)
        setTopbarTextWithTick(allMafia, `Eliminate a player within {i} seconds.`)
    end, function(cancelled)
        if cancelled then
            return
        end
        setTopbarTextWithTick(allMafia, "")
        phaseFinished:Fire()
    end)
    local killCountdownCancel

    -- could probably get refactored
    local killPlayerConnection = gameService.killPlayer:Connect(function(killer, victim, reason)
        local killerInfo = allPlayersInfo[killer.UserId]
        local victimInfo = allPlayersInfo[victim.UserId]
        if not victimInfo.alive or victimInfo.downed then
            return
        end
        if killerInfo.role == "mafia" and killCountdownCancel then
            return
        end
        if mafiaCountdownCancel() <= -1 then
            return
        end
        victimInfo.downed = true
        -- TODO: if they're not mafia they should just straight up die lol
        if killerInfo.role == "mafia" then
            victim.Character:SetAttribute("Downed", true)
        end
        ragdollService.setRagdoll:Fire(victim.Character, true)
        gameService.client.firstPersonForced:setForClient(victim, false)
        deaths[victim.UserId] = { -- TODO: of course remove this if they're revived at the end
            killer = killer.UserId,
            reason = reason
        }
        -- TODO: figure out how to properly 'kill' someone off the game
        -- also add spectating for dead players
        gameService.playersInfo:set(allPlayersInfo)
        if killerInfo.role == "mafia" then
            killCountdownCancel = countdownCoroutineInit(gameConfig.nightEndTimer, 1, function(i)
                setTopbarTextWithTick(allMafia, `The night will end in {i} seconds.`)
            end, function()
                setTopbarTextWithTick(allMafia, "")
                phaseFinished:Fire()
            end)
        end
    end)

    phaseFinished.Event:Wait()

    killPlayerConnection:Disconnect()
    gameService.client.abilitiesEnabled:set(false)
    pointingService.setCanPointArm:Fire(false)
    -- clean up
    gameService.client.setFadeProperty:fireAllClients({
        transparency = 0,
        duration = 1,
        easing = ReactSpring.easings.easeOutQuad
    })
    task.wait(1)
    return {
        deaths = deaths
    }
end

function gameService.DayPhase(phasesData, allPlayersInfo)
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
    local someoneDied = false
    gameService.client.lightsToggled:set(true)
    local seatIndex = 1
    local seats = workspace.Map.Seats:GetChildren()
    for userId, userInfo in allPlayersInfo do
        if not userInfo.alive then
            return
        end
        local seat: Seat = seats[seatIndex]
        local character = Players:GetPlayerByUserId(userId).Character
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        character:PivotTo(seat:GetPivot())
        seat:Sit(humanoid)
        seatIndex += 1
    end
    if not someoneDied then
        return
    end
    gameService.client.toggleAudio:fireAllClients({
        sound = SoundService.whoDied,
        playing = true,
        duration = 1,
        volume = 0.5
    })
    gameService.client.setFadeProperty:fireAllClients({
        transparency = 1,
        duration = 1,
        easing = ReactSpring.easings.easeInQuad
    })

    -- i am not doing allat right now

    -- clean up
    gameService.client.setFadeProperty:fireAllClients({
        transparency = 0,
        duration = 1,
        easing = ReactSpring.easings.easeOutQuad
    })
    gameService.client.toggleAudio:fireAllClients({
        sound = SoundService.whoDied,
        playing = false,
        duration = 1,
        volume = 0
    })
    task.wait(1)
end

function gameService.DiscussionPhase(phasesData, allPlayersInfo)
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
    gameService.client.setFadeProperty:fireAllClients({
        transparency = 1,
        duration = 1,
        easing = ReactSpring.easings.easeOutQuad
    })
    task.wait(1)
    gameService.client.chatToggled:set(true)
    gameService.client.abilitiesEnabled:set(true)
    gameService.client.firstPersonForced:set(false)
    local randomDiscussionSound = SoundService[`discussionMusic{math.random(1,3)}`]
    gameService.client.toggleAudio:fireAllClients({
        sound = randomDiscussionSound,
        playing = true,
        duration = 1,
        volume = 0.5
    })

    -- phase actions
    -- this phase should be interruptable by vigilante
    -- relevant roles are given abilities
    local discussionFinished = false
    local secondsToDiscuss = gameConfig.discussionTimer
    repeat
        local breakLoopEvent = Instance.new("BindableEvent")
        local discussionCountdownCancel = countdownCoroutineInit(secondsToDiscuss, 1, function(i)
            setTopbarTextWithTick("all", `Discuss who you think the Mafia is. ({i})`)
        end, function(cancelled)
            setTopbarTextWithTick("all", "")
            breakLoopEvent:Fire()
            if cancelled then
                return
            end
            discussionFinished = true
        end)

        local vigilanteInterruptConnection
        vigilanteInterruptConnection = gameService.vigilanteInterrupt:Connect(function(player)
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
    gameService.client.abilitiesEnabled:set(false)
    gameService.client.setTopbarText:fireAllClients(nil)
    gameService.client.toggleAudio:fireAllClients({
        sound = randomDiscussionSound,
        playing = false,
        duration = 1,
        volume = 0
    })
end

function gameService.VotingPhase(phasesData, allPlayersInfo)
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
    gameService.client.canVote:set(true)
    pointingService.setCanPointArm:Fire(true)

    local votingPhaseFinished = Instance.new("BindableEvent")

    local allAlivePlayers = getPlayers(allPlayersInfo, function(_, playerInfo)
        return playerInfo.alive
    end)
    local playerVotes = {}
    local playerSkips = {}

    local voteConnection = gameService.client.votePlayer:connect(function(player: Player, targetVote: Player)
        local userId = player.UserId
        if not table.find(allAlivePlayers, player) or playerVotes[userId] then
            return
        end
        if not table.find(allAlivePlayers, targetVote) then
            return
        end
        playerVotes[player.UserId] = targetVote.UserId
    end)

    local skipConnection = gameService.client.skipVote:connect(function(player: Player)
        local userId = player.UserId
        if table.find(playerSkips, userId) then
            return
        end
        table.insert(playerSkips, userId)
    end)

    local votingCountdownCancel = countdownCoroutineInit(gameConfig.votingTimer, 1, function(i)
        setTopbarTextWithTick("all", `Vote on who you believe the Mafia is. ({i})`)
    end, function()
        setTopbarTextWithTick("all", "")
        votingPhaseFinished:Fire()
    end)

    task.delay(gameConfig.skipVoteTimer, function()
        if #playerSkips > #allAlivePlayers/2 then
            votingCountdownCancel()
        end
    end)

    votingPhaseFinished.Event:Wait()

    gameService.client.canVote:set(false)

    pointingService.setCanPointArm:Fire(false)

    local talliedVotes = {}
    -- tally votes
    for _, voted in playerVotes do
        local player = Players:GetPlayerByUserId(voted)
        if not talliedVotes[player] then
            talliedVotes[player] = 0
        end
        talliedVotes[player] += 1
    end
    
    local mostVotes = {}

    for player, votes in talliedVotes do
        if not mostVotes[votes] then
            mostVotes[votes] = {}
        end
        table.insert(mostVotes[votes], player)
    end

    print(mostVotes)

    local votesText = "The votes are in."
    gameService.client.setTopbarText:fireAllClients({
        targetText = votesText
    })
    
    -- vote someone out

    -- handle ties (try just killing all players in a tie lol)
    
    task.wait(2+#votesText*.025)

    voteConnection:Disconnect()
    skipConnection:Disconnect()

    -- clean up
    -- mafiaVoting should be stopped here but uhh it doesnt exist lol
    gameService.client.setTopbarText:fireAllClients(nil)
    gameService.client.setFadeProperty:fireAllClients({
        transparency = 0,
        duration = 1,
        easing = ReactSpring.easings.easeOutQuad
    })
    task.wait(1)
end

function gameService.gameIntro(assignedRoles, participatingPlayers)
    for userId, role in assignedRoles do
        local player = Players:GetPlayerByUserId(userId)
        if not player then
            assignedRoles[userId] = nil
            participatingPlayers[table.find(participatingPlayers, userId)] = nil
        end
        gameService.client.explainRules:fireClient(player, role)
        print(`Sent explainRules to {player.Name}, {role}`)
    end

    local readyPlayers = {}
    local skippedIntroPlayers = {}

    local introCompletedConnection = gameService.client.introCompleted:connect(function(player)
        if assignedRoles[player.UserId] ~= nil and not table.find(readyPlayers, player.UserId) then
            table.insert(readyPlayers, player.UserId)
        end
    end)

    gameService.client.introSkippedInfo:set({
        playersSkippedIntro = 0,
        participatingPlayers = #participatingPlayers
    })

    local skipIntroConnection = gameService.client.skipIntro:connect(function(player)
        if assignedRoles[player.UserId] ~= nil and not table.find(skippedIntroPlayers, player.UserId) then
            table.insert(skippedIntroPlayers, player.UserId)
            gameService.client.introSkippedInfo:set({
                playersSkippedIntro = #skippedIntroPlayers,
                participatingPlayers = #participatingPlayers
            })
        end
    end)

    while #readyPlayers < #participatingPlayers do
        if #skippedIntroPlayers >= #participatingPlayers * (2/3) and gameService.client.introSkipped:get() ~= true then
            gameService.client.introSkipped:set(true)
        end
        task.wait()
    end

    introCompletedConnection:Disconnect()
    skipIntroConnection:Disconnect()

    print("All participating players are ready.")
end

function gameService.startGame()
    gameService.client.introSkipped:set(false)
    gameService.client.gameStarted:set(false)
    gameService.client.introSkippedInfo:set({
        playersSkippedIntro = 0,
        participatingPlayers = 0
    })
    gameService.client.setFadeProperty:fireAllClients({
        transparency = 0,
        duration = 1,
        easing = ReactSpring.easings.easeOutQuad
    })

    -- waiting for fading to complete
    task.wait(1)

    local spawnLocations = {}
	local map = Maps[math.random(1, #Maps)]:Clone()
	map = ReplicatedStorage.MAPS.Library:Clone() -- test code for getting a specific map lol, should make a debug config instead
    map.Name = "Map"
    map.Parent = workspace

    -- disable any seats found in maps
	if map:FindFirstChild("Seats") then
		for _, seat in pairs(map.Seats:GetChildren()) do
			seat.Disabled = true
		end
	end

    for _, spawnLocation in pairs(map:GetChildren()) do
        if spawnLocation:IsA('SpawnLocation') then
            table.insert(spawnLocations, spawnLocation)
        end
    end

    local participatingPlayers = Players:GetPlayers()

    for index, player in participatingPlayers do
        participatingPlayers[index] = player.UserId
    end

	local assignedRoles = gameService.assignRoles(participatingPlayers)

    local allPlayersInfo = {}

    for userId, role in assignedRoles do
        allPlayersInfo[userId] = {
            role = role,
            alive = true,
            downed = false,
        }
    end

    gameService.client.sendMapDescendantsCount:fireAllClients(#map:GetDescendants())

    gameService.client.setTopbarText:fireAllClients({
        targetText = "Loading map..."
    })

    local loadedPlayers = {}
    local allPlayersLoadedEvent = Instance.new("BindableEvent")
    local mapLoadedConnection
    mapLoadedConnection = gameService.client.mapLoaded:connect(function(player)
        if table.find(participatingPlayers, player.UserId) and not table.find(loadedPlayers, player.UserId) then
            table.insert(loadedPlayers, player.UserId)
        end
        print(#participatingPlayers, #loadedPlayers)
        if #participatingPlayers == #loadedPlayers then
            mapLoadedConnection:Disconnect()
            allPlayersLoadedEvent:Fire()
        end
    end)

    allPlayersLoadedEvent.Event:Wait()

    gameService.client.setTopbarText:fireAllClients(nil)

    if gameConfig.shouldPlayIntro then
        gameService.gameIntro(assignedRoles, participatingPlayers)
    end

    gameService.client.gameStarted:set(true)

    gameService.client.setFadeProperty:fireAllClients({
        transparency = 1,
        duration = 1,
        easing = ReactSpring.easings.easeOutQuad
    })

    -- TODO: update playersInfo on death etc
    gameService.playersInfo:set(allPlayersInfo)

    local gamePhases = {
        "Night",
        "Day",
        "Discussion",
        "Voting"
    }

    local phasesData = {}
    while true do
        for _, phase in gamePhases do
            gameService.client.gamePhase:set(phase)
            if phase == "Night" then
                phasesData.night = gameService.NightPhase(phasesData, allPlayersInfo, spawnLocations)
            elseif phase == "Day" then
                phasesData.day = gameService.DayPhase(phasesData, allPlayersInfo)
            elseif phase == "Discussion" then
                phasesData.discussion = gameService.DiscussionPhase(phasesData, allPlayersInfo)
            elseif phase == "Voting" then
                phasesData.voting = gameService.VotingPhase(phasesData, allPlayersInfo)
            end
        end
    end
end

return gameService