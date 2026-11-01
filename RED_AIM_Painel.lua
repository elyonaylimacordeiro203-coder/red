-- RED AIM - Script Completo, Otimizado e Anti-Loop de Notificações
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

local playerGui = localPlayer:WaitForChild("PlayerGui")

-- SISTEMA ANTI-DUPLICAÇÃO: Remove qualquer painel anterior antes de criar um novo
pcall(function()
    for _, guiObj in ipairs(playerGui:GetChildren()) do
        if guiObj.Name == "RedAimGui" then
            guiObj:Destroy()
        end
    end
    for _, guiObj in ipairs(CoreGui:GetChildren()) do
        if guiObj.Name == "RedAimGui" then
            guiObj:Destroy()
        end
    end
    if gethui then
        for _, guiObj in ipairs(gethui():GetChildren()) do
            if guiObj.Name == "RedAimGui" then
                guiObj:Destroy()
            end
        end
    end
end)

local targetParent = playerGui
pcall(function()
    if gethui then
        targetParent = gethui()
    else
        targetParent = CoreGui
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "RedAimGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.Parent = targetParent

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
    elseif protectgui then
        protectgui(gui)
    end
end)

local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.ZIndex = 999
fovCircle.Parent = gui

local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = 1.5
fovStroke.Color = Color3.fromRGB(220, 20, 30)
fovStroke.Parent = fovCircle

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

getgenv().RedAimBind = Enum.KeyCode.Insert
getgenv().WallCheckBind = Enum.KeyCode.Unknown 

getgenv().RedAimConfig = {
    AimbotEnabled = false,
    TargetPart = nil,     
    AimMode = nil,        
    ExibirFOV = false,
    FOVValue = 80,
    LeveSmoothValue = 3,  
    WallCheck = false,
    TeamCheck = false,
    EspEnabled = true,    
    EspLinha = false,
    EspCaixa = false,
    EspVida = false,
    EspHighlight = false, 
    EspName = false,      
    EspDistancia = false, 
    EspTeamCheck = false,
    OcultarStream = false,
}

getgenv().RedAimProfiles = getgenv().RedAimProfiles or {
    {name = "Perfil 1 (Vazio)", config = {}},
    {name = "Perfil 2 (Vazio)", config = {}},
    {name = "Perfil 3 (Vazio)", config = {}},
    {name = "Perfil 4 (Vazio)", config = {}},
    {name = "Perfil 5 (Vazio)", config = {}},
}

local profilesFileName = "RedAim_Profiles_v3.json"
local currentSelectedSlot = 1

local function saveAllProfiles()
    pcall(function()
        if writefile then
            local profilesToSave = {}
            for i, prof in ipairs(getgenv().RedAimProfiles) do
                local cfgCopy = {}
                for k, v in pairs(prof.config) do
                    cfgCopy[k] = v
                end
                if cfgCopy.WallCheckBindName then
                    cfgCopy.WallCheckBindName = tostring(cfgCopy.WallCheckBindName)
                end
                table.insert(profilesToSave, {name = prof.name, config = cfgCopy})
            end
            local data = HttpService:JSONEncode(profilesToSave)
            writefile(profilesFileName, data)
        end
    end)
end

local function loadAllProfiles()
    pcall(function()
        if readfile and isfile and isfile(profilesFileName) then
            local content = readfile(profilesFileName)
            local data = HttpService:JSONDecode(content)
            if type(data) == "table" then
                for i, prof in ipairs(data) do
                    if prof.config and prof.config.WallCheckBindName then
                        local keyName = prof.config.WallCheckBindName
                        pcall(function()
                            prof.config.WallCheckBindName = Enum.KeyCode[keyName]
                        end)
                    end
                end
                getgenv().RedAimProfiles = data
            end
        end
    end)
end

loadAllProfiles()

local activeEsp = {}
local activeHighlights = {}

local function cleanEsp(player)
    if activeEsp[player] then
        for _, obj in pairs(activeEsp[player]) do
            pcall(function() obj:Remove() end)
        end
        activeEsp[player] = nil
    end
    if activeHighlights[player] then
        pcall(function() activeHighlights[player]:Destroy() end)
        activeHighlights[player] = nil
    end
end

local function clearAllEspAndVisuals()
    for p, _ in pairs(activeEsp) do
        cleanEsp(p)
    end
    fovCircle.Visible = false
end

local function getEsp(player)
    if activeEsp[player] then return activeEsp[player] end
    
    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 1.5
    box.Filled = false
    box.Color = Color3.fromRGB(220, 20, 30)
    
    local line = Drawing.new("Line")
    line.Visible = false
    line.Thickness = 1
    line.Color = Color3.fromRGB(220, 20, 30)
    
    local healthBackground = Drawing.new("Line")
    healthBackground.Visible = false
    healthBackground.Thickness = 4
    healthBackground.Color = Color3.fromRGB(15, 15, 15)
    
    local healthBar = Drawing.new("Line")
    healthBar.Visible = false
    healthBar.Thickness = 2
    healthBar.Color = Color3.fromRGB(0, 255, 100)

    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Size = 11
    nameText.Center = true
    nameText.Outline = true
    nameText.Color = Color3.fromRGB(255, 255, 255)

    local distText = Drawing.new("Text")
    distText.Visible = false
    distText.Size = 11
    distText.Center = true
    distText.Outline = false 
    distText.Color = Color3.fromRGB(255, 255, 255)

    local data = {
        box = box,
        line = line,
        healthBar = healthBar,
        healthBackground = healthBackground,
        nameText = nameText,
        distText = distText,
    }

    activeEsp[player] = data
    return data
end

Players.PlayerRemoving:Connect(cleanEsp)

local function isValidTarget(targetPlayer)
    if not targetPlayer or targetPlayer == localPlayer then return false end
    local character = targetPlayer.Character
    if not character or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then return false end
    
    if getgenv().RedAimConfig.TeamCheck then
        if targetPlayer.Team and localPlayer.Team and targetPlayer.Team == localPlayer.Team then
            return false
        end
        if targetPlayer.TeamColor and localPlayer.TeamColor and targetPlayer.TeamColor == localPlayer.TeamColor then
            return false
        end
    end
    return true
end

local function isVisible(targetPart, targetChar)
    if not getgenv().RedAimConfig.WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {localPlayer.Character, targetChar}
    raycastParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    return result == nil
end

local function getClosestPlayerWithinFOV()
    local closest = nil
    local maxRadius = getgenv().RedAimConfig.FOVValue
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local shortestDist = maxRadius
    
    for _, p in ipairs(Players:GetPlayers()) do
        if isValidTarget(p) then
            local char = p.Character
            local targetPartName = getgenv().RedAimConfig.TargetPart
            if not targetPartName then return nil end
            
            local partName = (targetPartName == "Head") and "Head" or "HumanoidRootPart"
            local targetPart = char:FindFirstChild(partName)
            
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local target2D = Vector2.new(screenPos.X, screenPos.Y)
                    local dist = (target2D - centerScreen).Magnitude
                    
                    if dist <= shortestDist then
                        if isVisible(targetPart, char) then
                            closest = targetPart
                            shortestDist = dist
                        end
                    end
                end
            end
        end
    end
    return closest
