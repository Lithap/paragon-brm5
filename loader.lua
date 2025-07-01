--------------------------------------------------------------------
--  PARAGON  •  Loader with streamlined ESP (no skeleton)
--  key : paragon
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

--=======  kill Valex1 spam  =======--
local function nuke(s) if s:IsA("LocalScript") and s.Name=="Valex1" then s.Disabled=true end end
for _,d in ipairs(game:GetDescendants()) do nuke(d) end
game.DescendantAdded:Connect(nuke)

--=======  shortcuts / colours  =======--
local Players, TweenService, UIS, Camera =
      game:GetService("Players"), game:GetService("TweenService"),
      game:GetService("UserInputService"), workspace.CurrentCamera
local LP, PG = Players.LocalPlayer, Players.LocalPlayer.PlayerGui

local C_BLUE  = Color3.fromRGB(0,160,255)
local C_RED   = Color3.fromRGB(255,70,70)
local C_GREEN = Color3.fromRGB(80,255,80)
local C_TEXT  = Color3.fromRGB(235,235,235)
local C_PANEL = Color3.fromRGB(20,20,24)
local KEY     = "paragon"

(PG:FindFirstChild("ParagonLoaderUI"))?.:Destroy()

--=======  key panel  =======--
local sg = Instance.new("ScreenGui", PG)
sg.Name, sg.IgnoreGuiInset, sg.ResetOnSpawn = "ParagonLoaderUI", true, false
if syn and syn.protect_gui then syn.protect_gui(sg) end

local panel = Instance.new("Frame", sg)
panel.BackgroundColor3, panel.BackgroundTransparency = C_PANEL, 0.3
panel.BorderSizePixel = 0
panel.Position = UDim2.new(0.5,-150,0.5,-130)
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,6)
local stroke = Instance.new("UIStroke", panel) stroke.Color = C_BLUE

local header = Instance.new("TextLabel", panel)
header.Size = UDim2.new(1,0,0,40) header.BackgroundTransparency=1
header.Font = Enum.Font.GothamBlack header.TextScaled=true
header.TextColor3=C_TEXT header.Text="PARAGON"

local div = Instance.new("Frame", panel)
div.Position,div.Size,div.BackgroundColor3=UDim2.new(0,6,0,42),UDim2.new(1,-12,0,1),C_BLUE

local container=Instance.new("Frame",panel) container.BackgroundTransparency=1
local layout=Instance.new("UIListLayout",container) layout.Padding=UDim.new(0,4)

-- key row
local row=Instance.new("Frame",container) row.Size=UDim2.new(1,0,0,32) row.BackgroundTransparency=1
local lbl=Instance.new("TextLabel",row)
lbl.BackgroundTransparency=1 lbl.Size=UDim2.new(0.55,0,1,0)
lbl.Font=Enum.Font.GothamSemibold lbl.TextScaled=true lbl.TextColor3=C_TEXT
lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.Text="Enter Key:"
local box=Instance.new("TextBox",row)
box.Size,box.Position=UDim2.new(0.45,0,1,0),UDim2.new(0.55,0,0,0)
box.BackgroundColor3,box.BackgroundTransparency=C_PANEL,0.35 box.BorderSizePixel=0
box.Font=Enum.Font.Gotham box.TextScaled=true box.TextColor3=C_TEXT
box.PlaceholderText=KEY box.ClearTextOnFocus=false
Instance.new("UICorner",box).CornerRadius=UDim.new(0,4)

-- unlock button
local unlock=Instance.new("TextButton",container)
unlock.Size=UDim2.new(1,0,0,30)
unlock.BackgroundColor3,unlock.BackgroundTransparency=C_PANEL,0.35
unlock.BorderSizePixel=0 unlock.Font=Enum.Font.GothamBold unlock.TextScaled=true
unlock.TextColor3=C_TEXT unlock.Text="Unlock"
Instance.new("UICorner",unlock).CornerRadius=UDim.new(0,4)
local hi=Instance.new("Frame",unlock)
hi.Size=UDim2.new(1,0,1,0) hi.BackgroundColor3=C_BLUE hi.BackgroundTransparency=0.9 hi.BorderSizePixel=0

