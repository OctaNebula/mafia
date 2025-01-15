-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local exampleController = {}

function exampleController.start()
    RunService.RenderStepped:Connect(exampleController.updateBobbleEffect)
end

function exampleController.updateBobbleEffect()
    local character = game.Players.LocalPlayer.Character
    if not character then
        return
    end
    -- local hrp = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    -- local se = hrp:WaitForChild("Running")
    -- se:Destroy()

    local camera = workspace.CurrentCamera
    
    local currentTime = tick()
    if game.Players.LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson then
        if humanoid.MoveDirection.Magnitude > 0 then
            local multiplier = 0.2
            local magnitude = 5

            if humanoid.WalkSpeed > game.StarterPlayer.CharacterWalkSpeed + 1 then
                magnitude = magnitude * 2
            end

            local bobbleX = math.cos(currentTime * magnitude) * multiplier
            local bobbleY = math.abs(math.sin(currentTime * magnitude)) * multiplier

            local bobble = Vector3.new(bobbleX, bobbleY, -1)

            humanoid.CameraOffset = humanoid.CameraOffset:Lerp(bobble, .25)
            camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, bobbleX/55)--, 0) -- commented out part since angles probably doesnt use the 4th arg? add it back if things start imploding
        else 
            humanoid.CameraOffset = Vector3.new(humanoid.CameraOffset.X * .75, humanoid.CameraOffset.Y * .75, -1)
        end
    end

    -- might want to make a different controller for these things
    -- for _, v in pairs(character:GetChildren()) do
    --     if v:IsA("BasePart") then
    --         if v.Name ~= "Head" then
    --             v.LocalTransparencyModifier = 0
    --         end
    --         if humanoid.Parent:GetAttribute("Downed") == true then
    --             v.LocalTransparencyModifier = 0
    --         end
    --     end

    --     if v:IsA("Accessory") then
    --         if not (v.Handle:FindFirstChild("AccessoryWeld").Part1 == script.Parent.Head) then
    --             v.Handle.LocalTransparencyModifier = 0
    --         else 
    --             if humanoid.Parent:GetAttribute("Downed") == true then
    --                 v.Handle.LocalTransparencyModifier = 0
    --             end
    --         end
    --     end
    -- end
    
    -- local flashlight = script.Parent:FindFirstChild("Flashlight")
    -- if flashlight then
    --     for _, plart in flashlight:GetDescendants() do
    --         if plart:IsA("BasePart") then
    --             plart.LocalTransparencyModifier = 0
    --         end
    --     end
    -- end
end

return exampleController