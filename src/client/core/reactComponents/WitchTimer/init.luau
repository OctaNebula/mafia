local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.sharedPackages

-- local ReactRoblox = require(Packages.ReactRoblox)
local ReactSpring = require(Packages.ReactSpring)
local React = require(Packages.React)

local e = React.createElement

local function WitchTimer(props)
    local timeStarted = props.timeStarted or 0
    local timer = props.timer or 0

    local percentLeft, setPercentLeft = React.useState(0)

    React.useEffect(function()
        setPercentLeft((os.clock()-timeStarted)/timer)
    end, {timeStarted, timer, percentLeft})

    local gradientStyle = ReactSpring.useSpring({
        offset = if timeStarted == 0 then Vector2.new(-0.5) else Vector2.new(-percentLeft + 0.5)
    })
    local frameStyle = ReactSpring.useSpring({
        position = if timeStarted == 0 then UDim2.fromScale(0.5, 1.05) else UDim2.fromScale(0.5, 0.945)
    })

    return e("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = frameStyle.position,
        Size = UDim2.fromScale(0.151, 0.012),
    }, {
        bar = e("ImageLabel", {
            Image = "rbxassetid://98309587182519",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
        }, {
            base = e("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Position = UDim2.fromScale(0.0102, 0),
                Size = UDim2.fromScale(0.98, 0.938),
            }, {
                base1 = e("ImageLabel", {
                    Image = "rbxassetid://137753375943276",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.fromScale(-0.0104, 0.0667),
                    Size = UDim2.fromScale(1.02, 1),
                }, {
                    gradient = e("UIGradient", {
                        Offset = gradientStyle.offset,
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(0.5, 0),
                            NumberSequenceKeypoint.new(0.501, 1),
                            NumberSequenceKeypoint.new(1, 1),
                        }),
                    }),
                }),
            }),
    
            overlay = e("ImageLabel", {
                Image = "rbxassetid://106871874892197",
                ImageTransparency = 0.5,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.fromScale(0.0102, 0.0625),
                Size = UDim2.fromScale(0.98, 0.875),
                ZIndex = 2,
            }),
        }),
    })
end

return WitchTimer