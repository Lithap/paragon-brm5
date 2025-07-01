local UIS = game:GetService("UserInputService")

local frame = Instance.new("Frame", gui)
frame.AnchorPoint = Vector2.new(0, 0.5)
frame.Position = UDim2.new(0, -600, 0.5, 0)
frame.Size = UDim2.new(0, 600, 0, 340)
frame.BackgroundColor3 = COLOR_MAIN
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", frame)
stroke.Color = COLOR_ACCENT
stroke.Thickness = 1
stroke.Transparency = 0.4

local header = Instance.new("TextLabel", frame)
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundTransparency = 1
header.Text = "PARAGON | OPEN WORLD"
header.Font = Enum.Font.GothamBlack
header.TextSize = 32
header.TextColor3 = COLOR_TEXT
header.TextStrokeTransparency = 0.85

local divider = Instance.new("Frame", frame)
divider.Position = UDim2.new(0, 10, 0, 52)
divider.Size = UDim2.new(1, -20, 0, 1)
divider.BackgroundColor3 = COLOR_ACCENT

local content = Instance.new("Frame", frame)
content.Position = UDim2.new(0, 10, 0, 60)
content.Size = UDim2.new(1, -20, 1, -70)
content.BackgroundTransparency = 1
local layout = Instance.new("UIListLayout", content)
layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top

local function createButton(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 250, 0, 40)
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 20
    btn.TextColor3 = COLOR_TEXT
    btn.BackgroundColor3 = COLOR_MAIN
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    local uicorner = Instance.new("UICorner", btn)
    uicorner.CornerRadius = UDim.new(0, 6)
    local h = Instance.new("UIStroke", btn)
    h.Color = COLOR_ACCENT
    h.Thickness = 1
    h.Transparency = 0.8

    btn.MouseEnter:Connect(function()
        TweenService:Create(h, TweenInfo.new(0.2), {Transparency = 0.2}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(h, TweenInfo.new(0.2), {Transparency = 0.8}):Play()
    end)

    return btn
end


createButton("🙋 Self").Parent = content
createButton("🌐 Online").Parent = content
createButton("🔫 Weapon").Parent = content
createButton("🌍 World").Parent = content


local menuOpen = false
local openPos = UDim2.new(0, 10, 0.5, -frame.Size.Y.Offset / 2)
local closedPos = UDim2.new(0, -frame.Size.X.Offset, 0.5, -frame.Size.Y.Offset / 2)

local function toggleMenu()
    menuOpen = not menuOpen
    local targetPos = menuOpen and openPos or closedPos
    TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = targetPos
    }):Play()
end


UIS.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.BackSlash then
        toggleMenu()
    end
end)


toggleMenu()
