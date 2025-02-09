local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- local serviceUtil = require(ReplicatedStorage.shared.utilities.serviceUtil)

local Packages = ReplicatedStorage.sharedPackages

local ReactRoblox = require(Packages.ReactRoblox)
-- local ReactSpring = require(Packages.ReactSpring)
local React = require(Packages.React)

local reactComponents = ReplicatedStorage.client.reactComponents

local Signal = require(Packages.Signal)

local App = require(script.App)

local e = React.createElement

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local uiList = {
	{
		uiName = "AlphaWarning",
		ignoreGuiInset = true
	},
	{
		uiName = "Death",
		ignoreGuiInset = true
	},
	{
		uiName = "Topbar",
		ignoreGuiInset = false
	},
	{
		uiName = "WitchTimer",
		ignoreGuiInset = true
	},
	{
		uiName = "SkipIntro",
		ignoreGuiInset = true
	},
	{
        uiName = "Fade",
		ignoreGuiInset = true
	},
	{
		uiName = "MafiaVote",
		ignoreGuiInset = true
	},
    {
        uiName = "Spectate",
        ignoreGuiInset = true
    },
}

local uiRoots = {}
local uiProps = {}
local uiPropsSignal = {}

local uiController = {
	setUIToggledSignal = Signal.new(),
	setUIPropSignal = Signal.new()
}

function uiController.start()
	uiController.setUIToggledSignal:Connect(function(uiName: string, toggled: boolean)
		uiController:setUIToggledSignal(uiName, toggled)
	end)

	uiController.setUIPropSignal:Connect(function(uiName: string, props: {[string]: any} | nil)
		if props ~= nil and typeof(props) ~= "table" then
			return
		end
		uiProps[uiName] = props
		uiPropsSignal[uiName]:Fire(props)
	end)

	for _, uiInfo in uiList do
		local uiName = uiInfo.uiName
		uiPropsSignal[uiName] = Signal.new()
		uiController:setUIToggled(uiName, true)
	end
end

function uiController:findIndexFromUIName(uiName: string)
	for index, uiInfo in uiList do
		if uiInfo.uiName == uiName then
			return index
		end
	end
    return
end

function uiController:setUIToggled(uiName: string, toggled: boolean)
	local uiIndex = uiController:findIndexFromUIName(uiName)
	local uiRoot = uiRoots[uiIndex]
	if uiRoot then
		uiRoot:unmount()
	end

	if not toggled then
		return
	end

	local ignoreGuiInset = uiList[uiIndex].ignoreGuiInset

	uiRoot = ReactRoblox.createRoot(Instance.new("Folder"))
	uiRoot:render(ReactRoblox.createPortal(e("ScreenGui", {
		IgnoreGuiInset = ignoreGuiInset or true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		DisplayOrder = -uiIndex
	}, {
		Component = e(App, {
			child = require(reactComponents[uiName]),
			uiPropsChanged = uiPropsSignal[uiName],
			initialProps = uiProps[uiName]
		})
	}), playerGui, uiName))
	uiRoots[uiName] = uiRoot
end

function uiController:setFadeProps(transparency: number?, duration: number?, easing: ((number) -> number)?)
	uiController.setUIPropSignal:Fire("Fade", {
		transparency = transparency,
		duration = duration,
		easing = easing
	})
end

function uiController:setTopbarProps(targetText: string?, initialText: string?, typewriterDelay: number?)
	uiController.setUIPropSignal:Fire("Topbar", {
		typewriterDelay = typewriterDelay,
		initialText = initialText,
		targetText = targetText,
	})
end

function uiController:setSkipIntroVisible(visible: boolean?)
	uiController.setUIPropSignal:Fire("SkipIntro", {
		visible = visible
	})
end

function uiController:setWitchTimerProps(timeStarted: number?, timer: number?)
	uiController.setUIPropSignal:Fire("WitchTimer", {
		timeStarted = timeStarted,
		timer = timer
	})
	
end

return uiController