-- Paragon BRM5 • Rayfield Mini-ESP (v18)
-- Head-Box ▸ 2-D Box ▸ Chams ▸ Tracers ▸ Distance ▸ Health ▸ VisCheck
-- Key = paragon • Right-Shift opens Rayfield
---------------------------------------------------------------------
local P,RS,WS = game:GetService("Players"),game:GetService("RunService"),game:GetService("Workspace")
local LP,Camera = P.LocalPlayer,WS.CurrentCamera
getgenv().SecureMode = true
local UPDATE_HZ,MAX_DIST,BAR = 30,1500,Vector2.new(50,4)
local DRAW_OK = pcall(function()return Drawing end)
local ESP={Enabled=true,Opt={headbox=true,box2d=true,chams=true,tracers=true,distance=true,health=true,vischeck=true},
           Tgt={},C={headbox=setmetatable({}, {__mode="k"}),cham=setmetatable({}, {__mode="k"}),
                     box2d=setmetatable({}, {__mode="k"}),tracer=setmetatable({}, {__mode="k"}),
                     label=setmetatable({}, {__mode="k"}),health=setmetatable({}, {__mode="k"})}}
---------------------------------------------------------------------
-- target registry
local function isEnemy(m) if not(m:IsA("Model")and m.Name=="Male")then return false end
  for _,c in ipairs(m:GetChildren())do if c.Name:sub(1,3)=="AI_"then return true end end end
local function add(m) if ESP.Tgt[m]then return end
  local r=m:FindFirstChild("HumanoidRootPart")or m:FindFirstChild("UpperTorso")
  local h=m:FindFirstChild("Head") if r and h then ESP.Tgt[m]={root=r,head=h,model=m} end end
for _,d in ipairs(WS:GetDescendants())do if isEnemy(d)then add(d)end end
WS.DescendantAdded:Connect(function(d)if isEnemy(d)then task.wait();add(d)end end)
WS.DescendantRemoving:Connect(function(d)ESP.Tgt[d]=nil end)
---------------------------------------------------------------------
-- helpers
local function newHeadBox(p) local b=Instance.new("BoxHandleAdornment")
  b.AlwaysOnTop,b.ZIndex,b.Adornee=true,5,p; b.Size=Vector3.new(0.6,0.8,0.6); return b end
local function getHB(p) local b=ESP.C.headbox[p]; if not b or not b.Parent then b=newHeadBox(p);b.Parent=p;ESP.C.headbox[p]=b end; return b end
local function getCham(m) local h=ESP.C.cham[m]; if not h or not h.Parent then h=Instance.new("Highlight");h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;h.Parent=m;ESP.C.cham[m]=h end; return h end
local function getDraw(tbl,id,k) if not DRAW_OK then return end; local o=tbl[id] or Drawing.new(k); tbl[id]=o; return o end
local function hide(tbl,id) local o=tbl[id]; if o then o.Visible=false end end
local function hp(f)return Color3.fromRGB((1-f)*255,f*255,0)end
local function canSee(part) if not ESP.Opt.vischeck then return true end
  local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Blacklist; rp.FilterDescendantsInstances={LP.Character}
  local hit=WS:Raycast(Camera.CFrame.Position,part.Position-Camera.CFrame.Position,rp)
  return(not hit)or hit.Instance:IsDescendantOf(part.Parent) end
local function clr()for _,b in pairs(ESP.C.headbox)do b.Transparency=1 end for _,h in pairs(ESP.C.cham)do h.Enabled=false end
  if DRAW_OK then for _,t in pairs{ESP.C.box2d,ESP.C.tracer,ESP.C.label,ESP.C.health}do for _,o in pairs(t)do o.Visible=false end end end end
