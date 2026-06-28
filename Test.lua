--[[
    Bee Swarm Simulator - Visual Click GUI
    Экзекьютер: Delta
    Версия: 6.4 (Слайдер работает на телефоне!)
]]

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

local TWEEN_SPEED = 0.15
local tweenInfo = TweenInfo.new(TWEEN_SPEED, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local startTime = tick()
local stopEverything = false
local currentWalkSpeed = 16

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

-- Иконка-квадратик
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

-- Основное меню
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

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(0, 1, 1, 0)
Divider.Position = UDim2.new(1, 0, 0, 0)
Divider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Divider.BorderSizePixel = 0
Divider.Parent = TabPanel

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

-- Хранилище табов
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
        for _, e in ipairs(SelectedTab.Elements) do
            if e and e:IsA("GuiObject") then
                h = h + e.AbsoluteSize.Y + 6
            end
        end
        ContentContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(h + 20, ContentContainer.AbsoluteSize.Y))
    end
end

-- ====== УНИВЕРСАЛЬНЫЙ СЛАЙДЕР (телефон + ПК) ======
function CreateSlider(tabData, name, min, max, default, suffix, callback)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Size = UDim2.new(1, -10, 0, 60)
    SliderFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
    SliderFrame.BorderSizePixel = 0
    SliderFrame.LayoutOrder = #tabData.Elements + 1
    SliderFrame.Parent = tabData.Page
    Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0, 8)

    -- Заголовок со значением
    local SliderLabel = Instance.new("TextLabel")
    SliderLabel.Size = UDim2.new(1, -20, 0, 20)
    SliderLabel.Position = UDim2.new(0, 10, 0, 6)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    SliderLabel.Text = name .. ": " .. default .. suffix
    SliderLabel.TextSize = 13
    SliderLabel.Font = Enum.Font.GothamBold
    SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    SliderLabel.Parent = SliderFrame

    -- Полоса слайдера (делаем повыше для пальца)
    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, -20, 0, 12)  -- толще для тача
    SliderBar.Position = UDim2.new(0, 10, 0, 32)
    SliderBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    SliderBar.BorderSizePixel = 0
    SliderBar.Parent = SliderFrame
    Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(0, 6)

    -- Заполнение
    local fillPercent = (default - min) / (max - min)
    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new(fillPercent, 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBar
    Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 6)

    -- Кружок-ползунок
    local SliderKnob = Instance.new("Frame")
    SliderKnob.Size = UDim2.new(0, 20, 0, 20)  -- крупнее для пальца
    SliderKnob.Position = UDim2.new(fillPercent, -10, 0.5, -10)
    SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderKnob.BorderSizePixel = 0
    SliderKnob.Parent = SliderBar
    Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(1, 0)

    local currentValue = default
    local dragging = false

    -- Функция обновления позиции
    local function updateFromPosition(inputPosition)
        local barSize = SliderBar.AbsoluteSize.X
        if barSize <= 0 then return end
        local relativePos = math.clamp((inputPosition.X - SliderBar.AbsolutePosition.X) / barSize, 0, 1)
        currentValue = math.floor(min + (max - min) * relativePos + 0.5)
        SliderFill.Size = UDim2.new(relativePos, 0, 1, 0)
        SliderKnob.Position = UDim2.new(relativePos, -10, 0.5, -10)
        SliderLabel.Text = name .. ": " .. currentValue .. suffix
        callback(currentValue)
    end

    -- Начало перетаскивания (тач и мышь)
    local function startDrag(input)
        dragging = true
        updateFromPosition(input.Position)
    end

    -- Конец перетаскивания
    local function endDrag(input)
        dragging = false
    end

    -- Обработчики для SliderBar (основная зона захвата)
    SliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            startDrag(input)
        end
    end)

    SliderBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            endDrag(input)
        end
    end)

    -- Глобальное отслеживание движения (для тача и мыши)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            -- Для тача используем позицию пальца
            local touches = UserInputService:GetTouches()
            if #touches > 0 then
                updateFromPosition(touches[1].Position)
            elseif input.UserInputType == Enum.UserInputType.MouseMovement then
                updateFromPosition(input.Position)
            end
        end
    end)

    -- Также отслеживаем перемещение конкретного тача
    UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
        if not dragging then return end
        updateFromPosition(touch.Position)
    end)

    -- Завершение при отпускании мыши/тача глобально
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
            end
        end
    end)

    table.insert(tabData.Elements, SliderFrame)
    UpdateCanvasSize()

    return {
        Set = function(val)
            currentValue = math.clamp(val, min, max)
            local relativePos = (currentValue - min) / (max - min)
            SliderFill.Size = UDim2.new(relativePos, 0, 1, 0)
            SliderKnob.Position = UDim2.new(relativePos, -10, 0.5, -10)
            SliderLabel.Text = name .. ": " .. currentValue .. suffix
        end,
        Get = function() return currentValue end
    }
