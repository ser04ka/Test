--[[
    Bee Swarm Simulator - Visual Click GUI
    Экзекьютер: Delta
    Версия: 5.1 (Умный захват мёда + слушатель изменений)
]]

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

local TWEEN_SPEED = 0.15
local tweenInfo = TweenInfo.new(TWEEN_SPEED, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local startTime = tick()
local initialHoney = nil
local stopEverything = false
local honeyElement = nil  -- ссылка на GUI с мёдом

-- Функция поиска элемента с мёдом (возвращает элемент или nil)
local function findHoneyElement()
    local player = LocalPlayer
    if not player then return nil end
    
    -- 1. Попробуем найти leaderstats (часто содержит IntValue)
    local leaderstats = player:FindFirstChild("leaderstats") or player:FindFirstChild("stats")
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            local name = stat.Name:lower()
            if name == "honey" or name == "honeyamount" or name == "honey total" then
                if stat:IsA("IntValue") or stat:IsA("DoubleValue") or stat:IsA("NumberValue") then
                    return stat  -- это не текст, но мы можем вернуть Value
                end
            end
        end
    end
    
    -- 2. Поиск в PlayerGui текстового элемента с "honey"
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, element in ipairs(playerGui:GetDescendants()) do
            if element:IsA("TextLabel") or element:IsA("TextButton") then
                local text = element.Text:lower()
                if text:find("honey") then
                    return element  -- сам элемент, будем слушать его .Text
                end
            end
        end
    end
    return nil
end

-- Извлечение числа из текста (ожидает "honey" рядом)
local function extractHoneyFromText(text)
    if not text then return nil end
    local lower = text:lower()
    if not lower:find("honey") then return nil end
    -- ищем число с запятыми
    local numStr = lower:match("([%d,]+)")
    if numStr then
        local cleaned = numStr:gsub(",", "")
        return tonumber(cleaned)
    end
    return nil
end

-- Получение текущего мёда (если элемент уже найден – читаем его текст или Value)
local function getCurrentHoney()
    if honeyElement then
        if honeyElement:IsA("IntValue") or honeyElement:IsA("DoubleValue") or honeyElement:IsA("NumberValue") then
            return honeyElement.Value
        elseif honeyElement:IsA("TextLabel") or honeyElement:IsA("TextButton") then
            return extractHoneyFromText(honeyElement.Text)
        end
    end
    return nil
end

-- Функция обновления Session Honey (вызывается при изменении мёда)
local function updateSessionHoney()
    local cur = getCurrentHoney()
    if cur then
        if initialHoney == nil then
            initialHoney = cur
        end
        local session = math.max(0, cur - initialHoney)
        HoneyLabel.Text = "Session Honey: " .. session
    else
        HoneyLabel.Text = "Session Honey: searching..."
    end
end

-- Инициализация поиска элемента (повторяем, пока не найдём)
spawn(function()
    while not honeyElement do
        honeyElement = findHoneyElement()
        if honeyElement then
            -- Если это текстовый элемент, вешаем слушатель изменений текста
            if honeyElement:IsA("TextLabel") or honeyElement:IsA("TextButton") then
                honeyElement:GetPropertyChangedSignal("Text"):Connect(function()
                    updateSessionHoney()
                end)
            elseif honeyElement:IsA("Instance") and honeyElement:FindFirstChild("Value") then
                -- для IntValue и т.п.
                honeyElement.Changed:Connect(function()
                    updateSessionHoney()
                end)
            end
            print("✅ Honey element found: " .. honeyElement:GetFullName())
        end
        task.wait(1)
    end
    -- Первое обновление после находки
    updateSessionHoney()
end)

-- Форматирование времени
local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end

-- ====== GUI ======
local ClickGui = Instance.new("ScreenGui")
ClickGui.Name = "BeeSwarmVisuals"
ClickGui.ResetOnSpawn = false
ClickGui.Parent = CoreGui

-- Иконка
local IconButton = Instance.new("TextButton")
IconButton.Size = UDim2.new(0, 45, 0, 45)
IconButton.Position = UDim2.new(0.5, -22, 0, 30)
IconButton.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
IconButton.BorderSizePixel = 0
IconButton.TextColor3 = Color3.fromRGB(255, 200, 60)
IconButton.Text = "🐝"
IconButton.TextSize = 24
IconButton.Font = Enum.Font.GothamBold
IconButton.AutoButtonColor = false
IconButton.Parent = ClickGui
Instance.new("UIStroke", IconButton).Color = Color3.fromRGB(255, 180, 30)
Instance.new("UIStroke", IconButton).Thickness = 2
Instance.new("UICorner", IconButton).CornerRadius = UDim.new(0, 14)

-- Главное меню
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 500, 0, 290)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -145)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ClickGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 6)

