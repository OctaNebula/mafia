local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local sharedPackages = ReplicatedStorage.sharedPackages

local network = require(sharedPackages.network)
local Signal = require(sharedPackages.Signal)

--[[
local SOCKET_SETTINGS_R15 = {
	head = {MaxFrictionTorque = 150, UpperAngle = 15, TwistLowerAngle = -15, TwistUpperAngle = 15},
	upperTorso = {MaxFrictionTorque = 50, UpperAngle = 20, TwistLowerAngle = -10, TwistUpperAngle = 30},
	lowerTorso = {MaxFrictionTorque = 50, UpperAngle = 20, TwistLowerAngle = 0, TwistUpperAngle = 30},
	upperArms = {MaxFrictionTorque = 150, UpperAngle = 90, TwistLowerAngle = -45, TwistUpperAngle = 45},
	lowerArms = {MaxFrictionTorque = 150, UpperAngle = 0, TwistLowerAngle = -5, TwistUpperAngle = 65},
	upperLegs = {MaxFrictionTorque = 150, UpperAngle = 40, TwistLowerAngle = -5, TwistUpperAngle = 20},
	lowerLegs = {MaxFrictionTorque = 150, UpperAngle = 0, TwistLowerAngle = -45, TwistUpperAngle = 10},
	handsFeets = {MaxFrictionTorque = 50, UpperAngle = 10, TwistLowerAngle = -45, TwistUpperAngle = 25},
}
]]

local SOCKET_SETTINGS_R15 = {
	head = {MaxFrictionTorque = 50, UpperAngle = 15, TwistLowerAngle = -15, TwistUpperAngle = 15},
	upperTorso = {MaxFrictionTorque = 50, UpperAngle = 20, TwistLowerAngle = -10, TwistUpperAngle = 30},
	lowerTorso = {MaxFrictionTorque = 50, UpperAngle = 20, TwistLowerAngle = 0, TwistUpperAngle = 30},
	upperArms = {MaxFrictionTorque = 50, UpperAngle = 15, TwistLowerAngle = -45, TwistUpperAngle = 45},
	lowerArms = {MaxFrictionTorque = 50, UpperAngle = 0, TwistLowerAngle = -5, TwistUpperAngle = 30},
	upperLegs = {MaxFrictionTorque = 50, UpperAngle = 40, TwistLowerAngle = -5, TwistUpperAngle = 20},
	lowerLegs = {MaxFrictionTorque = 50, UpperAngle = 0, TwistLowerAngle = -45, TwistUpperAngle = 10},
	handsFeets = {MaxFrictionTorque = 50, UpperAngle = 10, TwistLowerAngle = -45, TwistUpperAngle = 25},
}

local ragdollService = {
    setRagdoll = Signal.new(),
    client = {
        ragdoll = network.Server.RemoteSignal.new(),
        unragdoll = network.Server.RemoteSignal.new()
    }
}

function ragdollService.start()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(ragdollService.characterAdded)
        -- task.spawn(function()
        --     while task.wait(3) do
        --         print("ragdoll!")
        --         ragdollService.ragdollCharacter(player.Character)
        --         task.wait(3)
        --         print("unragdoll!")
        --         ragdollService.unragdollCharacter(player.Character)
        --     end
        -- end)
    end)
    ragdollService.setRagdoll:Connect(function(character, ragdollToggled)
        if ragdollToggled then
            ragdollService.ragdollCharacter(character)
        else
            ragdollService.unragdollCharacter(character)
        end
    end)
    -- task.delay(5, function()
    --     print('balls')
    --     ragdollService.characterAdded(workspace.R15)
    --     while task.wait(1) do
    --         ragdollService.ragdollCharacter(workspace.R15)
    --         task.wait(1)
    --         ragdollService.unragdollCharacter(workspace.R15)
    --     end
    -- end)
end

function ragdollService.characterAdded(character)
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    humanoid.BreakJointsOnDeath = false
    humanoid.RequiresNeck = false
    for _, part in character:GetChildren() do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local collisionPart = part:Clone()
            collisionPart:ClearAllChildren()
            collisionPart.CanCollide = false
            collisionPart.Massless = true
            -- collisionPart.Size = Vector3.one
            collisionPart.Name = "Ragdoll"
            collisionPart.Transparency = 1
            collisionPart.Parent = part

            local weld = Instance.new("Weld")
            weld.Part0 = part
            weld.Part1 = collisionPart
            weld.Parent = collisionPart
        end
    end
    humanoid.Died:Connect(function()
        ragdollService.ragdollCharacter(character)
    end)
end

function ragdollService.toggleRagdollCollisionGroup(character: Model, enabled: boolean)
    for _, descendant in character:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.CollisionGroup = if enabled then "Ragdoll" else "Character"
        end
    end
end

function ragdollService.toggleCollisionParts(character: Model, enabled: boolean)
    for _, part in character:GetChildren() do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = not enabled
            part.Ragdoll.CanCollide = enabled
        end
    end
end

function ragdollService.toggleMotor6D(character: Model, enabled: boolean)
    for _, descendant in character:GetDescendants() do
        if descendant.Name == "Handle" or descendant.Name == "RootJoint" or descendant.Name == "Neck" then
            return
        end
        if descendant:IsA("Motor6D") then
            descendant.Enabled = enabled
        end
        if descendant:IsA("BasePart") then
            descendant.CollisionGroup = if enabled then "Character" else "Ragdoll"
        end
    end
