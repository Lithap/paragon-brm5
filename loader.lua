-- Paragon BRM5 • Rayfield Mini‑ESP (v14 – fixes & optimizations)
-- ──────────────────────────────────────────────────────────────────
-- ✅ Modules: Box | Chams | Tracers | Distance | Health | VisCheck
-- ✅ Tracers now anchor to SCREEN‑BOTTOM each frame (no drift)
-- ✅ Clearing logic purges boxes/chams/drawing objects instantly
-- ✅ 30 Hz update; optional FPS‑adaptive mode
-- ✅ Key = paragon • Right‑Shift opens Rayfield
--------------------------------------------------------------------
local Players,RunService,Workspace = game:GetService("Players"),game:GetService("RunService"),game:GetService("Workspace")
local LP,Camera = Players.LocalPlayer,Workspace.CurrentCamera
getgenv().SecureMode = true

-- CONFIG -----------------------------------------------------------
local UPDATE_HZ      = 30          -- fixed refresh; set 0 for adaptive (dt‑based)
local MAX_DIST       = 1500
local BAR_SIZE       = Vector2.new(50,4)
local DRAWING_OK     = pcall(function()return Drawing end)

-- STATE ------------------------------------------------------------
local ESP={Enabled=true,Options={box=true,chams=true,tracers=true,distance=true,health=true,vischeck=true},
           Targets={},Cache={box=setmetatable({}, {__mode="k"}),cham=setmetatable({}, {__mode="k"}),
                            tracer=setmetatable({}, {__mode="k"}),label=setmetatable({}, {__mode="k"}),
                            health=setmetatable({}, {__mode="k"})}}

-- ENEMY REGISTRATION ----------------------------------------------
local function isEnemy(m)
    if not(m:IsA("Model") and m.Name=="Male")then return false end
    for _,c in ipairs(m:GetChildren())do if c.Name:sub(1,3)=="AI_" then return true end end
end
local function register(m)
    if ESP.Targets[m]then return end
    local root=m:FindFirstChild("Head")or m:FindFirstChild("UpperTorso")
    if root then ESP.Targets[m]={root=root} end
end
for _,d in ipairs(Workspace:GetDescendants())do if isEnemy(d)then register(d) end end
Workspace.DescendantAdded:Connect(function(d)if isEnemy(d)then task.wait()register(d)end end)
Workspace.DescendantRemoving:Connect(function(d)ESP.Targets[d]=nil end)

-- FACTORIES --------------------------------------------------------
local function getBox(p)
    local b=ESP.Cache.box[p]
    if not b or not b.Parent then b=Instance.new("BoxHandleAdornment");b.AlwaysOnTop,b.ZIndex,b.Adornee=true,5,p;b.Parent=p;ESP.Cache.box[p]=b end
    return b
end
local function getCham(m)
    local h=ESP.Cache.cham[m]
    if not h or not h.Parent then h=Instance.new("Highlight");h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;h.Parent=m;ESP.Cache.cham[m]=h end
    return h
end
local function getDraw(tbl,id,kind)
    if not DRAWING_OK then return end
    local o=tbl[id] or Drawing.new(kind);tbl[id]=o;return o
end
local function hide(tbl,id) local o=tbl[id];if o then o.Visible=false end end
local function hpColor(f)return Color3.fromRGB((1-f)*255,f*255,0)end

-- VIS‑CHECK --------------------------------------------------------
local function visible(part)
    if not ESP.Options.vischeck then return true end
    local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Blacklist;rp.FilterDescendantsInstances={LP.Character or Instance.new("Folder")}
    local hit=Workspace:Raycast(Camera.CFrame.Position,part.Position-Camera.CFrame.Position,rp)
    return(not hit)or hit.Instance:IsDescendantOf(part.Parent)
end

-- CLEAR ------------------------------------------------------------
local function clear()
    for _,b in pairs(ESP.Cache.box)   do b.Transparency=1 end
    for _,h in pairs(ESP.Cache.cham)  do h.Enabled=false end
    if DRAWING_OK then
        for _,tbl in pairs{ESP.Cache.tracer,ESP.Cache.label,ESP.Cache.health}do for _,o in pairs(tbl)do o.Visible=false end end
    end
end

