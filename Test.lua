--[[
    Bee Swarm Simulator - Visual Click GUI
    Стиль: Тёмный с золотым акцентом
    Экзекьютер: Delta
    Версия: 3.2 (Иконка Home крупнее)
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

-- Закругление углов
local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(0, 14)
IconCorner.Parent = IconButton

-- ====== ОСНОВНОЕ МЕНЮ ======
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 400)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = false
MainFrame.Visible = false
MainFrame.Parent = ClickGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 6)
MainCorner.Parent = MainFrame

-- Верхняя панель
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(40, 35, 20)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 6)
TopCorner.Parent = TopBar

-- Золотая линия
local GoldLine = Instance.new("Frame")
GoldLine.Size = UDim2.new(1, 0, 0, 2)
GoldLine.Position = UDim2.new(0, 0, 1, 0)
GoldLine.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
GoldLine.BorderSizePixel = 0
GoldLine.Parent = TopBar

-- Иконка в заголовке
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

-- Кнопка закрытия (кастомный крестик)
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 28, 0, 28)
CloseButton.Position = UDim2.new(1, -34, 0.5, -14)
CloseButton.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
CloseButton.BorderSizePixel = 0
CloseButton.Text = ""
CloseButton.AutoButtonColor = false
CloseButton.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

-- Линия 1 крестика
local Line1 = Instance.new("Frame")
Line1.Size = UDim2.new(0, 2, 0, 16)
Line1.Position = UDim2.new(0.5, -1, 0.5, -8)
Line1.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
Line1.BorderSizePixel = 0
Line1.Rotation = 45
Line1.Parent = CloseButton

-- Линия 2 крестика
local Line2 = Instance.new("Frame")
Line2.Size = UDim2.new(0, 2, 0, 16)
Line2.Position = UDim2.new(0.5, -1, 0.5, -8)
Line2.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
Line2.BorderSizePixel = 0
Line2.Rotation = -45
Line2.Parent = CloseButton

-- Левая панель (табы)
local TabPanel = Instance.new("Frame")
TabPanel.Name = "TabPanel"
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

    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 6)
    TabCorner.Parent = TabButton

    local Highlight = Instance.new("Frame")
    Highlight.Name = "Highlight"
    Highlight.Size = UDim2.new(0, 3, 1, -8)
    Highlight.Position = UDim2.new(0, -4, 0, 4)
    Highlight.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
    Highlight.BorderSizePixel = 0
    Highlight.BackgroundTransparency = 1
    Highlight.Parent = TabButton

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

    TabButton.MouseButton1Click:Connect(function()
        SelectTab(tabData)
    end)

    table.insert(Tabs, tabData)
    return tabData
end

-- Выбор таба
function SelectTab(tabData)
    if SelectedTab == tabData then return end

    if SelectedTab then
        TweenService:Create(SelectedTab.Highlight, tweenInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(SelectedTab.Button, tweenInfo, {
            BackgroundColor3 = Color3.fromRGB(25, 25, 28),
            TextColor3 = Color3.fromRGB(180, 180, 190)
        }):Play()
        SelectedTab.Page.Visible = false
    end

    SelectedTab = tabData
    tabData.Page.Visible = true
    TweenService:Create(tabData.Highlight, tweenInfo, {BackgroundTransparency = 0}):Play()
    TweenService:Create(tabData.Button, tweenInfo, {
        BackgroundColor3 = Color3.fromRGB(35, 30, 20),
        TextColor3 = Color3.fromRGB(255, 200, 60)
    }):Play()

    UpdateCanvasSize()
end

function UpdateCanvasSize()
    if SelectedTab then
        local height = 0
        for _, element in ipairs(SelectedTab.Elements) do
            height = height + element.AbsoluteSize.Y + 6
        end
        ContentContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(height + 20, ContentContainer.AbsoluteSize.Y))
    end
end

-- ====== DRAG ДЛЯ МЕНЮ ======
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

-- ====== DRAG ДЛЯ ИКОНКИ ======
local iconDragging = false
local iconDragStart, iconStartPos

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
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        task.wait(0.05)
        iconDragging = false
    end
end)

-- ====== СОЗДАНИЕ ВКЛАДОК ======
local HomeTab = CreateTab("Home", "⌂")
local FarmingTab = CreateTab("Farming", "✿")
local CombatTab = CreateTab("Combat", "⚔")
local QuestTab = CreateTab("Quest", "📕")
local PlantersTab = CreateTab("Planters", "🌱")
local ToysTab = CreateTab("Toys", "🧸")
local SettingsTab = CreateTab("Settings", "⚙")

-- Делаем иконку Home чуть больше
HomeTab.Button.TextSize = 14

-- Выбираем вкладку Home по умолчанию
SelectTab(HomeTab)

-- ====== ФИНАЛЬНЫЕ НАСТРОЙКИ ======
IconButton.Visible = true
MainFrame.Visible = false

print("✅ Bee Swarm Click GUI v3.2 загружен!")
print("🐝 Иконка Home увеличена (TextSize 14)")
