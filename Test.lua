--[[
    Bee Swarm Simulator - Visual Click GUI
    Стиль: Тёмный с золотым акцентом
    Экзекьютер: Delta
    Версия: 2.0
]]

-- Сервисы
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Настройки анимации
local TWEEN_SPEED = 0.15
local tweenInfo = TweenInfo.new(TWEEN_SPEED, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- Создаём главный GUI
local ClickGui = Instance.new("ScreenGui")
ClickGui.Name = "BeeSwarmVisuals"
ClickGui.ResetOnSpawn = false
ClickGui.Parent = CoreGui

-- ====== ИКОНКА-КВАДРАТИК (открывашка) ======
local IconButton = Instance.new("TextButton")
IconButton.Name = "IconButton"
IconButton.Size = UDim2.new(0, 45, 0, 45)
-- Позиция: по центру сверху (не в самом верху, отступ 30 пикселей)
IconButton.Position = UDim2.new(0.5, -22, 0, 30)
IconButton.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
IconButton.BorderSizePixel = 0
IconButton.TextColor3 = Color3.fromRGB(255, 200, 60)
IconButton.Text = "🐝"
IconButton.TextSize = 24
IconButton.Font = Enum.Font.GothamBold
IconButton.AutoButtonColor = false
IconButton.Parent = ClickGui

-- Золотая рамка
local IconStroke = Instance.new("UIStroke")
IconStroke.Color = Color3.fromRGB(255, 180, 30)
IconStroke.Thickness = 2
IconStroke.Parent = IconButton

-- Закругление углов (через UICorner)
local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(0, 14)
IconCorner.Parent = IconButton

-- Тень под иконкой
local IconShadow = Instance.new("ImageLabel")
IconShadow.Size = UDim2.new(0, 49, 0, 49)
IconShadow.Position = UDim2.new(0.5, -24, 0.5, -24)
IconShadow.BackgroundTransparency = 1
IconShadow.Image = "rbxassetid://6015897843" -- стандартная тень Roblox
IconShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
IconShadow.ImageTransparency = 0.6
IconShadow.ScaleType = Enum.ScaleType.Slice
IconShadow.SliceCenter = Rect.new(49, 49, 209, 209)
IconShadow.Parent = IconButton

-- ====== ОСНОВНОЕ МЕНЮ ======
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 400)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = false
MainFrame.Visible = false -- СКРЫТО по умолчанию
MainFrame.Parent = ClickGui

-- Закругление меню
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 6)
MainCorner.Parent = MainFrame

-- Градиентная рамка (верхняя полоса)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(40, 35, 20)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

-- Закругление верхней части
local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 6)
TopCorner.Parent = TopBar

-- Золотая линия под топбаром
local GoldLine = Instance.new("Frame")
GoldLine.Size = UDim2.new(1, 0, 0, 2)
GoldLine.Position = UDim2.new(0, 0, 1, 0)
GoldLine.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
GoldLine.BorderSizePixel = 0
GoldLine.Parent = TopBar

-- Иконка пчелы (эмодзи)
local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0, 25, 0, 25)
TitleIcon.Position = UDim2.new(0, 8, 0.5, -12)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text = "🐝"
TitleIcon.TextSize = 18
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.Parent = TopBar

-- Заголовок
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
CloseButton.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseButton.Text = "✕"
CloseButton.TextSize = 16
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TopBar

-- Закругление кнопки закрытия
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

-- Левая панель (табы)
local TabPanel = Instance.new("Frame")
TabPanel.Name = "TabPanel"
TabPanel.Size = UDim2.new(0, 140, 1, -35)
TabPanel.Position = UDim2.new(0, 0, 0, 35)
TabPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
TabPanel.BorderSizePixel = 0
TabPanel.Parent = MainFrame

-- Разделительная линия
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(0, 1, 1, 0)
Divider.Position = UDim2.new(1, 0, 0, 0)
Divider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Divider.BorderSizePixel = 0
Divider.Parent = TabPanel

-- Правая панель (контент)
local ContentPanel = Instance.new("Frame")
ContentPanel.Name = "ContentPanel"
ContentPanel.Size = UDim2.new(1, -140, 1, -35)
ContentPanel.Position = UDim2.new(0, 140, 0, 35)
ContentPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
ContentPanel.BorderSizePixel = 0
ContentPanel.Parent = MainFrame

