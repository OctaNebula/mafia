local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local shared = ReplicatedStorage.shared
local serviceUtil = require(shared.utilities.serviceUtil)
local gameService = serviceUtil.service("gameService")

local cameraController = {}

function cameraController.start()
	RunService.RenderStepped:Connect(cameraController.updateBobbleEffect)
end

function cameraController.updateBobbleEffect()
	local character = LocalPlayer.Character
	if not character then
		return
	end
	local humanoid = character:WaitForChild("Humanoid")

	local mouse = LocalPlayer:GetMouse()

	local camera = workspace.CurrentCamera

	local currentTime = tick()
	if LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson then
		if humanoid.MoveDirection.Magnitude > 0 then
			local multiplier = 0.2
			local magnitude = 5

			if humanoid.WalkSpeed > game.StarterPlayer.CharacterWalkSpeed + 1 then
				magnitude = magnitude * 2
			end

			local bobbleX = math.cos(currentTime * magnitude) * multiplier
			local bobbleY = math.abs(math.sin(currentTime * magnitude)) * multiplier

			local bobble = Vector3.new(bobbleX, bobbleY, -1)

			humanoid.CameraOffset = humanoid.CameraOffset:Lerp(bobble, 0.25)
			camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, bobbleX / 55) --, 0) -- commented out part since angles probably doesnt use the 4th arg? add it back if things start imploding
		else
			humanoid.CameraOffset =
				Vector3.new(humanoid.CameraOffset.X * 0.75, humanoid.CameraOffset.Y * 0.75, -1)
		end
	end

	-- Setting head direction
	if character:FindFirstChild("Head") then
        if not humanoid.PlatformStand then -- can change condition to not being dead, so they can 'look around' while downed
            local target
            if LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson then
                target = character.UpperTorso.CFrame:toObjectSpace(workspace.CurrentCamera.CFrame).lookVector
            else
                target = character.UpperTorso.CFrame:toObjectSpace(mouse.Hit).lookVector
            end
            local targetC0 = CFrame.new(0, 0.8, 0)
            * CFrame.Angles(
                math.tan(target.Y) + math.rad(0),
                math.rad(0) - math.asin(target.X),
                0
            )
            character.Head.Neck.C0 = character.Head.Neck.C0:Lerp(targetC0, 0.3)
            gameService.pointHead:fireServer(targetC0, 0.3)
        end
	end

	-- might want to make a different controller for these things
	for _, v in pairs(character:GetChildren()) do
		if v:IsA("BasePart") then
			if v.Name ~= "Head" then
				v.LocalTransparencyModifier = 0
			end
			if humanoid.Parent:GetAttribute("Downed") == true then
				v.LocalTransparencyModifier = 0
			end
		end

		if v:IsA("Accessory") then
			if not (v.Handle:FindFirstChild("AccessoryWeld").Part1 == character.Head) then
				v.Handle.LocalTransparencyModifier = 0
			else
				if humanoid.Parent:GetAttribute("Downed") == true then
					v.Handle.LocalTransparencyModifier = 0
				end
			end
		end
	end

	local flashlight = character:FindFirstChild("Flashlight")
	if flashlight then
		for _, plart in flashlight:GetDescendants() do
			if plart:IsA("BasePart") then
				plart.LocalTransparencyModifier = 0
			end
		end
	end
end

return cameraController
