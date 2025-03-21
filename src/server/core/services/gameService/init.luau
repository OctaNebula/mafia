local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local sharedPackages = ReplicatedStorage.sharedPackages

local network = require(sharedPackages.network)
local Signal = require(sharedPackages.Signal)

local managers = script.managers

local introManager = require(managers.introManager)
local mapManager = require(managers.mapManager)
local uiManager = require(managers.uiManager)

local phaseHandler = require(script.phaseHandler)
local gameState = require(script.gameState)

local GAME_CONFIG = {
    GAME_START_TIMER = 1, -- 15

    SHOULD_PLAY_INTRO = false,

    NIGHT_START_TIMER = 1, -- 15
    MAFIA_KILL_TIMER = 5000, -- 90
    DOCTOR_REVIVE_TIMER = 10, -- unused -- 10
    NIGHT_END_TIMER = 15, -- 15 -- time until the night ends after a mafia kill

    DISCUSSION_TIMER = 5, -- 60
    SKIP_VOTE_TIMER = 30, -- unused -- 20
    VOTING_TIMER = 15, -- 30

    MIN_PLAYERS = 3,
    MAX_PLAYERS = 15,

    ROLE_CONFIGS = {
        DEFAULT = {
            roles = {
                guaranteed = {
                    mafia = 1,
                    doctor = 2
                },
                special = {
                    detainer = { maxPlayers = 1, baseChance = 1 },
                    jester = { maxPlayers = 1, baseChance = 1 },
                    vigilante = { maxPlayers = 1, baseChance = 1 },
                    witch = { maxPlayers = 1, baseChance = 1 }
                },
                default = {"civilian"}
            }
        },
        LARGE_GAME = {
            roles = {
                guaranteed = {
                    mafia = 3,
                    doctor = 1,
                    detective = 1
                },
                special = {
                    detainer = { maxPlayers = 1, baseChance = 1 },
                    jester = { maxPlayers = 1, baseChance = 1 },
                    vigilante = { maxPlayers = 1, baseChance = 1 },
                    witch = { maxPlayers = 1, baseChance = 1 }
                },
                default = {"civilian"}
            }
        }
    }
}

local gameActive = false
local loopThread

-- misc instance variables that are likely to be moved out of gameService

local gameService = {
    playersInfo = network.Server.RemoteProperty.new(nil),
    setCameraLockedToHead = Signal.new(),
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
        talliedVotes = network.Server.RemoteProperty.new(nil),

        -- client states
        lightsToggled = network.Server.RemoteProperty.new(true),
        chatToggled = network.Server.RemoteProperty.new(true),
        firstPersonForced = network.Server.RemoteProperty.new(false),
        cameraLockedToHead = network.Server.RemoteProperty.new(false),
        canSkipVote = network.Server.RemoteProperty.new(false),
        canVote = network.Server.RemoteProperty.new(false),
        isDead = network.Server.RemoteProperty.new(false),
        spectating = network.Server.RemoteProperty.new(false),
    }
}

