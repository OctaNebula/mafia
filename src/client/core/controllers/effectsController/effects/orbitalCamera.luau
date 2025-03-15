local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local cameraTween: Tween?

return function(enabled)
    if cameraTween then
        cameraTween:Cancel()
        cameraTween = nil
    end
    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera
    if enabled then
        camera.CameraType = Enum.CameraType.Orbital
        player.CameraMode = Enum.CameraMode.Classic
        player.CameraMinZoomDistance = 0.1
        player.CameraMaxZoomDistance = 0.1
        cameraTween = TweenService:Create(player, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CameraMinZoomDistance = 12, CameraMaxZoomDistance = 12})
        cameraTween:Play()
        -- tbh idk what this does but it might be a cool effect
        task.spawn(function()
            local oldoffset = player.Character.Humanoid.CameraOffset
            for i = 0, 10 do
                local x = math.random(-100,100)/800
                local y = math.random(-100,100)/800
                local z = math.random(-100,100)/1200
                player.Character.Humanoid.CameraOffset = Vector3.new(x, y, z)math.random(-1, 1)
                task.wait()
            end
            player.Character.Humanoid.CameraOffset = oldoffset
        end)
        print(camera.CameraType, player.CameraMode)
        task.wait(1)
        print(player.CameraMaxZoomDistance)
    else
        camera.CameraType = Enum.CameraType.Custom
    end
end