end

RunService:BindToRenderStep("RedAimEngine", Enum.RenderPriority.Camera.Value + 1, function()
    local config = getgenv().RedAimConfig

    if config.ExibirFOV then
        fovCircle.Visible = true
        local size = config.FOVValue * 2
        fovCircle.Size = UDim2.fromOffset(size, size)
    else
        fovCircle.Visible = false
    end

    if config.AimbotEnabled and config.TargetPart and config.AimMode then
        local target = getClosestPlayerWithinFOV()
        if target then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            local mode = config.AimMode
            
            if mode == "Hacker" then
                Camera.CFrame = targetCFrame
            elseif mode == "Rapido" then
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 0.45)
            elseif mode == "Leve" then
                local smoothFactor = math.clamp(config.LeveSmoothValue, 1, 10) * 0.015
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothFactor)
            end
        end
    end

    local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            local char = p.Character
            local esp = getEsp(p)
            
            if char and char:FindFirstChild("Humanoid") then
                local hum = char.Humanoid
                hum.NameDisplayDistance = 0
                hum.HealthDisplayDistance = 0
                hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            end

            local shouldRender = false
            if config.EspEnabled and char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                local passTeam = true
                if config.EspTeamCheck and p.Team and localPlayer.Team and p.Team == localPlayer.Team then
                    passTeam = false
                end
                
                if passTeam then
                    shouldRender = true
                    local rootPart = char.HumanoidRootPart
                    local head = char.Head
                    local humanoid = char.Humanoid
                    
                    if config.EspHighlight then
                        local highlight = activeHighlights[p]
                        if not highlight or highlight.Parent ~= char then
                            if highlight then highlight:Destroy() end
                            highlight = Instance.new("Highlight")
                            highlight.Name = "RedAimHighlight"
                            highlight.Adornee = char
                            highlight.FillColor = Color3.fromRGB(220, 20, 30)
                            highlight.OutlineTransparency = 1 
                            highlight.FillTransparency = 0.8  
                            highlight.Parent = char
                            activeHighlights[p] = highlight
                        end
                        highlight.Enabled = true
                    else
                        if activeHighlights[p] then
                            activeHighlights[p].Enabled = false
                        end
                    end
                    
                    local rootPos, rootOnScreen = Camera:WorldToViewportPoint(rootPart.Position)
                    
                    if rootOnScreen then
                        local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                        local legPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
                        local height = math.abs(headPos.Y - legPos.Y)
                        local width = height / 2

                        if config.EspCaixa then
                            esp.box.Visible = true
                            esp.box.Size = Vector2.new(width, height)
                            esp.box.Position = Vector2.new(rootPos.X - width / 2, headPos.Y)
                        else
                            esp.box.Visible = false
                        end

                        if config.EspLinha then
                            esp.line.Visible = true
                            esp.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            esp.line.To = Vector2.new(rootPos.X, legPos.Y)
                        else
                            esp.line.Visible = false
                        end

                        if config.EspVida then
                            local hp = humanoid.Health
                            local maxHp = humanoid.MaxHealth > 0 and humanoid.MaxHealth or 100
                            local healthPercent = math.clamp(hp / maxHp, 0, 1)
                            
                            esp.healthBackground.Visible = true
                            esp.healthBackground.From = Vector2.new(rootPos.X - width / 2 - 6, legPos.Y)
                            esp.healthBackground.To = Vector2.new(rootPos.X - width / 2 - 6, headPos.Y)

                            esp.healthBar.Visible = true
                            esp.healthBar.From = Vector2.new(rootPos.X - width / 2 - 6, legPos.Y)
                            esp.healthBar.To = Vector2.new(rootPos.X - width / 2 - 6, legPos.Y - (height * healthPercent))

                            if healthPercent > 0.6 then
                                esp.healthBar.Color = Color3.fromRGB(0, 255, 100)
                            elseif healthPercent > 0.3 then
                                esp.healthBar.Color = Color3.fromRGB(255, 220, 0)
                            else
                                esp.healthBar.Color = Color3.fromRGB(255, 30, 30)
                            end
                        else
                            esp.healthBackground.Visible = false
                            esp.healthBar.Visible = false
                        end

                        local inRange = false
                        local metersDist = 0
                        if myRoot then
                            local distance = (myRoot.Position - rootPart.Position).Magnitude
                            metersDist = math.floor(distance * 0.28)
                            if metersDist <= 30 then
                                inRange = true
                            end
                        end

                        if config.EspName and inRange then
                            esp.nameText.Visible = true
                            esp.nameText.Text = p.Name .. " [" .. tostring(metersDist) .. "m]"
                            esp.nameText.Position = Vector2.new(rootPos.X, headPos.Y - 18)
                        else
                            esp.nameText.Visible = false
                        end

                        if config.EspDistancia and myRoot then
                            local studsDist = (myRoot.Position - rootPart.Position).Magnitude
                            local distMeters = math.floor(studsDist * 0.28)
                            esp.distText.Visible = true
                            esp.distText.Text = tostring(distMeters) .. "m"
                            esp.distText.Position = Vector2.new(rootPos.X, legPos.Y + 4)
                        else
                            esp.distText.Visible = false
                        end
                    else
                        esp.box.Visible = false
                        esp.line.Visible = false
                        esp.healthBackground.Visible = false
                        esp.healthBar.Visible = false
                        esp.nameText.Visible = false
                        esp.distText.Visible = false
                    end
                end
            end
            
            if not shouldRender then
                esp.box.Visible = false
                esp.line.Visible = false
                esp.healthBackground.Visible = false
                esp.healthBar.Visible = false
                esp.nameText.Visible = false
                esp.distText.Visible = false
                if activeHighlights[p] then
                    activeHighlights[p].Enabled = false
                end
            end
        end
    end
end)

local themes = {
    {name = "Vermelho", main = Color3.fromRGB(220, 20, 30), dark = Color3.fromRGB(80, 5, 10)},
    {name = "Azul", main = Color3.fromRGB(20, 100, 220), dark = Color3.fromRGB(5, 30, 80)},
    {name = "Verde", main = Color3.fromRGB(20, 200, 50), dark = Color3.fromRGB(5, 60, 15)},
    {name = "Roxo", main = Color3.fromRGB(140, 30, 220), dark = Color3.fromRGB(45, 10, 80)}
}
local currentThemeIndex = 1
local currentTheme = themes[currentThemeIndex]

local BLACK = Color3.fromRGB(0, 0, 0)
local PANEL_BG = Color3.fromRGB(0, 0, 0)
local TAB_BG = Color3.fromRGB(40, 40, 45)
local WHITE = Color3.fromRGB(245, 245, 245)
local GRAY = Color3.fromRGB(160, 160, 165)
local CHECK_BG_OFF = Color3.fromRGB(30, 30, 30)
local CHECK_BG_ON  = Color3.fromRGB(30, 70, 45)
local CHECK_GREEN  = Color3.fromRGB(40, 220, 90)

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local main = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(450, 480),
    Position = UDim2.new(0.5, -225, 0.5, -240),
    BackgroundColor3 = PANEL_BG,
    BorderSizePixel = 0,
    Visible = true,
}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, main)
local mainStroke = make("UIStroke", {Color = currentTheme.main, Thickness = 1.5}, main)

