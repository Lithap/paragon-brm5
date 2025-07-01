--------------------------------------------------------------------
--  PARAGON • FULL SINGLE-FILE LOADER (July-2025)
--  key: paragon
--  »  Silences all Valex1 spam
--  »  Skeleton ESP embedded
--  »  No external HttpGet
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

--------------------------------------------------------------------
-- 0️⃣  VALEX EXTERMINATOR (runs first)
--------------------------------------------------------------------
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local ScriptCtx  = game:GetService("ScriptContext")

-- console filter
local function swallow(msg) if msg:find("Valex") then return true end end
LogService.MessageOut:Connect(function(m,t)
    if t == Enum.MessageType.MessageError then return swallow(m) end
end)
ScriptCtx.Error:Connect(function(m,stack,scriptInst) return swallow(m) end)

-- script neutraliser
local function purge(inst)
    if inst:IsA("LocalScript") or inst:IsA("ModuleScript") then
        local ok,src = pcall(function() return inst.Source end)
        if inst.Name:find("Valex") or (ok and src and src:find("Valex")) then
            pcall(function() inst.Source = "" end)
            inst.Disabled = true
            inst.Name     = "Valex_DISABLED"
        end
    end
end
for _,d in ipairs(game:GetDescendants()) do purge(d) end          -- wipe existing
game.DescendantAdded:Connect(purge)                               -- wipe future
RunService.Heartbeat:Connect(function() purge(game) end)          -- periodic sweep

--------------------------------------------------------------------
-- 1️⃣  LOADER PANEL
--------------------------------------------------------------------
local Players, TweenService, UIS, Camera =
      game:GetService("Players"), game:GetService("TweenService"),
      game:GetService("UserInputService"), workspace.CurrentCamera
local LP         = Players.LocalPlayer
local GUI_PARENT = LP:WaitForChild("PlayerGui")

(GUI_PARENT:FindFirstChild("ParagonLoaderUI"))?.:Destroy()

-- colours / constants
local C_BLUE  = Color3.fromRGB(0,160,255)
local C_RED   = Color3.fromRGB(255,70,70)
local C_GREEN = Color3.fromRGB(80,255,80)
local C_TEXT  = Color3.fromRGB(235,235,235)
local C_PANEL = Color3.fromRGB(20,20,24)
local KEY     = "paragon"

-- root gui
local sg = Instance.new("ScreenGui", GUI_PARENT)
sg.Name, sg.IgnoreGuiInset, sg.ResetOnSpawn = "ParagonLoaderUI", true, false
if syn and syn.protect_gui then syn.protect_gui(sg) end

-- panel
local panel = Instance.new("Frame", sg)
panel.BackgroundColor3, panel.BackgroundTransparency = C_PANEL, 0.3
panel.BorderSizePixel = 0
panel.Position = UDim2.new(0.5,-160,0.5,-130)
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,6)
local stroke = Instance.new("UIStroke", panel) stroke.Color = C_BLUE

local header = Instance.new("TextLabel", panel)
header.Size = UDim2.new(1,0,0,40) header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBlack header.TextScaled = true
header.TextColor3 = C_TEXT header.Text = "PARAGON"

local divider = Instance.new("Frame", panel)
divider.Position, divider.Size = UDim2.new(0,6,0,42), UDim2.new(1,-12,0,1)
divider.BackgroundColor3 = C_BLUE

local container = Instance.new("Frame", panel) container.BackgroundTransparency = 1
local layout = Instance.new("UIListLayout", container) layout.Padding = UDim.new(0,4)

-- key row
local row = Instance.new("Frame", container) row.Size = UDim2.new(1,0,0,32) row.BackgroundTransparency = 1
local lbl = Instance.new("TextLabel", row)
lbl.BackgroundTransparency = 1
lbl.Size = UDim2.new(0.55,0,1,0)
lbl.Font = Enum.Font.GothamSemibold lbl.TextScaled = true
lbl.TextColor3 = C_TEXT lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Text = "Enter Key:"
local box = Instance.new("TextBox", row)
box.Size, box.Position = UDim2.new(0.45,0,1,0), UDim2.new(0.55,0,0,0)
box.BackgroundColor3, box.BackgroundTransparency = C_PANEL, 0.35
box.BorderSizePixel = 0
box.Font = Enum.Font.Gotham box.TextScaled=true
box.TextColor3=C_TEXT box.PlaceholderText=KEY box.ClearTextOnFocus=false
Instance.new("UICorner", box).CornerRadius = UDim.new(0,4)

