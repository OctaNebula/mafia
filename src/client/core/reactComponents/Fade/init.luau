local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.sharedPackages

-- local ReactRoblox = require(Packages.ReactRoblox)
local ReactSpring = require(Packages.ReactSpring)
local React = require(Packages.React)

local e = React.createElement

local function Fade(props)
    local transparency = props.transparency or 1
    local duration = props.duration or nil
    local easing = props.easing or nil

    local frameStyle = ReactSpring.useSpring({
        backgroundTransparency = transparency,
        config = if duration == nil or easing == nil then nil else {
            duration = duration,
            easing = easing
        }
    })

    return e("Frame", {
        AnchorPoint = Vector2.new(0, 0),
        BackgroundTransparency = frameStyle.backgroundTransparency,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0, 0),
        Size = UDim2.fromScale(1, 1),
    })
end

return Fade