-- LOOP -------------------------------------------------------------
local acc=0
RunService.RenderStepped:Connect(function(dt)
    if not ESP.Enabled then return end
    acc+=dt; if UPDATE_HZ>0 and acc<1/UPDATE_HZ then return end; acc=0
    local camPos=Camera.CFrame.Position; local tracerOrigin=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)

    for mdl,t in pairs(ESP.Targets)do
        local root=t.root; if not root or not mdl.Parent then ESP.Targets[mdl]=nil continue end
        local dist=(root.Position-camPos).Magnitude; if dist>MAX_DIST then clear(); continue end
        local scr,onScr=Camera:WorldToViewportPoint(root.Position); local vis=visible(root)
        -- BOX
        if ESP.Options.box and onScr then local b=getBox(root);b.Size=root.Size+Vector3.new(0.1,0.1,0.1);b.Transparency=0.25;b.Color3=vis and Color3.fromRGB(255,0,0)or Color3.fromRGB(110,110,110) else if ESP.Cache.box[root] then ESP.Cache.box[root].Transparency=1 end end
        -- CHAMS
        if ESP.Options.chams then local h=getCham(mdl);h.Enabled=true;h.FillColor=vis and Color3.fromRGB(255,75,75)or Color3.fromRGB(0,190,255);h.FillTransparency=0.15;h.OutlineColor,h.OutlineTransparency=h.FillColor,0.1 else if ESP.Cache.cham[mdl] then ESP.Cache.cham[mdl].Enabled=false end end
        if DRAWING_OK then
            -- TRACER
            if ESP.Options.tracers and onScr then local tr=getDraw(ESP.Cache.tracer,mdl,"Line");tr.Visible=true;tr.Thickness=1.5;tr.Color=vis and Color3.fromRGB(255,0,0)or Color3.fromRGB(255,255,0);tr.From,tr.To=tracerOrigin,Vector2.new(scr.X,scr.Y) else hide(ESP.Cache.tracer,mdl) end
            -- DISTANCE
            if ESP.Options.distance and onScr then local lb=getDraw(ESP.Cache.label,mdl,"Text");lb.Visible=true;lb.Center,lb.Outline,lb.Size=true,true,14;lb.Color=Color3.new(1,1,1);lb.Text=("%.0f"):format(dist);lb.Position=Vector2.new(scr.X,scr.Y-16) else hide(ESP.Cache.label,mdl) end
            -- HEALTH
            if ESP.Options.health and onScr then local hum=mdl:FindFirstChildOfClass("Humanoid"); if hum then local f=math.clamp(hum.Health/hum.MaxHealth,0,1);local hb=getDraw(ESP.Cache.health,mdl,"Square");hb.Visible=true;hb.Filled=true;hb.Size=BAR_SIZE*Vector2.new(f,1);hb.Position=Vector2.new(scr.X-BAR_SIZE.X/2,scr.Y+12);hb.Color=hpColor(f) end else hide(ESP.Cache.health,mdl) end
        end
    end
end)

-- RAYFIELD GUI ------------------------------------------------------
local Rayfield=loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()
local Window=Rayfield:CreateWindow({Name="Paragon BRM5 • Mini‑ESP",LoadingTitle="Paragon BRM5",LoadingSubtitle="Mini ESP",Theme="Midnight",KeySystem=true,KeySettings={Title="Paragon Key",Subtitle="Enter key",Note="Key is: paragon",SaveKey=true,Key={"paragon"}}})
local tab=Window:CreateTab("ESP","eye")

tab:CreateLabel("Master")
tab:CreateToggle({Name="Enable ESP",CurrentValue=true,Callback=function(v)ESP.Enabled=v;if not v then clear() end end})

tab:CreateLabel("Modules")
for k,v in pairs({box="3‑D Box",chams="Chams",tracers="Tracers",distance="Distance",health="Health Bar",vischeck="VisCheck"})do tab:CreateToggle({Name=v,CurrentValue=ESP.Options[k],Callback=function(val)ESP.Options[k]=val;if not val and k=="tracers" then hide(ESP.Cache.tracer) end end})end

Rayfield:Notify({Title="Paragon BRM5",Content="Mini ESP v14 loaded – Right‑Shift for UI",Duration=4})
