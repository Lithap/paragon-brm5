--------------------------------------------------------------------
--  PARAGON OPEN WORLD  •  Skeleton ESP + LOS + Clean Tracers
--  2025-07-XX
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

-- ░█▀▀░█▀█░█▀█░█▀▄░█▀▀   – services
local Players, TweenService, RunService, UIS =
      game:GetService("Players"), game:GetService("TweenService"),
      game:GetService("RunService"), game:GetService("UserInputService")
local LP, Camera     = Players.LocalPlayer, workspace.CurrentCamera
local PG             = LP:WaitForChild("PlayerGui")
local DRAWING_OK     = pcall(function() return Drawing end)

-- ░█▀▄░█▀█░█▀█░█▀▀   – config
local MAX_DIST  = 3000          -- ← extended range
local TICK_HZ   = 20
local BAR_SIZE  = Vector2.new(50,4)
local TRACER_ORG= function() return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) end

-- UI colours
local C_MAIN , C_ACC , C_TEXT = Color3.fromRGB(22,22,26), Color3.fromRGB(0,160,255), Color3.fromRGB(240,240,240)
local ICON_X = "✕"

-- state flags
local ESP_ON = false
local OPT = {skeleton=true,chams=false,tracers=false,distance=false,health=false,vischeck=false}

-- caches
local targets = {}   -- [Model] = {root=part}
local pool = {       -- weak-key stores
    highlight = setmetatable({}, {__mode="k"}),
    tracer    = setmetatable({}, {__mode="k"}),
    label     = setmetatable({}, {__mode="k"}),
    health    = setmetatable({}, {__mode="k"}),
    skeleton  = setmetatable({}, {__mode="k"}),  -- {Drawing.Line, …}
}

-- helpers ---------------------------------------------------------
local function getHi(m)
    local h=pool.highlight[m]
    if not h or h.Parent==nil then
        h=Instance.new("Highlight"); h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent=m; pool.highlight[m]=h
    end; return h
end
local function getDraw(tbl,id,kind)
    if not DRAWING_OK then return end
    local o=tbl[id]; if not o then o=Drawing.new(kind); tbl[id]=o end
    return o
end
local function hide(tbl,id) if tbl[id] then tbl[id].Visible=false end end
local function hpColor(f) return Color3.fromRGB((1-f)*255, f*255, 0) end
local function LOS(part)
    local rp=RaycastParams.new()
    rp.FilterType=Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances={LP.Character or Instance.new("Folder")}
    local hit=workspace:Raycast(Camera.CFrame.Position, part.Position-Camera.CFrame.Position, rp)
    return (not hit) or hit.Instance:IsDescendantOf(part.Parent)
end

-- npc register ----------------------------------------------------
local function enemy(m)
    if not(m:IsA("Model") and m.Name=="Male") then return false end
    for _,c in ipairs(m:GetChildren()) do if c.Name:sub(1,3)=="AI_" then return true end end
    return false
end
local function add(m)
    if targets[m] then return end
    local root=m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso")
    if root then targets[m]={root=root} end
end
for _,d in ipairs(workspace:GetDescendants()) do if enemy(d) then add(d) end end
workspace.DescendantAdded:Connect(function(d) if enemy(d) then task.wait(); add(d) end end)
workspace.DescendantRemoving:Connect(function(d) targets[d]=nil pool.skeleton[d]=nil end)

