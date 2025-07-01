---------------------------------------------------------------------
-- 5. Clear util (unchanged)
---------------------------------------------------------------------
local function clear()
    for _,b in pairs(ESP.Cache.box)  do b.Transparency = 1 end
    for _,h in pairs(ESP.Cache.cham) do h.Enabled      = false end
    if DRAWING_OK then
        for _,t in pairs{ESP.Cache.tracer,ESP.Cache.label,ESP.Cache.health} do
            for _,o in pairs(t) do o.Visible = false end
        end
    end
end

---------------------------------------------------------------------
-- 6. Render loop  – now **every frame**, with smarter culling
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not ESP.Enabled then return end
    
    local camPos = Camera.CFrame.Position
    local vp     = Camera.ViewportSize
    local tracerOrigin = Vector2.new(vp.X/2, vp.Y)   -- recalc each frame

    for mdl,t in pairs(ESP.Targets) do
        local root = t.root
        if not root or not mdl.Parent then ESP.Targets[mdl] = nil continue end

        -- distance cull first
        local dist = (root.Position - camPos).Magnitude
        if dist > MAX_DIST then
            -- hide everything in one go
            if DRAWING_OK then
                hide(ESP.Cache.tracer, mdl)
                hide(ESP.Cache.label,  mdl)
                hide(ESP.Cache.health, mdl)
            end
            if ESP.Cache.box[root] then ESP.Cache.box[root].Transparency = 1 end
            if ESP.Cache.cham[mdl]  then ESP.Cache.cham[mdl].Enabled     = false end
            continue
        end

        -- 2-D screen projection
        local scr, onScr = Camera:WorldToViewportPoint(root.Position)
        if not onScr and not ESP.Options.tracers then  -- nothing to draw off-screen
            continue
        end
        
        -------------------------------- Box (3-D) -------------------
        if ESP.Options.box and onScr then
            local b = getBox(root)
            b.Size         = root.Size + Vector3.new(0.1,0.1,0.1)
            b.Transparency = 0.25
            b.Color3       = Color3.fromRGB(255,0,0)
        elseif ESP.Cache.box[root] then
            ESP.Cache.box[root].Transparency = 1
        end

        -------------------------------- Chams -----------------------
        if ESP.Options.chams then
            local c = getCham(mdl)
            c.Enabled = true
            c.FillColor           = Color3.fromRGB(255,75,75)
            c.FillTransparency    = 0.15
            c.OutlineColor        = c.FillColor
            c.OutlineTransparency = 0.1
        elseif ESP.Cache.cham[mdl] then
            ESP.Cache.cham[mdl].Enabled = false
        end

        -- VisCheck only when needed & on-screen
        local visible = true
        if ESP.Options.vischeck and onScr then
            visible = lineOfSight(root)
        end

        if DRAWING_OK then
            ---------------------------- Tracer ----------------------
            if ESP.Options.tracers then
                local tr = getDraw(ESP.Cache.tracer, mdl, "Line")
                tr.Visible = true
                tr.Thickness = 1.5
                tr.Color = visible and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,255,0)
                
                -- Clamp endpoint to screen edge if off-screen
                local endPos = Vector2.new(scr.X, scr.Y)
                if not onScr then
                    endPos.X = math.clamp(endPos.X, 0, vp.X)
                    endPos.Y = math.clamp(endPos.Y, 0, vp.Y)
                end
                tr.From, tr.To = tracerOrigin, endPos
            else
                hide(ESP.Cache.tracer, mdl)
            end

            --------------------------- Distance ---------------------
            if ESP.Options.distance and onScr then
                local lb = getDraw(ESP.Cache.label, mdl, "Text")
                lb.Visible, lb.Center, lb.Outline, lb.Size = true, true, true, 14
                lb.Color  = Color3.new(1,1,1)
                lb.Text   = ("%.0f"):format(dist)
                lb.Position = Vector2.new(scr.X, scr.Y - 16)
            else
                hide(ESP.Cache.label, mdl)
            end

            ---------------------------- Health ----------------------
            if ESP.Options.health and onScr then
                local hum = mdl:FindFirstChildOfClass("Humanoid")
                if hum then
                    local frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local hb   = getDraw(ESP.Cache.health, mdl, "Square")
                    hb.Visible, hb.Filled = true, true
                    hb.Size     = BAR_SIZE * Vector2.new(frac, 1)
                    hb.Position = Vector2.new(scr.X - BAR_SIZE.X/2, scr.Y + 12)
                    hb.Color    = hpColor(frac)
                end
            else
                hide(ESP.Cache.health, mdl)
            end
        end
    end
end)
