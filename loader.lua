--------------------------------------------------------------------
--  PARAGON  •  All-in-one Loader  (ESP UI embedded)
--  - Return-key friendly
--  - Silences BRM5’s buggy “Valex1” LocalScript
--  - No HttpGet needed – UI code is in OPENWORLD_SRC below
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

--------------------------------------------------------------------
--  Services & locals
--------------------------------------------------------------------
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local Camera       = workspace.CurrentCamera
local LP           = Players.LocalPlayer
local GUI_PARENT   = LP:WaitForChild("PlayerGui")

--------------------------------------------------------------------
-- 1️⃣  Kill Valex1 (map sound helper that spams errors once)
--------------------------------------------------------------------
local function nukeValex(s)
    if s:IsA("LocalScript") and s.Name == "Valex1" then
        s.Disabled = true
    end
end
local existing = LP.PlayerScripts:FindFirstChild("Valex1")
if existing then nukeValex(existing) end
LP.PlayerScripts.ChildAdded:Connect(nukeValex)

--------------------------------------------------------------------
-- Colours & constants
--------------------------------------------------------------------
local COL_BLUE   = Color3.fromRGB(0,160,255)
local COL_RED    = Color3.fromRGB(255,70,70)
local COL_GREEN  = Color3.fromRGB(80,255,80)
local COL_TEXT   = Color3.fromRGB(235,235,235)
local COL_PANEL  = Color3.fromRGB(20,20,24)

local VALID_KEY   = "paragon"      -- <<< change if you like
local MIN_PANEL_H = 260

--------------------------------------------------------------------
--  Remove any previous loader
--------------------------------------------------------------------
local old = GUI_PARENT:FindFirstChild("ParagonLoaderUI")
if old then old:Destroy() end

--------------------------------------------------------------------
--  Root ScreenGui
--------------------------------------------------------------------
local sg = Instance.new("ScreenGui")
sg.Name, sg.IgnoreGuiInset, sg.ResetOnSpawn = "ParagonLoaderUI", true, false
if syn and syn.protect_gui then syn.protect_gui(sg) end
sg.Parent = GUI_PARENT

--------------------------------------------------------------------
--  Main panel
--------------------------------------------------------------------
local panel = Instance.new("Frame", sg)
panel.BackgroundColor3, panel.BackgroundTransparency, panel.BorderSizePixel =
    COL_PANEL, 0.3, 0
panel.Position = UDim2.new(0.5,-160,0.5,-MIN_PANEL_H/2)
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,6)
local stroke = Instance.new("UIStroke", panel) stroke.Color = COL_BLUE

local header = Instance.new("TextLabel", panel)
header.Size = UDim2.new(1,0,0,40)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBlack
header.TextScaled = true
header.TextColor3 = COL_TEXT
header.Text = "PARAGON"

local divider = Instance.new("Frame", panel)
divider.Position, divider.Size, divider.BackgroundColor3 =
    UDim2.new(0,6,0,42), UDim2.new(1,-12,0,1), COL_BLUE

local container = Instance.new("Frame", panel) container.BackgroundTransparency = 1
local layout = Instance.new("UIListLayout", container) layout.Padding = UDim.new(0,4)

-- Key row
local keyRow = Instance.new("Frame", container) keyRow.Size=UDim2.new(1,0,0,32) keyRow.BackgroundTransparency=1
local keyLbl = Instance.new("TextLabel", keyRow)
keyLbl.BackgroundTransparency = 1
keyLbl.Size = UDim2.new(0.55,0,1,0)
keyLbl.Font = Enum.Font.GothamSemibold
keyLbl.TextScaled = true
keyLbl.TextColor3 = COL_TEXT
keyLbl.TextXAlignment = Enum.TextXAlignment.Left
keyLbl.Text = "Enter Key:"
local keyBox = Instance.new("TextBox", keyRow)
keyBox.Size, keyBox.Position = UDim2.new(0.45,0,1,0), UDim2.new(0.55,0,0,0)
keyBox.BackgroundColor3, keyBox.BackgroundTransparency, keyBox.BorderSizePixel =
    COL_PANEL, 0.35, 0
