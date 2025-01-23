local roleDescriptions = {}

for _, role in script:GetChildren() do
	local roleDescription = require(role)
	roleDescriptions[role.Name] = roleDescription
end

return roleDescriptions
