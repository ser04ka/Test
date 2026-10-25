local SRC = [==[
-- ============================================================
-- === Lite Project ===
-- RightShift - скрыть/показать меню
-- ============================================================

-- ВАЖНО: ссылка на этот скрипт (raw), чтобы он сам запускался после перезахода.
-- Если оставить пустым - скрипт попробует прочитать файл "LiteProject.lua"
-- из папки workspace твоего эксплойта (положи туда копию этого скрипта).
local SCRIPT_URL = ""

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
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
    V = 4,
    FPSBoost = true,
    HideBees = true,
    HideTokens = true,
    HideDecor = true,
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
    TabActiveBg = Color3.fromRGB(40, 40, 45),
    ToggleOff = Color3.fromRGB(45, 45, 50),
    Danger = Color3.fromRGB(190, 60, 75),
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

    setStatus("rejoining: " .. reason:sub(1, 40))
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


-- ============================================================
-- === FPS BOOST (с полным восстановлением) ===
-- ============================================================

local boost = {
    parts = setmetatable({}, { __mode = "k" }),
    fx = setmetatable({}, { __mode = "k" }),
    light = nil,
    quality = nil,
    conn = nil,
    token = 0,
    restoring = false,
    hide = setmetatable({}, { __mode = "k" }),
    names = {},
    dnames = {},
    deleted = 0,
    underY = nil
}

local FX_CLASSES = {
    ParticleEmitter = true, Trail = true, Beam = true,
    Smoke = true, Fire = true, Sparkles = true,
    PointLight = true, SpotLight = true, SurfaceLight = true,
    Clouds = true, Highlight = true
}

-- Нарезка работы по времени: не фризит даже слабое устройство
local function newSlicer()
    local t0 = os.clock()
    return function()
        if os.clock() - t0 > 0.006 then
            task.wait()
            t0 = os.clock()
        end
    end
end
local POST_CLASSES = {
    BlurEffect = true, SunRaysEffect = true, ColorCorrectionEffect = true,
    BloomEffect = true, DepthOfFieldEffect = true
}

local function inCharacter(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    return model ~= nil and Players:GetPlayerFromCharacter(model) ~= nil
end

-- Правила скрытия по названиям объектов (подстроки в нижнем регистре).
-- Объекты НЕ удаляются, а скрываются (Transparency = 1) - это безопасно:
-- токены остаются собираемыми, ничего не ломается, а при выключении всё возвращается.
local HIDE_RULES = {
    { flag = "HideBees", include = { "bee" },
      exclude = { "bear", "honey", "hive", "shop", "store", "spawn" } },
    { flag = "HideTokens", include = { "collectible" }, exclude = {} },
    { flag = "HideDecor",
      include = {
          "bubble", "particle", "tree", "cactus", "pumpkin", "strawberr", "clover",
          "web", "bush", "bamboo", "pineapple", "pepper", "sunflower", "coconut",
          "palm", "rose", "frog", "fence", "flower", "grass"
      },
      exclude = { "crab" } }
}
local SKIP_NAMES = {
    part = true, meshpart = true, union = true, model = true,
    folder = true, handle = true, mesh = true
}

local function nameHidesRaw(name)
    local n = string.lower(name)
    if SKIP_NAMES[n] then return false end
    for _, rule in ipairs(HIDE_RULES) do
        if Config[rule.flag] then
            local blocked = false
            for _, x in ipairs(rule.exclude) do
                if n:find(x, 1, true) then
                    blocked = true
                    break
                end
            end
            if not blocked then
                for _, k in ipairs(rule.include) do
                    if n:find(k, 1, true) then return true end
                end
            end
        end
    end
    return false
end

local function nameHides(name)
    local c = boost.names[name]
    if c == nil then
        c = nameHidesRaw(name)
        boost.names[name] = c
    end
    return c
end

-- true, если сам объект или любой его родитель подходит под правила
-- (персонажи игроков никогда не скрываются). Результаты кэшируются.
local function hiddenByName(inst)
    local cache = boost.hide
    local chain, hit, n = {}, {}, 0
    local base, isChar = false, false
    local cur = inst

    while cur and cur ~= Workspace do
        local c = cache[cur]
        if c ~= nil then
            if c == "char" then isChar = true else base = c end
            break
        end
        if cur:IsA("Model") and Players:GetPlayerFromCharacter(cur) then
            cache[cur] = "char"
            isChar = true
            break
        end
        n = n + 1
        chain[n] = cur
        hit[n] = nameHides(cur.Name)
        cur = cur.Parent
    end

    local val = (not isChar) and base or false
    for i = n, 1, -1 do
        if isChar then
            val = false
        else
            val = val or hit[i]
        end
        cache[chain[i]] = val
    end
    return val
end

-- Всё, что целиком находится глубоко под картой
local function computeUnderY()
    local zones = Workspace:FindFirstChild("FlowerZones")
    if not zones then return nil end
    local minY = nil
    for _, z in ipairs(zones:GetChildren()) do
        if z:IsA("BasePart") then
            local y = z.Position.Y
            if minY == nil or y < minY then minY = y end
        end
    end
    if minY then return minY - 60 end
    return nil
end

local function underMap(part)
    local y = boost.underY
    if not y then return false end
    local ok, res = pcall(function()
        return part.Position.Y + part.Size.Y * 0.5 < y
    end)
    return ok and res and not inCharacter(part)
end

-- ============================================================
-- Реальное УДАЛЕНИЕ декора (деревья, кусты, цветы, заборы и т.д.)
-- Удалённое возвращается только после перезахода на сервер.
-- ============================================================
local DELETE_KEYS = {
    "tree", "cactus", "pumpkin", "strawberr", "clover", "web", "bush", "bamboo",
    "pineapple", "pepper", "sunflower", "coconut", "palm", "rose", "frog",
    "fence", "flower", "grass"
}
local DELETE_EXCLUDE = { "crab", "zone", "street" }

-- Контейнеры, внутри которых ничего не удаляем (игровая логика)
local PROTECTED_ANCESTORS = {
    "FlowerZones", "Collectibles", "Particles", "Honeycombs", "NPCs", "Monsters", "MonsterSpawners"
}

local function decorNameMatches(name)
    local c = boost.dnames[name]
    if c ~= nil then return c end

    local n = string.lower(name)
    local res = false
    if not SKIP_NAMES[n] then
        local blocked = false
        for _, x in ipairs(DELETE_EXCLUDE) do
            if n:find(x, 1, true) then
                blocked = true
                break
            end
        end
        if not blocked then
            for _, k in ipairs(DELETE_KEYS) do
                if n:find(k, 1, true) then
                    res = true
                    break
                end
            end
        end
    end
    boost.dnames[name] = res
    return res
end

local function isProtected(obj)
    for _, name in ipairs(PROTECTED_ANCESTORS) do
        if obj.Name == name or obj:FindFirstAncestor(name) then return true end
    end
    if Players:GetPlayerFromCharacter(obj) or inCharacter(obj) then return true end
    for _, pl in ipairs(Players:GetPlayers()) do
        local c = pl.Character
        if c and (obj == c or obj:IsAncestorOf(c)) then return true end
    end
    -- NPC, монстры и всё, где есть Humanoid
    if obj:IsA("Model") or obj:IsA("Folder") then
        if obj:FindFirstChildWhichIsA("Humanoid", true) then return true end
    end
    return false
end

-- Большие твёрдые части (земля поля) не удаляем, чтобы не провалиться под карту
local function isFloorPart(p)
    return p.CanCollide and math.max(p.Size.X, p.Size.Z) >= 25
end

local function safeToDestroy(obj)
    if obj:IsA("BasePart") then
        return not isFloorPart(obj)
    end
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("BasePart") and isFloorPart(d) then return false end
    end
    return true
end

-- true = объект удалён (или уже удалён) и дальше его обрабатывать не нужно
local function decorDelete(obj)
    if not obj.Parent then return true end
    if not (obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Folder")) then return false end

    local parent = obj.Parent
    local matched = decorNameMatches(obj.Name)

    -- содержимое верхнеуровневой папки вроде "Flowers" удаляем, саму папку оставляем
    if not matched and parent and parent.Parent == Workspace and parent:IsA("Folder")
        and decorNameMatches(parent.Name) then
        matched = true
    end
    if not matched then return false end
    if obj:IsA("Folder") and parent == Workspace then return false end

    if isProtected(obj) or not safeToDestroy(obj) then return false end

    boost.deleted = boost.deleted + 1
    obj:Destroy()
    return true
end

local function processObj(obj)
    if obj:IsA("Terrain") then return end

    if Config.HideDecor and decorDelete(obj) then return end

    if obj:IsA("BasePart") then
        local s = boost.parts[obj]
        if not s then
            s = { obj.Material, obj.Reflectance, obj.CastShadow }
            boost.parts[obj] = s
        end
        obj.CastShadow = false
        obj.Reflectance = 0
        obj.Material = Enum.Material.Plastic

        if s[4] == nil and obj:IsA("MeshPart") and not inCharacter(obj) then
            s[4] = obj.TextureID
            obj.TextureID = ""
        end

        if hiddenByName(obj) or (Config.HideDecor and underMap(obj)) then
            if s[5] == nil then s[5] = obj.Transparency end
            obj.Transparency = 1
        end
    elseif FX_CLASSES[obj.ClassName] then
        if boost.fx[obj] == nil then boost.fx[obj] = { "Enabled", obj.Enabled } end
        obj.Enabled = false
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        if boost.fx[obj] == nil and not inCharacter(obj) then
            boost.fx[obj] = { "Transparency", obj.Transparency }
            obj.Transparency = 1
        end
    elseif obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
        if boost.fx[obj] == nil and hiddenByName(obj) then
            boost.fx[obj] = { "Enabled", obj.Enabled }
            obj.Enabled = false
        end
    end
end

local function applyBoost()
    if boost.restoring then return end

    boost.token = boost.token + 1
    local token = boost.token

    boost.hide = setmetatable({}, { __mode = "k" })
    boost.names, boost.dnames = {}, {}
    boost.underY = computeUnderY()

    if not boost.light then
        boost.light = {}
        pcall(function()
            boost.light.GlobalShadows = Lighting.GlobalShadows
            boost.light.FogEnd = Lighting.FogEnd
            boost.light.ShadowSoftness = Lighting.ShadowSoftness
        end)
        pcall(function()
            local t = Workspace.Terrain
            boost.light.Water = { t.WaterWaveSize, t.WaterWaveSpeed, t.WaterReflectance }
        end)
        pcall(function() boost.light.Decoration = Workspace.Terrain.Decoration end)
        pcall(function() boost.quality = settings().Rendering.QualityLevel end)
    end

    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
    end)
    pcall(function()
        local t = Workspace.Terrain
        t.WaterWaveSize = 0
        t.WaterWaveSpeed = 0
        t.WaterReflectance = 0
    end)
    pcall(function() Workspace.Terrain.Decoration = false end)

    for _, v in ipairs(Lighting:GetDescendants()) do
        pcall(function()
            if POST_CLASSES[v.ClassName] then
                if boost.fx[v] == nil then boost.fx[v] = { "Enabled", v.Enabled } end
                v.Enabled = false
            elseif v:IsA("Atmosphere") then
                if boost.fx[v] == nil then boost.fx[v] = { "Density", v.Density } end
                v.Density = 0
            end
        end)
    end

    -- Обработка карты кусками, чтобы не фризить слабое устройство
    task.spawn(function()
        local step = newSlicer()
        for _, v in ipairs(Workspace:GetDescendants()) do
            if not alive or boost.token ~= token or not Config.FPSBoost then return end
            pcall(processObj, v)
            step()
        end
    end)

    if boost.conn then boost.conn:Disconnect() end

    local queue, qh, qt = {}, 1, 0
    boost.conn = Workspace.DescendantAdded:Connect(function(v)
        qt = qt + 1
        queue[qt] = v
    end)

    -- один воркер обрабатывает новые объекты (токены, частицы) в рамках бюджета времени
    task.spawn(function()
        while alive and boost.token == token and Config.FPSBoost do
            local t0 = os.clock()
            while qh <= qt and os.clock() - t0 < 0.004 do
                local v = queue[qh]
                queue[qh] = nil
                qh = qh + 1
                if v and v.Parent then pcall(processObj, v) end
            end
            if qh > qt then
                qh, qt = 1, 0
                task.wait(0.25)
            else
                task.wait()
            end
        end
    end)
end

local function restoreBoost()
    boost.token = boost.token + 1
    boost.restoring = true
    boost.hide = setmetatable({}, { __mode = "k" })
    boost.names, boost.dnames = {}, {}

    if boost.conn then
        boost.conn:Disconnect()
        boost.conn = nil
    end

    if boost.light then
        local l = boost.light
        pcall(function()
            if l.GlobalShadows ~= nil then Lighting.GlobalShadows = l.GlobalShadows end
            if l.FogEnd ~= nil then Lighting.FogEnd = l.FogEnd end
            if l.ShadowSoftness ~= nil then Lighting.ShadowSoftness = l.ShadowSoftness end
        end)
        pcall(function()
            local t = Workspace.Terrain
            if l.Water then
                t.WaterWaveSize = l.Water[1]
                t.WaterWaveSpeed = l.Water[2]
                t.WaterReflectance = l.Water[3]
            end
        end)
        pcall(function()
            if l.Decoration ~= nil then Workspace.Terrain.Decoration = l.Decoration end
        end)
        boost.light = nil
    end
    pcall(function()
        if boost.quality then settings().Rendering.QualityLevel = boost.quality end
    end)
    boost.quality = nil

    task.spawn(function()
        local step = newSlicer()
        for part, s in pairs(boost.parts) do
            if part and part.Parent then
                pcall(function()
                    part.Material = s[1]
                    part.Reflectance = s[2]
                    part.CastShadow = s[3]
                    if s[4] ~= nil then part.TextureID = s[4] end
                    if s[5] ~= nil then part.Transparency = s[5] end
                end)
            end
            boost.parts[part] = nil
            step()
        end

        for obj, s in pairs(boost.fx) do
            if obj and obj.Parent then
                pcall(function() obj[s[1]] = s[2] end)
            end
            boost.fx[obj] = nil
            step()
        end

        boost.restoring = false
        -- если за время восстановления буст включили снова - применяем
        if alive and Config.FPSBoost then
            applyBoost()
        end
    end)
end

-- ============================================================
-- === MEMORY CLEANER (раз в 30 минут) ===
-- ============================================================

local CLEAN_INTERVAL = 30 * 60
local Stats = game:GetService("Stats")
local memory = {
    nextAt = os.clock() + CLEAN_INTERVAL,
    cleaning = false,
    lastText = "Last clean: not yet"
}

local function totalMemoryMb()
    local ok, v = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
    if ok and type(v) == "number" then return v end
    return 0
end

local function luaMb()
    local ok, v = pcall(collectgarbage, "count")
    if ok and type(v) == "number" then return v / 1024 end
    return 0
end

-- Топ потребителей памяти (по тегам движка Roblox)
local function topMemoryTags(n)
    local list = {}
    local ok = pcall(function()
        for _, tag in ipairs(Enum.DeveloperMemoryTag:GetEnumItems()) do
            local mb = Stats:GetMemoryUsageMbForTag(tag)
            if mb and mb >= 5 then list[#list + 1] = { tag.Name, mb } end
        end
    end)
    if not ok or #list == 0 then return "n/a" end
    table.sort(list, function(x, y) return x[2] > y[2] end)
    local parts = {}
    for i = 1, math.min(n, #list) do
        parts[#parts + 1] = string.format("%s %.0f", list[i][1], list[i][2])
    end
    return table.concat(parts, ", ")
end

-- Принудительная сборка мусора. В Roblox/некоторых эксплойтах
-- collectgarbage("collect") запрещён - пробуем все доступные варианты.
local function tryGC()
    if pcall(collectgarbage, "collect") then return true end
    if pcall(collectgarbage) then return true end
    if pcall(function() collectgarbage("step", 100000) end) then return true end
    return false
end

local function cleanMemory()
    if memory.cleaning then return end
    memory.cleaning = true

    local ok, err = pcall(function()
        local luaBefore, totalBefore = luaMb(), totalMemoryMb()

        -- 1) собственные кэши скрипта
        pcall(function()
            boost.names, boost.dnames = {}, {}
            boost.hide = setmetatable({}, { __mode = "k" })
        end)

        -- 2) записи о давно удалённых объектах (чтобы таблицы не росли бесконечно)
        pcall(function()
            local deadParts, deadFx = {}, {}
            for part in pairs(boost.parts) do
                if not part.Parent then deadParts[#deadParts + 1] = part end
            end
            for obj in pairs(boost.fx) do
                if not obj.Parent then deadFx[#deadFx + 1] = obj end
            end
            local step = newSlicer()
            for _, part in ipairs(deadParts) do
                boost.parts[part] = nil
                step()
            end
            for _, obj in ipairs(deadFx) do
                boost.fx[obj] = nil
                step()
            end
        end)

        -- 3) сборка мусора (два прохода: второй добирает то, что освободил первый)
        task.wait()
        local gcOk = tryGC()
        if gcOk then
            task.wait(0.25)
            tryGC()
            task.wait(0.25)
        end

        local luaAfter, totalAfter = luaMb(), totalMemoryMb()
        local freed = math.max(0, luaBefore - luaAfter)

        if gcOk then
            memory.lastText = string.format(
                "Last clean: -%.1f MB Lua, total %.0f to %.0f MB",
                freed, totalBefore, totalAfter
            )
            notify(string.format("Memory cleaned: -%.1f MB", freed))
        else
            memory.lastText = "Last clean: caches cleared, forced GC is blocked here"
            notify("Caches cleared (GC blocked by executor)")
        end
    end)

    if not ok then
        memory.lastText = "Last clean failed: " .. tostring(err):sub(1, 70)
    end
    memory.nextAt = os.clock() + CLEAN_INTERVAL
    memory.cleaning = false
end

task.spawn(function()
    while alive and task.wait(5) do
        if Config.AutoClean then
            if os.clock() >= memory.nextAt then
                cleanMemory()
            end
        else
            memory.nextAt = os.clock() + CLEAN_INTERVAL
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
    return mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, obj)
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
        Size = UDim2.fromOffset(250, 36),
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 270, 1, -16),
        BackgroundColor3 = THEME.ElementBg,
        BorderSizePixel = 0,
        Text = tostring(text),
        TextColor3 = THEME.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12
    }, gui)
    corner(toast, 8)
    mk("UIStroke", { Color = THEME.Accent, Thickness = 1 }, toast)
    lastToast = toast

    TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
        Position = UDim2.new(1, -16, 1, -16)
    }):Play()

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
    Visible = false,
    ClipsDescendants = true
}, gui)
corner(main, 10)
mk("UIStroke", { Color = THEME.Border, Thickness = 1 }, main)
local mainScale = mk("UIScale", { Scale = 1 }, main)

