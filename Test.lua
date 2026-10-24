-- === Swarm Tweaker: Lite Project (Final Fix + Auto Rejoin) ===
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer

-- Очистка старых меню
for _, name in ipairs({"LiteProjectUI", "LiteProjectMinGui", "SwarmTweakerPro", "SwarmMinButton", "SwarmTweaker"}) do
    if player.PlayerGui:FindFirstChild(name) then player.PlayerGui[name]:Destroy() end
end

local THEME = {
    Bg = Color3.fromRGB(18, 18, 20),
    Sidebar = Color3.fromRGB(14, 14, 16),
    Accent = Color3.fromRGB(232, 121, 249),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(140, 140, 150),
    Border = Color3.fromRGB(45, 45, 50),
    ElementBg = Color3.fromRGB(30, 30, 35),
    TabActiveBg = Color3.fromRGB(40, 40, 45),
    ToggleOff = Color3.fromRGB(45, 45, 50)
}

_G.FPSBoostActive = false
_G.AutoCleanMemory = true
_G.FPSLimitActive = true
_G.AutoRejoin = true
_G.CurrentFPS = 60
local isDraggingSlider = false

-- === АВТО-РЕДЖОИН (Безопасный) ===
local REJOIN_FILE = "LiteProject_Server.txt"
task.spawn(function()
    -- Пытаемся сохранить при запуске
    pcall(function()
        if isfile and readfile and isfile(REJOIN_FILE) then
            local savedData = readfile(REJOIN_FILE)
            if savedData and savedData ~= "" then
                local sep = string.find(savedData, "|")
                if sep and _G.AutoRejoin then
                    local placeId = tonumber(string.sub(savedData, 1, sep - 1))
                    local jobId = string.sub(savedData, sep + 1)
                    if jobId and jobId ~= "" and game.JobId ~= jobId then
                        TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
                    end
                end
            end
        end
    end)
    
    -- Постоянное сохранение
    while task.wait(30) do
        if _G.AutoRejoin then
            pcall(function()
                if writefile and game.JobId and game.JobId ~= "" then
                    writefile(REJOIN_FILE, tostring(game.PlaceId) .. "|" .. game.JobId)
                end
            end)
        end
    end
end)

-- === БЕЗОПАСНЫЙ FPS ===
local function updateFPS()
    pcall(function()
        if type(setfpscap) == "function" then 
            if _G.FPSLimitActive then
                setfpscap(_G.CurrentFPS)
            else
                setfpscap(9999) -- Безлимит
            end
        end
    end)
end
updateFPS()

-- === ИНТЕРФЕЙС ===
local gui = Instance.new("ScreenGui")
gui.Name = "LiteProjectUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = player:WaitForChild("PlayerGui")

local minGui = Instance.new("ScreenGui")
minGui.Name = "LiteProjectMinGui"
minGui.ResetOnSpawn = false
minGui.DisplayOrder = 101
minGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 480, 0, 320)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = THEME.Bg
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = gui

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 8)

-- Драг окна (с защитой слайдера)
local function makeDraggable(frame, onTap)
    local dragging, dragInput, dragStart, startPos, maxDist = false, nil, nil, nil, 0
    frame.InputBegan:Connect(function(input)
        if isDraggingSlider then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = UDim2.new(0, frame.AbsolutePosition.X, 0, frame.AbsolutePosition.Y); maxDist = 0
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging and not isDraggingSlider then
            local delta = input.Position - dragStart
            if delta.Magnitude > maxDist then maxDist = delta.Magnitude end
            local vp = Workspace.CurrentCamera.ViewportSize
            frame.AnchorPoint = Vector2.new(0, 0)
            frame.Position = UDim2.new(0, math.clamp(startPos.X.Offset + delta.X, 0, vp.X - frame.AbsoluteSize.X), 0, math.clamp(startPos.Y.Offset + delta.Y, 0, vp.Y - frame.AbsoluteSize.Y))
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false; dragInput = nil
                if maxDist < 10 and onTap then onTap() end
            end
        end
    end)
end
makeDraggable(mainFrame)

-- Заголовок
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 45)
topBar.BackgroundTransparency = 1

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "★ Lite Project"
title.TextColor3 = THEME.Text
title.Font = Enum.Font.GothamMedium
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left

local minimizeBtn = Instance.new("TextButton", topBar)
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -40, 0, 7.5)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = THEME.TextDim
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18

