--[[
  Paragon BRM5 • **Elite ESP‑Only** (v25)
  ──────────────────────────────────────────────────────────────────────────
  • Pure ESP implementation – Fly module fully removed for maximum stability.
  • BRM5‑safe: uses Roblox Highlight & BoxHandleAdornment with smart capping
    (chams limited to 30 highlights to avoid roblox 31+ crash).
  • Lightning‑fast: zero waits, single RenderStepped loop, memory‑weak caches.
  • Hot‑reload & hot‑clear: toggling modules or master instantly wipes visuals.
  • Keybinds:
      ▸ **Right‑Shift**  – open/close Rayfield UI
      ▸ **F**           – quick master toggle (Enable ESP)
  • Built by Paragon – engineered for competitive play.
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
getgenv().SecureMode = true

---------------------------------------------------------------------
-- 1. Configuration / State
---------------------------------------------------------------------
local MAX_DIST   = 1500                -- studs
local MAX_HL     = 30                  -- Roblox highlight limit

local ESP = {
    Enabled = true,
    Opt     = { box = true, chams = true, vischeck = true },
    Tgt     = {},                     -- [Model] = {root = BasePart}
    Cache   = {
        box  = setmetatable({}, { __mode = "k" }), -- [BasePart] = BoxHandleAdornment
        cham = setmetatable({}, { __mode = "k" }), -- [Model]    = Highlight
    },
    ChamCt = 0,
}

---------------------------------------------------------------------
-- 2. Target acquisition (BRM5 NPC logic)
---------------------------------------------------------------------
local function isEnemy(model: Instance): boolean
    if not (model:IsA("Model") and model.Name == "Male") then return false end
    for _, c in ipairs(model:GetChildren()) do
        if c.Name:sub(1, 3) == "AI_" then return true end
    end
end

local function addTarget(model: Model)
    local root = model:FindFirstChild("HumanoidRootPart")
              or model:FindFirstChild("Head")
              or model:FindFirstChild("UpperTorso")
    if root then ESP.Tgt[model] = { root = root } end
end

-- Pre‑scan existing map
for _, inst in ipairs(Workspace:GetDescendants()) do
    if isEnemy(inst) then addTarget(inst) end
end

-- Live updates
Workspace.DescendantAdded:Connect(function(inst)
    if isEnemy(inst) then task.defer(addTarget, inst) end
end)
Workspace.DescendantRemoving:Connect(function(inst)
    ESP.Tgt[inst] = nil
end)

---------------------------------------------------------------------
-- 3. Factory helpers (lazy creation, weak refs)
---------------------------------------------------------------------
local function boxOf(part: BasePart)
    local box = ESP.Cache.box[part]
    if not box or not box.Parent then
        box = Instance.new("BoxHandleAdornment")
        box.AlwaysOnTop   = true
        box.ZIndex        = 10
        box.Adornee       = part
        box.Size          = part.Size + Vector3.new(0.1, 0.1, 0.1)
        box.Transparency  = 1
        box.Parent        = part
        ESP.Cache.box[part] = box
    end
    return box
end

local function chamOf(model: Model)
    if ESP.ChamCt >= MAX_HL then return nil end
    local hl = ESP.Cache.cham[model]
    if not hl or not hl.Parent then
        hl = Instance.new("Highlight")
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency     = 0.08
        hl.OutlineTransparency  = 0.05
        hl.Parent = model
        ESP.Cache.cham[model] = hl
        ESP.ChamCt += 1
    end
    return hl
end

local function clearESP()
    for _, b in next, ESP.Cache.box  do b.Transparency = 1 end
    for _, h in next, ESP.Cache.cham do h.Enabled = false end
end

---------------------------------------------------------------------
-- 4. VisCheck helper (client‑side raycast)
---------------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.FilterDescendantsInstances = { LP.Character }

local function canSee(part: BasePart): boolean
    if not ESP.Opt.vischeck then return true end
    rayParams.FilterDescendantsInstances[1] = LP.Character -- hot‑swap (respawn safe)
    local hit = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rayParams)
    return (not hit) or hit.Instance:IsDescendantOf(part.Parent)
end

---------------------------------------------------------------------
-- 5. Render loop (single, ultra‑light)
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not ESP.Enabled then return end

    local camPos = Camera.CFrame.Position
    for mdl, t in next, ESP.Tgt do
        local root = t.root
        if not root or not mdl.Parent then ESP.Tgt[mdl] = nil continue end

        -- Distance & on‑screen culling
        local distSq = (root.Position - camPos).Magnitude
        if distSq > MAX_DIST then
            (ESP.Cache.box[root]  or {}).Transparency = 1
            (ESP.Cache.cham[mdl] or {}).Enabled       = false
            continue
        end
        local _, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            (ESP.Cache.box[root]  or {}).Transparency = 1
            (ESP.Cache.cham[mdl] or {}).Enabled       = false
            continue
        end

        -- Visibility test
        local visible = canSee(root)

        -- Box module
        if ESP.Opt.box then
            local box = boxOf(root)
            box.Size         = root.Size + Vector3.new(0.1, 0.1, 0.1)
            box.Transparency = 0.18
            box.Color3       = visible and Color3.fromRGB(0, 255, 35) or Color3.fromRGB(160, 160, 160)
        else
            (ESP.Cache.box[root] or {}).Transparency = 1
        end

        -- Chams module
        if ESP.Opt.chams then
            local hl = chamOf(mdl)
            if hl then
                hl.Enabled   = true
                hl.FillColor = visible and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(0, 200, 255)
                hl.OutlineColor = Color3.new(1, 1, 1)
            end
        else
            (ESP.Cache.cham[mdl] or {}).Enabled = false
        end
    end
end)

---------------------------------------------------------------------
-- 6. Quick‑toggle (F key) & respawn safety
---------------------------------------------------------------------
UserInput.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Enum.KeyCode.F then
        ESP.Enabled = not ESP.Enabled
        if not ESP.Enabled then clearESP() end
    end
end)

LP.CharacterAdded:Connect(function()
    -- ensure new character isn\'t part of vischeck blacklist
    rayParams.FilterDescendantsInstances[1] = LP.Character
end)

---------------------------------------------------------------------
-- 7. Rayfield UI (minimal, responsive)
---------------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()
local win = Rayfield:CreateWindow({
    Name           = "Paragon BRM5 • Elite ESP",
    LoadingTitle   = "Paragon BRM5",
    LoadingSubtitle= "v25 – ESP‑Only",
    Theme          = "Midnight",
    KeySystem      = true,
    KeySettings    = {
        Title     = "Paragon Key",
        Subtitle  = "Enter key",
        Note      = "Key is: paragon",
        SaveKey   = true,
        Key       = { "paragon" },
    }
})
local tab = win:CreateTab("ESP", "eye")

tab:CreateToggle({
    Name          = "Enable ESP (F)",
    CurrentValue  = ESP.Enabled,
    Callback      = function(v) ESP.Enabled = v if not v then clearESP() end end,
})

for field, label in pairs({ box = "3‑D Box", chams = "Chams", vischeck = "VisCheck" }) do
    tab:CreateToggle({
        Name         = label,
        CurrentValue = ESP.Opt[field],
        Callback     = function(v)
            ESP.Opt[field] = v
            clearESP()
        end,
    })
end

Rayfield:Notify({
    Title    = "Paragon BRM5",
    Content  = "Elite ESP‑Only v25 loaded — Right‑Shift opens UI",
    Duration = 5,
})
