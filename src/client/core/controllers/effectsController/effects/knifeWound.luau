local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

return function(character, target)
    local knifeSound = SoundService["knifeHit"..math.random(1, 2)]:Clone()
    knifeSound.Parent = character.HumanoidRootPart
    knifeSound:Play()
    Debris:AddItem(knifeSound, knifeSound.TimeLength)
end