-- Верхняя панель
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(40, 35, 20)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 6)

local GoldLine = Instance.new("Frame")
GoldLine.Size = UDim2.new(1, 0, 0, 2)
GoldLine.Position = UDim2.new(0, 0, 1, 0)
GoldLine.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
GoldLine.BorderSizePixel = 0
GoldLine.Parent = TopBar

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0, 25, 0, 25)
TitleIcon.Position = UDim2.new(0, 8, 0.5, -12)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text = "🐝"
TitleIcon.TextSize = 18
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 180, 0, 25)
TitleLabel.Position = UDim2.new(0, 38, 0.5, -12)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 200, 60)
TitleLabel.Text = "Bee Swarm Visuals"
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

-- Кнопка закрытия
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 28, 0, 28)
CloseButton.Position = UDim2.new(1, -34, 0.5, -14)
CloseButton.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
CloseButton.BorderSizePixel = 0
CloseButton.Text = ""
CloseButton.AutoButtonColor = false
CloseButton.Parent = TopBar
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 6)

local Line1 = Instance.new("Frame")
Line1.Size = UDim2.new(0, 2, 0, 16)
Line1.Position = UDim2.new(0.5, -1, 0.5, -8)
Line1.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
Line1.BorderSizePixel = 0
Line1.Rotation = 45
Line1.Parent = CloseButton

local Line2 = Instance.new("Frame")
Line2.Size = UDim2.new(0, 2, 0, 16)
Line2.Position = UDim2.new(0.5, -1, 0.5, -8)
Line2.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
Line2.BorderSizePixel = 0
Line2.Rotation = -45
Line2.Parent = CloseButton

-- Левая панель (табы)
local TabPanel = Instance.new("Frame")
TabPanel.Size = UDim2.new(0, 140, 1, -35)
TabPanel.Position = UDim2.new(0, 0, 0, 35)
TabPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
TabPanel.BorderSizePixel = 0
TabPanel.Parent = MainFrame

Instance.new("Frame", TabPanel).Size = UDim2.new(0, 1, 1, 0)
TabPanel.Divider.Position = UDim2.new(1, 0, 0, 0)
TabPanel.Divider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)

-- Правая панель (контент)
local ContentPanel = Instance.new("Frame")
ContentPanel.Size = UDim2.new(1, -140, 1, -35)
ContentPanel.Position = UDim2.new(0, 140, 0, 35)
ContentPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
ContentPanel.BorderSizePixel = 0
ContentPanel.Parent = MainFrame

local ContentContainer = Instance.new("ScrollingFrame")
ContentContainer.Size = UDim2.new(1, -20, 1, -20)
ContentContainer.Position = UDim2.new(0, 10, 0, 10)
ContentContainer.BackgroundTransparency = 1
ContentContainer.BorderSizePixel = 0
ContentContainer.ScrollBarThickness = 3
ContentContainer.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 70)
ContentContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentContainer.Parent = ContentPanel

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ContentContainer

-- Табы
local Tabs = {}
local SelectedTab = nil

