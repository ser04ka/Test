--[[
    Bee Swarm Simulator - Visual Click GUI
    Экзекьютер: Delta
    Версия: 4.1 (Фикс Session Honey, отступы, высота Stop Everything)
]]

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

local TWEEN_SPEED = 0.15
local tweenInfo = TweenInfo.new(TWEEN_SPEED, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- Глобальные переменные
local startTime = tick()
local initialHoney = nil  -- изменим: будем ждать, пока найдём статистику
local stopEverything = false

-- Функция поиска мёда по возможным путям
local function getHoneyValue()
    local player = LocalPlayer
    if not player then return 0 end
    -- Путь 1: leaderstats.Honey (стандартно)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local honey = leaderstats:FindFirstChild("Honey")
        if honey and honey:IsA("IntValue") or honey:IsA("DoubleValue") or honey:IsA("NumberValue") then
            return honey.Value
        end
    end
    -- Путь 2: Stats.Honey (иногда)
    local stats = player:FindFirstChild("Stats")
    if stats then
        local honey = stats:FindFirstChild("Honey")
        if honey and (honey:IsA("IntValue") or honey:IsA("DoubleValue") or honey:IsA("NumberValue")) then
            return honey.Value
        end
    end
    -- Путь 3: прямо в Player (редко)
    local honey = player:FindFirstChild("Honey")
    if honey and (honey:IsA("IntValue") or honey:IsA("DoubleValue") or honey:IsA("NumberValue")) then
        return honey.Value
    end
    return 0
end

-- Ожидание появления мёда для начального значения
spawn(function()
    while initialHoney == nil do
        local val = getHoneyValue()
        if val > 0 or LocalPlayer.Character then -- если персонаж загрузился и мед доступен
            initialHoney = val
            print("Initial Honey set to:", initialHoney)
        else
            task.wait(2) -- повторять каждые 2 секунды
        end
    end
end)

-- Форматирование времени
local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end

-- Создание GUI (весь предыдущий код до вкладок остаётся без изменений, я опущу его для краткости, 
-- но в финальном ответе будет полный скрипт)

-- ... весь код создания GUI (IconButton, MainFrame, TopBar, CloseButton, TabPanel, и т.д.) ...

-- Вкладка Home (обновлённая)
local HomePage = HomeTab.Page

-- Обёртка секции
local HomeSectionFrame = Instance.new("Frame")
HomeSectionFrame.Size = UDim2.new(1, -10, 0, 95)  -- временно, позже обновим
HomeSectionFrame.BackgroundTransparency = 1
HomeSectionFrame.LayoutOrder = 1
HomeSectionFrame.Parent = HomePage

-- Кнопка раскрытия с белой стрелкой
local HomeToggleBtn = Instance.new("TextButton")
HomeToggleBtn.Size = UDim2.new(1, 0, 0, 28)
HomeToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
HomeToggleBtn.BorderSizePixel = 0
HomeToggleBtn.Text = "  ▼  Home"
HomeToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HomeToggleBtn.TextSize = 13
HomeToggleBtn.Font = Enum.Font.GothamBold
HomeToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
HomeToggleBtn.AutoButtonColor = false
HomeToggleBtn.Parent = HomeSectionFrame

local ToggleBtnCorner = Instance.new("UICorner")
ToggleBtnCorner.CornerRadius = UDim.new(0, 6)
ToggleBtnCorner.Parent = HomeToggleBtn

-- Контейнер для содержимого (увеличенная высота, отступы)
local HomeContent = Instance.new("Frame")
HomeContent.Size = UDim2.new(1, 0, 0, 80)  -- было 65, стало 80 (хватит с запасом)
HomeContent.Position = UDim2.new(0, 0, 0, 32)
HomeContent.BackgroundTransparency = 1
HomeContent.ClipsDescendants = true  -- чтобы лишнее не вылезало
HomeContent.Parent = HomeSectionFrame

local ContentList = Instance.new("UIListLayout")
ContentList.Padding = UDim.new(0, 6)  -- увеличенный отступ
ContentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentList.SortOrder = Enum.SortOrder.LayoutOrder
ContentList.Parent = HomeContent

-- Uptime Label
local UptimeLabel = Instance.new("TextLabel")
UptimeLabel.Size = UDim2.new(1, 0, 0, 20)
UptimeLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
UptimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
UptimeLabel.Text = "Uptime: 00:00:00"
UptimeLabel.TextSize = 12
UptimeLabel.Font = Enum.Font.Gotham
UptimeLabel.Parent = HomeContent

local UptimeCorner = Instance.new("UICorner")
UptimeCorner.CornerRadius = UDim.new(0, 4)
UptimeCorner.Parent = UptimeLabel

-- Session Honey Label
local HoneyLabel = Instance.new("TextLabel")
HoneyLabel.Size = UDim2.new(1, 0, 0, 20)
HoneyLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
HoneyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
HoneyLabel.Text = "Session Honey: --"  -- пока не инициализирован
HoneyLabel.TextSize = 12
HoneyLabel.Font = Enum.Font.Gotham
HoneyLabel.Parent = HomeContent

local HoneyCorner = Instance.new("UICorner")
HoneyCorner.CornerRadius = UDim.new(0, 4)
HoneyCorner.Parent = HoneyLabel

-- Stop Everything Toggle
local StopFrame = Instance.new("Frame")
StopFrame.Size = UDim2.new(1, 0, 0, 22)
StopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
StopFrame.BorderSizePixel = 0
StopFrame.Parent = HomeContent

local StopFrameCorner = Instance.new("UICorner")
StopFrameCorner.CornerRadius = UDim.new(0, 4)
StopFrameCorner.Parent = StopFrame

local StopLabel = Instance.new("TextLabel")
StopLabel.Size = UDim2.new(0, 140, 0, 22)
StopLabel.BackgroundTransparency = 1
StopLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StopLabel.Text = "Stop Everything"
StopLabel.TextSize = 12
StopLabel.Font = Enum.Font.Gotham
StopLabel.TextXAlignment = Enum.TextXAlignment.Left
StopLabel.Parent = StopFrame

local StopButton = Instance.new("TextButton")
StopButton.Size = UDim2.new(0, 30, 0, 16)
StopButton.Position = UDim2.new(1, -38, 0.5, -8)
StopButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
StopButton.BorderSizePixel = 0
StopButton.Text = ""
StopButton.AutoButtonColor = false
StopButton.Parent = StopFrame

local StopBtnCorner = Instance.new("UICorner")
StopBtnCorner.CornerRadius = UDim.new(1, 0)
StopBtnCorner.Parent = StopButton

local StopCircle = Instance.new("Frame")
StopCircle.Size = UDim2.new(0, 10, 0, 10)
StopCircle.Position = UDim2.new(0, 2, 0.5, -5)
StopCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
StopCircle.BorderSizePixel = 0
StopCircle.Parent = StopButton

local StopCircleCorner = Instance.new("UICorner")
StopCircleCorner.CornerRadius = UDim.new(1, 0)
StopCircleCorner.Parent = StopCircle

-- Состояние раскрытия
local homeSectionOpen = true

-- Функция обновления размера секции
local function updateHomeSectionSize()
    if homeSectionOpen then
        HomeContent.Visible = true
        -- Вычисляем реальную высоту контента
        local contentHeight = 0
        for _, child in ipairs(HomeContent:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then
                contentHeight = contentHeight + child.Size.Y.Offset
            end
        end
        -- Добавляем суммарный паддинг (между элементами)
        local padding = ContentList.Padding.Offset
        local itemCount = 0
        for _, child in ipairs(HomeContent:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then
                itemCount = itemCount + 1
            end
        end
        if itemCount > 1 then
            contentHeight = contentHeight + padding * (itemCount - 1)
        end
        HomeContent.Size = UDim2.new(1, 0, 0, contentHeight)
        HomeSectionFrame.Size = UDim2.new(1, -10, 0, 28 + contentHeight)
    else
        HomeContent.Visible = false
        HomeSectionFrame.Size = UDim2.new(1, -10, 0, 28)
    end
    UpdateCanvasSize()
end

-- Вызов после создания всех элементов
updateHomeSectionSize()

-- Клик по кнопке раскрытия
HomeToggleBtn.MouseButton1Click:Connect(function()
    homeSectionOpen = not homeSectionOpen
    HomeToggleBtn.Text = homeSectionOpen and "  ▼  Home" or "  ▶  Home"
    updateHomeSectionSize()
end)

-- Stop Everything переключение
local stopEverythingEnabled = false
StopButton.MouseButton1Click:Connect(function()
    stopEverythingEnabled = not stopEverythingEnabled
    if stopEverythingEnabled then
        TweenService:Create(StopButton, tweenInfo, {BackgroundColor3 = Color3.fromRGB(255, 80, 80)}):Play()
        TweenService:Create(StopCircle, tweenInfo, {Position = UDim2.new(1, -12, 0.5, -5)}):Play()
    else
        TweenService:Create(StopButton, tweenInfo, {BackgroundColor3 = Color3.fromRGB(50, 50, 55)}):Play()
        TweenService:Create(StopCircle, tweenInfo, {Position = UDim2.new(0, 2, 0.5, -5)}):Play()
    end
    stopEverything = stopEverythingEnabled
end)

-- Обновление Uptime и Session Honey
spawn(function()
    while true do
        task.wait(1)
        local elapsed = tick() - startTime
        UptimeLabel.Text = "Uptime: " .. formatTime(elapsed)

        if initialHoney ~= nil then
            local currentHoney = getHoneyValue()
            local sessionHoney = math.max(0, currentHoney - initialHoney)
            HoneyLabel.Text = "Session Honey: " .. sessionHoney
        else
            HoneyLabel.Text = "Session Honey: waiting..."
        end
    end
end)

-- Регистрируем HomeSectionFrame в элементах таба для скролла
table.insert(HomeTab.Elements, HomeSectionFrame)

-- ... (остальной код, Drag, выбор табов, иконка и т.д.) ...
