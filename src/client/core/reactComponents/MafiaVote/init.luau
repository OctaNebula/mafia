local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local mouse = LocalPlayer:GetMouse()

local voteHighlight = ReplicatedStorage.assets.voteHighlight

local Packages = ReplicatedStorage.sharedPackages

local shared = ReplicatedStorage.shared

local controllers = ReplicatedStorage.client.controllers
local armController = require(controllers.armController)

local getCharacter = require(shared.modules.getCharacter)

local serviceUtil = require(shared.utilities.serviceUtil)
local gameService = serviceUtil.service("gameService")

-- local ReactRoblox = require(Packages.ReactRoblox)
local ReactSpring = require(Packages.ReactSpring)
local React = require(Packages.React)

local e = React.createElement

local function MafiaVote()
	local canVote, setCanVote = React.useState(false)
	local voteConfirmed, setVoteConfirmed = React.useState(false)
	local target, setTarget = React.useState(nil)

	local style = ReactSpring.useSpring({
		position = UDim2.fromScale(0.503, if target and not voteConfirmed then 0.875 else 1.17)
	})

	React.useEffect(function()
		local connection = gameService.canVote:observe(function(newCanVote)
			setCanVote(newCanVote)
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	React.useEffect(function()
		if not canVote then
            setVoteConfirmed(false)
            setTarget(nil)
            -- reseting variables and armController, might need to reset differently so as to not conflict with a different controller
            armController.setIsPointing:Fire("MafiaVote", false)
            armController.setPointingTarget:Fire(nil)
			return
		end

		armController.setIsPointing:Fire("MafiaVote", true)

        if voteConfirmed then
            return
        end

		local function votePlayer(part: BasePart)
			if not part then
				return
			end
			local character = getCharacter(part)
			if not character then
				return
			end
			local player = Players:GetPlayerFromCharacter(character)

			armController.setPointingTarget:Fire(mouse.Hit.Position)
			setTarget(player)
			print("Vote confirmation displayed for "..player.Name)
		end
		local mouseConnection = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
			if not gameProcessedEvent and input.UserInputType == Enum.UserInputType.MouseButton1 and not target then
				votePlayer(mouse.Target)
			end
		end)
		local tapConnection = UserInputService.TouchTapInWorld:Connect(function(touchPosition, gameProcessedEvent)
			if not gameProcessedEvent and not target then
				local mouseRay = workspace.CurrentCamera:ScreenPointToRay(touchPosition.X, touchPosition.Y)

				local raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000)
				votePlayer(raycastResult.Instance)
			end
		end)
		return function()
			mouseConnection:Disconnect()
			tapConnection:Disconnect()
		end
	end, {canVote, target, voteConfirmed})

	React.useEffect(function()
		local connection
		local highlight = voteHighlight:Clone()
		if target then
			highlight.Parent = target.Character
		elseif canVote then
			connection = RunService.RenderStepped:Connect(function()
				local character = getCharacter(mouse.Target)
				if character then
					highlight.Parent = character
				else
					highlight.Parent = nil
				end
			end)
		end
		return function()
			if connection then
				connection:Disconnect()
			end
			highlight:Destroy()
		end
	end, {canVote, target, mouse.Target})

	local function confirmVote()
		if not target or voteConfirmed then
			return
		end
		armController.setIsPointing:Fire("MafiaVote", true) -- redundancy
        setVoteConfirmed(true)
        -- note that it should prevent voting for a new player, so it should visually reflect that
        gameService.votePlayer:fireServer(target)
		print("Vote confirmed for "..target.Name)
	end

	local function cancelVote()
		if not target or voteConfirmed then
			return
		end
		armController.setIsPointing:Fire("MafiaVote", false)
		armController.setPointingTarget:Fire(nil)
		print("Vote cancelled for "..target.Name)
		setTarget(nil)
	end

	return e("ImageLabel", {
		Image = "rbxassetid://16726808279",
		ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = style.position,
		Size = UDim2.fromScale(0.331, 0.156),
	}, {
		no = e("ImageButton", {
			Image = "rbxassetid://16726827844",
			ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.731, 0.557),
			Size = UDim2.fromScale(0.402, 0.243),

			[React.Event.Activated] = cancelVote
		}, {
			textLabel = e("TextLabel", {
				FontFace = Font.new(
					"rbxassetid://12187376739",
					Enum.FontWeight.SemiBold,
					Enum.FontStyle.Normal
				),
				Text = "No",
				TextColor3 = Color3.fromRGB(235, 235, 235),
				TextScaled = true,
				TextSize = 29,
				TextWrapped = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.445),
				Size = UDim2.fromScale(1, 1.08),
			}, {
				uiAspectRatioConstraint = e("UIAspectRatioConstraint", {
					AspectRatio = 4.6,
				}),
			}),

			uiAspectRatioConstraint1 = e("UIAspectRatioConstraint", {
				AspectRatio = 4.98,
			}),
		}),

		yes = e("ImageButton", {
			Image = "rbxassetid://16726823958",
			ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.268, 0.557),
			Size = UDim2.fromScale(0.402, 0.243),

			[React.Event.Activated] = confirmVote
		}, {
			textLabel1 = e("TextLabel", {
				FontFace = Font.new(
					"rbxassetid://12187376739",
					Enum.FontWeight.SemiBold,
					Enum.FontStyle.Normal
				),
				Text = "Yes",
				TextColor3 = Color3.fromRGB(235, 235, 235),
				TextScaled = true,
				TextSize = 29,
				TextWrapped = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.445),
				Size = UDim2.fromScale(1, 1.08),
			}, {
				uiAspectRatioConstraint2 = e("UIAspectRatioConstraint", {
					AspectRatio = 4.6,
				}),
			}),

			uiAspectRatioConstraint3 = e("UIAspectRatioConstraint", {
				AspectRatio = 4.98,
			}),
		}),

		playerName = e("TextLabel", {
			FontFace = Font.new(
				"rbxassetid://12187376739",
				Enum.FontWeight.Heavy,
				Enum.FontStyle.Normal
			),
			Text = "PLAYER",
			TextColor3 = Color3.fromRGB(235, 235, 235),
			TextScaled = true,
			TextSize = 36,
			TextWrapped = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.128),
			Size = UDim2.fromScale(1, 0.257),
		}, {
			uiAspectRatioConstraint4 = e("UIAspectRatioConstraint", {
				AspectRatio = 11.7,
			}),
		}),

		textLabel2 = e("TextLabel", {
			FontFace = Font.new(
				"rbxassetid://12187376739",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
			Text = "IS THE MAFIA?",
			TextColor3 = Color3.fromRGB(235, 235, 235),
			TextScaled = true,
			TextSize = 27,
			TextWrapped = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.345),
			Size = UDim2.fromScale(1, 0.176),
		}, {
			uiAspectRatioConstraint5 = e("UIAspectRatioConstraint", {
				AspectRatio = 17.2,
			}),
		}),

		imageLabel = e("ImageLabel", {
			Image = "rbxassetid://16726814425",
			ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.498, -0.208),
			Size = UDim2.fromScale(1, 0.321),
		}, {
			textLabel3 = e("TextLabel", {
				FontFace = Font.new(
					"rbxassetid://12187376739",
					Enum.FontWeight.SemiBold,
					Enum.FontStyle.Normal
				),
				Text = "DO YOU THINK",
				TextColor3 = Color3.fromRGB(235, 235, 235),
				TextScaled = true,
				TextSize = 36,
				TextWrapped = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.502, 0.412),
				Size = UDim2.fromScale(1, 0.83),
			}, {
				uiAspectRatioConstraint6 = e("UIAspectRatioConstraint", {
					AspectRatio = 11.4,
				}),
			}),

			uiAspectRatioConstraint7 = e("UIAspectRatioConstraint", {
				AspectRatio = 9.43,
			}),
		}),

		uiAspectRatioConstraint8 = e("UIAspectRatioConstraint", {
			AspectRatio = 2.99,
			AspectType = Enum.AspectType.ScaleWithParentSize,
		}),

		vigil = e("ImageButton", {
			Image = "rbxassetid://135195273919100",
			Active = false,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.628, 0.797),
			Selectable = false,
			Size = UDim2.fromScale(0.0563, 0.174),
			Visible = false,
		}, {
			imageLabel1 = e("ImageLabel", {
				Image = "rbxassetid://104015655720076",
				ImageTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.118, 0.109),
				Size = UDim2.fromScale(0.758, 0.758),
			}),

			textLabel4 = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/JosefinSans.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "Target this player?",
				TextColor3 = Color3.fromRGB(209, 209, 209),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Right,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(-5.71, 0),
				Size = UDim2.fromScale(5.49, 1),
			}),
		}),
	})
end

return MafiaVote