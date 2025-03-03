local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

return function(character, target)
    -- local att = Instance.new("Attachment")
    -- character.Gun.Beam.Attachment0 = character.Gun.Attachment
    -- character.Gun.Beam.Attachment1 = att
    -- att.Parent = target.Head

    local gunShot = SoundService["gunshot"..math.random(1, 3)]:Clone()
    gunShot.Parent = character.HumanoidRootPart
    gunShot:Play()
    Debris:AddItem(gunShot, gunShot.TimeLength)
    task.spawn(function()
        Lighting.GunFlare.Enabled = true
        task.wait()
        Lighting.GunFlare.Enabled = false
    end)
    -- character.Gun.Attachment.PointLight.Enabled = true
    -- task.wait(0.05)
    -- character.Gun.Attachment.PointLight.Enabled = false
    -- task.wait(0.05)
    -- character.Gun.Beam.Attachment1 = nil
end