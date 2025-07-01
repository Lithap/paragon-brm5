
if not game:IsLoaded() then game.Loaded:Wait() end

--------------------------------------------------------------------
-- ░█▀▀░█▀█░█▀▄░█▀█░█▀▀░█▀▄  –  Services & locals
--------------------------------------------------------------------
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local LP           = Players.LocalPlayer
local Camera       = workspace.CurrentCamera
local PG           = LP:WaitForChild("PlayerGui")

-- destroy previous instance
local pre = PG:FindFirstChild("ParagonMainUI")
if pre then pre:Destroy() end

--------------------------------------------------------------------
-- ░█▄█░█▀█░█▀▄░█▀▄░█▀▀   –  Config
--------------------------------------------------------------------
local MAX_DISTANCE    = 600      -- studs to render ESP
local UPDATE_HZ       = 20       -- ESP refresh rate
local BOX_PADDING     = 0.05
local TRACER_ORIGIN   = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
local HEALTH_BAR_SIZE = Vector2.new(50,4)

--------------------------------------------------------------------
-- ░█▀▀░█░█░█▀▄░█▀▄░█▀▀   –  State & pools
--------------------------------------------------------------------
local ESP_ENABLED = false
local OPTIONS = {
    box       = true,
    chams     = false,
    tracers   = false,
    distance  = false,
    health    = false,
    walkwalls = false,
}

local ICON_X = "✕"           -- unicode char used as status icon

local targets = {}            -- tracked NPCs   [Model] = {root = Part}

-- drawing pools (weak‐key)
local pool = {
    box       = setmetatable({}, {__mode="k"}),
    highlight = setmetatable({}, {__mode="k"}),
    tracer    = setmetatable({}, {__mode="k"}),
    label     = setmetatable({}, {__mode="k"}),
    health    = setmetatable({}, {__mode="k"}),
}

local DRAWING_OK = pcall(function() return Drawing end)

--------------------------------------------------------------------
-- ░█▀▄░█░█░█▀▀  –  Factory helpers
--------------------------------------------------------------------
local function getHighlight(model)
    local h = pool.highlight[model]
    if not h or h.Parent == nil then
        h = Instance.new("Highlight")
        h.DepthMode, h.FillTransparency, h.OutlineTransparency =
            Enum.HighlightDepthMode.AlwaysOnTop, 0.55, 1
        h.Parent = model
        pool.highlight[model] = h
    end
    return h
end

local function getBox(part)
    local b = pool.box[part]
    if not b or b.Parent == nil then
        b = Instance.new("BoxHandleAdornment")
        b.Adornee, b.ZIndex, b.AlwaysOnTop = part, 5, true
        b.Parent = part
        pool.box[part] = b
    end
    return b
end

local function getDrawing(tbl, id, typ)
    if not DRAWING_OK then return end
    local obj = tbl[id]
    if not obj then
        obj = Drawing.new(typ)
        tbl[id] = obj
    end
    return obj
end

local function hideDrawing(tbl, id)
    if tbl[id] then tbl[id].Visible = false end
end

local function colourLerp(ratio)
    return Color3.fromRGB((1-ratio)*255, ratio*255, 0)
end

--------------------------------------------------------------------
-- ░█▀█░█▀█░█▀▀  –  NPC acquisition
--------------------------------------------------------------------
local function isEnemy(model)
    if not (model and model:IsA("Model") and model.Name=="Male") then return false end
    for _,c in ipairs(model:GetChildren()) do
        if c.Name:sub(1,3)=="AI_" then return true end
    end
    return false
end

local function track(model)
    if targets[model] then return end
    local head = model:FindFirstChild("Head") or model:FindFirstChild("UpperTorso")
    if head then targets[model]={root=head} end
end

for _,d in ipairs(workspace:GetDescendants()) do
    if isEnemy(d) then track(d) end
end
workspace.DescendantAdded:Connect(function(d)
    if isEnemy(d) then task.wait(); track(d) end
end)
workspace.DescendantRemoving:Connect(function(d) targets[d]=nil end)

