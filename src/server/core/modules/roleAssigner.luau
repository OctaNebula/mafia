--[[
    author: brycentjw

    roleAssigner
    A module for assigning roles to players with configurable rules and probabilities.

    Example usage:
    local roleConfigs = {
        roles = {
            guaranteed = { -- list of roles that will be given, values are the number of players the role will be given to
                mafia = 2,
                doctor = 1,
                detective = 1
            },
            special = {
                detainer = {
                    maxPlayers = 2, -- can get up to 2 slots
                    baseChance = 0.5 -- 50% for each slot to be used
                },
                jester = {
                    maxPlayers = 1, -- can get up to 1 slot
                    baseChance = 0.5 -- 50% for each slot to be used
                },
                vigilante = {
                    maxPlayers = 4, -- can get up to 4 slots
                    baseChance = 0.5 -- 50% for each slot to be used
                },
                witch = {
                    maxPlayers = 1, -- can get up to 1 slot
                    baseChance = 0.5 -- 50% for each slot to be used
                }
            },
            default = {"civilian"} -- list of roles that will be assigned to anyone without a role, if there are multiple default roles they will be distributed as evenly as possible with priority going to default roles with indexes closest to 1
        },
        playerModifiers = {
            ["Player1"] = {
                mafia = 2, -- 2x chance to get this role
                doctor = 0.5, -- 0.5x chance to get this role
                detective = 0.5 -- 0.5x chance to get this role
            },
            ["Player2"] = {
                mafia = 0, -- 0x chance to get this role
                doctor = 0.5, -- 0.5x chance to get this role
                detective = 0.5 -- 0.5x chance to get this role
            },
            ["Player3"] = {
                mafia = true, -- guaranteed to get this role
            }
        }
    }

    icl most of this was written by an ai so it's very close to just being a straight up black box since i didnt write any of it myself
    the math behind it should be fairly obvious given the configuration though, just means it's a lot of work to write a function that calculates the chances of a player getting a role in a way that even makes sense
]]

local roleAssigner = {}

-- Utility function to clone a table
local function tableClone(t)
	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			copy[k] = tableClone(v)
		else
			copy[k] = v
		end
	end
	return copy
end

-- Converts configuration to internal format
local function normalizeConfig(config)
	local normalized = {
		roles = {},
	}

	-- Process guaranteed roles
	for role, count in pairs(config.roles.guaranteed or {}) do
		normalized.roles[role] = {
			minPlayers = count,
			maxPlayers = count,
			baseChance = 100,
			isGuaranteed = true,
		}
	end

	-- Process special roles
	for role, settings in pairs(config.roles.special or {}) do
		normalized.roles[role] = {
			minPlayers = 0,
			maxPlayers = settings.maxPlayers,
			baseChance = settings.baseChance * 100, -- Convert from decimal to percentage
			isSpecial = true,
		}
	end

	-- Process default roles
	for index, role in ipairs(config.roles.default or {}) do
		normalized.roles[role] = {
			minPlayers = 0,
			maxPlayers = math.huge, -- No limit for default roles
			baseChance = 100,
			isDefault = true,
			defaultPriority = index, -- Lower means higher priority
		}
	end

	-- Process player modifiers
	normalized.playerModifiers = {}
	for player, modifiers in pairs(config.playerModifiers or {}) do
		normalized.playerModifiers[player] = {}
		for role, modifier in pairs(modifiers) do
			-- Convert boolean guarantees to special modifier value
			if type(modifier) == "boolean" and modifier then
				normalized.playerModifiers[player][role] = "GUARANTEED"
			else
				normalized.playerModifiers[player][role] = modifier
			end
		end
	end

	return normalized
end

