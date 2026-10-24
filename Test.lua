local SRC = [==[
-- ============================================================
-- === Swarm Tweaker: Lite Project v7 (SAFE REJOIN) ===
-- RightShift - скрыть/показать меню
-- ============================================================

-- ВАЖНО: ссылка на этот скрипт (raw), чтобы он сам запускался после перезахода.
-- Если оставить пустым - скрипт попробует прочитать файл "LiteProject.lua"
-- из папки workspace твоего эксплойта (положи туда копию этого скрипта).
local SCRIPT_URL = ""

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
while not player do
    task.wait()
    player = Players.LocalPlayer
end
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- === UNLOAD / ПОВТОРНЫЙ ЗАПУСК ===
-- ============================================================

local OLD_GUIS = {
    "LiteProjectUI", "LiteProjectMinGui", "SwarmTweakerPro", "SwarmMinButton", "SwarmTweaker"
}

local guiParent = playerGui
pcall(function()
    if type(gethui) == "function" then
        guiParent = gethui()
    end
end)

local function destroyOldGuis()
    for _, parent in ipairs({ playerGui, guiParent }) do
        for _, name in ipairs(OLD_GUIS) do
            local old = parent:FindFirstChild(name)
            if old then old:Destroy() end
        end
    end
end

if _G.LiteProjectUnload then
    pcall(_G.LiteProjectUnload)
end
destroyOldGuis()

local alive = true
local conns = {}
local function track(conn)
    conns[#conns + 1] = conn
    return conn
end

-- ============================================================
-- === КОНФИГ (сохраняется в файл) ===
-- ============================================================

local CONFIG_FILE = "LiteProject_Config.json"
local SERVER_FILE = "LiteProject_Server.txt"

local Config = {
    V = 7,
    AutoClean = true,
    FPSLimit = true,
    FPS = 60,
    AutoRejoin = true,
    AnyError = false
}

local function safeWrite(path, data)
    pcall(function()
        if type(writefile) == "function" then writefile(path, data) end
    end)
end

local function safeRead(path)
    local ok, result = pcall(function()
        if type(readfile) == "function" and type(isfile) == "function" and isfile(path) then
            return readfile(path)
        end
        return nil
    end)
    if ok then return result end
    return nil
end

do
    local raw = safeRead(CONFIG_FILE)
    if raw then
        pcall(function()
            local data = HttpService:JSONDecode(raw)
            -- настройки старых версий игнорируем (чтобы применились новые значения по умолчанию)
            if data.V == Config.V then
                for k, v in pairs(data) do
                    if Config[k] ~= nil and type(v) == type(Config[k]) then
                        Config[k] = v
                    end
                end
            end
        end)
    end
end

local saveQueued = false
local function saveConfig()
    if saveQueued then return end
    saveQueued = true
    task.delay(1, function()
        saveQueued = false
        pcall(function()
            safeWrite(CONFIG_FILE, HttpService:JSONEncode(Config))
        end)
    end)
end

local THEME = {
    Bg = Color3.fromRGB(18, 18, 20),
    Sidebar = Color3.fromRGB(14, 14, 16),
    Accent = Color3.fromRGB(232, 121, 249),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(140, 140, 150),
    Border = Color3.fromRGB(45, 45, 50),
    ElementBg = Color3.fromRGB(30, 30, 35),
    Hover = Color3.fromRGB(38, 38, 45),
    Press = Color3.fromRGB(48, 48, 58),
    TabActiveBg = Color3.fromRGB(40, 40, 45),
    ToggleOff = Color3.fromRGB(45, 45, 50),
    Danger = Color3.fromRGB(190, 60, 75),
    DangerHover = Color3.fromRGB(207, 76, 91),
    DangerPress = Color3.fromRGB(160, 48, 62),
    Good = Color3.fromRGB(110, 220, 130),
    Warn = Color3.fromRGB(240, 200, 90),
    Bad = Color3.fromRGB(240, 100, 100)
}

local isDraggingSlider = false
local statusLabel = nil
local notify = function() end

local function setStatus(text)
    if statusLabel and statusLabel.Parent then
        statusLabel.Text = "Status: " .. tostring(text)
    end
end

-- ============================================================
-- === SAFE REJOIN CORE ===
-- ============================================================

local ERROR_CODES = { 273, 267, 287, 529, 304, 319, 317, 292, 277, 279, 266, 288 }

local REJOIN = { busy = false, last = 0, armed = false }
local memoryServer = { placeId = nil, jobId = nil }

local function containsErrorCode(text)
    text = tostring(text or "")
    if text == "" then return false end
    for _, code in ipairs(ERROR_CODES) do
        if text:find("%f[%d]" .. tostring(code) .. "%f[%D]") then
            return true
        end
    end
    return false
end

local function isRealErrorText(text)
    text = tostring(text or "")
    if text == "" then return false end
    if containsErrorCode(text) then return true end

    local lower = string.lower(text)
    local patterns = {
        "disconnect", "connection lost", "lost connection", "network",
        "timeout", "timed out", "kicked", "shut down", "shutting down",
        "error code", "cannot join", "join request failed", "reconnect"
    }
    for _, p in ipairs(patterns) do
        if lower:find(p, 1, true) then return true end
    end
    return false
end

local function saveCurrentServer()
    pcall(function()
        local placeId, jobId = game.PlaceId, game.JobId
        if placeId and placeId > 0 and jobId and jobId ~= "" then
            memoryServer.placeId = placeId
            memoryServer.jobId = jobId
            safeWrite(SERVER_FILE, tostring(placeId) .. "|" .. tostring(jobId))
        end
    end)
end

local function getSavedServer()
    if memoryServer.placeId and memoryServer.jobId and memoryServer.jobId ~= "" then
        return memoryServer.placeId, memoryServer.jobId
    end
    local data = safeRead(SERVER_FILE)
    if data then
        local placeStr, jobStr = string.match(tostring(data), "^(%d+)|(.*)$")
        local placeId = tonumber(placeStr)
        if placeId and jobStr and jobStr ~= "" then
            return placeId, jobStr
        end
    end
    return nil, nil
end

local function canReexecute()
    local q = queue_on_teleport or (syn and syn.queue_on_teleport)
    if type(q) ~= "function" then return false, "queue_on_teleport not supported" end
    if SCRIPT_URL ~= "" then return true, "from SCRIPT_URL" end
    if safeRead("LiteProject.lua") then return true, "from LiteProject.lua" end
    return false, "set SCRIPT_URL or save LiteProject.lua"
end

-- Запуск скрипта заново после телепорта
local function queueReexecute()
    local q = queue_on_teleport or (syn and syn.queue_on_teleport)
    if type(q) ~= "function" then return end

    local code
    if SCRIPT_URL ~= "" then
        code = ('loadstring(game:HttpGet("%s"))()'):format(SCRIPT_URL)
    else
        code = [[
            local ok, src = pcall(function() return readfile("LiteProject.lua") end)
            if ok and src then loadstring(src)() end
        ]]
    end
    pcall(q, code)
end

local function doRejoinCore(reason, force, trusted)
    reason = tostring(reason or "Unknown")

    if not force then
        if not Config.AutoRejoin then return end
        if not REJOIN.armed then return end
        if not trusted and not Config.AnyError and not isRealErrorText(reason) then return end
    end

    if REJOIN.busy and not force then return end
    if not force and tick() - REJOIN.last < 12 then return end

    REJOIN.busy = true
    REJOIN.last = tick()

    setStatus("rejoining (" .. reason:sub(1, 40) .. ")")
    notify("Rejoining...")
    queueReexecute()

    task.spawn(function()
        local attempts = force and 3 or 6

        for attempt = 1, attempts do
            if not force and not Config.AutoRejoin then break end

            saveCurrentServer()
            local savedPlace, savedJob = getSavedServer()
            local placeId = savedPlace or game.PlaceId
            local jobId = savedJob or game.JobId

            if placeId and placeId > 0 then
                -- первые 2 попытки: тот же сервер, потом любой другой
                local useJob = jobId and jobId ~= "" and attempt <= 2

                local ok = pcall(function()
                    if useJob then
                        TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
                    else
                        TeleportService:Teleport(placeId, player)
                    end
                end)

                if ok then
                    task.wait(12) -- если телепорт прошёл, игра закроется сама
                else
                    task.wait(math.clamp(2 + attempt, 2, 8))
                end
            else
                task.wait(3)
            end
        end

        setStatus("rejoin failed, watching again")
        task.delay(8, function()
            REJOIN.busy = false
        end)
    end)
end

_G.LiteProjectDoRejoin = doRejoinCore

local function doRejoin(reason, force, trusted)
    return doRejoinCore(reason, force, trusted)
end

-- Включаем авто-перезаход через 20 сек после загрузки (против ложных срабатываний)
task.spawn(function()
    pcall(function()
        if not game:IsLoaded() then game.Loaded:Wait() end
    end)
    task.wait(20)
    if alive then
        REJOIN.armed = true
        setStatus("armed, watching for disconnects")
    end
end)

saveCurrentServer()
track(player.CharacterAdded:Connect(saveCurrentServer))
task.spawn(function()
    while alive and task.wait(10) do
        if Config.AutoRejoin then saveCurrentServer() end
    end
end)

-- 1) Ошибка телепорта
pcall(function()
    track(TeleportService.TeleportInitFailed:Connect(function(targetPlayer)
        if targetPlayer == player then
            doRejoinCore("TeleportInitFailed", false, true)
        end
    end))
end)

-- 2) Сообщение об ошибке в GuiService
pcall(function()
    track(GuiService.ErrorMessageChanged:Connect(function()
        local msg, code = "", 0
        pcall(function() msg = GuiService:GetErrorMessage() end)
        pcall(function() code = GuiService:GetErrorCode().Value end)
        msg = tostring(msg or "")

        if msg == "" and code == 0 then return end

        local trusted = containsErrorCode(tostring(code))
        doRejoinCore("GuiError:" .. tostring(code) .. " " .. msg, false, trusted)
    end))
end)

-- 3) Окно ошибки Roblox (самый надёжный способ)
task.spawn(function()
    local ok, overlay = pcall(function()
        return CoreGui:WaitForChild("RobloxPromptGui", 20):WaitForChild("promptOverlay", 20)
    end)
    if ok and overlay then
        track(overlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" then
                task.wait(1)
                local text = ""
                pcall(function()
                    for _, d in ipairs(child:GetDescendants()) do
                        if d:IsA("TextLabel") and d.Text ~= "" then
                            text = text .. " " .. d.Text
                        end
                    end
                end)
                doRejoinCore("ErrorPrompt:" .. text, false, true)
            end
        end))
    end