-- resize helper
local function resize()
    local need=46
    for _,c in ipairs(container:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then need+=c.Size.Y.Offset+layout.Padding.Offset end
    end
    container.Size=UDim2.new(1,-12,0,need-46) container.Position=UDim2.new(0,6,0,46)
    local vp=Camera.ViewportSize
    panel.Size=UDim2.new(0,math.clamp(vp.X*0.28,320,500),0,math.max(need+20,260))
end
resize(); layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

local function flash(col,msg)
    stroke.Color,div.BackgroundColor3=col,col
    unlock.Text,unlock.TextColor3=msg,col
    task.wait(1)
    unlock.Text,unlock.TextColor3="Unlock",C_TEXT
    stroke.Color,div.BackgroundColor3=C_BLUE,C_BLUE
end

--------------------------------------------------------------------
--  ESP CODE  (no skeleton) – embedded
--------------------------------------------------------------------
local OPENWORLD_SRC = [=[
if not game:IsLoaded() then game.Loaded:Wait() end
local Players, TweenService, RunService =
      game:GetService("Players"), game:GetService("TweenService"), game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP, Camera = Players.LocalPlayer, workspace.CurrentCamera
local PG = LP:WaitForChild("PlayerGui")
local DRAWING_OK = pcall(function() return Drawing end)

-- cfg
local MAX_DIST, TICK_HZ = 3000, 20
local BAR = Vector2.new(50,4)
local CENTER = function() local v=Camera.ViewportSize return Vector2.new(v.X/2,v.Y/2) end

-- state
local ON=false
local OPT={chams=false,tracers=false,distance=false,health=true,vischeck=false}

local targets = {}
local w = {__mode="k"}
local pool={
  hi=setmetatable({},w), trac=setmetatable({},w), lab=setmetatable({},w), hp=setmetatable({},w)
}

local function getHi(m)
  local h=pool.hi[m]
  if not h or h.Parent==nil then h=Instance.new("Highlight") h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop h.Parent=m pool.hi[m]=h end
  return h
end
local function draw(tab,id,k) if not DRAWING_OK then return end local o=tab[id] if not o then o=Drawing.new(k) tab[id]=o end return o end
local function hide(tab,id) if tab[id] then tab[id].Visible=false end end
local function hpCol(f) return Color3.fromRGB((1-f)*255,f*255,0) end
local function LOS(p) local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Blacklist rp.FilterDescendantsInstances={LP.Character or Instance.new("Folder")} local h=workspace:Raycast(Camera.CFrame.Position,p.Position-Camera.CFrame.Position,rp) return (not h) or h.Instance:IsDescendantOf(p.Parent) end

-- enemy reg
local function isEnemy(m) if not(m:IsA("Model") and m.Name=="Male") then return false end for _,c in ipairs(m:GetChildren()) do if c.Name:sub(1,3)=="AI_" then return true end end return false end
local function add(m) if targets[m] then return end local r=m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso") if r then targets[m]={root=r} end end
for _,d in ipairs(workspace:GetDescendants()) do if isEnemy(d) then add(d) end end
workspace.DescendantAdded:Connect(function(d) if isEnemy(d) then task.wait(); add(d) end end)
workspace.DescendantRemoving:Connect(function(d) targets[d]=nil end)

-- main loop
local acc=0
RunService.RenderStepped:Connect(function(dt)
  if not ON then return end acc+=dt if acc<1/TICK_HZ then return end acc=0
  local cam=Camera.CFrame.Position
  for m,t in pairs(targets) do
    if not m.Parent then targets[m]=nil hide(pool.trac,m) hide(pool.lab,m) hide(pool.hp,m) if pool.hi[m] then pool.hi[m].Enabled=false end continue end
    local root=t.root local hum=m:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health<=0 then hide(pool.trac,m) hide(pool.lab,m) hide(pool.hp,m) if pool.hi[m] then pool.hi[m].Enabled=false end continue end
    local dist=(root.Position-cam).Magnitude
    if dist>MAX_DIST then hide(pool.trac,m) hide(pool.lab,m) hide(pool.hp,m) if pool.hi[m] then pool.hi[m].Enabled=false end continue end

    local v2,on=Camera:WorldToViewportPoint(root.Position)
    local vis=(not OPT.vischeck) or LOS(root)

    -- chams
    if OPT.chams then
      local h=getHi(m) h.Enabled=true h.FillTransparency=0.15 h.OutlineTransparency=0.1
      h.FillColor=vis and Color3.fromRGB(255,75,75) or Color3.fromRGB(0,190,255)
      h.OutlineColor=h.FillColor
    elseif pool.hi[m] then pool.hi[m].Enabled=false end

    -- tracer
    if DRAWING_OK then
      if OPT.tracers then
        local tr=draw(pool.trac,m,"Line")
        tr.Visible=true tr.Thickness=1.5
        tr.Color=vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,255,0)
        tr.From,tr.To=CENTER(),Vector2.new(v2.X,v2.Y)
      else hide(pool.trac,m) end

      if OPT.distance and on then
        local lb=draw(pool.lab,m,"Text")
        lb.Visible=true lb.Center=true lb.Outline=true lb.Size=14
        lb.Color=Color3.new(1,1,1) lb.Text=("%.0f"):format(dist)
        lb.Position=Vector2.new(v2.X,v2.Y-16)
      else hide(pool.lab,m) end

      if OPT.health and on then
        local f=math.clamp(hum.Health/hum.MaxHealth,0,1)
        local hb=draw(pool.hp,m,"Square")
        hb.Visible=true hb.Filled=true
        hb.Size=BAR*Vector2.new(f,1) hb.Position=Vector2.new(v2.X-BAR.X/2,v2.Y+12)
        hb.Color=hpCol(f)
      else hide(pool.hp,m) end
    end
  end
end)

-- clear when master off
local function clear()
  for _,h in pairs(pool.hi) do h.Enabled=false end
  for _,tab in ipairs{pool.trac,pool.lab,pool.hp} do for _,o in pairs(tab) do o.Visible=false end end
end

-- GUI panel
local C_MAIN,C_ACC,C_TEXT = Color3.fromRGB(22,22,26),Color3.fromRGB(0,160,255),Color3.fromRGB(240,240,240)
local ICON="✕"
(PG:FindFirstChild("ParagonMainUI"))?.:Destroy()
local g=Instance.new("ScreenGui",PG)
g.Name,g.IgnoreGuiInset,g.ResetOnSpawn="ParagonMainUI",true,false
if syn and syn.protect_gui then syn.protect_gui(g) end
local f=Instance.new("Frame",g)
f.AnchorPoint=Vector2.new(0,0.5) f.Size=UDim2.new(0,270,0,280) f.Position=UDim2.new(0,-280,0.5,0)
f.BackgroundColor3,f.BackgroundTransparency=C_MAIN,0.2 f.BorderSizePixel=0
Instance.new("UICorner",f).CornerRadius=UDim.new(0,8) Instance.new("UIStroke",f).Color=C_ACC
local h=Instance.new("TextLabel",f) h.Size=UDim2.new(1,0,0,40) h.BackgroundTransparency=1 h.Font=Enum.Font.GothamBlack h.Text="PARAGON ESP" h.TextScaled=true h.TextColor3=C_TEXT
local dv=Instance.new("Frame",f) dv.Position,dv.Size,dv.BackgroundColor3=UDim2.new(0,8,0,42),UDim2.new(1,-16,0,1),C_ACC
local bd=Instance.new("Frame",f) bd.Position,bd.Size=UDim2.new(0,8,0,50),UDim2.new(1,-16,1,-58) bd.BackgroundTransparency=1
local list=Instance.new("UIListLayout",bd) list.Padding=UDim.new(0,6) list.HorizontalAlignment=list.HorizontalAlignment.Center
local function tog(txt,k)
  local b=Instance.new("TextButton",bd) b.Size=UDim2.new(1,0,0,32) b.BackgroundColor3,b.BackgroundTransparency=C_MAIN,0.15 b.AutoButtonColor=false
  Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
  local t=Instance.new("TextLabel",b)
  t.BackgroundTransparency=1 t.Size,t.Position=UDim2.new(1,-28,1,0),UDim2.new(0,6,0,0)
  t.Font=Enum.Font.GothamSemibold t.TextScaled=true t.TextColor3=C_TEXT t.TextXAlignment=Enum.TextXAlignment.Left t.Text=txt
  local ico=Instance.new("TextLabel",b) ico.BackgroundTransparency=1 ico.Size,ico.Position=UDim2.new(0,22,0,22),UDim2.new(1,-26,0.5,-11)
  ico.Font=Enum.Font.GothamBold ico.TextScaled=true ico.Text=ICON
  local st=Instance.new("UIStroke",b) st.Color=C_ACC st.Transparency=0.8
  local function ref() local flag=(k=="master" and ON) or OPT[k] ico.TextColor3=flag and Color3.fromRGB(0,255,80) or Color3.fromRGB(180,180,180) end
  ref()
  b.MouseEnter:Connect(function() TweenService:Create(st,TweenInfo.new(0.15),{Transparency=0.2}):Play() end)
  b.MouseLeave:Connect(function() TweenService:Create(st,TweenInfo.new(0.15),{Transparency=0.8}):Play() end)
  b.MouseButton1Click:Connect(function()
    if k=="master" then ON=not ON if not ON then clear() end else OPT[k]=not OPT[k] end
    ref()
  end)
end
tog("ESP Master","master") tog("Chams","chams") tog("Tracers","tracers")
tog("Distance","distance") tog("Health Bar","health") tog("VisCheck","vischeck")
local open=false
UIS.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode==Enum.KeyCode.BackSlash then open=not open local y=-f.AbsoluteSize.Y/2
    local tgt=open and UDim2.new(0,10,0.5,y) or UDim2.new(0,-f.AbsoluteSize.X-10,0.5,y)
    TweenService:Create(f,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=tgt}):Play() end end)
