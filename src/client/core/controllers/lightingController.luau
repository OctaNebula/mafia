local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local lightingController = {}

function lightingController.start()

end

function lightingController.animateDeathGreyscale(toggled: boolean)
    if toggled then
        TweenService:Create(Lighting.Grayscale, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Brightness = -0.2,
            Contrast = 0.6,
            Saturation = -0.5
        }):Play()
    else
		TweenService:Create(Lighting.Grayscale, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Brightness = 0,
			Contrast = 0,
			Saturation = 0
		}):Play()
    end
end

return lightingController