local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Packages = ReplicatedStorage.sharedPackages

-- local ReactRoblox = require(Packages.ReactRoblox)
local ReactSpring = require(Packages.ReactSpring)
local React = require(Packages.React)

local e = React.createElement

local useTypewriter = require(ReplicatedStorage.client.reactHooks.useTypewriter)

local function Topbar(props)
    local initialText = props.initialText or ""
    local targetText = props.targetText or ""
    local typewriterDelay = props.typerwriterDelay or 0.025

    local currentText = useTypewriter(initialText, targetText, typewriterDelay, function()
        if typewriterDelay > 0 then
            SoundService.typewriter:Play()
        end
    end)

    local gradientStyle = ReactSpring.useSpring({
        offset = if targetText == "" then Vector2.new(0, -1) else Vector2.new(0, 1)
    })

    return e("ImageLabel", {
        Image = "rbxassetid://16657592580",
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0),
        Size = UDim2.fromScale(1, 0.04),
    }, {
        uiGradient = e("UIGradient", {
            Offset = gradientStyle.offset,
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }),
        }),

        label = e("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/JosefinSans.json"),
            Text = currentText,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            TextSize = 14,
            TextWrapped = true,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Position = UDim2.fromScale(0, 0.277),
            Size = UDim2.fromScale(1, 0.479),
        }),
    })
end

return Topbar