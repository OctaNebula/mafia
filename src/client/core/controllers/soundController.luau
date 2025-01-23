local TweenService = game:GetService("TweenService")

local soundController = {}

function soundController.start()

end

function soundController.play2DAudio(sound: Sound, playing: boolean, duration: number?, volume: number?)
    local tween
    if duration then
        sound.Volume = volume or if playing then 0.5 else 0
        tween = TweenService:Create(sound, TweenInfo.new(duration), {Volume = volume or if playing then 0.5 else 0})
    end
    if playing then
        sound:Play()
    end
    if tween then
        -- print(`Playing tween for ({sound.Name})`)
        tween:Play()
        tween.Completed:Wait()
        -- print(`Finished tween for sound ({sound.Name})`)
    end
    if not playing then
        sound:Stop()
    end
end

function soundController.play3DAudio()
    
end

return soundController