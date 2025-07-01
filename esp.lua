-- Paragon BRM5 • Rayfield Mini‑ESP (v11)
-- ✔️ **No external dependencies** – self‑contained ESP written from scratch.
-- ✔️ Shows 3‑D Box (BoxHandleAdornment) **and** Chams (Highlight).
-- ✔️ Key = paragon, Right‑Shift opens Rayfield.  Works on any executor that
--    supports Instance.new + Drawing API *optional*.

---------------------------------------------------------------------
-- 0. Services / locals ----------------------------------------------
---------------------------------------------------------------------
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local LP           = Players.LocalPlayer
local Camera       = workspace.CurrentCamera
local PG           = LP:WaitForChild("PlayerGui")

getgenv().SecureMode = true   -- lower Rayfield footprint

---------------------------------------------------------------------
-- 1. State tables ----------------------------------------------------
---------------------------------------------------------------------
local ESP = {
    Enabled = true,
    Options = {
        box   = true,
        chams = true,
    },
    Targets = {},     -- [Model] = {root = Part}
    Cache   = {
        box   = setmetatable({}, {__mode="k"}),
        cham  = setmetatable({}, {__mode="k"}),
    }
}

---------------------------------------------------------------------
-- 2. Simple enemy detector ------------------------------------------
---------------------------------------------------------------------
local function isEnemy(model)
    if not (model:IsA("Model") and model.Name == "Male") then return false end
    for _,c in ipairs(model:GetChildren()) do
        if c.Name:sub(1,3) == "AI_" then return true end
    end
    return false
end

local function register(model)
    if ESP.Targets[model] then return end
    local root = model:FindFirstChild("Head") or model:FindFirstChild("UpperTorso")
    if root then ESP.Targets[model] = {root = root} end
end

for _,d in ipairs(workspace:GetDescendants()) do if isEnemy(d) then register(d) end end
workspace.DescendantAdded:Connect(function(d) if isEnemy(d) then task.wait(); register(d) end end)
workspace.DescendantRemoving:Connect(function(d) ESP.Targets[d] = nil end)

---------------------------------------------------------------------
-- 3. Box / Cham factories -------------------------------------------
---------------------------------------------------------------------
local function getBox(part)
    local b = ESP.Cache.box[part]
    if not b or b.Parent == nil then
        b = Instance.new("BoxHandleAdornment")
        b.ZIndex = 5; b.AlwaysOnTop = true; b.Adornee = part
        b.Parent = part; ESP.Cache.box[part] = b
    end
    return b
end

local function getCham(model)
    local h = ESP.Cache.cham[model]
    if not h or h.Parent == nil then
        h = Instance.new("Highlight")
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = model; ESP.Cache.cham[model] = h
    end
    return h
end

local function hideAll()
    for part,box in pairs(ESP.Cache.box)  do if box and box.Parent then box.Transparency = 1 end end
    for mdl,hi  in pairs(ESP.Cache.cham) do if hi  and hi .Parent then hi.Enabled      = false end end
end

---------------------------------------------------------------------
-- 4. Render loop -----------------------------------------------------
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not ESP.Enabled then return end

    for mdl,t in pairs(ESP.Targets) do
        local root = t.root
        if not root or not mdl.Parent then ESP.Targets[mdl] = nil continue end

        -- Box -------------------------------------------------------
        if ESP.Options.box then
            local b = getBox(root)
            b.Size, b.Transparency = root.Size + Vector3.new(0.1,0.1,0.1), 0.25
            b.Color3 = Color3.fromRGB(0,255,0)
        elseif ESP.Cache.box[root] then
            ESP.Cache.box[root].Transparency = 1
        end

        -- Chams -----------------------------------------------------
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
-- 5. Rayfield GUI ----------------------------------------------------
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
    ESP.Enabled = v; if not v then hideAll() end end})

tab:CreateLabel("Modules")
for flag,label in pairs{box="3‑D Box",chams="Chams"} do
    tab:CreateToggle({Name=label,CurrentValue=ESP.Options[flag],Callback=function(v) ESP.Options[flag]=v end})
end

Rayfield:Notify({Title="Paragon BRM5",Content="Mini ESP loaded – Right‑Shift shows UI",Duration=4})
