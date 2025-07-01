
if not game:IsLoaded() then game.Loaded:Wait() end

--------------------------------------------------------------------
-- Services
--------------------------------------------------------------------
local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local RunService     = game:GetService("RunService")
local UIS            = game:GetService("UserInputService")
local PhysicsService = game:GetService("PhysicsService")
local LP             = Players.LocalPlayer
local Camera         = workspace.CurrentCamera
local PG             = LP:WaitForChild("PlayerGui")
local DRAWING_OK     = pcall(function() return Drawing end)

--------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------
local MAX_DISTANCE    = 1500
local UPDATE_HZ       = 20
local BOX_PADDING     = 0.05
local TRACER_ORIGIN   = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
local HEALTH_BAR_SIZE = Vector2.new(50,4)

--------------------------------------------------------------------
-- Colours / UI constants
--------------------------------------------------------------------
local C_MAIN, C_ACCENT, C_TEXT = Color3.fromRGB(22,22,26), Color3.fromRGB(0,160,255), Color3.fromRGB(240,240,240)
local ICON_X = "✕"

--------------------------------------------------------------------
-- State containers
--------------------------------------------------------------------
local ESP_ENABLED = false
local OPTIONS = {
    box       = true,
    chams     = false,
    tracers   = false,
    distance  = false,
    health    = false,
    vischeck  = false,
    walkwalls = false,
}

local targets = {}   -- [Model] = {root = Part}

-- weak-key drawing / adornment pools
local pool = {
    box       = setmetatable({}, {__mode="k"}),
    highlight = setmetatable({}, {__mode="k"}),
    tracer    = setmetatable({}, {__mode="k"}),
    label     = setmetatable({}, {__mode="k"}),
    health    = setmetatable({}, {__mode="k"}),
}

--------------------------------------------------------------------
-- ESP helper factories  (unchanged)
--------------------------------------------------------------------
local function getHighlight(model)
    local h = pool.highlight[model]
    if not h or h.Parent==nil then
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
    if not b or b.Parent==nil then
        b = Instance.new("BoxHandleAdornment")
        b.AlwaysOnTop, b.ZIndex = true, 5
        b.Adornee = part
        b.Parent  = part
        pool.box[part] = b
    end
    return b
end

local function getDraw(tbl, id, kind)
    if not DRAWING_OK then return end
    local obj = tbl[id]
    if not obj then obj = Drawing.new(kind); tbl[id] = obj end
    return obj
end
local function hideDraw(tbl,id) if tbl[id] then tbl[id].Visible=false end end
local function lerpHealth(c) return Color3.fromRGB((1-c)*255, c*255, 0) end

--------------------------------------------------------------------
-- LOS helper
--------------------------------------------------------------------
local function hasLOS(part)
    local origin = Camera.CFrame.Position
    local rayParams = RaycastParams.new()
    rayParams.FilterType               = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances= {LP.Character or Instance.new("Folder")}
    local hit = workspace:Raycast(origin, part.Position - origin, rayParams)
    return not hit or hit.Instance:IsDescendantOf(part.Parent)
end

--------------------------------------------------------------------
-- NPC detection
--------------------------------------------------------------------
local function isEnemy(model)
    if not (model and model:IsA("Model") and model.Name=="Male") then return false end
    for _,c in ipairs(model:GetChildren()) do
        if c.Name:sub(1,3)=="AI_" then return true end
    end
    return false
end
local function register(model)
    if targets[model] then return end
    local head = model:FindFirstChild("Head") or model:FindFirstChild("UpperTorso")
    if head then targets[model] = {root = head} end
end
for _,d in ipairs(workspace:GetDescendants()) do if isEnemy(d) then register(d) end end
workspace.DescendantAdded:Connect(function(d) if isEnemy(d) then task.wait(); register(d) end end)
workspace.DescendantRemoving:Connect(function(d) targets[d]=nil end)

