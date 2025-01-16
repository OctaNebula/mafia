local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local sharedPackages = ReplicatedStorage.sharedPackages
local serverModules = ServerStorage.server.modules

local network = require(sharedPackages.network)

local roleAssigner = require(serverModules.roleAssigner)

-- misc instance variables that are likely to be moved out of gameService
local Maps = ServerStorage:WaitForChild("MAPS"):GetChildren()

local gameService = {
    client = {
        playDeathCutscene = network.Server.RemoteSignal.new(),
        explainRules = network.Server.RemoteSignal.new(),
        introCompleted = network.Server.RemoteSignal.new(),
        skipIntro = network.Server.RemoteSignal.new(),
        
        introSkipped = network.Server.RemoteProperty.new(false),
        gameStarted = network.Server.RemoteProperty.new(false),
        introSkippedInfo = network.Server.RemoteProperty.new({
            playersSkippedIntro = 0,
            participatingPlayers = 0
        }),
        gameIntroCountdown = network.Server.RemoteProperty.new(nil)
    }
}

function gameService.start()
    PhysicsService:RegisterCollisionGroup("player")
    PhysicsService:RegisterCollisionGroup("ghost")
    PhysicsService:CollisionGroupSetCollidable("player", "ghost", false)

    -- testing code
    Players.PlayerAdded:Connect(function()
        local allPlayers = Players:GetPlayers()
        if #allPlayers >= 3 then
            for i = 20, 0, -1 do
                gameService.client.gameIntroCountdown:set(i)
                task.wait(1)
            end
            gameService.client.gameIntroCountdown:set(nil)
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
    12/01/2025
        Added skipping intro with majority

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
    gameService.client.introSkipped:set(false)
    gameService.client.gameStarted:set(false)
    gameService.client.introSkippedInfo:set({
        playersSkippedIntro = 0,
        participatingPlayers = 0
    })

    local spawnLocations = {} -- should be stored outside of this scope?
	local map = Maps[math.random(1, #Maps)]:Clone() -- should be stored outside of this scope
	map = ServerStorage.MAPS.Library:Clone() -- test code for getting a specific map lol, should make a debug config instead
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

	local assignedRoles -- should be stored outside this scope
    if #participatingPlayers < 3 then
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

    gameService.client.gameStarted:set(true)

    -- this should start the game after firing a lot of remoteevents and then using NightCycle.StartNight
    -- gives an explanation of the game rules for 1 second, then starts the game
	-- if InGame == false then
	-- 	InGame = true
	-- 	TweenService:Create(SoundService["explainingRules"], TweenInfo.new(1), {Volume = 0}):Play()
	-- 	task.delay(1, function()
	-- 		SoundService["explainingRules"]:Stop()
	-- 	end)
	-- 	ReplicatedStorage.Remote.Client:FireAllClients("RemoveSkip")
	-- 	ReplicatedStorage.Configuration:SetAttribute("SkippedInstructions", true)
	-- 	ReplicatedStorage.Remote.Client:FireAllClients("GameStart", Spawns)
	-- 	NightCycle.StartNight(Map, Spawns, AssignedRoles)
	-- end
end

return gameService