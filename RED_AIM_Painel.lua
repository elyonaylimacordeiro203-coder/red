-- RED AIM - Painel de configurações (Roblox Studio)
-- Coloque este arquivo como um LocalScript em StarterPlayer > StarterPlayerScripts.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

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

local RED = Color3.fromRGB(190, 20, 35)
local GREEN = Color3.fromRGB(35, 180, 55)
local DARK_RED = Color3.fromRGB(105, 8, 18)
local BLACK = Color3.fromRGB(13, 13, 16)
local PANEL = Color3.fromRGB(24, 24, 29)
local WHITE = Color3.fromRGB(245, 245, 245)
local GRAY = Color3.fromRGB(175, 175, 180)

-- Variável de estado global do Aimbot
getgenv().RedAimEnabled = false

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local main = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(430, 380),
    Position = UDim2.new(0.5, -215, 0.5, -190),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
    Visible = true,
}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 10)}, main)
make("UIStroke", {Color = RED, Thickness = 2}, main)

-- Faixas pretas decorativas nas laterais
make("Frame", {
    Name = "LeftStripe",
    Size = UDim2.new(0, 12, 1, -20),
    Position = UDim2.fromOffset(8, 10),
    BackgroundColor3 = BLACK,
    BorderSizePixel = 0,
}, main)
make("Frame", {
    Name = "RightStripe",
    Size = UDim2.new(0, 12, 1, -20),
    Position = UDim2.new(1, -20, 0, 10),
    BackgroundColor3 = BLACK,
    BorderSizePixel = 0,
}, main)

local header = make("Frame", {
    Size = UDim2.new(1, -40, 0, 54),
    Position = UDim2.fromOffset(20, 0),
    BackgroundColor3 = DARK_RED,
    BorderSizePixel = 0,
}, main)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, header)

make("TextLabel", {
    Size = UDim2.new(1, -60, 1, 0),
    Position = UDim2.fromOffset(16, 0),
    BackgroundTransparency = 1,
    Text = "RED AIM  |  CONFIGURAÇÕES",
    TextColor3 = WHITE,
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local close = make("TextButton", {
    Size = UDim2.fromOffset(34, 34),
    Position = UDim2.new(1, -43, 0, 10),
    BackgroundColor3 = BLACK,
    Text = "×",
    TextColor3 = WHITE,
    Font = Enum.Font.GothamBold,
    TextSize = 24,
    BorderSizePixel = 0,
}, header)
make("UICorner", {CornerRadius = UDim.new(0, 7)}, close)

-- Criando o ScrollingFrame para permitir rolar para baixo
local content = make("ScrollingFrame", {
    Size = UDim2.new(1, -64, 1, -72),
    Position = UDim2.fromOffset(32, 64),
    BackgroundTransparency = 1,
    CanvasSize = UDim2.new(0, 0, 0, 360),
    ScrollBarThickness = 6,
    ScrollBarImageColor3 = RED,
    BorderSizePixel = 0,
}, main)

local function label(text, y)
    return make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.fromOffset(0, y),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = WHITE,
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, content)
end

local function button(text, x, y, width)
    local b = make("TextButton", {
        Size = UDim2.fromOffset(width, 30),
        Position = UDim2.fromOffset(x, y),
        BackgroundColor3 = BLACK,
        Text = text,
        TextColor3 = WHITE,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        BorderSizePixel = 0,
        AutoButtonColor = true,
    }, content)
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, b)
    make("UIStroke", {Color = RED, Thickness = 1}, b)
    return b
end

-- Botão de Ativar/Desativar o Aimbot
label("Estado do Aimbot", 0)
local toggleAimButton = button("STATUS: DESLIGADO", 0, 26, 366)
toggleAimButton.BackgroundColor3 = RED

local function updateAimToggle()
    if getgenv().RedAimEnabled then
        toggleAimButton.Text = "STATUS: LIGADO"
        toggleAimButton.BackgroundColor3 = GREEN
    else
        toggleAimButton.Text = "STATUS: DESLIGADO"
        toggleAimButton.BackgroundColor3 = RED
    end
end

toggleAimButton.MouseButton1Click:Connect(function()
    getgenv().RedAimEnabled = not getgenv().RedAimEnabled
    updateAimToggle()
end)

label("Parte selecionada", 68)
local selectedPart = "Cabeça"
local partButton = button("Cabeça", 0, 94, 112)
local bodyButton = button("Corpo", 120, 94, 112)
local customButton = button("Personalizado", 240, 94, 126)