--------------------------------------------------------------------
-- ░█▀▄░█▀▀░█▀▀  –  ESP update loop
--------------------------------------------------------------------
local dtAcc = 0
RunService.RenderStepped:Connect(function(dt)
    if not ESP_ENABLED then return end
    dtAcc += dt
    if dtAcc < 1/UPDATE_HZ then return end
    dtAcc = 0

    local camPos = Camera.CFrame.Position

    for model,t in pairs(targets) do
        if not model.Parent then targets[model]=nil continue end
        local root = t.root
        if not root then continue end

        local distance = (root.Position - camPos).Magnitude
        if distance > MAX_DISTANCE then
            -- hide everything for this model
            hideDrawing(pool.tracer, model)
            hideDrawing(pool.label,  model)
            hideDrawing(pool.health, model)
            if pool.highlight[model] then pool.highlight[model].Enabled=false end
            if pool.box[root] then pool.box[root].Transparency = 1 end
            continue
        end

        local onScreen, screenPos = Camera:WorldToViewportPoint(root.Position)

        -- BOX
        if OPTIONS.box and onScreen then
            local box = getBox(root)
            box.Size         = root.Size + Vector3.new(BOX_PADDING,BOX_PADDING,BOX_PADDING)
            box.Color3       = Color3.fromRGB(0,255,0)
            box.Transparency = 0.25
        elseif pool.box[root] then pool.box[root].Transparency = 1 end

        -- CHAMS
        if OPTIONS.chams then
            local hi = getHighlight(model)
            hi.FillColor = onScreen and Color3.fromRGB(0,190,255) or Color3.fromRGB(255,60,60)
            hi.Enabled   = true
        elseif pool.highlight[model] then
            pool.highlight[model].Enabled = false
        end

        -- TRACER
        if DRAWING_OK then
            if OPTIONS.tracers and onScreen then
                local tr = getDrawing(pool.tracer, model, "Line")
                tr.Visible      = true
                tr.Thickness    = 1.5
                tr.Color        = Color3.fromRGB(255,255,0)
                tr.From, tr.To  = TRACER_ORIGIN, Vector2.new(screenPos.X, screenPos.Y)
            else hideDrawing(pool.tracer, model) end

            -- DISTANCE LABEL
            if OPTIONS.distance and onScreen then
                local lab = getDrawing(pool.label, model, "Text")
                lab.Visible   = true
                lab.Center    = true
                lab.Outline   = true
                lab.Size      = 14
                lab.Color     = Color3.new(1,1,1)
                lab.Position  = Vector2.new(screenPos.X, screenPos.Y-16)
                lab.Text      = ("%.0f"):format(distance)
            else hideDrawing(pool.label, model) end

            -- HEALTH BAR
            if OPTIONS.health and onScreen then
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum then
                    local frac = math.clamp(hum.Health/hum.MaxHealth,0,1)
                    local hb   = getDrawing(pool.health, model, "Square")
                    hb.Visible   = true
                    hb.Filled    = true
                    hb.Size      = HEALTH_BAR_SIZE * Vector2.new(frac,1)
                    hb.Position  = Vector2.new(screenPos.X-HEALTH_BAR_SIZE.X/2, screenPos.Y+12)
                    hb.Color     = colourLerp(frac)
                end
            else hideDrawing(pool.health, model) end
        end
    end
end)

--------------------------------------------------------------------
-- ░█▀▀░█░█░█▀▄  –  Disable all visuals helper
--------------------------------------------------------------------
local function disableAll()
    for _,b in pairs(pool.box)       do b.Transparency = 1 end
    for _,h in pairs(pool.highlight) do h.Enabled = false end
    if DRAWING_OK then
        for _,tbl in pairs{pool.tracer,pool.label,pool.health} do
            for _,obj in pairs(tbl) do obj.Visible = false end
        end
    end
end

--------------------------------------------------------------------
-- ░█▀█░▄▀▄░█▀▀  –  Walk-Through-Walls helpers
--------------------------------------------------------------------
local function applyNoClip(char, state)
    for _,p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") then p.CanCollide = not state end
    end
end

local function setNoClip(state)
    if LP.Character then applyNoClip(LP.Character, state) end
    if not setNoClip._hooked then
        LP.CharacterAdded:Connect(function(c) applyNoClip(c, OPTIONS.walkwalls) end)
        setNoClip._hooked = true
    end
end

--------------------------------------------------------------------
-- ░█▀█░█▀█░█░█   –  GUI  (left panel)
--------------------------------------------------------------------
local C_MAIN, C_ACCENT, C_TEXT = Color3.fromRGB(22,22,26), Color3.fromRGB(0,160,255), Color3.fromRGB(240,240,240)

local root = Instance.new("ScreenGui", PG)
root.Name, root.IgnoreGuiInset, root.ResetOnSpawn = "ParagonMainUI", true, false
if syn and syn.protect_gui then syn.protect_gui(root) end

