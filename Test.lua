-- === Swarm Tweaker: Lite Project (Full Fixed Rejoin) ===

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
while not player do
    task.wait()
    player = Players.LocalPlayer
end

local playerGui = player:WaitForChild("PlayerGui")

-- Очистка старых меню
for _, name in ipairs({
    "LiteProjectUI",
    "LiteProjectMinGui",
    "SwarmTweakerPro",
    "SwarmMinButton",
    "SwarmTweaker"
}) do
    if playerGui:FindFirstChild(name) then
        playerGui[name]:Destroy()
    end
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

-- ============================================================
-- === АВТО-РЕДЖОИН: ЯДРО ===
-- ============================================================

if _G.AutoRejoin == nil then
    _G.AutoRejoin = true
end

if _G.RejoinOnAnyError == nil then
    _G.RejoinOnAnyError = true
end

_G.RejoinErrorCodes = {
    273,
    267,
    287,
    529,
    304,
    319,
    317,
    292,
}

if not _G.LiteProjectRejoinLoaded then
    _G.LiteProjectRejoinLoaded = true

    local GuiService = game:GetService("GuiService")
    local LogService = game:GetService("LogService")

    local REJOIN_FILE = "LiteProject_Server.txt"
    local REJOIN_STATE = {
        busy = false,
        last = 0,
    }

    local memoryServer = {
        placeId = nil,
        jobId = nil,
    }

    local function safeWrite(path, data)
        pcall(function()
            if type(writefile) == "function" then
                writefile(path, data)
            end
        end)
    end

    local function safeRead(path)
        local ok, result = pcall(function()
            if type(readfile) == "function" and type(isfile) == "function" and isfile(path) then
                return readfile(path)
            end
            return nil
        end)

        if ok then
            return result
        end

        return nil
    end

    local function containsErrorCode(text)
        text = tostring(text or "")

        if text == "" then
            return false
        end

        for _, code in ipairs(_G.RejoinErrorCodes or {}) do
            local c = tostring(code)

            -- Ищем код как отдельное число, чтобы не цеплять случайные совпадения
            if
                text:find("%f[%d]" .. c .. "%f[%D]")
                or text:find("%f[%d]" .. c .. "$")
            then
                return true
            end
        end

        return false
    end

    local function getSavedServer()
        -- Сначала используем память, потому что после дисконнекта файл может быть недоступен
        if memoryServer.placeId and memoryServer.jobId and memoryServer.jobId ~= "" then
            return memoryServer.placeId, memoryServer.jobId
        end

        local data = safeRead(REJOIN_FILE)

        if not data then
            return nil, nil
        end

        local placeStr, jobStr = string.match(tostring(data), "^(%d+)|(.*)$")
        local placeId = tonumber(placeStr)

        if placeId and jobStr and jobStr ~= "" then
            return placeId, jobStr
        end

        return nil, nil
    end

    local function saveCurrentServer()
        pcall(function()
            local placeId = game.PlaceId
            local jobId = game.JobId

            if placeId and placeId > 0 and jobId and jobId ~= "" then
                memoryServer.placeId = placeId
                memoryServer.jobId = jobId
                safeWrite(REJOIN_FILE, tostring(placeId) .. "|" .. tostring(jobId))
            end
        end)
    end

    local function shouldRejoin(msg)
        if not _G.AutoRejoin then
            return false
        end

        if _G.RejoinOnAnyError then
            return true
        end

        return containsErrorCode(msg)
    end

    local function doRejoinCore(reason, force)
        reason = tostring(reason or "Unknown")

        if not force and not shouldRejoin(reason) then
            return
        end

        if REJOIN_STATE.busy and not force then
            return
        end

        if not force and tick() - REJOIN_STATE.last < 8 then
            return
        end

        REJOIN_STATE.busy = true
        REJOIN_STATE.last = tick()

        task.spawn(function()
            local attempts = force and 3 or 8

            for attempt = 1, attempts do
                if not force and not _G.AutoRejoin then
                    break
                end

                saveCurrentServer()

                local savedPlace, savedJob = getSavedServer()
                local placeId = savedPlace or game.PlaceId
                local jobId = savedJob or game.JobId

                if placeId and placeId > 0 then
                    -- Первые несколько попыток пробуем вернуться именно в сохранённый сервер.
                    -- Если не выходит, дальше пробуем обычный вход в игру.
                    local useJob = jobId and jobId ~= "" and attempt <= 4

                    local ok = pcall(function()
                        local target = Players.LocalPlayer

                        if target and target.Parent then
                            if useJob then
                                TeleportService:TeleportToPlaceInstance(placeId, jobId, target)
                            else
                                TeleportService:Teleport(placeId, target)
                            end
                        else
                            if useJob then
                                TeleportService:TeleportToPlaceInstance(placeId, jobId)
                            else
                                TeleportService:Teleport(placeId)
                            end
                        end
                    end)

                    if ok then
                        -- Даём телепорту стартовать.
                        task.wait(5)
                        break
                    end
                end

                task.wait(math.clamp(2 + attempt * 2, 2, 12))
            end

            task.delay(8, function()
                REJOIN_STATE.busy = false
            end)
        end)
    end

    _G.LiteProjectDoRejoin = doRejoinCore

    -- Первичное сохранение
    saveCurrentServer()

    -- Сохранение при респавне
    pcall(function()
        player.CharacterAdded:Connect(function()
            saveCurrentServer()
        end)
    end)

    -- Регулярное сохранение сервера
    task.spawn(function()
        while task.wait(10) do
            if _G.AutoRejoin then
                saveCurrentServer()
            end
        end
    end)

    -- 1) Ошибки телепорта
    pcall(function()
        TeleportService.TeleportInitFailed:Connect(function(targetPlayer, result)
            pcall(function()
                if targetPlayer == Players.LocalPlayer then
                    doRejoinCore("TeleportInitFailed:" .. tostring(result), false)
                end
            end)
        end)
    end)

    pcall(function()
        TeleportService.LocalPlayerTeleported:Connect(function(result)
            pcall(function()
                if result ~= Enum.TeleportResult.Success then
                    doRejoinCore("LocalPlayerTeleported:" .. tostring(result), false)
                end
            end)
        end)
    end)

    pcall(function()
        TeleportService.ErrorMessage:Connect(function(msg)
            pcall(function()
                doRejoinCore("TeleportErrorMessage:" .. tostring(msg), false)
            end)
        end)
    end)

    -- 2) Ошибки из клиентского GUI
    pcall(function()
        GuiService.ErrorMessageChanged:Connect(function()
            pcall(function()
                local msg = GuiService.ErrorMessage

                if msg and msg ~= "" then
                    doRejoinCore("GuiError:" .. tostring(msg), false)
                end
            end)
        end)
    end)

    -- Если ошибка уже висит на момент выполнения скрипта
    pcall(function()
        local msg = GuiService.ErrorMessage

        if msg and msg ~= "" then
            doRejoinCore("GuiErrorInitial:" .. tostring(msg), false)
        end
    end)

    -- 3) Ошибки из лога
    pcall(function()
        LogService.MessageOut:Connect(function(message, messageType)
            pcall(function()
                if
                    messageType == Enum.MessageType.MessageError
                    or messageType == Enum.MessageType.MessageWarning
                then
                    local msg = tostring(message)
                    local lower = string.lower(msg)

                    if
                        containsErrorCode(msg)
                        or lower:find("disconnect", 1, true)
                        or lower:find("connection", 1, true)
                        or lower:find("timeout", 1, true)
                    then
                        doRejoinCore("LogError:" .. msg, false)
                    end
                end
            end)
        end)
    end)

    -- 4) Сетевой дисконнект, если сервис доступен
    pcall(function()
        local NetworkClient = game:GetService("NetworkClient")

        NetworkClient.ClientDisconnected:Connect(function(msg)
            pcall(function()
                doRejoinCore("NetworkClientDisconnected:" .. tostring(msg), false)
            end)
        end)
    end)

    -- 5) PlayerDisconnecting, если доступно
    pcall(function()
        Players.PlayerDisconnecting:Connect(function(plr)
            pcall(function()
                if plr == Players.LocalPlayer then
                    doRejoinCore("PlayerDisconnecting", false)
                end
            end)
        end)
    end)

    -- 6) Если локальный игрок вдруг выгружается
    pcall(function()
        player.AncestryChanged:Connect(function()
            pcall(function()
                if not player.Parent then
                    doRejoinCore("LocalPlayerRemoved", false)
                end
            end)
        end)
    end)

    -- 7) Watchdog: если серверное время не обновляется, скорее всего связь отвалилась
    task.spawn(function()
        local lastDistributed = nil
        local lastGood = tick()

        pcall(function()
            lastDistributed = Workspace.DistributedGameTime
        end)

        while task.wait(5) do
            if _G.AutoRejoin then
                local ok, current = pcall(function()
                    return Workspace.DistributedGameTime
                end)

                if ok and current ~= lastDistributed then
                    lastDistributed = current
                    lastGood = tick()
                elseif tick() - lastGood > 75 then
                    doRejoinCore("WatchdogNoServerUpdate", false)
                    lastGood = tick()
                end
            end
        end
    end)

    -- 8) Хук Kick, если твой исполнитель поддерживает такие функции.
    -- Если не нужен или ломает игру — удали этот блок.
    pcall(function()
        if hookmetamethod and getnamecallmethod and checkcaller then
            local oldNamecall

            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                pcall(function()
                    if not checkcaller() then
                        local method = getnamecallmethod()

                        if self == Players.LocalPlayer and (method == "Kick" or method == "kick") then
                            doRejoinCore("PlayerKickHook", false)
                        end
                    end
                end)

                return oldNamecall(self, ...)
            end)
        end
    end)
