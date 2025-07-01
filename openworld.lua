--------------------------------------------------------------------
--  PARAGON OPEN WORLD UI | v2.0                                     
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

--------------------------------------------------------------------
-- Services & PlayerGui
--------------------------------------------------------------------
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local LP           = Players.LocalPlayer

-- destroy dupes
local pg = LP:WaitForChild("PlayerGui")
local prev = pg:FindFirstChild("ParagonMainUI")
if prev then prev:Destroy() end

--------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------
local COLOR_MAIN   = Color3.fromRGB(22,22,26)
local COLOR_ACCENT = Color3.fromRGB(0,160,255)
local COLOR_TEXT   = Color3.fromRGB(240,240,240)

--------------------------------------------------------------------
-- Root ScreenGui
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn = "ParagonMainUI", true, false
if syn and syn.protect_gui then syn.protect_gui(gui) end
gui.Parent = pg

--------------------------------------------------------------------
-- Frame
--------------------------------------------------------------------
local frame = Instance.new("Frame", gui)
frame.AnchorPoint = Vector2.new(0,0.5)   -- left-edge anchor
frame.Position    = UDim2.new(0,-610,0.5,0)  -- start fully hidden
frame.Size        = UDim2.new(0,600,0,340)
frame.BackgroundColor3, frame.BackgroundTransparency = COLOR_MAIN, 0.2
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

local stroke = Instance.new("UIStroke", frame)
stroke.Color, stroke.Thickness, stroke.Transparency = COLOR_ACCENT, 1, 0.4

--------------------------------------------------------------------
-- Header
--------------------------------------------------------------------
local header = Instance.new("TextLabel", frame)
header.Size = UDim2.new(1,0,0,50)
header.BackgroundTransparency = 1
header.Text = "PARAGON | OPEN WORLD"
header.Font = Enum.Font.GothamBlack
header.TextSize = 32
header.TextColor3 = COLOR_TEXT
header.TextStrokeTransparency = 0.85

local divider = Instance.new("Frame", frame)
divider.Position = UDim2.new(0,10,0,52)
divider.Size = UDim2.new(1,-20,0,1)
divider.BackgroundColor3 = COLOR_ACCENT

--------------------------------------------------------------------
-- Content container
--------------------------------------------------------------------
local content = Instance.new("Frame", frame)
content.Position = UDim2.new(0,10,0,60)
content.Size     = UDim2.new(1,-20,1,-70)
content.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", content)
layout.Padding = UDim.new(0,10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment   = Enum.VerticalAlignment.Top

--------------------------------------------------------------------
-- Button Factory
--------------------------------------------------------------------
local function make(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,250,0,40)
    b.Text = text
    b.Font = Enum.Font.GothamSemibold
    b.TextSize, b.TextColor3 = 20, COLOR_TEXT
    b.BackgroundColor3, b.BackgroundTransparency, b.BorderSizePixel =
        COLOR_MAIN, 0.2, 0
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    local hi = Instance.new("UIStroke", b)
    hi.Color, hi.Thickness, hi.Transparency = COLOR_ACCENT, 1, 0.8

    -- hover glow
    b.MouseEnter:Connect(function()
        TweenService:Create(hi,TweenInfo.new(0.2),{Transparency=0.2}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(hi,TweenInfo.new(0.2),{Transparency=0.8}):Play()
    end)
    return b
end

-- buttons
make("🙋 Self").Parent     = content
make("🌐 Online").Parent   = content
make("🔫 Weapon").Parent   = content
make("🌍 World").Parent    = content

--------------------------------------------------------------------
-- Slide-in / Slide-out Toggle
--------------------------------------------------------------------
local menuOpen  = false
local openPos   = UDim2.new(0,10, 0.5, -frame.Size.Y.Offset/2)
local closedPos = UDim2.new(0,-frame.Size.X.Offset-10, 0.5, -frame.Size.Y.Offset/2)

local function toggle()
    menuOpen = not menuOpen
    TweenService:Create(frame, TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {
        Position = menuOpen and openPos or closedPos
    }):Play()
end

-- Backslash key
UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.BackSlash then toggle() end
end)

-- open automatically once
toggle()