end)

-- 4) Kick hook (если поддерживается эксплойтом), ставится один раз за сессию
pcall(function()
    if _G.LP_KickHooked then return end
    if hookmetamethod and getnamecallmethod and checkcaller then
        _G.LP_KickHooked = true
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            pcall(function()
                if not checkcaller() and self == Players.LocalPlayer then
                    local method = getnamecallmethod()
                    if method == "Kick" or method == "kick" then
                        if _G.LiteProjectDoRejoin then
                            _G.LiteProjectDoRejoin("KickHook", false, true)
                        end
                    end
                end
            end)
            return oldNamecall(self, ...)
        end)
    end
end)

-- ============================================================
-- === FPS LIMIT / MEMORY ===
-- ============================================================

local function updateFPS()
    pcall(function()
        if type(setfpscap) == "function" then
            if Config.FPSLimit then
                setfpscap(Config.FPS)
            else
                setfpscap(9999)
            end
        end
    end)
end

task.spawn(function()
    while alive and task.wait(45) do
        if Config.AutoClean then
            pcall(function() collectgarbage("collect") end)
        end
    end
end)

-- ============================================================
-- === UI ===
-- ============================================================

local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end

local function corner(obj, r)
    return mk("UICorner", { CornerRadius = UDim.new(0, r or 10) }, obj)