end

-- Заглушки
function CreateSection() end
function CreateToggle() end
function CreateButton() end

-- Перетаскивание меню
local menuDragging = false
local menuDragStart, menuStartPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        menuDragging = true
        menuDragStart = input.Position
        menuStartPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then menuDragging = false end end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if menuDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local pos = input.Position
        if input.UserInputType == Enum.UserInputType.Touch then
            local touches = UserInputService:GetTouches()
            if #touches > 0 then pos = touches[1].Position end
        end
        local delta = pos - menuDragStart
        MainFrame.Position = UDim2.new(menuStartPos.X.Scale, menuStartPos.X.Offset + delta.X, menuStartPos.Y.Scale, menuStartPos.Y.Offset + delta.Y)
    end
end)

-- Перетаскивание иконки
local iconDragging = false
local iconDragStart, iconStartPos
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
        local pos = input.Position
        if input.UserInputType == Enum.UserInputType.Touch then
            local touches = UserInputService:GetTouches()
            if #touches > 0 then pos = touches[1].Position end
        end
        local delta = pos - iconDragStart
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

-- Вкладки
local HomeTab = CreateTab("Home", "⌂")
local FarmingTab = CreateTab("Farming", "✿")
local CombatTab = CreateTab("Combat", "⚔")
local QuestTab = CreateTab("Quest", "📕")
local PlantersTab = CreateTab("Planters", "🌱")
local ToysTab = CreateTab("Toys", "🧸")
local SettingsTab = CreateTab("Settings", "⚙")

HomeTab.Button.TextSize = 14

-- ====== HOME ======
local HomeSectionFrame = Instance.new("Frame")
HomeSectionFrame.Size = UDim2.new(1, -10, 0, 95)
HomeSectionFrame.BackgroundTransparency = 1
HomeSectionFrame.LayoutOrder = 1
HomeSectionFrame.Parent = HomeTab.Page

local HomeToggleBtn = Instance.new("TextButton")
HomeToggleBtn.Size = UDim2.new(1, 0, 0, 28)
HomeToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
HomeToggleBtn.Text = "  ▼  Home"
HomeToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HomeToggleBtn.TextSize = 18
HomeToggleBtn.Font = Enum.Font.GothamBold
HomeToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
HomeToggleBtn.AutoButtonColor = false
HomeToggleBtn.Parent = HomeSectionFrame
Instance.new("UICorner", HomeToggleBtn).CornerRadius = UDim.new(0, 6)

local HomeContent = Instance.new("Frame")
HomeContent.Size = UDim2.new(1, 0, 0, 50)
HomeContent.Position = UDim2.new(0, 0, 0, 32)
HomeContent.BackgroundTransparency = 1
HomeContent.Parent = HomeSectionFrame
local ContentList = Instance.new("UIListLayout")
ContentList.Padding = UDim.new(0, 6)
ContentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentList.SortOrder = Enum.SortOrder.LayoutOrder
ContentList.Parent = HomeContent

local UptimeLabel = Instance.new("TextLabel")
UptimeLabel.Size = UDim2.new(1, 0, 0, 20)
UptimeLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
UptimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
UptimeLabel.Text = "Uptime: 00:00:00"
UptimeLabel.TextSize = 12
UptimeLabel.Font = Enum.Font.Gotham
UptimeLabel.Parent = HomeContent
Instance.new("UICorner", UptimeLabel).CornerRadius = UDim.new(0, 4)

