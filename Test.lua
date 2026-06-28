--[[
    Bee Swarm Simulator - Красивый GUI v12.0
    • Панель вкладок слева с иконками
    • Единый стиль: неактивные — тёмные, активная — золотая
    • Работает на телефоне (Delta) через Activated
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local startTime = tick()
local currentSpeed = 16
local stopEverything = false

-- Удаляем старый GUI
pcall(function()
    if CoreGui:FindFirstChild("BeeSwarmGUI") then
        CoreGui.BeeSwarmGUI:Destroy()
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "BeeSwarmGUI"
gui.Parent = CoreGui

function formatTime(sec)
    local h = math.floor(sec/3600)
    local m = math.floor((sec%3600)/60)
    local s = math.floor(sec%60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

-- ====== ИКОНКА (пчёлка) ======
local icon = Instance.new("TextButton")
icon.Size = UDim2.new(0, 45, 0, 45)
icon.Position = UDim2.new(0.5, -22, 0.1, 0)
icon.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
icon.TextColor3 = Color3.fromRGB(255, 200, 60)
icon.Text = "🐝"
icon.TextSize = 24
icon.Font = Enum.Font.GothamBold
icon.AutoButtonColor = false
icon.Parent = gui
Instance.new("UIStroke", icon).Color = Color3.fromRGB(255, 180, 30)
Instance.new("UIStroke", icon).Thickness = 2
Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 14)

-- ====== ГЛАВНОЕ ОКНО ======
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 500, 0, 310)
main.Position = UDim2.new(0.5, -250, 0.5, -155)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
main.Visible = false
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 6)

-- Верхняя панель
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 35)
topBar.BackgroundColor3 = Color3.fromRGB(40, 35, 20)
topBar.Parent = main
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 6)

local goldLine = Instance.new("Frame")
goldLine.Size = UDim2.new(1, 0, 0, 2)
goldLine.Position = UDim2.new(0, 0, 1, 0)
goldLine.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
goldLine.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 300, 0, 25)
title.Position = UDim2.new(0, 50, 0.5, -12)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 200, 60)
title.Text = "🐝 Bee Swarm GUI"
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = topBar

-- Крестик
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
closeBtn.Text = ""
closeBtn.AutoButtonColor = false
closeBtn.Parent = topBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local l1 = Instance.new("Frame")
l1.Size = UDim2.new(0, 2, 0, 16)
l1.Position = UDim2.new(0.5, -1, 0.5, -8)
l1.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
l1.Rotation = 45
l1.Parent = closeBtn

local l2 = Instance.new("Frame")
l2.Size = UDim2.new(0, 2, 0, 16)
l2.Position = UDim2.new(0.5, -1, 0.5, -8)
l2.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
l2.Rotation = -45
l2.Parent = closeBtn

-- ====== БОКОВАЯ ПАНЕЛЬ (СЛЕВА) ======
local tabPanel = Instance.new("Frame")
tabPanel.Size = UDim2.new(0, 150, 1, -35)      -- ширина 150
tabPanel.Position = UDim2.new(0, 0, 0, 35)
tabPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
tabPanel.Parent = main

local tabList = Instance.new("UIListLayout")
tabList.Padding = UDim.new(0, 6)
tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabList.SortOrder = Enum.SortOrder.LayoutOrder
tabList.Parent = tabPanel

local div = Instance.new("Frame")
div.Size = UDim2.new(0, 1, 1, 0)
div.Position = UDim2.new(1, 0, 0, 0)
div.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
div.Parent = tabPanel

-- ====== КОНТЕНТ (СПРАВА ОТ ПАНЕЛИ) ======
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -150, 1, -35)
content.Position = UDim2.new(0, 150, 0, 35)
content.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
content.Parent = main

local contentList = Instance.new("UIListLayout")
contentList.Padding = UDim.new(0, 8)
contentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentList.Parent = content

-- ====== ЛОГИКА ВКЛАДОК ======
local tabs = {}
local activeTabButton = nil

local ACTIVE_BG = Color3.fromRGB(255, 200, 60)   -- золотой
local ACTIVE_TEXT = Color3.fromRGB(20, 20, 22)     -- тёмный текст
local INACTIVE_BG = Color3.fromRGB(25, 25, 28)
local INACTIVE_TEXT = Color3.fromRGB(200, 200, 210)