-- Контейнер для контента табов
local ContentContainer = Instance.new("ScrollingFrame")
ContentContainer.Size = UDim2.new(1, -20, 1, -20)
ContentContainer.Position = UDim2.new(0, 10, 0, 10)
ContentContainer.BackgroundTransparency = 1
ContentContainer.BorderSizePixel = 0
ContentContainer.ScrollBarThickness = 3
ContentContainer.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 70)
ContentContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentContainer.Parent = ContentPanel

-- Список для контента
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ContentContainer

-- Хранилище табов
local Tabs = {}
local SelectedTab = nil

-- Функция создания таба
function CreateTab(name, icon)
    local TabButton = Instance.new("TextButton")
    TabButton.Name = name
    TabButton.Size = UDim2.new(1, -20, 0, 32)
    TabButton.Position = UDim2.new(0, 10, 0, (#Tabs * 38) + 10)
    TabButton.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
    TabButton.BorderSizePixel = 0
    TabButton.TextColor3 = Color3.fromRGB(180, 180, 190)
    TabButton.Text = "  " .. icon .. "  " .. name
    TabButton.TextSize = 13
    TabButton.Font = Enum.Font.GothamSemibold
    TabButton.TextXAlignment = Enum.TextXAlignment.Left
    TabButton.AutoButtonColor = false
    TabButton.Parent = TabPanel

    -- Закругление табов
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 6)
    TabCorner.Parent = TabButton

    -- Золотая полоска (скрыта по умолчанию)
    local Highlight = Instance.new("Frame")
    Highlight.Name = "Highlight"
    Highlight.Size = UDim2.new(0, 3, 1, -8)
    Highlight.Position = UDim2.new(0, -4, 0, 4)
    Highlight.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
    Highlight.BorderSizePixel = 0
    Highlight.BackgroundTransparency = 1
    Highlight.Parent = TabButton

    -- Создаём страницу контента
    local TabPage = Instance.new("Frame")
    TabPage.Name = name .. "Page"
    TabPage.Size = UDim2.new(1, 0, 0, 0)
    TabPage.BackgroundTransparency = 1
    TabPage.Visible = false
    TabPage.Parent = ContentContainer

    local PageLayout = Instance.new("UIListLayout")
    PageLayout.Padding = UDim.new(0, 6)
    PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Parent = TabPage

    local tabData = {
        Button = TabButton,
        Page = TabPage,
        Highlight = Highlight,
        Layout = PageLayout,
        Elements = {}
    }

    -- Клик по табу
    TabButton.MouseButton1Click:Connect(function()
        SelectTab(tabData)
    end)

    table.insert(Tabs, tabData)
    return tabData
end

-- Выбор таба
function SelectTab(tabData)
    if SelectedTab == tabData then return end

    -- Сброс предыдущего
    if SelectedTab then
        TweenService:Create(SelectedTab.Highlight, tweenInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(SelectedTab.Button, tweenInfo, {
            BackgroundColor3 = Color3.fromRGB(25, 25, 28),
            TextColor3 = Color3.fromRGB(180, 180, 190)
        }):Play()
        SelectedTab.Page.Visible = false
    end

    -- Активация нового
    SelectedTab = tabData
    tabData.Page.Visible = true
    TweenService:Create(tabData.Highlight, tweenInfo, {BackgroundTransparency = 0}):Play()
    TweenService:Create(tabData.Button, tweenInfo, {
        BackgroundColor3 = Color3.fromRGB(35, 30, 20),
        TextColor3 = Color3.fromRGB(255, 200, 60)
    }):Play()

    -- Обновление размера контента
    UpdateCanvasSize()
end

-- Обновление размера скролла
function UpdateCanvasSize()
    if SelectedTab then
        local height = 0
        for _, element in ipairs(SelectedTab.Elements) do
            height = height + element.AbsoluteSize.Y + 6
        end
        ContentContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(height + 20, ContentContainer.AbsoluteSize.Y))
    end
end

-- Создание секции
function CreateSection(tabData, title)
    local Section = Instance.new("Frame")
    Section.Name = title
    Section.Size = UDim2.new(1, -10, 0, 30)
    Section.BackgroundTransparency = 1
    Section.BorderSizePixel = 0
    Section.LayoutOrder = #tabData.Elements + 1
    Section.Parent = tabData.Page

    local SectionLabel = Instance.new("TextLabel")
    SectionLabel.Size = UDim2.new(1, 0, 0, 20)
    SectionLabel.BackgroundTransparency = 1
    SectionLabel.TextColor3 = Color3.fromRGB(255, 180, 30)
    SectionLabel.Text = title
    SectionLabel.TextSize = 12
    SectionLabel.Font = Enum.Font.GothamBold
    SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    SectionLabel.Parent = Section

    local SectionLine = Instance.new("Frame")
    SectionLine.Size = UDim2.new(1, 0, 0, 1)
    SectionLine.Position = UDim2.new(0, 0, 1, 0)
    SectionLine.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    SectionLine.BorderSizePixel = 0
    SectionLine.Parent = Section

    table.insert(tabData.Elements, Section)
    return Section
end

-- Создание тоггла
function CreateToggle(tabData, section, name, default, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, -10, 0, 36)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.LayoutOrder = #tabData.Elements + 1
    ToggleFrame.Parent = tabData.Page

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 6)
    ToggleCorner.Parent = ToggleFrame

    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(0, 140, 0, 36)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
    ToggleLabel.Text = name
    ToggleLabel.TextSize = 12
    ToggleLabel.Font = Enum.Font.Gotham
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
    ToggleLabel.Parent = ToggleFrame

    -- Кнопка тоггла (вкл/выкл)
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 36, 0, 18)
    ToggleButton.Position = UDim2.new(1, -46, 0.5, -9)
    ToggleButton.BackgroundColor3 = default and Color3.fromRGB(255, 180, 30) or Color3.fromRGB(50, 50, 55)
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = ""
    ToggleButton.AutoButtonColor = false
    ToggleButton.Parent = ToggleFrame

    local ToggleBtnCorner = Instance.new("UICorner")
    ToggleBtnCorner.CornerRadius = UDim.new(1, 0)
    ToggleBtnCorner.Parent = ToggleButton

    local ToggleCircle = Instance.new("Frame")
    ToggleCircle.Size = UDim2.new(0, 12, 0, 12)
    ToggleCircle.Position = default and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ToggleCircle.BorderSizePixel = 0
    ToggleCircle.Parent = ToggleButton

    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = ToggleCircle

    local state = default

    local function UpdateToggle()
        if state then
            TweenService:Create(ToggleButton, tweenInfo, {BackgroundColor3 = Color3.fromRGB(255, 180, 30)}):Play()
            TweenService:Create(ToggleCircle, tweenInfo, {Position = UDim2.new(1, -15, 0.5, -6)}):Play()
        else
            TweenService:Create(ToggleButton, tweenInfo, {BackgroundColor3 = Color3.fromRGB(50, 50, 55)}):Play()
            TweenService:Create(ToggleCircle, tweenInfo, {Position = UDim2.new(0, 3, 0.5, -6)}):Play()
        end
    end

    ToggleButton.MouseButton1Click:Connect(function()
        state = not state
        UpdateToggle()
        callback(state)
    end)

    table.insert(tabData.Elements, ToggleFrame)
    return {Set = function(val) state = val; UpdateToggle() end, Get = function() return state end}
