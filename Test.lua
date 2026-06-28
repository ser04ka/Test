--[[
    Bee Swarm Simulator - Visual Click GUI
    Экзекьютер: Delta
    Версия: 9.0 (Красивый дизайн + работающий слайдер)
]]

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

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
MainFrame.Visible = false
MainFrame.Parent = ClickGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 6)

-- Верхняя панель (перетаскивание)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(40, 35, 20)
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 6)

-- Золотая линия
local GoldLine = Instance.new("Frame")
GoldLine.Size = UDim2.new(1, 0, 0, 2)
GoldLine.Position = UDim2.new(0, 0, 1, 0)
GoldLine.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
GoldLine.Parent = TopBar

-- Заголовок
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 180, 0, 25)
TitleLabel.Position = UDim2.new(0, 38, 0.5, -12)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 200, 60)
TitleLabel.Text = "🐝 Bee Swarm Visuals"
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

-- Кнопка закрытия
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 28, 0, 28)
CloseButton.Position = UDim2.new(1, -34, 0.5, -14)
CloseButton.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
CloseButton.Text = ""
CloseButton.AutoButtonColor = false
CloseButton.Parent = TopBar
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 6)

local Line1 = Instance.new("Frame")
Line1.Size = UDim2.new(0, 2, 0, 16)
Line1.Position = UDim2.new(0.5, -1, 0.5, -8)
Line1.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
Line1.Rotation = 45
Line1.Parent = CloseButton

local Line2 = Instance.new("Frame")
Line2.Size = UDim2.new(0, 2, 0, 16)
Line2.Position = UDim2.new(0.5, -1, 0.5, -8)
Line2.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
Line2.Rotation = -45
Line2.Parent = CloseButton

-- Левая панель (табы)
local TabPanel = Instance.new("Frame")
TabPanel.Size = UDim2.new(0, 140, 1, -35)
TabPanel.Position = UDim2.new(0, 0, 0, 35)
TabPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
TabPanel.Parent = MainFrame

local TabList = Instance.new("UIListLayout")
TabList.Padding = UDim.new(0, 4)
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabList.Parent = TabPanel

-- Разделитель
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(0, 1, 1, 0)
Divider.Position = UDim2.new(1, 0, 0, 0)
Divider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Divider.Parent = TabPanel

-- Правая панель (контент)
local ContentPanel = Instance.new("Frame")
ContentPanel.Size = UDim2.new(1, -140, 1, -35)
ContentPanel.Position = UDim2.new(0, 140, 0, 35)
ContentPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
ContentPanel.Parent = MainFrame

local ContentList = Instance.new("UIListLayout")
ContentList.Padding = UDim.new(0, 8)
ContentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentList.Parent = ContentPanel

-- Хранилище табов
local Tabs = {}
local SelectedTab = nil

function AddTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
    btn.TextColor3 = Color3.fromRGB(180, 180, 190)
    btn.Text = "  " .. icon .. "  " .. name
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamSemibold
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.Parent = TabPanel
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local page = Instance.new("Frame")
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = ContentPanel
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local tabData = { Button = btn, Page = page }
    btn.MouseButton1Click:Connect(function()
        if SelectedTab then SelectedTab.Page.Visible = false end
        page.Visible = true
        SelectedTab = tabData
    end)
    table.insert(Tabs, tabData)
    return tabData
end

-- Создаём вкладки
local HomeTab = AddTab("Home", "⌂")
local SettingsTab = AddTab("Settings", "⚙")
HomeTab.Button.TextSize = 14

-- ====== HOME ======
local HomeSection = Instance.new("Frame")
HomeSection.Size = UDim2.new(1, -16, 0, 28)
HomeSection.BackgroundTransparency = 1
HomeSection.Parent = HomeTab.Page

-- Стрелка раскрытия
local HomeToggle = Instance.new("TextButton")
HomeToggle.Size = UDim2.new(1, 0, 0, 28)
HomeToggle.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
HomeToggle.Text = "  ▼  Home"
HomeToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
HomeToggle.TextSize = 18
HomeToggle.Font = Enum.Font.GothamBold
HomeToggle.TextXAlignment = Enum.TextXAlignment.Left
HomeToggle.AutoButtonColor = false
HomeToggle.Parent = HomeSection
Instance.new("UICorner", HomeToggle).CornerRadius = UDim.new(0, 6)

-- Контент Home
local HomeContent = Instance.new("Frame")
HomeContent.Size = UDim2.new(1, 0, 0, 56)
HomeContent.Position = UDim2.new(0, 0, 0, 32)
HomeContent.BackgroundTransparency = 1
HomeContent.Visible = true
HomeContent.Parent = HomeSection
local HomeContentList = Instance.new("UIListLayout")
HomeContentList.Padding = UDim.new(0, 6)
HomeContentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
HomeContentList.Parent = HomeContent

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

-- Stop Everything
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

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(0, 32, 0, 18)
StopBtn.Position = UDim2.new(1, -38, 0.5, -9)
StopBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
StopBtn.Text = ""
StopBtn.AutoButtonColor = false
StopBtn.Parent = StopFrame
Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(1, 0)

local StopDot = Instance.new("Frame")
StopDot.Size = UDim2.new(0, 12, 0, 12)
StopDot.Position = UDim2.new(0, 3, 0.5, -6)
StopDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
StopDot.Parent = StopBtn
Instance.new("UICorner", StopDot).CornerRadius = UDim.new(1, 0)

