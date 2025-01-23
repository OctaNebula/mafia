local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local Packages = ReplicatedStorage.sharedPackages

local ReactSpring = require(Packages.ReactSpring)

local controllers = ReplicatedStorage.client.controllers
local uiController = require(controllers.uiController)

local shared = ReplicatedStorage.shared

local serviceUtil = require(shared.utilities.serviceUtil)
local gameService = serviceUtil.service("gameService")

local configurations = ReplicatedStorage.shared.configurations
local roleDescriptions = require(configurations.roleDescriptions)
local roles = require(configurations.roles)

local ThreeDify = require(script["3Dify"])

local introController = {}

local function lerp(a, b, l)
	return a + (b - a) * l
end

function introController.start()
	gameService.explainRules:connect(function(role)
		introController.explainRulesCutscene(role)
		local introCoro, introCleanUp = introController.mapIntroCutscene(role)

		uiController:setSkipIntroVisible(true)
		
		coroutine.resume(introCoro)

		while coroutine.status(introCoro) ~= "dead" and gameService.introSkipped:get() ~= true do
			task.wait()
		end

		if coroutine.status(introCoro) ~= "dead" then
			coroutine.close(introCoro)
		end

		introCleanUp()

		uiController:setSkipIntroVisible(false)

		gameService.introCompleted:fireServer()

		while gameService.gameStarted:get() == false do
			uiController:setTopbarProps(`Waiting for players...`)
			gameService.gameStarted.onUpdate:Wait()
		end
		uiController:setTopbarProps()

		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom

		uiController:setFadeProps(1, 1, ReactSpring.easings.easeInQuad)
	end)
end

function introController.explainRulesCutscene(role: string)
	if role == "witch" then
		return introController.explainRulesWitch()
	end
    local roleInfo = roles[role]
    if not roleInfo then
        error(`Role ({role}) not found.`)
    end
    local currentCamera = workspace.CurrentCamera
    local scene = workspace:WaitForChild("IntroSequence")
	local cameraPoints = scene:WaitForChild("Cameras")
	local camera1 = cameraPoints:WaitForChild("Camera1")
	local camera2 = cameraPoints:WaitForChild("Camera2")

    local CurveTween = TweenService:Create(currentCamera, TweenInfo.new(11, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = camera1.CFrame})
	local FOVTween = TweenService:Create(currentCamera, TweenInfo.new(10, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {FieldOfView = 55})

	uiController:setFadeProps(0, 1, ReactSpring.easings.easeOutQuad)

	task.wait(1)

	local title = scene["3D"]:WaitForChild("Title"):Clone()
	local titleTextLabel = title.SurfaceGui.TextLabel
	local description = scene["3D"]:WaitForChild("Description"):Clone()
	local descriptionTextLabel = description.SurfaceGui.TextLabel

	titleTextLabel.Text = `YOU ARE THE {string.upper(roleInfo.name)}`
	titleTextLabel.TextColor3 = roleInfo.color
	descriptionTextLabel.Text = roleInfo.description

	title = ThreeDify.Make3D(title)
	description = ThreeDify.Make3D(description)
	
	title.Parent = scene["3D"]
	description.Parent = scene["3D"]

	currentCamera.CameraType = Enum.CameraType.Scriptable
	currentCamera.CFrame = camera2.CFrame
	currentCamera.FieldOfView = 70

	SoundService.rolesSequence:Play()

	uiController:setFadeProps(1, 1, ReactSpring.easings.easeInQuad)
	CurveTween:Play()
	FOVTween:Play()

	task.wait(11)

	uiController:setFadeProps(0, 1, ReactSpring.easings.easeOutQuad)

    task.wait(1)

	title:Destroy()
    description:Destroy()

	currentCamera.FieldOfView = 70
end

function introController.explainRulesWitch()
	--TWEEN
    local currentCamera = workspace.CurrentCamera
    local scene = workspace:WaitForChild("WitchChooser")
	local cameraPoints = scene:WaitForChild("Cameras")
	local camera1 = cameraPoints:WaitForChild("Camera1")
    local mouse = LocalPlayer:GetMouse()

    uiController:setFadeProps(0, 1, ReactSpring.easings.easeOutQuad)

	task.wait(1)

	currentCamera.CameraType = Enum.CameraType.Scriptable
	currentCamera.CFrame = camera1.CFrame
	currentCamera.FieldOfView = 70

    uiController:setFadeProps(1, 1, ReactSpring.easings.easeInQuad)

	uiController:setWitchTimerProps(os.clock(), 11)

	local connection = RunService.RenderStepped:Connect(function()
		workspace.CurrentCamera.CFrame = camera1.CFrame

		local freak = CFrame.new(mouse.UnitRay.Direction.X/250, mouse.UnitRay.Direction.Y/250, mouse.UnitRay.Direction.Z/250) + Vector3.new(camera1.Position.X, camera1.Position.Y, camera1.Position.Z)

		workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.lookAt(camera1.Position, freak.Position), .3)

		local pos = Vector2.new(mouse.x, mouse.y)
		local center = workspace.CurrentCamera.ViewportSize / 2
		local side = (pos - center)

		if side.X < 0 then
			scene.SpotLights.selectSpotInnocent.SpotLight.Brightness = lerp(scene.SpotLights.selectSpotInnocent.SpotLight.Brightness, 10, .2)
			scene.SpotLights.selectSpotMafia.SpotLight.Brightness = lerp(scene.SpotLights.selectSpotMafia.SpotLight.Brightness, 0, .2)
		elseif side.X > 0 then
			scene.SpotLights.selectSpotInnocent.SpotLight.Brightness = lerp(scene.SpotLights.selectSpotInnocent.SpotLight.Brightness, 0, .2)
			scene.SpotLights.selectSpotMafia.SpotLight.Brightness = lerp(scene.SpotLights.selectSpotMafia.SpotLight.Brightness, 10, .2)
		end
	end)

	task.wait(11)

	-- TODO: fireServer so the server knows which side the player has chosen
	connection:Disconnect()

	uiController:setWitchTimerProps()

	uiController:setFadeProps(0, 1, ReactSpring.easings.easeOutQuad)

	currentCamera.FieldOfView = 70

	task.wait(1)