local line = Instance.new("Frame", mainFrame)
line.Size = UDim2.new(1, 0, 0, 1)
line.Position = UDim2.new(0, 0, 0, 45)
line.BackgroundColor3 = THEME.Border
line.BorderSizePixel = 0

local sidebar = Instance.new("Frame", mainFrame)
sidebar.Size = UDim2.new(0, 140, 1, -46)
sidebar.Position = UDim2.new(0, 0, 0, 46)
sidebar.BackgroundColor3 = THEME.Sidebar
sidebar.BorderSizePixel = 0

local content = Instance.new("Frame", mainFrame)
content.Size = UDim2.new(1, -140, 1, -46)
content.Position = UDim2.new(0, 140, 0, 46)
content.BackgroundTransparency = 1

-- === КОМПОНЕНТЫ ===
local function createTab(text, yPos)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -30, 0, 40)
    btn.Position = UDim2.new(0, 15, 0, yPos)
    btn.BackgroundColor3 = THEME.Sidebar
    btn.Text = "  " .. text
    btn.TextColor3 = THEME.TextDim
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local function createToggle(text, default, yPos, callback)
    local container = Instance.new("Frame", content)
    container.Size = UDim2.new(1, -40, 0, 30)
    container.Position = UDim2.new(0, 20, 0, yPos)
    container.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, -50, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = THEME.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local toggleBg = Instance.new("TextButton", container)
    toggleBg.Size = UDim2.new(0, 40, 0, 24)
    toggleBg.Position = UDim2.new(1, 0, 0.5, -12)
    toggleBg.BackgroundColor3 = default and THEME.Accent or THEME.ToggleOff
    toggleBg.Text = ""
    toggleBg.AutoButtonColor = false
    toggleBg.BorderSizePixel = 0
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame", toggleBg)
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    knob.BackgroundColor3 = default and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    local isOn = default
    toggleBg.MouseButton1Click:Connect(function()
        isOn = not isOn
        if isOn then
            TweenService:Create(toggleBg, TweenInfo.new(0.2), {BackgroundColor3 = THEME.Accent}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -22, 0.5, -10), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        else
            TweenService:Create(toggleBg, TweenInfo.new(0.2), {BackgroundColor3 = THEME.ToggleOff}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -10), BackgroundColor3 = Color3.fromRGB(150, 150, 150)}):Play()
        end
        if callback then callback(isOn) end
    end)
    return container
end

-- 🔥 ИДЕАЛЬНЫЙ СЛАЙДЕР
local function createSlider(text, default, yPos, callback)
    local container = Instance.new("Frame", content)
    container.Size = UDim2.new(1, -40, 0, 50)
    container.Position = UDim2.new(0, 20, 0, yPos)
    container.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, -40, 0, 15)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = THEME.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local valLabel = Instance.new("TextLabel", container)
    valLabel.Size = UDim2.new(0, 40, 0, 15)
    valLabel.Position = UDim2.new(1, -40, 0, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(default)
    valLabel.TextColor3 = THEME.Accent
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 12
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    local track = Instance.new("TextButton", container)
    track.Size = UDim2.new(1, 0, 0, 20) -- Толстая зона клика
    track.Position = UDim2.new(0, 0, 0, 20)
    track.BackgroundTransparency = 1
    track.Text = ""
    
    local bg = Instance.new("Frame", track)
    bg.Size = UDim2.new(1, 0, 0, 4)
    bg.Position = UDim2.new(0, 0, 0.5, -2)
    bg.BackgroundColor3 = THEME.ElementBg
    bg.BorderSizePixel = 0
    
    local fill = Instance.new("Frame", bg)
    fill.Size = UDim2.new((default - 15) / 105, 0, 1, 0)
    fill.BackgroundColor3 = THEME.Accent
    fill.BorderSizePixel = 0
    
    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((default - 15) / 105, -8, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    local function update(input)
        if track.AbsoluteSize.X == 0 then return end
        local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, -8, 0.5, -8)
        local val = math.floor(15 + 105 * percent)
        valLabel.Text = tostring(val)
        callback(val)
    end
    
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
            isDraggingSlider = true 
            update(i) 
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
            isDraggingSlider = false 
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if isDraggingSlider and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then 
            update(i) 
        end
    end)
    return container
end

local function createButton(text, yPos, callback)
    local btn = Instance.new("TextButton", content)
    btn.Size = UDim2.new(1, -40, 0, 40)
    btn.Position = UDim2.new(0, 20, 0, yPos)
    btn.BackgroundColor3 = THEME.ElementBg
    btn.Text = text
    btn.TextColor3 = THEME.Text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- === НАПОЛНЕНИЕ ===