main.Size = UDim2.fromOffset(0, 0)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
local openTween = TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.fromOffset(450, 480),
    Position = UDim2.new(0.5, -225, 0.5, -240)
})
openTween:Play()

local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = currentTheme.dark,
    BorderSizePixel = 0,
}, main)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, header)

make("TextLabel", {
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1,
    Text = "criado por @og.limaxqw7",
    TextColor3 = WHITE,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local fpsLabel = make("TextLabel", {
    Size = UDim2.fromOffset(60, 28),
    Position = UDim2.new(1, -100, 0.5, -14),
    BackgroundTransparency = 1,
    Text = "FPS: 60",
    TextColor3 = WHITE,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Right,
}, header)

local lastUpdate, frameCount = 0, 0
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastUpdate >= 0.5 then
        fpsLabel.Text = "FPS: " .. math.floor(frameCount / (now - lastUpdate) + 0.5)
        frameCount, lastUpdate = 0, now
    end
end)

local closeBtn = make("TextButton", {
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.new(1, -34, 0.5, -14),
    BackgroundColor3 = BLACK,
    Text = "×",
    TextColor3 = WHITE,
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    BorderSizePixel = 0,
}, header)
make("UICorner", {CornerRadius = UDim.new(0, 5)}, closeBtn)

local tabBar = make("Frame", {
    Size = UDim2.new(1, -20, 0, 36),
    Position = UDim2.fromOffset(10, 48),
    BackgroundTransparency = 1,
}, main)

make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
}, tabBar)

local contentArea = make("Frame", {
    Size = UDim2.new(1, -20, 1, -94),
    Position = UDim2.fromOffset(10, 88),
    BackgroundTransparency = 1,
}, main)

local pages = {}
local tabButtons = {}
local tabNames = {"Aimbot", "Esp", "Diversos", "Info"}

for _, name in ipairs(tabNames) do
    local scroll = make("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = currentTheme.main,
        BorderSizePixel = 0,
        Visible = false,
    }, contentArea)
    make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)}, scroll)
    make("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)}, scroll)
    pages[name] = scroll
end

local function switchTab(selectedName)
    for name, page in pairs(pages) do page.Visible = (name == selectedName) end
    for name, btn in pairs(tabButtons) do
        local isSel = (name == selectedName)
        btn.BackgroundColor3 = isSel and currentTheme.main or TAB_BG
        btn.TextColor3 = isSel and WHITE or WHITE
        local stroke = btn:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = isSel and currentTheme.main or GRAY
            stroke.Transparency = isSel and 0 or 0.4
        end
    end
end

for i, name in ipairs(tabNames) do
    local btn = make("TextButton", {
        Name = name .. "Tab",
        Size = UDim2.new(0.25, -5, 1, 0),
        BackgroundColor3 = TAB_BG,
        Text = name,
        TextColor3 = WHITE,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        BorderSizePixel = 0,
        LayoutOrder = i,
    }, tabBar)
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, btn)
    make("UIStroke", {Color = GRAY, Transparency = 0.4, Thickness = 1}, btn)
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    tabButtons[name] = btn
end

local checkboxUpdaters = {}
local targetPartUpdaters = nil
local aimModeUpdaters = nil
local fovCheckboxUpdate = nil
local bindingWallCheckKey = false

