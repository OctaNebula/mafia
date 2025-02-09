local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedPackages = ReplicatedStorage.sharedPackages
local ReactSpring = require(sharedPackages.ReactSpring)

local uiManager = {
    events = {}
}

function uiManager.init(gameService)
    uiManager.events.setFadeProperty = gameService.client.setFadeProperty
    uiManager.events.setTopbarText = gameService.client.setTopbarText
end

function uiManager.setTopbarText(targetPlayers, text, shouldTick, shouldWait)
    local textData = {
        targetText = text,
        initialText = if shouldTick then #text == 0 and "" or string.sub(text, 1, -2) else nil
    }
    
    if targetPlayers == "all" then
        uiManager.events.setTopbarText:fireAllClients(textData)
    else
        uiManager.events.setTopbarText:fireClients(targetPlayers, textData)
    end
    if shouldWait then
        task.wait(#text*0.025)
    end
end

function uiManager.fade(transparency, duration, easing)
    uiManager.events.setFadeProperty:fireAllClients({
        transparency = transparency,
        duration = duration or 1,
        easing = if easing then easing elseif transparency == 0 then ReactSpring.easings.easeOutQuad else ReactSpring.easings.easeInQuad
    })
end

return uiManager