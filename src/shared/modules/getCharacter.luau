function getCharacter(basePart: BasePart)
    if not basePart or not basePart.Parent or not basePart.Parent.Parent then
        return
    end
	local humanoid = basePart.Parent:FindFirstChildWhichIsA("Humanoid")
		or basePart.Parent.Parent:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end
	return humanoid.Parent
end

return getCharacter