---------------------------------------------------------------------
-- loop
local acc=0
RS.RenderStepped:Connect(function(dt) if not ESP.Enabled then return end
  acc+=dt; if acc<1/UPDATE_HZ then return end; acc=0
  local cam=Camera.CFrame.Position; local vp=Camera.ViewportSize; local orig=Vector2.new(vp.X/2,vp.Y)
  for mdl,t in pairs(ESP.Tgt)do local root,head=t.root,t.head
    if not root or not head or not mdl.Parent then ESP.Tgt[mdl]=nil continue end
    local dist=(root.Position-cam).Magnitude; if dist>MAX_DIST then continue end
    local scr,onScr=Camera:WorldToViewportPoint(root.Position); local vis=canSee(root)
    -- Head-Box
    local hb=getHB(head); if ESP.Opt.headbox then hb.Transparency=0.25; hb.Color3=vis and Color3.fromRGB(0,255,0)or Color3.fromRGB(120,120,120)
      else hb.Transparency=1 end
    -- Chams
    local ch=getCham(mdl); if ESP.Opt.chams then ch.Enabled=true; ch.FillColor=vis and Color3.fromRGB(255,75,75)or Color3.fromRGB(0,190,255); ch.FillTransparency=0.15; ch.OutlineColor,ch.OutlineTransparency=ch.FillColor,0.1 else ch.Enabled=false end
    if DRAW_OK and onScr then
      -- 2-D Box
      if ESP.Opt.box2d then local size=mdl:GetExtentsSize(); local tl=Camera:WorldToViewportPoint(root.Position+Vector3.new(-size.X/2,size.Y/2,0))
        local br=Camera:WorldToViewportPoint(root.Position+Vector3.new(size.X/2,-size.Y/2,0))
        local rect=getDraw(ESP.C.box2d,mdl,"Square"); rect.Visible=true; rect.Thickness=1.5; rect.Color=Color3.fromRGB(255,165,0); rect.Filled=false;
        rect.Size=Vector2.new(math.abs(br.X-tl.X),math.abs(br.Y-tl.Y)); rect.Position=Vector2.new(math.min(tl.X,br.X),math.min(tl.Y,br.Y))
      else hide(ESP.C.box2d,mdl) end
      -- Tracer (edge-aware)
      if ESP.Opt.tracers then local tr=getDraw(ESP.C.tracer,mdl,"Line"); tr.Visible=true; tr.Thickness=1.5; tr.Color=vis and Color3.fromRGB(255,0,0)or Color3.fromRGB(255,255,0)
        local endPos=Vector2.new(scr.X,scr.Y); if not onScr then endPos.X=math.clamp(endPos.X,0,vp.X); endPos.Y=math.clamp(endPos.Y,0,vp.Y) end
        tr.From,tr.To=orig,endPos
      else hide(ESP.C.tracer,mdl) end
      -- Distance
      if ESP.Opt.distance then local lb=getDraw(ESP.C.label,mdl,"Text"); lb.Visible=true; lb.Center,lb.Outline,lb.Size=true,true,14; lb.Color=Color3.new(1,1,1)
        lb.Text=("%.0f"):format(dist); lb.Position=Vector2.new(scr.X,scr.Y-18) else hide(ESP.C.label,mdl) end
      -- Health
      if ESP.Opt.health then local hum=mdl:FindFirstChildOfClass("Humanoid")
        if hum then local f=math.clamp(hum.Health/hum.MaxHealth,0,1); local hb2=getDraw(ESP.C.health,mdl,"Square"); hb2.Visible=true; hb2.Filled=true
          hb2.Size=BAR*Vector2.new(f,1); hb2.Position=Vector2.new(scr.X-BAR.X/2,scr.Y+14); hb2.Color=hp(f) end
      else hide(ESP.C.health,mdl) end
    end
  end
end)
---------------------------------------------------------------------
-- GUI
local RF=loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()
local Win=RF:CreateWindow({Name="Paragon BRM5 • Mini-ESP",LoadingTitle="Paragon BRM5",LoadingSubtitle="Head-Box Edition",
   Theme="Midnight",KeySystem=true,KeySettings={Title="Paragon Key",Subtitle="Enter key",Note="Key is: paragon",SaveKey=true,Key={"paragon"}}})
local tab=Win:CreateTab("ESP","eye")
tab:CreateLabel("Master")
tab:CreateToggle({Name="Enable ESP",CurrentValue=true,Callback=function(v)ESP.Enabled=v;if not v then clr()end end})
local toggles={headbox="Head Box",box2d="2-D Box",chams="Chams",tracers="Tracers",distance="Distance",health="Health Bar",vischeck="VisCheck"}
tab:CreateLabel("Modules")
for f,l in pairs(toggles) do tab:CreateToggle({Name=l,CurrentValue=ESP.Opt[f],Callback=function(v)ESP.Opt[f]=v;if not v then if f~=\"vischeck\" then clr() end end end}) end
RF:Notify({Title="Paragon BRM5",Content="Mini-ESP v18 loaded – Right-Shift to open menu",Duration=4})