local frame = Instance.new("Frame", root)
frame.AnchorPoint = Vector2.new(0,0.5)
frame.Size        = UDim2.new(0,260,0,280)
frame.Position    = UDim2.new(0,-frame.Size.X.Offset-10,0.5,0)
frame.BackgroundColor3, frame.BackgroundTransparency = C_MAIN, 0.2
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
local st = Instance.new("UIStroke", frame) st.Color, st.Transparency = C_ACCENT, 0.4

local hd = Instance.new("TextLabel", frame)
hd.Size, hd.BackgroundTransparency = UDim2.new(1,0,0,40), 1
hd.Font, hd.Text, hd.TextColor3, hd.TextScaled = Enum.Font.GothamBlack, "PARAGON ESP", C_TEXT, true
hd.TextStrokeTransparency = 0.85

local div = Instance.new("Frame", frame)
div.Position, div.Size, div.BackgroundColor3 = UDim2.new(0,8,0,42), UDim2.new(1,-16,0,1), C_ACCENT

local container = Instance.new("Frame", frame)
container.Position, container.Size, container.BackgroundTransparency = UDim2.new(0,8,0,50), UDim2.new(1,-16,1,-58), 1
local list = Instance.new("UIListLayout", container)
list.Padding, list.FillDirection = UDim.new(0,6), Enum.FillDirection.Vertical
list.HorizontalAlignment, list.VerticalAlignment = Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top

--------------------------------------------------------------------
-- ░█░█░█▀█░█▀█  –  Toggle factory (with status ✕)
--------------------------------------------------------------------
local function makeToggle(label, key, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1,0,0,32)
    btn.BackgroundColor3, btn.BackgroundTransparency, btn.BorderSizePixel = C_MAIN, 0.15, 0
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local txt = Instance.new("TextLabel", btn)
    txt.BackgroundTransparency = 1
    txt.Size, txt.Position = UDim2.new(1,-28,1,0), UDim2.new(0,6,0,0)
    txt.Font, txt.TextXAlignment, txt.TextColor3, txt.TextScaled =
        Enum.Font.GothamSemibold, Enum.TextXAlignment.Left, C_TEXT, true
    txt.Text = label

    local ico = Instance.new("TextLabel", btn)
    ico.BackgroundTransparency = 1
    ico.Size, ico.Position = UDim2.new(0,22,0,22), UDim2.new(1,-26,0.5,-11)
    ico.Font, ico.TextScaled, ico.Text = Enum.Font.GothamBold, true, ICON_X

    local hi = Instance.new("UIStroke", btn) hi.Color, hi.Transparency = C_ACCENT, 0.8

    local function refresh()
        local on = (key=="master" and ESP_ENABLED) or OPTIONS[key]
        ico.TextColor3 = on and Color3.fromRGB(0,255,80) or Color3.fromRGB(180,180,180)
    end
    refresh()

    btn.MouseEnter:Connect(function()
        TweenService:Create(hi,TweenInfo.new(0.15),{Transparency=0.2}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(hi,TweenInfo.new(0.15),{Transparency=0.8}):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        if key=="master" then
            ESP_ENABLED = not ESP_ENABLED
            if not ESP_ENABLED then disableAll() end
        else
            OPTIONS[key] = not OPTIONS[key]
            if key=="walkwalls" then setNoClip(OPTIONS.walkwalls) end
        end
        refresh()
        if callback then callback(OPTIONS[key]) end
    end)
end

--------------------------------------------------------------------
-- ░█░█░█▀█░█▀█  –  Build menu
--------------------------------------------------------------------
makeToggle("ESP Master",  "master")
makeToggle("3D Box",      "box")
makeToggle("Chams",       "chams")
makeToggle("Tracers",     "tracers")
makeToggle("Distance",    "distance")
makeToggle("Health Bar",  "health")
makeToggle("Walk Through Walls", "walkwalls", setNoClip)

--------------------------------------------------------------------
-- ░█▄█░█▀█░█▀▄   –  Slide panel toggle  (`\`)
--------------------------------------------------------------------
local open, margin = false, 10
local function slide()
    open = not open
    local y = -frame.AbsoluteSize.Y/2
    local tgt = open and UDim2.new(0,margin,0.5,y) or UDim2.new(0,-frame.AbsoluteSize.X-margin,0.5,y)
    TweenService:Create(frame,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
        {Position = tgt}):Play()
end
UIS.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode==Enum.KeyCode.BackSlash then slide() end end)
slide() -- open at start