end

-- Создание слайдера
function CreateSlider(tabData, section, name, min, max, default, suffix, callback)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Size = UDim2.new(1, -10, 0, 55)
    SliderFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
    SliderFrame.BorderSizePixel = 0
    SliderFrame.LayoutOrder = #tabData.Elements + 1
    SliderFrame.Parent = tabData.Page

    local SliderCorner = Instance.new("UICorner")
    SliderCorner.CornerRadius = UDim.new(0, 6)
    SliderCorner.Parent = SliderFrame

    local SliderLabel = Instance.new("TextLabel")
    SliderLabel.Size = UDim2.new(0, 140, 0, 20)
    SliderLabel.Position = UDim2.new(0, 10, 0, 5)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
    SliderLabel.Text = name .. ": " .. default .. suffix
    SliderLabel.TextSize = 12
    SliderLabel.Font = Enum.Font.Gotham
    SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    SliderLabel.Parent = SliderFrame

    -- Прогресс-бар
    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, -20, 0, 6)
    SliderBar.Position = UDim2.new(0, 10, 0, 32)
    SliderBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    SliderBar.BorderSizePixel = 0
    SliderBar.Parent = SliderFrame

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(0, 3)
    BarCorner.Parent = SliderBar

    local SliderFill = Instance.new("Frame")
    local fillPercent = (default - min) / (max - min)
    SliderFill.Size = UDim2.new(fillPercent, 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBar

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 3)
    FillCorner.Parent = SliderFill

    local SliderButton = Instance.new("TextButton")
    SliderButton.Size = UDim2.new(1, 0, 0, 20)
    SliderButton.Position = UDim2.new(0, 0, 0, 25)
    SliderButton.BackgroundTransparency = 1
    SliderButton.Text = ""
    SliderButton.Parent = SliderFrame

    local dragging = false
    local currentValue = default

    local function UpdateSlider(input)
        local barSize = SliderBar.AbsoluteSize.X
        local relativePos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / barSize, 0, 1)
        currentValue = math.floor(min + (max - min) * relativePos + 0.5)
        SliderFill.Size = UDim2.new(relativePos, 0, 1, 0)
        SliderLabel.Text = name .. ": " .. currentValue .. suffix
        callback(currentValue)
    end

    SliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            UpdateSlider(input)
        end
    end)

    SliderButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateSlider(input)
        end
    end)

    table.insert(tabData.Elements, SliderFrame)
    return {Set = function(val) currentValue = val; SliderLabel.Text = name .. ": " .. val .. suffix; SliderFill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0) end, Get = function() return currentValue end}