local openBtn = mk("TextButton", {
    Name = "LiteProjectMinGui",
    Size = UDim2.fromOffset(54, 54),
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 30),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
    Visible = true
}, gui)

-- градиентное кольцо (медленно вращается)
local logoRing = mk("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BorderSizePixel = 0
}, openBtn)
corner(logoRing, 27)
local ringGradient = mk("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(232, 121, 249)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 140, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(232, 121, 249))
    }),
    Rotation = 0
}, logoRing)

local logoInner = mk("Frame", {
    Size = UDim2.new(1, -6, 1, -6),
    Position = UDim2.fromOffset(3, 3),
    BackgroundColor3 = Color3.fromRGB(16, 16, 20),
    BorderSizePixel = 0
}, logoRing)
corner(logoInner, 24)

local logoText = mk("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "LP",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBlack,
    TextSize = 19
}, logoInner)
mk("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(245, 160, 255), Color3.fromRGB(120, 150, 255)),
    Rotation = 45
}, logoText)

local logoScale = mk("UIScale", { Scale = 1 }, openBtn)
openBtn.MouseButton1Down:Connect(function()
    TweenService:Create(logoScale, TweenInfo.new(0.08), { Scale = 0.9 }):Play()
end)
local function logoRelease()
    TweenService:Create(logoScale, TweenInfo.new(0.12), { Scale = 1 }):Play()
