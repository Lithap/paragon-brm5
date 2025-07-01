--------------------------------------------------------------------
-- PARAGON OPEN WORLD  •  Advanced ESP + LOS + client noclip (final)
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

--------------------------------------------------------------------
-- Services
--------------------------------------------------------------------
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local LP           = Players.LocalPlayer
local Camera       = workspace.CurrentCamera
local PG           = LP:WaitForChild("PlayerGui")
local DRAWING_OK   = pcall(function() return Drawing end)

--------------------------------------------------------------------
-- Config
--------------------------------------------------------------------
local MAX_DIST   = 1500
local TICK_HZ    = 20
local BOX_PAD    = 0.05
local BAR_SIZE   = Vector2.new(50,4)
local TRACER_ORG = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)

--------------------------------------------------------------------
-- UI colours
--------------------------------------------------------------------
local C_MAIN , C_ACC , C_TEXT = Color3.fromRGB(22,22,26), Color3.fromRGB(0,160,255), Color3.fromRGB(240,240,240)
local ICON_X = "✕"

--------------------------------------------------------------------
-- State flags
--------------------------------------------------------------------
local ESP_ON = false
local OPT = {box=true,chams=false,tracers=false,distance=false,health=false,vischeck=false,walkwalls=false}

--------------------------------------------------------------------
-- Caches
--------------------------------------------------------------------
local targets = {}  -- [Model] = {root = Part}
local pool = {      -- weak-key stores
    box       = setmetatable({}, {__mode="k"}),
    highlight = setmetatable({}, {__mode="k"}),
    tracer    = setmetatable({}, {__mode="k"}),
    label     = setmetatable({}, {__mode="k"}),
    health    = setmetatable({}, {__mode="k"}),
}

--------------------------------------------------------------------
-- Factories
--------------------------------------------------------------------
local function getBox(p)
    local b = pool.box[p]
    if not b or b.Parent==nil then
        b = Instance.new("BoxHandleAdornment")
        b.AlwaysOnTop, b.ZIndex, b.Adornee = true, 5, p
        b.Parent = p
        pool.box[p] = b
    end
    return b
end

local function getHi(m)
    local h = pool.highlight[m]
    if not h or h.Parent==nil then
        h = Instance.new("Highlight")
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = m
        pool.highlight[m] = h
    end
    return h
end

local function getDraw(tbl,id,kind)
    if not DRAWING_OK then return end
    local o = tbl[id]; if not o then o = Drawing.new(kind); tbl[id]=o end
    return o
end
local function hide(tbl,id) if tbl[id] then tbl[id].Visible=false end end
local function healthCol(f) return Color3.fromRGB((1-f)*255, f*255, 0) end

local function hasLOS(part)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances = {LP.Character or Instance.new("Folder")}
    local hit = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rp)
    return (not hit) or hit.Instance:IsDescendantOf(part.Parent)
end

--------------------------------------------------------------------
-- NPC registration
--------------------------------------------------------------------
local function isEnemy(m)
    if not (m:IsA("Model") and m.Name=="Male") then return false end
    for _,c in ipairs(m:GetChildren()) do if c.Name:sub(1,3)=="AI_" then return true end end
    return false
end
local function register(m)
    if targets[m] then return end
    local head = m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso")
    if head then targets[m]={root=head} end
end
for _,d in ipairs(workspace:GetDescendants()) do if isEnemy(d) then register(d) end end
workspace.DescendantAdded:Connect(function(d) if isEnemy(d) then task.wait(); register(d) end end)
workspace.DescendantRemoving:Connect(function(d) targets[d]=nil end)

--------------------------------------------------------------------
-- ESP loop
--------------------------------------------------------------------
local acc=0
RunService.RenderStepped:Connect(function(dt)
    if not ESP_ON then return end
    acc+=dt; if acc<1/TICK_HZ then return end; acc=0
    local camPos = Camera.CFrame.Position

    for m,t in pairs(targets) do
        if not m.Parent then targets[m]=nil continue end
        local root = t.root
        if not root then continue end

        local dist = (root.Position - camPos).Magnitude
        if dist > MAX_DIST then
            hide(pool.tracer,m); hide(pool.label,m); hide(pool.health,m)
            if pool.box[root] then pool.box[root].Transparency=1 end
            if pool.highlight[m] then pool.highlight[m].Enabled=false end
            continue
        end

        local v2, onScreen = Camera:WorldToViewportPoint(root.Position)
        local vis = (not OPT.vischeck) or hasLOS(root)

        -- BOX
        if OPT.box and onScreen then
            local b = getBox(root)
            b.Size         = root.Size + Vector3.new(BOX_PAD, BOX_PAD, BOX_PAD)
            b.Transparency = 0.25
            b.Color3       = vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
        elseif pool.box[root] then pool.box[root].Transparency=1 end

        -- CHAMS
        if OPT.chams then
            local h = getHi(m)
            h.Enabled             = true
            h.FillColor           = vis and Color3.fromRGB(255,75,75) or Color3.fromRGB(0,190,255)
            h.FillTransparency    = 0.15
            h.OutlineColor        = h.FillColor
            h.OutlineTransparency = 0.1
        elseif pool.highlight[m] then
            pool.highlight[m].Enabled=false
        end

        if DRAWING_OK then
            -- TRACER
            if OPT.tracers and onScreen then
                local tr = getDraw(pool.tracer,m,"Line")
                tr.Visible, tr.Thickness = true, 1.5
                tr.Color = vis and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,255,0)
                tr.From, tr.To = TRACER_ORG, Vector2.new(v2.X, v2.Y)
            else hide(pool.tracer,m) end

            -- DISTANCE
            if OPT.distance and onScreen then
                local lb = getDraw(pool.label,m,"Text")
                lb.Visible, lb.Center, lb.Outline, lb.Size = true,true,true,14
                lb.Color, lb.Text = Color3.new(1,1,1), ("%.0f"):format(dist)
                lb.Position = Vector2.new(v2.X, v2.Y-16)
            else hide(pool.label,m) end

            -- HEALTH
            if OPT.health and onScreen then
                local hum = m:FindFirstChildOfClass("Humanoid")
                if hum then
                    local frac = math.clamp(hum.Health/hum.MaxHealth,0,1)
                    local hb = getDraw(pool.health,m,"Square")
                    hb.Visible, hb.Filled = true, true
                    hb.Size     = BAR_SIZE * Vector2.new(frac,1)
                    hb.Position = Vector2.new(v2.X-BAR_SIZE.X/2, v2.Y+12)
                    hb.Color    = healthCol(frac)
                end
            else hide(pool.health,m) end
        end
    end
