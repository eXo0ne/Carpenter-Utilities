--[[
	LoadingScreen.lua
	ChiefWildin
	Created: 05/30/2022

	Description:
		Used to manage the transition of the loading screen into the game.

	Documentation:
		::FadeIn()
			Tweens out the logo and status text (bar is handled automatically as
			its tween is completed). Then fades out the black background, and
			disables the loading screen GUI afterwards. Yields until the logo
			and status text are faded out.

		::LoadCurrentQueue()
	        Load the current content provider queue. If `skipFade` is true, and
			the module is set to use the provided GUI, then the loading screen
			will not automatically fade out after the queue is exhausted.
--]]

-- Services

local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local StarterGui = game:GetService("StarterGui")

-- Main job table

local LoadingScreen = {}

-- Dependencies

local AnimNation = shared("AnimNation") ---@module AnimNation

-- Constants

-- This delay only applies to `:LoadCurrentQueue()`, there is a separate
-- constant in `LoadingScreen.client.lua` for the delay in initial load.
local SKIP_BUTTON_DELAY = 5
-- Whether to display and animate the loading screen GUI when
-- `:LoadCurrentQueue()` is called.
local USE_DEFAULT_GUI = false
-- Whether the loading screen should automatically fade in after asset and
-- job initialization has completed. If false, the loading screen will remain
-- visible until `:FadeIn()` is called by some other module.
local AUTOMATIC_FADE_IN = true
-- The desired CoreGui states to enable after loading
local CORE_GUI_STATES = {
	[Enum.CoreGuiType.PlayerList] = true,
	[Enum.CoreGuiType.EmotesMenu] = true,
	[Enum.CoreGuiType.Backpack] = true,
	[Enum.CoreGuiType.Chat] = true,
	[Enum.CoreGuiType.Health] = true,
	[Enum.CoreGuiType.SelfView] = true,
}

-- Global variables

local CurrentQueueLoading = false

-- Objects

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local LoadingScreenGui = PlayerGui:WaitForChild("LoadingScreenGui")
local MainFrame = LoadingScreenGui:WaitForChild("Frame")
local Logo = MainFrame:WaitForChild("Logo")
local Label = MainFrame:WaitForChild("Label")
local StatusLabel = MainFrame:WaitForChild("StatusLabel")
local SkipButton = MainFrame:WaitForChild("SkipButton")
local SkipButtonStroke = SkipButton:WaitForChild("UIStroke")
local LoadingBar = MainFrame:WaitForChild("LoadingBarHolder"):WaitForChild("LoadingBar")

-- Private functions

-- Public functions

-- Yields the current thread until loading is complete
function LoadingScreen:WaitUntilLoaded()
	if not LoadingScreenGui:GetAttribute("Loaded") then
		LoadingScreenGui:GetAttributeChangedSignal("Loaded"):Wait()
	end
end

-- Tweens out the logo and status text (bar is handled automatically as its
-- tween is completed). Then fades out the black background, and disables the
-- loading screen GUI afterwards. Yields until the logo and status text are
-- faded out.
function LoadingScreen:FadeIn()
	self:WaitUntilLoaded()

	-- Wipe logo and text
	SkipButton.Active = false
	AnimNation.tween(Logo, TweenInfo.new(2), { ImageTransparency = 1 })
	AnimNation.tween(SkipButton, TweenInfo.new(0.5), { BackgroundTransparency = 1, TextTransparency = 1 })
	AnimNation.tween(SkipButtonStroke, TweenInfo.new(0.5), { Transparency = 1 })
	AnimNation.tween(StatusLabel, TweenInfo.new(2), { TextTransparency = 1 })
	AnimNation.tween(Label, TweenInfo.new(2), { TextTransparency = 1 }, true)

	-- Fade in
	AnimNation.tween(LoadingScreenGui.Frame, TweenInfo.new(1), { BackgroundTransparency = 1 })
	SkipButton.Visible = false
	task.delay(1, function()
		LoadingScreenGui.Enabled = false
	end)

	for coreGuiType, enabled in pairs(CORE_GUI_STATES) do
		StarterGui:SetCoreGuiEnabled(coreGuiType, enabled)
	end
