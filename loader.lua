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
local OPENWORLD_SRC = --------------------------------------------------------------------
--  PARAGON OPEN WORLD  •  Advanced ESP + LOS + Client-Noclip
--  2025-07-XX
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

--------------------------------------------------------------------
--  Services
--------------------------------------------------------------------
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local LP           = Players.LocalPlayer
local Camera       = workspace.CurrentCamera
local PG           = LP:WaitForChild("PlayerGui")
local DRAWING_OK   = pcall(function() return Drawing end)

--------------------------------------------------------------------
--  Config
--------------------------------------------------------------------
local MAX_DIST  = 1500          -- ESP render distance
local TICK_HZ   = 20            -- refresh rate (Hz)
local BOX_PAD   = 0.05
local BAR_SIZE  = Vector2.new(50,4)
local TRACER_ORG= Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)

--------------------------------------------------------------------
--  UI colours
--------------------------------------------------------------------
local C_MAIN , C_ACC , C_TEXT = Color3.fromRGB(22,22,26), Color3.fromRGB(0,160,255), Color3.fromRGB(240,240,240)
local ICON_X = "✕"

--------------------------------------------------------------------
--  Global state
--------------------------------------------------------------------
local ESP_ON = false
local OPT = {
    box       = true,
    chams     = false,
    tracers   = false,
    distance  = false,
    health    = false,
    vischeck  = false,
    walkwalls = false,
}

--------------------------------------------------------------------
--  Caches (weak tables)
--------------------------------------------------------------------
local targets = {}  -- [Model] = {root = Part}
local pool    = {
    box       = setmetatable({}, {__mode="k"}),
    highlight = setmetatable({}, {__mode="k"}),
    tracer    = setmetatable({}, {__mode="k"}),
    label     = setmetatable({}, {__mode="k"}),
    health    = setmetatable({}, {__mode="k"}),
}

--------------------------------------------------------------------
--  Factory helpers
--------------------------------------------------------------------
local function getBox(part)
    local b = pool.box[part]
    if not b or b.Parent == nil then
        b = Instance.new("BoxHandleAdornment")
        b.AlwaysOnTop, b.ZIndex, b.Adornee = true, 5, part
        b.Parent = part
        pool.box[part] = b
    end
    return b
end

local function getHi(model)
    local h = pool.highlight[model]
    if not h or h.Parent == nil then
        h = Instance.new("Highlight")
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = model
        pool.highlight[model] = h
    end
    return h
end

local function getDraw(tbl, id, kind)
    if not DRAWING_OK then return end
    local o = tbl[id]
    if not o then o = Drawing.new(kind); tbl[id] = o end
    return o
end

local function hide(tbl, id) if tbl[id] then tbl[id].Visible = false end end
local function hpColor(f) return Color3.fromRGB((1-f)*255, f*255, 0) end

local function lineOfSight(part)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances = { LP.Character or Instance.new("Folder") }
    local hit = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rp)
    return (not hit) or hit.Instance:IsDescendantOf(part.Parent)
end

--------------------------------------------------------------------
--  NPC detection
--------------------------------------------------------------------
local function isEnemy(m)
    if not (m:IsA("Model") and m.Name == "Male") then return false end
    for _,c in ipairs(m:GetChildren()) do
        if c.Name:sub(1,3) == "AI_" then return true end
    end
    return false
end

local function register(m)
    if targets[m] then return end
    local root = m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso")
    if root then targets[m] = {root = root} end
end

for _,d in ipairs(workspace:GetDescendants()) do if isEnemy(d) then register(d) end end
workspace.DescendantAdded:Connect(function(d) if isEnemy(d) then task.wait(); register(d) end end)
workspace.DescendantRemoving:Connect(function(d) targets[d] = nil end)