-- skeleton util ---------------------------------------------------
local BONES = {           -- pairs of part names to connect
    {"Head","UpperTorso"},
    {"UpperTorso","HumanoidRootPart"},
    {"HumanoidRootPart","LeftFoot"},
    {"HumanoidRootPart","RightFoot"},
    {"UpperTorso","LeftHand"},
    {"UpperTorso","RightHand"},
}
local function ensureSkeleton(model)
    local arr = pool.skeleton[model]
    if arr then return arr end
    arr={}
    for _=1,#BONES do
        local ln = Drawing.new("Line")
        ln.Thickness, ln.Color = 2, Color3.fromRGB(255,255,0)
        ln.Visible=false
        arr[#arr+1]=ln
    end
    pool.skeleton[model]=arr
    return arr
end
local function hideSkeleton(model)
    local arr=pool.skeleton[model]; if not arr then return end
    for _,ln in ipairs(arr) do ln.Visible=false end
end

-- esp loop --------------------------------------------------------
local acc=0
RunService.RenderStepped:Connect(function(dt)
    if not ESP_ON then return end
    acc+=dt; if acc < 1/TICK_HZ then return end; acc=0
    local camPos=Camera.CFrame.Position

    for m,t in pairs(targets) do
        if not m.Parent then targets[m]=nil hideSkeleton(m) continue end
        local root=t.root
        if not root then continue end

        local dist=(root.Position-camPos).Magnitude
        if dist>MAX_DIST then
            hide(pool.tracer,m); hide(pool.label,m); hide(pool.health,m)
            hideSkeleton(m)
            if pool.highlight[m] then pool.highlight[m].Enabled=false end
            continue
        end

        local v2,onScreen=Camera:WorldToViewportPoint(root.Position)
        local vis = (not OPT.vischeck) or LOS(root)

        -- SKELETON -------------------------------------------------
        if OPT.skeleton and onScreen and DRAWING_OK then
            local lines = ensureSkeleton(m)
            for i,pair in ipairs(BONES) do
                local a=m:FindFirstChild(pair[1]); local b=m:FindFirstChild(pair[2])
                local ln = lines[i]
                if a and b then
                    local a2,onA=Camera:WorldToViewportPoint(a.Position)
                    local b2,onB=Camera:WorldToViewportPoint(b.Position)
                    if onA and onB then
                        ln.Visible=true
                        ln.From, ln.To = Vector2.new(a2.X,a2.Y), Vector2.new(b2.X,b2.Y)
                        ln.Color = vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
                    else ln.Visible=false end
                else ln.Visible=false end
            end
        else hideSkeleton(m) end

        -- CHAMS ----------------------------------------------------
        if OPT.chams then
            local h=getHi(m); h.Enabled=true
            h.FillColor           = vis and Color3.fromRGB(255,75,75) or Color3.fromRGB(0,190,255)
            h.FillTransparency    = 0.15
            h.OutlineColor        = h.FillColor
            h.OutlineTransparency = 0.1
        elseif pool.highlight[m] then pool.highlight[m].Enabled=false end

        if DRAWING_OK then
            -- TRACER
            if OPT.tracers then
                local tr=getDraw(pool.tracer,m,"Line")
                tr.Visible=true; tr.Thickness=1.5
                tr.Color=vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,255,0)
                tr.From, tr.To = TRACER_ORG(), Vector2.new(v2.X,v2.Y)
            else hide(pool.tracer,m) end

            -- DISTANCE
            if OPT.distance and onScreen then
                local lb=getDraw(pool.label,m,"Text")
                lb.Visible=true; lb.Center=true; lb.Outline=true; lb.Size=14
                lb.Color=Color3.new(1,1,1); lb.Text=("%.0f"):format(dist)
                lb.Position=Vector2.new(v2.X,v2.Y-16)
            else hide(pool.label,m) end

            -- HEALTH
            if OPT.health and onScreen then
                local hum=m:FindFirstChildOfClass("Humanoid")
                if hum then
                    local frac=math.clamp(hum.Health/hum.MaxHealth,0,1)
                    local hb=getDraw(pool.health,m,"Square")
                    hb.Visible=true; hb.Filled=true
                    hb.Size=BAR_SIZE*Vector2.new(frac,1)
                    hb.Position=Vector2.new(v2.X-BAR_SIZE.X/2, v2.Y+12)
                    hb.Color=hpColor(frac)
                end
            else hide(pool.health,m) end
        end
    end
end)

