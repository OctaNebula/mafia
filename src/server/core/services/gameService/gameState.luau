local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local serverModules = ServerStorage.server.modules
local roleAssigner = require(serverModules.roleAssigner)

local gameState = {}
gameState.__index = gameState

function gameState.new(gameService, GAME_CONFIG, participatingPlayers)
    local self = setmetatable({}, gameState)
    self:init(gameService, GAME_CONFIG, participatingPlayers)
    return self
end

function gameState:init(gameService, GAME_CONFIG, participatingPlayers)
    self.properties = {
        playersInfo = gameService.playersInfo
    }

    self.GAME_CONFIG = GAME_CONFIG
    self.currentDay = 1
    self.players = {}
    self.deaths = {}
    for _, player in participatingPlayers do
        self.players[player.UserId] = {
            role = nil,
            alive = true,
        }
    end
    self.properties.playersInfo:set(table.clone(self.players))
end

function gameState:registerSpawnLocations(spawnLocations)
    self.spawnLocations = spawnLocations
end

function gameState:assignRoles()
    local playerCount = 0
    for _, _ in self.players do
        playerCount += 1
    end
    if playerCount < self.GAME_CONFIG.MIN_PLAYERS and not RunService:IsStudio() then
        error(`There are only {playerCount}/{self.GAME_CONFIG.MIN_PLAYERS} required players.`)
    end

    local roleConfig = playerCount >= self.GAME_CONFIG.MAX_PLAYERS
        and self.GAME_CONFIG.ROLE_CONFIGS.LARGE_GAME
        or self.GAME_CONFIG.ROLE_CONFIGS.DEFAULT

    -- Special case for studio testing
    if playerCount == 1 and RunService:IsStudio() then
        roleConfig = { roles = { default = {"civilian"} } }
    end

    local participatingPlayers = {}
    for userId, _ in self.players do
        participatingPlayers[#participatingPlayers+1] = userId
    end

    local assignedRoles = roleAssigner.assignRoles(roleConfig, participatingPlayers)

    for userId, role in assignedRoles do
        if self.players[userId] then
            self.players[userId].role = role
        end
    end

    print(self.players)
    self.properties.playersInfo:set(table.clone(self.players))
    return assignedRoles
end

function gameState:incrementCurrentDay()
    self.currentDay += 1
end

function gameState:registerDeath(killer, victim, reason, bodyFinder)
    print(killer.UserId, victim.UserId, reason, self.players)
    if not self.players[victim.UserId].alive then
        return false
    end

    self.players[victim.UserId].alive = false

    if not self.deaths[self.currentDay] then
        self.deaths[self.currentDay] = {}
    end

    self.deaths[self.currentDay][victim.UserId] = {
        killer = killer.UserId,
        roleKiller = self.players[killer.UserId].role,
        reason = reason,
        bodyFinder = bodyFinder
    }

    self.properties.playersInfo:set(table.clone(self.players))
    return true
end

function gameState:getAllDeathsOnCurrentDay()
    return self.deaths[self.currentDay] or {}
end

return gameState