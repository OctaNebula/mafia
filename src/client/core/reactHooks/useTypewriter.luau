local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.sharedPackages

-- local ReactRoblox = require(Packages.ReactRoblox)
-- local ReactSpring = require(Packages.ReactSpring)
local React = require(Packages.React)

function useTypewriter(initialText: string, targetText: string, delay: number, callback: () -> ()): React.ReactBinding<string>
    local currentText, setCurrentText = React.useBinding("")

    React.useEffect(function()
        local coro = coroutine.create(function()
            if string.sub(targetText, 1, #initialText) ~= initialText then
                initialText = targetText
            end
            local newText = initialText
            if #targetText == 0 or initialText == targetText then
                setCurrentText(targetText)
                return
            end
            for index = #initialText + 1, #targetText do
                newText = newText .. string.sub(targetText, index, index)
                setCurrentText(newText)
                callback()
                task.wait(delay)
            end
        end)
        
        coroutine.resume(coro)

        return function()
            coroutine.close(coro)
        end
    end, {targetText})

    return currentText
end

return useTypewriter