local function createCheckbox(parent, text, configKey, layoutOrder)
    local frame = make("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = layoutOrder or 0}, parent)
    local isChecked = getgenv().RedAimConfig[configKey]
    
    local box = make("TextButton", {
        Size = UDim2.fromOffset(26, 26), Position = UDim2.fromOffset(0, 3),
        BackgroundColor3 = isChecked and CHECK_BG_ON or CHECK_BG_OFF,
        Text = isChecked and "✓" or "", TextColor3 = CHECK_GREEN,
        Font = Enum.Font.GothamBold, TextSize = 16, BorderSizePixel = 0,
    }, frame)
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, box)
    make("UIStroke", {Color = GRAY, Transparency = 0.5, Thickness = 1}, box)
    
    local lblWidth = (configKey == "WallCheck") and UDim2.new(1, -126, 1, 0) or UDim2.new(1, -36, 1, 0)
    local lbl = make("TextButton", {
        Size = lblWidth, Position = UDim2.fromOffset(36, 0),
        BackgroundTransparency = 1, Text = text, TextColor3 = WHITE,
        Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)
    
    local function toggle()
        local newState = not getgenv().RedAimConfig[configKey]
        getgenv().RedAimConfig[configKey] = newState
        box.BackgroundColor3 = newState and CHECK_BG_ON or CHECK_BG_OFF
        box.Text = newState and "✓" or ""

        if configKey == "AimbotEnabled" then
            getgenv().RedAimConfig.ExibirFOV = newState
            if fovCheckboxUpdate then
                fovCheckboxUpdate(newState)
            end
        end
    end

    box.MouseButton1Click:Connect(toggle)
    lbl.MouseButton1Click:Connect(toggle)

    checkboxUpdaters[configKey] = function(state)
        box.BackgroundColor3 = state and CHECK_BG_ON or CHECK_BG_OFF
        box.Text = state and "✓" or ""
    end

    if configKey == "ExibirFOV" then
        fovCheckboxUpdate = function(state)
            getgenv().RedAimConfig.ExibirFOV = state
            box.BackgroundColor3 = state and CHECK_BG_ON or CHECK_BG_OFF
            box.Text = state and "✓" or ""
        end
    end

    if configKey == "WallCheck" then
        local keybindBtn = make("TextButton", {
            Size = UDim2.fromOffset(80, 26),
            Position = UDim2.new(1, -80, 0, 3),
            BackgroundColor3 = CHECK_BG_OFF,
            Text = (getgenv().WallCheckBind == Enum.KeyCode.Unknown) and "[Tecla]" or "[" .. getgenv().WallCheckBind.Name .. "]",
            TextColor3 = (getgenv().WallCheckBind == Enum.KeyCode.Unknown) and GRAY or CHECK_GREEN,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            BorderSizePixel = 0,
        }, frame)
        make("UICorner", {CornerRadius = UDim.new(0, 6)}, keybindBtn)
        make("UIStroke", {Color = GRAY, Transparency = 0.5, Thickness = 1}, keybindBtn)

        keybindBtn.MouseButton1Click:Connect(function()
            bindingWallCheckKey = true
            keybindBtn.Text = "Pressione..."
            keybindBtn.TextColor3 = WHITE
        end)

        getgenv().UpdateWallCheckKeyText = function()
            if getgenv().WallCheckBind == Enum.KeyCode.Unknown then
                keybindBtn.Text = "[Tecla]"
                keybindBtn.TextColor3 = GRAY
            else
                keybindBtn.Text = "[" .. getgenv().WallCheckBind.Name .. "]"
                keybindBtn.TextColor3 = CHECK_GREEN
            end
        end
    end

    return frame
end

local function createTargetPartsSelector(parent, layoutOrder)
    local frame = make("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = layoutOrder or 0}, parent)

    local headBox = make("TextButton", {
        Size = UDim2.fromOffset(26, 26), Position = UDim2.fromOffset(0, 3),
        BackgroundColor3 = getgenv().RedAimConfig.TargetPart == "Head" and CHECK_BG_ON or CHECK_BG_OFF,
        Text = getgenv().RedAimConfig.TargetPart == "Head" and "✓" or "", TextColor3 = CHECK_GREEN,
        Font = Enum.Font.GothamBold, TextSize = 16, BorderSizePixel = 0,
    }, frame)
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, headBox)
    make("UIStroke", {Color = GRAY, Transparency = 0.5, Thickness = 1}, headBox)

    local headLbl = make("TextButton", {
        Size = UDim2.new(0.5, -40, 1, 0), Position = UDim2.fromOffset(36, 0),
        BackgroundTransparency = 1, Text = "Cabeça", TextColor3 = WHITE,
        Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local chestBox = make("TextButton", {
        Size = UDim2.fromOffset(26, 26), Position = UDim2.new(0.5, 0, 0, 3),
        BackgroundColor3 = getgenv().RedAimConfig.TargetPart == "Chest" and CHECK_BG_ON or CHECK_BG_OFF,
        Text = getgenv().RedAimConfig.TargetPart == "Chest" and "✓" or "", TextColor3 = CHECK_GREEN,
        Font = Enum.Font.GothamBold, TextSize = 16, BorderSizePixel = 0,
    }, frame)
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, chestBox)
    make("UIStroke", {Color = GRAY, Transparency = 0.5, Thickness = 1}, chestBox)

    local chestLbl = make("TextButton", {
        Size = UDim2.new(0.5, -40, 1, 0), Position = UDim2.new(0.5, 36, 0, 0),
        BackgroundTransparency = 1, Text = "Peito", TextColor3 = WHITE,
        Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local function selectPart(part)
        if getgenv().RedAimConfig.TargetPart == part then
            getgenv().RedAimConfig.TargetPart = nil 
        else
            getgenv().RedAimConfig.TargetPart = part
        end
        local current = getgenv().RedAimConfig.TargetPart
        
        headBox.BackgroundColor3 = (current == "Head") and CHECK_BG_ON or CHECK_BG_OFF
        headBox.Text = (current == "Head") and "✓" or ""
        chestBox.BackgroundColor3 = (current == "Chest") and CHECK_BG_ON or CHECK_BG_OFF
        chestBox.Text = (current == "Chest") and "✓" or ""
    end

    headBox.MouseButton1Click:Connect(function() selectPart("Head") end)
    headLbl.MouseButton1Click:Connect(function() selectPart("Head") end)
    chestBox.MouseButton1Click:Connect(function() selectPart("Chest") end)
    chestLbl.MouseButton1Click:Connect(function() selectPart("Chest") end)

    targetPartUpdaters = function(part)
        headBox.BackgroundColor3 = (part == "Head") and CHECK_BG_ON or CHECK_BG_OFF
        headBox.Text = (part == "Head") and "✓" or ""
        chestBox.BackgroundColor3 = (part == "Chest") and CHECK_BG_ON or CHECK_BG_OFF
        chestBox.Text = (part == "Chest") and "✓" or ""
    end

    return frame
end

local function createAimModesSelector(parent, layoutOrder)
    local frame = make("Frame", {Size = UDim2.new(1, 0, 0, 68), BackgroundTransparency = 1, LayoutOrder = layoutOrder or 0}, parent)

    local hackerBox = make("TextButton", {
        Size = UDim2.fromOffset(22, 22), Position = UDim2.fromOffset(0, 3),
        BackgroundColor3 = getgenv().RedAimConfig.AimMode == "Hacker" and CHECK_BG_ON or CHECK_BG_OFF,
        Text = getgenv().RedAimConfig.AimMode == "Hacker" and "✓" or "", TextColor3 = CHECK_GREEN,
        Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0,
    }, frame)
    make("UICorner", {CornerRadius = UDim.new(0, 5)}, hackerBox)
    make("UIStroke", {Color = GRAY, Transparency = 0.5, Thickness = 1}, hackerBox)

    local hackerLbl = make("TextButton", {
        Size = UDim2.new(0.5, -32, 0, 26), Position = UDim2.fromOffset(30, 0),
        BackgroundTransparency = 1, Text = "Aim Hacker", TextColor3 = WHITE,
        Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local rapidoBox = make("TextButton", {
        Size = UDim2.fromOffset(22, 22), Position = UDim2.new(0.5, 0, 0, 3),
        BackgroundColor3 = getgenv().RedAimConfig.AimMode == "Rapido" and CHECK_BG_ON or CHECK_BG_OFF,
        Text = getgenv().RedAimConfig.AimMode == "Rapido" and "✓" or "", TextColor3 = CHECK_GREEN,
        Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0,
    }, frame)
    make("UICorner", {CornerRadius = UDim.new(0, 5)}, rapidoBox)
    make("UIStroke", {Color = GRAY, Transparency = 0.5, Thickness = 1}, rapidoBox)

    local rapidoLbl = make("TextButton", {
        Size = UDim2.new(0.5, -32, 0, 26), Position = UDim2.new(0.5, 30, 0, 0),
        BackgroundTransparency = 1, Text = "Aim Rápido", TextColor3 = WHITE,
        Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local leveBox = make("TextButton", {
        Size = UDim2.fromOffset(22, 22), Position = UDim2.fromOffset(0, 36),
        BackgroundColor3 = getgenv().RedAimConfig.AimMode == "Leve" and CHECK_BG_ON or CHECK_BG_OFF,
        Text = getgenv().RedAimConfig.AimMode == "Leve" and "✓" or "", TextColor3 = CHECK_GREEN,
        Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0,
    }, frame)
    make("UICorner", {CornerRadius = UDim.new(0, 5)}, leveBox)
    make("UIStroke", {Color = GRAY, Transparency = 0.5, Thickness = 1}, leveBox)

    local leveLbl = make("TextButton", {
        Size = UDim2.new(1, -32, 0, 26), Position = UDim2.fromOffset(30, 33),
        BackgroundTransparency = 1, Text = "Aim Leve (Discreto / Legit)", TextColor3 = WHITE,
        Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local function selectMode(mode)
        if getgenv().RedAimConfig.AimMode == mode then
            getgenv().RedAimConfig.AimMode = nil 
        else
            getgenv().RedAimConfig.AimMode = mode
        end
        local current = getgenv().RedAimConfig.AimMode
        
        hackerBox.BackgroundColor3 = (current == "Hacker") and CHECK_BG_ON or CHECK_BG_OFF
        hackerBox.Text = (current == "Hacker") and "✓" or ""
        rapidoBox.BackgroundColor3 = (current == "Rapido") and CHECK_BG_ON or CHECK_BG_OFF
        rapidoBox.Text = (current == "Rapido") and "✓" or ""
        leveBox.BackgroundColor3 = (current == "Leve") and CHECK_BG_ON or CHECK_BG_OFF
        leveBox.Text = (current == "Leve") and "✓" or ""
    end

    hackerBox.MouseButton1Click:Connect(function() selectMode("Hacker") end)
    hackerLbl.MouseButton1Click:Connect(function() selectMode("Hacker") end)
    rapidoBox.MouseButton1Click:Connect(function() selectMode("Rapido") end)
    rapidoLbl.MouseButton1Click:Connect(function() selectMode("Rapido") end)
    leveBox.MouseButton1Click:Connect(function() selectMode("Leve") end)
    leveLbl.MouseButton1Click:Connect(function() selectMode("Leve") end)

    aimModeUpdaters = function(mode)
        hackerBox.BackgroundColor3 = (mode == "Hacker") and CHECK_BG_ON or CHECK_BG_OFF
        hackerBox.Text = (mode == "Hacker") and "✓" or ""
        rapidoBox.BackgroundColor3 = (mode == "Rapido") and CHECK_BG_ON or CHECK_BG_OFF
        rapidoBox.Text = (mode == "Rapido") and "✓" or ""
        leveBox.BackgroundColor3 = (mode == "Leve") and CHECK_BG_ON or CHECK_BG_OFF
        leveBox.Text = (mode == "Leve") and "✓" or ""
    end

    return frame
end

local sliderFills = {}
local function createLeveSmoothSlider(parent, layoutOrder)
    local frame = make("Frame", {Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, LayoutOrder = layoutOrder or 0}, parent)
    local sliderBg = make("Frame", {Size = UDim2.new(1, -130, 0, 26), Position = UDim2.fromOffset(0, 9), BackgroundColor3 = Color3.fromRGB(15, 15, 15), BorderSizePixel = 0}, frame)
    make("UICorner", {CornerRadius = UDim.new(0, 5)}, sliderBg)
    make("UIStroke", {Color = GRAY, Transparency = 0.7, Thickness = 1}, sliderBg)

    local currentVal = getgenv().RedAimConfig.LeveSmoothValue
    local handle = make("Frame", {
        Size = UDim2.fromOffset(16, 26), AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(math.clamp((currentVal - 1) / 9, 0, 1), 0, 0, 0),
        BackgroundColor3 = currentTheme.main, BorderSizePixel = 0,
    }, sliderBg)
    make("UICorner", {CornerRadius = UDim.new(0, 4)}, handle)
    table.insert(sliderFills, handle)

    local valLabel = make("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = tostring(currentVal), TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center}, sliderBg)
    make("TextLabel", {Size = UDim2.fromOffset(120, 26), Position = UDim2.new(1, -120, 0, 9), BackgroundTransparency = 1, Text = "Ajuste Aim Leve", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right}, frame)

    local dragging = false
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pct = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local newVal = math.floor(1 + pct * 9 + 0.5)
            getgenv().RedAimConfig.LeveSmoothValue = newVal
            handle.Position = UDim2.new(pct, 0, 0, 0)
            valLabel.Text = tostring(newVal)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    return frame
end

local function createFovSlider(parent, layoutOrder)
    local frame = make("Frame", {Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, LayoutOrder = layoutOrder or 0}, parent)
    local sliderBg = make("Frame", {Size = UDim2.new(1, -110, 0, 26), Position = UDim2.fromOffset(0, 9), BackgroundColor3 = Color3.fromRGB(15, 15, 15), BorderSizePixel = 0}, frame)
    make("UICorner", {CornerRadius = UDim.new(0, 5)}, sliderBg)
    make("UIStroke", {Color = GRAY, Transparency = 0.7, Thickness = 1}, sliderBg)

    local fovVal = getgenv().RedAimConfig.FOVValue
    local handle = make("Frame", {
        Size = UDim2.fromOffset(16, 26), AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(math.clamp((fovVal - 10) / 240, 0, 1), 0, 0, 0),
        BackgroundColor3 = currentTheme.main, BorderSizePixel = 0,
    }, sliderBg)
    make("UICorner", {CornerRadius = UDim.new(0, 4)}, handle)
    table.insert(sliderFills, handle)

    local valLabel = make("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = tostring(fovVal), TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center}, sliderBg)
    make("TextLabel", {Size = UDim2.fromOffset(100, 26), Position = UDim2.new(1, -100, 0, 9), BackgroundTransparency = 1, Text = "Regular FOV", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right}, frame)

    local dragging = false
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pct = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local newFov = math.floor(10 + pct * 240 + 0.5)
            getgenv().RedAimConfig.FOVValue = newFov
            handle.Position = UDim2.new(pct, 0, 0, 0)
            valLabel.Text = tostring(newFov)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    return frame
end

local aimbotPage = pages["Aimbot"]
createCheckbox(aimbotPage, "Ativar Aimbot", "AimbotEnabled", 1)
createTargetPartsSelector(aimbotPage, 2)
createAimModesSelector(aimbotPage, 3)
createCheckbox(aimbotPage, "Exibir Circulo do FOV", "ExibirFOV", 4)
createFovSlider(aimbotPage, 5)
createLeveSmoothSlider(aimbotPage, 6) 
createCheckbox(aimbotPage, "Wall Check", "WallCheck", 7)
createCheckbox(aimbotPage, "Team Check", "TeamCheck", 8)

local espPage = pages["Esp"]
createCheckbox(espPage, "Ativar ESP", "EspEnabled", 1)
createCheckbox(espPage, "ESP Linha", "EspLinha", 2)
createCheckbox(espPage, "ESP Caixa", "EspCaixa", 3)
createCheckbox(espPage, "ESP Vida", "EspVida", 4)
createCheckbox(espPage, "ESP Highlight", "EspHighlight", 5)
createCheckbox(espPage, "ESP Name", "EspName", 6)          
createCheckbox(espPage, "ESP Distância", "EspDistancia", 7)
createCheckbox(espPage, "Team Check", "EspTeamCheck", 8)

local diversosPage = pages["Diversos"]

make("TextLabel", {Size = UDim2.new(1, 0, 0, 10), BackgroundTransparency = 1, Text = "", LayoutOrder = 1}, diversosPage)
make("TextLabel", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Tecla para abrir / fechar painel:", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2}, diversosPage)

local bindButton = make("TextButton", {Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = CHECK_BG_OFF, Text = tostring(getgenv().RedAimBind.Name), TextColor3 = CHECK_GREEN, Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0, LayoutOrder = 3}, diversosPage)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, bindButton)
make("UIStroke", {Color = GRAY, Transparency = 0.5, Thickness = 1}, bindButton)

local bindingKey = false
bindButton.MouseButton1Click:Connect(function()
    bindingKey = true
    bindButton.Text = "Pressione qualquer tecla..."
    bindButton.TextColor3 = WHITE
end)

local activeWallCheckNotif = nil

-- Garante exclusividade: destrói imediatamente a notificação anterior antes de exibir a nova
local function showWallCheckNotification(state)
    if activeWallCheckNotif and activeWallCheckNotif.Parent then
        pcall(function()
            activeWallCheckNotif:Destroy()
        end)
    end

    local notif = make("Frame", {
        Size = UDim2.fromOffset(240, 46),
        Position = UDim2.new(0.5, -120, 0.75, 12),
        BackgroundColor3 = Color3.fromRGB(12, 12, 12),
        BorderSizePixel = 0,
        ZIndex = 999999,
    }, gui)
    activeWallCheckNotif = notif

    make("UICorner", {CornerRadius = UDim.new(0, 6)}, notif)
    make("UIStroke", {Color = state and CHECK_GREEN or Color3.fromRGB(220, 50, 50), Thickness = 1.2}, notif)

    make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.fromOffset(0, 4),
        BackgroundTransparency = 1,
        Text = state and "Wall Check: ATIVADO" or "Wall Check: DESATIVADO",
        TextColor3 = state and CHECK_GREEN or Color3.fromRGB(255, 90, 90),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 1000000,
    }, notif)

    make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.fromOffset(0, 22),
        BackgroundTransparency = 1,
        Text = state and "não puxando atras da parede" or "puxando atras da parede",
        TextColor3 = state and GRAY or WHITE,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 1000000,
    }, notif)

    notif.Size = UDim2.fromOffset(0, 0)
    notif.Position = UDim2.new(0.5, 0, 0.75, 35)
    
    local showTween = TweenService:Create(notif, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(240, 46),
        Position = UDim2.new(0.5, -120, 0.75, 12)
    })
    showTween:Play()

    task.delay(1.2, function()
        if activeWallCheckNotif == notif and notif.Parent then
            pcall(function()
                local hideTween = TweenService:Create(notif, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                    Size = UDim2.fromOffset(0, 0),
                    Position = UDim2.new(0.5, 0, 0.75, 35)
                })
                hideTween:Play()
                hideTween.Completed:Wait()
                if activeWallCheckNotif == notif then
                    activeWallCheckNotif = nil
                end
                notif:Destroy()
            end)
        end
    end)
end

local activeMinifiedNotif = nil

local function showMinifiedNotification(bindName)
    if activeMinifiedNotif and activeMinifiedNotif.Parent then
        pcall(function()
            activeMinifiedNotif:Destroy()
        end)
    end

    local notif = make("Frame", {
        Size = UDim2.fromOffset(340, 60),
        Position = UDim2.new(0.5, -170, 0.75, 0),
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        BorderSizePixel = 0,
        ZIndex = 999999,
    }, gui)
    activeMinifiedNotif = notif

    make("UICorner", {CornerRadius = UDim.new(0, 8)}, notif)
    make("UIStroke", {Color = currentTheme.main, Thickness = 1.5}, notif)

    make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 0, 8),
        BackgroundTransparency = 1,
        Text = "Minimizado!",
        TextColor3 = currentTheme.main,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 1000000,
    }, notif)

    local lineContainer = make("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 32),
        BackgroundTransparency = 1,
        ZIndex = 1000000,
    }, notif)

    local part1 = "aperte "
    local keyText = bindName
    local part2 = " para abrir o painel"

    local font = Enum.Font.GothamBold
    local textSize = 11

    local t1Label = make("TextLabel", {
        BackgroundTransparency = 1,
        Text = part1,
        TextColor3 = WHITE,
        Font = font,
        TextSize = textSize,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 1000000,
    }, lineContainer)

    local keyLabel = make("TextLabel", {
        BackgroundTransparency = 1,
        Text = keyText,
        TextColor3 = CHECK_GREEN,
        Font = font,
        TextSize = textSize,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 1000000,
    }, lineContainer)

    local t2Label = make("TextLabel", {
        BackgroundTransparency = 1,
        Text = part2,
        TextColor3 = WHITE,
        Font = font,
        TextSize = textSize,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 1000000,
    }, lineContainer)

    RunService.RenderStepped:Wait()
    local totalWidth = t1Label.AbsoluteSize.X + keyLabel.AbsoluteSize.X + t2Label.AbsoluteSize.X

    local startX = (340 - totalWidth) / 2
    t1Label.Position = UDim2.new(0, startX, 0, 0)
    keyLabel.Position = UDim2.new(0, startX + t1Label.AbsoluteSize.X, 0, 0)
    t2Label.Position = UDim2.new(0, startX + t1Label.AbsoluteSize.X + keyLabel.AbsoluteSize.X, 0, 0)

    notif.Size = UDim2.fromOffset(0, 0)
    notif.Position = UDim2.new(0.5, 0, 0.75, 30)
    
    local showTween = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(340, 60),
        Position = UDim2.new(0.5, -170, 0.75, 0)
    })
    showTween:Play()

    task.delay(2.5, function()
        if activeMinifiedNotif == notif and notif.Parent then
            pcall(function()
                local hideTween = TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                    Size = UDim2.fromOffset(0, 0),
                    Position = UDim2.new(0.5, 0, 0.75, 30)
                })
                hideTween:Play()
                hideTween.Completed:Wait()
                if activeMinifiedNotif == notif then
                    activeMinifiedNotif = nil
                end
                notif:Destroy()
            end)
        end
    end)