end
openBtn.MouseButton1Up:Connect(logoRelease)
openBtn.MouseLeave:Connect(logoRelease)

task.spawn(function()
    while alive do
        task.wait(0.05)
        if openBtn.Visible then
            ringGradient.Rotation = (ringGradient.Rotation + 4) % 360
        end
    end
end)

local function showMain(show)
    main.Visible = show
    openBtn.Visible = not show
    if show then
        mainScale.Scale = 0.92
        TweenService:Create(mainScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Scale = 1 }):Play()
    end
end

-- Перетаскивание (с поддержкой "тапа")
local function makeDraggable(handle, target, onTap)
    local dragging, dragStart, startPos, moved = false, nil, nil, 0

    handle.InputBegan:Connect(function(input)
        if isDraggingSlider then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
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

-- Верхняя панель
local topBar = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = THEME.Sidebar,
    BorderSizePixel = 0
}, main)
mk("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(14, 14, 16), Color3.fromRGB(52, 26, 60)),
    Rotation = 0
}, topBar)

local badge = mk("Frame", {
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.fromOffset(14, 8),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BorderSizePixel = 0
}, topBar)
corner(badge, 14)
mk("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(232, 121, 249), Color3.fromRGB(110, 140, 255)),
    Rotation = 45
}, badge)
local badgeInner = mk("Frame", {
    Size = UDim2.new(1, -4, 1, -4),
    Position = UDim2.fromOffset(2, 2),
    BackgroundColor3 = Color3.fromRGB(16, 16, 20),
    BorderSizePixel = 0
}, badge)
corner(badgeInner, 12)
mk("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "LP",
    TextColor3 = THEME.Accent,
    Font = Enum.Font.GothamBlack,
    TextSize = 11
}, badgeInner)