end

local function tw(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

-- Отклик на нажатие: элемент слегка "вдавливается" и меняет цвет.
-- hit - то, что ловит нажатие, target - то, что анимируется.
-- Цвета можно не передавать (тогда будет только эффект масштаба).
local function addPressFx(hit, target, baseColor, hoverColor, pressColor)
    local sc = target:FindFirstChildOfClass("UIScale") or mk("UIScale", { Scale = 1 }, target)
    local pressed = false

    hit.InputBegan:Connect(function(input)
        if isPress(input) then
            pressed = true
            tw(sc, 0.07, { Scale = 0.96 })
            if pressColor then tw(target, 0.07, { BackgroundColor3 = pressColor }) end
        elseif input.UserInputType == Enum.UserInputType.MouseMovement and hoverColor and not pressed then
            tw(target, 0.12, { BackgroundColor3 = hoverColor })
        end
    end)

    hit.InputEnded:Connect(function(input)
        if isPress(input) then
            pressed = false
            tw(sc, 0.14, { Scale = 1 })
            if baseColor then tw(target, 0.14, { BackgroundColor3 = baseColor }) end
        elseif input.UserInputType == Enum.UserInputType.MouseMovement and baseColor and not pressed then
            tw(target, 0.12, { BackgroundColor3 = baseColor })
        end
    end)
end

local gui = mk("ScreenGui", {
    Name = "LiteProjectUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999
}, guiParent)

-- Уведомления
local lastToast = nil
notify = function(text)
    if not gui.Parent then return end
    if lastToast then lastToast:Destroy() end

    local toast = mk("TextLabel", {
        Size = UDim2.fromOffset(250, 38),
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 270, 1, -16),
        BackgroundColor3 = THEME.ElementBg,
        BorderSizePixel = 0,
        Text = tostring(text),
        TextColor3 = THEME.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12
    }, gui)
    corner(toast, 12)
    mk("UIStroke", { Color = THEME.Accent, Thickness = 1 }, toast)
    lastToast = toast

    tw(toast, 0.25, { Position = UDim2.new(1, -16, 1, -16) })

    task.delay(3, function()
        if toast.Parent then
            local t = TweenService:Create(toast, TweenInfo.new(0.25), {
                Position = UDim2.new(1, 270, 1, -16)
            })
            t:Play()
            t.Completed:Wait()
            toast:Destroy()
        end
    end)