end

local function showClosedNotification()
    local notif = make("Frame", {
        Size = UDim2.fromOffset(320, 50),
        Position = UDim2.new(0.5, -160, 0.75, 0),
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        BorderSizePixel = 0,
        ZIndex = 999999,
    }, gui)
    make("UICorner", {CornerRadius = UDim.new(0, 8)}, notif)
    make("UIStroke", {Color = CHECK_GREEN, Thickness = 1.5}, notif)

    make("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        Text = "Fechado com sucesso!",
        TextColor3 = CHECK_GREEN,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 1000000,
    }, notif)

    notif.Size = UDim2.fromOffset(0, 0)
    notif.Position = UDim2.new(0.5, 0, 0.75, 25)
    
    local showTween = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(320, 50),
        Position = UDim2.new(0.5, -160, 0.75, 0)
    })
    showTween:Play()

    task.delay(2.5, function()
        pcall(function()
            local hideTween = TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.fromOffset(0, 0),
                Position = UDim2.new(0.5, 0, 0.75, 25)
            })
            hideTween:Play()
            hideTween.Completed:Wait()
            notif:Destroy()
        end)
    end)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if bindingKey and input.UserInputType == Enum.UserInputType.Keyboard then
        getgenv().RedAimBind = input.KeyCode
        bindButton.Text = tostring(input.KeyCode.Name)
        bindButton.TextColor3 = CHECK_GREEN
        bindingKey = false
        return
    end

    if bindingWallCheckKey and input.UserInputType == Enum.UserInputType.Keyboard then
        getgenv().WallCheckBind = input.KeyCode
        if getgenv().UpdateWallCheckKeyText then
            getgenv().UpdateWallCheckKeyText()
        end
        bindingWallCheckKey = false
        return
    end

    if not processed and getgenv().WallCheckBind ~= Enum.KeyCode.Unknown and input.KeyCode == getgenv().WallCheckBind then
        getgenv().RedAimConfig.WallCheck = not getgenv().RedAimConfig.WallCheck
        if checkboxUpdaters["WallCheck"] then
            checkboxUpdaters["WallCheck"](getgenv().RedAimConfig.WallCheck)
        end
        showWallCheckNotification(getgenv().RedAimConfig.WallCheck)
    end

    if not processed and input.KeyCode == getgenv().RedAimBind then
        if main.Visible then
            local bindName = tostring(getgenv().RedAimBind.Name)
            local closeTween = TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.fromOffset(0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            })
            closeTween:Play()
            closeTween.Completed:Wait()
            main.Visible = false
            showMinifiedNotification(bindName)
        else
            main.Visible = true
            main.Size = UDim2.fromOffset(0, 0)
            main.Position = UDim2.new(0.5, 0, 0.5, 0)
            local openTween = TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(450, 480),
                Position = UDim2.new(0.5, -225, 0.5, -240)
            })
            openTween:Play()
        end
    end