-- Gets list of roles a player is guaranteed for
local function getGuaranteedRoles(player, normalizedConfig)
	local guaranteed = {}
	local modifiers = normalizedConfig.playerModifiers[player] or {}

	-- First add guaranteed roles
	for role, config in pairs(normalizedConfig.roles) do
		if config.isGuaranteed and modifiers[role] == "GUARANTEED" then
			table.insert(guaranteed, { role = role, priority = 1 })
		end
	end

	-- Then add special roles
	for role, config in pairs(normalizedConfig.roles) do
		if config.isSpecial and modifiers[role] == "GUARANTEED" then
			table.insert(guaranteed, { role = role, priority = 2 })
		end
	end

	-- Sort by priority (guaranteed before special)
	table.sort(guaranteed, function(a, b)
		return a.priority < b.priority
	end)

	return guaranteed
end

-- Gets default role probabilities without player modifiers
function roleAssigner.getDefaultRoleProbabilities(config)
	local normalized = normalizeConfig(config)
	local probabilities = {}
	local totalWeight = 0

	-- Calculate total base weight
	for _, roleConfig in pairs(normalized.roles) do
		if not roleConfig.isDefault then -- Skip default roles
			totalWeight = totalWeight + (roleConfig.baseChance * roleConfig.maxPlayers)
		end
	end

	-- Calculate percentage for each role
	for roleName, roleConfig in pairs(normalized.roles) do
		if not roleConfig.isDefault then -- Skip default roles
			local roleWeight = roleConfig.baseChance * roleConfig.maxPlayers
			probabilities[roleName] = {
				percentage = (roleWeight / totalWeight) * 100,
				maxPlayers = roleConfig.maxPlayers,
				baseChance = roleConfig.baseChance,
			}
		end
	end

	return probabilities
end

