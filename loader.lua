-- Paragon BRM5 • Lite ESP + Fly (v24 – BRM5‑compatible)
--  • Fly rewritten for Blackhawk Rescue Mission 5 physics: uses AssemblyLinearVelocity
--    each Heartbeat (no BodyVelocity caps / no PlatformStand issues).
--  • Toggle key: **F** (or Rayfield switch).  WASD + Space (up) + Left‑Ctrl (down).
--  • ESP: 3‑D Box, Chams, VisCheck – same as v23, but chams capped at 30.
--  • Master toggle wipes visuals; modules hot‑clear.
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
-- 1. Config / State
---------------------------------------------------------------------
local MAX_DIST   = 1500
local MAX_HL     = 30            -- Roblox highlight limit
local FLY_SPEED  = 90            -- studs/sec

local ESP = { Enabled=true, Opt={box=true,chams=true,vischeck=true},
              Tgt={}, Cache={box=setmetatable({}, {__mode='k'}),cham=setmetatable({}, {__mode='k'})}, ChamCt=0 }

local Fly = { Active=false, Move=Vector3.zero }

---------------------------------------------------------------------
-- 2. Enemy registration
---------------------------------------------------------------------
local function isEnemy(m)
  if not(m:IsA("Model") and m.Name=="Male") then return false end
  for _,c in ipairs(m:GetChildren())do if c.Name:sub(1,3)=="AI_" then return true end end
end
local function addTarget(m)
  local root=m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso")
  if root then ESP.Tgt[m]={root=root} end
end
for _,d in ipairs(Workspace:GetDescendants())do if isEnemy(d)then addTarget(d) end end
Workspace.DescendantAdded:Connect(function(d) if isEnemy(d) then task.defer(addTarget,d) end end)
Workspace.DescendantRemoving:Connect(function(d) ESP.Tgt[d]=nil end)

---------------------------------------------------------------------
-- 3. Factory helpers
---------------------------------------------------------------------
local function boxOf(p)
  local b=ESP.Cache.box[p]
  if not b or not b.Parent then b=Instance.new("BoxHandleAdornment"); b.AlwaysOnTop=true; b.ZIndex=10; b.Adornee=p; b.Parent=p; ESP.Cache.box[p]=b end
  return b
end
local function chamOf(m)
  if ESP.ChamCt>=MAX_HL then return end
  local h=ESP.Cache.cham[m]
  if not h or not h.Parent then h=Instance.new("Highlight"); h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Parent=m; ESP.Cache.cham[m]=h; ESP.ChamCt+=1 end
  return h
end
local function clearESP()
  for _,b in pairs(ESP.Cache.box)  do b.Transparency=1 end
  for _,h in pairs(ESP.Cache.cham) do h.Enabled=false end
end
---------------------------------------------------------------------
-- 4. Fly implementation (AssemblyLinearVelocity) -------------------
---------------------------------------------------------------------
local dirKeys={W=Vector3.new(0,0,-1),S=Vector3.new(0,0,1),A=Vector3.new(-1,0,0),D=Vector3.new(1,0,0),Space=Vector3.new(0,1,0),LeftControl=Vector3.new(0,-1,0)}
UserInput.InputBegan:Connect(function(i,g)
  if g then return end
  if i.KeyCode==Enum.KeyCode.F then Fly.Active=not Fly.Active end
  local v=dirKeys[i.KeyCode.Name]; if v then Fly.Move+=v end
end)
UserInput.InputEnded:Connect(function(i,g) if g then return end; local v=dirKeys[i.KeyCode.Name]; if v then Fly.Move-=v end end)

RunService.Heartbeat:Connect(function(dt)
  if not Fly.Active then return end
  local char=LP.Character; if not char then return end
  local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
  -- make sure client owns HRP
  hrp:SetNetworkOwner(LP)
  -- compute velocity
  local mv=Fly.Move
  if mv.Magnitude>0 then
      mv=mv.Unit
      mv=Camera.CFrame:VectorToWorldSpace(mv)
      hrp.AssemblyLinearVelocity=mv*FLY_SPEED
  else
      hrp.AssemblyLinearVelocity=Vector3.zero
  end
end)

LP.CharacterAdded:Connect(function()
  if Fly.Active then Fly.Active=false end  -- reset on respawn; user can re‑toggle
end)

---------------------------------------------------------------------
-- 5. VisCheck helper
---------------------------------------------------------------------
local function canSee(part)
  if not ESP.Opt.vischeck then return true end
  local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Blacklist; rp.FilterDescendantsInstances={LP.Character}
  local hit=Workspace:Raycast(Camera.CFrame.Position, part.Position-Camera.CFrame.Position, rp)
  return(not hit)or hit.Instance:IsDescendantOf(part.Parent)
end

---------------------------------------------------------------------
-- 6. Render loop
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
  if not ESP.Enabled then return end
  local cam=Camera.CFrame.Position
  for mdl,t in pairs(ESP.Tgt) do
    local root=t.root; if not root or not mdl.Parent then ESP.Tgt[mdl]=nil; continue end
    local dist=(root.Position-cam).Magnitude; if dist>MAX_DIST then boxOf(root).Transparency=1; (ESP.Cache.cham[mdl] or {}).Enabled=false; continue end
    local _,onScr=Camera:WorldToViewportPoint(root.Position); if not onScr then boxOf(root).Transparency=1; (ESP.Cache.cham[mdl] or {}).Enabled=false; continue end
    local vis=canSee(root)
    -- Box
    if ESP.Opt.box then local b=boxOf(root); b.Size=root.Size+Vector3.new(0.1,0.1,0.1); b.Transparency=0.18; b.Color3=vis and Color3.fromRGB(0,255,35)or Color3.fromRGB(160,160,160) else boxOf(root).Transparency=1 end
    -- Cham
    if ESP.Opt.chams then local h=chamOf(mdl); if h then h.Enabled=true; h.FillColor=vis and Color3.fromRGB(255,60,60)or Color3.fromRGB(0,200,255); h.FillTransparency=0.08; h.OutlineColor=Color3.new(1,1,1); h.OutlineTransparency=0.05 end else if ESP.Cache.cham[mdl] then ESP.Cache.cham[mdl].Enabled=false end end
  end
end)

---------------------------------------------------------------------
-- 7. UI ------------------------------------------------------------
local Rayfield=loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()
local win=Rayfield:CreateWindow({Name="Paragon BRM5 • Lite ESP",LoadingTitle="Paragon BRM5",LoadingSubtitle="v24",Theme="Midnight",KeySystem=true,KeySettings={Title="Paragon Key",Subtitle="Enter key",Note="Key is: paragon",SaveKey=true,Key={"paragon"}}})
local tab=win:CreateTab("ESP","eye")

-- Master
tab:CreateToggle({Name="Enable ESP",CurrentValue=true,Callback=function(v)ESP.Enabled=v; if not v then clearESP() end end})
-- Modules
for f,l in pairs{box="3-D Box",chams="Chams",vischeck="VisCheck"} do tab:CreateToggle({Name=l,CurrentValue=ESP.Opt[f],Callback=function(v)ESP.Opt[f]=v; clearESP() end}) end
-- Fly
tab:CreateToggle({Name="Fly (key F)",CurrentValue=false,Callback=function(v)Fly.Active=v end})
Rayfield:Notify({Title="Paragon BRM5",Content="Lite ESP + Fly v24 loaded — Right-Shift opens UI",Duration=5})