function CreateTab(name, icon)
    local TabButton = Instance.new("TextButton")
    TabButton.Size = UDim2.new(1, -20, 0, 32)
    TabButton.Position = UDim2.new(0, 10, 0, (#Tabs * 33) + 10)
    TabButton.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
    TabButton.BorderSizePixel = 0
    TabButton.TextColor3 = Color3.fromRGB(180, 180, 190)
    TabButton.Text = "  " .. icon .. "  " .. name
    TabButton.TextSize = 13
    TabButton.Font = Enum.Font.GothamSemibold
    TabButton.TextXAlignment = Enum.TextXAlignment.Left
    TabButton.AutoButtonColor = false
    TabButton.Parent = TabPanel
    Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 6)
    
    local Highlight = Instance.new("Frame")
    Highlight.Size = UDim2.new(0, 3, 1, -8)
    Highlight.Position = UDim2.new(0, -4, 0, 4)
    Highlight.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
    Highlight.BorderSizePixel = 0
    Highlight.BackgroundTransparency = 1
    Highlight.Parent = TabButton
    
    local TabPage = Instance.new("Frame")
    TabPage.BackgroundTransparency = 1
    TabPage.Visible = false
    TabPage.Parent = ContentContainer
    local PageLayout = Instance.new("UIListLayout")
    PageLayout.Padding = UDim.new(0, 6)
    PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Parent = TabPage
    
    local tabData = { Button = TabButton, Page = TabPage, Highlight = Highlight, Layout = PageLayout, Elements = {} }
    TabButton.MouseButton1Click:Connect(function() SelectTab(tabData) end)
    table.insert(Tabs, tabData)
    return tabData
end

function SelectTab(tabData)
    if SelectedTab == tabData then return end
    if SelectedTab then
        TweenService:Create(SelectedTab.Highlight, tweenInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(SelectedTab.Button, tweenInfo, {BackgroundColor3 = Color3.fromRGB(25, 25, 28), TextColor3 = Color3.fromRGB(180, 180, 190)}):Play()
        SelectedTab.Page.Visible = false
    end
    SelectedTab = tabData
    tabData.Page.Visible = true
    TweenService:Create(tabData.Highlight, tweenInfo, {BackgroundTransparency = 0}):Play()
    TweenService:Create(tabData.Button, tweenInfo, {BackgroundColor3 = Color3.fromRGB(35, 30, 20), TextColor3 = Color3.fromRGB(255, 200, 60)}):Play()
    UpdateCanvasSize()
end

function UpdateCanvasSize()
    if SelectedTab then
        local h = 0
        for _, e in ipairs(SelectedTab.Elements) do h = h + e.AbsoluteSize.Y + 6 end
        ContentContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(h + 20, ContentContainer.AbsoluteSize.Y))
    end
end

-- Заглушки
function CreateSection() end function CreateToggle() end function CreateSlider() end function CreateButton() end

-- Перетаскивание меню
local menuDragging, menuDragStart, menuStartPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        menuDragging = true
        menuDragStart = input.Position
        menuStartPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then menuDragging = false end end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if menuDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - menuDragStart
        MainFrame.Position = UDim2.new(menuStartPos.X.Scale, menuStartPos.X.Offset + delta.X, menuStartPos.Y.Scale, menuStartPos.Y.Offset + delta.Y)
    end
end)

-- Перетаскивание иконки
local iconDragging, iconDragStart, iconStartPos
IconButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        iconDragging = true
        iconDragStart = input.Position
        iconStartPos = IconButton.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then iconDragging = false end end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if iconDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - iconDragStart
        IconButton.Position = UDim2.new(iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X, iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y)
    end
end)

IconButton.MouseButton1Click:Connect(function()
    if iconDragging then return end
    MainFrame.Visible = true
    IconButton.Visible = false
end)
CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    IconButton.Visible = true
end)
IconButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then task.wait(0.05) iconDragging = false end
end)

-- Вкладки
local HomeTab = CreateTab("Home", "⌂")
local FarmingTab = CreateTab("Farming", "✿")
local CombatTab = CreateTab("Combat", "⚔")
local QuestTab = CreateTab("Quest", "📕")
local PlantersTab = CreateTab("Planters", "🌱")
local ToysTab = CreateTab("Toys", "🧸")
local SettingsTab = CreateTab("Settings", "⚙")
HomeTab.Button.TextSize = 14

-- ====== ВКЛАДКА HOME ======
local HomePage = HomeTab.Page

local HomeSectionFrame = Instance.new("Frame")
HomeSectionFrame.Size = UDim2.new(1, -10, 0, 95)
HomeSectionFrame.BackgroundTransparency = 1
HomeSectionFrame.LayoutOrder = 1
HomeSectionFrame.Parent = HomePage

local HomeToggleBtn = Instance.new("TextButton")
HomeToggleBtn.Size = UDim2.new(1, 0, 0, 28)
HomeToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
HomeToggleBtn.BorderSizePixel = 0
HomeToggleBtn.Text = "  ▼  Home"
HomeToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HomeToggleBtn.TextSize = 18
HomeToggleBtn.Font = Enum.Font.GothamBold
HomeToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
HomeToggleBtn.AutoButtonColor = false
HomeToggleBtn.Parent = HomeSectionFrame
Instance.new("UICorner", HomeToggleBtn).CornerRadius = UDim.new(0, 6)

local HomeContent = Instance.new("Frame")
HomeContent.Size = UDim2.new(1, 0, 0, 80)
HomeContent.Position = UDim2.new(0, 0, 0, 32)
HomeContent.BackgroundTransparency = 1
HomeContent.ClipsDescendants = true
HomeContent.Parent = HomeSectionFrame

local ContentList = Instance.new("UIListLayout")
ContentList.Padding = UDim.new(0, 4)
ContentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentList.SortOrder = Enum.SortOrder.LayoutOrder
ContentList.Parent = HomeContent