end

-- Создание кнопки
function CreateButton(tabData, section, name, callback)
    local ButtonFrame = Instance.new("Frame")
    ButtonFrame.Size = UDim2.new(1, -10, 0, 32)
    ButtonFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
    ButtonFrame.BorderSizePixel = 0
    ButtonFrame.LayoutOrder = #tabData.Elements + 1
    ButtonFrame.Parent = tabData.Page

    local BtnFrameCorner = Instance.new("UICorner")
    BtnFrameCorner.CornerRadius = UDim.new(0, 6)
    BtnFrameCorner.Parent = ButtonFrame

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -20, 0, 26)
    Button.Position = UDim2.new(0, 10, 0, 3)
    Button.BackgroundColor3 = Color3.fromRGB(45, 40, 25)
    Button.BorderSizePixel = 0
    Button.TextColor3 = Color3.fromRGB(255, 200, 60)
    Button.Text = name
    Button.TextSize = 12
    Button.Font = Enum.Font.GothamBold
    Button.AutoButtonColor = false
    Button.Parent = ButtonFrame

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 4)
    BtnCorner.Parent = Button

    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, tweenInfo, {BackgroundColor3 = Color3.fromRGB(60, 50, 30)}):Play()
    end)

    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, tweenInfo, {BackgroundColor3 = Color3.fromRGB(45, 40, 25)}):Play()
    end)

    Button.MouseButton1Click:Connect(function()
        TweenService:Create(Button, tweenInfo, {BackgroundColor3 = Color3.fromRGB(255, 180, 30)}):Play()
        task.wait(0.1)
        TweenService:Create(Button, tweenInfo, {BackgroundColor3 = Color3.fromRGB(45, 40, 25)}):Play()
        callback()
    end)

    table.insert(tabData.Elements, ButtonFrame)
    return Button
end

-- ====== DRAG ДЛЯ МЕНЮ (за верхнюю панель) ======
local menuDragging = false
local menuDragInput, menuDragStart, menuStartPos

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        menuDragging = true
        menuDragStart = input.Position
        menuStartPos = MainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                menuDragging = false
            end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if menuDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - menuDragStart
        MainFrame.Position = UDim2.new(
            menuStartPos.X.Scale, menuStartPos.X.Offset + delta.X,
            menuStartPos.Y.Scale, menuStartPos.Y.Offset + delta.Y
        )
    end
end)

-- ====== DRAG ДЛЯ ИКОНКИ (квадратика) ======
local iconDragging = false
local iconDragInput, iconDragStart, iconStartPos

IconButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        iconDragging = true
        iconDragStart = input.Position
        iconStartPos = IconButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                iconDragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if iconDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - iconDragStart
        IconButton.Position = UDim2.new(
            iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X,
            iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y
        )
    end
end)

-- ====== ОТКРЫТИЕ/ЗАКРЫТИЕ МЕНЮ ======
-- При клике на иконку - показываем меню
IconButton.MouseButton1Click:Connect(function()
    -- Игнорируем клик если был драг (проверяем расстояние)
    if iconDragging then return end
    
    MainFrame.Visible = true
    IconButton.Visible = false
end)

-- При клике на крестик - скрываем меню, показываем иконку
CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    IconButton.Visible = true
    -- Иконка остаётся там же где была (не сбрасываем позицию)
end)

-- Защита от ложного клика при драге
IconButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        -- Небольшая задержка чтобы отделить драг от клика
        task.wait(0.05)
        iconDragging = false
    end
end)

