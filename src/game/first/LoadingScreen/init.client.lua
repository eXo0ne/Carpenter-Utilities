--[[ File Info

	Author(s): ChiefWildin
	Version: 2.0.0

	* ENDING THE LOADING SCREEN IS HANDLED BY THE CLIENT JOB LoadingScreen.lua *

	The style of this code may differ from others (i.e. Services are not
	initialized at the top of the code), because it's structured in a way to
	maximize operations for load order.

]]

local PLAY_IN_STUDIO = true
local SKIP_BUTTON_DELAY = 5

local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local LoadingScreenGui: ScreenGui = require(script:WaitForChild("LoadingScreenGui"))

LoadingScreenGui.Parent = PlayerGui

if not RunService:IsStudio() or PLAY_IN_STUDIO then
	LoadingScreenGui.Enabled = true
	script.Parent:RemoveDefaultLoadingScreen()

	local mainFrame: Frame = LoadingScreenGui:WaitForChild("Frame")
	local loadingBar: Frame = mainFrame:WaitForChild("LoadingBarHolder"):WaitForChild("LoadingBar")
	local logo: ImageLabel = mainFrame:WaitForChild("Logo")
	local label: TextLabel = mainFrame:WaitForChild("Label")
	local status: TextLabel = mainFrame:WaitForChild("StatusLabel")
	local skipButton: TextButton = mainFrame:WaitForChild("SkipButton")
	local skipButtonStroke: UIStroke = skipButton:WaitForChild("UIStroke")
	local skipped = false

	task.spawn(ContentProvider.PreloadAsync, ContentProvider, { logo.Image })

	local function murderTweenWhenDone(tween: Tween)
		tween.Completed:Wait()
		tween:Destroy()
	end

	local function tween(object: Instance, tweenInfo: TweenInfo, properties: {}, waitToKill: boolean)
		if not object then
			warn("Tween failure - invalid object passed\n", debug.traceback())
			if waitToKill then
				task.wait(tweenInfo.Time)
			end
			return
		end

		local thisTween = TweenService:Create(object, tweenInfo, properties)
		thisTween:Play()
		if waitToKill then
			murderTweenWhenDone(thisTween)
		else
			task.spawn(murderTweenWhenDone, thisTween)
		end
	end

	skipButton.Visible = true

	tween(logo, TweenInfo.new(2), { ImageTransparency = 0 }, true)
	tween(label, TweenInfo.new(2), { TextTransparency = 0 }, true)
	tween(status, TweenInfo.new(1), { TextTransparency = 0 }, true)

	task.spawn(function()
		while logo.ImageTransparency == 0 do
			tween(
				loadingBar,
				TweenInfo.new(0.375, Enum.EasingStyle.Quint),
				{ Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0 },
				true
			)

			loadingBar.AnchorPoint = Vector2.new(1, 0.5)
			loadingBar.Position = UDim2.fromScale(1, 0.5)

			tween(
				loadingBar,
				TweenInfo.new(0.375, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Size = UDim2.fromScale(0, 1), BackgroundTransparency = 1 },
				true
			)

			loadingBar.AnchorPoint = Vector2.new(0, 0.5)
			loadingBar.Position = UDim2.fromScale(0, 0.5)

			task.wait(0.15)
		end
	end)

	local loadStart = os.clock()
	local skipButtonShown = false

	task.wait(3)

	while (ContentProvider.RequestQueueSize > 1 or not game:IsLoaded()) and not skipped do
		if os.clock() - loadStart > SKIP_BUTTON_DELAY and not skipButtonShown then
			skipButtonShown = true

			tween(skipButton, TweenInfo.new(0.5), { BackgroundTransparency = 1, TextTransparency = 0 })
			tween(skipButtonStroke, TweenInfo.new(0.5), { Transparency = 0 })

			skipButton.Active = true

			skipButton.MouseEnter:Connect(function()
				if not skipped then
					tween(skipButton, TweenInfo.new(0.2), { BackgroundTransparency = 0, TextColor3 = Color3.new() })
				end
			end)

			skipButton.MouseLeave:Connect(function()
				tween(skipButton, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1) })
			end)

			skipButton.Activated:Connect(function()
				if not skipped then
					skipped = true
					tween(skipButton, TweenInfo.new(0.5), { BackgroundTransparency = 1, TextTransparency = 1 })
					tween(skipButtonStroke, TweenInfo.new(0.5), { Transparency = 1 })
					skipButton.Active = false
				end
			end)
		end
		task.wait()
	end

	status.Text = "L O A D I N G   G A M E   S C R I P T S"

	LoadingScreenGui:SetAttribute("Loaded", true)
	skipButton.Visible = false
else
	LoadingScreenGui:SetAttribute("Loaded", true)
end
