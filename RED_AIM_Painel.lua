-- RED AIM - Painel de Configurações com Abas (Roblox Studio)
-- Coloque este arquivo como um LocalScript em StarterPlayer > StarterPlayerScripts.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("RedAimGui")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "RedAimGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

-- Cores do Tema (Estilo da Imagem)
local RED = Color3.fromRGB(220, 20, 30)
local DARK_RED = Color3.fromRGB(120, 10, 15)
local BLACK = Color3.fromRGB(15, 15, 18)
local PANEL_BG = Color3.fromRGB(25, 25, 28)
local TAB_BG = Color3.fromRGB(35, 35, 40)
local WHITE = Color3.fromRGB(245, 245, 245)
local GRAY = Color3.fromRGB(160, 160, 165)

-- Tabela de estado global para salvar as opções ativas
getgenv().RedAimConfig = {
    -- Aimbot
    AimbotEnabled = false,
    ExibirFOV = false,
    WallCheck = false,
    TeamCheck = false,
    
    -- ESP
    EspEnabled = false,
    EspLinha = false,
    EspCaixa = false,
    EspVida = false,
    EspHighlight = false,
    EspEsqueleto = false,
}

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

-- Janela Principal
local main = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(450, 380),
    Position = UDim2.new(0.5, -225, 0.5, -190),
    BackgroundColor3 = PANEL_BG,
    BorderSizePixel = 0,
    Visible = true,
}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, main)
make("UIStroke", {Color = RED, Thickness = 1.5}, main)

-- Cabeçalho / Barra Superior
local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = DARK_RED,
    BorderSizePixel = 0,
}, main)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, header)

make("TextLabel", {
    Size = UDim2.new(1, -50, 1, 0),
    Position = UDim2.fromOffset(14, 0),
    BackgroundTransparency = 1,
    Text = "Slowly Sensi 1.108.X",
    TextColor3 = WHITE,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

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

-- Barra de Abas (Tabs)
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

-- Área de Conteúdo
local contentArea = make("Frame", {
    Size = UDim2.new(1, -20, 1, -94),
    Position = UDim2.fromOffset(10, 88),
    BackgroundTransparency = 1,
}, main)

local pages = {}
local tabButtons = {}
local tabNames = {"Aimbot", "Esp", "Diversos", "Info"}

local function createPage(name)
    local scroll = make("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = RED,
        BorderSizePixel = 0,
        Visible = false,
    }, contentArea)
    
    make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
    }, scroll)
    
    make("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
    }, scroll)
    
    pages[name] = scroll
    return scroll
end

for _, name in ipairs(tabNames) do
    createPage(name)
end

local function switchTab(selectedName)
    for name, page in pairs(pages) do
        page.Visible = (name == selectedName)
    end
    for name, btn in pairs(tabButtons) do
        if name == selectedName then
            btn.BackgroundColor3 = RED
            btn.TextColor3 = WHITE
        else
            btn.BackgroundColor3 = TAB_BG
            btn.TextColor3 = GRAY
        end
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
    
    btn.MouseButton1Click:Connect(function()
        switchTab(name)
    end)
    tabButtons[name] = btn
end

-- Função para criar Checkboxes idênticos aos da imagem
local function createCheckbox(parent, text, configKey, layoutOrder)
    local frame = make("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        LayoutOrder = layoutOrder or 0,
    }, parent)
    
    local box = make("TextButton", {
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.fromOffset(0, 3),
        BackgroundColor3 = getgenv().RedAimConfig[configKey] and RED or BLACK,
        Text = getgenv().RedAimConfig[configKey] and "✓" or "",
        TextColor3 = WHITE,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        BorderSizePixel = 0,
    }, frame)
    make("UICorner", {CornerRadius = UDim.new(0, 4)}, box)
    make("UIStroke", {Color = RED, Thickness = 1}, box)
    
    local lbl = make("TextButton", {
        Size = UDim2.new(1, -36, 1, 0),
        Position = UDim2.fromOffset(36, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = WHITE,
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)
    
    local function toggle()
        local newState = not getgenv().RedAimConfig[configKey]
        getgenv().RedAimConfig[configKey] = newState
        box.BackgroundColor3 = newState and RED or BLACK
        box.Text = newState and "✓" or ""
    end
    
    box.MouseButton1Click:Connect(toggle)
    lbl.MouseButton1Click:Connect(toggle)
    
    return frame
end

-- ==================== ABA AIMBOT ====================
local aimbotPage = pages["Aimbot"]
createCheckbox(aimbotPage, "Ativar Aimbot", "AimbotEnabled", 1)
createCheckbox(aimbotPage, "Exibir Circulo do FOV", "ExibirFOV", 2)
createCheckbox(aimbotPage, "Wall Check", "WallCheck", 3)
createCheckbox(aimbotPage, "Team Check", "TeamCheck", 4)

-- ==================== ABA ESP ====================
local espPage = pages["Esp"]
createCheckbox(espPage, "Ativar ESP", "EspEnabled", 1)
createCheckbox(espPage, "ESP Linha", "EspLinha", 2)
createCheckbox(espPage, "ESP Caixa", "EspCaixa", 3)
createCheckbox(espPage, "ESP Vida", "EspVida", 4)
createCheckbox(espPage, "ESP Highlight", "EspHighlight", 5)
createCheckbox(espPage, "ESP Esqueleto (R6/R15)", "EspEsqueleto", 6)

-- ==================== ABA DIVERSOS ====================
local diversosPage = pages["Diversos"]
make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 24),
    BackgroundTransparency = 1,
    Text = "Tecla para abrir/fechar: RightShift",
    TextColor3 = GRAY,
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, diversosPage)

-- ==================== ABA INFO ====================
local infoPage = pages["Info"]
make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    Text = "Interface RED AIM • Versão 1.108.X",
    TextColor3 = WHITE,
    Font = Enum.Font.GothamSemibold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, infoPage)

-- Seleciona a aba inicial
switchTab("Aimbot")

-- Eventos de Abrir/Fechar e Arrastar
local function togglePanel()
    main.Visible = not main.Visible
end
closeBtn.MouseButton1Click:Connect(togglePanel)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        togglePanel()
    end
end)

local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
