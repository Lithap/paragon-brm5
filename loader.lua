-- Paragon BRM5 • Mini‑ESP + Fly (v23 — stability patch)
--  • Fly toggle now works from Rayfield (re‑attaches on Respawn)
--  • Chams show for all NPCs (switches to Box mode after Roblox’s 31‑Highlight limit)
--  • Head/Root fallback improved → no more missing ESP on some enemies
--  • Clean master toggle (clears + disables BV)
--  • Removed lingering tracer/distance code remnants
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
local MAX_DIST   = 1500
local DRAW_OK    = pcall(function() return Drawing end)
local MAX_HIGHLIGHTS = 30                -- Roblox limit ~31

local ESP = {
    Enabled = true,
    Opt = { box=true, chams=true, vischeck=true },
    Tgt = {},
    Cache = {
        box  = setmetatable({}, {__mode='k'}),
        cham = setmetatable({}, {__mode='k'}),
    },
    ChamCount = 0
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
    local root = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso")
    if root then ESP.Tgt[m] = {root=root} end
end
for _,d in ipairs(Workspace:GetDescendants()) do if isEnemy(d) then addTarget(d) end end
Workspace.DescendantAdded:Connect(function(d) if isEnemy(d) then task.defer(addTarget,d) end end)
Workspace.DescendantRemoving:Connect(function(d) ESP.Tgt[d] = nil end)

---------------------------------------------------------------------
-- 3. Factories & Helpers
---------------------------------------------------------------------
local function getBox(p)
    local b=ESP.Cache.box[p]
    if not b or not b.Parent then b=Instance.new("BoxHandleAdornment"); b.AlwaysOnTop=true; b.ZIndex=10; b.Adornee=p; b.Parent=p; ESP.Cache.box[p]=b end
    return b
end
local function getCham(m)
    -- respect Roblox limit
    if ESP.ChamCount >= MAX_HIGHLIGHTS then return nil end
    local h=ESP.Cache.cham[m]
    if not h or not h.Parent then
        h=Instance.new("Highlight"); h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Parent=m; ESP.Cache.cham[m]=h; ESP.ChamCount+=1
    end
    return h
end
local function hideCham(m)
    local h=ESP.Cache.cham[m]; if h then h.Enabled=false end
end
local function hideBox(p)
    local b=ESP.Cache.box[p]; if b then b.Transparency=1 end
end
local function LOS(part)
    if not ESP.Opt.vischeck then return true end
    local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Blacklist; rp.FilterDescendantsInstances={LP.Character}
    local hit=Workspace:Raycast(Camera.CFrame.Position, part.Position-Camera.CFrame.Position, rp)
    return(not hit)or hit.Instance:IsDescendantOf(part.Parent)
end
local function clearESP()
    for _,b in pairs(ESP.Cache.box)  do b.Transparency=1 end
    for _,h in pairs(ESP.Cache.cham) do h.Enabled=false end
end

---------------------------------------------------------------------
-- 4. Fly Engine
---------------------------------------------------------------------
local flyBV; local humanoid; local move=Vector3.zero
local keyMap={W=Vector3.new(0,0,-1),S=Vector3.new(0,0,1),A=Vector3.new(-1,0,0),D=Vector3.new(1,0,0)}
local function setFly(on)
    Fly.Active = on
    if on then
        local char=LP.Character or LP.CharacterAdded:Wait(); humanoid=char:WaitForChild("Humanoid"); local hrp=char:WaitForChild("HumanoidRootPart")
        flyBV=Instance.new("BodyVelocity"); flyBV.MaxForce=Vector3.new(1e5,1e5,1e5); flyBV.P=12e3; flyBV.Parent=hrp; humanoid.PlatformStand=true
    else
        if flyBV then flyBV:Destroy(); flyBV=nil end; if humanoid then humanoid.PlatformStand=false end; move=Vector3.zero
    end
end

UserInput.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.F then setFly(not Fly.Active) end
    local v=keyMap[i.KeyCode.Name]; if v and Fly.Active then move+=v end
end)
UserInput.InputEnded:Connect(function(i,gp)
    if gp then return end; local v=keyMap[i.KeyCode.Name]; if v and Fly.Active then move-=v end
end)

RunService.Heartbeat:Connect(function()
    if Fly.Active and flyBV and flyBV.Parent then
        local dir=(move.Magnitude>0)and move.Unit or Vector3.zero
        dir=Camera.CFrame:VectorToWorldSpace(dir)
        flyBV.Velocity=dir*Fly.Speed
    end
end)

LP.CharacterAdded:Connect(function() if Fly.Active then setFly(true) end end)

---------------------------------------------------------------------
-- 5. Render loop
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not ESP.Enabled then return end
    local cam=Camera.CFrame.Position
    for mdl,t in pairs(ESP.Tgt) do
        local root=t.root; if not root or not mdl.Parent then ESP.Tgt[mdl]=nil; hideBox(root); hideCham(mdl) continue end
        local dist=(root.Position-cam).Magnitude
        if dist>MAX_DIST then hideBox(root); hideCham(mdl) continue end
        local scr,onScr=Camera:WorldToViewportPoint(root.Position); if not onScr then hideBox(root); hideCham(mdl) continue end
        local vis=LOS(root)
        -- Box
        if ESP.Opt.box then
            local bx=getBox(root); bx.Size=root.Size+Vector3.new(0.1,0.1,0.1); bx.Transparency=0.18; bx.Color3=vis and Color3.fromRGB(0,255,35)or Color3.fromRGB(160,160,160)
        else hideBox(root) end
        -- Chams (limited count)
        if ESP.Opt.chams then
            local ch=getCham(mdl); if ch then ch.Enabled=true; ch.FillColor=vis and Color3.fromRGB(255,60,60)or Color3.fromRGB(0,200,255); ch.FillTransparency=0.08; ch.OutlineColor=Color3.new(1,1,1); ch.OutlineTransparency=0.05 end
        else hideCham(mdl) end
    end
end)

---------------------------------------------------------------------
-- 6. UI (Rayfield)
---------------------------------------------------------------------
local Rayfield=loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()
local Window=Rayfield:CreateWindow({Name="Paragon BRM5 • Lite ESP",LoadingTitle="Paragon BRM5",LoadingSubtitle="v23",Theme="Midnight",KeySystem=true,KeySettings={Title="Paragon Key",Subtitle="Enter key",Note="Key is: paragon",SaveKey=true,Key={"paragon"}}})
local tab=Window:CreateTab("ESP","eye")

-- Master
tab:CreateToggle({Name="Enable ESP",CurrentValue=true,Callback=function(v)ESP.Enabled=v; if not v then clearESP() end end})

-- Module toggles
for flag,label in pairs{box="3-D Box",chams="Chams",vischeck="VisCheck"} do
    tab:CreateToggle({Name=label,CurrentValue=ESP.Opt[flag],Callback=function(v)ESP.Opt[flag]=v; clearESP() end})
end

-- Fly toggle
tab:CreateToggle({Name="Fly (F)",CurrentValue=false,Callback=function(v) setFly(v) end})

Rayfield:Notify({Title="Paragon BRM5",Content="ESP v23 loaded — Right‑Shift opens UI",Duration=5})
