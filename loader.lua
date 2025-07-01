-- Paragon BRM5 • Mini‑ESP + Fly (v22)
-- ▶ Features: 3‑D Box ESP, Chams, VisCheck, Toggleable Fly (WASD)
-- ▶ Removed: Tracers, Distance text, Health bar → lighter & faster.
-- Key = paragon • Right‑Shift opens Rayfield
---------------------------------------------------------------------
-- 0. Services / locals
---------------------------------------------------------------------
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UserInput    = game:GetService("UserInputService")
local Workspace    = game:GetService("Workspace")

local LP           = Players.LocalPlayer
local Camera       = Workspace.CurrentCamera

getgenv().SecureMode = true

---------------------------------------------------------------------
-- 1. Settings & State
---------------------------------------------------------------------
local MAX_DIST   = 1500         -- ESP render distance
local DRAW_OK    = pcall(function() return Drawing end)

local ESP = {
    Enabled = true,
    Opt = { box=true, chams=true, vischeck=true },
    Tgt = {},                              -- [Model] = {root=Part}
    Cache = {
        box  = setmetatable({}, {__mode='k'}),
        cham = setmetatable({}, {__mode='k'}),
    }
}

local Fly = { Active = false, Speed = 80 }

---------------------------------------------------------------------
-- 2. Enemy Detection
---------------------------------------------------------------------
local function isEnemy(m)
    if not (m:IsA("Model") and m.Name=="Male") then return false end
    for _,c in ipairs(m:GetChildren()) do if c.Name:sub(1,3)=="AI_" then return true end end
end
local function addTarget(m)
    local root = m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso")
    if root then ESP.Tgt[m] = {root=root} end
end
for _,d in ipairs(Workspace:GetDescendants()) do if isEnemy(d) then addTarget(d) end end
Workspace.DescendantAdded:Connect(function(d) if isEnemy(d) then task.defer(addTarget,d) end end)
Workspace.DescendantRemoving:Connect(function(d) ESP.Tgt[d] = nil end)

---------------------------------------------------------------------
-- 3. Factories
---------------------------------------------------------------------
local function getBox(p)
    local b = ESP.Cache.box[p]
    if not b or not b.Parent then
        b = Instance.new("BoxHandleAdornment")
        b.AlwaysOnTop, b.ZIndex, b.Adornee = true, 10, p
        b.Parent = p
        ESP.Cache.box[p] = b
    end
    return b
end
local function getCham(m)
    local h = ESP.Cache.cham[m]
    if not h or not h.Parent then
        h = Instance.new("Highlight")
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = m
        ESP.Cache.cham[m] = h
    end
    return h
end
local function hideBoxAndCham(mdl, root)
    if root and ESP.Cache.box[root] then ESP.Cache.box[root].Transparency = 1 end
    if ESP.Cache.cham[mdl] then ESP.Cache.cham[mdl].Enabled = false end
end
local function lineOfSight(part)
    if not ESP.Opt.vischeck then return true end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances = {LP.Character}
    local hit = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rp)
    return (not hit) or hit.Instance:IsDescendantOf(part.Parent)
end
local function clearESP()
    for _,b in pairs(ESP.Cache.box)  do b.Transparency = 1 end
    for _,h in pairs(ESP.Cache.cham) do h.Enabled      = false end
end

---------------------------------------------------------------------
-- 4. Fly Logic  (refined)
--    • Toggle key = F  or Rayfield switch
--    • Uses BodyVelocity + sets Humanoid.PlatformStand to keep player upright
--    • WASD input captured each frame so diagonal speed is consistent
---------------------------------------------------------------------
local flyVel  -- BodyVelocity instance
local humanoid
local moveVec = Vector3.zero

-- Helper to (re)attach BodyVelocity
local function enableFly()
    local char = LP.Character or LP.CharacterAdded:Wait()
    humanoid   = char:FindFirstChildOfClass("Humanoid")
    local hrp  = char:WaitForChild("HumanoidRootPart",2)
    if not hrp then return end
    if not flyVel then
        flyVel = Instance.new("BodyVelocity")
        flyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
        flyVel.P = 12e3
    end
    flyVel.Parent = hrp
    humanoid.PlatformStand = true
end
local function disableFly()
    if flyVel then flyVel.Parent = nil end
    if humanoid then humanoid.PlatformStand = false end
    moveVec = Vector3.zero
