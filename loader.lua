-- Paragon BRM5 • Rayfield Mini‑ESP (v20 — Turbo Expanded)
-- ▶ 200‑line readability version with every‑frame updates, bright colours,
--   edge‑clamped tracers, and guaranteed clearing when ESP is disabled.
-- Key = paragon  •  Right‑Shift opens Rayfield
---------------------------------------------------------------------
-- 0.  Services / locals
---------------------------------------------------------------------
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local Workspace    = game:GetService("Workspace")

local LP        = Players.LocalPlayer
local Camera    = Workspace.CurrentCamera

getgenv().SecureMode = true

---------------------------------------------------------------------
-- 1.  Settings & state tables
---------------------------------------------------------------------
local MAX_DIST   = 1500                       -- ESP render distance
local BAR_SIZE   = Vector2.new(60, 4)         -- health‑bar pixel size
local DRAWING_OK = pcall(function() return Drawing end)

local ESP = {
    Enabled = true,
    Options = {
        box      = true,   -- 3‑D BoxHandle around model rootPart
        chams    = true,   -- Roblox Highlight overlay
        tracers  = true,   -- bottom‑centre line
        distance = true,   -- white distance text
        health   = true,   -- coloured health bar
        vischeck = true,   -- line‑of‑sight colour swap
    },
    Targets = {},          -- [model] = {root = Part}
    Cache   = {            -- weak tables for objects
        box     = setmetatable({}, {__mode = "k"}),
        cham    = setmetatable({}, {__mode = "k"}),
        tracer  = setmetatable({}, {__mode = "k"}),
        label   = setmetatable({}, {__mode = "k"}),
        health  = setmetatable({}, {__mode = "k"}),
    }
}

---------------------------------------------------------------------
-- 2.  Enemy registration helpers
---------------------------------------------------------------------
local function isEnemy(m: Instance)
    if not (m:IsA("Model") and m.Name == "Male") then return false end
    for _, c in ipairs(m:GetChildren()) do
        if c.Name:sub(1,3) == "AI_" then return true end
    end
end

local function registerModel(m)
    if ESP.Targets[m] then return end     -- already tracked
    local root = m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso")
    if root then ESP.Targets[m] = {root = root} end
end

-- initial sweep
for _, d in ipairs(Workspace:GetDescendants()) do
    if isEnemy(d) then registerModel(d) end
end
-- dynamic hooks
Workspace.DescendantAdded:Connect(function(d)
    if isEnemy(d) then task.defer(registerModel, d) end
end)
Workspace.DescendantRemoving:Connect(function(d)
    ESP.Targets[d] = nil
end)

---------------------------------------------------------------------
-- 3.  Factory wrappers (Box / Highlight / Drawing)
---------------------------------------------------------------------
local function getBox(part: BasePart)
    local b = ESP.Cache.box[part]
    if not b or not b.Parent then
        b = Instance.new("BoxHandleAdornment")
        b.AlwaysOnTop = true
        b.ZIndex      = 10
        b.Adornee     = part
        b.Parent      = part
        ESP.Cache.box[part] = b
    end
    return b
end

local function getCham(model: Model)
    local h = ESP.Cache.cham[model]
    if not h or not h.Parent then
        h = Instance.new("Highlight")
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent    = model
        ESP.Cache.cham[model] = h
    end
    return h
end

local function getDraw(tbl, id, kind)
    if not DRAWING_OK then return end
    local o = tbl[id]
    if not o then o = Drawing.new(kind); tbl[id] = o end
    return o
end

local function hide(tbl, id)
    local o = tbl[id]; if o then o.Visible = false end
end

local function healthColour(frac)
    return Color3.fromRGB((1‑frac)*255, frac*255, 0)
end

---------------------------------------------------------------------
-- 4.  Utility helpers
---------------------------------------------------------------------
local function lineOfSight(part: BasePart)
    if not ESP.Options.vischeck then return true end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances = {LP.Character}
    local hit = Workspace:Raycast(Camera.CFrame.Position, part.Position ‑ Camera.CFrame.Position, rp)
    return (not hit) or hit.Instance:IsDescendantOf(part.Parent)
end

local function clearAll()
    -- hide BoxHandle & Highlight
    for _, b in pairs(ESP.Cache.box)  do b.Transparency = 1 end
    for _, h in pairs(ESP.Cache.cham) do h.Enabled      = false end
    -- hide Drawing objects
    if DRAWING_OK then
        for _, tbl in pairs{ESP.Cache.tracer, ESP.Cache.label, ESP.Cache.health} do
            for _, o in pairs(tbl) do o.Visible = false end
        end
    end
end

