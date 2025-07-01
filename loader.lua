-- Paragon BRM5 • Rayfield Edition (v8 – **Rayfield‑only, linked flags**)  
-- NPC ESP with 3‑D Box, Chams, Tracers, Distance, Health – ON by default.  
-- • Loads ONLY the ESP logic (strips original GUI), exposing its `OPT` table so Rayfield toggles work.  
-- • No legacy Paragon panel anymore.  
-- • Key is **paragon**.  Right‑Shift opens Rayfield.

---------------------------------------------------------------------
-- 0. Silence “valex1” console spam -----------------------------------
---------------------------------------------------------------------
local LogService, ScriptContext = game:GetService("LogService"), game:GetService("ScriptContext")
local function swallow(msg) return typeof(msg)=="string" and msg:lower():find("valex1") end
LogService.MessageOut:Connect(function(m,t) if t==Enum.MessageType.MessageError and swallow(m) then return true end end)
ScriptContext.Error:Connect(function(m) if swallow(m) then return true end end)

---------------------------------------------------------------------
-- 1. Fetch Parvus openworld.lua and keep only ESP core ---------------
---------------------------------------------------------------------
local src = game:HttpGet("https://raw.githubusercontent.com/Lithap/paragon-brm5/main/esp.lua")
assert(src and #src>2000, "Failed to download openworld.lua")
-- extract everything before the GUI block
local core = src:match("^(.-)%-%-%s*GUI")
assert(core and #core>1000, "Failed to slice ESP core; repo layout changed")

-- load in a dedicated environment so we can reach OPT/clearESP
local env = {}; setmetatable(env,{__index=_G})
local fn,err = loadstring(core,"ParagonESPCore"); assert(fn,err)
setfenv(fn, env); assert(pcall(fn), "ESP core runtime error")

---------------------------------------------------------------------
-- 2. Turn ON desired visuals by default ------------------------------
---------------------------------------------------------------------
for _,k in ipairs({"box","chams","tracers","distance","health"}) do env.OPT[k]=true end
env.ESP_ON = true

---------------------------------------------------------------------
-- 3. Boot Rayfield ---------------------------------------------------
---------------------------------------------------------------------
getgenv().SecureMode = true
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()

local Window = Rayfield:CreateWindow({
    Name            = "Paragon BRM5 • Rayfield",
    LoadingTitle    = "Paragon BRM5",
    LoadingSubtitle = "Advanced ESP",
    Theme           = "Midnight",
    ConfigurationSaving = {Enabled=true, FileName="ParagonCfg"},
    KeySystem       = true,
    KeySettings     = {Title="Paragon Key",Subtitle="Enter key",Note="Key is: paragon",SaveKey=true,Key={"paragon"}}
})

---------------------------------------------------------------------
-- 4. Rayfield ↔ OPT bridge ------------------------------------------
---------------------------------------------------------------------
local tab = Window:CreateTab("ESP","eye")

tab:CreateLabel("Master Control")

tab:CreateToggle({Name="Enable ESP",CurrentValue=true,Callback=function(on)
    env.ESP_ON = on; if not on and env.clearESP then env.clearESP() end end})

tab:CreateLabel("Modules (NPCs)")
local function add(flag,label)
    tab:CreateToggle({Name=label,CurrentValue=env.OPT[flag],Callback=function(v) env.OPT[flag]=v end})
end
add("box","3‑D Box")
add("chams","Chams")
add("tracers","Tracers")
add("distance","Distance Text")
add("health","Health Bar")

Rayfield:Notify({Title="Paragon BRM5",Content="Rayfield ESP ready – Right‑Shift opens UI",Duration=5})