end

local function limbManager(limbName)
	local rigUpperArms = {"RightUpperArm", "LeftUpperArm"}
	local rigLowerArms = {"RightLowerArm", "LeftLowerArm"}
	local rigUpperLegs = {"RightUpperLeg", "LeftUpperLeg"}
	local rigLowerLegs = {"RightLowerLeg", "LeftLowerLeg"}
	local rigHandsFeets = {"RightHand", "LeftHand", "RightFoot", "LeftFoot"}
	if limbName == "Head" then 
		return "head"
	elseif limbName == "UpperTorso" then 
		return "upperTorso"
	elseif limbName == "LowerTorso" then 
		return "lowerTorso"
	elseif table.find(rigUpperArms, limbName) then
		return "upperArms"
	elseif table.find(rigLowerArms, limbName) then
		return "lowerArms"
	elseif table.find(rigUpperLegs, limbName) then
		return "upperLegs"
	elseif table.find(rigLowerLegs, limbName) then
		return "lowerLegs"
	elseif table.find(rigHandsFeets, limbName) then
		return "handsFeets"
	else 
		return nil
	end
end

function ragdollService.buildJoints(character: Model)
    for _, motor6D in character:GetDescendants() do
        if not motor6D:IsA("Motor6D") then
            continue
        end

        local attachment0: Attachment, attachment1: Attachment = Instance.new("Attachment"), Instance.new("Attachment")

        attachment0.Name = "RAGDOLL_ATTACHMENT"
        attachment0.CFrame = motor6D.C0
        attachment0.Parent = motor6D.Part0

        attachment1.Name = "RAGDOLL_ATTACHMENT"
        attachment1.CFrame = motor6D.C1
        attachment1.Parent = motor6D.Part1

        -- local noCollisionConstraint = Instance.new("NoCollisionConstraint")
        -- noCollisionConstraint.Name = "RAGDOLL_NO_COLLISION"
        -- noCollisionConstraint.Part0 = motor6D.Part0
        -- noCollisionConstraint.Part1 = motor6D.Part1
        -- noCollisionConstraint.Parent = motor6D.Parent

        local joint: BallSocketConstraint = Instance.new("BallSocketConstraint")
        joint.Name = "RAGDOLL_CONSTRAINT"
        joint.Attachment0 = attachment0
        joint.Attachment1 = attachment1
        joint.TwistLimitsEnabled = true
        joint.LimitsEnabled = true
        joint.Parent = motor6D

        local limbGroup = limbManager(motor6D.Parent.Name)
        if limbGroup ~= nil then
            local socketSettings = SOCKET_SETTINGS_R15[limbGroup]
            if not socketSettings then
                continue
            end
            for i, v in socketSettings do
                if joint[i] then
                    joint[i] = v
                end
            end
        end
    end
end

function ragdollService.destroyJoints(character: Model)
    for _, descendant in character:GetDescendants() do
        if descendant.Name == "RAGDOLL_ATTACHMENT" or descendant.Name == "RAGDOLL_CONSTRAINT" or descendant.Name == "RAGDOLL_NO_COLLISION" then
            descendant:Destroy()
        end
    end
end

function ragdollService.ragdollCharacter(character: Model)
    if not character or character:GetAttribute("Ragdolled") then
        return
    end
    local player = Players:GetPlayerFromCharacter(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    assert(humanoidRootPart, "Character did not have HumanoidRootPart")
    assert(humanoid, "Character did not have Humanoid")

    ragdollService.toggleRagdollCollisionGroup(character, true)
    ragdollService.toggleCollisionParts(character, true)
    ragdollService.toggleMotor6D(character, false)
    ragdollService.buildJoints(character)

    if player then
        ragdollService.client.ragdoll:fireClient(player)
    else
        humanoidRootPart:SetNetworkOwner(nil)
        humanoid.AutoRotate = false
        humanoid.PlatformStand = true
    end
    character:SetAttribute("Ragdolled", true)
    local handVelocity = math.random(-50, 50)
    character.Head.AssemblyLinearVelocity += character.Head.CFrame.LookVector * 50
    character.RightHand.AssemblyLinearVelocity += character.RightHand.CFrame.LookVector * Vector3.new(0, 100, 50)
    character.LeftHand.AssemblyLinearVelocity += character.LeftHand.CFrame.LookVector * Vector3.new(0, 100, 50)
end

function ragdollService.unragdollCharacter(character: Model)
    if not character or not character:GetAttribute("Ragdolled") then
        return
    end
    local player = Players:GetPlayerFromCharacter(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    assert(humanoidRootPart, "Character did not have HumanoidRootPart")
    assert(humanoid, "Character did not have Humanoid")

    ragdollService.toggleRagdollCollisionGroup(character, false)
    ragdollService.toggleCollisionParts(character, false)
    ragdollService.toggleMotor6D(character, true)
    ragdollService.destroyJoints(character)

    if player then
        ragdollService.client.unragdoll:fireClient(player)
    else
        humanoidRootPart:SetNetworkOwner(nil)
        humanoid.AutoRotate = true
        humanoid.PlatformStand = false
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    character:SetAttribute("Ragdolled", nil)
end

return ragdollService