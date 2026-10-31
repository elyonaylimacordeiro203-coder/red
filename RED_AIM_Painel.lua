-- RED AIM - Painel Completo Otimizado & Sincronizado
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

local playerGui = localPlayer:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("RedAimGui")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "RedAimGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.Parent = playerGui

-- Círculo do FOV Fixo no Centro
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

-- Configurações Globais
getgenv().RedAimBind = Enum.KeyCode.Insert
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
    EspTeamCheck = false,
}

-- ==================== MOTOR DE LÓGICA (AIMBOT & ESP) ====================
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

    local data = {
        box = box,
        line = line,
        healthBar = healthBar,
        healthBackground = healthBackground,
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

-- Render Loop Ultra Rápido
RunService:BindToRenderStep("RedAimEngine", Enum.RenderPriority.Camera.Value + 1, function()
    -- 1. Controle Visual do FOV
    if getgenv().RedAimConfig.ExibirFOV then
        fovCircle.Visible = true
        local size = getgenv().RedAimConfig.FOVValue * 2
        fovCircle.Size = UDim2.fromOffset(size, size)
    else
        fovCircle.Visible = false
    end

    -- 2. Aimbot
    local config = getgenv().RedAimConfig
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

    -- 3. Motor ESP e Highlight Super Leve em Tempo Real
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            local char = p.Character
            local esp = getEsp(p)
            
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
                    else
                        esp.box.Visible = false
                        esp.line.Visible = false
                        esp.healthBackground.Visible = false
                        esp.healthBar.Visible = false
                    end
                end
            end
            
            if not shouldRender then
                esp.box.Visible = false
                esp.line.Visible = false
                esp.healthBackground.Visible = false
                esp.healthBar.Visible = false
                if activeHighlights[p] then
                    activeHighlights[p].Enabled = false
                end
            end
        end
    end
end)

-- ==================== INTERFACE GRÁFICA (UI) ====================
local themes = {
    {name = "Vermelho", main = Color3.fromRGB(220, 20, 30), dark = Color3.fromRGB(120, 10, 15)},
    {name = "Azul", main = Color3.fromRGB(20, 100, 220), dark = Color3.fromRGB(10, 50, 120)},
    {name = "Verde", main = Color3.fromRGB(20, 200, 50), dark = Color3.fromRGB(10, 100, 25)},
    {name = "Roxo", main = Color3.fromRGB(140, 30, 220), dark = Color3.fromRGB(70, 15, 120)}
}
local currentThemeIndex = 1
local currentTheme = themes[currentThemeIndex]

local BLACK = Color3.fromRGB(15, 15, 18)
local PANEL_BG = Color3.fromRGB(25, 25, 28)
local TAB_BG = Color3.fromRGB(35, 35, 40)
local WHITE = Color3.fromRGB(245, 245, 245)
local GRAY = Color3.fromRGB(160, 160, 165)
local CHECK_BG_OFF = Color3.fromRGB(45, 45, 50)
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
        btn.BackgroundColor3 = (name == selectedName) and currentTheme.main or TAB_BG
        btn.TextColor3 = (name == selectedName) and WHITE or GRAY
    end
end

for i, name in ipairs(tabNames) do
    local btn = make("TextButton", {
        Name = name .. "Tab",
        Size = UDim2.new(0.25, -5, 1, 0),
        BackgroundColor3 = TAB_BG,
        Text = name,
        TextColor3 = GRAY,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        BorderSizePixel = 0,
        LayoutOrder = i,
    }, tabBar)
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, btn)
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    tabButtons[name] = btn
end