function createTab(name, iconChar)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 34)
    btn.BackgroundColor3 = INACTIVE_BG
    btn.TextColor3 = INACTIVE_TEXT
    btn.Text = "  " .. iconChar .. "   " .. name
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamSemibold
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.Parent = tabPanel
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local page = Instance.new("Frame")
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = content
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 6)
    page.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local data = { button = btn, page = page }

    btn.Activated:Connect(function()
        if activeTabButton then
            -- сброс предыдущей активной
            activeTabButton.BackgroundColor3 = INACTIVE_BG
            activeTabButton.TextColor3 = INACTIVE_TEXT
        end
        -- скрываем все страницы
        for _, t in ipairs(tabs) do
            t.page.Visible = false
        end
        page.Visible = true
        btn.BackgroundColor3 = ACTIVE_BG
        btn.TextColor3 = ACTIVE_TEXT
        activeTabButton = btn
    end)

    table.insert(tabs, data)
    return data
end

-- Создаём 6 вкладок с нужными иконками
local homeTab     = createTab("Home",     "⌂")   -- домик
local farmingTab  = createTab("Farming",  "❀")   -- цветок
local combatTab   = createTab("Combat",   "⚔")   -- мечи
local plantersTab = createTab("Planters", "🌱")   -- росток (эмодзи, но в стиле)
local toysTab     = createTab("Toys",     "🧸")   -- мишка
local settingsTab = createTab("Settings", "⚙")   -- шестерёнка

-- ====== HOME ======
local homeGroup = Instance.new("Frame")
homeGroup.Size = UDim2.new(1, -16, 0, 28)
homeGroup.BackgroundTransparency = 1
homeGroup.Parent = homeTab.page

local homeToggle = Instance.new("TextButton")
homeToggle.Size = UDim2.new(1, 0, 0, 28)
homeToggle.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
homeToggle.Text = "  ▼  Home"
homeToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
homeToggle.TextSize = 18
homeToggle.Font = Enum.Font.GothamBold
homeToggle.TextXAlignment = Enum.TextXAlignment.Left
homeToggle.AutoButtonColor = false
homeToggle.Parent = homeGroup
Instance.new("UICorner", homeToggle).CornerRadius = UDim.new(0, 6)

local homeContent = Instance.new("Frame")
homeContent.Size = UDim2.new(1, 0, 0, 56)
homeContent.Position = UDim2.new(0, 0, 0, 32)
homeContent.BackgroundTransparency = 1
homeContent.Visible = true
homeContent.Parent = homeGroup
local hList = Instance.new("UIListLayout")
hList.Padding = UDim.new(0, 6)
hList.HorizontalAlignment = Enum.HorizontalAlignment.Center
hList.Parent = homeContent

local uptimeLabel = Instance.new("TextLabel")
uptimeLabel.Size = UDim2.new(1, 0, 0, 20)
uptimeLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
uptimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
uptimeLabel.Text = "Uptime: 00:00:00"
uptimeLabel.TextSize = 12
uptimeLabel.Font = Enum.Font.Gotham
uptimeLabel.Parent = homeContent
Instance.new("UICorner", uptimeLabel).CornerRadius = UDim.new(0, 4)

local stopFrame = Instance.new("Frame")
stopFrame.Size = UDim2.new(1, 0, 0, 24)
stopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
stopFrame.Parent = homeContent
Instance.new("UICorner", stopFrame).CornerRadius = UDim.new(0, 4)

local stopLabel = Instance.new("TextLabel")
stopLabel.Size = UDim2.new(0, 140, 0, 24)
stopLabel.BackgroundTransparency = 1
stopLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
stopLabel.Text = "Stop Everything"
stopLabel.TextSize = 12
stopLabel.Font = Enum.Font.Gotham
stopLabel.Parent = stopFrame

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0, 32, 0, 18)
stopBtn.Position = UDim2.new(1, -38, 0.5, -9)
stopBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
stopBtn.Text = ""
stopBtn.AutoButtonColor = false
stopBtn.Parent = stopFrame
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(1, 0)

local stopDot = Instance.new("Frame")
stopDot.Size = UDim2.new(0, 12, 0, 12)
stopDot.Position = UDim2.new(0, 3, 0.5, -6)
stopDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
stopDot.Parent = stopBtn
Instance.new("UICorner", stopDot).CornerRadius = UDim.new(1, 0)

local homeOpen = true
homeToggle.Activated:Connect(function()
    homeOpen = not homeOpen
    homeToggle.Text = homeOpen and "  ▼  Home" or "  ▶  Home"
    homeContent.Visible = homeOpen
    homeGroup.Size = homeOpen and UDim2.new(1, -16, 0, 28+56) or UDim2.new(1, -16, 0, 28)
end)

local stopEnabled = false
stopBtn.Activated:Connect(function()
    stopEnabled = not stopEnabled
    if stopEnabled then
        TweenService:Create(stopBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 80, 80)}):Play()
        TweenService:Create(stopDot, TweenInfo.new(0.15), {Position = UDim2.new(1, -15, 0.5, -6)}):Play()
    else
        TweenService:Create(stopBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 55)}):Play()
        TweenService:Create(stopDot, TweenInfo.new(0.15), {Position = UDim2.new(0, 3, 0.5, -6)}):Play()
    end
    stopEverything = stopEnabled