--------------------------------------------------------------------
--  Main ESP loop
--------------------------------------------------------------------
local acc = 0
RunService.RenderStepped:Connect(function(dt)
    if not ESP_ON then return end
    acc += dt; if acc < 1/TICK_HZ then return end; acc = 0

    local camPos = Camera.CFrame.Position

    for model, t in pairs(targets) do
        if not model.Parent then targets[model] = nil continue end
        local root = t.root
        if not root then continue end

        local dist = (root.Position - camPos).Magnitude
        if dist > MAX_DIST then
            hide(pool.tracer,model); hide(pool.label,model); hide(pool.health,model)
            if pool.box[root] then pool.box[root].Transparency = 1 end
            if pool.highlight[model] then pool.highlight[model].Enabled = false end
            continue
        end

        local v2, onScreen = Camera:WorldToViewportPoint(root.Position)
        local vis = (not OPT.vischeck) or lineOfSight(root)

        -- BOX
        if OPT.box and onScreen then
            local b = getBox(root)
            b.Size         = root.Size + Vector3.new(BOX_PAD,BOX_PAD,BOX_PAD)
            b.Transparency = 0.25
            b.Color3       = vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
        elseif pool.box[root] then pool.box[root].Transparency = 1 end

        -- CHAMS
        if OPT.chams then
            local h = getHi(model)
            h.Enabled             = true
            h.FillColor           = vis and Color3.fromRGB(255,75,75) or Color3.fromRGB(0,190,255)
            h.FillTransparency    = 0.15
            h.OutlineColor        = h.FillColor
            h.OutlineTransparency = 0.1
        elseif pool.highlight[model] then
            pool.highlight[model].Enabled = false
        end

        if DRAWING_OK then
            -- TRACER
            if OPT.tracers and onScreen then
                local tr = getDraw(pool.tracer, model, "Line")
                tr.Visible, tr.Thickness = true, 1.5
                tr.Color = vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,255,0)
                tr.From, tr.To = TRACER_ORG, Vector2.new(v2.X, v2.Y)
            else hide(pool.tracer, model) end

            -- DISTANCE
            if OPT.distance and onScreen then
                local lb = getDraw(pool.label, model, "Text")
                lb.Visible, lb.Center, lb.Outline, lb.Size = true, true, true, 14
                lb.Color, lb.Text = Color3.new(1,1,1), ("%.0f"):format(dist)
                lb.Position = Vector2.new(v2.X, v2.Y - 16)
            else hide(pool.label, model) end

            -- HEALTH
            if OPT.health and onScreen then
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum then
                    local frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local hb = getDraw(pool.health, model, "Square")
                    hb.Visible, hb.Filled = true, true
                    hb.Size     = BAR_SIZE * Vector2.new(frac,1)
                    hb.Position = Vector2.new(v2.X - BAR_SIZE.X/2, v2.Y + 12)
                    hb.Color    = hpColor(frac)
                end
            else hide(pool.health, model) end
        end
    end
end)

local function clearESP()
    for _,b in pairs(pool.box) do b.Transparency = 1 end
    for _,h in pairs(pool.highlight) do h.Enabled = false end
    if DRAWING_OK then
        for _,tbl in ipairs{pool.tracer,pool.label,pool.health} do
            for _,o in pairs(tbl) do o.Visible = false end
        end
    end
end

