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

-- misc instance variables that are likely to be moved out of gameService
local Maps = ServerStorage:WaitForChild("MAPS"):GetChildren()

local gameService = {
    vigilanteInterrupt = Signal.new(),
    client = {
        -- server -> client
        playDeathCutscene = network.Server.RemoteSignal.new(),
        explainRules = network.Server.RemoteSignal.new(),
        skipIntro = network.Server.RemoteSignal.new(),
        setTopbarText = network.Server.RemoteSignal.new(),
        setFadeProperty = network.Server.RemoteSignal.new(),
        countdownTimer = network.Server.RemoteSignal.new(),
        toggleAudio = network.Server.RemoteSignal.new(),

        -- client -> server
        introCompleted = network.Server.RemoteSignal.new(),
        votePlayer = network.Server.RemoteSignal.new(),
        skipVote = network.Server.RemoteSignal.new(),

        -- unreliable client -> server
        pointHead = network.Server.RemoteSignal.new(),
        pointArm = network.Server.RemoteSignal.new(),

        -- intro properties
        introSkipped = network.Server.RemoteProperty.new(false),
        introSkippedInfo = network.Server.RemoteProperty.new({
            playersSkippedIntro = 0,
            participatingPlayers = 0
        }),
        
        -- game states
        gameStarted = network.Server.RemoteProperty.new(false),
        gamePhase = network.Server.RemoteProperty.new(nil),

        -- client states
        lightsToggled = network.Server.RemoteProperty.new(true),
        chatToggled = network.Server.RemoteProperty.new(true),
        firstPersonForced = network.Server.RemoteProperty.new(false),
        canVote = network.Server.RemoteProperty.new(false),
    }
}

local gameConfig = {
    gameStartTimer = 30, -- 15

    shouldPlayIntro = false,

    nightStartTimer = 2, -- 15
    mafiaKillTimer = 2, -- 90
    doctorReviveTimer = 10, -- unused -- 10
    nightEndTimer = 15, -- unused -- 15 -- time until the night ends after a mafia kill

    discussionTimer = 2, -- 60
    skipVoteTimer = 30, -- unused -- 20
    votingTimer = 60, -- 30
}

function gameService.start()
    gameService.client.pointHead:connect(function(player, targetC0, lerpValue)
        local character = player.Character
        if not character then
            return
        end
        character.Head.Neck.C0 = character.Head.Neck.C0:Lerp(targetC0, lerpValue)
    end)

    gameService.client.pointArm:connect(function(player, shoulderC0, elbowC0, lerpValue)
        -- add sanity check, this should only be used for voting phase (use canVote) and flashlights(?)
        -- need to add a arm reset thingy when it's not being used anymore
        local character = player.Character
        if not character then
            return
        end
        local rightShoulder = character.RightUpperArm.RightShoulder
        local rightElbow = character.RightLowerArm.RightElbow

        rightShoulder.C0 = rightShoulder.C0:Lerp(shoulderC0, lerpValue)
        rightElbow.C0 = rightElbow.C0:Lerp(elbowC0, lerpValue)
        task.spawn(function()
            task.wait()
			rightShoulder.Transform = CFrame.new()
			rightElbow.Transform = CFrame.new()
        end)
    end)

    -- testing code
    local gameStarted = false
    Players.PlayerAdded:Connect(function()
        local allPlayers = Players:GetPlayers()
        if #allPlayers >= 3 and not gameStarted then
            gameStarted = true
            for i = gameConfig.gameStartTimer, 0, -1 do
                gameService.client.setTopbarText:fireAllClients({
                    targetText = `Game starting in: {i}`,
                    initialText = string.sub(`Game starting in: {i}`, 1, -2)
                })
                task.wait(1)
            end
            gameService.client.setTopbarText:fireAllClients()
            gameService.startGame()
        end
    end)
end

