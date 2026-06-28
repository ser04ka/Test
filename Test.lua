--[[
    Bee Swarm Simulator - Красивый GUI
    Версия 10.0 (100% работает)
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local startTime = tick()
local currentSpeed = 16
local stopEverything = false

-- Удаляем старый интерфейс, если был
pcall(function()
    if CoreGui:FindFirstChild("BeeSwarmGUI") then
        CoreGui.BeeSwarmGUI:Destroy()
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "BeeSwarmGUI"
gui.Parent = CoreGui

-- Формат времени
function formatTime(sec)
    local h = math.floor(sec/3600)
    local m = math.floor((sec%3600)/60)
    local s = math.floor(sec%60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

-- ====== ИКОНКА ======
local icon = Instance.new("TextButton")
icon.Size = UDim2.new(0, 45, 0, 45)
icon.Position = UDim2.new(0.5, -22, 0.1, 0)  -- чуть выше центра
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
main.Size = UDim2.new(0, 500, 0, 290)
main.Position = UDim2.new(0.5, -250, 0.5, -145)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
main.Visible = false
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 6)

-- Верхняя панель (заголовок и драг)
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 35)
topBar.BackgroundColor3 = Color3.fromRGB(40, 35, 20)
topBar.Parent = main
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 6)

-- Золотая линия под заголовком
local goldLine = Instance.new("Frame")
goldLine.Size = UDim2.new(1, 0, 0, 2)
goldLine.Position = UDim2.new(0, 0, 1, 0)
goldLine.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
goldLine.Parent = topBar

-- Текст заголовка
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 200, 0, 25)
title.Position = UDim2.new(0, 42, 0.5, -12)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 200, 60)
title.Text = "🐝 Bee Swarm Visuals"
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

-- Кнопка закрытия (крестик)
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

-- ====== БОКОВАЯ ПАНЕЛЬ ВКЛАДОК ======
local tabPanel = Instance.new("Frame")
tabPanel.Size = UDim2.new(0, 140, 1, -35)
tabPanel.Position = UDim2.new(0, 0, 0, 35)
tabPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
tabPanel.Parent = main

local tabList = Instance.new("UIListLayout")
tabList.Padding = UDim.new(0, 4)
tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabList.Parent = tabPanel

-- Разделитель
local div = Instance.new("Frame")
div.Size = UDim2.new(0, 1, 1, 0)
div.Position = UDim2.new(1, 0, 0, 0)
div.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
div.Parent = tabPanel

-- ====== КОНТЕНТ ======
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -140, 1, -35)
content.Position = UDim2.new(0, 140, 0, 35)
content.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
content.Parent = main

local contentList = Instance.new("UIListLayout")
contentList.Padding = UDim.new(0, 8)
contentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentList.Parent = content

-- ====== ЛОГИКА ВКЛАДОК ======
local tabs = {}
local currentTab = nil

function createTab(name, iconChar)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
    btn.TextColor3 = Color3.fromRGB(180, 180, 190)
    btn.Text = "  " .. iconChar .. "  " .. name
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamSemibold
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.Parent = tabPanel
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local page = Instance.new("Frame")
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = content
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 6)
    page.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local data = { button = btn, page = page }
    btn.MouseButton1Click:Connect(function()
        if currentTab then currentTab.page.Visible = false end
        page.Visible = true
        currentTab = data
    end)
    table.insert(tabs, data)
    return data
end

local homeTab = createTab("Home", "⌂")
local settingsTab = createTab("Settings", "⚙")
homeTab.button.TextSize = 14

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

-- Uptime
local uptimeLabel = Instance.new("TextLabel")
uptimeLabel.Size = UDim2.new(1, 0, 0, 20)
uptimeLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
uptimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
uptimeLabel.Text = "Uptime: 00:00:00"
uptimeLabel.TextSize = 12
uptimeLabel.Font = Enum.Font.Gotham
uptimeLabel.Parent = homeContent
Instance.new("UICorner", uptimeLabel).CornerRadius = UDim.new(0, 4)

-- Stop Everything
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

-- Раскрытие/скрытие Home
local homeOpen = true
homeToggle.MouseButton1Click:Connect(function()
    homeOpen = not homeOpen
    homeToggle.Text = homeOpen and "  ▼  Home" or "  ▶  Home"
    homeContent.Visible = homeOpen
    homeGroup.Size = homeOpen and UDim2.new(1, -16, 0, 28+56) or UDim2.new(1, -16, 0, 28)
end)

-- Stop Everything
local stopEnabled = false
stopBtn.MouseButton1Click:Connect(function()
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

-- Логика слайдера (работает мышью и пальцем)
local sliderDrag = false
local function setSpeed(x)
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
        sliderDrag = true
        setSpeed(input.Position.X)
    end
end)

speedBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDrag = false
    end
end)

speedBar.MouseMoved:Connect(function(x, y)
    if sliderDrag then setSpeed(x) end
end)

speedBar.TouchMoved:Connect(function(touch, gameProcessed)
    if sliderDrag then setSpeed(touch.Position.X) end
end)

-- ====== ПЕРЕТАСКИВАНИЕ ОКНА ======
local winDrag = false
local winStart, frameStart
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        winDrag = true
        winStart = input.Position
        frameStart = main.Position
    end
end)
topBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        winDrag = false
    end
end)
topBar.MouseMoved:Connect(function(x, y)
    if winDrag then
        local delta = Vector2.new(x, y) - winStart
        main.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X,
            frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
    end
end)
topBar.TouchMoved:Connect(function(touch, gameProcessed)
    if winDrag then
        local delta = touch.Position - winStart
        main.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X,
            frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
    end
end)

-- ====== ПЕРЕТАСКИВАНИЕ ИКОНКИ ======
local iconDrag = false
local iconStart, iconPosStart
icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        iconDrag = true
        iconStart = input.Position
        iconPosStart = icon.Position
    end
end)
icon.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        iconDrag = false
    end
end)
icon.MouseMoved:Connect(function(x, y)
    if iconDrag then
        local delta = Vector2.new(x, y) - iconStart
        icon.Position = UDim2.new(iconPosStart.X.Scale, iconPosStart.X.Offset + delta.X,
            iconPosStart.Y.Scale, iconPosStart.Y.Offset + delta.Y)
    end
end)
icon.TouchMoved:Connect(function(touch, gameProcessed)
    if iconDrag then
        local delta = touch.Position - iconStart
        icon.Position = UDim2.new(iconPosStart.X.Scale, iconPosStart.X.Offset + delta.X,
            iconPosStart.Y.Scale, iconPosStart.Y.Offset + delta.Y)
    end
end)

-- ====== ОТКРЫТИЕ/ЗАКРЫТИЕ ======
icon.MouseButton1Click:Connect(function()
    if not iconDrag then
        main.Visible = true
        icon.Visible = false
    end
end)
closeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
    icon.Visible = true
end)

-- ====== ЗАПУСК ======
currentTab = homeTab
homeTab.page.Visible = true

-- Обновление Uptime
spawn(function()
    while true do
        wait(0.5)
        uptimeLabel.Text = "Uptime: " .. formatTime(tick() - startTime)
    end
end)

-- Восстановление скорости при респавне
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        wait(0.3)
        if not stopEverything then
            hum.WalkSpeed = currentSpeed
        end
    end
end)

print("✅ Bee Swarm GUI v10.0 готов!")