end

local main = mk("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(520, 340),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundColor3 = THEME.Bg,
    BorderSizePixel = 0,
    Visible = false
}, gui)
corner(main, 18)
mk("UIStroke", { Color = THEME.Border, Thickness = 1 }, main)
local mainScale = mk("UIScale", { Scale = 1 }, main)

local openBtn = mk("TextButton", {
    Name = "LiteProjectMinGui",
    Size = UDim2.fromOffset(48, 48),
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 30),
    BackgroundColor3 = THEME.Bg,
    Text = "LP",
    TextColor3 = THEME.Accent,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    AutoButtonColor = false,
    Visible = true
}, gui)
corner(openBtn, 24)
mk("UIStroke", { Color = THEME.Accent, Thickness = 1.5 }, openBtn)
addPressFx(openBtn, openBtn)

local function showMain(show)
    main.Visible = show
    openBtn.Visible = not show
    if show then
        mainScale.Scale = 0.92
        tw(mainScale, 0.18, { Scale = 1 })
    end
end

-- Перетаскивание (с поддержкой "тапа")
local function makeDraggable(handle, target, onTap)
    local dragging, dragStart, startPos, moved = false, nil, nil, 0

    handle.InputBegan:Connect(function(input)
        if isDraggingSlider then return end
        if isPress(input) then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            moved = 0
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if dragging and moved < 8 and onTap then onTap() end
                    dragging = false
                end
            end)
        end
    end)

    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and not isDraggingSlider
            and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            if d.Magnitude > moved then moved = d.Magnitude end
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end))
end

-- Все панели лежат внутри главного окна с отступом 10px, поэтому
-- скруглённые углы нигде не обрезаются и не торчат за края окна.
local topBar = mk("Frame", {
    Size = UDim2.new(1, -20, 0, 44),
    Position = UDim2.fromOffset(10, 10),
    BackgroundColor3 = THEME.Sidebar,
    BorderSizePixel = 0
}, main)
corner(topBar, 14)
mk("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(14, 14, 16), Color3.fromRGB(52, 26, 60)),
    Rotation = 0
}, topBar)