-- Логика раскрытия Home
local homeOpen = true
HomeToggle.MouseButton1Click:Connect(function()
    homeOpen = not homeOpen
    HomeToggle.Text = homeOpen and "  ▼  Home" or "  ▶  Home"
    HomeContent.Visible = homeOpen
    HomeSection.Size = homeOpen and UDim2.new(1, -16, 0, 28 + 56) or UDim2.new(1, -16, 0, 28)
end)

-- Stop Everything
local stopEnabled = false
StopBtn.MouseButton1Click:Connect(function()
    stopEnabled = not stopEnabled
    if stopEnabled then
        TweenService:Create(StopBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 80, 80)}):Play()
        TweenService:Create(StopDot, TweenInfo.new(0.15), {Position = UDim2.new(1, -15, 0.5, -6)}):Play()
    else
        TweenService:Create(StopBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 55)}):Play()
        TweenService:Create(StopDot, TweenInfo.new(0.15), {Position = UDim2.new(0, 3, 0.5, -6)}):Play()
    end
    stopEverything = stopEnabled
end)

-- ====== SETTINGS: MOVESPEED ======
local SpeedGroup = Instance.new("Frame")
SpeedGroup.Size = UDim2.new(1, -16, 0, 60)
SpeedGroup.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
SpeedGroup.Parent = SettingsTab.Page
Instance.new("UICorner", SpeedGroup).CornerRadius = UDim.new(0, 8)

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, -16, 0, 22)
SpeedLabel.Position = UDim2.new(0, 8, 0, 4)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.Text = "Move Speed: 16"
SpeedLabel.TextSize = 13
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = SpeedGroup

local SpeedBar = Instance.new("TextButton")
SpeedBar.Size = UDim2.new(1, -16, 0, 14)
SpeedBar.Position = UDim2.new(0, 8, 0, 30)
SpeedBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
SpeedBar.Text = ""
SpeedBar.AutoButtonColor = false
SpeedBar.Parent = SpeedGroup
Instance.new("UICorner", SpeedBar).CornerRadius = UDim.new(0, 7)

local SpeedFill = Instance.new("Frame")
SpeedFill.Size = UDim2.new((16-1)/(40-1), 0, 1, 0)
SpeedFill.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
SpeedFill.Parent = SpeedBar
Instance.new("UICorner", SpeedFill).CornerRadius = UDim.new(0, 7)

local SpeedKnob = Instance.new("Frame")
SpeedKnob.Size = UDim2.new(0, 22, 0, 22)
SpeedKnob.Position = UDim2.new((16-1)/(40-1), -11, 0.5, -11)
SpeedKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SpeedKnob.Parent = SpeedBar
Instance.new("UICorner", SpeedKnob).CornerRadius = UDim.new(1, 0)

-- Логика слайдера (уже рабочая)
local sliderDragging = false
local function updateSpeed(screenX)
    local barStart = SpeedBar.AbsolutePosition.X
    local barSize = SpeedBar.AbsoluteSize.X
    if barSize <= 0 then return end
    local rel = math.clamp((screenX - barStart) / barSize, 0, 1)
    local val = math.floor(1 + 39 * rel + 0.5)
    currentWalkSpeed = val
    SpeedFill.Size = UDim2.new(rel, 0, 1, 0)
    SpeedKnob.Position = UDim2.new(rel, -11, 0.5, -11)
    SpeedLabel.Text = "Move Speed: " .. val
    if not stopEverything then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = val
        end
    end
end

SpeedBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        updateSpeed(input.Position.X)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not sliderDragging then return end
    local pos = nil
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        pos = input.Position
    elseif input.UserInputType == Enum.UserInputType.Touch then
        local touches = UserInputService:GetTouches()
        if #touches > 0 then pos = touches[1].Position end
    end
    if pos then updateSpeed(pos.X) end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

-- ====== ДРАГ МЕНЮ ======
local draggingMenu = false
local dragStartPos, frameStartPos

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingMenu = true
        dragStartPos = input.Position
        frameStartPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not draggingMenu then return end
    local pos = nil
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        pos = input.Position
    elseif input.UserInputType == Enum.UserInputType.Touch then
        local touches = UserInputService:GetTouches()
        if #touches > 0 then pos = touches[1].Position end
    end
    if pos then
        local delta = pos - dragStartPos
        MainFrame.Position = UDim2.new(frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function()
    draggingMenu = false
end)

-- ====== ДРАГ ИКОНКИ ======
local draggingIcon = false
local iconDragStart, iconStartPos

IconButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingIcon = true
        iconDragStart = input.Position
        iconStartPos = IconButton.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not draggingIcon then return end
    local pos = nil
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        pos = input.Position
    elseif input.UserInputType == Enum.UserInputType.Touch then
        local touches = UserInputService:GetTouches()
        if #touches > 0 then pos = touches[1].Position end
    end
    if pos then
        local delta = pos - iconDragStart
        IconButton.Position = UDim2.new(iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X,
            iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function()
    draggingIcon = false
end)

-- Открытие/закрытие
IconButton.MouseButton1Click:Connect(function()
    if draggingIcon then return end
    MainFrame.Visible = true
    IconButton.Visible = false
end)

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    IconButton.Visible = true
end)

-- ====== ЗАПУСК ======
SelectedTab = HomeTab
HomeTab.Page.Visible = true

spawn(function()
    while true do
        task.wait(0.5)
        UptimeLabel.Text = "Uptime: " .. formatTime(tick() - startTime)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        task.wait(0.3)
        if not stopEverything then
            hum.WalkSpeed = currentWalkSpeed
        end
    end
end)

IconButton.Visible = true
MainFrame.Visible = false

print("✅ v9.0 загружен! Красота и функционал вместе.")