end

function introController.animateCameraPoints(animationTime: number, currentCameraIndex: number, tweenCallback: (Tween) -> ())
	if currentCameraIndex % 2 == 1 then
		local map = workspace:WaitForChild("Map")

		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		workspace.CurrentCamera.CFrame = map.Cameras["Camera"..currentCameraIndex].CFrame
		tweenCallback(TweenService:Create(workspace.CurrentCamera, TweenInfo.new(animationTime*2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {CFrame = map.Cameras["Camera"..currentCameraIndex+1].CFrame}))

		uiController:setFadeProps(1, .5, ReactSpring.easings.easeInQuad)
	end
	task.wait(animationTime-1.5)
	if currentCameraIndex % 2 == 0 then
		uiController:setFadeProps(0, 1.5, ReactSpring.easings.easeOutQuad)
	end
	task.wait(1.5)
end

function introController.mapIntroCutscene(role: string) -- TODO: get disguised/undisguised, as well as number of mafia members 
	local roleDescription = roleDescriptions[role]
	if string.lower(role) == "witch" then
		roleDescription = roleDescription.civilian -- TODO: check if civilian or mafia type of witch
	end
	local explainRulesMusic = SoundService.explainingRules
	explainRulesMusic.Volume = 0

	local tweens = {}

	local function addAndPlayTween(tween: Tween)
		tween:Play()
		table.insert(tweens, tween)
	end

	local function cleanUp()
		uiController:setTopbarProps()

		uiController:setFadeProps(0, 1, ReactSpring.easings.easeOutQuad)
		TweenService:Create(explainRulesMusic, TweenInfo.new(1), {Volume = 0}):Play()
		task.wait(1)
		explainRulesMusic:Stop()
		for _, tween in tweens do
			tween:Cancel()
		end
		tweens = table.clear(tweens)
	end

	local introCoro = coroutine.create(function()explainRulesMusic:Play()
		addAndPlayTween(TweenService:Create(explainRulesMusic, TweenInfo.new(1), {Volume = .5}))

		uiController:setTopbarProps(`Welcome to Mafia. This will be a X (disguised/undisguised) round.`)
		task.wait(4)
		uiController:setTopbarProps(`There are X Mafia(s) among us.`, nil, 0.035)

		for index, descriptionInfo in roleDescription do
			local text = descriptionInfo.text
			local typewriterDelay = descriptionInfo.typewriterDelay
			local delay = descriptionInfo.delay

			introController.animateCameraPoints(delay, index, addAndPlayTween)

			uiController:setTopbarProps(text, nil, typewriterDelay)
			task.wait(typewriterDelay*#text)
		end

		task.wait(4)

		uiController:setTopbarProps(`Good luck.`)
		task.wait(3)
	end)

	return introCoro, cleanUp
end

return introController