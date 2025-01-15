local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Packages = ReplicatedStorage.sharedPackages

local serviceUtil = require(ReplicatedStorage.shared.utilities.serviceUtil)
local gameService = serviceUtil.service("gameService")

local controllers = ReplicatedStorage.client.controllers
local lightingController = require(controllers.lightingController)

-- local ReactRoblox = require(Packages.ReactRoblox)
local ReactSpring = require(Packages.ReactSpring)
local React = require(Packages.React)

local e = React.createElement

local function Death()
    -- local isDead, setIsDead = React.useState(false)
    local imageStyle, imageApi = ReactSpring.useSpring(function()
        return {
            imageTransparency = 1,
            config = {
                duration = 3,
                easing = ReactSpring.easings.easeOutQuad
            }
        }
    end)
    local gradientStyle, gradientApi = ReactSpring.useSpring(function()
        return {
            rotation = 0,
            config = {
                duration = 2,
                easing = ReactSpring.easings.easeOutQuad
            }
        }
    end)
    local frameStyle, frameApi = ReactSpring.useSpring(function()
        return {
            backgroundTransparency = 1,
            config = {
                duration = 2,
                easing = ReactSpring.easings.easeOutQuad
            }
        }
    end)
    local textLabelStyle, textLabelApi = ReactSpring.useSpring(function()
        return {
            textTransparency = 1,
            config = {
                duration = 1.5,
                easing = ReactSpring.easings.easeOutQuad
            }
        }
    end)
    local function playDeathCutscene()
		SoundService["death"..math.random(1,2)]:Play()
        lightingController.animateDeathGreyscale(true)
        imageApi.start({ imageTransparency = 0.26 })
        frameApi.start({ backgroundTransparency = 0.4 })
        gradientApi.start({ rotation = 180 })
        task.wait(1.5)
        textLabelApi.start({ textTransparency = 0 })
        task.wait(5)
        lightingController.animateDeathGreyscale(false)
        imageApi.start({ imageTransparency = 1 })
        frameApi.start({ backgroundTransparency = 1 })
        gradientApi.start({ rotation = 0 })
        task.wait(1.5)
        textLabelApi.start({ textTransparency = 1 })
    end

    React.useEffect(function()
        gameService.playerDied:connect(playDeathCutscene)
    end, {})

    return e("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
      }, {
        frame = e("Frame", {
          AnchorPoint = Vector2.new(0.5, 0.5),
          BackgroundColor3 = Color3.fromRGB(0, 0, 0),
          BackgroundTransparency = frameStyle.backgroundTransparency,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.fromScale(0.5, 0.499),
          Size = UDim2.fromScale(1, 0.119),
        }, {
          textLabel = e("TextLabel", {
            FontFace = Font.new(
              "rbxassetid://12187376739",
              Enum.FontWeight.Bold,
              Enum.FontStyle.Normal
            ),
            Text = "YOU DIED.",
            TextColor3 = Color3.fromRGB(170, 80, 82),
            TextScaled = true,
            TextSize = 80,
            TextStrokeColor3 = Color3.fromRGB(9, 9, 9),
            TextTransparency = textLabelStyle.textTransparency,
            TextWrapped = true,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Position = UDim2.fromScale(0.499, 0.446),
            Size = UDim2.fromOffset(646, 83),
          }),
      
          uiGradient = e("UIGradient", {
            Transparency = NumberSequence.new({
              NumberSequenceKeypoint.new(0, 1),
              NumberSequenceKeypoint.new(0.0698, 0.306),
              NumberSequenceKeypoint.new(0.158, 0),
              NumberSequenceKeypoint.new(0.85, 0),
              NumberSequenceKeypoint.new(0.909, 0.287),
              NumberSequenceKeypoint.new(1, 1),
            }),

            Rotation = gradientStyle.rotation,
          }),
        }),
      
        imageLabel = e("ImageLabel", {
          Image = "rbxassetid://17438344339",
          ImageTransparency = imageStyle.imageTransparency,
          AnchorPoint = Vector2.new(0.5, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 1,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.fromScale(0.5, 0.5),
          Size = UDim2.fromScale(1.25, 1.25),
        }),
      })
end

return Death