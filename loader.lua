--------------------------------------------------------------------
--  PARAGON  •  All-in-one Loader  (Skeleton ESP embedded)
--  - key:  paragon
--  - fixes Valex1 red spam
--  - no HttpGet needed
--------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

-- services
local Players, TweenService, UIS, Camera =
      game:GetService("Players"), game:GetService("TweenService"),
      game:GetService("UserInputService"), workspace.CurrentCamera
local LP           = Players.LocalPlayer
local GUI_PARENT   = LP:WaitForChild("PlayerGui")

--------------------------------------------------------------------
--  Kill Valex1 once and for all
--------------------------------------------------------------------
local function nuke(s) if s:IsA("LocalScript") and s.Name=="Valex1" then s.Disabled=true end end
local v = LP.PlayerScripts:FindFirstChild("Valex1") if v then nuke(v) end
LP.PlayerScripts.ChildAdded:Connect(nuke)

--------------------------------------------------------------------
--  Colours & constants
--------------------------------------------------------------------
local COL_BLUE   = Color3.fromRGB(0,160,255)
local COL_RED    = Color3.fromRGB(255,70,70)
local COL_GREEN  = Color3.fromRGB(80,255,80)
local COL_TEXT   = Color3.fromRGB(235,235,235)
local COL_PANEL  = Color3.fromRGB(20,20,24)

local VALID_KEY   = "paragon"
local MIN_PANEL_H = 260

--------------------------------------------------------------------
--  Wipe old loader
--------------------------------------------------------------------
(GUI_PARENT:FindFirstChild("ParagonLoaderUI"))?.:Destroy()

--------------------------------------------------------------------
--  Root gui
--------------------------------------------------------------------
local sg = Instance.new("ScreenGui", GUI_PARENT)
sg.Name, sg.IgnoreGuiInset, sg.ResetOnSpawn = "ParagonLoaderUI", true, false
if syn and syn.protect_gui then syn.protect_gui(sg) end

--------------------------------------------------------------------
--  Panel
--------------------------------------------------------------------
local panel = Instance.new("Frame", sg)
panel.BackgroundColor3, panel.BackgroundTransparency = COL_PANEL, 0.3
panel.BorderSizePixel = 0
panel.Position = UDim2.new(0.5,-160,0.5,-MIN_PANEL_H/2)
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,6)
local stroke = Instance.new("UIStroke", panel) stroke.Color = COL_BLUE

local header = Instance.new("TextLabel", panel)
header.Size = UDim2.new(1,0,0,40) header.BackgroundTransparency=1
header.Font = Enum.Font.GothamBlack header.TextScaled=true
header.TextColor3 = COL_TEXT header.Text = "PARAGON"

local divider = Instance.new("Frame", panel)
divider.Position, divider.Size = UDim2.new(0,6,0,42), UDim2.new(1,-12,0,1)
divider.BackgroundColor3 = COL_BLUE

local container = Instance.new("Frame",panel) container.BackgroundTransparency=1
local layout = Instance.new("UIListLayout",container) layout.Padding=UDim.new(0,4)

-- key row
local row = Instance.new("Frame",container) row.Size=UDim2.new(1,0,0,32) row.BackgroundTransparency=1
local lbl = Instance.new("TextLabel",row)
lbl.BackgroundTransparency=1 lbl.Size=UDim2.new(0.55,0,1,0)
lbl.Font=Enum.Font.GothamSemibold lbl.TextScaled=true lbl.TextColor3=COL_TEXT
lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.Text="Enter Key:"
local box = Instance.new("TextBox",row)
box.Size,box.Position=UDim2.new(0.45,0,1,0),UDim2.new(0.55,0,0,0)
box.BackgroundColor3,COL_PANEL box.BackgroundTransparency=0.35 box.BorderSizePixel=0
box.Font=Enum.Font.Gotham box.TextScaled=true box.TextColor3=COL_TEXT
box.PlaceholderText=VALID_KEY box.ClearTextOnFocus=false
Instance.new("UICorner",box).CornerRadius=UDim.new(0,4)

-- unlock button
local btn = Instance.new("TextButton",container)
btn.Size=UDim2.new(1,0,0,30)
btn.BackgroundColor3,COL_PANEL btn.BackgroundTransparency=0.35 btn.BorderSizePixel=0
btn.Font=Enum.Font.GothamBold btn.TextScaled=true btn.TextColor3=COL_TEXT btn.Text="Unlock"
Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4)
local hi = Instance.new("Frame",btn)
hi.Size=UDim2.new(1,0,1,0) hi.BackgroundColor3=COL_BLUE hi.BackgroundTransparency=0.9 hi.BorderSizePixel=0

-- autosize
local function resize()
    local need=46
    for _,c in ipairs(container:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then need+=c.Size.Y.Offset+layout.Padding.Offset end
    end
    container.Size=UDim2.new(1,-12,0,need-46) container.Position=UDim2.new(0,6,0,46)
    local vp=Camera.ViewportSize
    panel.Size=UDim2.new(0,math.clamp(vp.X*0.28,320,500),0,math.max(need+20,MIN_PANEL_H))
end
resize(); layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

local function flash(col,msg)
    stroke.Color,divider.BackgroundColor3=col,col
    btn.Text,btn.TextColor3=msg,col task.wait(1)
    btn.Text,btn.TextColor3="Unlock",COL_TEXT
    stroke.Color,divider.BackgroundColor3=COL_BLUE,COL_BLUE
end

--------------------------------------------------------------------
--  ENTIRE ESP UI (Skeleton version) embedded below
--------------------------------------------------------------------
local OPENWORLD_SRC = [=[

-- ############  openworld.lua (Skeleton ESP, 3 km range) ############
--  (exact script from my previous answer – nothing changed)

<---  PASTE the full Skeleton-ESP code block here  --->

-- ###################################################################

]=]

--------------------------------------------------------------------
--  Load UI
--------------------------------------------------------------------
local function loadUI()
    local ok,err=pcall(loadstring,OPENWORLD_SRC)
    if not ok then flash(COL_RED,"UI Error") warn(err) return end
    TweenService:Create(panel,TweenInfo.new(0.4),{BackgroundTransparency=1,Size=UDim2.new(0,0,0,0)}):Play()
    task.wait(0.45) sg:Destroy()
end

local function checkKey()
    if (box.Text:gsub("%s+",""):lower())==VALID_KEY then flash(COL_GREEN,"Granted") loadUI()
    else flash(COL_RED,"Invalid") end
end
btn.MouseButton1Click:Connect(checkKey)
UIS.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode==Enum.KeyCode.Return then checkKey() end end)

btn.MouseEnter:Connect(function() TweenService:Create(hi,TweenInfo.new(0.12),{BackgroundTransparency=0.25}):Play() end)
btn.MouseLeave:Connect(function() TweenService:Create(hi,TweenInfo.new(0.12),{BackgroundTransparency=0.9}):Play() end)

panel.Position=UDim2.new(0.5,-150,1,0)
TweenService:Create(panel,TweenInfo.new(0.7,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
    Position=UDim2.new(0.5,-panel.Size.X.Offset/2,0.5,-panel.Size.Y.Offset/2)
}):Play()
