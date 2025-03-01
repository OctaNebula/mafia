-- sorry this code is rushed im sleepy as all hell
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local initializedPlayers = {}

local mafiaHighlightTimer = {}

function mafiaHighlightTimer.init(timeToHide, timeToReset, timeToHighlight)
    local function characterAdded(player, character)
        if initializedPlayers[player].highlighted then
            character:AddTag("MafiaHighlighted")
        end
    end

    local function playerAdded(player)
        initializedPlayers[player] = {
            highlighted = false,
            timerActive = false,
            highlightedTimer = timeToHighlight,
            resetTimer = timeToReset,
            hideTimer = timeToHide,
        }
        player.CharacterAdded:Connect(function(character: Model)
            characterAdded(player, character)
        end)
    end

    for _, player in Players:GetPlayers() do
        playerAdded(player)
    end
    Players.PlayerAdded:Connect(playerAdded)

    CollectionService:GetInstanceRemovedSignal("MafiaHighlighted"):Connect(function(object)
        local player = Players:GetPlayerFromCharacter(object)
        if not player then
            return
        end
        local timerData = initializedPlayers[player]
        timerData.highlighted = false
        timerData.highlightedTimer = timeToHighlight
        timerData.resetTimer = timeToReset
        timerData.hideTimer = timeToHide
    end)

    Players.PlayerRemoving:Connect(function(player)
        initializedPlayers[player] = nil
    end)

    RunService.Heartbeat:Connect(function(deltaTime)
        for player, timerData in initializedPlayers do
            local character: Model = player.Character
            if not character then
                continue
            end
            local timerActive = timerData.timerActive

            -- if there's still hiding time left and the timer is active, reduce it
            if timerData.hideTimer > 0 and timerActive then
                timerData.hideTimer -= deltaTime
                -- highlight the player if there's no time left
                if timerData.hideTimer <= 0 then
                    timerData.highlighted = true
                    character:AddTag("MafiaHighlighted")
                end
            -- however, if there's still no time left and the timer is active, reset the highlight timer
            elseif timerData.hideTimer <= 0 and timerActive then
                timerData.highlightedTimer = timeToHide
            end

            -- if the timer is not active and the player is highlighted, reduce the highlighted time left
            if timerData.hideTimer <= 0 and not timerActive and timerData.highlightedTimer > 0 then
                timerData.highlightedTimer -= deltaTime
                -- if the player has run out of highlight time, unhighlight them
                if timerData.highlightedTimer <= 0 then
                    timerData.highlighted = false
                    character:RemoveTag("MafiaHighlighted")
                end
            end

            -- if the player was never highlighted but used up some hideTimer and the timer isnt active, reduce reset timer
            if not timerData.highlighted and timerData.hideTimer < timeToHide and not timerActive then
                timerData.resetTimer -= deltaTime
                -- if this timer reaches 0, reset all timers
                if timerData.resetTimer <= 0 then
                    timerData.highlightedTimer = timeToHighlight
                    timerData.resetTimer = timeToReset
                    timerData.hideTimer = timeToHide
                end
            end
        end
    end)
    return mafiaHighlightTimer
end

function mafiaHighlightTimer.toggleTimer(player, toggled)
    initializedPlayers[player].timerActive = toggled
end

function mafiaHighlightTimer.disableAllTimers()
    for player, timerData in initializedPlayers do
        local character: Model = player.Character
        timerData.timerActive = false
        character:RemoveTag("MafiaHighlighted")
    end
end

return mafiaHighlightTimer