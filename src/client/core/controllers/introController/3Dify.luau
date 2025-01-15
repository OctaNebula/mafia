local threedify = {}

function lerp(a, b, l)
	return a + (b - a) * l
end

function threedify.Make3D(v)
	local model = Instance.new("Model")
	model.Name = v.Name

	v.Parent = model
	for i = 1, v:GetAttribute("depth"), 1 do
		local part = v:Clone()
		part.Name = v.Name .. "Depth"
		part.Parent = model
		local range = v:GetAttribute("range")
		part.CFrame = v.CFrame * CFrame.new(0, 0, range*i)
		part.SurfaceGui.ZOffset = v:GetAttribute("depth")+1-i
		if v:GetAttribute("colortoblack") then
			local basecolor = part.SurfaceGui.TextLabel.TextColor3
			local lerpval = i/v:GetAttribute("depth")

			part.SurfaceGui.TextLabel.TextColor3 = Color3.new(lerp(basecolor.R, 0, lerpval), lerp(basecolor.G, 0, lerpval), lerp(basecolor.B, 0, lerpval))
		end
	end
	
	return model
end

return threedify