local function clearESP()
    for _,h in pairs(pool.highlight) do h.Enabled=false end
    for _,tbl in ipairs{pool.tracer,pool.label,pool.health} do
        for _,o in pairs(tbl) do o.Visible=false end
    end
    for m,_ in pairs(pool.skeleton) do hideSkeleton(m) end
end

--------------------------------------------------------------------
-- GUI panel -------------------------------------------------------
--------------------------------------------------------------------
-- wipe dupe panel
local dup=PG:FindFirstChild("ParagonMainUI") if dup then dup:Destroy() end

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
head.TextScaled=true
head.Text="PARAGON ESP"
head.TextColor3=C_TEXT
head.TextStrokeTransparency=0.85

local div=Instance.new("Frame",frame)
div.Position,div.Size,div.BackgroundColor3=UDim2.new(0,8,0,42),UDim2.new(1,-16,0,1),C_ACC

local body=Instance.new("Frame",frame)
body.Position,body.Size=UDim2.new(0,8,0,50),UDim2.new(1,-16,1,-58)
body.BackgroundTransparency=1
local list=Instance.new("UIListLayout",body)
list.Padding=UDim.new(0,6)
list.HorizontalAlignment, list.VerticalAlignment = Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top

local function addToggle(text,key,cb)
    local btn=Instance.new("TextButton",body)
    btn.Size=UDim2.new(1,0,0,32)
    btn.BackgroundColor3,btn.BackgroundTransparency=C_MAIN,0.15
    btn.AutoButtonColor=false
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)

    local label=Instance.new("TextLabel",btn)
    label.BackgroundTransparency=1
    label.Size, label.Position=UDim2.new(1,-28,1,0), UDim2.new(0,6,0,0)
    label.Font=Enum.Font.GothamSemibold
    label.TextScaled=true
    label.TextColor3=C_TEXT
    label.TextXAlignment=Enum.TextXAlignment.Left
    label.Text=text

    local ico=Instance.new("TextLabel",btn)
    ico.BackgroundTransparency=1
    ico.Size, ico.Position=UDim2.new(0,22,0,22), UDim2.new(1,-26,0.5,-11)
    ico.Font=Enum.Font.GothamBold
    ico.TextScaled=true
    ico.Text=ICON_X

    local st=Instance.new("UIStroke",btn) st.Color=C_ACC st.Transparency=0.8
    local function refresh()
        local flag=(key=="master" and ESP_ON) or OPT[key]
        ico.TextColor3=flag and Color3.fromRGB(0,255,80) or Color3.fromRGB(180,180,180)
    end
    refresh()

    btn.MouseEnter:Connect(function() TweenService:Create(st,TweenInfo.new(0.15),{Transparency=0.2}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(st,TweenInfo.new(0.15),{Transparency=0.8}):Play() end)

    btn.MouseButton1Click:Connect(function()
        if key=="master" then
            ESP_ON = not ESP_ON
            if not ESP_ON then clearESP() end
        else
            OPT[key] = not OPT[key]
        end
        refresh(); if cb then cb(OPT[key]) end
    end)
end

addToggle("ESP Master",      "master")
addToggle("Skeleton",        "skeleton")
addToggle("Chams",           "chams")
addToggle("Tracers",         "tracers")
addToggle("Distance",        "distance")
addToggle("Health Bar",      "health")
addToggle("VisCheck (LOS)",  "vischeck")

-- slide key
local open=false
local function slide()
    open=not open
    local y=-frame.AbsoluteSize.Y/2
    local tgt=open and UDim2.new(0,10,0.5,y) or UDim2.new(0,-frame.AbsoluteSize.X-10,0.5,y)
    TweenService:Create(frame,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=tgt}):Play()
end
UIS.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode==Enum.KeyCode.BackSlash then slide() end end)
slide()  -- open on load