--[[
### a bunch of notes im keeping for future reference since this might actually take a while lol

sessions (total of 16 hours and 30 minutes as of 12/01/2025):
    02/01/2025 - 2 hours
        spent a lot of time just reading and comprehending whatever the hell it is im reading
    05/01/2025 - 2 hours
        started work on converting UI
    08/01/2025 - 2 hours
        conversion work
    09/01/2025 - 1 hour
        conversion work
    10/01/2025 - 4 hours
        conversion work (and going insane)
    11/01/2025 - 3 hours and 30 minutes
        working on game loop
    12/01/2025 - 2 hours
        added skipping intro and a proper countdown
    16/01/2025 - 4 hours
        working on game loop
    18/01/2025 - 2 hours
        ui stuff
    19/01/2025 - 2 hours
        i forgot wtf i did
    20/01/2025 - 2 hours
        pointing and head looking stuff
    21/01/2025 - 2 hours
        voting phase
    22/01/2025 - 2 hours
        finished pointing head and arm stuff, also added ragdolling

stuff done with elaborations in top down chronological order (DD/MM/YYYY):
    02/01/2025:
        LocalFootsteps from StarterPack converted to footstepsController -- UNTESTED!!!
            uses an attribute called 'Downed' on character, which at time of writing isnt implemented in rewrite
        Bob from StarterPlayerScripts converted to bobbleContoller -- UNTESTED!!!
            commented out some lines that deletes an instance named "Running" parented to HumanoidRootPart
            commented out a snippet of code that makes some stuff visible when in first person (i.e: flashlight)
                likely will want to move to a different controller, or turn bobbleController into a firstPersonController of sorts
    05/01/2025:
        Added uiController
            will be used to initialize and enable/disable all UI because I'm too lazy to give them each a controller
        AlphaWarning UI converted
            it's literally just text
        Death UI converted
            has working animations, which is also connected to playDeathCutscene event in gameService
    08/01/2025:
        Modified uiController to allow for props to be changed via a signal
        Implemented Fade and WitchTimer
        Added IntroController -- a bit untested!!!
            Currently only has the role explanation intros
    09/01/2025:
        Added Topbar
            Typewriter effect and sound included
    10/01/2025:
        Updated uiController to support DisplayOrder
        Updated Topbar to support duration and easings
        Updated Fade to support duration and easings
        Added mapIntroCutscene to introController
            this singlehandedly took me like 2 hours because:
                im stupid
                whoever made this is stupid
                whoever made this is a genius
                the typewriter in the old code was actually asynchronous, which meant it contributed to the delay
                    this isn't a bad thing though, the effect of this delay is almost magical
                    well except for the fact this took me an hour to figure out because im stupid
            mapIntroCutscene is virtually identical to the old version
        Updated introController in some places to better emulate the old version, while keeping the refactored and rewritten aspect
    11/01/2025:
        Created roleAssigner
            new version should be much better and much more future proof, as well as making it easier to customize later on when admin panels are added
        Updated startGame so it'll assign roles using roleAssigner
        Added syncing players loading into the game after the intro cutscene, will require further testing to see if it needs to be improved
    12/01/2025:
        Added skipping intro with majority
    16/01/2025:
        game loop prototype
            added events
                server -> client
                    setTopbarText
                    setFadeProperty
                    countdownTimer
                    toggleAudio
                client -> server
                    votePlayer
                    skipVote
            added properties
                gamePhase
                lightsToggled
                chatToggled
                firstPersonForced
                canVote
        most of these might be rewritten but these will be the initial ideas basically

all roles implemented pre-rewrite (has reference code):
    Civilian
        Survive the night. Cooperate with other innocent players to figure out who the Mafia may be.
        Color3.fromRGB(36, 156, 48)
    Detainer
        Cuff a player and they won't be present until the next night. Will you cuff a Mafia, or a Civilian?
        Color3.fromRGB(100, 215, 190)
    Detective
        You will obtain police reports at the end of each night. One of the players close to the deceased body may be one of the Mafias.
        Color3.fromRGB(211, 109, 0)
    Doctor
        Heal players who get attacked by the Mafia. Be quick though, they don't have long to live.
        Color3.fromRGB(29, 162, 205)
    Jester
        Fool everyone into believing you're the Mafia and you'll be able to strike your revenge.
        Color3.fromRGB(151, 32, 37)
    Mafia
        Eliminate all Civilians as discreetly as possible without exposing yourself to any remaining players.
        Color3.fromRGB(151, 32, 37)
    Vigilante
        Eliminate who you suspect the Mafia is as soon as possible. One wrong shot, and you go down too.
        Color3.fromRGB(104, 120, 208)
    Witch
        Curse a player during the night to prevent them from talking until the next night begins.
        Color3.fromRGB(100, 215, 190)

game phases:
    Intermission
        game hasnt even started at this point
    NightIntermission (15 seconds)
        countdown timer for night time, should be a trigger for first person
    Night
        it's night time, chats are off, lights are dimmed and relevant roles will be given their abilities
    DayIntermission
        The death cutscene will play for 9 seconds
        whoDiedMafia audio will play
        Chat will turn ON
        Everyone's screen will show the corpse of the player on the floor, slowly zooming in above the player who died
        '[Player Name] died tonight.' (3 seconds)
        'Cause of Death: [Gunshot/Knife Wound]' (3 seconds)
        'Found by: [Player Name]' (3 seconds) (If the body wasn"t found by anyone, it will just say 'No one found the body.')
    Discussion
        can be paused by relevant role active abilities
    Role
        might add this entirely different phase for just role cutscenes?
    Voting
        no roles should be able to have active abilities at this phase
        people can vote for a specific player or skip
            discuss the idea of doing it similarly to town of salem, where you need a majority
    VoteCutscene
        cutscene stuff lolool refer to design doc
    Judge
        should be activated in a tie and if the judge is available


removed features that should be brought back or otherwise superseded
    initialize function
        removed a snippet of code parenting all characters to a folder named 'Players'
        removed a sizable snippet of code related to doors
        removed 'Configuration' instance from map
            attributes it's assigned (surprisingly only 2):
                SkippedInstructions
                MapName
        removed spawn() from spawnLocation finder thing, not sure why or if it was needed

priority todo list:
    work on game loop to at minimum support the following: (expecting this to take about 5 hours if im not completely braindead)
        day/night cycle
            create a framework to easily implement game mechanics with
            lighting should be dimmed or brightened accordingly to test this a little
        voting system
        mafia killing mechanic
        doing the above is already sufficient for testing and first impressions
            makes it much easier to implement any and all future mechanics if this point can be reached
    convert old first person system into a controller (1 hour)
    flashlights (1 hour)
    night vision (1 hour)

todo list:
    add ragdoll for dead people
    convert FootstepTracking in StarterPlayerScripts
    convert UI in StarterGui into react to make it easier to manage
            should be noted that most of these might get replaced because they're really (really) bad
        detain
        gameOver
        mutedSign
        Grain
        gamemodevote
        mafiavote
        skipinstructions
        spectator
        detectiveUI
        silence
]]

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
            return 0
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
        print(userId, playerInfo)
        if callback(userId, playerInfo) then
            table.insert(players, Players:GetPlayerByUserId(userId))
        end
    end
    print(players)
    return players
end

function gameService.assignRoles(participatingPlayers)
    local assignedRoles
    if #participatingPlayers == 1 and RunService:IsStudio() then
        assignedRoles = roleAssigner.assignRoles({
            roles = {
                default = {"civilian"}
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
                    mafia = 1,
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
    end
    return assignedRoles
end

function gameService.NightPhase(allPlayersInfo, spawnLocations)
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
        gameService.client.setTopbarText:fireAllClients({
            targetText = `Night starts in {i}`,
            initialText = string.sub(`Night starts in {i}`, 1, -2)
        })
        task.wait(1)
    end
    gameService.client.setTopbarText:fireAllClients(nil)
    gameService.client.lightsToggled:set(false)
    gameService.client.chatToggled:set(false)

    -- phase actions
    -- allow relevant roles to use their abilities
    local phaseFinished = Instance.new("BindableEvent")
    local allMafia = getPlayers(allPlayersInfo, function(_, playerInfo)
        return playerInfo.role == "mafia"
    end)

    -- i hope this works (it's probably not gonna work) (it worked)
    local mafiaCountdownCancel = countdownCoroutineInit(gameConfig.mafiaKillTimer, 1, function(i)
        gameService.client.countdownTimer:fireClients(allMafia, i)
    end, function(cancelled)
        gameService.client.countdownTimer:fireClients(allMafia, nil)
        if cancelled then
            return
        end
        phaseFinished:Fire()
    end)
    -- if a mafia kills someone, stop the previous timer and start a 15 second timer which skips to clean up after reaching 0

    phaseFinished.Event:Wait()

    -- clean up
    gameService.client.setFadeProperty:fireAllClients({
        transparency = 0,
        duration = 1,
        easing = ReactSpring.easings.easeOutQuad
    })
    task.wait(1)
end

function gameService.DayPhase(allPlayersInfo)
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

function gameService.DiscussionPhase(allPlayersInfo)
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
            gameService.client.countdownTimer:fireAllClients(i)
            gameService.client.setTopbarText:fireAllClients({
                targetText = `Discuss who you think the Mafia is. ({i})`,
                initialText = string.sub(`Discuss who you think the Mafia is. ({i})`, 1, -2)
            })
        end, function(cancelled)
            gameService.client.countdownTimer:fireAllClients(nil)
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
            if secondsToDiscuss <= 0 then
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
    gameService.client.setTopbarText:fireAllClients(nil)
    gameService.client.toggleAudio:fireAllClients({
        sound = randomDiscussionSound,
        playing = false,
        duration = 1,
        volume = 0
    })
end

function gameService.VotingPhase(allPlayersInfo)
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
    print(gameService.client.canVote:get())

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
        gameService.client.countdownTimer:fireAllClients(i)
        gameService.client.setTopbarText:fireAllClients({
            targetText = `Vote on who you believe the Mafia is. ({i})`,
            initialText = string.sub(`Vote on who you believe the Mafia is. ({i})`, 1, -2)
        })
    end, function()
        gameService.client.countdownTimer:fireAllClients(nil)
        votingPhaseFinished:Fire()
    end)

    task.delay(gameConfig.skipVoteTimer, function()
        if #playerSkips > #allAlivePlayers/2 then
            votingCountdownCancel()
        end
    end)

    print('adfjhnaisfh')
    votingPhaseFinished.Event:Wait()

    gameService.client.canVote:set(false)

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

    local spawnLocations = {}
	local map = Maps[math.random(1, #Maps)]:Clone()
	map = ServerStorage.MAPS.Motel:Clone() -- test code for getting a specific map lol, should make a debug config instead
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

    if gameConfig.shouldPlayIntro then
        gameService.gameIntro(assignedRoles, participatingPlayers)
    end

    gameService.client.gameStarted:set(true)

    local allPlayersInfo = {}

    for userId, role in assignedRoles do
        allPlayersInfo[userId] = {
            role = role,
            alive = true
        }
    end

    local gamePhases = {
        "Night",
        "Day",
        "Discussion",
        "Voting"
    }

    while true do
        for _, phase in gamePhases do
            gameService.client.gamePhase:set(phase)
            if phase == "Night" then
                gameService.NightPhase(allPlayersInfo, spawnLocations)
            elseif phase == "Day" then
                gameService.DayPhase(allPlayersInfo)
            elseif phase == "Discussion" then
                gameService.DiscussionPhase(allPlayersInfo)
            elseif phase == "Voting" then
                gameService.VotingPhase(allPlayersInfo)
            end
        end
    end
end

return gameService