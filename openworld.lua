if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

if LP:FindFirstChild("PlayerGui") and LP.PlayerGui:FindFirstChild("ParagonMainUI") then
    LP.PlayerGui.ParagonMainUI:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "ParagonMainUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
if syn and syn.protect_gui then syn.protect_gui(gui) end
gui.Parent = LP:WaitForChild("PlayerGui")

local COLOR_MAIN = Color3.fromRGB(22, 22, 26)
local COLOR_ACCENT = Color3.fromRGB(0,160,255)
local COLOR_TEXT = Color3.fromRGB(240,240,240)

local frame = Instance.new("Frame", gui)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
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


local selfBtn = createButton("🙋 Self")
selfBtn.Parent = content

local onlineBtn = createButton("🌐 Online")
onlineBtn.Parent = content

local weaponBtn = createButton("🔫 Weapon")
weaponBtn.Parent = content

local worldBtn = createButton("🌍 World")
worldBtn.Parent = content


frame.Position = UDim2.new(0.5, 0, 1.2, 0)
TweenService:Create(frame, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, 0, 0.5, 0)
}):Play()
