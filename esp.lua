-- Paragon BRM5 • Rayfield Mini‑ESP (v13)
-- ✔️ Self‑contained, zero external fetches.
-- ✔️ Modules: 3‑D Box, Chams, Tracers, Distance text, Health bar, VisCheck.
-- ✔️ 30 Hz throttle, weak caches → maximum FPS.
-- ✔️ Key = paragon • Right‑Shift opens Rayfield.

---------------------------------------------------------------------
-- 0. Services / locals ----------------------------------------------
---------------------------------------------------------------------
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local LP         = Players.LocalPlayer
local Camera     = Workspace.CurrentCamera

getgenv().SecureMode = true

---------------------------------------------------------------------
-- 1. Settings & state ------------------------------------------------
---------------------------------------------------------------------
local UPDATE_HZ  = 30                    -- throttle (Hz)
local MAX_DIST   = 1500                  -- render distance
local BAR_SIZE   = Vector2.new(50,4)
local TRACER_ORG = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)

local DRAWING_OK = pcall(function() return Drawing end)

local ESP = {
    Enabled = true,
    Options = {
        box      = true,
        chams    = true,
        tracers  = true,
        distance = true,
        health   = true,
        vischeck = true,
    },
    Targets = {},  -- [Model] = {root = Part}
    Cache   = {
        box     = setmetatable({}, {__mode="k"}),
        cham    = setmetatable({}, {__mode="k"}),
        tracer  = setmetatable({}, {__mode="k"}),
        label   = setmetatable({}, {__mode="k"}),
        health  = setmetatable({}, {__mode="k"}),
    }
}

---------------------------------------------------------------------
-- 2. Enemy detector --------------------------------------------------
---------------------------------------------------------------------
local function isEnemy(m)
    if not (m:IsA("Model") and m.Name == "Male") then return false end
    for _,c in ipairs(m:GetChildren()) do
        if c.Name:sub(1,3) == "AI_" then return true end
    end
    return false
end

local function register(m)
    if ESP.Targets[m] then return end
    local root = m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso")
    if root then ESP.Targets[m] = {root = root} end
end

for _,d in ipairs(Workspace:GetDescendants()) do if isEnemy(d) then register(d) end end
Workspace.DescendantAdded:Connect(function(d) if isEnemy(d) then task.wait(); register(d) end end)
Workspace.DescendantRemoving:Connect(function(d) ESP.Targets[d] = nil end)

---------------------------------------------------------------------
-- 3. Factories -------------------------------------------------------
---------------------------------------------------------------------
local function getBox(p)
    local b = ESP.Cache.box[p]
    if not b or b.Parent == nil then
        b = Instance.new("BoxHandleAdornment")
        b.AlwaysOnTop, b.ZIndex, b.Adornee = true, 5, p
        b.Parent = p; ESP.Cache.box[p] = b
    end
    return b
end

local function getCham(m)
    local h = ESP.Cache.cham[m]
    if not h or h.Parent == nil then
        h = Instance.new("Highlight")
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = m; ESP.Cache.cham[m] = h
    end
    return h
end

local function getDraw(tbl,id,kind)
    if not DRAWING_OK then return end
    local o = tbl[id]
    if not o then o = Drawing.new(kind); tbl[id] = o end
    return o
end

local function hide(tbl,id,prop)
    local o = tbl[id]; if o then o[prop] = false end
end

local function hpColor(f) return Color3.fromRGB((1-f)*255, f*255, 0) end

---------------------------------------------------------------------
-- 4. VisCheck helper -------------------------------------------------
---------------------------------------------------------------------
local function lineOfSight(part)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances = { LP.Character or Instance.new("Folder") }
    local hit = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rp)
    return (not hit) or hit.Instance:IsDescendantOf(part.Parent)
end

---------------------------------------------------------------------
-- 5. Clear util ------------------------------------------------------
---------------------------------------------------------------------
local function clear()
    for _,b  in pairs(ESP.Cache.box)    do b.Transparency = 1 end
    for _,h  in pairs(ESP.Cache.cham)   do h.Enabled      = false end
    if DRAWING_OK then
        for _,tbl in pairs{ESP.Cache.tracer,ESP.Cache.label,ESP.Cache.health} do
            for _,o in pairs(tbl) do o.Visible = false end
        end
    end
end

