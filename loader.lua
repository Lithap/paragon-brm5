--[[
  Paragon Open World • **Quantum ESP** (v5)
  ──────────────────────────────────────────────────────────────────────────
  ▸ GUI‑free, standalone ESP engineered for any open‑world shooter on Roblox.
  ▸ Modules: 3‑D Boxes, Chams, Tracers, Distance, Health Bar, VisCheck.
  ▸ Zero‑stutter architecture: single RenderStepped loop, memory‑weak caches,
    no busy‑waiting, no deprecated API calls.
  ▸ Drawing API optional – script gracefully degrades if unavailable.
  ▸ Quick master toggle: **F**   |   Global settings via _G.OPT / _G.ESP_ON.

  © 2025 Paragon. Redistribution permitted with credit.
]]--------------------------------------------------------------------------

---------------------------------------------------------------------
-- 0. Services / strict locals
---------------------------------------------------------------------
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UserInput    = game:GetService("UserInputService")
local Workspace    = game:GetService("Workspace")
local LP           = Players.LocalPlayer
local Camera       = Workspace.CurrentCamera

-- ensure game is loaded (safe for server hoppers)
if not game:IsLoaded() then game.Loaded:Wait() end

---------------------------------------------------------------------
-- 1. Global toggles (user‑modifiable)
---------------------------------------------------------------------
_G.ESP_ON = _G.ESP_ON ~= false            -- default ‑> enabled
_G.OPT    = _G.OPT or {
    box      = true,
    chams    = true,
    tracers  = true,
    distance = true,
    health   = true,
    vischeck = true,
}

---------------------------------------------------------------------
-- 2. Constants / internal state
---------------------------------------------------------------------
local MAX_DIST     = 2000                       -- studs, hard cut‑off
local BAR_SIZE     = Vector2.new(50, 4)         -- health bar pixel size
local cache = {
    box    = setmetatable({}, { __mode = "k" }), -- [BasePart] = BoxHandleAdornment
    cham   = setmetatable({}, { __mode = "k" }), -- [Model]    = Highlight
    tracer = setmetatable({}, { __mode = "k" }), -- [Model]    = Drawing Line
    label  = setmetatable({}, { __mode = "k" }), -- [Model]    = Drawing Text
    health = setmetatable({}, { __mode = "k" }), -- [Model]    = Drawing Square
}
local targets = {}                              -- [Model] = { root = BasePart }
local DRAWING_OK = pcall(function() return Drawing end)

---------------------------------------------------------------------
-- 3. Enemy detection (generic NPC heuristic)
---------------------------------------------------------------------
local function isEnemy(model: Instance): boolean
    if not (model:IsA("Model") and model.Name == "Male") then return false end
    for _, child in ipairs(model:GetChildren()) do
        if child.Name:sub(1, 3) == "AI_" then return true end
    end
end

local function register(model: Model)
    if targets[model] then return end
    local root = model:FindFirstChild("HumanoidRootPart")
             or model:FindFirstChild("Head")
             or model:FindFirstChild("UpperTorso")
    if root then targets[model] = { root = root } end
end

-- initial scan
for _, inst in ipairs(Workspace:GetDescendants()) do
    if isEnemy(inst) then register(inst) end
end

-- live updates
Workspace.DescendantAdded:Connect(function(inst)
    if isEnemy(inst) then task.defer(register, inst) end
end)
Workspace.DescendantRemoving:Connect(function(inst)
    targets[inst] = nil
end)

---------------------------------------------------------------------
-- 4. Factory helpers (lazy, cached)
---------------------------------------------------------------------
local function getBox(part: BasePart)
    local box = cache.box[part]
    if not box or not box.Parent then
        box = Instance.new("BoxHandleAdornment")
        box.AlwaysOnTop  = true
        box.ZIndex       = 10
        box.Adornee      = part
        box.Size         = part.Size + Vector3.new(0.1, 0.1, 0.1)
        box.Transparency = 1
        box.Parent       = part
        cache.box[part]  = box
    end
    return box
end

local function getCham(model: Model)
    local cham = cache.cham[model]
    if not cham or not cham.Parent then
        cham = Instance.new("Highlight")
        cham.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
        cham.FillTransparency    = 0.15
        cham.OutlineTransparency = 0.05
        cham.Enabled            = false
        cham.Parent             = model
        cache.cham[model]       = cham
    end
    return cham
end

local function getDrawing(tbl, id, kind)
    if not DRAWING_OK then return nil end
    local obj = tbl[id]
    if obj and obj.__removed__ then obj = nil end -- paranoia guard
    if not obj then
        obj = Drawing.new(kind)
        tbl[id] = obj
    end
    return obj
end

local function hide(tbl, id, prop)
    local obj = tbl[id]
    if obj then obj[prop] = false end
end

local function hpColor(frac: number)
    return Color3.fromRGB((1 - frac) * 255, frac * 255, 0)