local function updatePartButtons()
    partButton.BackgroundColor3 = selectedPart == "Cabeça" and RED or BLACK
    bodyButton.BackgroundColor3 = selectedPart == "Corpo" and RED or BLACK
    customButton.BackgroundColor3 = selectedPart == "Personalizado" and RED or BLACK
end
partButton.MouseButton1Click:Connect(function()
    selectedPart = "Cabeça"
    updatePartButtons()
end)
bodyButton.MouseButton1Click:Connect(function()
    selectedPart = "Corpo"
    updatePartButtons()
end)
customButton.MouseButton1Click:Connect(function()
    selectedPart = "Personalizado"
    updatePartButtons()
end)

label("Perfil de assistência", 136)
local selectedMode = "Leve"
local modeHacker = button("Hacker", 0, 162, 112)
local modeFast = button("Rápido", 120, 162, 112)
local modeLight = button("Leve", 240, 162, 126)

local function updateModeButtons()
    modeHacker.BackgroundColor3 = selectedMode == "Hacker" and RED or BLACK
    modeFast.BackgroundColor3 = selectedMode == "Rápido" and RED or BLACK
    modeLight.BackgroundColor3 = selectedMode == "Leve" and RED or BLACK
end
modeHacker.MouseButton1Click:Connect(function()
    selectedMode = "Hacker"
    updateModeButtons()
end)
modeFast.MouseButton1Click:Connect(function()
    selectedMode = "Rápido"
    updateModeButtons()
end)
modeLight.MouseButton1Click:Connect(function()
    selectedMode = "Leve"
    updateModeButtons()
end)

-- Slider do Campo de Visão (FOV)
local fovValue = 100
local fovTitle = label("Campo de visão (FOV): 100°", 204)

local sliderBack = make("Frame", {
    Size = UDim2.new(1, 0, 0, 8),
    Position = UDim2.fromOffset(0, 236),
    BackgroundColor3 = BLACK,
    BorderSizePixel = 0,
}, content)
make("UICorner", {CornerRadius = UDim.new(1, 0)}, sliderBack)

local sliderFill = make("Frame", {
    Size = UDim2.new((fovValue - 10) / 240, 0, 1, 0),
    BackgroundColor3 = RED,
    BorderSizePixel = 0,
}, sliderBack)
make("UICorner", {CornerRadius = UDim.new(1, 0)}, sliderFill)

local knob = make("Frame", {
    Size = UDim2.fromOffset(16, 16),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new((fovValue - 10) / 240, 0, 0.5, 0),
    BackgroundColor3 = WHITE,
    BorderSizePixel = 0,
}, sliderBack)
make("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)

local dragging = false
local function setFovFromX(x)
    local pct = math.clamp((x - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
    fovValue = math.floor(10 + pct * 240 + 0.5)
    local normalized = (fovValue - 10) / 240
    sliderFill.Size = UDim2.new(normalized, 0, 1, 0)
    knob.Position = UDim2.new(normalized, 0, 0.5, 0)
    fovTitle.Text = "Campo de visão (FOV): " .. fovValue .. "°"
end

sliderBack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        setFovFromX(input.Position.X)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        setFovFromX(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

label("Tecla para abrir/fechar o painel", 258)
local openKey = Enum.KeyCode.RightShift
local keyButton = button("RightShift", 0, 284, 150)
local keyChoices = {Enum.KeyCode.RightShift, Enum.KeyCode.Insert, Enum.KeyCode.F4, Enum.KeyCode.F6, Enum.KeyCode.Home}
local keyIndex = 1
keyButton.MouseButton1Click:Connect(function()
    keyIndex = keyIndex % #keyChoices + 1
    openKey = keyChoices[keyIndex]
    keyButton.Text = openKey.Name
end)

local footer = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 28),
    Position = UDim2.fromOffset(0, 322),
    BackgroundTransparency = 1,
    Text = "Painel com Rolagem • FOV de 10° a 250°",
    TextColor3 = GRAY,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, content)

local function togglePanel()
    main.Visible = not main.Visible
end

close.MouseButton1Click:Connect(togglePanel)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == openKey then
        togglePanel()
    end
end)

-- Arrastar o painel pela barra superior.
local draggingPanel = false
local dragStart, startPosition
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingPanel = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingPanel and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingPanel = false
    end
end)

updatePartButtons()
updateModeButtons()
updateAimToggle()
