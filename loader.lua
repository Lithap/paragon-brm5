-- Paragon BRM5 • Rayfield Mini‑ESP (v21 — Turbo‑Expanded, auto‑purge)
-- ▶ Every‑frame draw, bright visuals, tracers/distance clear when NPC dies
--   and when ESP is toggled off or target leaves screen.
-- Key = paragon  •  Right‑Shift opens Rayfield
---------------------------------------------------------------------
-- 0.  Services / locals
---------------------------------------------------------------------
local Players, RunService, Workspace = game:GetService("Players"), game:GetService("RunService"), game:GetService("Workspace")
local LP, Camera = Players.LocalPlayer, Workspace.CurrentCamera
getgenv().SecureMode = true

---------------------------------------------------------------------
-- 1.  Config
---------------------------------------------------------------------
local MAX_DIST   = 1500                      -- ESP range
local BAR_SIZE   = Vector2.new(60, 4)        -- health bar
local DRAW_OK    = pcall(function() return Drawing end)

---------------------------------------------------------------------
-- 2.  State
---------------------------------------------------------------------
local ESP = {
    Enabled = true,
    Opt = {
        box=true, chams=true, tracers=true,
        distance=true, health=true, vischeck=true,
    },
    Tgt   = {},   -- [model] = {root=Part}
    Cache = {
        box     = setmetatable({}, {__mode='k'}),
        cham    = setmetatable({}, {__mode='k'}),
        tracer  = setmetatable({}, {__mode='k'}),
        label   = setmetatable({}, {__mode='k'}),
        health  = setmetatable({}, {__mode='k'}),
    }
}

---------------------------------------------------------------------
-- 3.  Enemy registration
---------------------------------------------------------------------
local function isEnemy(m)
    if not (m:IsA("Model") and m.Name=="Male") then return false end
    for _,c in ipairs(m:GetChildren()) do if c.Name:sub(1,3)=="AI_" then return true end end
end

local function addTarget(m)
    local root=m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso")
    if root then ESP.Tgt[m]={root=root} end
end

local function purgeModel(m)
    -- hide all visuals tied to this model then drop handle
    hide(ESP.Cache.tracer, m)
    hide(ESP.Cache.label,  m)
    hide(ESP.Cache.health, m)
    local ch=ESP.Cache.cham[m]; if ch then ch.Enabled=false end
    local t=ESP.Tgt[m]; if t and t.root then local bx=ESP.Cache.box[t.root]; if bx then bx.Transparency=1 end end
    ESP.Tgt[m]=nil
end

for _,d in ipairs(Workspace:GetDescendants()) do if isEnemy(d) then addTarget(d) end end
Workspace.DescendantAdded:Connect(function(d) if isEnemy(d) then task.defer(addTarget,d) end end)
Workspace.DescendantRemoving:Connect(function(d) purgeModel(d) end)

---------------------------------------------------------------------
-- 4.  Factory helpers
---------------------------------------------------------------------
local function getBox(p)
    local b=ESP.Cache.box[p]
    if not b or not b.Parent then b=Instance.new("BoxHandleAdornment"); b.AlwaysOnTop=true; b.ZIndex=10; b.Adornee=p; b.Parent=p; ESP.Cache.box[p]=b end
    return b
end
local function getCham(m)
    local h=ESP.Cache.cham[m]
    if not h or not h.Parent then h=Instance.new("Highlight"); h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Parent=m; ESP.Cache.cham[m]=h end
    return h
end
local function getDraw(tbl,id,k) if not DRAW_OK then return end; local o=tbl[id] or Drawing.new(k); tbl[id]=o; return o end
function hide(tbl,id) local o=tbl[id]; if o then o.Visible=false end end
local function hp(frac) return Color3.fromRGB((1-frac)*255,frac*255,0) end
local function canSee(part)
    if not ESP.Opt.vischeck then return true end
    local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Blacklist; rp.FilterDescendantsInstances={LP.Character}
    local hit=Workspace:Raycast(Camera.CFrame.Position, part.Position-Camera.CFrame.Position, rp)
    return(not hit)or hit.Instance:IsDescendantOf(part.Parent)