end

-- Load the current content provider queue. If `skipFade` is true, and the
-- module is set to use the provided GUI, then the loading screen will not
-- automatically fade out after the queue is exhausted.
function LoadingScreen:LoadCurrentQueue(skipFade: boolean)
	if not CurrentQueueLoading then
		CurrentQueueLoading = true
		local loadStart = os.clock()
		local skipped = false

		if USE_DEFAULT_GUI then
			StatusLabel.Text = "L O A D I N G   A S S E T S"
			LoadingScreenGui.Enabled = true
			SkipButton.Visible = true

			AnimNation.tween(LoadingScreenGui.Frame, TweenInfo.new(0.5), { BackgroundTransparency = 0 }, true)
			AnimNation.tween(Logo, TweenInfo.new(2), { ImageTransparency = 0 })
			AnimNation.tween(SkipButton, TweenInfo.new(0.5), { BackgroundTransparency = 1, TextTransparency = 0 })
			AnimNation.tween(SkipButtonStroke, TweenInfo.new(0.5), { Transparency = 1 })
			AnimNation.tween(StatusLabel, TweenInfo.new(2), { TextTransparency = 0 })
			AnimNation.tween(Label, TweenInfo.new(2), { TextTransparency = 0 }, true)

			task.spawn(function()
				while CurrentQueueLoading do
					AnimNation.tween(
						LoadingBar,
						TweenInfo.new(0.5, Enum.EasingStyle.Quint),
						{ Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0 },
						true
					)
					LoadingBar.AnchorPoint = Vector2.new(1, 0.5)
					LoadingBar.Position = UDim2.fromScale(1, 0.5)
					AnimNation.tween(
						LoadingBar,
						TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{ Size = UDim2.fromScale(0, 1), BackgroundTransparency = 1 },
						true
					)
					LoadingBar.AnchorPoint = Vector2.new(0, 0.5)
					LoadingBar.Position = UDim2.fromScale(0, 0.5)
					task.wait(0.2)
				end
			end)
		end

		local skipButtonShown = false
		while (ContentProvider.RequestQueueSize > 1 or not game:IsLoaded()) and not skipped do
			if os.clock() - loadStart > SKIP_BUTTON_DELAY and not skipButtonShown then
				skipButtonShown = true
				SkipButton.Active = true

				AnimNation.tween(SkipButton, TweenInfo.new(0.5), { BackgroundTransparency = 1, TextTransparency = 0 })
				AnimNation.tween(SkipButtonStroke, TweenInfo.new(0.5), { Transparency = 0 })

				SkipButton.MouseEnter:Connect(function()
					if not skipped then
						AnimNation.tween(
							SkipButton,
							TweenInfo.new(0.2),
							{ BackgroundTransparency = 0, TextColor3 = Color3.new() }
						)
					end
				end)

				SkipButton.MouseLeave:Connect(function()
					AnimNation.tween(
						SkipButton,
						TweenInfo.new(0.2),
						{ BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1) }
					)
				end)

				SkipButton.Activated:Connect(function()
					if not skipped then
						skipped = true
						AnimNation.tween(
							SkipButton,
							TweenInfo.new(0.5),
							{ BackgroundTransparency = 1, TextTransparency = 1 }
						)
						AnimNation.tween(SkipButtonStroke, TweenInfo.new(0.5), { Transparency = 1 })
						SkipButton.Active = false
					end
				end)
			end
			task.wait()
		end

		CurrentQueueLoading = false

		if not skipFade and USE_DEFAULT_GUI then
			LoadingScreen:FadeIn()
		end
	end
end

-- Framework callbacks

function LoadingScreen:Run()
	if AUTOMATIC_FADE_IN then
		LoadingScreen:FadeIn()
	end
end

return LoadingScreen