local renderElements, playerElements, rejoinElements = {}, {}, {}

-- Render Tab
table.insert(renderElements, createToggle("Ultra FPS Boost", false, 10, function(s) _G.FPSBoostActive = s end))
table.insert(renderElements, createToggle("Auto Clear Memory", true, 50, function(s) _G.AutoCleanMemory = s end))
table.insert(renderElements, createToggle("FPS Limit Enable", true, 90, function(s) _G.FPSLimitActive = s; updateFPS() end))
table.insert(renderElements, createSlider("FPS Cap", 60, 130, function(v) _G.CurrentFPS = v; updateFPS() end))

-- Player Tab
table.insert(playerElements, createButton("Teleport: Pine Tree", 10, function()
    pcall(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(-315, 68, -210)
        end
    end)
end))

table.insert(playerElements, createButton("Teleport: Spawn", 60, function()
    pcall(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local spawnLoc = Workspace:FindFirstChildOfClass("SpawnLocation")
            player.Character.HumanoidRootPart.CFrame = CFrame.new(spawnLoc and spawnLoc.Position or Vector3.new(0, 50, 0))
        end
    end)
end))

-- Rejoin Tab
table.insert(rejoinElements, createToggle("Auto Rejoin (Save Server)", true, 10, function(s) _G.AutoRejoin = s end))
table.insert(rejoinElements, createButton("Rejoin Now", 60, function()
    pcall(function()
        if game.JobId and game.JobId ~= "" then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
        end
    end)
end))

for _, v in pairs(playerElements) do v.Visible = false end
for _, v in pairs(rejoinElements) do v.Visible = false end

-- Переключение вкладок
local btnRender = createTab("Render", 15)
local btnPlayer = createTab("Player", 65)
local btnRejoin = createTab("Rejoin", 115)

local function selectTab(act, inact1, inact2, showL, hideL1, hideL2)
    act.BackgroundColor3 = THEME.TabActiveBg; act.TextColor3 = THEME.Text
    inact1.BackgroundColor3 = THEME.Sidebar; inact1.TextColor3 = THEME.TextDim
    inact2.BackgroundColor3 = THEME.Sidebar; inact2.TextColor3 = THEME.TextDim
    
    for _, v in pairs(showL) do v.Visible = true end
    for _, v in pairs(hideL1) do v.Visible = false end
    for _, v in pairs(hideL2) do v.Visible = false end
end

btnRender.MouseButton1Click:Connect(function() selectTab(btnRender, btnPlayer, btnRejoin, renderElements, playerElements, rejoinElements) end)
btnPlayer.MouseButton1Click:Connect(function() selectTab(btnPlayer, btnRender, btnRejoin, playerElements, renderElements, rejoinElements) end)
btnRejoin.MouseButton1Click:Connect(function() selectTab(btnRejoin, btnRender, btnPlayer, rejoinElements, renderElements, playerElements) end)

selectTab(btnRender, btnPlayer, btnRejoin, renderElements, playerElements, rejoinElements)

-- Мини-иконка
local openBtn = Instance.new("TextButton", minGui)
openBtn.Size = UDim2.new(0, 45, 0, 45)
openBtn.Position = UDim2.new(0.5, 0, 0, 30)
openBtn.AnchorPoint = Vector2.new(0.5, 0)
openBtn.BackgroundColor3 = THEME.Bg
openBtn.Text = "LP"
openBtn.TextColor3 = THEME.Accent
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 14
openBtn.Visible = true
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)

makeDraggable(openBtn, function() openBtn.Visible = false; mainFrame.Visible = true end)
minimizeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false; openBtn.Visible = true end)

-- === ФОНОВЫЕ ЦИКЛЫ ===
task.spawn(function()
    while task.wait(45) do
        if _G.AutoCleanMemory then pcall(function() collectgarbage("collect") end) end
    end
end)

task.spawn(function()
    while task.wait(3) do
        if _G.FPSBoostActive then
            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                Lighting.GlobalShadows = false
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v:IsA("BasePart") and not Players:GetPlayerFromCharacter(v:FindFirstAncestorOfClass("Model")) then
                        v.CastShadow = false
                        if v:IsA("MeshPart") then v.TextureID = "" end
                    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then 
                        v.Enabled = false 
                    end
                end
            end)
        end
    end
end)