end

-- Обёртка для интерфейса
local function doRejoin(reason, force)
    if _G.LiteProjectDoRejoin then
        return _G.LiteProjectDoRejoin(reason, force)
    end
end

-- ============================================================
-- === БЕЗОПАСНЫЙ FPS ===
-- ============================================================

local function updateFPS()
    pcall(function()
        if type(setfpscap) == "function" then
            if _G.FPSLimitActive then
                setfpscap(_G.CurrentFPS)
            else
                setfpscap(9999)
            end
        end
    end)
end

updateFPS()

-- ============================================================
-- === ИНТЕРФЕЙС ===
-- ============================================================

local gui = Instance.new("ScreenGui")
gui.Name = "LiteProjectUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = playerGui

local minGui = Instance.new("ScreenGui")
minGui.Name = "LiteProjectMinGui"
minGui.ResetOnSpawn = false
minGui.DisplayOrder = 101
minGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 480, 0, 320)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = THEME.Bg
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = true
mainFrame.Parent = gui

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 8)

-- Драг окна
local function makeDraggable(frame, onTap)
    local dragging, dragInput, dragStart, startPos, maxDist = false, nil, nil, nil, 0

    frame.InputBegan:Connect(function(input)
        if isDraggingSlider then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = UDim2.new(0, frame.AbsolutePosition.X, 0, frame.AbsolutePosition.Y)
            maxDist = 0
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging and not isDraggingSlider then
            local delta = input.Position - dragStart
            if delta.Magnitude > maxDist then
                maxDist = delta.Magnitude
            end

            local vp = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1000, 1000)

            frame.AnchorPoint = Vector2.new(0, 0)
            frame.Position = UDim2.new(
                0,
                math.clamp(startPos.X.Offset + delta.X, 0, vp.X - frame.AbsoluteSize.X),
                0,
                math.clamp(startPos.Y.Offset + delta.Y, 0, vp.Y - frame.AbsoluteSize.Y)
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                dragInput = nil

                if maxDist < 10 and onTap then
                    onTap()
                end
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

-- Отступы
local contentPad = Instance.new("UIPadding", content)
contentPad.PaddingTop = UDim.new(0, 15)
contentPad.PaddingLeft = UDim.new(0, 20)
contentPad.PaddingRight = UDim.new(0, 20)

-- ============================================================
-- === КОМПОНЕНТЫ ===
-- ============================================================

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
    container.Size = UDim2.new(1, 0, 0, 30)
    container.Position = UDim2.new(0, 0, 0, yPos)
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
    toggleBg.Position = UDim2.new(1, -40, 0.5, -12)
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
            TweenService:Create(knob, TweenInfo.new(0.2), {
                Position = UDim2.new(1, -22, 0.5, -10),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
        else
            TweenService:Create(toggleBg, TweenInfo.new(0.2), {BackgroundColor3 = THEME.ToggleOff}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {
                Position = UDim2.new(0, 2, 0.5, -10),
                BackgroundColor3 = Color3.fromRGB(150, 150, 150)
            }):Play()
        end

        if callback then
            callback(isOn)
        end
    end)

    return container
end

local function createSlider(text, default, yPos, callback)
    local container = Instance.new("Frame", content)
    container.Size = UDim2.new(1, 0, 0, 50)
    container.Position = UDim2.new(0, 0, 0, yPos)
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
    track.Size = UDim2.new(1, 0, 0, 20)
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
        if track.AbsoluteSize.X == 0 then
            return
        end

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
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.BackgroundColor3 = THEME.ElementBg
    btn.Text = text
    btn.TextColor3 = THEME.Text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(callback)

    return btn
end

-- ============================================================
-- === НАПОЛНЕНИЕ ===
-- ============================================================

local renderElements, playerElements, rejoinElements = {}, {}, {}

-- Render
table.insert(renderElements, createToggle("Ultra FPS Boost", false, 10, function(s)
    _G.FPSBoostActive = s
end))

table.insert(renderElements, createToggle("Auto Clear Memory", true, 50, function(s)
    _G.AutoCleanMemory = s
end))

table.insert(renderElements, createToggle("FPS Limit Enable", true, 90, function(s)
    _G.FPSLimitActive = s
    updateFPS()
end))

table.insert(renderElements, createSlider("FPS Cap", 60, 130, function(v)
    _G.CurrentFPS = v
    updateFPS()
end))

-- Player
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

-- Rejoin
table.insert(rejoinElements, createToggle("Auto Rejoin", true, 10, function(s)
    _G.AutoRejoin = s
end))

table.insert(rejoinElements, createToggle("Rejoin On Any Error", true, 50, function(s)
    _G.RejoinOnAnyError = s
end))

table.insert(rejoinElements, createButton("Force Rejoin Now", 100, function()
    doRejoin("ManualButton", true)
end))

-- Скрыть неактивные вкладки
for _, v in pairs(playerElements) do
    v.Visible = false
end

for _, v in pairs(rejoinElements) do
    v.Visible = false
end

local btnRender = createTab("Render", 15)
local btnPlayer = createTab("Player", 65)
local btnRejoin = createTab("Rejoin", 115)

local function selectTab(act, inact1, inact2, showL, hideL1, hideL2)
    act.BackgroundColor3 = THEME.TabActiveBg
    act.TextColor3 = THEME.Text

    inact1.BackgroundColor3 = THEME.Sidebar
    inact1.TextColor3 = THEME.TextDim

    inact2.BackgroundColor3 = THEME.Sidebar
    inact2.TextColor3 = THEME.TextDim

    for _, v in pairs(showL) do
        v.Visible = true
    end

    for _, v in pairs(hideL1) do
        v.Visible = false
    end

    for _, v in pairs(hideL2) do
        v.Visible = false
    end
end

btnRender.MouseButton1Click:Connect(function()
    selectTab(btnRender, btnPlayer, btnRejoin, renderElements, playerElements, rejoinElements)
end)

btnPlayer.MouseButton1Click:Connect(function()
    selectTab(btnPlayer, btnRender, btnRejoin, playerElements, renderElements, rejoinElements)
end)

btnRejoin.MouseButton1Click:Connect(function()
    selectTab(btnRejoin, btnRender, btnPlayer, rejoinElements, renderElements, playerElements)
end)

selectTab(btnRender, btnPlayer, btnRejoin, renderElements, playerElements, rejoinElements)

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

makeDraggable(openBtn, function()
    openBtn.Visible = false
    mainFrame.Visible = true
end)

minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    openBtn.Visible = true
end)

-- ============================================================
-- === ФОНОВЫЕ ПРОЦЕССЫ ===
-- ============================================================

task.spawn(function()
    while task.wait(45) do
        if _G.AutoCleanMemory then
            pcall(function()
                collectgarbage("collect")
            end)
        end
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

                        if v:IsA("MeshPart") then
                            v.TextureID = ""
                        end
                    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                        v.Enabled = false
                    end
                end
            end)
        end
    end
end)
