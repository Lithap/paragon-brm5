-- Paragon BRM5 • Rayfield Mini‑ESP (v19)
-- Key = paragon • Right‑Shift opens Rayfield
---------------------------------------------------------------------
-- 0. Services / locals
---------------------------------------------------------------------
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local LP         = Players.LocalPlayer
local Camera     = Workspace.CurrentCamera
getgenv().SecureMode = true
---------------------------------------------------------------------
-- 1. Settings & state
---------------------------------------------------------------------
local UPDATE_HZ  = 30                    -- throttle (Hz)
local MAX_DIST   = 1500                  -- render distance
local BAR_SIZE   = Vector2.new(50,4)
local DRAWING_OK = pcall(function() return Drawing end)
local ESP = {
    Enabled = true,
    Options = {
        headbox  = true,
        box2d    = true,
        chams    = true,
        tracers  = true,
        distance = true,
        health   = true,
        vischeck = true,
    },
    Targets = {},
    Cache   = {
        headbox = setmetatable({}, {__mode="k"}),
        box2d   = setmetatable({}, {__mode="k"}),
        cham    = setmetatable({}, {__mode="k"}),
        tracer  = setmetatable({}, {__mode="k"}),
        label   = setmetatable({}, {__mode="k"}),
        health  = setmetatable({}, {__mode="k"}),
    }
}
---------------------------------------------------------------------
-- 2. Enemy detector
---------------------------------------------------------------------
local function isEnemy(m)
    if not (m:IsA("Model") and m.Name == "Male") then return false end
    for _,c in ipairs(m:GetChildren()) do if c.Name:sub(1,3) == "AI_" then return true end end
end
local function register(m)
    if ESP.Targets[m] then return end
    local root=m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("UpperTorso")
    local head=m:FindFirstChild("Head")
    if root and head then ESP.Targets[m]={root=root,head=head,model=m} end
end
for _,d in ipairs(Workspace:GetDescendants()) do if isEnemy(d) then register(d) end end
Workspace.DescendantAdded:Connect(function(d) if isEnemy(d) then task.wait(); register(d) end end)
Workspace.DescendantRemoving:Connect(function(d) ESP.Targets[d] = nil end)
---------------------------------------------------------------------
-- 3. Factories
---------------------------------------------------------------------
local function getHeadBox(part)
    local b=ESP.Cache.headbox[part]
    if not b or b.Parent==nil then
        b=Instance.new("BoxHandleAdornment"); b.AlwaysOnTop,b.ZIndex,b.Adornee=true,5,part
        b.Size=Vector3.new(0.6,0.8,0.6); b.Parent=part; ESP.Cache.headbox[part]=b
    end; return b
end
local function getCham(m)
    local h=ESP.Cache.cham[m]
    if not h or h.Parent==nil then
        h=Instance.new("Highlight"); h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Parent=m; ESP.Cache.cham[m]=h
    end; return h
end
local function getDraw(tbl,id,kind)
    if not DRAWING_OK then return end
    local o=tbl[id]; if not o then o=Drawing.new(kind); tbl[id]=o end; return o
end
local function hide(tbl,id) local o=tbl[id]; if o then o.Visible=false end end
local function hpColor(f) return Color3.fromRGB((1-f)*255,f*255,0) end
local function lineOfSight(part)
    if not ESP.Options.vischeck then return true end
    local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Blacklist; rp.FilterDescendantsInstances={LP.Character}
    local hit=Workspace:Raycast(Camera.CFrame.Position,part.Position-Camera.CFrame.Position,rp)
    return (not hit) or hit.Instance:IsDescendantOf(part.Parent)
end
local function clear()
    for _,b in pairs(ESP.Cache.headbox) do b.Transparency=1 end
    for _,h in pairs(ESP.Cache.cham)    do h.Enabled=false end
    if DRAWING_OK then
        for _,t in pairs{ESP.Cache.box2d,ESP.Cache.tracer,ESP.Cache.label,ESP.Cache.health} do for _,o in pairs(t)do o.Visible=false end end
    end
