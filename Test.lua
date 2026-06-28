--[[
    Bee Swarm Simulator - Minimal GUI
    Версия: 8.0 (Самый простой, точно работает)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local startTime = tick()
local currentSpeed = 16
local sliderDragging = false

-- Функция форматирования времени
local function formatTime(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = math.floor(sec % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

-- Очищаем старый GUI (на всякий случай)
if CoreGui:FindFirstChild("BeeSwarmGUI") then
    CoreGui.BeeSwarmGUI:Destroy()
end

-- Основной GUI
local gui = Instance.new("ScreenGui")
gui.Name = "BeeSwarmGUI"
gui.Parent = CoreGui

-- Иконка
local icon = Instance.new("TextButton")
icon.Size = UDim2.new(0, 50, 0, 50)
icon.Position = UDim2.new(0.5, -25, 0.1, 0)
icon.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
icon.Text = "🐝"
icon.TextSize = 28
icon.Font = Enum.Font.GothamBold
icon.Parent = gui
Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", icon).Color = Color3.fromRGB(255, 180, 30)

-- Главное окно
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 300, 0, 200)
main.Position = UDim2.new(0.5, -150, 0.5, -100)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.Visible = false
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(40, 35, 20)
title.Text = "Bee Swarm"
title.TextColor3 = Color3.fromRGB(255, 200, 60)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = main
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

-- Крестик
local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 24, 0, 24)
close.Position = UDim2.new(1, -28, 0, 3)
close.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
close.Text = "✕"
close.TextColor3 = Color3.fromRGB(255, 100, 100)
close.TextSize = 14
close.Font = Enum.Font.GothamBold
close.Parent = main
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 4)

-- Вкладка Home (просто Uptime)
local homePage = Instance.new("Frame")
homePage.Size = UDim2.new(1, -20, 1, -40)
homePage.Position = UDim2.new(0, 10, 0, 35)
homePage.BackgroundTransparency = 1
homePage.Parent = main

local uptimeLabel = Instance.new("TextLabel")
uptimeLabel.Size = UDim2.new(1, 0, 0, 30)
uptimeLabel.Position = UDim2.new(0, 0, 0, 10)
uptimeLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
uptimeLabel.Text = "Uptime: 00:00:00"
uptimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
uptimeLabel.TextSize = 14
uptimeLabel.Font = Enum.Font.Gotham
uptimeLabel.Parent = homePage
Instance.new("UICorner", uptimeLabel).CornerRadius = UDim.new(0, 4)

-- Вкладка Settings (скрыта)
local settingsPage = Instance.new("Frame")
settingsPage.Size = UDim2.new(1, -20, 1, -40)
settingsPage.Position = UDim2.new(0, 10, 0, 35)
settingsPage.BackgroundTransparency = 1
settingsPage.Visible = false
settingsPage.Parent = main

-- Кнопки вкладок
local homeTab = Instance.new("TextButton")
homeTab.Size = UDim2.new(0, 70, 0, 24)
homeTab.Position = UDim2.new(0, 15, 0, 35)
homeTab.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
homeTab.Text = "Home"
homeTab.TextSize = 12
homeTab.Font = Enum.Font.GothamBold
homeTab.Parent = main
Instance.new("UICorner", homeTab).CornerRadius = UDim.new(0, 4)

local settingsTab = Instance.new("TextButton")
settingsTab.Size = UDim2.new(0, 70, 0, 24)
settingsTab.Position = UDim2.new(0, 90, 0, 35)
settingsTab.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
settingsTab.Text = "Settings"
settingsTab.TextSize = 12
settingsTab.Font = Enum.Font.GothamBold
settingsTab.Parent = main
Instance.new("UICorner", settingsTab).CornerRadius = UDim.new(0, 4)

homeTab.MouseButton1Click:Connect(function()
    homePage.Visible = true
    settingsPage.Visible = false
    homeTab.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
    settingsTab.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
end)

settingsTab.MouseButton1Click:Connect(function()
    homePage.Visible = false
    settingsPage.Visible = true
    homeTab.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    settingsTab.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
end)

-- Слайдер скорости (в settingsPage)
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 20)
speedLabel.Position = UDim2.new(0, 0, 0, 10)
speedLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
speedLabel.Text = "Speed: 16"
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextSize = 13
speedLabel.Font = Enum.Font.Gotham
speedLabel.Parent = settingsPage
Instance.new("UICorner", speedLabel).CornerRadius = UDim.new(0, 4)

local sliderBar = Instance.new("TextButton")
sliderBar.Size = UDim2.new(1, 0, 0, 20)
sliderBar.Position = UDim2.new(0, 0, 0, 40)
sliderBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
sliderBar.Text = ""
sliderBar.AutoButtonColor = false
sliderBar.Parent = settingsPage
Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0, 10)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new((16-1)/(40-1), 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
sliderFill.Parent = sliderBar
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 10)

local sliderKnob = Instance.new("Frame")
sliderKnob.Size = UDim2.new(0, 24, 0, 24)
sliderKnob.Position = UDim2.new((16-1)/(40-1), -12, 0.5, -12)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderKnob.Parent = sliderBar
Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

-- Логика слайдера (мышь + тач)
local function setSpeedFromX(x)
    local barX = sliderBar.AbsolutePosition.X
    local barW = sliderBar.AbsoluteSize.X
    if barW <= 0 then return end
    local rel = math.clamp((x - barX) / barW, 0, 1)
    local val = math.floor(1 + 39 * rel + 0.5)
    currentSpeed = val
    sliderFill.Size = UDim2.new(rel, 0, 1, 0)
    sliderKnob.Position = UDim2.new(rel, -12, 0.5, -12)
    speedLabel.Text = "Speed: " .. val
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
end

sliderBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        setSpeedFromX(input.Position.X)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not sliderDragging then return end
    local x = nil
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        x = input.Position.X
    elseif input.UserInputType == Enum.UserInputType.Touch then
        local touches = UserInputService:GetTouches()
        if #touches > 0 then x = touches[1].Position.X end
    end
    if x then setSpeedFromX(x) end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

-- Перетаскивание окна
local dragWindow = false
local dragStart, winStart

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragWindow = true
        dragStart = input.Position
        winStart = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragWindow then return end
    local pos = nil
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        pos = input.Position
    elseif input.UserInputType == Enum.UserInputType.Touch then
        local touches = UserInputService:GetTouches()
        if #touches > 0 then pos = touches[1].Position end
    end
    if pos then
        local delta = pos - dragStart
        main.Position = UDim2.new(winStart.X.Scale, winStart.X.Offset + delta.X,
            winStart.Y.Scale, winStart.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function()
    dragWindow = false
end)

-- Открытие/закрытие
icon.MouseButton1Click:Connect(function()
    main.Visible = true
    icon.Visible = false
end)

close.MouseButton1Click:Connect(function()
    main.Visible = false
    icon.Visible = true
end)

-- Обновление Uptime
spawn(function()
    while true do
        task.wait(1)
        uptimeLabel.Text = "Uptime: " .. formatTime(tick() - startTime)
    end
end)

-- Поддержание скорости при респавне
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        task.wait(0.3)
        hum.WalkSpeed = currentSpeed
    end
end)

print("✅ Minimal GUI loaded. Speed slider works.")