mk("TextLabel", {
    Size = UDim2.new(1, -220, 0, 20),
    Position = UDim2.fromOffset(16, 5),
    BackgroundTransparency = 1,
    Text = "★ Lite Project",
    TextColor3 = THEME.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left
}, topBar)

mk("TextLabel", {
    Size = UDim2.new(1, -220, 0, 14),
    Position = UDim2.fromOffset(16, 24),
    BackgroundTransparency = 1,
    Text = "Made for low-end devices",
    TextColor3 = THEME.TextDim,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left
}, topBar)

-- Живой счётчик FPS
local fpsPill = mk("Frame", {
    Size = UDim2.fromOffset(76, 26),
    Position = UDim2.new(1, -132, 0.5, -13),
    BackgroundColor3 = THEME.Bg,
    BorderSizePixel = 0
}, topBar)
corner(fpsPill, 13)
mk("UIStroke", { Color = THEME.Border, Thickness = 1 }, fpsPill)

local fpsLabel = mk("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "-- FPS",
    TextColor3 = THEME.Good,
    Font = Enum.Font.GothamBold,
    TextSize = 12
}, fpsPill)

do
    local frames, last = 0, os.clock()
    track(RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = os.clock()
        if now - last >= 0.5 then
            if main.Visible then
                local fps = math.floor(frames / (now - last) + 0.5)
                fpsLabel.Text = fps .. " FPS"
                fpsLabel.TextColor3 = fps >= 50 and THEME.Good or (fps >= 30 and THEME.Warn or THEME.Bad)
            end
            frames, last = 0, now
        end
    end))
end

local minimizeBtn = mk("TextButton", {
    Size = UDim2.fromOffset(32, 32),
    Position = UDim2.new(1, -42, 0.5, -16),
    BackgroundColor3 = THEME.ElementBg,
    Text = "–",
    TextColor3 = THEME.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    AutoButtonColor = false
}, topBar)
corner(minimizeBtn, 10)
addPressFx(minimizeBtn, minimizeBtn, THEME.ElementBg, THEME.Hover, THEME.Press)

makeDraggable(topBar, main)
makeDraggable(openBtn, openBtn, function() showMain(true) end)

minimizeBtn.Activated:Connect(function() showMain(false) end)

track(UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightShift and gui.Parent then
        showMain(not main.Visible)
    end
end))

-- Боковая панель + контент
local sidebar = mk("Frame", {
    Size = UDim2.new(0, 124, 1, -74),
    Position = UDim2.fromOffset(10, 64),
    BackgroundColor3 = THEME.Sidebar,
    BorderSizePixel = 0
}, main)
corner(sidebar, 14)
mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
mk("UIPadding", {
    PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)
}, sidebar)

local content = mk("Frame", {
    Size = UDim2.new(1, -144, 1, -74),
    Position = UDim2.fromOffset(140, 64),
    BackgroundTransparency = 1
}, main)

local pages, tabButtons = {}, {}

local function selectTab(name)
    for n, page in pairs(pages) do
        page.Visible = (n == name)
    end
    for n, btn in pairs(tabButtons) do
        local active = (n == name)
        tw(btn, 0.15, {
            BackgroundColor3 = active and THEME.TabActiveBg or THEME.Sidebar,
            TextColor3 = active and THEME.Text or THEME.TextDim
        })
        btn:FindFirstChild("Bar").Visible = active
    end
end

local function createTab(name, order)
    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = THEME.Sidebar,
        BorderSizePixel = 0,
        Text = "   " .. name,
        TextColor3 = THEME.TextDim,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        LayoutOrder = order
    }, sidebar)
    corner(btn, 10)
    addPressFx(btn, btn)

    local bar = mk("Frame", {
        Name = "Bar",
        Size = UDim2.fromOffset(3, 18),
        Position = UDim2.new(0, 4, 0.5, -9),
        BackgroundColor3 = THEME.Accent,
        BorderSizePixel = 0,
        Visible = false
    }, btn)
    corner(bar, 2)

    local page = mk("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = THEME.Accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    }, content)
    mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    mk("UIPadding", {
        PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)
    }, page)

    pages[name] = page
    tabButtons[name] = btn
    btn.Activated:Connect(function() selectTab(name) end)
    return page
