--------------------------------------------------------------------
--  PARAGON LOADER  (error-free, Return-key fixed)
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

--// Services
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local Camera       = workspace.CurrentCamera
local LP           = Players.LocalPlayer

--// Simple log helper
local function log(msg) print("[PARAGON] "..msg) end

--// Colours & constants
local COLOR_BLUE   = Color3.fromRGB(0,160,255)
local COLOR_RED    = Color3.fromRGB(255,70,70)
local COLOR_GREEN  = Color3.fromRGB(80,255,80)
local COLOR_TEXT   = Color3.fromRGB(235,235,235)
local COLOR_PANEL  = Color3.fromRGB(20,20,24)
local MIN_PANEL_H  = 260
local VALID_KEY    = "paragon"
local OPENWORLD_URL= "https://raw.githubusercontent.com/Lithap/paragon-brm5/main/openworld.lua"

--// Remove previous loader
local old = LP:FindFirstChild("PlayerGui") and LP.PlayerGui:FindFirstChild("ParagonLoaderUI")
if old then old:Destroy() log("Old loader destroyed") end

--// Root GUI
local gui = Instance.new("ScreenGui")
gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn = "ParagonLoaderUI", true, false
if syn and syn.protect_gui then syn.protect_gui(gui) end
gui.Parent = LP:WaitForChild("PlayerGui")

--------------------------------------------------------------------
--  MAIN PANEL
--------------------------------------------------------------------
local panel = Instance.new("Frame", gui)
panel.Position = UDim2.new(0.5,-160,0.5,-MIN_PANEL_H/2)
panel.BackgroundColor3, panel.BackgroundTransparency, panel.BorderSizePixel = COLOR_PANEL, 0.3, 0
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,6)
local stroke = Instance.new("UIStroke", panel) stroke.Color, stroke.Transparency = COLOR_BLUE, 0.4

local header = Instance.new("TextLabel", panel)
header.Size, header.BackgroundTransparency = UDim2.new(1,0,0,40), 1
header.Text, header.Font, header.TextScaled, header.TextColor3 = "PARAGON", Enum.Font.GothamBlack, true, COLOR_TEXT

local divider = Instance.new("Frame", panel)
divider.Position, divider.Size, divider.BackgroundColor3 = UDim2.new(0,6,0,42), UDim2.new(1,-12,0,1), COLOR_BLUE

local container = Instance.new("Frame", panel) container.BackgroundTransparency = 1
local layout = Instance.new("UIListLayout", container) layout.Padding = UDim.new(0,4)

--------------------------------------------------------------------
--  KEY ROW + UNLOCK BUTTON
--------------------------------------------------------------------
local keyRow = Instance.new("Frame", container) keyRow.Size = UDim2.new(1,0,0,32) keyRow.BackgroundTransparency = 1
local lbl = Instance.new("TextLabel", keyRow)
lbl.Size, lbl.BackgroundTransparency, lbl.Font, lbl.TextScaled, lbl.TextColor3, lbl.TextXAlignment =
    UDim2.new(0.55,0,1,0), 1, Enum.Font.GothamSemibold, true, COLOR_TEXT, Enum.TextXAlignment.Left
lbl.Text = "Enter Key:"

local box = Instance.new("TextBox", keyRow)
box.Size, box.Position = UDim2.new(0.45,0,1,0), UDim2.new(0.55,0,0,0)
box.BackgroundColor3, box.BackgroundTransparency, box.BorderSizePixel =
    COLOR_PANEL, 0.35, 0
box.Font, box.TextScaled, box.TextColor3, box.PlaceholderText, box.ClearTextOnFocus =
    Enum.Font.Gotham, true, COLOR_TEXT, VALID_KEY, false
Instance.new("UICorner", box).CornerRadius = UDim.new(0,4)

local unlock = Instance.new("TextButton", container)
unlock.Size = UDim2.new(1,0,0,30)
unlock.BackgroundColor3, unlock.BackgroundTransparency, unlock.BorderSizePixel =
    COLOR_PANEL, 0.35, 0
unlock.Text, unlock.Font, unlock.TextScaled, unlock.TextColor3 = "Unlock", Enum.Font.GothamBold, true, COLOR_TEXT
Instance.new("UICorner", unlock).CornerRadius = UDim.new(0,4)
local hi = Instance.new("Frame", unlock)
hi.Size, hi.BackgroundColor3, hi.BackgroundTransparency, hi.BorderSizePixel = UDim2.new(1,0,1,0), COLOR_BLUE, 0.9, 0

local function resize()
    local h = 46
    for _,c in ipairs(container:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then h += c.Size.Y.Offset + layout.Padding.Offset end
    end
    container.Size, container.Position = UDim2.new(1,-12,0,h-46), UDim2.new(0,6,0,46)
    local vp = Camera.ViewportSize
    panel.Size = UDim2.new(0, math.clamp(vp.X*0.28,320,500), 0, math.max(h+20, MIN_PANEL_H))
end
resize(); layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize); Camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

--------------------------------------------------------------------
--  KEY CHECK
--------------------------------------------------------------------
local function border(col)
    TweenService:Create(stroke, TweenInfo.new(0.15), {Color=col}):Play()
    TweenService:Create(divider, TweenInfo.new(0.15), {BackgroundColor3=col}):Play()
end
local function bad()
    border(COLOR_RED)
    unlock.Text, unlock.TextColor3 = "Invalid", COLOR_RED
    task.wait(1)
    unlock.Text, unlock.TextColor3 = "Unlock", COLOR_TEXT
    border(COLOR_BLUE)
end
local function good()
    border(COLOR_GREEN)
    unlock.Text, unlock.TextColor3 = "Granted", COLOR_GREEN
    task.wait(0.25)

    local raw = game:HttpGet(OPENWORLD_URL)          -- fetch UI
    local ok, err = pcall(loadstring(raw))
    if not ok then warn("[PARAGON] Runtime error:",err) end

    TweenService:Create(panel, TweenInfo.new(0.4), {BackgroundTransparency=1, Size=UDim2.new(0,0,0,0)}):Play()
    task.wait(0.45); gui:Destroy()
end
local function checkKey()
    if (box.Text:gsub("%s+",""):lower()) == VALID_KEY then good() else bad() end
end
unlock.MouseButton1Click:Connect(checkKey)

-- Return-key handling (no .FireEvent)
UIS.InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.KeyCode==Enum.KeyCode.Return then
        checkKey()
    end
end)

-- Simple hi-light on hover
unlock.MouseEnter:Connect(function() TweenService:Create(hi,TweenInfo.new(0.12),{BackgroundTransparency=0.25}):Play() end)
unlock.MouseLeave:Connect(function() TweenService:Create(hi,TweenInfo.new(0.12),{BackgroundTransparency=0.9 }):Play() end)

panel.Position = UDim2.new(0.5,-panel.Size.X.Offset/2,1,0)
TweenService:Create(panel,TweenInfo.new(0.7,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
    {Position=UDim2.new(0.5,-panel.Size.X.Offset/2,0.5,-panel.Size.Y.Offset/2)}):Play()
log("Loader ready – type key, press Enter or click Unlock.")