end)

make("TextLabel", {Size = UDim2.new(1, 0, 0, 10), BackgroundTransparency = 1, Text = "", LayoutOrder = 4}, diversosPage)

local profileContainer = make("Frame", {
    Size = UDim2.new(1, 0, 0, 155),
    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
    BorderSizePixel = 0,
    LayoutOrder = 5,
}, diversosPage)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, profileContainer)
make("UIStroke", {Color = GRAY, Transparency = 0.7, Thickness = 1}, profileContainer)

make("TextLabel", {
    Size = UDim2.new(1, -20, 0, 26),
    Position = UDim2.fromOffset(10, 8),
    BackgroundTransparency = 1,
    Text = "Perfis de Configuração (Slots 1 a 5)",
    TextColor3 = WHITE,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, profileContainer)

local slotRow = make("Frame", {
    Size = UDim2.new(1, -20, 0, 32),
    Position = UDim2.fromOffset(10, 38),
    BackgroundTransparency = 1,
}, profileContainer)
make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)}, slotRow)

local slotButtons = {}
for i = 1, 5 do
    local sBtn = make("TextButton", {
        Size = UDim2.new(0.2, -5, 1, 0),
        BackgroundColor3 = (i == currentSelectedSlot) and Color3.fromRGB(35, 35, 45) or Color3.fromRGB(20, 20, 20),
        Text = tostring(i),
        TextColor3 = (i == currentSelectedSlot) and WHITE or GRAY,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        BorderSizePixel = 0,
        LayoutOrder = i,
    }, slotRow)
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, sBtn)
    make("UIStroke", {Color = (i == currentSelectedSlot) and currentTheme.main or GRAY, Transparency = (i == currentSelectedSlot) and 0 or 0.6, Thickness = 1}, sBtn)
    slotButtons[i] = sBtn