end

local function addSection(page, text)
    return mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = string.upper(text),
        TextColor3 = THEME.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left
    }, page)
end

local function addLabel(page, text)
    return mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = THEME.TextDim,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left
    }, page)
end

-- Переключатель: нажимается вся строка целиком, а не только маленький тумблер
local function addToggle(page, text, key, desc, callback)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, desc and 56 or 44),
        BackgroundColor3 = THEME.ElementBg,
        BorderSizePixel = 0
    }, page)
    corner(row, 12)

    mk("TextLabel", {
        Size = UDim2.new(1, -76, 0, 20),
        Position = UDim2.fromOffset(14, desc and 9 or 12),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = THEME.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)

    if desc then
        mk("TextLabel", {
            Size = UDim2.new(1, -76, 0, 16),
            Position = UDim2.fromOffset(14, 29),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = THEME.TextDim,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left
        }, row)
    end

    local sw = mk("Frame", {
        Size = UDim2.fromOffset(44, 24),
        Position = UDim2.new(1, -58, 0.5, -12),
        BorderSizePixel = 0,
        BackgroundColor3 = Config[key] and THEME.Accent or THEME.ToggleOff
    }, row)
    corner(sw, 12)

    local knob = mk("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = Config[key] and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
        BackgroundColor3 = Config[key] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150),
        BorderSizePixel = 0
    }, sw)
    corner(knob, 9)

    local hit = mk("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5
    }, row)
    addPressFx(hit, row, THEME.ElementBg, THEME.Hover, THEME.Press)

    hit.Activated:Connect(function()
        Config[key] = not Config[key]
        local on = Config[key]

        tw(sw, 0.18, { BackgroundColor3 = on and THEME.Accent or THEME.ToggleOff })
        tw(knob, 0.18, {
            Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
        })

        saveConfig()
        if callback then callback(on) end
    end)

    return row
end

local function addSlider(page, text, min, max, key, callback)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 66),
        BackgroundColor3 = THEME.ElementBg,
        BorderSizePixel = 0
    }, page)
    corner(row, 12)

    mk("TextLabel", {
        Size = UDim2.new(1, -90, 0, 20),
        Position = UDim2.fromOffset(14, 8),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = THEME.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)

    local valLabel = mk("TextLabel", {
        Size = UDim2.fromOffset(60, 20),
        Position = UDim2.new(1, -74, 0, 8),
        BackgroundTransparency = 1,
        Text = tostring(Config[key]),
        TextColor3 = THEME.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right
    }, row)

    -- большая зона нажатия, чтобы удобно попадать пальцем
    local hit = mk("TextButton", {
        Size = UDim2.new(1, -28, 0, 32),
        Position = UDim2.fromOffset(14, 28),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false
    }, row)

    local bg = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0.5, -3),
        BackgroundColor3 = THEME.ToggleOff,
        BorderSizePixel = 0
    }, hit)
    corner(bg, 3)

    local rel0 = (Config[key] - min) / (max - min)
    local fill = mk("Frame", {
        Size = UDim2.fromScale(rel0, 1),
        BackgroundColor3 = THEME.Accent,
        BorderSizePixel = 0
    }, bg)
    corner(fill, 3)

    local knob = mk("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(rel0, -9, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0
    }, hit)
    corner(knob, 9)
    local knobScale = mk("UIScale", { Scale = 1 }, knob)

    local dragging = false

    local function setFromX(x)
        if bg.AbsoluteSize.X <= 0 then return end
        local rel = math.clamp((x - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * rel + 0.5)
        Config[key] = value
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.new(rel, -9, 0.5, -9)
        valLabel.Text = tostring(value)
        if callback then callback(value) end
    end

    local function setValue(value)
        value = math.clamp(math.floor(value), min, max)
        Config[key] = value
        local rel = (value - min) / (max - min)
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.new(rel, -9, 0.5, -9)
        valLabel.Text = tostring(value)
    end

    hit.InputBegan:Connect(function(input)
        if isPress(input) then
            dragging = true
            isDraggingSlider = true
            tw(knobScale, 0.1, { Scale = 1.25 })
            setFromX(input.Position.X)
        end
    end)

    track(UserInputService.InputChanged:Connect(function(input)
        if dragging
            and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end))

    track(UserInputService.InputEnded:Connect(function(input)
        if dragging and isPress(input) then
            dragging = false
            isDraggingSlider = false
            tw(knobScale, 0.12, { Scale = 1 })
            saveConfig()
        end
    end))

    return row, setValue
end

-- Быстрые кнопки-значения (чипы)
local function addChips(page, values, labels, onPick, getCurrent)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1
    }, page)
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, row)

    local chips = {}
    local function refresh()
        for v, b in pairs(chips) do
            local on = (getCurrent() == v)
            tw(b, 0.12, {
                BackgroundColor3 = on and THEME.Accent or THEME.ElementBg,
                TextColor3 = on and Color3.fromRGB(20, 20, 24) or THEME.Text
            })
        end
    end

    local n = #values
    for i, v in ipairs(values) do
        local b = mk("TextButton", {
            Size = UDim2.new(1 / n, -6 * (n - 1) / n, 1, 0),
            BackgroundColor3 = THEME.ElementBg,
            BorderSizePixel = 0,
            Text = labels[i],
            TextColor3 = THEME.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            AutoButtonColor = false,
            LayoutOrder = i
        }, row)
        corner(b, 10)
        addPressFx(b, b)
        chips[v] = b
        b.Activated:Connect(function()
            onPick(v)
            refresh()
        end)
    end

    refresh()
    return refresh
