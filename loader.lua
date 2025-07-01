-- Paragon BRM5 • Rayfield Lite (v10 – stable)
-- NPC ESP: **3‑D Box + Chams** only.  No legacy GUI.  Key = paragon.
-- Implementation notes:
--   • Uses the already‑stripped `openworld_esp.lua` (no GUI) → no slicing, no regex fail.
--   • Executes it in _G so the code runs unmodified.
--   • Rayfield toggles write directly to the global OPT table.
--   • Boxes & Chams enabled at startup.

---------------------------------------------------------------------
-- 0. Mute Valex spam -----------------------------------------------
---------------------------------------------------------------------
local LS, SC = game:GetService("LogService"), game:GetService("ScriptContext")
local function swallow(msg) return typeof(msg)=="string" and msg:lower():find("valex1") end
LS.MessageOut:Connect(function(m,t) if t==Enum.MessageType.MessageError and swallow(m) then return true end end)
SC.Error:Connect(function(m) if swallow(m) then return true end end)

---------------------------------------------------------------------
-- 1. Download GUI‑free Parvus ESP core ------------------------------
---------------------------------------------------------------------
local coreSrc = game:HttpGet("https://raw.githubusercontent.com/Lithap/paragon-brm5/main/esp.lua")
assert(coreSrc and #coreSrc>1000, "Failed to fetch esp.lua")

local coreFn, loadErr = loadstring(coreSrc, "ParvusESPCore"); assert(coreFn, loadErr)
assert(pcall(coreFn), "Parvus ESP runtime error – check executor")

-- Ensure globals exist
_G.OPT      = _G.OPT      or {}
_G.ESP_ON   = _G.ESP_ON   or false
_G.clearESP = _G.clearESP or function() end

-- Enable only Box + Chams
for _,k in ipairs({"box","chams"})                 do _G.OPT[k] = true end
for _,k in ipairs({"tracers","distance","health","vischeck","walkwalls"}) do _G.OPT[k] = false end
_G.ESP_ON = true

---------------------------------------------------------------------
-- 2. Boot Rayfield --------------------------------------------------
---------------------------------------------------------------------
getgenv().SecureMode = true
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()

local Window = Rayfield:CreateWindow({
  Name="Paragon BRM5 • Rayfield Lite",  LoadingTitle="Paragon BRM5", LoadingSubtitle="Lite ESP",
  Theme="Midnight", ConfigurationSaving={Enabled=true,FileName="ParagonCfg"},
  KeySystem=true,
  KeySettings={Title="Paragon Key",Subtitle="Enter key",Note="Key is: paragon",SaveKey=true,Key={"paragon"}}
})

---------------------------------------------------------------------
-- 3. Rayfield UI ----------------------------------------------------
---------------------------------------------------------------------
local tab = Window:CreateTab("ESP","eye")

tab:CreateLabel("Master Control")

tab:CreateToggle({Name="Enable ESP",CurrentValue=true,Callback=function(on)
    _G.ESP_ON = on; if not on then _G.clearESP() end end})

tab:CreateLabel("Modules (NPCs)")
local function add(flag,label)
    tab:CreateToggle({Name=label,CurrentValue=_G.OPT[flag],Callback=function(v) _G.OPT[flag]=v end})
end
add("box","3‑D Box")
add("chams","Chams")

Rayfield:Notify({Title="Paragon BRM5",Content="Lite ESP loaded – Right‑Shift shows UI",Duration=5})