end
local function clearAll()
    for _,b in pairs(ESP.Cache.box)  do b.Transparency=1 end
    for _,h in pairs(ESP.Cache.cham) do h.Enabled=false end
    if DRAW_OK then for _,tbl in pairs{ESP.Cache.tracer,ESP.Cache.label,ESP.Cache.health} do for _,o in pairs(tbl)do o.Visible=false end end end
end

---------------------------------------------------------------------
-- 5.  Render loop
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not ESP.Enabled then return end
    local cam=Camera.CFrame.Position; local vp=Camera.ViewportSize; local origin=Vector2.new(vp.X/2,vp.Y)
    for mdl,t in pairs(ESP.Tgt) do
        local root=t.root; if not root or not mdl.Parent then purgeModel(mdl) continue end
        local dist=(root.Position-cam).Magnitude; if dist>MAX_DIST then purgeModel(mdl) continue end
        local scr,onScr=Camera:WorldToViewportPoint(root.Position); local vis=canSee(root)

        -- BOX -------------------------------------------------------
        local bx=getBox(root)
        if ESP.Opt.box and onScr then
            bx.Size=root.Size+Vector3.new(0.1,0.1,0.1)
            bx.Transparency=0.18
            bx.Color3=vis and Color3.fromRGB(0,255,30) or Color3.fromRGB(180,180,180)
        else bx.Transparency=1 end

        -- CHAMS -----------------------------------------------------
        local ch=getCham(mdl)
        if ESP.Opt.chams then
            ch.Enabled=true
            ch.FillColor=vis and Color3.fromRGB(255,60,60) or Color3.fromRGB(0,200,255)
            ch.FillTransparency=0.08
            ch.OutlineColor=Color3.new(1,1,1)
            ch.OutlineTransparency=0.05
        else ch.Enabled=false end

        if not DRAW_OK then continue end

        -- TRACER ----------------------------------------------------
        if ESP.Opt.tracers and onScr then
            local tr=getDraw(ESP.Cache.tracer,mdl,"Line"); tr.Visible=true; tr.Thickness=2
            tr.Color=vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,255,0)
            tr.From,tr.To=origin,Vector2.new(scr.X,scr.Y)
        else hide(ESP.Cache.tracer,mdl) end

        -- DISTANCE --------------------------------------------------
        if ESP.Opt.distance and onScr then
            local lb=getDraw(ESP.Cache.label,mdl,"Text"); lb.Visible=true; lb.Center=true; lb.Size=15; lb.Outline=true
            lb.Color=Color3.new(1,1,1); lb.Text=("%.0f m"):format(dist); lb.Position=Vector2.new(scr.X,scr.Y-18)
        else hide(ESP.Cache.label,mdl) end

        -- HEALTH ----------------------------------------------------
        if ESP.Opt.health and onScr then
            local hum=mdl:FindFirstChildOfClass("Humanoid"); if hum then local f=math.clamp(hum.Health/hum.MaxHealth,0,1)
                local hb=getDraw(ESP.Cache.health,mdl,"Square"); hb.Visible=true; hb.Filled=true
                hb.Size=BAR_SIZE*Vector2.new(f,1); hb.Position=Vector2.new(scr.X-BAR_SIZE.X/2,scr.Y+14); hb.Color=hp(f)
            end
        else hide(ESP.Cache.health,mdl) end
    end
end)

---------------------------------------------------------------------
-- 6.  Rayfield GUI
---------------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()
local Window = Rayfield:CreateWindow({Name="Paragon BRM5 • Mini‑ESP",LoadingTitle="Paragon BRM5",LoadingSubtitle="Turbo Expanded",Theme="Midnight",KeySystem=true,KeySettings={Title="Paragon Key",Subtitle="Enter key",Note="Key is: paragon",SaveKey=true,Key={"paragon"}}})
local tab = Window:CreateTab("ESP","eye")

tab:CreateLabel("Master")
 tab:CreateToggle({Name="Enable ESP",CurrentValue=true,Callback=function(v)ESP.Enabled=v; if not v then clearAll() end end})

tab:CreateLabel("Modules")
for f,l in pairs{box="3‑D Box",chams="Chams",tracers="Tracers",distance="Distance",health="Health Bar",vischeck="VisCheck"} do
    tab:CreateToggle({Name=l,CurrentValue=ESP.Opt[f],Callback=function(v)ESP.Opt[f]=v; if not v then clearAll() end end})
end
Rayfield