end)

local function clearESP()
    for _,b in pairs(pool.box) do b.Transparency=1 end
    for _,h in pairs(pool.highlight) do h.Enabled=false end
    if DRAWING_OK then
        for _,tbl in ipairs{pool.tracer,pool.label,pool.health} do
            for _,o in pairs(tbl) do o.Visible=false end
        end
    end
end

--------------------------------------------------------------------
-- Simple noclip (client only)
--------------------------------------------------------------------
local function applyCollide(on)
    if LP.Character then
        for _,p in ipairs(LP.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=on; p.Massless=not on end
        end
    end
end
local function noclipToggle(on) applyCollide(not on) end
LP.CharacterAdded:Connect(function(c) c:WaitForChild("HumanoidRootPart",6); if OPT.walkwalls then applyCollide(false) end end)
RunService.Heartbeat:Connect(function()
    if OPT.walkwalls and LP.Character then
        for _,p in ipairs(LP.Character:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false; p.Massless=true end
        end
    end
end)

--------------------------------------------------------------------
-- GUI (panel + toggles)
--------------------------------------------------------------------
(PG:FindFirstChild("ParagonMainUI")):Destroy() if PG:FindFirstChild("ParagonMainUI") end
local gui = Instance.new("ScreenGui", PG)
gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn = "ParagonMainUI",true,false
if syn and syn.protect_gui then syn.protect_gui(gui) end

local frame = Instance.new("Frame", gui)
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

local function makeToggle(txt,key,cb)
    local btn=Instance.new("TextButton",body)
    btn.Size=UDim2.new(1,0,0,32)
    btn.BackgroundColor3,btn.BackgroundTransparency=C_MAIN,0.15
    btn.AutoButtonColor=false
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)

    local name=Instance.new("TextLabel",btn)
    name.BackgroundTransparency=1
    name.Size, name.Position = UDim2.new(1,-28,1,0), UDim2.new(0,6,0,0)
    name.Font=Enum.Font.GothamSemibold
    name.TextColor3=C_TEXT
    name.TextXAlignment=Enum.TextXAlignment.Left
    name.TextScaled=true
    name.Text=txt

    local ico=Instance.new("TextLabel",btn)
    ico.BackgroundTransparency=1
    ico.Size, ico.Position=UDim2.new(0,22,0,22), UDim2.new(1,-26,0.5,-11)
    ico.Font=Enum.Font.GothamBold
    ico.TextScaled=true
    ico.Text=ICON_X

    local st=Instance.new("UIStroke",btn) st.Color=C_ACC st.Transparency=0.8
    local function refresh()
        local on=(key=="master" and ESP_ON) or OPT[key]
        ico.TextColor3 = on and Color3.fromRGB(0,255,80) or Color3.fromRGB(180,180,180)
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
            if key=="walkwalls" then noclipToggle(OPT.walkwalls) end
        end
        refresh()
        if cb then cb(OPT[key]) end
    end)
end

makeToggle("ESP Master","master")
makeToggle("3D Box","box")
makeToggle("Chams","chams")
makeToggle("Tracers","tracers")
makeToggle("Distance","distance")
makeToggle("Health Bar","health")
makeToggle("VisCheck (LOS)","vischeck")
makeToggle("Walk Through Walls","walkwalls",noclipToggle)

-- slide panel (`\`)
local open=false
local function slide()
    open = not open
    local y=-frame.AbsoluteSize.Y/2
    local tgt=open and UDim2.new(0,10,0.5,y) or UDim2.new(0,-frame.AbsoluteSize.X-10,0.5,y)
    TweenService:Create(frame,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=tgt}):Play()
end
UIS.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode==Enum.KeyCode.BackSlash then slide() end end)
slide()  -- auto open