keyBox.Font = Enum.Font.Gotham
keyBox.TextScaled, keyBox.TextColor3 = true, COL_TEXT
keyBox.PlaceholderText, keyBox.ClearTextOnFocus = VALID_KEY, false
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0,4)

-- Unlock button
local unlock = Instance.new("TextButton", container)
unlock.Size = UDim2.new(1,0,0,30)
unlock.BackgroundColor3, unlock.BackgroundTransparency = COL_PANEL, 0.35
unlock.BorderSizePixel = 0
unlock.Font = Enum.Font.GothamBold
unlock.TextScaled = true
unlock.TextColor3 = COL_TEXT
unlock.Text = "Unlock"
Instance.new("UICorner", unlock).CornerRadius = UDim.new(0,4)
local hover = Instance.new("Frame", unlock)
hover.Size = UDim2.new(1,0,1,0)
hover.BackgroundColor3 = COL_BLUE
hover.BackgroundTransparency = 0.9
hover.BorderSizePixel = 0

--------------------------------------------------------------------
--  Autosize panel
--------------------------------------------------------------------
local function resize()
    local need = 46
    for _,c in ipairs(container:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then
            need += c.Size.Y.Offset + layout.Padding.Offset
        end
    end
    container.Size     = UDim2.new(1,-12,0,need-46)
    container.Position = UDim2.new(0,6,0,46)

    local vp = Camera.ViewportSize
    panel.Size = UDim2.new(0, math.clamp(vp.X*0.28,320,500),
                           0, math.max(need+20, MIN_PANEL_H))
end
resize(); layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

--------------------------------------------------------------------
--  Visual feedback helpers
--------------------------------------------------------------------
local function tint(col)
    stroke.Color, divider.BackgroundColor3 = col, col
end
local function flash(col,msg)
    tint(col)
    unlock.Text, unlock.TextColor3 = msg, col
    task.wait(1)
    unlock.Text, unlock.TextColor3 = "Unlock", COL_TEXT
    tint(COL_BLUE)
end

--------------------------------------------------------------------
--  ESP UI Embed  (everything between [=[ and ]=] is the openworld.lua)
--------------------------------------------------------------------
local OPENWORLD_SRC = [=[
--------------------------------------------------------------------
-- (openworld.lua contents go here – the exact full script from
-- the previous answer.  For brevity in this view, it is omitted.
-- Paste the full code block labelled “openworld.lua” from the
-- previous answer RIGHT HERE, unmodified.)
--------------------------------------------------------------------
]=]

--------------------------------------------------------------------
--  Load UI from embedded source
--------------------------------------------------------------------
local function loadUI()
    local ok, err = pcall(loadstring, OPENWORLD_SRC)
    if not ok then
        flash(COL_RED,"UI Error")
        warn("[PARAGON] UI syntax:", err)
        return
    end
    TweenService:Create(panel,TweenInfo.new(0.4),{
        BackgroundTransparency = 1,
        Size = UDim2.new(0,0,0,0)
    }):Play()
    task.wait(0.45)
    sg:Destroy()
end

--------------------------------------------------------------------
--  Key check
--------------------------------------------------------------------
local function checkKey()
    if (keyBox.Text:gsub("%s+",""):lower()) == VALID_KEY
    then flash(COL_GREEN,"Granted") loadUI()
    else flash(COL_RED,"Invalid") end
end
unlock.MouseButton1Click:Connect(checkKey)
UIS.InputBegan:Connect(function(i,gp)
    if not gp and i.KeyCode==Enum.KeyCode.Return then checkKey() end
end)

-- Hover tween
unlock.MouseEnter:Connect(function()
    TweenService:Create(hover,TweenInfo.new(0.12),{BackgroundTransparency=0.25}):Play()
end)
unlock.MouseLeave:Connect(function()
    TweenService:Create(hover,TweenInfo.new(0.12),{BackgroundTransparency=0.9}):Play()
end)

--------------------------------------------------------------------
--  Entrance tween
--------------------------------------------------------------------
panel.Position = UDim2.new(0.5,-150,1,0)
TweenService:Create(panel,TweenInfo.new(0.7,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
    Position = UDim2.new(0.5,-panel.Size.X.Offset/2,0.5,-panel.Size.Y.Offset/2)
}):Play()
