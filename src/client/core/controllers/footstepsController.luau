local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local configs = ReplicatedStorage.client.configs
local footstepSounds = require(configs.footstepSounds)

local footstepSoundGroup

local footstepsController = {}

function footstepsController.start()
	footstepSoundGroup = footstepsController.createSoundGroup()

	local localPlayer = Players.LocalPlayer
	localPlayer.CharacterAdded:Connect(footstepsController.characterAdded)
end

function footstepsController.createSoundGroup()
	local soundGroup = Instance.new("SoundGroup")
	for materialName, soundId in footstepSounds do
		local materialSound = Instance.new("Sound")
		materialSound.Name = materialName
		materialSound.SoundId = soundId
		materialSound.Parent = soundGroup
	end
	soundGroup.Parent = SoundService

	return soundGroup
end

function footstepsController.getHumanoidMaterial(humanoid)
	local floormat = humanoid.FloorMaterial
	if not floormat then
		floormat = "Air"
	end
	local matstring = string.split(tostring(floormat), "Enum.Material.")[2]
	local material = matstring
	return material
end

function footstepsController.characterAdded(character)
	local humanoid = character.Humanoid
	local walking

	humanoid.Running:Connect(function(speed)
		if speed > humanoid.WalkSpeed / 2 then
			walking = true
		else
			walking = false
		end
	end)

	local lastMaterial
	RunService.Heartbeat:Connect(function()
		if character:GetAttribute("Downed") ~= true then -- might not use attributes in future
			if walking then
				local material = footstepsController.getHumanoidMaterial(humanoid)
				if material ~= lastMaterial and lastMaterial ~= nil then
					footstepSoundGroup[lastMaterial].Playing = false
				end
				local materialSound = footstepSoundGroup[material]
				materialSound.PlaybackSpeed = humanoid.WalkSpeed / 12
				materialSound.Playing = true
				lastMaterial = material
			else
				for _, sound in footstepSoundGroup:GetChildren() do
					sound.Playing = false
				end
			end
		end
	end)
end

return footstepsController
