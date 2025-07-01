--------------------------------------------------------------------
--  PARAGON LOADER  •  Clean, Return-key safe, zero console errors
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

--------------------------------------------------------------------
-- Services & shortcuts
--------------------------------------------------------------------
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local Camera       = workspace.CurrentCamera
local LP           = Players.LocalPlayer
local GUI_PARENT   = LP:WaitForChild("PlayerGui")

local function log(m) print("[PARAGON] "..m) end

--------------------------------------------------------------------
-- Constants / colours
--------------------------------------------------------------------
local COL_BLUE   = Color3.fromRGB(0,160,255)
local COL_RED    = Color3.fromRGB(255, 70, 70)
local COL_GREEN  = Color3.fromRGB( 80,255, 80)
local COL_TEXT   = Color3.fromRGB(235,235,235)
local COL_PANEL  = Color3.fromRGB( 20, 20, 24)

local MIN_PANEL_H = 260
local VALID_KEY   = "paragon"
local UI_URL      = "https://raw.githubusercontent.com/Lithap/paragon-brm5/main/openworld.lua"

--------------------------------------------------------------------
-- Destroy previous instances
--------------------------------------------------------------------
(GUI_PARENT:FindFirstChild("ParagonLoaderUI"))?.:Destroy()

--------------------------------------------------------------------
-- Root ScreenGui
--------------------------------------------------------------------
local sg = Instance.new("ScreenGui")
sg.Name, sg.IgnoreGuiInset, sg.ResetOnSpawn = "ParagonLoaderUI", true, false
if syn and syn.protect_gui then syn.protect_gui(sg) end
sg.Parent = GUI_PARENT

--------------------------------------------------------------------
-- Panel & static widgets
--------------------------------------------------------------------
local panel = Instance.new("Frame", sg)
panel.BackgroundColor3, panel.BackgroundTransparency, panel.BorderSizePixel =
    COL_PANEL, 0.3, 0
panel.Position = UDim2.new(0.5, -160, 0.5, -MIN_PANEL_H/2)
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 6)
local stroke = Instance.new("UIStroke", panel) stroke.Color = COL_BLUE

local header = Instance.new("TextLabel", panel)
header.Size, header.BackgroundTransparency = UDim2.new(1,0,0,40), 1
header.Font, header.TextScaled, header.TextColor3 = Enum.Font.GothamBlack, true, COL_TEXT
header.Text = "PARAGON"

local divider = Instance.new("Frame", panel)
divider.Position, divider.Size, divider.BackgroundColor3 =
    UDim2.new(0,6,0,42), UDim2.new(1,-12,0,1), COL_BLUE

--------------------------------------------------------------------
-- Container & layout
--------------------------------------------------------------------
local container = Instance.new("Frame", panel)
container.BackgroundTransparency = 1
local layout = Instance.new("UIListLayout", container)
layout.Padding, layout.SortOrder = UDim.new(0,4), Enum.SortOrder.LayoutOrder

--------------------------------------------------------------------
-- Key input row
--------------------------------------------------------------------
local keyRow = Instance.new("Frame", container)
keyRow.Size, keyRow.BackgroundTransparency = UDim2.new(1,0,0,32), 1

local keyLabel = Instance.new("TextLabel", keyRow)
keyLabel.Size  = UDim2.new(0.55,0,1,0)
keyLabel.BackgroundTransparency         = 1
keyLabel.Font, keyLabel.TextScaled      = Enum.Font.GothamSemibold, true
keyLabel.TextColor3, keyLabel.Text      = COL_TEXT, "Enter Key:"
keyLabel.TextXAlignment                 = Enum.TextXAlignment.Left

local keyBox  = Instance.new("TextBox", keyRow)
keyBox.Size, keyBox.Position           = UDim2.new(0.45,0,1,0), UDim2.new(0.55,0,0,0)
keyBox.BackgroundColor3, keyBox.BackgroundTransparency, keyBox.BorderSizePixel =
    COL_PANEL, 0.35, 0
keyBox.Font, keyBox.TextScaled, keyBox.TextColor3 =
    Enum.Font.Gotham, true, COL_TEXT