end)

-- ====== SETTINGS: MOVESPEED ======
local speedGroup = Instance.new("Frame")
speedGroup.Size = UDim2.new(1, -16, 0, 60)
speedGroup.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
speedGroup.Parent = settingsTab.page
Instance.new("UICorner", speedGroup).CornerRadius = UDim.new(0, 8)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -16, 0, 22)
speedLabel.Position = UDim2.new(0, 8, 0, 4)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.Text = "Move Speed: 16"
speedLabel.TextSize = 13
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedGroup

local speedBar = Instance.new("TextButton")
speedBar.Size = UDim2.new(1, -16, 0, 14)
speedBar.Position = UDim2.new(0, 8, 0, 30)
speedBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
speedBar.Text = ""
speedBar.AutoButtonColor = false
speedBar.Parent = speedGroup
Instance.new("UICorner", speedBar).CornerRadius = UDim.new(0, 7)

local speedFill = Instance.new("Frame")
speedFill.Size = UDim2.new((16-1)/(40-1), 0, 1, 0)
speedFill.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
speedFill.Parent = speedBar
Instance.new("UICorner", speedFill).CornerRadius = UDim.new(0, 7)

local speedKnob = Instance.new("Frame")
speedKnob.Size = UDim2.new(0, 22, 0, 22)
speedKnob.Position = UDim2.new((16-1)/(40-1), -11, 0.5, -11)
speedKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
speedKnob.Parent = speedBar
Instance.new("UICorner", speedKnob).CornerRadius = UDim.new(1, 0)

-- ====== ПУСТЫЕ СТРАНИЦЫ ДЛЯ ОСТАЛЬНЫХ ВКЛАДОК ======
for _, tab in ipairs({farmingTab, combatTab, plantersTab, toysTab}) do
    local stub = Instance.new("TextLabel")
    stub.Size = UDim2.new(1, -16, 0, 40)
    stub.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
    stub.TextColor3 = Color3.fromRGB(200, 200, 200)
    stub.Text = "🚧 Coming Soon"
    stub.TextSize = 16
    stub.Font = Enum.Font.GothamMedium
    stub.Parent = tab.page
    Instance.new("UICorner", stub).CornerRadius = UDim.new(0, 6)
end

-- ====== ЛОГИКА СЛАЙДЕРА ======
local sliderActive = false
local function setSpeedFromX(x)
    local barX = speedBar.AbsolutePosition.X
    local barW = speedBar.AbsoluteSize.X
    if barW <= 0 then return end
    local rel = math.clamp((x - barX) / barW, 0, 1)
    local val = math.floor(1 + 39 * rel + 0.5)
    currentSpeed = val
    speedFill.Size = UDim2.new(rel, 0, 1, 0)
    speedKnob.Position = UDim2.new(rel, -11, 0.5, -11)
    speedLabel.Text = "Move Speed: " .. val
    if not stopEverything then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = val
        end
    end
end

speedBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderActive = true
        setSpeedFromX(input.Position.X)
    end
end)

UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
    if sliderActive then
        setSpeedFromX(touch.Position.X)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderActive = false
    end
end)

-- ====== ПЕРЕТАСКИВАНИЕ ОКНА ======
local windowActive = false
local winStartPos, winStartFrame

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        windowActive = true
        winStartPos = input.Position
        winStartFrame = main.Position
    end
end)

UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
    if windowActive then
        local delta = touch.Position - winStartPos
        main.Position = UDim2.new(winStartFrame.X.Scale, winStartFrame.X.Offset + delta.X,
            winStartFrame.Y.Scale, winStartFrame.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        windowActive = false
    end
end)

-- ====== ОТКРЫТИЕ / ЗАКРЫТИЕ ======
icon.Activated:Connect(function()
    main.Visible = true
    icon.Visible = false
end)

closeBtn.Activated:Connect(function()
    main.Visible = false
    icon.Visible = true
end)

-- ====== ИНИЦИАЛИЗАЦИЯ ======
-- Делаем Home активной по умолчанию
homeTab.button.BackgroundColor3 = ACTIVE_BG
homeTab.button.TextColor3 = ACTIVE_TEXT
homeTab.page.Visible = true
activeTabButton = homeTab.button

-- Обновление uptime
spawn(function()
    while true do
        wait(0.5)
        uptimeLabel.Text = "Uptime: " .. formatTime(tick() - startTime)
    end
end)

-- Автовосстановление скорости при респавне
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        wait(0.3)
        if not stopEverything then
            hum.WalkSpeed = currentSpeed
        end
    end
end)

print("✅ v12.0 – левая панель с иконками, всё работает на телефоне.")
