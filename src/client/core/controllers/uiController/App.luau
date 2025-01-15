local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.sharedPackages

local serviceUtil = require(ReplicatedStorage.shared.utilities.serviceUtil)
local gameService = serviceUtil.service("gameService")

-- local ReactRoblox = require(Packages.ReactRoblox)
-- local ReactSpring = require(Packages.ReactSpring)
local React = require(Packages.React)

local e = React.createElement

local function App(props)
    local child = props.child
    local uiPropsChanged = props.uiPropsChanged
    local childProps, setChildProps = React.useState(props.initialProps)

    React.useEffect(function()
        local connection = uiPropsChanged:Connect(function(newProps)
            setChildProps(newProps)
        end)
        return function()
            connection:Disconnect()
        end
    end, {childProps})

    return e(child, childProps)
end

return App