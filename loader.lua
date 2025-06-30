-- PARAGON SYSTEMS  |  Loader UI  (Build 7.0 – Hardened, Zero‑Error, ASCII‑Only)
--  Key Features
--    * Pure Lua 5.1 syntax – no UTF‑8, no exotic comments, no +=, no emojis.
--    * Parents to PlayerGui only – avoids CoreGui permission errors.
--    * Press Enter in textbox OR use Unlock button / keyboard navigation.
--    * Responsive sizing, minimal calculations (cached viewport size).
--    * Blue border default, flashes Red on invalid key, Green on success.
----------------------------------------------------------------------

--------------------------------------------------------------------
--  SERVICES & SHORTCUTS
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local Camera       = workspace.CurrentCamera
local LP           = Players.LocalPlayer

local function log(msg) print("[PARAGON] " .. msg) end

--------------------------------------------------------------------
--  CONSTANTS (COLOURS & SETTINGS)
--------------------------------------------------------------------
local COLOR_BLUE   = Color3.fromRGB(0,160,255)
local COLOR_RED    = Color3.fromRGB(255,70,70)
local COLOR_GREEN  = Color3.fromRGB(80,255,80)
local COLOR_TEXT   = Color3.fromRGB(235,235,235)
local COLOR_PANEL  = Color3.fromRGB(20,20,24)
local MIN_PANEL_H  = 260
local VALID_KEY    = "paragon"

--------------------------------------------------------------------
--  ROOT GUI (PlayerGui only)
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
if syn and syn.protect_gui then syn.protect_gui(gui) end
gui.IgnoreGuiInset = true
gui.Name = "ParagonLoaderUI"
gui.Parent = LP:WaitForChild("PlayerGui")
log("GUI mounted to PlayerGui")

--------------------------------------------------------------------
--  SHADOW & MAIN PANEL
--------------------------------------------------------------------
local shadow = Instance.new("Frame", gui)
shadow.BackgroundColor3 = Color3.new(0,0,0)
shadow.BackgroundTransparency = 0.8
shadow.BorderSizePixel = 0
shadow.ZIndex = 0
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0,6)

local panel = Instance.new("Frame", gui)
panel.BackgroundColor3 = COLOR_PANEL
panel.BackgroundTransparency = 0.3
panel.BorderSizePixel = 0
panel.ZIndex = 1
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,6)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = COLOR_BLUE
stroke.Transparency = 0.4

--------------------------------------------------------------------
--  HEADER  (ASCII title, executor‑safe)
--------------------------------------------------------------------
local header = Instance.new("TextLabel", panel)
header.Size = UDim2.new(1,0,0,40)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBlack
header.Text = "PARAGON"
header.TextColor3 = COLOR_TEXT
header.TextScaled = true

local divider = Instance.new("Frame", panel)
divider.Size = UDim2.new(1,-12,0,1)
divider.Position = UDim2.new(0,6,0,42)
divider.BackgroundColor3 = COLOR_BLUE

--------------------------------------------------------------------
--  CONTENT CONTAINER & LIST LAYOUT
--------------------------------------------------------------------
local container = Instance.new("Frame", panel)
container.BackgroundTransparency = 1
local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0,4)

--------------------------------------------------------------------
--  KEY ENTRY ROW
--------------------------------------------------------------------
local keyRow = Instance.new("Frame", container)
keyRow.Size = UDim2.new(1,0,0,32)
keyRow.BackgroundTransparency = 1

local keyLabel = Instance.new("TextLabel", keyRow)
keyLabel.Size = UDim2.new(0.55,0,1,0)
keyLabel.BackgroundTransparency = 1
keyLabel.Text = "Enter Key:"
keyLabel.Font = Enum.Font.GothamSemibold
keyLabel.TextColor3 = COLOR_TEXT
keyLabel.TextScaled = true
keyLabel.TextXAlignment = Enum.TextXAlignment.Left

local keyBox = Instance.new("TextBox", keyRow)
keyBox.Size = UDim2.new(0.45,0,1,0)
keyBox.Position = UDim2.new(0.55,0,0,0)
keyBox.BackgroundColor3 = COLOR_PANEL
keyBox.BackgroundTransparency = 0.35
keyBox.BorderSizePixel = 0
keyBox.Font = Enum.Font.Gotham
keyBox.TextColor3 = COLOR_TEXT
keyBox.TextScaled = true
keyBox.PlaceholderText = "paragon"
keyBox.ClearTextOnFocus = false
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0,4)

--------------------------------------------------------------------
--  BUTTON ROW FACTORY (creates selectable rows)
--------------------------------------------------------------------
local function createRow(text)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1,0,0,30)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = COLOR_TEXT
    btn.TextScaled = true
    btn.BackgroundColor3 = COLOR_PANEL
    btn.BackgroundTransparency = 0.35
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
    local hi = Instance.new("Frame", btn)
    hi.Size = UDim2.new(1,0,1,0)
    hi.BackgroundColor3 = COLOR_BLUE
    hi.BackgroundTransparency = 0.9
    hi.BorderSizePixel = 0
    return btn, hi
