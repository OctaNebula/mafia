local animationOffsets = {
    closet = function(closet, character, character2)
        if not character then
            return
        end
        local characterCFrame = closet:GetPivot() *
            CFrame.new(-2.9883413314819336, -1.5126371383666992, 0.1451425552368164) *
            CFrame.Angles(0, math.rad(-90), 0)
        character:PivotTo(characterCFrame)
        if not character2 then
            return
        end
        local character2CFrame = closet:GetPivot() *
            CFrame.new(-0.12230587005615234, -1.512622356414795, 0.05348968505859375) *
            CFrame.Angles(0, math.rad(-90), 0)
        character2:PivotTo(character2CFrame)
    end,
}

return animationOffsets