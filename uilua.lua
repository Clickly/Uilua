-- =============================================
--  Chick Chick Hub | Base UI Module (UI CC)
--  Created with WindUI by Footagesus
-- =============================================

local UIOptions = ...

if type(UIOptions) ~= "table" then
    UIOptions = {}
end

local WindowOptions = type(UIOptions.Window) == "table" and UIOptions.Window or {}

local function getOption(key, default)
    if UIOptions[key] ~= nil then
        return UIOptions[key]
    end

    if WindowOptions[key] ~= nil then
        return WindowOptions[key]
    end

    return default
end

local function mergeOptions(defaults, overrides)
    local result = {}

    for key, value in pairs(defaults) do
        result[key] = value
    end

    if type(overrides) == "table" then
        for key, value in pairs(overrides) do
            result[key] = value
        end
    end

    return result
end

local WindUI = loadstring(game:HttpGet("https://longong.xyz/UiLOL.lua"))()

-- =============================================
-- Setup
-- =============================================

WindUI:SetNotificationLower(true)

local Window = WindUI:CreateWindow({
    Title = getOption("Title", "Delex Hub"),
    Icon = getOption("Icon", "rbxassetid://97074562899662"),
    Author = getOption("Author", "Mine a Mountain"),
    Folder = getOption("Folder", "DelexMAM"),
    Size = getOption("Size", UDim2.fromOffset(580, 460)),
    Transparent = getOption("Transparent", true),
    Theme = getOption("Theme", "Midnight"),
    SideBarWidth = getOption("SideBarWidth", 200),
})

-- แนบ WindUI ไปกับ Window เพื่อให้สคริปต์อื่นเรียกใช้ได้
Window.WindUI = WindUI

-- =============================================
-- Tags (FPS & Ping)
-- =============================================

local MainTagOptions = UIOptions.Tag

if MainTagOptions == nil and UIOptions.TagTitle ~= nil then
    MainTagOptions = {
        Title = UIOptions.TagTitle,
    }
end

if MainTagOptions ~= false then
    Window:Tag(mergeOptions({
        Title = "Momo Mi",
        Icon = "star", -- optional
        Color = Color3.fromRGB(160, 196, 255), -- custom color
    }, MainTagOptions))
end

if type(UIOptions.Tags) == "table" then
    for _, tagOptions in ipairs(UIOptions.Tags) do
        if type(tagOptions) == "table" then
            Window:Tag(tagOptions)
        end
    end
end

local FPSTag = Window:Tag({
    Title = "FPS: 0",
    Color = Color3.fromRGB(100, 150, 255),
})

local _RunService = game:GetService("RunService")
local lastUpdate = tick()
local frameCount = 0

-- ป้องกัน Loop ซ้อนทับเวลารันสคริปต์หลายครั้ง
if _G._gag2_fpsLoop then _G._gag2_fpsLoop:Disconnect() end
_G._gag2_fpsLoop = _RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    
    if now - lastUpdate >= 1 then
        local fps = math.floor(frameCount / (now - lastUpdate))
        FPSTag:SetTitle("FPS: " .. fps)
        
        if fps >= 50 then
            FPSTag:SetColor(Color3.fromRGB(0, 255, 0)) -- Green
        elseif fps >= 30 then
            FPSTag:SetColor(Color3.fromRGB(255, 200, 0)) -- Yellow
        else
            FPSTag:SetColor(Color3.fromRGB(255, 0, 0)) -- Red
        end
        
        frameCount = 0
        lastUpdate = now
    end
end)

local PingTag = Window:Tag({
    Title = "Ping: 0ms",
    Color = Color3.fromRGB(100, 200, 255),
})

if _G._gag2_pingLoop then task.cancel(_G._gag2_pingLoop) end
_G._gag2_pingLoop = task.spawn(function()
    while true do
        local success, ping = pcall(function()
            local Stats = game:GetService("Stats")
            local pingValue = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            return math.floor(pingValue)
        end)
        
        if success and ping then
            PingTag:SetTitle("Ping: " .. ping .. "ms")
            
            if ping <= 50 then
                PingTag:SetColor(Color3.fromRGB(0, 255, 0)) -- Green
            elseif ping <= 100 then
                PingTag:SetColor(Color3.fromRGB(255, 200, 0)) -- Yellow
            elseif ping <= 200 then
                PingTag:SetColor(Color3.fromRGB(255, 150, 0)) -- Orange
            else
                PingTag:SetColor(Color3.fromRGB(255, 0, 0)) -- Red
            end
        end
        
        task.wait(2)
    end
end)

