-- Paragon BRM5 • Rayfield Mini‑ESP (v13‑Turbo + Clarity)
-- Same feature set, but visuals are brighter, thicker, and update every frame.
-- Key = paragon • Right‑Shift opens Rayfield
---------------------------------------------------------------------
-- 0. Services / locals
---------------------------------------------------------------------
local P, RS, WS = game:GetService("Players"), game:GetService("RunService"), game:GetService("Workspace")
local LP, Camera = P.LocalPlayer, WS.CurrentCamera
getgenv().SecureMode = true

---------------------------------------------------------------------
-- 1. Settings & state
---------------------------------------------------------------------
local MAX_DIST   = 1500                -- render distance
local BAR_SIZE   = Vector2.new(60, 4)  -- longer health bar for clarity
local DRAW_OK    = pcall(function()return Drawing end)
local ESP = {
  Enabled = true,
  Opt = { box=true, chams=true, tracers=true, distance=true, health=true, vischeck=true },
  Tgt = {},
  Cache = {
    box=setmetatable({}, {__mode='k'}), cham=setmetatable({}, {__mode='k'}),
    tracer=setmetatable({}, {__mode='k'}), label=setmetatable({}, {__mode='k'}),
    health=setmetatable({}, {__mode='k'}) }
}

---------------------------------------------------------------------
-- 2. Enemy detection
---------------------------------------------------------------------
local function isEnemy(m)
  if not (m:IsA("Model") and m.Name=="Male") then return false end
  for _,c in ipairs(m:GetChildren()) do if c.Name:sub(1,3)=="AI_" then return true end end
end
local function reg(m)
  if ESP.Tgt[m] then return end
  local r=m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso"); if r then ESP.Tgt[m]={root=r} end
end
for _,d in ipairs(WS:GetDescendants())do if isEnemy(d)then reg(d) end end
WS.DescendantAdded:Connect(function(d) if isEnemy(d) then task.wait(); reg(d) end end)
WS.DescendantRemoving:Connect(function(d) ESP.Tgt[d]=nil end)

---------------------------------------------------------------------
-- 3. Factory helpers
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
local function getD(tbl,id,k) if not DRAW_OK then return end; local o=tbl[id] or Drawing.new(k); tbl[id]=o; return o end
local function hide(tbl,id) local o=tbl[id]; if o then o.Visible=false end end
local function hp(f) return Color3.fromRGB((1-f)*255,f*255,0) end
local function visible(part)
  if not ESP.Opt.vischeck then return true end
  local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Blacklist; rp.FilterDescendantsInstances={LP.Character}
  local hit=WS:Raycast(Camera.CFrame.Position, part.Position-Camera.CFrame.Position, rp)
  return (not hit) or hit.Instance:IsDescendantOf(part.Parent)
end
local function clear()
  for _,b in pairs(ESP.Cache.box)  do b.Transparency=1 end
  for _,h in pairs(ESP.Cache.cham) do h.Enabled=false end
  if DRAW_OK then for _,t in pairs{ESP.Cache.tracer,ESP.Cache.label,ESP.Cache.health} do for _,o in pairs(t)do o.Visible=false end end end
end

---------------------------------------------------------------------
-- 4. Render loop (every frame, adaptive)
---------------------------------------------------------------------
RS.RenderStepped:Connect(function()
  if not ESP.Enabled then return end
  local cam=Camera.CFrame.Position; local vp=Camera.ViewportSize; local origin=Vector2.new(vp.X/2,vp.Y)
  for mdl,t in pairs(ESP.Tgt) do
    local root=t.root; if not root or not mdl.Parent then ESP.Tgt[mdl]=nil continue end
    local dist=(root.Position-cam).Magnitude; if dist>MAX_DIST then hide(ESP.Cache.tracer,mdl); hide(ESP.Cache.label,mdl); hide(ESP.Cache.health,mdl); getBox(root).Transparency=1; getCham(mdl).Enabled=false continue end
    local scr,onScr=Camera:WorldToViewportPoint(root.Position)
    local vis=visible(root)
    -- 3-D Box (brighter & thicker colour)
    local bx=getBox(root); if ESP.Opt.box and onScr then bx.Size=root.Size+Vector3.new(0.1,0.1,0.1); bx.Transparency=0.18; bx.Color3=vis and Color3.fromRGB(0,255,30) or Color3.fromRGB(180,180,180) else bx.Transparency=1 end
    -- Chams with stronger outline
    local ch=getCham(mdl); if ESP.Opt.chams then ch.Enabled=true; ch.FillColor=vis and Color3.fromRGB(255,60,60) or Color3.fromRGB(0,200,255); ch.FillTransparency=0.08; ch.OutlineColor=Color3.new(1,1,1); ch.OutlineTransparency=0.05 else ch.Enabled=false end
    if DRAW_OK and onScr then
      -- Tracer (thicker) ------------------------------------------------
      if ESP.Opt.tracers then
        local tr=getD(ESP.Cache.tracer,mdl,"Line"); tr.Visible=true; tr.Thickness=2
        tr.Color=vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,255,0)
        local endPos=Vector2.new(scr.X,scr.Y)
        tr.From,tr.To=origin,endPos
      else hide(ESP.Cache.tracer,mdl) end
      -- Distance -------------------------------------------------------
      if ESP.Opt.distance then
        local lb=getD(ESP.Cache.label,mdl,"Text"); lb.Visible=true; lb.Center=true; lb.Outline=true; lb.Size=15; lb.Color=Color3.new(1,1,1); lb.Text=("%.0f m"):format(dist); lb.Position=Vector2.new(scr.X,scr.Y-18)
      else hide(ESP.Cache.label,mdl) end
      -- Health ---------------------------------------------------------
      if ESP.Opt.health then
        local hum=mdl:FindFirstChildOfClass("Humanoid"); if hum then local f=math.clamp(hum.Health/hum.MaxHealth,0,1); local hb=getD(ESP.Cache.health,mdl,"Square"); hb.Visible=true; hb.Filled=true; hb.Size=BAR_SIZE*Vector2.new(f,1); hb.Position=Vector2.new(scr.X-BAR_SIZE.X/2,scr.Y+14); hb.Color=hp(f) end
      else hide(ESP.Cache.health,mdl) end
    end
  end
end)

---------------------------------------------------------------------
-- 5. Rayfield GUI (unchanged keys)
---------------------------------------------------------------------
local RF=loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()
local Win=RF:CreateWindow({Name="Paragon BRM5 • Mini-ESP",LoadingTitle="Paragon BRM5",LoadingSubtitle="Mini ESP Turbo",Theme="Midnight",KeySystem=true,KeySettings={Title="Paragon Key",Subtitle="Enter key",Note="Key is: paragon",SaveKey=true,Key={"paragon"}}})
local tab=Win:CreateTab("ESP","eye")
tab:CreateLabel("Master")
tab:CreateToggle({Name="Enable ESP",CurrentValue=true,Callback=function(v)ESP.Enabled=v; if not v then clear() end end})
local map={box="3-D Box",chams="Chams",tracers="Tracers",distance="Distance",health="Health Bar",vischeck="VisCheck"}
tab:CreateLabel("Modules")
for f,l in pairs(map) do tab:CreateToggle({Name=l,CurrentValue=ESP.Opt[f],Callback=function(v)ESP.Opt[f]=v end}) end
RF:Notify({Title="Paragon BRM5",Content="Mini‑ESP Turbo loaded – Right‑Shift opens UI",Duration=4})
