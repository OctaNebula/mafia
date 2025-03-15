local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local effectDuration = 0.2

return function(character, target)
    local att = Instance.new("Attachment")
    character.Gun.Beam.Attachment0 = character.Gun.Attachment
    character.Gun.Beam.Attachment1 = att
    att.Parent = target.Head

    local gunShot = SoundService["gunshot"..math.random(1, 3)]:Clone()
    gunShot.Parent = character.HumanoidRootPart
    gunShot:Play()
    Debris:AddItem(gunShot, gunShot.TimeLength)
    task.spawn(function()
        Lighting.GunFlare.Enabled = true
        task.wait(effectDuration)
        Lighting.GunFlare.Enabled = false
    end)
    character.Gun.Attachment.PointLight.Enabled = true
    task.wait(effectDuration/2)
    character.Gun.Attachment.PointLight.Enabled = false
    task.wait(effectDuration/2)
    character.Gun.Beam.Attachment1 = nil
end