-- unlock button
local unlock = Instance.new("TextButton", container)
unlock.Size=UDim2.new(1,0,0,30)
unlock.BackgroundColor3, unlock.BackgroundTransparency = C_PANEL, 0.35
unlock.BorderSizePixel = 0
unlock.Font=Enum.Font.GothamBold unlock.TextScaled = true
unlock.TextColor3=C_TEXT unlock.Text="Unlock"
Instance.new("UICorner", unlock).CornerRadius = UDim.new(0,4)
local hi = Instance.new("Frame", unlock)
hi.Size=UDim2.new(1,0,1,0) hi.BackgroundColor3=C_BLUE
hi.BackgroundTransparency=0.9 hi.BorderSizePixel=0

-- resize
local function resize()
    local need = 46
    for _,c in ipairs(container:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then
            need += c.Size.Y.Offset + layout.Padding.Offset
        end
    end
    container.Size      = UDim2.new(1,-12,0,need-46)
    container.Position  = UDim2.new(0,6,0,46)
    local vp = Camera.ViewportSize
    panel.Size = UDim2.new(0, math.clamp(vp.X*0.28,320,500), 0, math.max(need+20,260))
end
resize(); layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

local function flash(col,msg)
    stroke.Color,divider.BackgroundColor3 = col,col
    unlock.Text,unlock.TextColor3 = msg,col
    task.wait(1)
    unlock.Text,unlock.TextColor3 = "Unlock", C_TEXT
    stroke.Color,divider.BackgroundColor3 = C_BLUE,C_BLUE
end

--------------------------------------------------------------------
-- 2️⃣  EMBEDDED SKELETON-ESP CODE
--------------------------------------------------------------------
local OPENWORLD_SRC = --------------------------------------------------------------------
--  >>>>>>>>>  START  –  Skeleton-ESP v3  (July-2025)  >>>>>>>>>>
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end
local Players, TweenService, RunService, UIS =
      game:GetService("Players"), game:GetService("TweenService"),
      game:GetService("RunService"), game:GetService("UserInputService")
local LP, Camera = Players.LocalPlayer, workspace.CurrentCamera
local PG         = LP:WaitForChild("PlayerGui")
local DRAWING_OK = pcall(function() return Drawing end)

--====== CONFIG ======--
local MAX_DIST  = 3000     -- render range
local TICK_HZ   = 20       -- refresh rate
local BAR_SIZE  = Vector2.new(50,4)
local CENTER    = function()
                    local v = Camera.ViewportSize
                    return Vector2.new(v.X/2, v.Y/2)
                  end

--====== STATE / CACHES ======--
local ESP_ON = false
local OPT    = {skeleton=true, chams=false, tracers=false,
                distance=false,  health=true, vischeck=false}

local targets = {}   -- [Model] = {root = Part}
local wmt = {__mode = "k"}
local pool = {
    hi    = setmetatable({}, wmt),
    trac  = setmetatable({}, wmt),
    lab   = setmetatable({}, wmt),
    hp    = setmetatable({}, wmt),
    skel  = setmetatable({}, wmt),
}

--====== HELPERS ======--
local function getHi(m)
    local h = pool.hi[m]
    if not h or h.Parent == nil then
        h = Instance.new("Highlight")
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = m
        pool.hi[m] = h
    end
    return h
end
local function getDraw(tab,id,kind)
    if not DRAWING_OK then return end
    local o = tab[id]; if not o then o = Drawing.new(kind); tab[id] = o end
    return o
end
local function hide(tab,id) if tab[id] then tab[id].Visible = false end end
local function hpColor(f)   return Color3.fromRGB((1-f)*255, f*255, 0) end
local function LOS(p)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances = {LP.Character or Instance.new("Folder")}
    local hit = workspace:Raycast(Camera.CFrame.Position,
                                  p.Position - Camera.CFrame.Position, rp)
    return (not hit) or hit.Instance:IsDescendantOf(p.Parent)
end

--====== REGISTRATION ======--
local function isEnemy(m)
    if not (m:IsA("Model") and m.Name == "Male") then return false end
    for _,c in ipairs(m:GetChildren()) do
        if c.Name:sub(1,3) == "AI_" then return true end
    end
    return false
end
local function register(m)
    if targets[m] then return end
    local root = m:FindFirstChild("HumanoidRootPart") or
                 m:FindFirstChild("Head")              or
                 m:FindFirstChild("UpperTorso")
    if root then targets[m] = {root = root} end
end
for _,d in ipairs(workspace:GetDescendants()) do if isEnemy(d) then register(d) end end
workspace.DescendantAdded:Connect(function(d) if isEnemy(d) then task.wait(); register(d) end end)
workspace.DescendantRemoving:Connect(function(d)
    targets[d] = nil
    pool.skel[d] = nil
end)

--====== SKELETON ======--
local BONES = {  -- 15 lines
    {"Head","UpperTorso"},
    {"UpperTorso","HumanoidRootPart"},
    {"HumanoidRootPart","LeftUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},
    {"LeftLowerLeg","LeftFoot"},
    {"HumanoidRootPart","RightUpperLeg"},
    {"RightUpperLeg","RightLowerLeg"},
    {"RightLowerLeg","RightFoot"},
    {"UpperTorso","LeftUpperArm"},
    {"LeftUpperArm","LeftLowerArm"},
    {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},
    {"RightUpperArm","RightLowerArm"},
    {"RightLowerArm","RightHand"},
    {"HumanoidRootPart","LowerTorso"}, -- spine fill
}
local function ensureSkel(m)
    local arr = pool.skel[m]
    if arr then return arr end
    arr = {}
    for _ = 1,#BONES do
        local ln = Drawing.new("Line")
        ln.Thickness = 2
        ln.Visible   = false
        arr[#arr+1] = ln
    end
    pool.skel[m] = arr
    return arr
end
local function hideSkel(m)
    local arr = pool.skel[m]; if not arr then return end
    for _,l in ipairs(arr) do l.Visible = false end
end

--====== MAIN LOOP ======--
local dtAcc = 0
RunService.RenderStepped:Connect(function(dt)
    if not ESP_ON then return end
    dtAcc += dt
    if dtAcc < 1/TICK_HZ then return end
    dtAcc = 0

    local camPos = Camera.CFrame.Position

    for m,t in pairs(targets) do
        if not m.Parent then
            targets[m] = nil; hideSkel(m)
            hide(pool.trac,m); hide(pool.lab ,m); hide(pool.hp ,m)
            if pool.hi[m] then pool.hi[m].Enabled = false end
            continue
        end

        local hum = m:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then     -- dead ⇒ hide visuals fast
            hideSkel(m); hide(pool.trac,m); hide(pool.lab,m); hide(pool.hp,m)
            if pool.hi[m] then pool.hi[m].Enabled = false end
            continue
        end

        local root = t.root
        if not root then continue end

        local dist = (root.Position - camPos).Magnitude
        if dist > MAX_DIST then
            hideSkel(m); hide(pool.trac,m); hide(pool.lab,m); hide(pool.hp,m)
            if pool.hi[m] then pool.hi[m].Enabled = false end
            continue
        end

        local v2, onScr = Camera:WorldToViewportPoint(root.Position)
        local vis = (not OPT.vischeck) or LOS(root)

        -- Skeleton
        if OPT.skeleton and onScr and DRAWING_OK then
            local ln = ensureSkel(m)
            for i,b in ipairs(BONES) do
                local a = m:FindFirstChild(b[1])
                local bPart = m:FindFirstChild(b[2])
                local dLine = ln[i]
                if a and bPart then
                    local a2,onA = Camera:WorldToViewportPoint(a.Position)
                    local b2,onB = Camera:WorldToViewportPoint(bPart.Position)
                    if onA and onB then
                        dLine.Visible = true
                        dLine.From, dLine.To = Vector2.new(a2.X,a2.Y), Vector2.new(b2.X,b2.Y)
                        dLine.Color = vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
                    else dLine.Visible = false end
                else dLine.Visible = false end
            end
        else hideSkel(m) end

        -- Chams
        if OPT.chams then
            local h = getHi(m)
            h.Enabled             = true
            h.FillTransparency    = 0.15
            h.OutlineTransparency = 0.1
            h.FillColor           = vis and Color3.fromRGB(255,75,75) or Color3.fromRGB(0,190,255)
            h.OutlineColor        = h.FillColor
        elseif pool.hi[m] then
            pool.hi[m].Enabled = false
        end

        -- Tracer
        if DRAWING_OK then
            if OPT.tracers then
                local tr = getDraw(pool.trac,m,"Line")
                tr.Visible   = true
                tr.Thickness = 1.5
                tr.Color     = vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,255,0)
                tr.From, tr.To = CENTER(), Vector2.new(v2.X,v2.Y)
            else hide(pool.trac,m) end

            -- Distance
            if OPT.distance and onScr then
                local lb = getDraw(pool.lab,m,"Text")
                lb.Visible, lb.Center, lb.Outline, lb.Size = true,true,true,14
                lb.Color, lb.Text = Color3.new(1,1,1), ("%.0f"):format(dist)
                lb.Position       = Vector2.new(v2.X, v2.Y - 16)
            else hide(pool.lab,m) end

            -- Health
            if OPT.health and onScr and hum then
                local frac = math.clamp(hum.Health / hum.MaxHealth, 0,1)
                local hb   = getDraw(pool.hp,m,"Square")
                hb.Visible, hb.Filled = true, true
                hb.Size     = BAR_SIZE * Vector2.new(frac,1)
                hb.Position = Vector2.new(v2.X - BAR_SIZE.X/2, v2.Y + 12)
                hb.Color    = hpColor(frac)
            else hide(pool.hp,m) end
        end
    end
end)

--====== CLEAR ESP (used when master toggle off) ======--
local function clear()
    for _,h in pairs(pool.hi) do h.Enabled = false end
    for _,tbl in ipairs{pool.trac,pool.lab,pool.hp} do
        for _,o in pairs(tbl) do o.Visible = false end
    end
    for m,_ in pairs(pool.skel) do hideSkel(m) end
end

--------------------------------------------------------------------
--  GUI PANEL  (same as before, but master toggle controls ESP_ON)
--------------------------------------------------------------------
local C_MAIN,C_ACC,C_TEXT = Color3.fromRGB(22,22,26),Color3.fromRGB(0,160,255),Color3.fromRGB(240,240,240)
local ICON="✕"
(PG:FindFirstChild("ParagonMainUI"))?.:Destroy()
local gui=Instance.new("ScreenGui",PG)
gui.Name,gui.IgnoreGuiInset,gui.ResetOnSpawn="ParagonMainUI",true,false
if syn and syn.protect_gui then syn.protect_gui(gui) end
local frame=Instance.new("Frame",gui)
frame.AnchorPoint=Vector2.new(0,0.5)
frame.Size=UDim2.new(0,270,0,340)
frame.Position=UDim2.new(0,-280,0.5,0)
frame.BackgroundColor3,frame.BackgroundTransparency=C_MAIN,0.2
frame.BorderSizePixel=0
Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",frame).Color=C_ACC
local head=Instance.new("TextLabel",frame)
head.Size=UDim2.new(1,0,0,40)
head.BackgroundTransparency=1
head.Font=Enum.Font.GothamBlack
head.Text="PARAGON ESP"
head.TextScaled=true
head.TextColor3=C_TEXT
head.TextStrokeTransparency=0.85
local div=Instance.new("Frame",frame)
div.Position,div.Size,div.BackgroundColor3=UDim2.new(0,8,0,42),UDim2.new(1,-16,0,1),C_ACC
local body=Instance.new("Frame",frame)
body.Position,body.Size=UDim2.new(0,8,0,50),UDim2.new(1,-16,1,-58)
body.BackgroundTransparency=1
local list=Instance.new("UIListLayout",body)
list.Padding=UDim.new(0,6)
list.HorizontalAlignment=list.HorizontalAlignment.Center

local function toggle(text,key)
    local b=Instance.new("TextButton",body)
    b.Size=UDim2.new(1,0,0,32)
    b.BackgroundColor3,b.BackgroundTransparency=C_MAIN,0.15
    b.AutoButtonColor=false
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)

    local t=Instance.new("TextLabel",b)
    t.BackgroundTransparency=1
    t.Size,t.Position=UDim2.new(1,-28,1,0),UDim2.new(0,6,0,0)
    t.Font=Enum.Font.GothamSemibold
    t.TextScaled=true
    t.TextColor3=C_TEXT
    t.TextXAlignment=Enum.TextXAlignment.Left
    t.Text=text

    local ico=Instance.new("TextLabel",b)
    ico.BackgroundTransparency=1
    ico.Size,ico.Position=UDim2.new(0,22,0,22),UDim2.new(1,-26,0.5,-11)
    ico.Font=Enum.Font.GothamBold
    ico.TextScaled=true
    ico.Text=ICON

    local st=Instance.new("UIStroke",b) st.Color=C_ACC st.Transparency=0.8
    local function ref() local f=(key=="master" and ESP_ON) or OPT[key] ico.TextColor3=f and Color3.fromRGB(0,255,80) or Color3.fromRGB(180,180,180) end
    ref()

    b.MouseEnter:Connect(function() TweenService:Create(st,TweenInfo.new(0.15),{Transparency=0.2}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(st,TweenInfo.new(0.15),{Transparency=0.8}):Play() end)

    b.MouseButton1Click:Connect(function()
        if key=="master" then
            ESP_ON = not ESP_ON
            if not ESP_ON then clear() end
        else
            OPT[key] = not OPT[key]
        end
        ref()
    end)
end

toggle("ESP Master","master")
toggle("Skeleton","skeleton")
toggle("Chams","chams")
toggle("Tracers","tracers")
toggle("Distance","distance")
toggle("Health","health")
toggle("VisCheck","vischeck")

-- slide with backslash
local open=false
local function slide()
    open=not open
    local y=-frame.AbsoluteSize.Y/2
    local tgt=open and UDim2.new(0,10,0.5,y) or UDim2.new(0,-frame.AbsoluteSize.X-10,0.5,y)
    TweenService:Create(frame,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=tgt}):Play()
end
UIS.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode==Enum.KeyCode.BackSlash then slide() end end)
slide()  -- auto open
--------------------------------------------------------------------
--  >>>>>>>>>  END – paste inside OPENWORLD_SRC  >>>>>>>>>>
--------------------------------------------------------------------