end

local function addButton(page, text, callback, danger)
    local base = danger and THEME.Danger or THEME.ElementBg
    local hover = danger and THEME.DangerHover or THEME.Hover
    local press = danger and THEME.DangerPress or THEME.Press

    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = base,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = THEME.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        AutoButtonColor = false
    }, page)
    corner(btn, 12)
    addPressFx(btn, btn, base, hover, press)
    btn.Activated:Connect(callback)
    return btn
end

local function addGrid(page)
    local frame = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1
    }, page)
    mk("UIGridLayout", {
        CellSize = UDim2.new(0.5, -4, 0, 36),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, frame)
    return frame
end

-- ============================================================
-- === ВКЛАДКИ ===
-- ============================================================

-- RENDER
local renderPage = createTab("Render", 1)
addSection(renderPage, "Memory")
addToggle(renderPage, "Auto Clear Memory", "AutoClean", "Очистка мусора каждые 45 сек")
addSection(renderPage, "Frame rate")
addToggle(renderPage, "FPS Limit", "FPSLimit", "Выключи, чтобы снять ограничение", function() updateFPS() end)
local refreshChips = function() end
local _, setFPSSlider = addSlider(renderPage, "FPS Cap", 15, 240, "FPS", function()
    updateFPS()
    refreshChips()
end)
refreshChips = addChips(renderPage, { 30, 60, 90, 120, 240 }, { "30", "60", "90", "120", "MAX" }, function(v)
    setFPSSlider(v)
    saveConfig()
    updateFPS()
end, function() return Config.FPS end)
if type(setfpscap) ~= "function" then
    addLabel(renderPage, "Твой эксплойт не поддерживает setfpscap - лимит FPS не будет работать.")
end

-- PLAYER
local playerPage = createTab("Player", 2)

local function getRoot()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

addSection(playerPage, "Teleport")
addButton(playerPage, "Teleport: My Hive", function()
    local root = getRoot()
    if not root then notify("Character not found") return end

    local target
    pcall(function()
        local sp = player:FindFirstChild("SpawnPos")
        if sp and typeof(sp.Value) == "CFrame" then
            target = sp.Value + Vector3.new(0, 5, 0)
        end
    end)
    if not target then
        local spawnLoc = Workspace:FindFirstChildOfClass("SpawnLocation")
        if spawnLoc then target = spawnLoc.CFrame + Vector3.new(0, 5, 0) end
    end

    if target then
        root.CFrame = target
        notify("Teleported to hive")
    else
        notify("Hive position not found")
    end
end)

addSection(playerPage, "Fields")
local fieldsInfo = addLabel(playerPage, "Loading fields...")
local fieldsGrid = addGrid(playerPage)

task.spawn(function()
    local zones = Workspace:WaitForChild("FlowerZones", 10)
    if not zones then
        fieldsInfo.Text = "FlowerZones not found (это не Bee Swarm Simulator?)"
        return
    end

    local list = {}
    local hidden = {
        ["ant field"] = true, ["blue brick"] = true, ["hub"] = true,
        ["mixed brick"] = true, ["red brick"] = true, ["white brick"] = true
    }
    for _, z in ipairs(zones:GetChildren()) do
        local lname = string.lower(z.Name)
        if z:IsA("BasePart") and not hidden[lname] and not lname:find("brick", 1, true) then
            list[#list + 1] = z
        end
    end
    table.sort(list, function(a, b) return a.Name < b.Name end)

    fieldsInfo.Text = "Tap a field to teleport (" .. #list .. ")"

    for i, zone in ipairs(list) do
        local btn = mk("TextButton", {
            BackgroundColor3 = THEME.ElementBg,
            BorderSizePixel = 0,
            Text = zone.Name,
            TextColor3 = THEME.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextTruncate = Enum.TextTruncate.AtEnd,
            AutoButtonColor = false,
            LayoutOrder = i
        }, fieldsGrid)
        corner(btn, 10)
        addPressFx(btn, btn, THEME.ElementBg, THEME.Hover, THEME.Press)
        btn.Activated:Connect(function()
            local root = getRoot()
            if root and zone.Parent then
                root.CFrame = zone.CFrame + Vector3.new(0, 5, 0)
                notify("→ " .. zone.Name)
            else
                notify("Can't teleport right now")
            end
        end)
    end
end)

-- REJOIN
local rejoinPage = createTab("Rejoin", 3)
addSection(rejoinPage, "Auto rejoin")
addToggle(rejoinPage, "Auto Rejoin", "AutoRejoin", "Перезаход при дисконнекте/кике")
addToggle(rejoinPage, "Any Error (risky)", "AnyError", "Любая ошибка - возможны ложные срабатывания")
statusLabel = addLabel(rejoinPage, "Status: waiting 20s to arm...")
if REJOIN.armed then setStatus("armed, watching for disconnects") end

do
    local ok, how = canReexecute()
    addLabel(rejoinPage, "Auto re-run after rejoin: " .. (ok and ("ON (" .. how .. ")") or ("OFF (" .. how .. ")")))
end

addSection(rejoinPage, "Actions")
addButton(rejoinPage, "Force Rejoin Now", function()
    doRejoin("ManualButton", true, true)
end)
addButton(rejoinPage, "Copy Server JobId", function()
    if type(setclipboard) == "function" then
        setclipboard(game.JobId)
        notify("JobId copied")
    else
        notify("setclipboard not supported")
    end
end)

-- INFO
local infoPage = createTab("Info", 4)
addSection(infoPage, "About")
addLabel(infoPage, "Swarm Tweaker: Lite Project v7\nМеню: RightShift. Настройки сохраняются в LiteProject_Config.json.")
addSection(infoPage, "Control")
addButton(infoPage, "Save Config Now", function()
    safeWrite(CONFIG_FILE, HttpService:JSONEncode(Config))
    notify("Config saved")
end)
addButton(infoPage, "Unload Script", function()
    if _G.LiteProjectUnload then _G.LiteProjectUnload() end
end, true)

selectTab("Render")

-- ============================================================
-- === UNLOAD ===
-- ============================================================

_G.LiteProjectUnload = function()
    alive = false
    for _, c in ipairs(conns) do
        pcall(function() c:Disconnect() end)
    end
    pcall(function() setfpscap(0) end)
    destroyOldGuis()
    _G.LiteProjectDoRejoin = nil
end

-- ============================================================
-- === СТАРТ ===
-- ============================================================

updateFPS()

task.defer(function()
    notify("Lite Project loaded - RightShift to toggle")
end)

print("[Swarm Tweaker Lite v7] loaded. RightShift - hide/show menu.")

]==]
pcall(function() writefile("LiteProject.lua", SRC) end)
local fn, err = loadstring(SRC)
if fn then fn() else warn("LiteProject load error: " .. tostring(err)) end