function gameService.start()
    introManager.init(gameService)
    mapManager.init(gameService)
    uiManager.init(gameService)

    phaseHandler.init(gameService)

    ReplicatedStorage.exe_storage.events.custom_command_events.startGame.OnServerEvent:Connect(function()
        gameService.startGame()
    end)

    ReplicatedStorage.exe_storage.events.custom_command_events.endGame.OnServerEvent:Connect(function()
        gameService.endGame()
    end)

    gameService.setCameraLockedToHead:Connect(function(player, bool)
        gameService.client.cameraLockedToHead:setForClient(player, bool)
    end)

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            character.HumanoidRootPart.CanCollide = false
        end)
        player:LoadCharacter()
    end)

    -- testing code
    -- local gameStarted = false
    -- local gameLoaded = {}
    -- gameService.client.gameLoaded:connect(function(player)
    --     if gameLoaded[player.UserId] then
    --         return
    --     end
    --     gameLoaded[player.UserId] = true
    --     local allPlayers = Players:GetPlayers()
    --     if (#allPlayers >= 3 and not gameStarted) or (player.UserId > 0 and not gameStarted) then
    --         gameStarted = true
    --         for i = GAME_CONFIG.GAME_START_TIMER, 0, -1 do
    --             uiManager.setTopbarText("all", `Game starting in: {i}`, true)
    --             task.wait(1)
    --         end
    --         gameService.client.setTopbarText:fireAllClients()
    --         gameService.startGame()
    --     end
    -- end)
    -- Players.PlayerRemoving:Connect(function(player)
    --     gameLoaded[player.UserId] = nil
    -- end)
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
    23/01/2025 - 1 hour
        moved some stuff over to pointingService
    28/01/2025 - 4 hours (summed up from some untracked days)
        fixing up roleService and roleController networking
        fixed a bunch of stupid bugs
    29/01/2025 - 4 hours
        literaly just refactoring gameService
    31/01/2025 - 5 hours
        finished voting stuff
        people can actually die now
        spectating works
    2/02/2025 - 2 hours
        added flashlights
    4/02/2025-10/02/2025 - 6 hours?
        i forgot to count honestly, dont even remember what i did exactly aside from the end date
        interactionService and interactionController added
    11/02/2025-12/02/2025 - 3 hours
        cleaned up code here and there to prep for some updates
        added animationService to preload animations for characters
        added exclusive interactions for better control over inputs

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

function gameService.startGame()
    if gameActive then
        return
    end
    gameActive = true
    local participatingPlayers = Players:GetPlayers()
    local currentGameState = gameState.new(gameService, GAME_CONFIG, participatingPlayers)
    uiManager.fade(0)
    task.wait(1)
    currentGameState:assignRoles()
    local _, spawnLocations = mapManager.loadMap(if RunService:IsStudio() then "Testing" else "Motel")
    currentGameState:registerSpawnLocations(spawnLocations)
    mapManager.waitForPlayersAsync(participatingPlayers)

    if GAME_CONFIG.SHOULD_PLAY_INTRO then
        introManager.playIntro(currentGameState.players)
    end

    gameService.client.gameStarted:set(true)

    uiManager.fade(1)

    loopThread = coroutine.create(function()
        local gamePhases = {"Night", "Day", "Discussion", "Voting"}
        while true do
            for _, phase in gamePhases do
                gameService.client.gamePhase:set(phase)
                phaseHandler[phase](currentGameState)
            end
            currentGameState:incrementCurrentDay()
        end
    end)
    coroutine.resume(loopThread)
    local connection
    connection = RunService.Heartbeat:Connect(function()
        local evilAlive = 0
        local goodAlive = 0
        for _, playerInfo in currentGameState.players do
            if playerInfo.alive then
                if playerInfo.role == "mafia" then
                    evilAlive += 1
                else
                    goodAlive += 1
                end
            end
        end
        if evilAlive >= goodAlive then
            connection:Disconnect()
            gameService.endGame()
        end
    end)
end

function gameService.endGame()
    if not gameActive then
        return
    end
    coroutine.close(loopThread)
    uiManager.fade(0)
    task.wait(1)
    local allPlayers = Players:GetPlayers()
    gameService.playersInfo:set(nil)
    gameService.client.gameStarted:set(false)

    gameService.client.introSkipped:set(false)
    gameService.client.introSkippedInfo:set({
        playersSkippedIntro = 0,
        participatingPlayers = 0,
    })

    gameService.client.gameStarted:set(false)
    gameService.client.abilitiesEnabled:set(false)
    gameService.client.gamePhase:set(nil)
    gameService.client.talliedVotes:set(nil)

    gameService.client.lightsToggled:setForClients(allPlayers, true)
    gameService.client.chatToggled:setForClients(allPlayers, true)
    gameService.client.firstPersonForced:setForClients(allPlayers, false)
    gameService.client.cameraLockedToHead:setForClients(allPlayers, false)
    gameService.client.canSkipVote:setForClients(allPlayers, false)
    gameService.client.canVote:setForClients(allPlayers, false)
    gameService.client.isDead:setForClients(allPlayers, false)
    gameService.client.spectating:setForClients(allPlayers, false)

    mapManager.unloadMap()

    for _, player in allPlayers do
        player:LoadCharacter()
    end
    uiManager.fade(1)
    gameActive = false
end

return gameService