--------------------------------------------------------------------
--  Noclip helper
--------------------------------------------------------------------
local function applyCollide(on)
    if LP.Character then
        for _,p in ipairs(LP.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = on; p.Massless = not on end
        end
    end
end
local function toggleNoClip(on) applyCollide(not on) end
LP.CharacterAdded:Connect(function(c)
    c:WaitForChild("HumanoidRootPart",6)
    if OPT.walkwalls then applyCollide(false) end
end)
RunService.Heartbeat:Connect(function()
    if OPT.walkwalls and LP.Character then
        for _,p in ipairs(LP.Character:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide = false; p.Massless = true
            end
        end
    end
end)

--------------------------------------------------------------------
--  GUI (panel + toggles + slide key)
--------------------------------------------------------------------
-- kill duplicate panel
local old = PG:FindFirstChild("ParagonMainUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui", PG)
gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn = "ParagonMainUI", true, false
if syn and syn.protect_gui then syn.protect_gui(gui) end

local frame = Instance.new("Frame", gui)
frame.AnchorPoint = Vector2.new(0,0.5)
frame.Size        = UDim2.new(0,270,0,340)
frame.Position    = UDim2.new(0,-280,0.5,0)
frame.BackgroundColor3, frame.BackgroundTransparency = C_MAIN, 0.2
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke", frame).Color = C_ACC

local head = Instance.new("TextLabel", frame)
head.Size = UDim2.new(1,0,0,40)
head.BackgroundTransparency = 1
head.Font = Enum.Font.GothamBlack
head.Text = "PARAGON ESP"
head.TextScaled = true
head.TextColor3 = C_TEXT
head.TextStrokeTransparency = 0.85

local div = Instance.new("Frame", frame)
div.Position, div.Size, div.BackgroundColor3 =
    UDim2.new(0,8,0,42), UDim2.new(1,-16,0,1), C_ACC

local body = Instance.new("Frame", frame)
body.Position, body.Size = UDim2.new(0,8,0,50), UDim2.new(1,-16,1,-58)
body.BackgroundTransparency = 1
local list = Instance.new("UIListLayout", body)
list.Padding = UDim.new(0,6)
list.HorizontalAlignment, list.VerticalAlignment = Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top

local function makeToggle(txt, key, cb)
    local btn = Instance.new("TextButton", body)
    btn.Size = UDim2.new(1,0,0,32)
    btn.BackgroundColor3, btn.BackgroundTransparency = C_MAIN, 0.15
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local name = Instance.new("TextLabel", btn)
    name.BackgroundTransparency = 1
    name.Size, name.Position = UDim2.new(1,-28,1,0), UDim2.new(0,6,0,0)
    name.Font = Enum.Font.GothamSemibold
    name.TextScaled, name.TextColor3, name.TextXAlignment = true, C_TEXT, Enum.TextXAlignment.Left
    name.Text = txt

    local ico = Instance.new("TextLabel", btn)
    ico.BackgroundTransparency = 1
    ico.Size, ico.Position = UDim2.new(0,22,0,22), UDim2.new(1,-26,0.5,-11)
    ico.Font, ico.TextScaled, ico.Text = Enum.Font.GothamBold, true, ICON_X

    local st = Instance.new("UIStroke", btn) st.Color, st.Transparency = C_ACC, 0.8

    local function refresh()
        local flag = (key == "master" and ESP_ON) or OPT[key]
        ico.TextColor3 = flag and Color3.fromRGB(0,255,80) or Color3.fromRGB(180,180,180)
    end
    refresh()

    btn.MouseEnter:Connect(function() TweenService:Create(st,TweenInfo.new(0.15),{Transparency=0.2}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(st,TweenInfo.new(0.15),{Transparency=0.8}):Play() end)

    btn.MouseButton1Click:Connect(function()
        if key == "master" then
            ESP_ON = not ESP_ON
            if not ESP_ON then clearESP() end
        else
            OPT[key] = not OPT[key]
            if key == "walkwalls" then toggleNoClip(OPT.walkwalls) end
        end
        refresh()
        if cb then cb(OPT[key]) end
    end)
end

makeToggle("ESP Master",       "master")
makeToggle("3D Box",           "box")
makeToggle("Chams",            "chams")
makeToggle("Tracers",          "tracers")
makeToggle("Distance",         "distance")
makeToggle("Health Bar",       "health")
makeToggle("VisCheck (LOS)",   "vischeck")
makeToggle("Walk Through Walls","walkwalls", toggleNoClip)

-- slide hotkey
local open=false
local function slide()
    open = not open
    local y = -frame.AbsoluteSize.Y/2
    local tgt = open and UDim2.new(0,10,0.5,y) or UDim2.new(0,-frame.AbsoluteSize.X-10,0.5,y)
    TweenService:Create(frame,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=tgt}):Play()
end
UIS.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode==Enum.KeyCode.BackSlash then slide() end end)
slide()  -- open panel on load


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