mk("TextLabel", {
    Size = UDim2.new(1, -240, 0, 20),
    Position = UDim2.fromOffset(52, 5),
    BackgroundTransparency = 1,
    Text = "Lite Project",
    TextColor3 = THEME.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left
}, topBar)

mk("TextLabel", {
    Size = UDim2.new(1, -240, 0, 14),
    Position = UDim2.fromOffset(52, 25),
    BackgroundTransparency = 1,
    Text = "Made for low-end devices",
    TextColor3 = THEME.TextDim,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left
}, topBar)

-- Живой счётчик FPS
local fpsPill = mk("Frame", {
    Size = UDim2.fromOffset(74, 24),
    Position = UDim2.new(1, -126, 0, 10),
    BackgroundColor3 = THEME.Bg,
    BorderSizePixel = 0
}, topBar)
corner(fpsPill, 12)
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
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -42, 0, 7),
    BackgroundColor3 = THEME.ElementBg,
    Text = "–",
    TextColor3 = THEME.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 16
}, topBar)
corner(minimizeBtn, 8)

mk("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.fromOffset(0, 44),
    BackgroundColor3 = THEME.Border,
    BorderSizePixel = 0
}, main)

makeDraggable(topBar, main)
makeDraggable(openBtn, openBtn, function() showMain(true) end)

