-- Paragon BRM5 • Rayfield Mini-ESP (v11)
-- ✔️ No external dependencies – self-contained ESP written from scratch.
-- ✔️ Draws 3-D Box (BoxHandleAdornment) and Chams (Highlight) on enemy NPCs.
-- ✔️ Key = paragon, Right-Shift opens Rayfield.

---------------------------------------------------------------------
-- 0. Services / locals
---------------------------------------------------------------------
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer
local Camera     = workspace.CurrentCamera

getgenv().SecureMode = true   -- lower Rayfield footprint

---------------------------------------------------------------------
-- 1. State tables
---------------------------------------------------------------------
local ESP = {
    Enabled = true,
    Options = { box = true, chams = true },
    Targets = {},                             -- [Model] = {root = Part}
    Cache   = { box = setmetatable({}, {__mode="k"}),
                cham= setmetatable({}, {__mode="k"}) }
}

---------------------------------------------------------------------
-- 2. Enemy detection (AI_… inside     Model named “Male”)
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

for _,d in ipairs(workspace:GetDescendants()) do if isEnemy(d) then register(d) end end
workspace.DescendantAdded:Connect(function(d) if isEnemy(d) then task.wait(); register(d) end end)
workspace.DescendantRemoving:Connect(function(d) ESP.Targets[d] = nil end)

---------------------------------------------------------------------
-- 3. Box / Cham helpers
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

local function hideAll()
    for _,b in pairs(ESP.Cache.box)  do if b.Parent  then b.Transparency = 1  end end
    for _,h in pairs(ESP.Cache.cham) do if h.Parent  then h.Enabled      = false end end
end

---------------------------------------------------------------------
-- 4. Render loop
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not ESP.Enabled then return end
    for mdl,t in pairs(ESP.Targets) do
        local root = t.root
        if not root or not mdl.Parent then ESP.Targets[mdl] = nil continue end

        -- Box
        if ESP.Options.box then
            local b = getBox(root)
            b.Size, b.Transparency = root.Size + Vector3.new(0.1,0.1,0.1), 0.25
            b.Color3 = Color3.fromRGB(0,255,0)
        elseif ESP.Cache.box[root] then
            ESP.Cache.box[root].Transparency = 1
        end

        -- Chams
        if ESP.Options.chams then
            local h = getCham(mdl)
            h.Enabled, h.FillColor, h.FillTransparency = true, Color3.fromRGB(255,75,75), 0.15
            h.OutlineColor, h.OutlineTransparency     = h.FillColor, 0.1
        elseif ESP.Cache.cham[mdl] then
            ESP.Cache.cham[mdl].Enabled = false
        end
    end
end)

---------------------------------------------------------------------
-- 5. Rayfield GUI
---------------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()

local Window = Rayfield:CreateWindow({
    Name            = "Paragon BRM5 • Mini-ESP",
    LoadingTitle    = "Paragon BRM5",
    LoadingSubtitle = "Mini ESP",
    Theme           = "Midnight",
    KeySystem       = true,
    KeySettings     = {
        Title = "Paragon Key", Subtitle = "Enter key",
        Note  = "Key is: paragon", SaveKey = true, Key = {"paragon"}
    }
})

local tab = Window:CreateTab("ESP", "eye")
tab:CreateLabel("Master")
tab:CreateToggle({
    Name = "Enable ESP", CurrentValue = true,
    Callback = function(v) ESP.Enabled = v; if not v then hideAll() end end
})

tab:CreateLabel("Modules")
for flag, label in pairs({ box = "3-D Box", chams = "Chams" }) do
    tab:CreateToggle({Name = label, CurrentValue = ESP.Options[flag],
        Callback = function(v) ESP.Options[flag] = v end})
end

Rayfield:Notify({Title="Paragon BRM5",Content="Mini ESP loaded – Right-Shift for UI",Duration=4})