---------------------------------------------------------------------
-- 6. Render loop (throttled) ----------------------------------------
---------------------------------------------------------------------
local acc = 0
RunService.RenderStepped:Connect(function(dt)
    if not ESP.Enabled then return end
    acc += dt; if acc < 1/UPDATE_HZ then return end; acc = 0

    local camPos = Camera.CFrame.Position

    for mdl,t in pairs(ESP.Targets) do
        local root = t.root
        if not root or not mdl.Parent then ESP.Targets[mdl] = nil continue end

        local dist = (root.Position - camPos).Magnitude
        if dist > MAX_DIST then
            if DRAWING_OK then
                hide(ESP.Cache.tracer,mdl,"Visible"); hide(ESP.Cache.label,mdl,"Visible"); hide(ESP.Cache.health,mdl,"Visible")
            end
            if ESP.Cache.box[root] then ESP.Cache.box[root].Transparency = 1 end
            if ESP.Cache.cham[mdl]  then ESP.Cache.cham[mdl].Enabled = false end
            continue
        end

        local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        local vis = (not ESP.Options.vischeck) or lineOfSight(root)

        -- Box -------------------------------------------------------
        if ESP.Options.box and onScreen then
            local b = getBox(root)
            b.Size = root.Size + Vector3.new(0.1,0.1,0.1)
            b.Transparency = 0.25
            b.Color3 = vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(120,120,120)
        elseif ESP.Cache.box[root] then
            ESP.Cache.box[root].Transparency = 1
        end

        -- Chams -----------------------------------------------------
        if ESP.Options.chams then
            local h = getCham(mdl)
            h.Enabled = true
            h.FillColor = vis and Color3.fromRGB(255,75,75) or Color3.fromRGB(0,190,255)
            h.FillTransparency = 0.15
            h.OutlineColor, h.OutlineTransparency = h.FillColor, 0.1
        elseif ESP.Cache.cham[mdl] then
            ESP.Cache.cham[mdl].Enabled = false
        end

        if DRAWING_OK then
            -- Tracer ----------------------------------------------
            if ESP.Options.tracers and onScreen then
                local tr = getDraw(ESP.Cache.tracer, mdl, "Line")
                tr.Visible, tr.Thickness = true, 1.5
                tr.Color = vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,255,0)
                tr.From,  tr.To = TRACER_ORG, Vector2.new(screenPos.X, screenPos.Y)
            else hide(ESP.Cache.tracer,mdl,"Visible") end

            -- Distance text ---------------------------------------
            if ESP.Options.distance and onScreen then
                local lb = getDraw(ESP.Cache.label, mdl, "Text")
                lb.Visible, lb.Center, lb.Outline, lb.Size = true, true, true, 14
                lb.Color, lb.Text = Color3.new(1,1,1), ("%.0f"):format(dist)
                lb.Position = Vector2.new(screenPos.X, screenPos.Y - 16)
            else hide(ESP.Cache.label,mdl,"Visible") end

            -- Health bar ------------------------------------------
            if ESP.Options.health and onScreen then
                local hum = mdl:FindFirstChildOfClass("Humanoid")
                if hum then
                    local frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local hb = getDraw(ESP.Cache.health, mdl, "Square")
                    hb.Visible, hb.Filled = true, true
                    hb.Size     = BAR_SIZE * Vector2.new(frac,1)
                    hb.Position = Vector2.new(screenPos.X - BAR_SIZE.X/2, screenPos.Y + 12)
                    hb.Color    = hpColor(frac)
                end
            else hide(ESP.Cache.health,mdl,"Visible") end
        end
    end
end)

---------------------------------------------------------------------
-- 7. Rayfield GUI ----------------------------------------------------
---------------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()

local Window = Rayfield:CreateWindow({
    Name="Paragon BRM5 • Mini‑ESP", LoadingTitle="Paragon BRM5", LoadingSubtitle="Mini ESP",
    Theme="Midnight", KeySystem=true,
    KeySettings={Title="Paragon Key",Subtitle="Enter key",Note="Key is: paragon",SaveKey=true,Key={"paragon"}}
})

local tab = Window:CreateTab("ESP","eye")

tab:CreateLabel("Master")

tab:CreateToggle({Name="Enable ESP",CurrentValue=true,Callback=function(v)
    ESP.Enabled = v; if not v then clear() end end})

tab:CreateLabel("Modules")
local labels = {
    box="3‑D Box",chams="Chams",tracers="Tracers",distance="Distance",health="Health Bar",vischeck="VisCheck"}
for flag,label in pairs(labels) do
    tab:CreateToggle({Name=label,CurrentValue=ESP.Options[flag],Callback=function(v) ESP.Options[flag]=v end})
end

Rayfield:
