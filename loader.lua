-- Paragon BRM5 • Rayfield Ultra‑ESP (v17)
-- ────────────────────────────────────────────────────────────────
--  Changes from v16
--  • Skeleton module fully removed (caused Valex errors for some users).
--  • All other features unchanged: Head‑Box, 2‑D Box, Chams, Tracers,
--    Distance, Health, VisCheck, edge‑aware tracers.
--  • Clean toggle list (no more Skeleton entry).
--------------------------------------------------------------------
local Plrs,RunSrv,Ws = game:GetService("Players"),game:GetService("RunService"),game:GetService("Workspace")
local LP,Camera = Plrs.LocalPlayer, Ws.CurrentCamera
getgenv().SecureMode = true

--------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------
local UPDATE_HZ  = 30                -- 0 → adaptive
local MAX_DIST   = 1500
local BAR_SIZE   = Vector2.new(50,4)
local DRAWING_OK = pcall(function() return Drawing end)

--------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------
local ESP = {
  Enabled = true,
  Options = {headbox=true, box2d=true, chams=true, tracers=true,
             distance=true, health=true, vischeck=true},
  Tgt = {}, -- [Model] = {root, head}
  C   = {headbox=setmetatable({}, {__mode='k'}), cham=setmetatable({}, {__mode='k'}),
         box2d=setmetatable({}, {__mode='k'}), tracer=setmetatable({}, {__mode='k'}),
         label=setmetatable({}, {__mode='k'}), health=setmetatable({}, {__mode='k'})}
}

--------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------
local function isEnemy(m)
  if not (m:IsA("Model") and m.Name=="Male") then return false end
  for _,c in ipairs(m:GetChildren()) do if c.Name:sub(1,3)=="AI_" then return true end end
end

local function addTarget(m)
  if ESP.Tgt[m] then return end
  local r=m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("UpperTorso")
  local h=m:FindFirstChild("Head")
  if r and h then ESP.Tgt[m]={root=r, head=h, model=m} end
end

for _,d in ipairs(Ws:GetDescendants()) do if isEnemy(d) then addTarget(d) end end
Ws.DescendantAdded:Connect(function(d) if isEnemy(d) then task.wait();addTarget(d) end end)
Ws.DescendantRemoving:Connect(function(d) ESP.Tgt[d]=nil end)

local function newHeadBox(p)
  local b=Instance.new("BoxHandleAdornment")
  b.AlwaysOnTop,b.ZIndex,b.Adornee=true,5,p
  b.Size=Vector3.new(0.6,0.8,0.6)
  return b
end
local function getHeadBox(p)
  local b=ESP.C.headbox[p]
  if not b or not b.Parent then b=newHeadBox(p);b.Parent=p;ESP.C.headbox[p]=b end
  return b
end
local function getCham(m)
  local h=ESP.C.cham[m]
  if not h or not h.Parent then h=Instance.new("Highlight");h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;h.Parent=m;ESP.C.cham[m]=h end
  return h
end
local function getDraw(tbl,id,k)
  if not DRAWING_OK then return end
  local o=tbl[id]; if not o then o=Drawing.new(k);tbl[id]=o end; return o
end
local function hide(tbl,id) local o=tbl[id]; if o then o.Visible=false end end
local function hpColor(f)return Color3.fromRGB((1-f)*255,f*255,0) end

local function canSee(part)
  if not ESP.Options.vischeck then return true end
  local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Blacklist; rp.FilterDescendantsInstances={LP.Character}
  local hit=Ws:Raycast(Camera.CFrame.Position, part.Position-Camera.CFrame.Position, rp)
  return (not hit) or hit.Instance:IsDescendantOf(part.Parent)
end

local function clearAll()
  for _,b in pairs(ESP.C.headbox) do b.Transparency=1 end
  for _,h in pairs(ESP.C.cham)    do h.Enabled=false end
  if DRAWING_OK then
    for _,tbl in pairs{ESP.C.box2d,ESP.C.tracer,ESP.C.label,ESP.C.health} do for _,o in pairs(tbl) do o.Visible=false end end
  end
end

