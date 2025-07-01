--------------------------------------------------------------------
-- PARAGON OPEN WORLD  •  ADVANCED ESP + LOS + CLIENT-NCLP
-- 2025-07-XX
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

--------------------------------------------------------------------
-- Services
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
-- Config
--------------------------------------------------------------------
local MAX_DIST  = 1500           -- studs
local TICK_HZ   = 20             -- esp refresh
local BOX_PAD   = 0.05
local BAR_SIZE  = Vector2.new(50,4)
local TRACER_ORIG = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)

--------------------------------------------------------------------
-- UI colours
--------------------------------------------------------------------
local COL_MAIN , COL_ACC , COL_TEXT = Color3.fromRGB(22,22,26), Color3.fromRGB(0,160,255), Color3.fromRGB(240,240,240)
local ICON_X = "✕"

--------------------------------------------------------------------
-- State
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
-- Caches
--------------------------------------------------------------------
local targets = {}   -- [model] = {root = part}
local pool = {       -- weak-key pools
    box       = setmetatable({}, {__mode="k"}),
    highlight = setmetatable({}, {__mode="k"}),
    tracer    = setmetatable({}, {__mode="k"}),
    label     = setmetatable({}, {__mode="k"}),
    health    = setmetatable({}, {__mode="k"}),
}

--------------------------------------------------------------------
-- Factory helpers
--------------------------------------------------------------------
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

local function getHi(model)
    local h = pool.highlight[model]
    if not h or h.Parent==nil then
        h = Instance.new("Highlight")
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = model
        pool.highlight[model] = h
    end
    return h
end

local function getDraw(tbl,id,kind)
    if not DRAWING_OK then return end
    local o = tbl[id]
    if not o then o = Drawing.new(kind); tbl[id] = o end
    return o
end
local function hide(tbl,id) if tbl[id] then tbl[id].Visible = false end end
local function healthCol(frac) return Color3.fromRGB((1-frac)*255, frac*255, 0) end

local function hasLOS(part)
    local rp = RaycastParams.new()
    rp.FilterType               = Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances= {LP.Character or Instance.new("Folder")}
    local hit = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rp)
    return (not hit) or hit.Instance:IsDescendantOf(part.Parent)
end

--------------------------------------------------------------------
-- NPC acquisition
--------------------------------------------------------------------
local function isEnemy(m)
    if not (m:IsA("Model") and m.Name=="Male") then return false end
    for _,c in ipairs(m:GetChildren()) do if c.Name:sub(1,3)=="AI_" then return true end end
    return false
end

local function register(m)
    if targets[m] then return end
    local head = m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso")
    if head then targets[m] = {root=head} end
end

for _,d in ipairs(workspace:GetDescendants()) do if isEnemy(d) then register(d) end end
workspace.DescendantAdded:Connect(function(d) if isEnemy(d) then task.wait(); register(d) end end)
workspace.DescendantRemoving:Connect(function(d) targets[d]=nil end)

--------------------------------------------------------------------
-- MAIN ESP TICK
--------------------------------------------------------------------
local accum = 0
RunService.RenderStepped:Connect(function(dt)
    if not ESP_ON then return end
    accum += dt
    if accum < 1/TICK_HZ then return end
    accum = 0

    local camPos = Camera.CFrame.Position

    for model,t in pairs(targets) do
        if not model.Parent then targets[model]=nil continue end
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
        local vis = (not OPT.vischeck) or hasLOS(root)

        -- BOX
        if OPT.box and onScreen then
            local box = getBox(root)
            box.Size         = root.Size + Vector3.new(BOX_PAD,BOX_PAD,BOX_PAD)
            box.Transparency = 0.25
            box.Color3       = vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
        elseif pool.box[root] then pool.box[root].Transparency = 1 end

        -- CHAMS (bright & obvious)
        if OPT.chams then
            local hi = getHi(model)
            hi.Enabled             = true
            hi.FillColor           = vis and Color3.fromRGB(255, 75, 75) or Color3.fromRGB(0,190,255)
            hi.FillTransparency    = 0.15
            hi.OutlineColor        = hi.FillColor
            hi.OutlineTransparency = 0.1
        elseif pool.highlight[model] then
            pool.highlight[model].Enabled = false
        end

        if DRAWING_OK then
            -- TRACER
            if OPT.tracers and onScreen then
                local tr = getDraw(pool.tracer,model,"Line")
                tr.Visible   = true
                tr.Thickness = 1.5
                tr.Color     = vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,255,0)
                tr.From, tr.To = TRACER_ORIG, Vector2.new(v2.X,v2.Y)
            else hide(pool.tracer,model) end

            -- DISTANCE
            if OPT.distance and onScreen then
                local lb = getDraw(pool.label,model,"Text")
                lb.Visible, lb.Center, lb.Outline, lb.Size = true,true,true,14
                lb.Color     = Color3.new(1,1,1)
                lb.Text      = ("%.0f"):format(dist)
                lb.Position  = Vector2.new(v2.X, v2.Y-16)
            else hide(pool.label,model) end

            -- HEALTH
            if OPT.health and onScreen then
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum then
                    local frac = math.clamp(hum.Health/hum.MaxHealth,0,1)
                    local hb   = getDraw(pool.health,model,"Square")
                    hb.Visible, hb.Filled = true, true
                    hb.Size      = BAR_SIZE * Vector2.new(frac,1)
                    hb.Position  = Vector2.new(v2.X-BAR_SIZE.X/2, v2.Y+12)
                    hb.Color     = healthCol(frac)
                end
            else hide(pool.health,model) end
        end
    end
end)

local function clearESP()
    for _,b in pairs(pool.box) do b.Transparency = 1 end
    for _,h in pairs(pool.highlight) do h.Enabled = false end
    if DRAWING_OK then
        for _,tbl in ipairs{pool.tracer,pool.label,pool.health} do
            for _,o in pairs(tbl) do o.Visible=false end
        end
    end
end

--------------------------------------------------------------------
-- Noclip (client-side CanCollide toggle)
--------------------------------------------------------------------
local function setCollide(on)
    if not LP.Character then return end
    for _,p in ipairs(LP.Character:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = on
            p.Massless   = not on
        end
    end
end
LP.CharacterAdded:Connect(function(c)
    c:WaitForChild("HumanoidRootPart",6)
    if OPT.walkwalls then setCollide(false) end
end)
RunService.Heartbeat:Connect(function()
    if OPT.walkwalls and LP.Character then
        for _,p in ipairs(LP.Character:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide=false; p.Massless=true
            end
        end
    end
end)

local function noclipToggle(on) setCollide(not on) end