keyBox.PlaceholderText, keyBox.ClearTextOnFocus = VALID_KEY, false
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0,4)

--------------------------------------------------------------------
-- Unlock button
--------------------------------------------------------------------
local unlock = Instance.new("TextButton", container)
unlock.Size   = UDim2.new(1,0,0,30)
unlock.Font   = Enum.Font.GothamBold
unlock.Text   = "Unlock"
unlock.TextScaled, unlock.TextColor3 = true, COL_TEXT
unlock.BackgroundColor3, unlock.BackgroundTransparency, unlock.BorderSizePixel =
    COL_PANEL, 0.35, 0
Instance.new("UICorner", unlock).CornerRadius = UDim.new(0,4)

local hover = Instance.new("Frame", unlock)
hover.Size, hover.BackgroundColor3, hover.BackgroundTransparency =
    UDim2.new(1,0,1,0), COL_BLUE, 0.9
hover.BorderSizePixel = 0

--------------------------------------------------------------------
-- Dynamic resize
--------------------------------------------------------------------
local function resize()
    local needed = 46
    for _,child in ipairs(container:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            needed += child.Size.Y.Offset + layout.Padding.Offset
        end
    end
    container.Size      = UDim2.new(1,-12,0,needed-46)
    container.Position  = UDim2.new(0,6,0,46)

    local vp = Camera.ViewportSize
    panel.Size = UDim2.new(
        0, math.clamp(vp.X*0.28, 320, 500),
        0, math.max(needed+20, MIN_PANEL_H)
    )
end
resize()
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

--------------------------------------------------------------------
-- Visual feedback helpers
--------------------------------------------------------------------
local function tint(col)
    TweenService:Create(stroke ,TweenInfo.new(0.15),{Color=col}):Play()
    TweenService:Create(divider,TweenInfo.new(0.15),{BackgroundColor3=col}):Play()
end

local function feedback(col,msg)
    tint(col)
    unlock.Text, unlock.TextColor3 = msg, col
    task.wait(1)
    unlock.Text, unlock.TextColor3 = "Unlock", COL_TEXT
    tint(COL_BLUE)
end

--------------------------------------------------------------------
-- Load the Open-World UI
--------------------------------------------------------------------
local function loadUI()
    local raw = game:HttpGet(UI_URL, true)
    local ok, err = pcall(loadstring, raw)
    if not ok then
        warn("[PARAGON] UI load error:", err)
        feedback(COL_RED, "Load Fail")
        return
    end

    -- Fade-out loader
    TweenService:Create(panel,TweenInfo.new(0.4),{
        BackgroundTransparency = 1,
        Size = UDim2.new(0,0,0,0)
    }):Play()
    task.wait(0.45)
    sg:Destroy()
end

--------------------------------------------------------------------
-- Key validation
--------------------------------------------------------------------
local function checkKey()
    local txt = (keyBox.Text or ""):gsub("%s+",""):lower()
    if txt == VALID_KEY then
        feedback(COL_GREEN, "Granted")
        loadUI()
    else
        feedback(COL_RED, "Invalid")
    end
end
unlock.MouseButton1Click:Connect(checkKey)

-- Return key triggers the same check
UIS.InputBegan:Connect(function(inp, gp)
    if not gp and inp.KeyCode == Enum.KeyCode.Return then
        checkKey()
    end
end)

--------------------------------------------------------------------
-- Hover animation
--------------------------------------------------------------------
unlock.MouseEnter:Connect(function()
    TweenService:Create(hover, TweenInfo.new(0.12), {BackgroundTransparency=0.25}):Play()
end)
unlock.MouseLeave:Connect(function()
    TweenService:Create(hover, TweenInfo.new(0.12), {BackgroundTransparency=0.9}):Play()
end)

--------------------------------------------------------------------
-- Intro tween
--------------------------------------------------------------------
panel.Position = UDim2.new(0.5, -150, 1, 0)
TweenService:Create(panel, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, -panel.Size.X.Offset/2, 0.5, -panel.Size.Y.Offset/2)
}):Play()

log("Loader ready – type key, press Enter or click Unlock.")