local StopFrame = Instance.new("Frame")
StopFrame.Size = UDim2.new(1, 0, 0, 24)
StopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
StopFrame.Parent = HomeContent
Instance.new("UICorner", StopFrame).CornerRadius = UDim.new(0, 4)

local StopLabel = Instance.new("TextLabel")
StopLabel.Size = UDim2.new(0, 140, 0, 24)
StopLabel.BackgroundTransparency = 1
StopLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StopLabel.Text = "Stop Everything"
StopLabel.TextSize = 12
StopLabel.Font = Enum.Font.Gotham
StopLabel.Parent = StopFrame

local StopButton = Instance.new("TextButton")
StopButton.Size = UDim2.new(0, 32, 0, 18)
StopButton.Position = UDim2.new(1, -38, 0.5, -9)
StopButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
StopButton.Text = ""
StopButton.AutoButtonColor = false
StopButton.Parent = StopFrame
Instance.new("UICorner", StopButton).CornerRadius = UDim.new(1, 0)

local StopCircle = Instance.new("Frame")
StopCircle.Size = UDim2.new(0, 12, 0, 12)
StopCircle.Position = UDim2.new(0, 3, 0.5, -6)
StopCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
StopCircle.Parent = StopButton
Instance.new("UICorner", StopCircle).CornerRadius = UDim.new(1, 0)

local homeOpen = true
local function updateHomeSize()
    if homeOpen then
        HomeContent.Visible = true
        local h = 0
        for _, c in ipairs(HomeContent:GetChildren()) do
            if c:IsA("GuiObject") then h = h + c.Size.Y.Offset end
        end
        HomeContent.Size = UDim2.new(1, 0, 0, h + 6)
        HomeSectionFrame.Size = UDim2.new(1, -10, 0, 28 + h + 6)
    else
        HomeContent.Visible = false
        HomeSectionFrame.Size = UDim2.new(1, -10, 0, 28)
    end
    UpdateCanvasSize()
end
updateHomeSize()

HomeToggleBtn.MouseButton1Click:Connect(function()
    homeOpen = not homeOpen
    HomeToggleBtn.Text = homeOpen and "  ▼  Home" or "  ▶  Home"
    updateHomeSize()
end)

-- Stop Everything
local stopEnabled = false
StopButton.MouseButton1Click:Connect(function()
    stopEnabled = not stopEnabled
    if stopEnabled then
        TweenService:Create(StopButton, tweenInfo, {BackgroundColor3 = Color3.fromRGB(255, 80, 80)}):Play()
        TweenService:Create(StopCircle, tweenInfo, {Position = UDim2.new(1, -15, 0.5, -6)}):Play()
    else
        TweenService:Create(StopButton, tweenInfo, {BackgroundColor3 = Color3.fromRGB(50, 50, 55)}):Play()
        TweenService:Create(StopCircle, tweenInfo, {Position = UDim2.new(0, 3, 0.5, -6)}):Play()
    end
    stopEverything = stopEnabled
end)

spawn(function()
    while true do
        task.wait(0.5)
        UptimeLabel.Text = "Uptime: " .. formatTime(tick() - startTime)
    end
end)

-- ====== SETTINGS: MOVESPEED ======
CreateSlider(
    SettingsTab,
    "Move Speed",
    1,
    40,
    16,
    "",
    function(value)
        currentWalkSpeed = value
        if not stopEverything then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then hum.WalkSpeed = value end
            end
        end
    end
)

-- Применяем скорость при респавне
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        task.wait(0.3)
        if not stopEverything then
            hum.WalkSpeed = currentWalkSpeed
        end
    end
end)

-- Регистрируем Home
table.insert(HomeTab.Elements, HomeSectionFrame)
SelectTab(HomeTab)

IconButton.Visible = true
MainFrame.Visible = false

print("✅ v6.4 загружен! Слайдер работает на телефоне (тач).")
