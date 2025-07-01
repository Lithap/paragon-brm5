--------------------------------------------------------------------
-- PARAGON LOADER  •  clean compile, zero console errors
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

-- Services
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local Camera       = workspace.CurrentCamera
local LP           = Players.LocalPlayer
local GUI_PARENT   = LP:WaitForChild("PlayerGui")

-- Colours / constants
local COL_BLUE   = Color3.fromRGB(0,160,255)
local COL_RED    = Color3.fromRGB(255, 70, 70)
local COL_GREEN  = Color3.fromRGB(80,255,80)
local COL_TEXT   = Color3.fromRGB(235,235,235)
local COL_PANEL  = Color3.fromRGB(20,20,24)

local VALID_KEY  = "paragon"
local OPENWORLD  = "https://raw.githubusercontent.com/Lithap/paragon-brm5/main/openworld.lua"
local MIN_H      = 260

-- Remove any previous loader GUI
local old = GUI_PARENT:FindFirstChild("ParagonLoaderUI")
if old then old:Destroy() end

-- Root GUI
local sg = Instance.new("ScreenGui")
sg.Name, sg.IgnoreGuiInset, sg.ResetOnSpawn = "ParagonLoaderUI", true, false
if syn and syn.protect_gui then syn.protect_gui(sg) end
sg.Parent = GUI_PARENT

--------------------------------------------------------------------
-- Panel & widgets
--------------------------------------------------------------------
local panel = Instance.new("Frame", sg)
panel.BackgroundColor3, panel.BackgroundTransparency, panel.BorderSizePixel =
    COL_PANEL, 0.3, 0
panel.Position = UDim2.new(0.5, -160, 0.5, -MIN_H/2)
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,6)
local stroke = Instance.new("UIStroke", panel) stroke.Color = COL_BLUE

local header = Instance.new("TextLabel", panel)
header.Size, header.BackgroundTransparency = UDim2.new(1,0,0,40), 1
header.Font, header.TextScaled, header.TextColor3 =
    Enum.Font.GothamBlack, true, COL_TEXT
header.Text = "PARAGON"

local divider = Instance.new("Frame", panel)
divider.Position, divider.Size, divider.BackgroundColor3 =
    UDim2.new(0,6,0,42), UDim2.new(1,-12,0,1), COL_BLUE

local container = Instance.new("Frame", panel) container.BackgroundTransparency=1
local layout = Instance.new("UIListLayout", container) layout.Padding=UDim.new(0,4)

-- Key row
local keyRow = Instance.new("Frame", container) keyRow.Size=UDim2.new(1,0,0,32) keyRow.BackgroundTransparency=1
local keyLbl = Instance.new("TextLabel", keyRow)
keyLbl.Size=UDim2.new(0.55,0,1,0) keyLbl.BackgroundTransparency=1
keyLbl.Font=Enum.Font.GothamSemibold keyLbl.TextScaled=true keyLbl.TextColor3=COL_TEXT
keyLbl.Text = "Enter Key:" keyLbl.TextXAlignment = Enum.TextXAlignment.Left

local keyBox = Instance.new("TextBox", keyRow)
keyBox.Size, keyBox.Position = UDim2.new(0.45,0,1,0), UDim2.new(0.55,0,0,0)
keyBox.BackgroundColor3, keyBox.BackgroundTransparency, keyBox.BorderSizePixel =
    COL_PANEL, 0.35, 0
keyBox.Font, keyBox.TextScaled, keyBox.TextColor3 =
    Enum.Font.Gotham, true, COL_TEXT
keyBox.PlaceholderText, keyBox.ClearTextOnFocus = VALID_KEY, false
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0,4)

-- Unlock button
local unlock = Instance.new("TextButton", container)
unlock.Size=UDim2.new(1,0,0,30)
unlock.BackgroundColor3, unlock.BackgroundTransparency, unlock.BorderSizePixel =
    COL_PANEL, 0.35, 0
unlock.Font, unlock.TextScaled, unlock.TextColor3 =
    Enum.Font.GothamBold, true, COL_TEXT
unlock.Text = "Unlock"
Instance.new("UICorner", unlock).CornerRadius = UDim.new(0,4)
local hi = Instance.new("Frame", unlock)
hi.Size, hi.BackgroundColor3, hi.BackgroundTransparency = UDim2.new(1,0,1,0), COL_BLUE, 0.9
hi.BorderSizePixel = 0

--------------------------------------------------------------------
-- Dynamic resize
--------------------------------------------------------------------
local function resize()
    local need = 46
    for _,c in ipairs(container:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then
            need += c.Size.Y.Offset + layout.Padding.Offset
        end
    end
    container.Size      = UDim2.new(1,-12,0,need-46)
    container.Position  = UDim2.new(0,6,0,46)

    local vp = Camera.ViewportSize
    panel.Size = UDim2.new(0, math.clamp(vp.X*0.28,320,500), 0, math.max(need+20, MIN_H))
end
resize(); layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

--------------------------------------------------------------------
-- Feedback helpers
--------------------------------------------------------------------
local function flash(col, msg)
    stroke.Color, divider.BackgroundColor3 = col, col
    unlock.Text, unlock.TextColor3 = msg, col
    task.wait(1)
    unlock.Text, unlock.TextColor3 = "Unlock", COL_TEXT
    stroke.Color, divider.BackgroundColor3 = COL_BLUE, COL_BLUE
end

--------------------------------------------------------------------
-- Load UI
--------------------------------------------------------------------
local function loadUI()
    local src, err = nil, nil
    local ok = pcall(function() src = game:HttpGet(UI_URL, true) end)
    if not ok or not src then flash(COL_RED, "HTTP Fail") return end
    local run, runErr = pcall(loadstring, src)
    if not run then flash(COL_RED, "Load Err") warn(runErr) return end

    TweenService:Create(panel, TweenInfo.new(0.4), {
        BackgroundTransparency = 1,
        Size = UDim2.new(0,0,0,0)
    }):Play()
    task.wait(0.45)
    sg:Destroy()
end

--------------------------------------------------------------------
-- Key check
--------------------------------------------------------------------
local function checkKey()
    if (keyBox.Text:gsub("%s+",""):lower()) == VALID_KEY
    then flash(COL_GREEN,"Granted"); loadUI()
    else flash(COL_RED,"Invalid") end
end
unlock.MouseButton1Click:Connect(checkKey)
UIS.InputBegan:Connect(function(i,gp)
    if (not gp) and i.KeyCode==Enum.KeyCode.Return then checkKey() end
end)

-- Hover effect
unlock.MouseEnter:Connect(function()
    TweenService:Create(hi, TweenInfo.new(0.12), {BackgroundTransparency=0.25}):Play()
end)
unlock.MouseLeave:Connect(function()
    TweenService:Create(hi, TweenInfo.new(0.12), {BackgroundTransparency=0.9}):Play()
end)

--------------------------------------------------------------------
-- Entrance tween
--------------------------------------------------------------------
panel.Position = UDim2.new(0.5,-150,1,0)
TweenService:Create(panel,TweenInfo.new(0.7,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
    Position = UDim2.new(0.5,-panel.Size.X.Offset/2,0.5,-panel.Size.Y.Offset/2)
}):Play()
