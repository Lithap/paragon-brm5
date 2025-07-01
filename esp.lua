--------------------------------------------------------------------
--  PARAGON OPEN WORLD • Core ESP (Boxes, Chams, Tracers, Distance, Health, VisCheck)
--  GUI-free version for standalone use.
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

local Players,RunService,Workspace = game:GetService("Players"),game:GetService("RunService"),game:GetService("Workspace")
local LP,Camera = Players.LocalPlayer,Workspace.CurrentCamera

_G.ESP_ON=_G.ESP_ON or true
_G.OPT=_G.OPT or {box=true,chams=true,tracers=true,distance=true,health=true,vischeck=true}

local DRAWING_OK=pcall(function()return Drawing end)
local BAR_SIZE=Vector2.new(50,4); local TRACER_ORG=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)

local cache={box=setmetatable({}, {__mode="k"}),cham=setmetatable({}, {__mode="k"}),
             tracer=setmetatable({}, {__mode="k"}),label=setmetatable({}, {__mode="k"}),
             health=setmetatable({}, {__mode="k"})}

local targets={}

local function isEnemy(m)
    if not(m:IsA("Model") and m.Name=="Male")then return false end
    for _,c in ipairs(m:GetChildren())do if c.Name:sub(1,3)=="AI_" then return true end end
end

local function reg(m)
    if targets[m]then return end
    local r=m:FindFirstChild("Head")or m:FindFirstChild("UpperTorso")
    if r then targets[m]={root=r} end
end
for _,d in ipairs(Workspace:GetDescendants())do if isEnemy(d)then reg(d) end end
Workspace.DescendantAdded:Connect(function(d)if isEnemy(d)then task.wait()reg(d)end end)
Workspace.DescendantRemoving:Connect(function(d)targets[d]=nil end)

local function getBox(p)
    local b=cache.box[p]
    if not b or b.Parent==nil then
        b=Instance.new("BoxHandleAdornment")
        b.AlwaysOnTop,b.ZIndex,b.Adornee=true,5,p
        b.Parent=p; cache.box[p]=b
    end;return b
end
local function getCham(m)
    local h=cache.cham[m]
    if not h or h.Parent==nil then
        h=Instance.new("Highlight")
        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent=m; cache.cham[m]=h
    end;return h
end
local function getDraw(tbl,id,kind)
    if not DRAWING_OK then return end
    local o=tbl[id]; if not o then o=Drawing.new(kind); tbl[id]=o end;return o
end
local function hide(tbl,id,prop)local o=tbl[id];if o then o[prop]=false end end
local function hpColor(f)return Color3.fromRGB((1-f)*255,f*255,0)end
local function vis(part)
    if not _G.OPT.vischeck then return true end
    local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances={LP.Character or Instance.new("Folder")}
    local hit=Workspace:Raycast(Camera.CFrame.Position,part.Position-Camera.CFrame.Position,rp)
    return(not hit)or hit.Instance:IsDescendantOf(part.Parent)
end

RunService.RenderStepped:Connect(function()
    if not _G.ESP_ON then return end
    local cam=Camera.CFrame.Position
    for mdl,t in pairs(targets)do
        local root=t.root;if not root or not mdl.Parent then targets[mdl]=nil continue end
        local d=(root.Position-cam).Magnitude
        local scr,onScr=Camera:WorldToViewportPoint(root.Position)
        local v=vis(root)
        -- Box
        if _G.OPT.box and onScr then local b=getBox(root);b.Size=root.Size+Vector3.new(0.1,0.1,0.1);b.Transparency=0.25;b.Color3=v and Color3.fromRGB(255,0,0)or Color3.fromRGB(120,120,120)
        elseif cache.box[root] then cache.box[root].Transparency=1 end
        -- Chams
        if _G.OPT.chams then local h=getCham(mdl);h.Enabled=true;h.FillColor=v and Color3.fromRGB(255,75,75)or Color3.fromRGB(0,190,255);h.FillTransparency=0.15;h.OutlineColor,h.OutlineTransparency=h.FillColor,0.1
        elseif cache.cham[mdl] then cache.cham[mdl].Enabled=false end
        if DRAWING_OK then
            if _G.OPT.tracers and onScr then local tr=getDraw(cache.tracer,mdl,"Line");tr.Visible,tr.Thickness=true,1.5;tr.Color=v and Color3.fromRGB(255,0,0)or Color3.fromRGB(255,255,0);tr.From,tr.To=TRACER_ORG,Vector2.new(scr.X,scr.Y)
            else hide(cache.tracer,mdl,"Visible") end
            if _G.OPT.distance and onScr then local lb=getDraw(cache.label,mdl,"Text");lb.Visible,lb.Center,lb.Outline,lb.Size=true,true,true,14;lb.Color,lb.Text=Color3.new(1,1,1),("%.0f"):format(d);lb.Position=Vector2.new(scr.X,scr.Y-16)
            else hide(cache.label,mdl,"Visible") end
            if _G.OPT.health and onScr then local hum=mdl:FindFirstChildOfClass("Humanoid"); if hum then local f=math.clamp(hum.Health/hum.MaxHealth,0,1);local hb=getDraw(cache.health,mdl,"Square");hb.Visible,hb.Filled=true,true;hb.Size=BAR_SIZE*Vector2.new(f,1);hb.Position=Vector2.new(scr.X-BAR_SIZE.X/2,scr.Y+12);hb.Color=hpColor(f)end
            else hide(cache.health,mdl,"Visible") end
        end
    end
end)

function _G.clearESP()for _,b in pairs(cache.box)do b.Transparency=1 end for _,h in pairs(cache.cham)do h.Enabled=false end if DRAWING_OK then for _,tbl in pairs{cache.tracer,cache.label,cache.health}do for _,o in pairs(tbl)do o.Visible=false end end end end
