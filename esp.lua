--------------------------------------------------------------------
--  PARAGON OPEN WORLD • Core ESP (no GUI)            → esp.lua
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

--------------------------------------------------------------------
--  Services & locals
--------------------------------------------------------------------
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--------------------------------------------------------------------
--  Config / globals
--------------------------------------------------------------------
_G.ESP_ON = _G.ESP_ON or false      -- master switch
_G.OPT    = _G.OPT    or {          -- per-module toggles
    box       = true,
    chams     = false,
    tracers   = false,
    distance  = false,
    health    = false,
    vischeck  = false,
    walkwalls = false,
}

--------------------------------------------------------------------
--  Weak-cache tables
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
--  Helper factory functions (Box & Highlight only)
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

--------------------------------------------------------------------
--  Enemy registration
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
--  Main render loop (Boxes & Chams only)
--------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not _G.ESP_ON then return end

    for model, t in pairs(targets) do
        local root = t.root
        if not root or not model.Parent then targets[model] = nil continue end

        -- BOX -------------------------------------------------------
        if _G.OPT.box then
            local b = getBox(root)
            b.Size, b.Transparency = root.Size + Vector3.new(0.1,0.1,0.1), 0.25
            b.Color3 = Color3.fromRGB(0,255,0)
        elseif pool.box[root] then
            pool.box[root].Transparency = 1
        end

        -- CHAMS -----------------------------------------------------
        if _G.OPT.chams then
            local h = getHi(model)
            h.Enabled             = true
            h.FillColor           = Color3.fromRGB(255,75,75)
            h.FillTransparency    = 0.15
            h.OutlineColor        = h.FillColor
            h.OutlineTransparency = 0.1
        elseif pool.highlight[model] then
            pool.highlight[model].Enabled = false
        end
    end
end)

--------------------------------------------------------------------
--  External helper to hide drawings (called by loaders)
--------------------------------------------------------------------
function _G.clearESP()
    for _,b in pairs(pool.box)       do b.Transparency = 1 end
    for _,h in pairs(pool.highlight) do h.Enabled      = false end
end
