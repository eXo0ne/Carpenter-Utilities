-- * Generated with Codify (Regular framework) * --

local loadingScreenGui = Instance.new("ScreenGui")
loadingScreenGui.Name = "LoadingScreenGui"
loadingScreenGui.DisplayOrder = 20
loadingScreenGui.IgnoreGuiInset = true
loadingScreenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
loadingScreenGui.Enabled = false
loadingScreenGui.ResetOnSpawn = false
loadingScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local frame = Instance.new("Frame")
frame.Name = "Frame"
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BorderSizePixel = 0
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.Size = UDim2.fromScale(1, 1)

local logo = Instance.new("ImageLabel")
logo.Name = "Logo"
logo.Image = "rbxassetid://9688321478"
logo.ImageTransparency = 1
logo.ScaleType = Enum.ScaleType.Fit
logo.AnchorPoint = Vector2.new(0.5, 1)
logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
logo.BackgroundTransparency = 1
logo.Position = UDim2.fromScale(0.5, 0.5)
logo.Size = UDim2.fromScale(1, 0.125)

local uISizeConstraint = Instance.new("UISizeConstraint")
uISizeConstraint.Name = "UISizeConstraint"
uISizeConstraint.MinSize = Vector2.new(75, 75)
uISizeConstraint.Parent = logo

local uIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
uIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
uIAspectRatioConstraint.AspectRatio = 4
uIAspectRatioConstraint.Parent = logo

logo.Parent = frame

local loadingBarHolder = Instance.new("Frame")
loadingBarHolder.Name = "LoadingBarHolder"
loadingBarHolder.AnchorPoint = Vector2.new(0.5, 0.5)
loadingBarHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
loadingBarHolder.BackgroundTransparency = 1
loadingBarHolder.LayoutOrder = 7
loadingBarHolder.Position = UDim2.fromScale(0.5, 0.75)
loadingBarHolder.Size = UDim2.fromScale(0.35, 0.005)

local loadingBar = Instance.new("Frame")
loadingBar.Name = "LoadingBar"
loadingBar.AnchorPoint = Vector2.new(0, 0.5)
loadingBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
loadingBar.BorderSizePixel = 0
loadingBar.Position = UDim2.fromScale(0, 0.5)
loadingBar.Size = UDim2.fromScale(0, 1)
loadingBar.Parent = loadingBarHolder

local uISizeConstraint1 = Instance.new("UISizeConstraint")
uISizeConstraint1.Name = "UISizeConstraint"
uISizeConstraint1.MaxSize = Vector2.new(500, math.huge)
uISizeConstraint1.MinSize = Vector2.new(200, 0)
uISizeConstraint1.Parent = loadingBarHolder

loadingBarHolder.Parent = frame

local uIListLayout = Instance.new("UIListLayout")
uIListLayout.Name = "UIListLayout"
uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
uIListLayout.Parent = frame

local buffer = Instance.new("Frame")
buffer.Name = "buffer"
buffer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
buffer.BackgroundTransparency = 1
buffer.BorderSizePixel = 0
buffer.LayoutOrder = 4
buffer.Size = UDim2.fromScale(1, 0.1)
buffer.SizeConstraint = Enum.SizeConstraint.RelativeXX

local uISizeConstraint2 = Instance.new("UISizeConstraint")
uISizeConstraint2.Name = "UISizeConstraint"
uISizeConstraint2.MaxSize = Vector2.new(math.huge, 150)
uISizeConstraint2.MinSize = Vector2.new(0, 75)
uISizeConstraint2.Parent = buffer

buffer.Parent = frame

local label = Instance.new("TextLabel")
label.Name = "Label"
label.FontFace = Font.new(
  "rbxasset://fonts/families/Inconsolata.json",
  Enum.FontWeight.Bold,
  Enum.FontStyle.Normal
)
label.Text = "S A W H O R S E   I N T E R A C T I V E"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.TextSize = 14
label.TextTransparency = 1
label.TextWrapped = true
label.AnchorPoint = Vector2.new(0.5, 0)
label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
label.BackgroundTransparency = 1
label.LayoutOrder = 2
label.Position = UDim2.fromScale(0.5, 1)
label.Size = UDim2.fromScale(1, 0.1)

local uISizeConstraint3 = Instance.new("UISizeConstraint")
uISizeConstraint3.Name = "UISizeConstraint"
uISizeConstraint3.MaxSize = Vector2.new(math.huge, 25)
uISizeConstraint3.Parent = label

local uIPadding = Instance.new("UIPadding")
uIPadding.Name = "UIPadding"
uIPadding.PaddingLeft = UDim.new(0.05, 0)
uIPadding.PaddingRight = UDim.new(0.05, 0)
uIPadding.Parent = label