--------------------------------------------------------------------
-- RENDER
--------------------------------------------------------------------
local acc=0
RunSrv.RenderStepped:Connect(function(dt)
  if not ESP.Enabled then return end
  acc+=dt; if UPDATE_HZ>0 and acc<1/UPDATE_HZ then return end; acc=0

  local camPos=Camera.CFrame.Position
  local vp=Camera.ViewportSize; local tracerOrigin=Vector2.new(vp.X/2,vp.Y)

  for mdl,t in pairs(ESP.Tgt) do
    local root,head=t.root,t.head; if not root or not head or not mdl.Parent then ESP.Tgt[mdl]=nil continue end
    local dist=(root.Position-camPos).Magnitude; if dist>MAX_DIST then continue end
    local scr,onScr=Camera:WorldToViewportPoint(root.Position); local vis=canSee(root)

    -- HEAD BOX
    local hb=getHeadBox(head)
    if ESP.Options.headbox then hb.Transparency=0.25; hb.Color3=vis and Color3.fromRGB(0,255,0) or Color3.fromRGB(120,120,120) else hb.Transparency=1 end

    -- CHAMS
    local ch=getCham(mdl)
    if ESP.Options.chams then ch.Enabled=true; ch.FillColor=vis and Color3.fromRGB(255,75,75) or Color3.fromRGB(0,190,255); ch.FillTransparency=0.15; ch.OutlineColor,ch.OutlineTransparency=ch.FillColor,0.1 else ch.Enabled=false end

    if DRAWING_OK and onScr then
      -- 2‑D BOX
      if ESP.Options.box2d then
        local size=mdl:GetExtentsSize(); local tl=Camera:WorldToViewportPoint(root.Position+Vector3.new(-size.X/2,size.Y/2,0))
        local br=Camera:WorldToViewportPoint(root.Position+Vector3.new(size.X/2,-size.Y/2,0))
        local rect=getDraw(ESP.C.box2d,mdl,"Square"); rect.Visible=true; rect.Thickness=1.5; rect.Color=Color3.fromRGB(255,165,0); rect.Filled=false; rect.Size=Vector2.new(math.abs(br.X-tl.X),math.abs(br.Y-tl.Y)); rect.Position=Vector2.new(math.min(tl.X,br.X), math.min(tl.Y,br.Y))
      else hide(ESP.C.box2d,mdl) end

      -- TRACER
      if ESP.Options.tracers then
        local tr=getDraw(ESP.C.tracer,mdl,"Line"); tr.Visible=true; tr.Thickness=1.5; tr.Color=vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,255,0)
        local endPos=Vector2.new(scr.X,scr.Y)
        if not onScr then endPos.X=math.clamp(endPos.X,0,vp.X); endPos.Y=math.clamp(endPos.Y,0,vp.Y) end
        tr.From,tr.To=tracerOrigin,endPos
      else hide(ESP.C.tracer,mdl) end

      -- DISTANCE
      if ESP.Options.distance then local lb=getDraw(ESP.C.label,mdl,"Text"); lb.Visible=true; lb.Center,lb.Outline,lb.Size=true,true,14; lb.Color=Color3.new(1,1,1); lb.Text=("%.0f"):format(dist); lb.Position=Vector2.new(scr.X,scr.Y-18)
      else hide(ESP.C.label,mdl) end

      -- HEALTH
      if ESP.Options.health then local hum=mdl:FindFirstChildOfClass("Humanoid"); if hum then local f=math.clamp(hum.Health/hum.MaxHealth,0,1); local hb2=getDraw(ESP.C.health,mdl,"Square"); hb2.Visible=true; hb2.Filled=true; hb2.Size=BAR_SIZE*Vector2.new(f,1); hb2.Position=Vector2.new(scr.X-BAR_SIZE.X/2,scr.Y+14); hb2.Color=hpColor(f) end
      else hide(ESP.C.health,mdl) end
    end
  end
end)

--------------------------------------------------------------------
-- RAYFIELD GUI
--------------------------------------------------------------------
local Rayfield=loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()
local Window=Rayfield:CreateWindow({Name="Paragon BRM5 • Ultra-ESP",LoadingTitle="Paragon BRM5",LoadingSubtitle="Ultra ESP",Theme="Midnight",KeySystem=true,KeySettings={Title="Paragon Key",Subtitle="Enter key",Note="Key is
