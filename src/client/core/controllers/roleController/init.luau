local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local shared = ReplicatedStorage.shared
local serviceUtil = require(shared.utilities.serviceUtil)
local roleService = serviceUtil.service("roleService")

local roles = script.roles

local roleController = {}

function roleController.start()
    local roleModule
	roleService.role:observe(function(newRole)
        -- TODO: disconnect roleModule here
        if not newRole then
            return
        end
        roleModule = roles:FindFirstChild(newRole)
        if not roleModule then
            return
        end
        require(roleModule).start()
    end)
end

return roleController