end

local profileNameBox = make("TextBox", {
    Size = UDim2.new(1, -20, 0, 32),
    Position = UDim2.fromOffset(10, 76),
    BackgroundColor3 = Color3.fromRGB(8, 8, 8),
    Text = getgenv().RedAimProfiles[currentSelectedSlot].name,
    TextColor3 = WHITE,
    PlaceholderText = "Nome do perfil...",
    PlaceholderColor3 = GRAY,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    ClearTextOnFocus = false,
    BorderSizePixel = 0,
}, profileContainer)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, profileNameBox)
make("UIStroke", {Color = GRAY, Transparency = 0.6, Thickness = 1}, profileContainer)

local actionRow = make("Frame", {
    Size = UDim2.new(1, -20, 0, 32),
    Position = UDim2.fromOffset(10, 114),
    BackgroundTransparency = 1,
}, profileContainer)
make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)}, actionRow)

local loadProfileBtn = make("TextButton", {
    Size = UDim2.new(0.33, -3, 1, 0),
    BackgroundColor3 = Color3.fromRGB(45, 45, 55),
    Text = "Carregar",
    TextColor3 = WHITE,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    BorderSizePixel = 0,
    LayoutOrder = 1,
}, actionRow)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, loadProfileBtn)
make("UIStroke", {Color = WHITE, Transparency = 0.3, Thickness = 1}, loadProfileBtn)

local resetProfileBtn = make("TextButton", {
    Size = UDim2.new(0.33, -3, 1, 0),
    BackgroundColor3 = Color3.fromRGB(45, 24, 24),
    Text = "Redefinir",
    TextColor3 = Color3.fromRGB(255, 90, 90),
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    BorderSizePixel = 0,
    LayoutOrder = 2,
}, actionRow)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, resetProfileBtn)
make("UIStroke", {Color = Color3.fromRGB(220, 50, 50), Transparency = 0.4, Thickness = 1}, resetProfileBtn)

local saveProfileBtn = make("TextButton", {
    Size = UDim2.new(0.33, -3, 1, 0),
    BackgroundColor3 = Color3.fromRGB(24, 45, 30),
    Text = "Salvar",
    TextColor3 = CHECK_GREEN,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    BorderSizePixel = 0,
    LayoutOrder = 3,
}, actionRow)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, saveProfileBtn)
make("UIStroke", {Color = CHECK_GREEN, Transparency = 0.4, Thickness = 1}, saveProfileBtn)

for i = 1, 5 do
    slotButtons[i].MouseButton1Click:Connect(function()
        currentSelectedSlot = i
        for idx, btn in ipairs(slotButtons) do
            local isSel = (idx == i)
            btn.BackgroundColor3 = isSel and Color3.fromRGB(35, 35, 45) or Color3.fromRGB(20, 20, 20)
            btn.TextColor3 = isSel and WHITE or GRAY
            local stroke = btn:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = isSel and currentTheme.main or GRAY
                stroke.Transparency = isSel and 0 or 0.6
            end
        end
        profileNameBox.Text = getgenv().RedAimProfiles[i].name
    end)
end

saveProfileBtn.MouseButton1Click:Connect(function()
    local nameInput = profileNameBox.Text
    if nameInput == "" then nameInput = "Perfil " .. tostring(currentSelectedSlot) end
    
    local configCopy = {}
    for k, v in pairs(getgenv().RedAimConfig) do
        configCopy[k] = v
    end
    configCopy.WallCheckBindName = (getgenv().WallCheckBind ~= Enum.KeyCode.Unknown) and getgenv().WallCheckBind.Name or "Unknown"
    
    getgenv().RedAimProfiles[currentSelectedSlot] = {
        name = nameInput,
        config = configCopy
    }
    
    saveAllProfiles()
    saveProfileBtn.Text = "Salvo!"
    task.wait(1.2)
    saveProfileBtn.Text = "Salvar"
end)

resetProfileBtn.MouseButton1Click:Connect(function()
    getgenv().RedAimProfiles[currentSelectedSlot] = {
        name = "Perfil " .. tostring(currentSelectedSlot) .. " (Vazio)",
        config = {}
    }
    profileNameBox.Text = getgenv().RedAimProfiles[currentSelectedSlot].name
    saveAllProfiles()
    
    resetProfileBtn.Text = "Redefinido!"
    task.wait(1.2)
    resetProfileBtn.Text = "Redefinir"
end)