label.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
statusLabel.RichText = true
statusLabel.Text = "L O A D I N G   A S S E T S"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextScaled = true
statusLabel.TextSize = 14
statusLabel.TextTransparency = 1
statusLabel.TextWrapped = true
statusLabel.AnchorPoint = Vector2.new(0.5, 0)
statusLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.BorderColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.BorderSizePixel = 2
statusLabel.LayoutOrder = 5
statusLabel.Position = UDim2.fromScale(0.5, 0.625)
statusLabel.Size = UDim2.fromScale(1, 0.1)

local uISizeConstraint4 = Instance.new("UISizeConstraint")
uISizeConstraint4.Name = "UISizeConstraint"
uISizeConstraint4.MaxSize = Vector2.new(math.huge, 20)
uISizeConstraint4.Parent = statusLabel

statusLabel.Parent = frame

local buffer1 = Instance.new("Frame")
buffer1.Name = "buffer"
buffer1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
buffer1.BackgroundTransparency = 1
buffer1.BorderSizePixel = 0
buffer1.LayoutOrder = 6
buffer1.Size = UDim2.fromScale(1, 0.02)
buffer1.SizeConstraint = Enum.SizeConstraint.RelativeXX

local uISizeConstraint5 = Instance.new("UISizeConstraint")
uISizeConstraint5.Name = "UISizeConstraint"
uISizeConstraint5.MaxSize = Vector2.new(math.huge, 20)
uISizeConstraint5.Parent = buffer1

buffer1.Parent = frame

local buffer2 = Instance.new("Frame")
buffer2.Name = "buffer"
buffer2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
buffer2.BackgroundTransparency = 1
buffer2.BorderSizePixel = 0
buffer2.LayoutOrder = 1
buffer2.Size = UDim2.fromScale(1, 0.02)
buffer2.Parent = frame

local skipButton = Instance.new("TextButton")
skipButton.Name = "SkipButton"
skipButton.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
skipButton.Text = "S K I P   P R E L O A D"
skipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
skipButton.TextScaled = true
skipButton.TextSize = 14
skipButton.TextTransparency = 1
skipButton.TextWrapped = true
skipButton.AutoButtonColor = false
skipButton.AnchorPoint = Vector2.new(0.5, 0)
skipButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
skipButton.BackgroundTransparency = 1
skipButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
skipButton.BorderSizePixel = 0
skipButton.LayoutOrder = 9
skipButton.Position = UDim2.new(0.5, 0, 1, 40)
skipButton.Size = UDim2.fromScale(0.25, 0.035)

local uIPadding1 = Instance.new("UIPadding")
uIPadding1.Name = "UIPadding"
uIPadding1.PaddingBottom = UDim.new(0.3, 0)
uIPadding1.PaddingLeft = UDim.new(0.1, 0)
uIPadding1.PaddingRight = UDim.new(0.1, 0)
uIPadding1.PaddingTop = UDim.new(0.3, 0)
uIPadding1.Parent = skipButton

local uISizeConstraint6 = Instance.new("UISizeConstraint")
uISizeConstraint6.Name = "UISizeConstraint"
uISizeConstraint6.MaxSize = Vector2.new(300, math.huge)
uISizeConstraint6.MinSize = Vector2.new(150, 0)
uISizeConstraint6.Parent = skipButton

local uIStroke = Instance.new("UIStroke")
uIStroke.Name = "UIStroke"
uIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
uIStroke.Color = Color3.fromRGB(255, 255, 255)
uIStroke.Thickness = 2
uIStroke.Transparency = 1
uIStroke.Parent = skipButton

local uICorner = Instance.new("UICorner")
uICorner.Name = "UICorner"
uICorner.CornerRadius = UDim.new(0.1, 0)
uICorner.Parent = skipButton

skipButton.Parent = frame

local buffer3 = Instance.new("Frame")
buffer3.Name = "buffer"
buffer3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
buffer3.BackgroundTransparency = 1
buffer3.BorderSizePixel = 0
buffer3.LayoutOrder = 8
buffer3.Size = UDim2.new(1, 0, 0.04, 20)
buffer3.SizeConstraint = Enum.SizeConstraint.RelativeXX

local uISizeConstraint7 = Instance.new("UISizeConstraint")
uISizeConstraint7.Name = "UISizeConstraint"
uISizeConstraint7.MaxSize = Vector2.new(math.huge, 50)
uISizeConstraint7.Parent = buffer3

buffer3.Parent = frame

frame.Parent = loadingScreenGui

return loadingScreenGui