local fovCheckboxUpdate = nil

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
    
    local lbl = make("TextButton", {
        Size = UDim2.new(1, -36, 1, 0), Position = UDim2.fromOffset(36, 0),
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

    if configKey == "ExibirFOV" then
        fovCheckboxUpdate = function(state)
            getgenv().RedAimConfig.ExibirFOV = state
            box.BackgroundColor3 = state and CHECK_BG_ON or CHECK_BG_OFF
            box.Text = state and "✓" or ""
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

    return frame
end

local sliderFills = {}
local function createLeveSmoothSlider(parent, layoutOrder)
    local frame = make("Frame", {Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, LayoutOrder = layoutOrder or 0}, parent)
    local sliderBg = make("Frame", {Size = UDim2.new(1, -130, 0, 26), Position = UDim2.fromOffset(0, 9), BackgroundColor3 = Color3.fromRGB(18, 18, 22), BorderSizePixel = 0}, frame)
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
    local sliderBg = make("Frame", {Size = UDim2.new(1, -110, 0, 26), Position = UDim2.fromOffset(0, 9), BackgroundColor3 = Color3.fromRGB(18, 18, 22), BorderSizePixel = 0}, frame)
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

-- Preenchendo as Abas
local aimbotPage = pages["Aimbot"]
createCheckbox(aimbotPage, "Ativar Aimbot", "AimbotEnabled", 1)
createTargetPartsSelector(aimbotPage, 2)
createAimModesSelector(aimbotPage, 3)
createLeveSmoothSlider(aimbotPage, 4) 
createCheckbox(aimbotPage, "Exibir Circulo do FOV", "ExibirFOV", 5)
createFovSlider(aimbotPage, 6)
createCheckbox(aimbotPage, "Wall Check", "WallCheck", 7)
createCheckbox(aimbotPage, "Team Check", "TeamCheck", 8)

local espPage = pages["Esp"]
createCheckbox(espPage, "Ativar ESP", "EspEnabled", 1)
createCheckbox(espPage, "ESP Linha", "EspLinha", 2)
createCheckbox(espPage, "ESP Caixa", "EspCaixa", 3)
createCheckbox(espPage, "ESP Vida", "EspVida", 4)
createCheckbox(espPage, "ESP Highlight", "EspHighlight", 5)
createCheckbox(espPage, "Team Check", "EspTeamCheck", 6)

local diversosPage = pages["Diversos"]
make("TextLabel", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Tecla para abrir / fechar painel:", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1}, diversosPage)

local bindButton = make("TextButton", {Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = CHECK_BG_OFF, Text = tostring(getgenv().RedAimBind.Name), TextColor3 = CHECK_GREEN, Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0, LayoutOrder = 2}, diversosPage)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, bindButton)
make("UIStroke", {Color = GRAY, Transparency = 0.5, Thickness = 1}, bindButton)

local bindingKey = false
bindButton.MouseButton1Click:Connect(function()
    bindingKey = true
    bindButton.Text = "Pressione qualquer tecla..."
    bindButton.TextColor3 = WHITE
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if bindingKey and input.UserInputType == Enum.UserInputType.Keyboard then
        getgenv().RedAimBind = input.KeyCode
        bindButton.Text = tostring(input.KeyCode.Name)
        bindButton.TextColor3 = CHECK_GREEN
        bindingKey = false
        return
    end
    if not processed and input.KeyCode == getgenv().RedAimBind then
        main.Visible = not main.Visible
    end
end)

make("TextLabel", {Size = UDim2.new(1, 0, 0, 10), BackgroundTransparency = 1, Text = "", LayoutOrder = 3}, diversosPage)
make("TextLabel", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Cor da interface", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 4}, diversosPage)

local themeButton = make("TextButton", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = CHECK_BG_OFF, Text = currentTheme.name, TextColor3 = currentTheme.main, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, BorderSizePixel = 0, LayoutOrder = 5}, diversosPage)
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
    for _, b in pairs(tabButtons) do if b.BackgroundColor3 ~= TAB_BG then b.BackgroundColor3 = currentTheme.main end end
end)

local infoPage = pages["Info"]
make("TextLabel", {Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = "Executor detetado:", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1}, infoPage)
make("TextLabel", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = tostring(identifyexecutor and identifyexecutor() or "Desconhecido"), TextColor3 = GRAY, Font = Enum.Font.GothamSemibold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2}, infoPage)

local rejoinButton = make("TextButton", {Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = CHECK_BG_OFF, Text = "Reentrar no Servidor (Rejoin)", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13, BorderSizePixel = 0, LayoutOrder = 3}, infoPage)
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
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

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
