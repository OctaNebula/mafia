local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local Packages = ReplicatedStorage.sharedPackages
local shared = ReplicatedStorage.shared

local serviceUtil = require(shared.utilities.serviceUtil)
local spectatingService = serviceUtil.service("spectatingService")

-- local ReactRoblox = require(Packages.ReactRoblox)
local ReactSpring = require(Packages.ReactSpring)
local React = require(Packages.React)

local e = React.createElement

local function Spectate()
    local spectatableTargets, setSpectatableTargets = React.useState({})
	local spectatingIndex, setSpectatingIndex = React.useState(1)
    local spectatedName, setSpectatedName = React.useState(nil)
	local visible, setVisible = React.useState(false)

    local rightButtonToggled, setRightButtonToggled = React.useState(false)
    local leftButtonToggled, setLeftButtonToggled = React.useState(false)

    local function getCharacter(userId)
        if not userId then
            return
        end
        local player = Players:GetPlayerByUserId(userId)
        if not player then
            return
        end
        local character = player.Character
        return character
    end

    local function setCameraToCharacter(character)
        if not character then
            return
        end
        local currentCamera = workspace.CurrentCamera

        currentCamera.CameraType = Enum.CameraType.Custom
        currentCamera.CameraSubject = character

        setSpectatedName(character.Name)
    end

    local updateSpectatingIndex = React.useCallback(function(direction)
        setSpectatingIndex(function(currentIndex)
            if #spectatableTargets == 0 then
                warn("No spectatable targets available")
                setCameraToCharacter(LocalPlayer.Character)
                return currentIndex
            end

            local newIndex = direction == "left" and currentIndex - 1 or currentIndex + 1
            if newIndex < 1 then
                newIndex = #spectatableTargets
            elseif newIndex > #spectatableTargets then
                newIndex = 1
            end

            local startIndex = newIndex
            repeat
                local userId = spectatableTargets[newIndex]
                local character = getCharacter(userId)

                if not userId then
                    warn("No user ID found at index", newIndex)
                elseif not character then
                    warn("No character found for user", userId)
                else
                    print(newIndex)
                    return newIndex
                end

                if direction == "left" then
                    newIndex = newIndex - 1
                    if newIndex < 1 then
                        newIndex = #spectatableTargets
                    end
                else
                    newIndex = newIndex + 1
                    if newIndex > #spectatableTargets then
                        newIndex = 1
                    end
                end
            until newIndex == startIndex

            warn("No valid characters found in spectatable targets")
            setCameraToCharacter(LocalPlayer.Character)
            return currentIndex
        end)
    end, {spectatableTargets})

    local function indexLeft()
        updateSpectatingIndex("left")
    end

    local function indexRight()
        updateSpectatingIndex("right")
    end

	React.useEffect(function()
        local connection = spectatingService.spectatableTargets:observe(function(newTargets)
            if not newTargets then
                setVisible(false)
                return
            end

            if spectatingIndex > #newTargets then
                setSpectatingIndex(#newTargets)
            end

            setSpectatableTargets(newTargets)
            setVisible(true)
        end)

        return function()
            connection:Disconnect()
        end
    end, {spectatingIndex})

    React.useEffect(function()
        local character = getCharacter(spectatableTargets[spectatingIndex])
        if not character then
            setCameraToCharacter(LocalPlayer.Character)
            return
        end

        setCameraToCharacter(character)
    end, {spectatableTargets, spectatingIndex})

    React.useEffect(function()
        local UserInputService = game:GetService("UserInputService")

        local connectionInputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or not visible then
                return
            end

            if input.KeyCode == Enum.KeyCode.Q then
                setLeftButtonToggled(true)
            elseif input.KeyCode == Enum.KeyCode.E then
                setRightButtonToggled(true)
            end
        end)

        local connectionInputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessed)
            if gameProcessed or not visible then
                return
            end

            if input.KeyCode == Enum.KeyCode.Q then
                setLeftButtonToggled(false)
                indexLeft()
            elseif input.KeyCode == Enum.KeyCode.E then
                setRightButtonToggled(false)
                indexRight()
            end
        end)

        return function()
            connectionInputBegan:Disconnect()
            connectionInputEnded:Disconnect()
        end
    end, {visible})

	local imageLabelStyle = ReactSpring.useSpring({
		position = UDim2.fromScale(0.5, if visible then 0.985 else 1.27)
	})

	return e("ImageLabel", {
		Image = "rbxassetid://16736240292",
		ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = imageLabelStyle.position,
		Size = UDim2.fromScale(0.332, 0.211),
	}, {
		label = e("ImageLabel", {
			Image = "rbxassetid://16736250750",
			ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, -0.221),
			Size = UDim2.fromScale(1, 0.32),
		}, {
			textLabel = e("TextLabel", {
				FontFace = Font.new(
					"rbxassetid://12187376739",
					Enum.FontWeight.SemiBold,
					Enum.FontStyle.Normal
				),
				Text = "SPECTATING",
				TextColor3 = Color3.fromRGB(235, 235, 235),
				TextScaled = true,
				TextSize = 36,
				TextWrapped = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.362),
				Size = UDim2.fromScale(1.01, 0.83),
			}, {
				uiAspectRatioConstraint = e("UIAspectRatioConstraint", {
					AspectRatio = 11.6,
				}),
			}),

			uiAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 9.59,
			}),
		}),

		left = e("ImageButton", {
			Image = "rbxassetid://16736261609",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = if leftButtonToggled then Color3.fromRGB(255, 255, 125) else Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(if leftButtonToggled then -0.078 else -0.068, 0.388),
			Size = UDim2.fromScale(0.108, 0.578),

			[React.Event.Activated] = function()
                indexLeft()
                setLeftButtonToggled(true)
                task.wait(0.05)
                setLeftButtonToggled(false)
            end
		}, {
			uiAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 0.575,
			}),

			textLabel = e("TextLabel", {
				FontFace = Font.new(
					"rbxassetid://12187376739",
					Enum.FontWeight.Heavy,
					Enum.FontStyle.Normal
				),
				Text = "Q",
				TextColor3 = Color3.fromRGB(235, 235, 235),
				TextScaled = true,
				TextSize = 36,
				TextWrapped = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.381),
				Size = UDim2.fromScale(0.619, 0.391),
			}),
		}),

		right = e("ImageButton", {
			Image = "rbxassetid://16736264920",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = if rightButtonToggled then Color3.fromRGB(255, 255, 125) else Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(if rightButtonToggled then 1.09 else 1.08, 0.388),
			Size = UDim2.fromScale(0.108, 0.578),

			[React.Event.Activated] = function()
                indexRight()
                setRightButtonToggled(true)
                task.wait(0.05)
                setRightButtonToggled(false)
            end
		}, {
			uiAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 0.575,
			}),

			textLabel = e("TextLabel", {
				FontFace = Font.new(
					"rbxassetid://12187376739",
					Enum.FontWeight.Heavy,
					Enum.FontStyle.Normal
				),
				Text = "E",
				TextColor3 = Color3.fromRGB(235, 235, 235),
				TextScaled = true,
				TextSize = 36,
				TextWrapped = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.381),
				Size = UDim2.fromScale(0.619, 0.391),
			}),
		}),

		returnButton = e("ImageButton", {
			Image = "rbxassetid://16736268547",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.544),
			Size = UDim2.fromScale(0.442, 0.272),
			Visible = false, -- disabled since i dont actually know what this does
		}, {
			uiAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 4.99,
			}),

			textLabel = e("TextLabel", {
				FontFace = Font.new(
					"rbxassetid://12187376739",
					Enum.FontWeight.Heavy,
					Enum.FontStyle.Normal
				),
				Text = "RETURN",
				TextColor3 = Color3.fromRGB(235, 235, 235),
				TextScaled = true,
				TextSize = 36,
				TextWrapped = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.475),
				Size = UDim2.fromScale(0.619, 0.773),
			}),
		}),

		playerName = e("TextLabel", {
			FontFace = Font.new(
				"rbxassetid://12187376739",
				Enum.FontWeight.Heavy,
				Enum.FontStyle.Normal
			),
			Text = spectatedName,
			TextColor3 = Color3.fromRGB(235, 235, 235),
			TextScaled = true,
			TextSize = 36,
			TextWrapped = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.495, 0.227),
			Size = UDim2.fromScale(1.01, 0.265),
		}, {
			uiAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 11.6,
			}),
		}),

		uiAspectRatioConstraint = e("UIAspectRatioConstraint", {
			AspectRatio = 3.07,
		}),
	})
end

return Spectate