minimizeBtn.MouseButton1Click:Connect(function() showMain(false) end)

track(UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightShift and gui.Parent then
        showMain(not main.Visible)
    end
end))

-- Боковая панель + контент
local sidebar = mk("Frame", {
    Size = UDim2.new(0, 130, 1, -45),
    Position = UDim2.fromOffset(0, 45),
    BackgroundColor3 = THEME.Sidebar,
    BorderSizePixel = 0
}, main)
mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
mk("UIPadding", {
    PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)
}, sidebar)

local content = mk("Frame", {
    Size = UDim2.new(1, -130, 1, -45),
    Position = UDim2.fromOffset(130, 45),
    BackgroundTransparency = 1
}, main)

local pages, tabButtons = {}, {}

local function selectTab(name)
    for n, page in pairs(pages) do
        page.Visible = (n == name)
    end
    for n, btn in pairs(tabButtons) do
        local active = (n == name)
        btn.BackgroundColor3 = active and THEME.TabActiveBg or THEME.Sidebar
        btn.TextColor3 = active and THEME.Accent or THEME.TextDim
    end
end

local function createTab(name, order)
    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
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
    corner(btn, 8)

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
        PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 18), PaddingBottom = UDim.new(0, 12)
    }, page)

    pages[name] = page
    tabButtons[name] = btn
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
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