--------------------------------------------------------------------
-- MAIN ESP LOOP
--------------------------------------------------------------------
local tickAcc = 0
RunService.RenderStepped:Connect(function(dt)
    if not ESP_ENABLED then return end
    tickAcc += dt
    if tickAcc < 1/UPDATE_HZ then return end
    tickAcc = 0

    local camPos = Camera.CFrame.Position

    for model,data in pairs(targets) do
        if not model.Parent then targets[model]=nil continue end
        local root = data.root
        if not root then continue end

        local dist = (root.Position - camPos).Magnitude
        if dist > MAX_DISTANCE then
            hideDraw(pool.tracer,model); hideDraw(pool.label,model); hideDraw(pool.health,model)
            if pool.box[root] then pool.box[root].Transparency=1 end
            if pool.highlight[model] then pool.highlight[model].Enabled=false end
            continue
        end

        local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        local vis = true
        if OPTIONS.vischeck then vis = hasLOS(root) end

        -- BOX
        if OPTIONS.box and onScreen then
            local box = getBox(root)
            box.Size         = root.Size + Vector3.new(BOX_PADDING,BOX_PADDING,BOX_PADDING)
            box.Transparency = 0.25
            box.Color3       = vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
        elseif pool.box[root] then pool.box[root].Transparency = 1 end

        -- CHAMS
        if OPTIONS.chams then
            local h = getHighlight(model)
            h.FillColor = vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,190,255)
            h.Enabled   = true
        elseif pool.highlight[model] then pool.highlight[model].Enabled=false end

        if DRAWING_OK then
            -- TRACER
            if OPTIONS.tracers and onScreen then
                local tr = getDraw(pool.tracer,model,"Line")
                tr.Visible, tr.Thickness = true, 1.5
                tr.Color  = vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,255,0)
                tr.From, tr.To = TRACER_ORIGIN, Vector2.new(screenPos.X, screenPos.Y)
            else hideDraw(pool.tracer,model) end
            -- DISTANCE
            if OPTIONS.distance and onScreen then
                local lb = getDraw(pool.label,model,"Text")
                lb.Visible, lb.Center, lb.Outline, lb.Size = true, true, true, 14
                lb.Color    = Color3.new(1,1,1)
                lb.Text     = ("%.0f"):format(dist)
                lb.Position = Vector2.new(screenPos.X, screenPos.Y-16)
            else hideDraw(pool.label,model) end
            -- HEALTH
            if OPTIONS.health and onScreen then
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum then
                    local frac = math.clamp(hum.Health/hum.MaxHealth,0,1)
                    local hb = getDraw(pool.health,model,"Square")
                    hb.Visible, hb.Filled = true, true
                    hb.Size      = HEALTH_BAR_SIZE * Vector2.new(frac,1)
                    hb.Position  = Vector2.new(screenPos.X-HEALTH_BAR_SIZE.X/2, screenPos.Y+12)
                    hb.Color     = lerpHealth(frac)
                end
            else hideDraw(pool.health,model) end
        end
    end
end)

--------------------------------------------------------------------
-- Disable all ESP visuals
--------------------------------------------------------------------
local function disableAll()
    for _,b in pairs(pool.box) do b.Transparency=1 end
    for _,h in pairs(pool.highlight) do h.Enabled=false end
    if DRAWING_OK then
        for _,tbl in ipairs{pool.tracer,pool.label,pool.health} do
            for _,o in pairs(tbl) do o.Visible=false end
        end
    end
end

--------------------------------------------------------------------
-- NOCLIP 2.0  (collision-group based)
--------------------------------------------------------------------
local NOGROUP = "ParagonNoClip"
-- create group if absent
if not pcall(function() PhysicsService:GetCollisionGroupId(NOGROUP) end) then
    PhysicsService:CreateCollisionGroup(NOGROUP)
end
-- ensure non-collidable with every other group
for _,g in ipairs(PhysicsService:GetCollisionGroups()) do
    PhysicsService:CollisionGroupSetCollidable(NOGROUP, g.name, false)
end

local function applyGroup(char, grpName, collideState)
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CollisionGroup = grpName
            p.CanCollide     = collideState
        end
    end
end

local function enforceNoClip(char)  -- runs each Heartbeat when ON
    if not OPTIONS.walkwalls then return end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.CollisionGroup ~= NOGROUP then
            p.CollisionGroup = NOGROUP
            p.CanCollide     = false
        end
    end
end

-- heartbeat hook once
RunService.Heartbeat:Connect(function()
    if OPTIONS.walkwalls and LP.Character then enforceNoClip(LP.Character) end
end)

local function setNoClip(state)
    if state then
        if LP.Character then applyGroup(LP.Character, NOGROUP, false) end
    else
        if LP.Character then applyGroup(LP.Character, "Default", true) end
    end
end
LP.CharacterAdded:Connect(function(char)
    if OPTIONS.walkwalls then
        char:WaitForChild("HumanoidRootPart",5)
        setNoClip(true)
    end
end)

