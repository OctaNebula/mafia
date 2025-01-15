local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.sharedPackages

-- local ReactRoblox = require(Packages.ReactRoblox)
-- local ReactSpring = require(Packages.ReactSpring)
local React = require(Packages.React)

local e = React.createElement

local function AlphaWarning()
	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.501, 0.501),
		Size = UDim2.fromScale(0.999, 0.998),
	}, {
		textLabel = e("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/JosefinSans.json"),
			Text = "This game is in pre-alpha stage, expect things to break!",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 31,
			TextTransparency = 0.68,
			TextWrapped = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.367, 0.954),
			Size = UDim2.fromScale(0.277, 0.0353),
		}, {
			uITextSizeConstraint = e("UITextSizeConstraint", {
				MaxTextSize = 31,
			}),
		}),

		uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
			AspectRatio = 1.78,
		}),
	})
end

return AlphaWarning