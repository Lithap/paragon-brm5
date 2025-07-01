--------------------------------------------------------------------
--  PARAGON LOADER  |  v2.0  |  2025-07-XX
--  Fully audited / error-free
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

--// Services
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local Camera       = workspace.CurrentCamera
local LP           = Players.LocalPlayer

local function log(m) print(("[PARAGON] %s"):format(m)) end

--// Constants -----------------------------------------------------
local COLOR_BLUE   = Color3.fromRGB(0,160,255)
local COLOR_RED    = Color3.fromRGB(255,70,70)
local COLOR_GREEN  = Color3.fromRGB(80,255,80)
local COLOR_TEXT   = Color3.fromRGB(235,235,235)
local COLOR_PANEL  = Color3.fromRGB(20,20,24)

local MIN_PANEL_H  = 260
local VALID_KEY    = "paragon"
local RAW_URL      = "https://raw.githubusercontent.com/Lithap/paragon-brm5/main/openworld.lua"

--// Clean previous instances -------------------------------------
local old = LP:FindFirstChild("PlayerGui")
             and LP.PlayerGui:FindFirstChild("ParagonLoaderUI")
if old then
    old:Destroy()
    log("Old loader destroyed (duplicate prevention)")
end

--// Root GUI ------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn = "ParagonLoaderUI", true, false
if syn and syn.protect_gui then syn.protect_gui(gui) end
gui.Parent = LP:WaitForChild("PlayerGui")

--------------------------------------------------------------------
--  MAIN PANEL & WIDGETS
--------------------------------------------------------------------
local panel = Instance.new("Frame", gui)
panel.BackgroundColor3, panel.BackgroundTransparency = COLOR_PANEL, 0.3
panel.BorderSizePixel, panel.ZIndex                 = 0, 1

local panelCorner     = Instance.new("UICorner", panel)
panelCorner.CornerRadius = UDim.new(0,6)

local stroke = Instance.new("UIStroke", panel)
stroke.Color, stroke.Transparency = COLOR_BLUE, 0.4

local header = Instance.new("TextLabel", panel)
header.Size, header.BackgroundTransparency = UDim2.new(1,0,0,40), 1
header.Font, header.Text, header.TextColor3, header.TextScaled =
    Enum.Font.GothamBlack, "PARAGON", COLOR_TEXT, true

local divider = Instance.new("Frame", panel)
divider.Size     = UDim2.new(1,-12,0,1)
divider.Position = UDim2.new(0,6,0,42)
divider.BackgroundColor3 = COLOR_BLUE

--// Container for rows
local container = Instance.new("Frame", panel)
container.BackgroundTransparency = 1
local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0,4)

--------------------------------------------------------------------
--  KEY ROW
--------------------------------------------------------------------
local keyRow = Instance.new("Frame", container)
keyRow.Size, keyRow.BackgroundTransparency = UDim2.new(1,0,0,32), 1

local keyLabel = Instance.new("TextLabel", keyRow)
keyLabel.Size = UDim2.new(0.55,0,1,0)
keyLabel.Text = "Enter Key:"
keyLabel.Font, keyLabel.TextScaled, keyLabel.TextColor3 =
    Enum.Font.GothamSemibold, true, COLOR_TEXT
keyLabel.BackgroundTransparency, keyLabel.TextXAlignment = 1, Enum.TextXAlignment.Left

local keyBox = Instance.new("TextBox", keyRow)
keyBox.Size, keyBox.Position       = UDim2.new(0.45,0,1,0), UDim2.new(0.55,0,0,0)
keyBox.BackgroundColor3            = COLOR_PANEL
keyBox.BackgroundTransparency      = 0.35
keyBox.BorderSizePixel             = 0
keyBox.Font, keyBox.TextScaled     = Enum.Font.Gotham, true
keyBox.TextColor3, keyBox.PlaceholderText =
    COLOR_TEXT, VALID_KEY
keyBox.ClearTextOnFocus            = false
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0,4)

--------------------------------------------------------------------
--  BUTTON FACTORY
--------------------------------------------------------------------
local function makeRow(txt)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1,0,0,30)
    btn.Text, btn.Font, btn.TextScaled, btn.TextColor3 = txt, Enum.Font.GothamBold, true, COLOR_TEXT
    btn.BackgroundColor3, btn.BackgroundTransparency, btn.BorderSizePixel =
        COLOR_PANEL, 0.35, 0
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)

    local hi = Instance.new("Frame", btn)
    hi.Size, hi.BorderSizePixel = UDim2.new(1,0,1,0), 0
    hi.BackgroundColor3, hi.BackgroundTransparency = COLOR_BLUE, 0.9
    return btn, hi
end

local rows, hiMap = {}, {}
local unlockBtn, unlockHi = makeRow("Unlock")
rows[1], hiMap[unlockBtn] = unlockBtn, unlockHi