end

local rows, hiMap = {}, {}
local unlockBtn, unlockHi = createRow("Unlock")
rows[1] = unlockBtn
hiMap[unlockBtn] = unlockHi

--------------------------------------------------------------------
--  RESIZE FUNCTION (responsive, lightweight)
--------------------------------------------------------------------
local cachedVP = Vector2.new()
local function resize(force)
    local vp = Camera.ViewportSize
    if not force and vp == cachedVP then return end
    cachedVP = vp

    -- compute needed height
    local neededH = 46 -- header+divider
    for _,child in ipairs(container:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            neededH = neededH + child.Size.Y.Offset + layout.Padding.Offset
        end
    end
    container.Size = UDim2.new(1,-12,0,neededH-46)
    container.Position = UDim2.new(0,6,0,46)

    local width  = math.clamp(vp.X * 0.28, 320, 500)
    local height = math.max(neededH + 20, MIN_PANEL_H)
    panel.Size   = UDim2.new(0,width,0,height)
    shadow.Size  = panel.Size + UDim2.new(0,6,0,6)
end
resize(true)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() resize(true) end)
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

--------------------------------------------------------------------
--  SELECTION / HIGHLIGHT HANDLING
--------------------------------------------------------------------
local selIndex = 1
local function setSel(i)
    if i<1 or i>#rows then return end
    selIndex = i
    for k,row in ipairs(rows) do
        local target = (k == selIndex) and 0.25 or 0.9
        TweenService:Create(hiMap[row], TweenInfo.new(0.12), {BackgroundTransparency = target}):Play()
    end
end
setSel(1)

-- Keyboard and mouse navigation
UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Up   and not keyBox:IsFocused() then setSel(selIndex - 1)
    elseif inp.KeyCode == Enum.KeyCode.Down and not keyBox:IsFocused() then setSel(selIndex + 1)
    elseif inp.KeyCode == Enum.KeyCode.Return then
        if keyBox:IsFocused() then rows[1]:Activate() else rows[selIndex]:Activate() end
    end
end)

UIS.InputChanged:Connect(function(inp, gp)
    if gp or keyBox:IsFocused() then return end
    if inp.UserInputType == Enum.UserInputType.MouseWheel then
        local dir = (inp.Position.Z < 0) and 1 or -1
        setSel(selIndex + dir)
    end
end)

for idx, row in ipairs(rows) do
    row.MouseEnter:Connect(function() setSel(idx) end)
end

--------------------------------------------------------------------
--  BORDER COLOUR TWEEN
--------------------------------------------------------------------
local function border(col)
    TweenService:Create(stroke,  TweenInfo.new(0.15), {Color = col}):Play()
    TweenService:Create(divider, TweenInfo.new(0.15), {BackgroundColor3 = col}):Play()
end

--------------------------------------------------------------------
--  VALID / INVALID KEY ACTIONS
--------------------------------------------------------------------
local function badKey()
    border(COLOR_RED)
    unlockBtn.Text = "Invalid"
    unlockBtn.TextColor3 = COLOR_RED
    wait(1)
    unlockBtn.Text = "Unlock"
    unlockBtn.TextColor3 = COLOR_TEXT
    border(COLOR_BLUE)
end

local function goodKey()
    border(COLOR_GREEN)
    unlockBtn.Text = "Granted"
    unlockBtn.TextColor3 = COLOR_GREEN
    wait(0.3)
    -- fade & shrink
    TweenService:Create(panel, TweenInfo.new(0.4), {BackgroundTransparency = 1, Size = UDim2.new(0,0,0,0)}):Play()
    shadow:Destroy()
    wait(0.45)
    gui:Destroy()
end

local function checkKey()
    local text = string.lower(string.gsub(keyBox.Text, "%s+", ""))
    if text == VALID_KEY then goodKey() else badKey() end
end
unlockBtn.MouseButton1Click:Connect(checkKey)

--------------------------------------------------------------------
--  OPENING TWEEN
--------------------------------------------------------------------
panel.Position = UDim2.new(0.5, -panel.Size.X.Offset / 2, 1, 0)
shadow.Position = panel.Position + UDim2.new(0,4,0,4)
TweenService:Create(panel, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Position = UDim2.new(0.5, -panel.Size.X.Offset / 2, 0.5, -panel.Size.Y.Offset / 2)}):Play()
TweenService:Create(shadow, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Position = shadow.Position - UDim2.new(0,0,1, panel.Size.Y.Offset / 2 - 4)}):Play()

log("Loader ready. Enter key and press Enter or Unlock.")