end
---------------------------------------------------------------------
-- 4. Render loop
---------------------------------------------------------------------
local acc=0
RunService.RenderStepped:Connect(function(dt)
    if not ESP.Enabled then return end
    acc+=dt; if acc<1/UPDATE_HZ then return end; acc=0
    local camPos=Camera.CFrame.Position; local vp=Camera.ViewportSize; local TRACER_ORG=Vector2.new(vp.X/2,vp.Y)
    for mdl,t in pairs(ESP.Targets) do
        local root,head=t.root,t.head
        if not root or not mdl.Parent then ESP.Targets[mdl]=nil continue end
        local dist=(root.Position-camPos).Magnitude; if dist>MAX_DIST then hide(ESP.Cache.box2d,mdl); hide(ESP.Cache.tracer,mdl); hide(ESP.Cache.label,mdl); hide(ESP.Cache.health,mdl); getHeadBox(head).Transparency=1; getCham(mdl).Enabled=false continue end
        local screen,onScr=Camera:WorldToViewportPoint(root.Position); local vis=lineOfSight(root)
        -- Head‑Box
        local hb=getHeadBox(head); if ESP.Options.headbox and onScr then hb.Transparency=0.25; hb.Color3=vis and Color3.fromRGB(0,255,0)or Color3.fromRGB(120,120,120) else hb.Transparency=1 end
        -- Chams
        local ch=getCham(mdl); if ESP.Options.chams then ch.Enabled=true; ch.FillColor=vis and Color3.fromRGB(255,75,75)or Color3.fromRGB(0,190,255); ch.FillTransparency=0.15; ch.OutlineColor,ch.OutlineTransparency=ch.FillColor,0.1 else ch.Enabled=false end
        if DRAWING_OK then
            -- 2‑D Box
            if ESP.Options.box2d and onScr then
                local size=mdl:GetExtentsSize(); local tl=Camera:WorldToViewportPoint(root.Position+Vector3.new(-size.X/2,size.Y/2,0))
                local br=Camera:WorldToViewportPoint(root.Position+Vector3.new(size.X/2,-size.Y/2,0))
                local rect=getDraw(ESP.Cache.box2d,mdl,"Square"); rect.Visible=true; rect.Thickness=1.5; rect.Color=Color3.fromRGB(255,165,0); rect.Filled=false
                rect.Size=Vector2.new(math.abs(br.X-tl.X),math.abs(br.Y-tl.Y)); rect.Position=Vector2.new(math.min(tl.X,br.X), math.min(tl.Y,br.Y))
            else hide(ESP.Cache.box2d,mdl) end
            -- Tracer
            if ESP.Options.tracers then
                local tr=getDraw(ESP.Cache.tracer,mdl,"Line"); tr.Visible=true; tr.Thickness=1.5; tr.Color=vis and Color3.fromRGB(255,0,0)or Color3.fromRGB(255,255,0)
                local endPos=Vector2.new(screen.X,screen.Y); if not onScr then endPos.X=math.clamp(endPos.X,0,vp.X); endPos.Y=math.clamp(endPos.Y,0,vp.Y) end
                tr.From,tr.To=TRACER_ORG,endPos
            else hide(ESP.Cache.tracer,mdl) end
            -- Distance
            if ESP.Options.distance and onScr then
                local lb=getDraw(ESP.Cache.label,mdl,"Text"); lb.Visible=true; lb.Center,lb.Outline,lb.Size=true,true,14; lb.Color=Color3.new(1,1,1); lb.Text=("%.0f"):format(dist); lb.Position=Vector2.new(screen.X,screen.Y-18)
            else hide(ESP.Cache.label,mdl) end
            -- Health
            if ESP.Options.health and onScr then local hum=mdl:FindFirstChildOfClass("Humanoid") if hum then local f=math.clamp(hum.Health/hum.MaxHealth,0,1); local hb2=getDraw(ESP.Cache.health,mdl,"Square"); hb2.Visible=true; hb2.Filled=true; hb2.Size=BAR_SIZE*Vector2.new(f,1); hb2.Position=Vector2.new(screen.X-BAR_SIZE.X/2,screen.Y+14); hb2.Color=hpColor(f) end else hide(ESP.Cache.health,mdl) end
        end
    end
end)
---------------------------------------------------------------------
-- 5. Rayfield GUI
---------------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()
local Window = Rayfield:CreateWindow({Name="Paragon BRM5 • Mini-ESP", LoadingTitle="Paragon BRM5", LoadingSubtitle="Head Box Edition", Theme="Midnight", KeySystem=true, KeySettings={Title="Paragon Key",Subtitle="Enter key",Note="Key is