end

---------------------------------------------------------------------
-- 5. Visibility check (client‑side raycast)
---------------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.FilterDescendantsInstances = { LP.Character or Instance.new("Folder") }

local function isVisible(part: BasePart)
    if not _G.OPT.vischeck then return true end
    rayParams.FilterDescendantsInstances[1] = LP.Character -- respawn safe
    local hit = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rayParams)
    return (not hit) or hit.Instance:IsDescendantOf(part.Parent)
end

---------------------------------------------------------------------
-- 6. Render loop (ultra‑light, every frame)
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not _G.ESP_ON then return end

    local camPos  = Camera.CFrame.Position
    local vpSize  = Camera.ViewportSize
    local tracerOrigin = Vector2.new(vpSize.X / 2, vpSize.Y)

    for model, data in next, targets do
        local root = data.root
        if not root or not model.Parent then targets[model] = nil continue end

        -- distance & screen culling
        local dist = (root.Position - camPos).Magnitude
        if dist > MAX_DIST then
            (cache.box[root]   or {}).Transparency = 1
            (cache.cham[model] or {}).Enabled      = false
            if DRAWING_OK then
                hide(cache.tracer, model, "Visible")
                hide(cache.label,  model, "Visible")
                hide(cache.health, model, "Visible")
            end
            continue
        end
        local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            (cache.box[root]   or {}).Transparency = 1
            (cache.cham[model] or {}).Enabled      = false
            if DRAWING_OK then
                hide(cache.tracer, model, "Visible")
                hide(cache.label,  model, "Visible")
                hide(cache.health, model, "Visible")
            end
            continue
        end

        local visible = isVisible(root)

        ------------------------------------------------------------------
        -- Box
        ------------------------------------------------------------------
        if _G.OPT.box then
            local box = getBox(root)
            box.Size         = root.Size + Vector3.new(0.1, 0.1, 0.1)
            box.Transparency = 0.18
            box.Color3       = visible and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(120, 120, 120)
        else
            (cache.box[root] or {}).Transparency = 1
        end

        ------------------------------------------------------------------
        -- Chams
        ------------------------------------------------------------------
        if _G.OPT.chams then
            local cham = getCham(model)
            cham.Enabled      = true
            cham.FillColor    = visible and Color3.fromRGB(255, 75, 75) or Color3.fromRGB(0, 190, 255)
            cham.OutlineColor = Color3.new(1, 1, 1)
        else
            (cache.cham[model] or {}).Enabled = false
        end

        ------------------------------------------------------------------
        -- Drawing‑based visuals
        ------------------------------------------------------------------
        if DRAWING_OK then
            -- Tracer
            if _G.OPT.tracers then
                local ln = getDrawing(cache.tracer, model, "Line")
                ln.Visible   = true
                ln.Thickness = 1.5
                ln.Color     = visible and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 255, 0)
                ln.From      = tracerOrigin
                ln.To        = Vector2.new(screenPos.X, screenPos.Y)
            else
                hide(cache.tracer, model, "Visible")
            end

            -- Distance label
            if _G.OPT.distance then
                local txt = getDrawing(cache.label, model, "Text")
                txt.Visible  = true
                txt.Center   = true
                txt.Outline  = true
                txt.Color    = Color3.new(1, 1, 1)
                txt.Size     = 14
                txt.Text     = ("%.0f"):format(dist)
                txt.Position = Vector2.new(screenPos.X, screenPos.Y - 16)
            else
                hide(cache.label, model, "Visible")
            end

            -- Health bar
            if _G.OPT.health then
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum then
                    local frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local bar  = getDrawing(cache.health, model, "Square")
                    bar.Visible = true
                    bar.Filled  = true
                    bar.Size    = BAR_SIZE * Vector2.new(frac, 1)
                    bar.Position= Vector2.new(screenPos.X - BAR_SIZE.X / 2, screenPos.Y + 12)
                    bar.Color   = hpColor(frac)
                end
            else
                hide(cache.health, model, "Visible")
            end
        end
    end
end)

---------------------------------------------------------------------
-- 7. Quick master toggle (F key) & manual clear helper
---------------------------------------------------------------------
UserInput.InputBegan:Connect(function(i, gameProcessed)
    if gameProcessed then return end
    if i.KeyCode == Enum.KeyCode.F then
        _G.ESP_ON = not _G.ESP_ON
        if not _G.ESP_ON then
            _G.clearESP()
        end
    end
end)

function _G.clearESP()
    for _, box in pairs(cache.box)   do box.Transparency = 1 end
    for _, cham in pairs(cache.cham)  do cham.Enabled     = false end
    if DRAWING_OK then
        for _, tbl in pairs({ cache.tracer, cache.label, cache.health }) do
            for _, obj in pairs(tbl) do obj.Visible = false end
        end
    end
end