-- Uptime
local UptimeLabel = Instance.new("TextLabel")
UptimeLabel.Size = UDim2.new(1, 0, 0, 20)
UptimeLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
UptimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
UptimeLabel.Text = "Uptime: 00:00:00"
UptimeLabel.TextSize = 12
UptimeLabel.Font = Enum.Font.Gotham
UptimeLabel.Parent = HomeContent
Instance.new("UICorner", UptimeLabel).CornerRadius = UDim.new(0, 4)

-- Session Honey
local HoneyLabel = Instance.new("TextLabel")
HoneyLabel.Size = UDim2.new(1, 0, 0, 20)
HoneyLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
HoneyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
HoneyLabel.Text = "Session Honey: searching..."
HoneyLabel.TextSize = 12
HoneyLabel.Font = Enum.Font.Gotham
HoneyLabel.Parent = HomeContent
Instance.new("UICorner", HoneyLabel).CornerRadius = UDim.new(0, 4)

-- Reset Honey Counter
local ResetHoneyBtn = Instance.new("TextButton")
ResetHoneyBtn.Size = UDim2.new(1, 0, 0, 20)
ResetHoneyBtn.BackgroundColor3 = Color3.fromRGB(45, 40, 25)
ResetHoneyBtn.BorderSizePixel = 0
ResetHoneyBtn.TextColor3 = Color3.fromRGB(255, 200, 60)
ResetHoneyBtn.Text = "↺ Reset Honey Counter"
ResetHoneyBtn.TextSize = 12
ResetHoneyBtn.Font = Enum.Font.GothamBold
ResetHoneyBtn.AutoButtonColor = false
ResetHoneyBtn.Parent = HomeContent
Instance.new("UICorner", ResetHoneyBtn).CornerRadius = UDim.new(0, 4)

-- Stop Everything
local StopFrame = Instance.new("Frame")
StopFrame.Size = UDim2.new(1, 0, 0, 22)
StopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
StopFrame.BorderSizePixel = 0
StopFrame.Parent = HomeContent
Instance.new("UICorner", StopFrame).CornerRadius = UDim.new(0, 4)

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
local StopBtnCorner = Instance.new("UICorner"); StopBtnCorner.CornerRadius = UDim.new(1, 0); StopBtnCorner.Parent = StopButton

local StopCircle = Instance.new("Frame")
StopCircle.Size = UDim2.new(0, 10, 0, 10)
StopCircle.Position = UDim2.new(0, 2, 0.5, -5)
StopCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
StopCircle.BorderSizePixel = 0
StopCircle.Parent = StopButton
local StopCircleCorner = Instance.new("UICorner"); StopCircleCorner.CornerRadius = UDim.new(1, 0); StopCircleCorner.Parent = StopCircle

-- Состояние раскрытия
local homeSectionOpen = true
local function updateHomeSectionSize()
    if homeSectionOpen then
        HomeContent.Visible = true
        local totalHeight = 0
        for _, child in ipairs(HomeContent:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
                totalHeight = totalHeight + child.Size.Y.Offset
            end
        end
        local itemCount = 0
        for _, child in ipairs(HomeContent:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
                itemCount = itemCount + 1
            end
        end
        if itemCount > 1 then
            totalHeight = totalHeight + ContentList.Padding.Offset * (itemCount - 1)
        end
        HomeContent.Size = UDim2.new(1, 0, 0, totalHeight)
        HomeSectionFrame.Size = UDim2.new(1, -10, 0, 28 + totalHeight)
    else
        HomeContent.Visible = false
        HomeSectionFrame.Size = UDim2.new(1, -10, 0, 28)
    end
    UpdateCanvasSize()
end
updateHomeSectionSize()

HomeToggleBtn.MouseButton1Click:Connect(function()
    homeSectionOpen = not homeSectionOpen
    HomeToggleBtn.Text = homeSectionOpen and "  ▼  Home" or "  ▶  Home"
    updateHomeSectionSize()
end)

-- Сброс счётчика мёда
ResetHoneyBtn.MouseButton1Click:Connect(function()
    local cur = getCurrentHoney()
    if cur then
        initialHoney = cur
        HoneyLabel.Text = "Session Honey: 0"
    end
end)

-- Stop Everything
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

-- Обновление Uptime
spawn(function()
    while true do
        task.wait(0.5)
        local elapsed = tick() - startTime
        UptimeLabel.Text = "Uptime: " .. formatTime(elapsed)
    end
end)

table.insert(HomeTab.Elements, HomeSectionFrame)
SelectTab(HomeTab)

IconButton.Visible = true
MainFrame.Visible = false

print("✅ v5.1 загружен! Найдёт Honey в GUI и будет отслеживать изменения.")