end

-- Hot‑toggle with F key
UserInput.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.F then
        Fly.Active = not Fly.Active
        if Fly.Active then enableFly() else disableFly() end
    end
end)

-- Movement keys update "moveVec" each frame for smooth blending
local keyMap = {
    [Enum.KeyCode.W] = Vector3.new( 0, 0,-1),
    [Enum.KeyCode.S] = Vector3.new( 0, 0, 1),
    [Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
    [Enum.KeyCode.D] = Vector3.new( 1, 0, 0),
}
UserInput.InputBegan:Connect(function(i,gp) if gp then return end; local v=keyMap[i.KeyCode]; if v then moveVec += v end end)
UserInput.InputEnded:Connect(function(i,gp) if gp then return end; local v=keyMap[i.KeyCode]; if v then moveVec -= v end end)

-- Apply velocity each Heartbeat
RunService.Heartbeat:Connect(function()
    if Fly.Active and flyVel and flyVel.Parent then
        local dir = moveVec.Magnitude > 0 and moveVec.Unit or Vector3.zero
        dir = Camera.CFrame:VectorToWorldSpace(dir)
        flyVel.Velocity = dir * Fly.Speed
    end
end)
---------------------------------------------------------------------
-- 5. Render loop Render loop
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not ESP.Enabled then return end
    local camPos = Camera.CFrame.Position
    for mdl,t in pairs(ESP.Tgt) do
        local root=t.root; if not root or not mdl.Parent then ESP.Tgt[mdl]=nil; hideBoxAndCham(mdl, root) continue end
        local dist=(root.Position-camPos).Magnitude; if dist>MAX_DIST then hideBoxAndCham(mdl, root) continue end

        local scr,onScr = Camera:WorldToViewportPoint(root.Position); if not onScr then hideBoxAndCham(mdl,root) continue end
        local vis = lineOfSight(root)
        -- Box
        if ESP.Opt.box then
            local bx=getBox(root); bx.Size = root.Size + Vector3.new(0.1,0.1,0.1); bx.Transparency=0.18; bx.Color3 = vis and Color3.fromRGB(0,255,35) or Color3.fromRGB(160,160,160)
        else getBox(root).Transparency=1 end
        -- Chams
        if ESP.Opt.chams then
            local ch=getCham(mdl); ch.Enabled=true; ch.FillColor = vis and Color3.fromRGB(255,60,60) or Color3.fromRGB(0,200,255); ch.FillTransparency=0.08; ch.OutlineColor=Color3.new(1,1,1); ch.OutlineTransparency=0.05
        else getCham(mdl).Enabled=false end
    end
end)

---------------------------------------------------------------------
-- 6. Rayfield UI
---------------------------------------------------------------------
local Rayfield=loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()
local Window=Rayfield:CreateWindow({Name="Paragon BRM5 • Mini-ESP",LoadingTitle="Paragon BRM5",LoadingSubtitle="Lite ESP + Fly",Theme="Midnight",KeySystem=true,KeySettings={Title="Paragon Key",Subtitle="Enter key",Note="Key is: paragon",SaveKey=true,Key={"paragon"}}})
local tab=Window:CreateTab("ESP","eye")
---------------------------------------------------------------------
-- Master toggle
---------------------------------------------------------------------
tab:CreateLabel("Master")
tab:CreateToggle({Name="Enable ESP",CurrentValue=true,Callback=function(v)ESP.Enabled=v; if not v then clearESP() end end})
---------------------------------------------------------------------
-- Modules
---------------------------------------------------------------------
tab:CreateLabel("Modules")
local labels={box="3-D Box",chams="Chams",vischeck="VisCheck"}
for f,lbl in pairs(labels) do
    tab:CreateToggle({Name=lbl,CurrentValue=ESP.Opt[f],Callback=function(v)ESP.Opt[f]=v; if not v then clearESP() end end})
end
---------------------------------------------------------------------
-- Fly Toggle
---------------------------------------------------------------------
tab:CreateLabel("Movement")
tab:CreateToggle({Name="Fly (toggle ‑ F)",CurrentValue=false,Callback=function(v)Fly.Active=v end})

Rayfield:Notify({Title="Paragon BRM5",Content="Lite ESP + Fly loaded — Right-Shift opens UI",Duration=5})