---------------------------------------------------------------------
-- 5.  Main render loop (every frame)
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not ESP.Enabled then return end

    local camPos = Camera.CFrame.Position
    local vp     = Camera.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y)   -- tracer origin, re‑calculated each frame

    for mdl, t in pairs(ESP.Targets) do
        local root = t.root
        -- validity + distance test ------------------------------------------------
        if (not root) or (not mdl.Parent) then ESP.Targets[mdl] = nil; continue end
        local dist = (root.Position - camPos).Magnitude
        if dist > MAX_DIST then
            -- quickly hide cached items and continue
            hide(ESP.Cache.tracer, mdl); hide(ESP.Cache.label, mdl); hide(ESP.Cache.health, mdl)
            getBox(root).Transparency = 1
            getCham(mdl).Enabled      = false
            continue
        end

        local scr, onScr = Camera:WorldToViewportPoint(root.Position)
        local vis        = lineOfSight(root)

        ------------------------------------------------------------------
        -- 3‑D Box (root sized)                                           --
        ------------------------------------------------------------------
        do
            local bx = getBox(root)
            if ESP.Options.box and onScr then
                bx.Size         = root.Size + Vector3.new(0.1,0.1,0.1)
                bx.Transparency = 0.2
                bx.Color3       = vis and Color3.fromRGB(0,255,35) or Color3.fromRGB(160,160,160)
            else
                bx.Transparency = 1
            end
        end

        ------------------------------------------------------------------
        -- Chams (Highlight)                                              --
        ------------------------------------------------------------------
        do
            local ch = getCham(mdl)
            if ESP.Options.chams then
                ch.Enabled             = true
                ch.FillTransparency    = 0.1
                ch.FillColor           = vis and Color3.fromRGB(255,60,60) or Color3.fromRGB(0,200,255)
                ch.OutlineColor        = Color3.new(1,1,1)
                ch.OutlineTransparency = 0.04
            else
                ch.Enabled = false
            end
        end

        if not DRAWING_OK then continue end    -- skip D API if unavailable

        ------------------------------------------------------------------
        -- Tracer (edge‑clamped)                                          --
        ------------------------------------------------------------------
        if ESP.Options.tracers then
            local tr = getDraw(ESP.Cache.tracer, mdl, "Line")
            tr.Visible   = true
            tr.Thickness = 2
            tr.Color     = vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,255,0)

            local endPos = Vector2.new(scr.X, scr.Y)
            -- clamp to screen edge if NPC is off‑screen (prevents sky spikes)
            if not onScr then
                endPos.X = math.clamp(endPos.X, 0, vp.X)
                endPos.Y = math.clamp(endPos.Y, 0, vp.Y)
            end
            tr.From, tr.To = center, endPos
        else
            hide(ESP.Cache.tracer, mdl)
        end

        ------------------------------------------------------------------
        -- Distance text                                                 --
        ------------------------------------------------------------------
        if ESP.Options.distance and onScr then
            local lb = getDraw(ESP.Cache.label, mdl, "Text")
            lb.Visible = true
            lb.Center  = true; lb.Outline = true; lb.Size = 15
            lb.Color   = Color3.new(1,1,1)
            lb.Text    = ("%.0f m"):format(dist)
            lb.Position= Vector2.new(scr.X, scr.Y - 18)
        else
            hide(ESP.Cache.label, mdl)
        end

        ------------------------------------------------------------------
        -- Health bar                                                   --
        ------------------------------------------------------------------
        if ESP.Options.health and onScr then
            local hum = mdl:FindFirstChildOfClass("Humanoid")
            if hum then
                local frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local hb   = getDraw(ESP.Cache.health, mdl, "Square")
                hb.Visible = true; hb.Filled = true
                hb.Size     = BAR_SIZE * Vector2.new(frac, 1)
                hb.Position = Vector2.new(scr.X - BAR_SIZE.X/2, scr.Y + 14)
                hb.Color    = healthColour(frac)
            end
        else
            hide(ESP.Cache.health, mdl)
        end
    end
end)

---------------------------------------------------------------------
-- 6.  Rayfield GUI setup
---------------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()

local Window = Rayfield:CreateWindow({
    Name            = "Paragon BRM5 • Mini‑ESP",
    LoadingTitle    = "Paragon BRM5",
    LoadingSubtitle = "Turbo Expanded",
    Theme           = "Midnight",
    KeySystem       = true,
    KeySettings     = {
        Title    = "Paragon Key",
        Subtitle = "Enter key",
        Note     = "Key is: paragon",
        SaveKey  = true,
        Key      = {"paragon"}
    }
})

local tab = Window:CreateTab("ESP", "eye")

tab:CreateLabel("Master Toggle")

-- Master on/off
tab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = true,
    Callback = function(v)
        ESP.Enabled = v
        if not v then clearAll() end
    end
})

tab:CreateLabel("Modules")

-- Mapping of option flags to UI labels
local flagLabel = {
    box      = "3‑D Box",
    chams    = "Chams",
    tracers  = "Tracers",
    distance = "Distance",
    health   = "Health Bar",
    vischeck = "VisCheck (LOS)",
}

-- Generate toggles
for flag, label in pairs(flagLabel) do
    tab:CreateToggle({
        Name         = label,
        CurrentValue = ESP.Options[flag],
        Callback     = function(v)
            ESP.Options[flag] = v
            -- Instant clear of Drawings if user disables module
            if not v then
                if flag == "box" then for _,b in pairs(ESP.Cache.box)  do b.Transparency = 1 end end
                if flag == "chams" then for _,h in pairs(ESP.Cache.cham) do h.Enabled      = false end end
                if flag == "tracers" then for _,t in pairs(ESP.Cache.tracer)do t.Visible     = false end end
                if flag == "distance" then for _,l in pairs(ESP.Cache.label) do l.Visible     = false end end
                if flag == "health" then for _,h in pairs(ESP.Cache.health)do h.Visible     = false end end
            end
        end
    })
end

Rayfield:Notify({
    Title   = "Paragon BRM5",
    Content = "Mini‑ESP v20 Turbo‑Expanded loaded — Right‑Shift opens UI",
    Duration = 5
})
