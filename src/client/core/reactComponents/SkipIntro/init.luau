local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.sharedPackages

local shared = ReplicatedStorage.shared

local serviceUtil = require(shared.utilities.serviceUtil)
local gameService = serviceUtil.service("gameService")

-- local ReactRoblox = require(Packages.ReactRoblox)
local ReactSpring = require(Packages.ReactSpring)
local React = require(Packages.React)

local e = React.createElement

local function SkipIntro(props)
    local visible = props.visible or false
    local playerCounterText, setPlayerCounterText = React.useBinding("")

    local style = ReactSpring.useSpring({
        position = if visible then UDim2.fromScale(1, 0.999) else UDim2.fromScale(1, 1.094),
    })

    React.useEffect(function()
        gameService.introSkippedInfo:observe(function(newInfo)
            setPlayerCounterText(`{newInfo.playersSkippedIntro}/{newInfo.participatingPlayers}`)
        end)
    end, {})

    return e("ImageLabel", {
        Image = "rbxassetid://16698532434",
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = style.position,
        Size = UDim2.fromScale(0.196, 0.0933),
      }, {
        base = e("ImageLabel", {
          Image = "rbxassetid://16698709498",
          ScaleType = Enum.ScaleType.Fit,
          AnchorPoint = Vector2.new(0.5, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 1,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.fromScale(0.426, 0.657),
          Size = UDim2.fromScale(0.193, 0.484),
          ZIndex = 5,
        }, {
          uiAspectRatioConstraint = e("UIAspectRatioConstraint", {
            AspectRatio = 1.49,
          }),
        }),
      
        imageButton = e("ImageButton", {
          Image = "rbxassetid://16698559848",
          AnchorPoint = Vector2.new(0.5, 0.1),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 1,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.fromScale(0.715, 0.467),
          Size = UDim2.fromScale(0.49, 0.476),

          [React.Event.Activated] = function()
            if gameService.introSkipped:get() ~= true then
                gameService.skipIntro:fireServer()
            end
          end
        }, {
          uiAspectRatioConstraint1 = e("UIAspectRatioConstraint", {
            AspectRatio = 3.85,
          }),
      
          textLabel = e("TextLabel", {
            FontFace = Font.new(
              "rbxassetid://12187376739",
              Enum.FontWeight.Bold,
              Enum.FontStyle.Normal
            ),
            Text = playerCounterText,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextScaled = true,
            TextSize = 45,
            TextWrapped = true,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Position = UDim2.fromScale(0.3, 0.0417),
            Size = UDim2.fromScale(0.509, 0.811),
          }, {
            uiTextSizeConstraint = e("UITextSizeConstraint", {
              MaxTextSize = 45,
            }),
          }),
        }),
      
        uiAspectRatioConstraint2 = e("UIAspectRatioConstraint", {
          AspectRatio = 3.74,
          DominantAxis = Enum.DominantAxis.Height,
        }),
      
        base1 = e("ImageLabel", {
          Image = "rbxassetid://16569263935",
          ImageColor3 = Color3.fromRGB(34, 28, 25),
          ImageTransparency = 0.1,
          AnchorPoint = Vector2.new(0.5, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 1,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.fromScale(1.08, 0.666),
          Rotation = 180,
          Size = UDim2.fromScale(0.166, 0.929),
        }),
      
        base2 = e("ImageLabel", {
          Image = "rbxassetid://16569263935",
          ImageColor3 = Color3.fromRGB(89, 59, 43),
          ImageTransparency = 0.24,
          AnchorPoint = Vector2.new(0.5, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 1,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.fromScale(1.09, 0.0809),
          Rotation = 180,
          Size = UDim2.fromScale(0.185, 0.184),
        }),
      
        arrow1 = e("ImageLabel", {
          Image = "rbxassetid://16698668802",
          ScaleType = Enum.ScaleType.Fit,
          AnchorPoint = Vector2.new(0.5, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 1,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.fromScale(0.876, 0.669),
          Size = UDim2.fromScale(0.058, 0.328),
        }, {
          uiAspectRatioConstraint3 = e("UIAspectRatioConstraint", {
            AspectRatio = 0.661,
          }),
        }),
      
        arrow2 = e("ImageLabel", {
          Image = "rbxassetid://16698668802",
          ScaleType = Enum.ScaleType.Fit,
          AnchorPoint = Vector2.new(0.5, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 1,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.fromScale(0.931, 0.669),
          Size = UDim2.fromScale(0.0577, 0.328),
        }, {
          uiAspectRatioConstraint4 = e("UIAspectRatioConstraint", {
            AspectRatio = 0.658,
          }),
        }),
      
        base3 = e("ImageLabel", {
          Image = "rbxassetid://16569263935",
          ImageColor3 = Color3.fromRGB(34, 28, 25),
          ImageTransparency = 0.1,
          AnchorPoint = Vector2.new(0.5, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 1,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.fromScale(0.51, 1.98),
          Rotation = 180,
          Size = UDim2.fromScale(1.03, 1.97),
        }),
      })
end

return SkipIntro