local function addToggle(page, text, key, desc, callback)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, desc and 54 or 42),
        BackgroundColor3 = THEME.ElementBg,
        BorderSizePixel = 0
    }, page)
    corner(row, 8)

    mk("TextLabel", {
        Size = UDim2.new(1, -70, 0, 20),
        Position = UDim2.fromOffset(12, desc and 8 or 11),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = THEME.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)

    if desc then
        mk("TextLabel", {
            Size = UDim2.new(1, -70, 0, 16),
            Position = UDim2.fromOffset(12, 28),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = THEME.TextDim,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left
        }, row)
    end

    local sw = mk("TextButton", {
        Size = UDim2.fromOffset(42, 22),
        Position = UDim2.new(1, -54, 0.5, -11),
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        BackgroundColor3 = Config[key] and THEME.Accent or THEME.ToggleOff
    }, row)
    corner(sw, 11)

    local knob = mk("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = Config[key] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
        BackgroundColor3 = Config[key] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150),
        BorderSizePixel = 0
    }, sw)
    corner(knob, 9)

    sw.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        local on = Config[key]

        TweenService:Create(sw, TweenInfo.new(0.18), {
            BackgroundColor3 = on and THEME.Accent or THEME.ToggleOff
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.18), {
            Position = on and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
            BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
        }):Play()

        saveConfig()
        if callback then callback(on) end
    end)

    return row