loadProfileBtn.MouseButton1Click:Connect(function()
    local targetProfile = getgenv().RedAimProfiles[currentSelectedSlot]
    if targetProfile and targetProfile.config and next(targetProfile.config) ~= nil then
        for k, v in pairs(targetProfile.config) do
            if k ~= "WallCheckBindName" then
                getgenv().RedAimConfig[k] = v
                if checkboxUpdaters[k] then
                    checkboxUpdaters[k](v)
                end
            end
        end
        if targetProfile.config.WallCheckBindName then
            local kName = tostring(targetProfile.config.WallCheckBindName)
            pcall(function()
                getgenv().WallCheckBind = Enum.KeyCode[kName] or Enum.KeyCode.Unknown
            end)
        else
            getgenv().WallCheckBind = Enum.KeyCode.Unknown
        end
        if getgenv().UpdateWallCheckKeyText then
            getgenv().UpdateWallCheckKeyText()
        end
        if targetPartUpdaters then
            targetPartUpdaters(getgenv().RedAimConfig.TargetPart)
        end
        if aimModeUpdaters then
            aimModeUpdaters(getgenv().RedAimConfig.AimMode)
        end

        loadProfileBtn.Text = "Carregado!"
        task.wait(1.2)
        loadProfileBtn.Text = "Carregar"
    else
        loadProfileBtn.Text = "Vazio!"
        task.wait(1.2)
        loadProfileBtn.Text = "Carregar"
    end
end)

make("TextLabel", {Size = UDim2.new(1, 0, 0, 10), BackgroundTransparency = 1, Text = "", LayoutOrder = 6}, diversosPage)
make("TextLabel", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Cor da interface", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 7}, diversosPage)

local themeButton = make("TextButton", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = CHECK_BG_OFF, Text = currentTheme.name, TextColor3 = currentTheme.main, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, BorderSizePixel = 0, LayoutOrder = 8}, diversosPage)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, themeButton)
local themeStroke = make("UIStroke", {Color = GRAY, Transparency = 0.5, Thickness = 1}, themeButton)

themeButton.MouseButton1Click:Connect(function()
    currentThemeIndex = currentThemeIndex % #themes + 1
    currentTheme = themes[currentThemeIndex]
    mainStroke.Color = currentTheme.main
    header.BackgroundColor3 = currentTheme.dark
    themeButton.Text = currentTheme.name
    themeButton.TextColor3 = currentTheme.main
    fovStroke.Color = currentTheme.main
    for _, h in ipairs(sliderFills) do h.BackgroundColor3 = currentTheme.main end
    switchTab("Aimbot")
end)

local infoPage = pages["Info"]

local function createInfoCard(title, valueText, layoutOrder)
    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Color3.fromRGB(12, 12, 12),
        BorderSizePixel = 0,
        LayoutOrder = layoutOrder or 0,
    }, infoPage)
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, card)
    make("UIStroke", {Color = GRAY, Transparency = 0.7, Thickness = 1}, card)

    make("TextLabel", {
        Size = UDim2.new(1, -16, 0, 18),
        Position = UDim2.fromOffset(8, 6),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = GRAY,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    local valLbl = make("TextLabel", {
        Size = UDim2.new(1, -16, 0, 22),
        Position = UDim2.fromOffset(8, 24),
        BackgroundTransparency = 1,
        Text = valueText,
        TextColor3 = WHITE,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    return valLbl
end

local executorName = "Desconhecido"
pcall(function()
    if identifyexecutor then
        executorName = identifyexecutor()
    elseif getexecutorname then
        executorName = getexecutorname()
    elseif syn then
        executorName = "Synapse X"
    elseif KRNL_LOADED then
        executorName = "KRNL"
    elseif DeltaLoaded then
        executorName = "Delta"
    elseif Fluxus then
        executorName = "Fluxus"
    end
end)

local envCapabilities = {}
if writefile then table.insert(envCapabilities, "writefile") end
if readfile then table.insert(envCapabilities, "readfile") end
if getgenv then table.insert(envCapabilities, "getgenv") end
if drawingmanager or Drawing then table.insert(envCapabilities, "Drawing API") end
local execDetails = string.format("%s (%d funções suportadas)", executorName, #envCapabilities)

createInfoCard("EXECUTOR UTILIZADO", execDetails, 1)

local platformInfo = "Computador / Desktop"
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    platformInfo = "Dispositivo Móvel (Celular / Tablet Touch)"
elseif UserInputService.GamepadEnabled then
    platformInfo = "Console / Controle (Gamepad)"
end

local osDetails = "Plataforma Padrão Roblox"
pcall(function()
    if UserInputService:GetPlatform() == Enum.Platform.IOS then
        osDetails = "Apple iOS (iPhone / iPad)"
    elseif UserInputService:GetPlatform() == Enum.Platform.Android then
        osDetails = "Android OS"
    elseif UserInputService:GetPlatform() == Enum.Platform.Windows then
        osDetails = "Windows PC"
    elseif UserInputService:GetPlatform() == Enum.Platform.OSX then
        osDetails = "MacOS"
    end
end)

local fullDeviceDescription = string.format("%s | %s", platformInfo, osDetails)
createInfoCard("DISPOSITIVO DETECTADO", fullDeviceDescription, 2)

local playerDetails = string.format("User: %s (ID: %d)", localPlayer.Name, localPlayer.UserId)
createInfoCard("CONTA CONECTADA", playerDetails, 3)

local gameDetails = string.format("Place ID: %d | Job ID Ativo", game.PlaceId)
createInfoCard("INFORMAÇÕES DO SERVIDOR", gameDetails, 4)

local destroyPanelBtn = make("TextButton", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = Color3.fromRGB(50, 20, 20),
    Text = "FECHAR PAINEL DEFINITIVAMENTE",
    TextColor3 = Color3.fromRGB(255, 90, 90),
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    BorderSizePixel = 0,
    LayoutOrder = 5,
}, infoPage)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, destroyPanelBtn)
make("UIStroke", {Color = Color3.fromRGB(220, 50, 50), Transparency = 0.4, Thickness = 1}, destroyPanelBtn)

destroyPanelBtn.MouseButton1Click:Connect(function()
    getgenv().RedAimConfig.AimbotEnabled = false
    getgenv().RedAimConfig.EspEnabled = false
    getgenv().RedAimConfig.ExibirFOV = false
    clearAllEspAndVisuals()

    TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    main.Visible = false

    showClosedNotification()
    task.delay(3.2, function()
        pcall(function() 
            clearAllEspAndVisuals()
            gui:Destroy() 
        end)
    end)
end)

local rejoinButton = make("TextButton", {Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = CHECK_BG_OFF, Text = "Reentrar no Servidor (Rejoin)", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13, BorderSizePixel = 0, LayoutOrder = 6}, infoPage)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, rejoinButton)
make("UIStroke", {Color = GRAY, Transparency = 0.5, Thickness = 1}, rejoinButton)

rejoinButton.MouseButton1Click:Connect(function()
    pcall(function()
        if #Players:GetPlayers() <= 1 then
            TeleportService:Teleport(game.PlaceId, localPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
        end
    end)
end)

switchTab("Aimbot")

closeBtn.MouseButton1Click:Connect(function()
    local bindName = tostring(getgenv().RedAimBind.Name)
    
    local closeTween = TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    closeTween:Play()
    closeTween.Completed:Wait()
    main.Visible = false

    showMinifiedNotification(bindName)
end)

local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dragStart, startPos = true, input.Position, main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