--------------------------------------------------------------------
-- GUI  (unchanged except new toggle added earlier)
--------------------------------------------------------------------
local old = PG:FindFirstChild("ParagonMainUI")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui", PG)
gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn = "ParagonMainUI", true, false
if syn and syn.protect_gui then syn.protect_gui(gui) end

local frame = Instance.new("Frame", gui)
frame.AnchorPoint = Vector2.new(0,0.5)
frame.Size        = UDim2.new(0,270,0,340)
frame.Position    = UDim2.new(0,-frame.Size.X.Offset-10,0.5,0)
frame.BackgroundColor3, frame.BackgroundTransparency = C_MAIN, 0.2
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke", frame).Color = C_ACCENT

local hdr = Instance.new("TextLabel", frame)
hdr.Size, hdr.BackgroundTransparency = UDim2.new(1,0,0,40), 1
hdr.Font, hdr.Text, hdr.TextColor3, hdr.TextScaled = Enum.Font.GothamBlack, "PARAGON ESP", C_TEXT, true
hdr.TextStrokeTransparency = 0.85

local div = Instance.new("Frame", frame)
div.Position, div.Size, div.BackgroundColor3 = UDim2.new(0,8,0,42), UDim2.new(1,-16,0,1), C_ACCENT

local body = Instance.new("Frame", frame)
body.Position, body.Size, body.BackgroundTransparency = UDim2.new(0,8,0,50), UDim2.new(1,-16,1,-58), 1
local list = Instance.new("UIListLayout", body)
list.Padding, list.HorizontalAlignment, list.VerticalAlignment =
    UDim.new(0,6), Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top

local function addToggle(label,key,callback)
    local btn = Instance.new("TextButton", body)
    btn.Size = UDim2.new(1,0,0,32)
    btn.BackgroundColor3, btn.BackgroundTransparency = C_MAIN, 0.15
    btn.AutoButtonColor, btn.BorderSizePixel = false, 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local name = Instance.new("TextLabel", btn)
    name.BackgroundTransparency = 1
    name.Size, name.Position = UDim2.new(1,-28,1,0), UDim2.new(0,6,0,0)
    name.Font, name.TextColor3, name.TextXAlignment, name.TextScaled =
        Enum.Font.GothamSemibold, C_TEXT, Enum.TextXAlignment.Left, true
    name.Text = label

    local icon = Instance.new("TextLabel", btn)
    icon.BackgroundTransparency = 1
    icon.Size, icon.Position = UDim2.new(0,22,0,22), UDim2.new(1,-26,0.5,-11)
    icon.Font, icon.TextScaled, icon.Text = Enum.Font.GothamBold, true, ICON_X

    local ust = Instance.new("UIStroke", btn) ust.Color, ust.Transparency = C_ACCENT, 0.8

    local function update()
        local active = (key=="master" and ESP_ENABLED) or OPTIONS[key]
        icon.TextColor3 = active and Color3.fromRGB(0,255,80) or Color3.fromRGB(180,180,180)
    end
    update()

    btn.MouseEnter:Connect(function() TweenService:Create(ust,TweenInfo.new(0.15),{Transparency=0.2}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(ust,TweenInfo.new(0.15),{Transparency=0.8}):Play() end)

    btn.MouseButton1Click:Connect(function()
        if key=="master" then
            ESP_ENABLED = not ESP_ENABLED
            if not ESP_ENABLED then disableAll() end
        else
            OPTIONS[key] = not OPTIONS[key]
            if key=="walkwalls" then setNoClip(OPTIONS.walkwalls) end
        end
        update()
        if callback then callback(OPTIONS[key]) end
    end)
end

-- menu buttons
addToggle("ESP Master",        "master")
addToggle("3D Box",            "box")
addToggle("Chams",             "chams")
addToggle("Tracers",           "tracers")
addToggle("Distance",          "distance")
addToggle("Health Bar",        "health")
addToggle("VisCheck (LOS)",    "vischeck")
addToggle("Walk Through Walls","walkwalls", setNoClip)

-- slide panel on `\`
local open, margin = false, 10
local function slide()
    open = not open
    local y = -frame.AbsoluteSize.Y/2
    local target = open and UDim2.new(0,margin,0.5,y)
                          or  UDim2.new(0,-frame.AbsoluteSize.X-margin,0.5,y)
    TweenService:Create(frame,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=target}):Play()
end
UIS.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode==Enum.KeyCode.BackSlash then slide() end end)
slide() -- open on spawn