end

local function addSlider(page, text, min, max, key, callback)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = THEME.ElementBg,
        BorderSizePixel = 0
    }, page)
    corner(row, 8)

    mk("TextLabel", {
        Size = UDim2.new(1, -80, 0, 20),
        Position = UDim2.fromOffset(12, 8),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = THEME.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)

    local valLabel = mk("TextLabel", {
        Size = UDim2.fromOffset(60, 20),
        Position = UDim2.new(1, -72, 0, 8),
        BackgroundTransparency = 1,
        Text = tostring(Config[key]),
        TextColor3 = THEME.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right
    }, row)

    local hit = mk("TextButton", {
        Size = UDim2.new(1, -24, 0, 24),
        Position = UDim2.fromOffset(12, 30),
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
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(rel0, -8, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0
    }, hit)
    corner(knob, 8)

    local dragging = false

    local function setFromX(x)
        if bg.AbsoluteSize.X <= 0 then return end
        local rel = math.clamp((x - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * rel + 0.5)
        Config[key] = value
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.new(rel, -8, 0.5, -8)
        valLabel.Text = tostring(value)
        if callback then callback(value) end
    end

    local function setValue(value)
        value = math.clamp(math.floor(value), min, max)
        Config[key] = value
        local rel = (value - min) / (max - min)
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.new(rel, -8, 0.5, -8)
        valLabel.Text = tostring(value)
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            isDraggingSlider = true
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
        if dragging
            and (input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            isDraggingSlider = false
            saveConfig()
        end
    end))

    return row, setValue
end

-- Быстрые кнопки-значения (чипы)
local function addChips(page, values, labels, onPick, getCurrent)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
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
            b.BackgroundColor3 = on and THEME.Accent or THEME.ElementBg
            b.TextColor3 = on and Color3.fromRGB(20, 20, 24) or THEME.Text
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
        corner(b, 8)
        chips[v] = b
        b.MouseButton1Click:Connect(function()
            onPick(v)
            refresh()
        end)
    end

    refresh()
    return refresh
end

local function addButton(page, text, callback, danger)
    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = danger and THEME.Danger or THEME.ElementBg,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = THEME.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        AutoButtonColor = true
    }, page)
    corner(btn, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function addGrid(page)
    local frame = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1
    }, page)
    mk("UIGridLayout", {
        CellSize = UDim2.new(0.5, -4, 0, 34),
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
addSection(renderPage, "Performance")
addToggle(renderPage, "FPS Boost", "FPSBoost", "Лёгкая графика: без текстур, теней, света, частиц", function(on)
    if on then applyBoost() else restoreBoost() end
    if on then
        notify("FPS Boost: ON")
    elseif boost.deleted > 0 then
        notify("FPS Boost: OFF. Удалённый декор вернётся после перезахода")
    else
        notify("FPS Boost: OFF")
    end
end)
addSection(renderPage, "What to hide")
local function reapplyHide()
    if Config.FPSBoost then restoreBoost() end -- восстановит и сразу применит заново
end
addToggle(renderPage, "Hide Bees", "HideBees", "Все пчёлы, включая декоративных", reapplyHide)
addToggle(renderPage, "Hide Tokens", "HideTokens", "Токены невидимы, но собираются", reapplyHide)
addToggle(renderPage, "Delete Map Decor", "HideDecor", "Удаляет деревья, кусты, цветы и заборы до перезахода", function(on)
    reapplyHide()
    if not on and boost.deleted > 0 then
        notify("Удалённое вернётся после перезахода")
    end
end)
addSection(renderPage, "Memory")
addToggle(renderPage, "Auto Clean Memory", "AutoClean", "Полная очистка каждые 30 минут")
local memLabel = addLabel(renderPage, "Memory: ...")
addButton(renderPage, "Clean Memory Now", function()
    task.spawn(cleanMemory)
end)
task.spawn(function()
    while alive and task.wait(2) do
        if main.Visible and memLabel.Parent then
            local mins = math.max(0, math.ceil((memory.nextAt - os.clock()) / 60))
            local nextText = Config.AutoClean and ("Next clean in " .. mins .. " min") or "Auto clean is off"
            memLabel.Text = string.format(
                "Memory: %.0f MB (Lua %.0f MB)\nTop: %s\n%s\n%s",
                totalMemoryMb(), luaMb(), topMemoryTags(3), nextText, memory.lastText
            )
        end
    end
end)
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

    fieldsInfo.Text = "Tap a field to teleport"

    for i, zone in ipairs(list) do
        local btn = mk("TextButton", {
            BackgroundColor3 = THEME.ElementBg,
            BorderSizePixel = 0,
            Text = zone.Name,
            TextColor3 = THEME.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextTruncate = Enum.TextTruncate.AtEnd,
            LayoutOrder = i
        }, fieldsGrid)
        corner(btn, 8)
        btn.MouseButton1Click:Connect(function()
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
addToggle(rejoinPage, "Any Error", "AnyError", "Любая ошибка - возможны ложные срабатывания")
statusLabel = addLabel(rejoinPage, "Status: waiting 20s to arm...")
if REJOIN.armed then setStatus("armed, watching for disconnects") end

do
    local ok, how = canReexecute()
    addLabel(rejoinPage, "Auto re-run after rejoin: " .. (ok and "ON" or ("OFF - " .. how)))
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
addLabel(infoPage, "Lite Project\nМеню: RightShift")
addSection(infoPage, "Control")
addButton(infoPage, "Save Config Now", function()
    safeWrite(CONFIG_FILE, HttpService:JSONEncode(Config))
    notify("Config saved")
end)
local function dumpStructure()
    local out = {}
    for _, c in ipairs(Workspace:GetChildren()) do
        if not (c:IsA("Terrain") or c:IsA("Camera")) and not Players:GetPlayerFromCharacter(c) then
            local kids = c:GetChildren()
            out[#out + 1] = c.ClassName .. ": " .. c.Name .. " (" .. #kids .. ")"
            local seen, shown = {}, 0
            for _, k in ipairs(kids) do
                if not seen[k.Name] and shown < 12 then
                    seen[k.Name] = true
                    shown = shown + 1
                    out[#out + 1] = "    - " .. k.ClassName .. ": " .. k.Name
                end
            end
        end
    end
    local text = table.concat(out, "\n")
    if #text > 15000 then text = text:sub(1, 15000) end
    if type(setclipboard) == "function" then
        setclipboard(text)
        notify("Workspace structure copied")
    else
        notify("setclipboard not supported")
    end
end

addSection(infoPage, "Debug")
addButton(infoPage, "Copy Workspace Structure", dumpStructure)
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
    pcall(function()
        if boost.conn then boost.conn:Disconnect() end
        if boost.light then
            restoreBoost() -- alive = false, поэтому повторно буст не применится
        end
    end)
    pcall(function() setfpscap(0) end)
    destroyOldGuis()
    _G.LiteProjectDoRejoin = nil
end

-- ============================================================
-- === СТАРТ ===
-- ============================================================

updateFPS()
if Config.FPSBoost then applyBoost() end

task.defer(function()
    notify("Lite Project loaded - RightShift to toggle")
end)

print("[Lite Project] loaded. RightShift - hide/show menu.")

]==]
pcall(function() writefile("LiteProject.lua", SRC) end)
local fn, err = loadstring(SRC)
if fn then fn() else warn("LiteProject load error: " .. tostring(err)) end
