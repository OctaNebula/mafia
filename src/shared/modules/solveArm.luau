function solveArm(originCFrame, targetPosition) -- do not ask me how this function works, i have 0 clue
    local a = 0.515
    local b = 1.031
    local pi = math.pi
    local halfpi = pi/2
	local localized = originCFrame:pointToObjectSpace(targetPosition)
	local localizedUnit = localized.unit

	local axis = Vector3.new(0,0,-1):Cross(localizedUnit)
	local angle = math.acos(-localizedUnit.Z)
	local plane = originCFrame*CFrame.fromAxisAngle(axis,angle)

	local c = localized.Magnitude

	if c < math.max(a,b)-math.min(a,b) then
		return plane * CFrame.new(0,0,math.max(b,a)-math.min(b,a)-c), -halfpi, pi
	elseif c > a+b then
		return plane * CFrame.new(0,0,a+b-c), halfpi, 0
	else
		local theta1 = -math.acos((-(b * b) + (a * a) + (c * c)) / (2 * a * c))
		local theta2 = math.acos(((b  * b) - (a * a) + (c * c)) / (2 * b * c))
		return plane, theta1 + halfpi, theta2 - theta1
	end
end

return solveArm