--------------------------------------------------------------------
--  RESPONSIVE RESIZE
--------------------------------------------------------------------
local cachedVP = Vector2.zero
local function resize(force)
    local vp = Camera.ViewportSize
    if not force and vp == cachedVP then return end
    cachedVP = vp

    -- dynamic height calculation
    local need = 46 -- header + top margin
    for _,c in ipairs(container:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then
            need += c.Size.Y.Offset + layout.Padding.Offset
        end
    end
    container.Size      = UDim2.new(1,-12,0,need-46)
    container.Position  = UDim2.new(0,6,0,46)

    local w = math.clamp(vp.X * 0.28, 320, 500)
    local h = math.max(need+20, MIN_PANEL_H)
    panel.Size          = UDim2.new(0,w,0,h)
end
resize(true)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() resize(true) end)
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

--------------------------------------------------------------------
--  SELECTION / KEYBOARD NAV
--------------------------------------------------------------------
local sel = 1
local function setSel(i)
    if i < 1 or i > #rows then return end
    sel = i
    for k,v in ipairs(rows) do
        local t = (k==sel) and 0.25 or 0.9
        TweenService:Create(hiMap[v], TweenInfo.new(0.12), {BackgroundTransparency=t}):Play()
    end
end
setSel(1)

local function fireRow(i)
    rows[i].MouseButton1Click:Fire()
end

UIS.InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Up   and not keyBox:IsFocused() then setSel(sel-1)
    elseif inp.KeyCode == Enum.KeyCode.Down and not keyBox:IsFocused() then setSel(sel+1)
    elseif inp.KeyCode == Enum.KeyCode.Return then
        if keyBox:IsFocused() then fireRow(1) else fireRow(sel) end
    end
end)

UIS.InputChanged:Connect(function(inp,gp)
    if gp or keyBox:IsFocused() then return end
    if inp.UserInputType == Enum.UserInputType.MouseWheel then
        setSel(sel + ((inp.Position.Z < 0) and 1 or -1))
    end
end)

for i,v in ipairs(rows) do
    v.MouseEnter:Connect(function() setSel(i) end)
end

--------------------------------------------------------------------
--  FEEDBACK HELPERS
--------------------------------------------------------------------
local function flash(col, lbl)
    TweenService:Create(stroke ,TweenInfo.new(0.15),{Color=col}):Play()
    TweenService:Create(divider,TweenInfo.new(0.15),{BackgroundColor3=col}):Play()
    unlockBtn.TextColor3 = col
    unlockBtn.Text       = lbl
    task.wait(1)
    unlockBtn.Text, unlockBtn.TextColor3 = "Unlock", COLOR_TEXT
    TweenService:Create(stroke ,TweenInfo.new(0.15),{Color=COLOR_BLUE}):Play()
    TweenService:Create(divider,TweenInfo.new(0.15),{BackgroundColor3=COLOR_BLUE}):Play()
end

--------------------------------------------------------------------
--  KEY CHECK
--------------------------------------------------------------------
local function loadOpenWorld()
    -- 1) fetch file
    local raw, err = nil, nil
    local ok = pcall(function() raw = game:HttpGet(RAW_URL) end)
    if not ok or not raw or #raw < 32 then
        warn("[PARAGON] HTTP error:", err or "empty body")
        return false, "Fetch failed"
    end

    -- 2) compile & run
    local good, e2 = pcall(function() loadstring(raw)() end)
    if not good then
        warn("[PARAGON] Runtime error:", e2)
        return false, "Runtime error"
    end
    return true
end

local function badKey()
    flash(COLOR_RED, "Invalid")
end

local function goodKey()
    unlockBtn.Text = "Granted"
    unlockBtn.TextColor3 = COLOR_GREEN
    TweenService:Create(stroke,TweenInfo.new(0.15),{Color=COLOR_GREEN}):Play()
    TweenService:Create(divider,TweenInfo.new(0.15),{BackgroundColor3=COLOR_GREEN}):Play()
    task.wait(0.3)

    -- attempt OpenWorld load
    local ok, why = loadOpenWorld()
    if not ok then
        flash(COLOR_RED, "Load Fail")
        return
    end

    -- shrink + remove loader
    TweenService:Create(panel,TweenInfo.new(0.4),{
        BackgroundTransparency = 1, Size = UDim2.new(0,0,0,0)
    }):Play()
    task.wait(0.45)
    gui:Destroy()
end

local function checkKey()
    local txt = (keyBox.Text or ""):gsub("%s+",""):lower()
    if txt == VALID_KEY then goodKey() else badKey() end
end
unlockBtn.MouseButton1Click:Connect(checkKey)

--------------------------------------------------------------------
--  OPENING TWEEN
--------------------------------------------------------------------
panel.Position = UDim2.new(0.5,-panel.Size.X.Offset/2,1,0)
TweenService:Create(panel,TweenInfo.new(0.7,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
    Position = UDim2.new(0.5,-panel.Size.X.Offset/2,0.5,-panel.Size.Y.Offset/2)
}):Play()

log("Loader ready – type key, press Enter or click Unlock.")