--------------------------------------------------------------------

--------------------------------------------------------------------
-- 3️⃣  LAUNCH
--------------------------------------------------------------------
local function loadUI()
    local ok,err = pcall(loadstring, OPENWORLD_SRC)
    if not ok then flash(C_RED,"UI Error") warn(err) return end
    TweenService:Create(panel,TweenInfo.new(0.4),{BackgroundTransparency=1,Size=UDim2.new(0,0,0,0)}):Play()
    task.wait(0.45) sg:Destroy()
end
local function check()
    if (box.Text:gsub("%s+",""):lower()) == KEY then flash(C_GREEN,"Granted") loadUI()
    else flash(C_RED,"Invalid") end
end
unlock.MouseButton1Click:Connect(check)
UIS.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode==Enum.KeyCode.Return then check() end end)
unlock.MouseEnter:Connect(function() TweenService:Create(hi,TweenInfo.new(0.12),{BackgroundTransparency=0.25}):Play() end)
unlock.MouseLeave:Connect(function() TweenService:Create(hi,TweenInfo.new(0.12),{BackgroundTransparency=0.9}):Play() end)

panel.Position=UDim2.new(0.5,-150,1,0)
TweenService:Create(panel,TweenInfo.new(0.7,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
    Position=UDim2.new(0.5,-panel.Size.X.Offset/2,0.5,-panel.Size.Y.Offset/2)
}):Play()