-- Assigns roles to players based on configurations
function roleAssigner.assignRoles(config, players)
	local normalized = normalizeConfig(config)
	local assignments = {}
	local roleCounts = {}
	local availablePlayers = tableClone(players)

	-- Initialize role counts
	for roleName, _ in pairs(normalized.roles) do
		roleCounts[roleName] = 0
	end

	-- Phase 1: Handle guaranteed role assignments
	local guaranteedPlayers = {}
	for _, player in ipairs(players) do
		local guaranteedRoles = getGuaranteedRoles(player, normalized)
		if #guaranteedRoles > 0 then
			table.insert(guaranteedPlayers, {
				player = player,
				roles = guaranteedRoles,
			})
		end
	end

	-- Sort guaranteed players randomly to handle competition fairly
	for i = #guaranteedPlayers, 2, -1 do
		local j = math.random(i)
		guaranteedPlayers[i], guaranteedPlayers[j] = guaranteedPlayers[j], guaranteedPlayers[i]
	end

	-- Try to assign guaranteed roles
	for _, data in ipairs(guaranteedPlayers) do
		local player = data.player

		for _, roleData in ipairs(data.roles) do
			local roleName = roleData.role
			local roleConfig = normalized.roles[roleName]

			-- Check if we can assign this role
			if roleCounts[roleName] < roleConfig.maxPlayers then
				-- For special roles, only create new slot if specifically guaranteed
				if
					not roleConfig.isSpecial
					or (
						roleConfig.isSpecial
						and normalized.playerModifiers[player][roleName] == "GUARANTEED"
					)
				then
					assignments[player] = roleName
					roleCounts[roleName] = roleCounts[roleName] + 1
					-- Remove from available players
					for i, p in ipairs(availablePlayers) do
						if p == player then
							table.remove(availablePlayers, i)
							break
						end
					end
					break
				end
			end
		end
	end

	-- Phase 2: Fill mandatory roles that weren't filled by guarantees
	for roleName, roleConfig in pairs(normalized.roles) do
		if roleConfig.minPlayers > 0 then
			while roleCounts[roleName] < roleConfig.minPlayers and #availablePlayers > 0 do
				-- Pick random player
				local randIndex = math.random(#availablePlayers)
				local player = availablePlayers[randIndex]

				-- Assign role
				assignments[player] = roleName
				roleCounts[roleName] = roleCounts[roleName] + 1

				-- Remove player from available pool
				table.remove(availablePlayers, randIndex)
			end
		end
	end

	-- Phase 3: Roll for special roles
	for roleName, roleConfig in pairs(normalized.roles) do
		if roleConfig.isSpecial then
			local remainingSlots = roleConfig.maxPlayers - roleCounts[roleName]

			-- Roll for each potential slot
			for _ = 1, remainingSlots do
				if #availablePlayers > 0 and math.random() < (roleConfig.baseChance / 100) then
					local randIndex = math.random(#availablePlayers)
					local player = availablePlayers[randIndex]

					-- Assign role
					assignments[player] = roleName
					roleCounts[roleName] = roleCounts[roleName] + 1

					-- Remove player from available pool
					table.remove(availablePlayers, randIndex)
				end
			end
		end
	end

	-- Phase 4: Assign remaining players to default roles
	if #availablePlayers > 0 then
		-- Get sorted default roles
		local defaultRoles = {}
		for roleName, roleConfig in pairs(normalized.roles) do
			if roleConfig.isDefault then
				table.insert(defaultRoles, {
					name = roleName,
					priority = roleConfig.defaultPriority,
				})
			end
		end

		-- Sort by priority
		table.sort(defaultRoles, function(a, b)
			return a.priority < b.priority
		end)

		-- Distribute remaining players across default roles
		local defaultRoleIndex = 1
		for _, player in ipairs(availablePlayers) do
			assignments[player] = defaultRoles[defaultRoleIndex].name
			defaultRoleIndex = defaultRoleIndex % #defaultRoles + 1
		end
	end

	return assignments
end

-- -- Gets individual probabilities for each player-role combination
-- function roleAssigner.getPlayerRoleProbabilities(config, players)
-- 	local normalized = normalizeConfig(config)
-- 	local probabilities = {}

-- 	-- Calculate probabilities for each player
-- 	for _, player in ipairs(players) do
-- 		probabilities[player] = {}
-- 		local totalPlayerWeight = 0
-- 		local modifiers = normalized.playerModifiers[player] or {}

-- 		-- Calculate total weight for this player
-- 		for roleName, roleConfig in pairs(normalized.roles) do
-- 			if not roleConfig.isDefault then -- Skip default roles
-- 				local modifier = modifiers[roleName]
-- 				if modifier == "GUARANTEED" then
-- 					modifier = 100 -- Very high chance for guaranteed roles
-- 				elseif type(modifier) == "number" then
-- 					modifier = modifier
-- 				else
-- 					modifier = 1
-- 				end
-- 				totalPlayerWeight = totalPlayerWeight + (roleConfig.baseChance * modifier * roleConfig.maxPlayers)
-- 			end
-- 		end

-- 		-- Calculate percentage for each role for this player
-- 		for roleName, roleConfig in pairs(normalized.roles) do
-- 			if not roleConfig.isDefault then -- Skip default roles
-- 				local modifier = modifiers[roleName]
-- 				if modifier == "GUARANTEED" then
-- 					modifier = 100 -- Very high chance for guaranteed roles
-- 				elseif type(modifier) == "number" then
-- 					modifier = modifier
-- 				else
-- 					modifier = 1
-- 				end
-- 				local roleWeight = roleConfig.baseChance * modifier * roleConfig.maxPlayers
-- 				probabilities[player][roleName] = {
-- 					percentage = (roleWeight / totalPlayerWeight) * 100,
-- 					modifier = modifier,
-- 					baseChance = roleConfig.baseChance,
-- 					effectiveWeight = roleWeight
-- 				}
-- 			end
-- 		end
-- 	end

-- 	return probabilities
-- end

-- -- Gets simplified percentage chances for each player
-- function roleAssigner.getSimplePlayerChances(config, players)
-- 	local normalized = normalizeConfig(config)
-- 	local probabilities = roleAssigner.getPlayerRoleProbabilities(config, players)
-- 	local simpleChances = {}

-- 	-- For each player
-- 	for _, player in ipairs(players) do
-- 		simpleChances[player] = {}
-- 		local playerProbs = probabilities[player]

-- 		-- Check for guaranteed roles first
-- 		local guaranteedRoles = getGuaranteedRoles(player, normalized)
-- 		if #guaranteedRoles > 0 then
-- 			-- Add guaranteed roles with 100% chance
-- 			for _, roleData in ipairs(guaranteedRoles) do
-- 				simpleChances[player][roleData.role] = "100% (Guaranteed)"
-- 			end
-- 			-- Other roles get very low chances due to guarantee
-- 			for roleName, _ in pairs(normalized.roles) do
-- 				if not simpleChances[player][roleName] then
-- 					simpleChances[player][roleName] = "~0%"
-- 				end
-- 			end
-- 		else
-- 			-- Add percentage for each role
-- 			for roleName, roleData in pairs(playerProbs) do
-- 				local percent = roleData.percentage
-- 				if percent == 0 then
-- 					simpleChances[player][roleName] = "0%"
-- 				elseif percent < 1 then
-- 					simpleChances[player][roleName] = "<1%"
-- 				else
-- 					simpleChances[player][roleName] = string.format("%.1f%%", percent)
-- 				end
-- 			end

-- 			-- Add default roles
-- 			local remainingChance = 0
-- 			for _, roleConfig in pairs(normalized.roles) do
-- 				if roleConfig.isDefault then
-- 					remainingChance = remainingChance + 1
-- 				end
-- 			end

-- 			if remainingChance > 0 then
-- 				for roleName, roleConfig in pairs(normalized.roles) do
-- 					if roleConfig.isDefault then
-- 						simpleChances[player][roleName] = string.format("%.1f%%", (1 / remainingChance) * 100)
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end

-- 	return simpleChances
-- end

-- -- Prints player chances in a formatted way
-- function roleAssigner.printPlayerChances(config, players)
-- 	local chances = roleAssigner.getSimplePlayerChances(config, players)

-- 	-- Get all role names for consistent ordering
-- 	local allRoles = {}

-- 	-- Add guaranteed roles first
-- 	for roleName, _ in pairs(config.roles.guaranteed or {}) do
-- 		table.insert(allRoles, roleName)
-- 	end

-- 	-- Add special roles next
-- 	for roleName, _ in pairs(config.roles.special or {}) do
-- 		table.insert(allRoles, roleName)
-- 	end

-- 	-- Add default roles last
-- 	for _, roleName in ipairs(config.roles.default or {}) do
-- 		table.insert(allRoles, roleName)
-- 	end

-- 	-- Calculate column widths
-- 	local playerNameWidth = 10 -- minimum width
-- 	for _, player in ipairs(players) do
-- 		playerNameWidth = math.max(playerNameWidth, #player)
-- 	end

-- 	local roleWidths = {}
-- 	for _, role in ipairs(allRoles) do
-- 		roleWidths[role] = math.max(#role, 7) -- minimum 7 for percentage
-- 	end

-- 	-- Print header
-- 	print(string.rep(" ", playerNameWidth + 2))
-- 	for _, role in ipairs(allRoles) do
-- 		local width = roleWidths[role]
-- 		print(string.format("%-" .. width .. "s  ", role))
-- 	end
-- 	print("\n")

-- 	-- Print separator
-- 	print(string.rep("-", playerNameWidth + 2))
-- 	for _, role in ipairs(allRoles) do
-- 		print(string.rep("-", roleWidths[role] + 2))
-- 	end
-- 	print("\n")

-- 	-- Print each player's chances
-- 	for _, player in ipairs(players) do
-- 		print(string.format("%-" .. playerNameWidth .. "s  ", player))
-- 		for _, role in ipairs(allRoles) do
-- 			local chance = chances[player][role] or "0%"
-- 			local width = roleWidths[role]
-- 			print(string.format("%-" .. width .. "s  ", chance))
-- 		end
-- 		print("\n")
-- 	end
-- end

return roleAssigner