-- auto open
open=true
TweenService:Create(f,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0,10,0.5,-f.AbsoluteSize.Y/2)}):Play()
]=]

--------------------------------------------------------------------
--  launch
--------------------------------------------------------------------
local function loadUI()
    local ok,err=pcall(loadstring,OPENWORLD_SRC)
    if not ok then flash(C_RED,"UI Error") warn(err) return end
    TweenService:Create(panel,TweenInfo.new(0.4),{BackgroundTransparency=1,Size=UDim2.new(0,0,0,0)}):Play()
    task.wait(0.45) sg:Destroy()
end
unlock.MouseButton1Click:Connect(function()
    if (box.Text:gsub("%s+",""):lower())==KEY then flash(C_GREEN,"Granted") loadUI()
    else flash(C_RED,"Invalid") end
end)
UIS.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode==Enum.KeyCode.Return then
    if (box.Text:gsub("%s+",""):lower())==KEY then flash(C_GREEN,"Granted") loadUI()
    else flash(C_RED,"Invalid") end
end end)
unlock.MouseEnter:Connect(function() TweenService:Create(hi,TweenInfo.new(0.12),{BackgroundTransparency=0.25}):Play() end)
unlock.MouseLeave:Connect(function() TweenService:Create(hi,TweenInfo.new(0.12),{BackgroundTransparency=0.9}):Play() end)

panel.Position=UDim2.new(0.5,-150,1,0)
TweenService:Create(panel,TweenInfo.new(0.7,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
    Position=UDim2.new(0.5,-panel.Size.X.Offset/2,0.5,-panel.Size.Y.Offset/2)
}):Play()