-- ====== АНИМАЦИЯ ПОЯВЛЕНИЯ МЕНЮ ======
MainFrame.Visible = false -- Изначально скрыто
MainFrame.BackgroundTransparency = 1 -- Для анимации

-- Функция показа с анимацией
local function ShowMenu()
    MainFrame.Visible = true
    MainFrame.BackgroundTransparency = 1
    MainFrame.Size = UDim2.new(0, 500, 0, 0)
    
    TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 500, 0, 400),
        BackgroundTransparency = 0
    }):Play()
    
    IconButton.Visible = false
end

-- Переопределяем клик на иконку с анимацией
IconButton.MouseButton1Click:Connect(function()
    if iconDragging then return end
    ShowMenu()
end)

-- ====== ИНИЦИАЛИЗАЦИЯ ТАБОВ ======
local VisualsTab = CreateTab("Visuals", "👁")
local PlayerTab = CreateTab("Player", "🧑")
local WorldTab = CreateTab("World", "🌍")

-- === Вкладка Visuals ===
CreateSection(VisualsTab, "ESP Settings")

CreateToggle(VisualsTab, nil, "Player ESP", false, function(state)
    print("Player ESP:", state)
end)

CreateToggle(VisualsTab, nil, "Mob ESP", false, function(state)
    print("Mob ESP:", state)
end)

CreateToggle(VisualsTab, nil, "Field ESP", false, function(state)
    print("Field ESP:", state)
end)

CreateSlider(VisualsTab, nil, "ESP Distance", 100, 2000, 1000, " studs", function(value)
    print("ESP Distance:", value)
end)

CreateSection(VisualsTab, "Player Visuals")

CreateToggle(VisualsTab, nil, "Chams", false, function(state)
    print("Chams:", state)
end)

CreateToggle(VisualsTab, nil, "Tracers", false, function(state)
    print("Tracers:", state)
end)

-- === Вкладка Player ===
CreateSection(PlayerTab, "Movement")

CreateToggle(PlayerTab, nil, "Fly", false, function(state)
    print("Fly:", state)
end)

CreateSlider(PlayerTab, nil, "Fly Speed", 10, 100, 50, "", function(value)
    print("Fly Speed:", value)
end)

CreateSlider(PlayerTab, nil, "Walk Speed", 16, 200, 16, "", function(value)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
end)

CreateSlider(PlayerTab, nil, "Jump Power", 50, 300, 50, "", function(value)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = value
    end
end)

CreateSection(PlayerTab, "Character")

CreateToggle(PlayerTab, nil, "Anti-AFK", false, function(state)
    print("Anti-AFK:", state)
end)

CreateButton(PlayerTab, nil, "Respawn", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
    end
end)

-- === Вкладка World ===
CreateSection(WorldTab, "Lighting")

CreateToggle(WorldTab, nil, "Fullbright", false, function(state)
    if state then
        game:GetService("Lighting").Brightness = 2
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").FogEnd = 999999
        game:GetService("Lighting").ClockTime = 14
    else
        game:GetService("Lighting").Brightness = 1
        game:GetService("Lighting").GlobalShadows = true
        game:GetService("Lighting").FogEnd = 5000
    end
end)

CreateSlider(WorldTab, nil, "Time", 0, 24, 14, ":00", function(value)
    game:GetService("Lighting").ClockTime = value
end)

CreateSlider(WorldTab, nil, "FOV", 30, 120, 70, "", function(value)
    workspace.CurrentCamera.FieldOfView = value
end)

CreateSection(WorldTab, "Farm")

CreateToggle(WorldTab, nil, "Auto Collect Pollen", false, function(state)
    print("Auto Collect:", state)
end)

CreateToggle(WorldTab, nil, "Auto Convert", false, function(state)
    print("Auto Convert:", state)
end)

-- Выбираем первый таб по умолчанию
SelectTab(Tabs[1])

-- ====== ФИНАЛЬНЫЕ НАСТРОЙКИ ======
-- Иконка видна, меню скрыто при запуске
IconButton.Visible = true
MainFrame.Visible = false
MainFrame.BackgroundTransparency = 0 -- Сбрасываем для нормального отображения
MainFrame.Size = UDim2.new(0, 500, 0, 400) -- Полный размер

print("✅ Bee Swarm Click GUI v2.0 загружен!")
print("🐝 Особенности:")
print("   - Круглый значок с закруглёнными краями")
print("   - Позиция: центр сверху (отступ 30px)")
print("   - Перетаскивание значка и меню")
print("   - Плавная анимация открытия")
print("   - Значок остаётся на месте после закрытия")
