local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local shared = ReplicatedStorage.shared
local serviceUtil = require(shared.utilities.serviceUtil)
local roleService = serviceUtil.service("roleService")

local roles = script.roles

local roleController = {}

function roleController.start()
	roleService.role:observe(function(newRole)
        if not newRole then
            return
        end
        local roleModule = roles:FindFirstChild(newRole)
        if not roleModule then
            return
        end
        -- TODO: disconnect previous role module
        require(roleModule).start()
    end)
end

return roleController