-- =============================================
-- ฟังก์ชัน Copy อัตโนมัติ รองรับทุก Executor
-- =============================================

local function copyToClipboard(text)
    if setclipboard then
        return pcall(setclipboard, text)
    elseif toclipboard then
        return pcall(toclipboard, text)
    else
        return false
    end
end

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace   = game:GetService("Workspace")
local Lighting    = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")

local PerformanceMode = {
    Enabled = false,
    Originals = {},
    Connections = {},
    RenderingQuality = nil,
    MeshPartDetailLevel = nil,
    SavedQuality = nil,
}

local function clearTable(target)
    if table.clear then
        table.clear(target)
    else
        for key in pairs(target) do
            target[key] = nil
        end
    end
end

local function disconnectPerformanceWatchers()
    for _, connection in ipairs(PerformanceMode.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    clearTable(PerformanceMode.Connections)
end

local function rememberProperty(instance, property)
    if typeof(instance) ~= "Instance" then
        return false
    end

    local ok, value = pcall(function()
        return instance[property]
    end)

    if not ok then
        return false
    end

    local stored = PerformanceMode.Originals[instance]
    if not stored then
        stored = {}
        PerformanceMode.Originals[instance] = stored
    end

    if stored[property] == nil then
        stored[property] = value
    end

    return true
end

local function setFastProperty(instance, property, value)
    if rememberProperty(instance, property) then
        pcall(function()
            instance[property] = value
        end)
    end
end

local function isLocalCharacterPart(instance)
    local character = LocalPlayer and LocalPlayer.Character
    return character and instance:IsDescendantOf(character)
end

local function isInstanceA(instance, className)
    local ok, result = pcall(function()
        return instance:IsA(className)
    end)

    return ok and result == true
end

local function optimizeVisualInstance(instance)
    if typeof(instance) ~= "Instance" then
        return
    end

    if isInstanceA(instance, "MeshPart") and not isLocalCharacterPart(instance) then
        setFastProperty(instance, "RenderFidelity", Enum.RenderFidelity.Performance)
        setFastProperty(instance, "CastShadow", false)
        setFastProperty(instance, "Reflectance", 0)
        setFastProperty(instance, "Material", Enum.Material.SmoothPlastic)
        setFastProperty(instance, "MaterialVariant", "")
    elseif isInstanceA(instance, "BasePart") and not isLocalCharacterPart(instance) then
        setFastProperty(instance, "CastShadow", false)
        setFastProperty(instance, "Reflectance", 0)
        setFastProperty(instance, "Material", Enum.Material.SmoothPlastic)
        setFastProperty(instance, "MaterialVariant", "")
    elseif isInstanceA(instance, "ParticleEmitter")
        or isInstanceA(instance, "Trail")
        or isInstanceA(instance, "Beam")
        or isInstanceA(instance, "Smoke")
        or isInstanceA(instance, "Fire")
        or isInstanceA(instance, "Sparkles") then
        if isInstanceA(instance, "ParticleEmitter") then
            setFastProperty(instance, "Rate", 0)
            pcall(function()
                instance:Clear()
            end)
        end
        setFastProperty(instance, "Enabled", false)
    elseif isInstanceA(instance, "Light") or isInstanceA(instance, "PostEffect") then
        setFastProperty(instance, "Enabled", false)
    elseif isInstanceA(instance, "Highlight") or isInstanceA(instance, "Clouds") then
        setFastProperty(instance, "Enabled", false)
    elseif isInstanceA(instance, "Atmosphere") then
        setFastProperty(instance, "Density", 0)
        setFastProperty(instance, "Haze", 0)
        setFastProperty(instance, "Glare", 0)
    elseif isInstanceA(instance, "Sky") then
        setFastProperty(instance, "CelestialBodiesShown", false)
        setFastProperty(instance, "StarCount", 0)
    elseif isInstanceA(instance, "SurfaceAppearance") then
        setFastProperty(instance, "ColorMap", "")
        setFastProperty(instance, "MetalnessMap", "")
        setFastProperty(instance, "NormalMap", "")
        setFastProperty(instance, "RoughnessMap", "")
    elseif isInstanceA(instance, "Decal") or isInstanceA(instance, "Texture") then
        setFastProperty(instance, "Transparency", 1)
    end
end

local function optimizeContainer(container)
    if typeof(container) ~= "Instance" then
        return
    end

    optimizeVisualInstance(container)

    local ok, descendants = pcall(function()
        return container:GetDescendants()
    end)

    if not ok or type(descendants) ~= "table" then
        return
    end

    for _, instance in ipairs(descendants) do
        optimizeVisualInstance(instance)
    end
end

local function setRenderingQuality(enabled)
    local okRendering, rendering = pcall(function()
        return settings().Rendering
    end)

    if okRendering and rendering then
        if enabled then
            if PerformanceMode.RenderingQuality == nil then
                pcall(function()
                    PerformanceMode.RenderingQuality = rendering.QualityLevel
                end)
            end

            pcall(function()
                rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
            if PerformanceMode.MeshPartDetailLevel == nil then
                pcall(function()
                    PerformanceMode.MeshPartDetailLevel = rendering.MeshPartDetailLevel
                end)
            end
            pcall(function()
                rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
            end)
        elseif PerformanceMode.RenderingQuality ~= nil then
            pcall(function()
                rendering.QualityLevel = PerformanceMode.RenderingQuality
            end)
            if PerformanceMode.MeshPartDetailLevel ~= nil then
                pcall(function()
                    rendering.MeshPartDetailLevel = PerformanceMode.MeshPartDetailLevel
                end)
            end
        end
    end

    local okSettings, gameSettings = pcall(function()
        return UserSettings():GetService("UserGameSettings")
    end)

    if okSettings and gameSettings then
        if enabled then
            if PerformanceMode.SavedQuality == nil then
                pcall(function()
                    PerformanceMode.SavedQuality = gameSettings.SavedQualityLevel
                end)
            end

            pcall(function()
                gameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
            end)
        elseif PerformanceMode.SavedQuality ~= nil then
            pcall(function()
                gameSettings.SavedQualityLevel = PerformanceMode.SavedQuality
            end)
        end
    end
end

local function applyPerformancePass()
    setFastProperty(Lighting, "GlobalShadows", false)
    setFastProperty(Lighting, "EnvironmentDiffuseScale", 0)
    setFastProperty(Lighting, "EnvironmentSpecularScale", 0)
    setFastProperty(Lighting, "Technology", Enum.Technology.Voxel)
    setFastProperty(Lighting, "Brightness", 1)
    setFastProperty(Lighting, "Ambient", Color3.fromRGB(90, 90, 90))
    setFastProperty(Lighting, "OutdoorAmbient", Color3.fromRGB(90, 90, 90))
    pcall(function()
        setFastProperty(Workspace, "RenderingCacheOptimizations", Enum.RenderingCacheOptimizationMode.Enabled)
    end)

    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        setFastProperty(terrain, "Decoration", false)
        setFastProperty(terrain, "WaterWaveSize", 0)
        setFastProperty(terrain, "WaterWaveSpeed", 0)
        setFastProperty(terrain, "WaterReflectance", 0)
        setFastProperty(terrain, "WaterTransparency", 1)
    end

    optimizeContainer(Workspace)
    optimizeContainer(Lighting)
end

local function restorePerformanceMode()
    disconnectPerformanceWatchers()
    setRenderingQuality(false)

    for instance, properties in pairs(PerformanceMode.Originals) do
        if typeof(instance) == "Instance" and instance.Parent ~= nil then
            for property, value in pairs(properties) do
                pcall(function()
                    instance[property] = value
                end)
            end
        end
    end

    clearTable(PerformanceMode.Originals)
    PerformanceMode.RenderingQuality = nil
    PerformanceMode.MeshPartDetailLevel = nil
    PerformanceMode.SavedQuality = nil
end

local function setPerformanceMode(enabled)
    enabled = enabled == true

    if enabled then
        PerformanceMode.Enabled = true
        setRenderingQuality(true)
        applyPerformancePass()
        disconnectPerformanceWatchers()

        table.insert(PerformanceMode.Connections, Workspace.DescendantAdded:Connect(function(instance)
            if PerformanceMode.Enabled then
                task.defer(optimizeVisualInstance, instance)
            end
        end))

        table.insert(PerformanceMode.Connections, Lighting.DescendantAdded:Connect(function(instance)
            if PerformanceMode.Enabled then
                task.defer(optimizeVisualInstance, instance)
            end
        end))
    else
        PerformanceMode.Enabled = false
        restorePerformanceMode()
    end

    return PerformanceMode.Enabled
end

Window.SetPerformanceMode = setPerformanceMode
Window.SetLowMode = setPerformanceMode

-- =============================================
-- ฟังก์ชันสำหรับสร้างแท็บพื้นฐาน (Misc & Settings)
-- =============================================
-- ให้ผู้ใช้เรียก Window:InitBaseTabs() ตอนท้ายสุดของสคริปต์
-- เพื่อให้แท็บพวกนี้ไปอยู่ด้านล่างสุดเสมอ

function Window:InitBaseTabs()
    local isWindowToggleAction = false

    local function toggleWindowVisibility()
        isWindowToggleAction = true

        if self.Instance then
            self.Instance.Enabled = not self.Instance.Enabled
        else
            pcall(function()
                self:Toggle()
            end)
        end

        task.defer(function()
            isWindowToggleAction = false
        end)
    end

    -- =============================================
    -- แท็ป : Misc
    -- =============================================

    local TabMisc = self:Tab({
        Title = "Misc",
        Desc = "System Support Player",
        Icon  = "wrench",
    })

    local LowOptions = type(UIOptions.Low) == "table" and UIOptions.Low or {}
    local SectionLow = TabMisc:Section({
        Title = LowOptions.SectionTitle or "Performance",
        Desc  = LowOptions.SectionDesc or "FPS boost and anti AFK",
        Icon  = LowOptions.SectionIcon or "gauge",
        Side  = LowOptions.Side or "left",
    })

    local function runLowMode(state, notifyUser)
        local enabled = setPerformanceMode(state == true)

        if type(LowOptions.Callback) == "function" then
            pcall(LowOptions.Callback, enabled)
        end

        if notifyUser then
            WindUI:Notify({
                Title = "FPS Boost",
                Content = enabled and "Performance mode applied" or "Graphics restored",
                Duration = 3,
                Icon = enabled and "gauge" or "rotate-ccw",
            })
        end
    end

    SectionLow:Toggle({
        Title       = LowOptions.Title or "FPS Boost",
        Description = LowOptions.Description or "Lower graphics, effects, shadows, textures, and terrain load",
        Icon        = LowOptions.Icon or "gauge",
        Value       = LowOptions.Value == true,
        Callback    = function(state)
            runLowMode(state == true, true)
        end,
    })

    SectionLow:Button({
        Title = "Apply FPS Boost",
        Desc = "Re-apply low graphics to current map objects",
        Icon = "zap",
        Callback = function()
            runLowMode(true, true)
        end,
    })

    SectionLow:Button({
        Title = "Restore Graphics",
        Desc = "Undo changes made by FPS Boost",
        Icon = "rotate-ccw",
        Callback = function()
            runLowMode(false, true)
        end,
    })

    local function getCurrentGameName()
        local ok, productInfo = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)

        if ok and type(productInfo) == "table" and productInfo.Name then
            return tostring(productInfo.Name)
        end

        return tostring(game.Name)
    end

    local currentJobId = tostring(game.JobId or "")
    local currentGameName = getCurrentGameName()
    local serverInfoText = table.concat({
        "Game Name: " .. currentGameName,
        "Game ID: " .. tostring(game.PlaceId),
        "Universe ID: " .. tostring(game.GameId),
        "Job ID: " .. (currentJobId ~= "" and currentJobId or "Unavailable"),
    }, "\n")

    local SectionServer = TabMisc:Section({
        Title = "Server Hop",
        Desc = "Join a server by its Job ID",
        Icon = "server",
        Side = "right",
    })

    SectionServer:Paragraph({
        Title = "Current Server",
        Desc = serverInfoText,
    })

    local requestedJobId = ""

    SectionServer:Input({
        Title = "Job ID",
        Desc = "Paste the Job ID of the server you want to join",
        Placeholder = "Enter Job ID",
        InputIcon = "key-round",
        Callback = function(value)
            requestedJobId = tostring(value or "")
        end,
    })

    SectionServer:Button({
        Title = "Join Server",
        Desc = "Teleport to the entered Job ID",
        Icon = "log-in",
        Callback = function()
            local jobId = requestedJobId:gsub("^%s*(.-)%s*$", "%1")

            if jobId == "" then
                WindUI:Notify({
                    Title = "Server Hop",
                    Content = "Please enter a Job ID first",
                    Duration = 4,
                    Icon = "alert-circle",
                })
                return
            end

            local ok, errorMessage = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
            end)

            if not ok then
                WindUI:Notify({
                    Title = "Server Hop Failed",
                    Content = tostring(errorMessage),
                    Duration = 5,
                    Icon = "alert-circle",
                })
            else
                WindUI:Notify({
                    Title = "Joining Server",
                    Content = "Teleport request sent",
                    Duration = 4,
                    Icon = "log-in",
                })
            end
        end,
    })

    SectionServer:Button({
        Title = "Copy Current Job ID",
        Desc = "Copy this server ID for sharing or joining",
        Icon = "copy",
        Callback = function()
            if currentJobId == "" then
                WindUI:Notify({
                    Title = "Server Hop",
                    Content = "Current Job ID is unavailable",
                    Duration = 4,
                    Icon = "alert-circle",
                })
                return
            end

            local copied = copyToClipboard(currentJobId)
            WindUI:Notify({
                Title = copied and "Copied!" or "Clipboard Unavailable",
                Content = copied and "Current Job ID copied to clipboard" or "Your executor does not support clipboard access",
                Duration = 4,
                Icon = copied and "clipboard-check" or "alert-circle",
            })
        end,
    })

    if LowOptions.Value == true then
        task.defer(function()
            runLowMode(true, false)
        end)
    end

    -- Advanced Anti-AFK (Auto Background)
    task.spawn(function()
        local VirtualUser = game:GetService("VirtualUser")
        
        if getconnections then
            for _, v in pairs(getconnections(LocalPlayer.Idled)) do
                if v["Disable"] then
                    v:Disable()
                elseif v["Disconnect"] then
                    v:Disconnect()
                end
            end
        end
        
        if _G._delexAntiAfkConnection then
            pcall(function()
                _G._delexAntiAfkConnection:Disconnect()
            end)
        end

        _G._delexAntiAfkConnection = LocalPlayer.Idled:Connect(function()
            pcall(function()
                local camera = workspace.CurrentCamera
                local cameraCFrame = camera and camera.CFrame or CFrame.new()
                VirtualUser:Button2Down(Vector2.new(0, 0), cameraCFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0, 0), cameraCFrame)
            end)
        end)
    end)

    -- =============================================
    -- แท็ป : Settings
    -- =============================================

    local TabSettings = self:Tab({
        Title = "Settings",
        Desc = "System Settings",
        Icon  = "settings",
    })

    -- Section: Contact
    local SectionInfo = TabSettings:Section({
        Title = "Contact",
        Desc  = "Roblox Script Executor",
        Icon  = "message-circle",
        Side  = "right",
    })

    SectionInfo:Image({
        Image = "rbxassetid://97074562899662",
        AspectRatio = "16:9",
        Radius = 12,
    })

    SectionInfo:Paragraph({
        Title   = "Delex Hub",
        Color   = Color3.fromRGB(251, 196, 3),
        Content = "Created By Ao Pro Free\nVersion: 2.0.0\nUI: WindUI by Footagesus",
    })

    SectionInfo:Button({
        Title   = "Discord",
        Justify = "Between",
        Desc    = "Join Discord",
        Color   = Color3.fromRGB(88, 101, 242),
        Icon    = "message-circle",
        Callback = function()
            local ok = copyToClipboard("https://discord.gg/CC4rfkErTe")
            if ok then
                WindUI:Notify({ Title = "Copied!", Content = "Discord link copied to clipboard", Duration = 4, Icon = "clipboard-check" })
            else
                WindUI:Notify({ Title = "Error",   Content = "Clipboard is not supported",      Duration = 4, Icon = "alert-circle" })
            end
        end,
    })

    SectionInfo:Button({
        Title   = "Facebook",
        Justify = "Between",
        Desc    = "Contact Facebook",
        Color   = Color3.fromRGB(24, 119, 242),
        Icon    = "share-2",
        Callback = function()
            local ok = copyToClipboard("https://www.facebook.com/share/1EWj44utjm/")
            if ok then
                WindUI:Notify({ Title = "Copied!", Content = "Facebook link copied to clipboard", Duration = 4, Icon = "clipboard-check" })
            else
                WindUI:Notify({ Title = "Error",   Content = "Clipboard is not supported",        Duration = 4, Icon = "alert-circle" })
            end
        end,
    })

    -- Section: Ui Setting
    local SectionConfig = TabSettings:Section({
        Title = "Ui setting",
        Icon  = "monitor",
        Side  = "left",
    })

    SectionConfig:Dropdown({
        Title       = "Theme",
        Description = "เลือก Theme ของ UI",
        Values      = {"Dark", "Light", "Midnight", "Amber", "Aqua", "Rose", "Plant", "Red", "Indigo", "Sky", "Violet", "Emerald", "Crimson", "Mellowsi", "Rianbow"},
        Default     = "Amber",
        Callback    = function(Value) WindUI:SetTheme(Value) end,
    })

    SectionConfig:Toggle({
        Title       = "Acrylic Background",
        Description = "เปิดใช้ Acrylic Blur",
        Icon = "layers",
        Value       = false,
        Callback    = function(State) WindUI:ToggleAcrylic(State) end,
    })

    SectionConfig:Keybind({
        Title           = "Toggle UI",
        Description     = "ปุ่มกด เปิด/ปิด UI",
        Default         = Enum.KeyCode.RightControl,
        Callback        = function()
            toggleWindowVisibility()
        end,
        ChangedCallback = function(key) end,
    })

    WindUI:Notify({
        Title   = "Delex Hub",
        Content = "Successfully loaded Script! Enjoy your time in Roblox.!",
        Duration = 5,
        Icon    = "rbxassetid://97074562899662",
    })

    -- =============================================
    -- Mobile Toggle Button
    -- =============================================
    local CoreGui = game:GetService("CoreGui")
    local PlayerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")

    local function removeOldToggle(parent)
        if not parent then
            return
        end

        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == "ChickChickToggle" or child.Name == "DelexToggle" then
                child:Destroy()
            end
        end
    end
    
    -- ลบอันเก่าถ้ามี (ป้องกันปุ่มทับซ้อนเวลารันใหม่)
    removeOldToggle(CoreGui)
    if gethui then
        removeOldToggle(gethui())
    end
    removeOldToggle(PlayerGui)

    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "DelexToggle"
    toggleGui.ResetOnSpawn = false

    if gethui then
        toggleGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(toggleGui)
        toggleGui.Parent = CoreGui
    else
        local ok = pcall(function() toggleGui.Parent = CoreGui end)
        if not ok then
            toggleGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        end
    end

    local toggleDestroyed = false
    local toggleConnections = {}

    local function trackConnection(signal, callback)
        local ok, connection = pcall(function()
            return signal:Connect(callback)
        end)

        if ok and connection then
            table.insert(toggleConnections, connection)
        end
    end

    local function destroyToggleGui()
        if toggleDestroyed then
            return
        end

        toggleDestroyed = true

        for _, connection in ipairs(toggleConnections) do
            pcall(function()
                connection:Disconnect()
            end)
        end

        pcall(function()
            toggleGui:Destroy()
        end)
    end

    self.ToggleGui = toggleGui
    self.DestroyToggleGui = destroyToggleGui

    local function wrapWindowMethod(methodName)
        local original = self[methodName]

        if type(original) ~= "function" then
            return
        end

        self[methodName] = function(windowSelf, ...)
            if windowSelf == self then
                destroyToggleGui()
            end

            return original(windowSelf, ...)
        end
    end

    local function getButtonText(object)
        local parts = {}

        local function collectText(target)
            local ok, value = pcall(function()
                return target.Text
            end)

            if ok and type(value) == "string" and value ~= "" then
                table.insert(parts, value:lower())
            end
        end

        collectText(object)

        for _, descendant in ipairs(object:GetDescendants()) do
            if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
                collectText(descendant)
            end
        end

        return table.concat(parts, " ")
    end

    local function isDestroyWindowButton(object)
        if not object or not object:IsA("GuiButton") then
            return false
        end

        local name = tostring(object.Name):lower()
        local text = getButtonText(object)

        return name:find("destroy", 1, true) ~= nil
            or name:find("unload", 1, true) ~= nil
            or text:find("close window", 1, true) ~= nil
            or text:find("destroy", 1, true) ~= nil
            or text:find("unload", 1, true) ~= nil
    end

    local hookedDestroyButtons = {}

    local function hookDestroyButton(object)
        if hookedDestroyButtons[object] or not isDestroyWindowButton(object) then
            return
        end

        hookedDestroyButtons[object] = true

        trackConnection(object.Activated, function()
            task.defer(destroyToggleGui)
        end)
    end

    wrapWindowMethod("Destroy")
    wrapWindowMethod("Remove")
    wrapWindowMethod("Unload")

    local previousOnDestroyCallback = rawget(self, "OnDestroyCallback")

    if type(self.OnDestroy) == "function" then
        pcall(function()
            self:OnDestroy(function(...)
                if type(previousOnDestroyCallback) == "function" then
                    pcall(previousOnDestroyCallback, ...)
                end

                task.defer(destroyToggleGui)
            end)
        end)
    end

    local function getWindowRoot()
        local elements = rawget(self, "UIElements")

        if type(elements) == "table" and typeof(elements.Main) == "Instance" then
            return elements.Main
        end

        if typeof(rawget(self, "Instance")) == "Instance" then
            return rawget(self, "Instance")
        end

        return nil
    end

    local windowRoot = getWindowRoot()

    if windowRoot then
        trackConnection(windowRoot.Destroying, destroyToggleGui)

        trackConnection(windowRoot.AncestryChanged, function(_, parent)
            if parent == nil then
                destroyToggleGui()
            end
        end)

        for _, object in ipairs(windowRoot:GetDescendants()) do
            hookDestroyButton(object)
        end

        trackConnection(windowRoot.DescendantAdded, hookDestroyButton)
    end

    local toggleBtn = Instance.new("ImageButton")
    toggleBtn.Name = "ToggleButton"
    toggleBtn.Parent = toggleGui
    toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    toggleBtn.BackgroundTransparency = 0.3
    toggleBtn.Position = UDim2.new(0, 20, 0, 20)
    toggleBtn.Size = UDim2.new(0, 50, 0, 50)
    toggleBtn.Image = "rbxassetid://97074562899662"

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = toggleBtn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.5
    stroke.Thickness = 1.5
    stroke.Parent = toggleBtn

    -- Dragging Logic
    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    trackConnection(toggleBtn.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = toggleBtn.Position
            
            trackConnection(input.Changed, function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    trackConnection(toggleBtn.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    trackConnection(game:GetService("UserInputService").InputChanged, function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    -- Click Logic
    local clickStart = 0
    trackConnection(toggleBtn.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            clickStart = tick()
        end
    end)

    trackConnection(toggleBtn.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if tick() - clickStart < 0.3 then -- If released quickly, count as click
                toggleWindowVisibility()
            end
        end
    end)

end

-- =============================================
-- Return โมดูล
-- =============================================

return Window
