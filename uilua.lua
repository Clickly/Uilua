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

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Clickly/Uilua/refs/heads/main/UiLOL.lua"))()

-- =============================================
-- Setup
-- =============================================

WindUI:SetNotificationLower(true)

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
