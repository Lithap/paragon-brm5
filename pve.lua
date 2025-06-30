--------------------------------------------------------------------
--  SERVICES
--------------------------------------------------------------------
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local LP           = Players.LocalPlayer

local function log(msg)
    print("[PARAGON:PVE] " .. msg)
end

log("PVE module loaded")

--------------------------------------------------------------------
--  MAIN CONTAINER
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
if syn and syn.protect_gui then syn.protect_gui(gui) end
gui.IgnoreGuiInset = true
gui.Name = "ParagonPVE"
gui.ResetOnSpawn = false
gui.Parent = LP:WaitForChild("PlayerGui")

--------------------------------------------------------------------
--  STUB PANEL
--------------------------------------------------------------------
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0, 360, 0, 220)
panel.Position = UDim2.new(0.5, -180, 0.5, -110)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

local header = Instance.new("TextLabel", panel)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBlack
header.Text = "PARAGON - PVE"
header.TextColor3 = Color3.fromRGB(255, 255, 255)
header.TextScaled = true
log("PVE UI mounted.")
