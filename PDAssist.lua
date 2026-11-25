-- =========================================================================================
--  B-Zone PDAssist v1.0 (Modern Mimgui Edition)
--  Tradus & modernizat din PDHelper V7.5 CLEO (by TheTom) in stilul TaxiAssist & LSSI Helper
-- =========================================================================================

script_name("B-Zone PDAssist")
script_version("1.0")        -- versiunea (o schimbi la update-uri mari)
script_version_number(0)     -- patch-ul (il cresti la fiecare update mic; conteaza cand versiunea e aceeasi)
script_author("TheTom, SyLvy & Antigravity")

require("lib.moonloader")
local sampev   = require("samp.events")
local imgui    = require("mimgui")
local encoding = require("encoding")
local ffi      = require("ffi")
local inicfg   = require("inicfg")
local vkeys    = require("vkeys")
local fa       = require("fAwesome5")
local bit      = require("bit")
local okRules, deptRulesAll = pcall(require, "lib.RulesDepartments")
if not okRules then deptRulesAll = nil end

encoding.default = "CP1251"
local u8 = encoding.UTF8
local new = imgui.new

-- =========================================================================================
--  SECTION 1: CONFIGURATION & PERSISTENCE (moonloader/config/PDAssist.ini)
-- =========================================================================================
local CONFIG_FILE    = "PDAssist.ini"
local CUSTOM_CMD_MAX = 25

local defaultComenzi = {
    en1 = 1, cmd1 = "qh",     txt1 = "/questhelp",
    en2 = 1, cmd2 = "gg",     txt2 = "/getgift",
    en3 = 1, cmd3 = "tow",    txt3 = "/service towtruck",
    en4 = 1, cmd4 = "taxi",   txt4 = "/service taxi",
    en9 = 0, cmd9 = "whynot", txt9 = "/sms Kelton ziua 11 in care iti cer sa ma faci admin",
}
for i = 1, CUSTOM_CMD_MAX do
    if defaultComenzi["en" .. i] == nil then defaultComenzi["en" .. i] = 0 end
    if defaultComenzi["cmd" .. i] == nil then defaultComenzi["cmd" .. i] = "" end
    if defaultComenzi["txt" .. i] == nil then defaultComenzi["txt" .. i] = "" end
end

local defaultCfg = {
    settings = {
        cfgVersion    = 4,
        faction       = "LSPD",     -- LSPD, LVPD, SFPD, FBI, NG
        pdTeam        = "RUTIERA",  -- RUTIERA sau SWAT (activ doar pentru LSPD/LVPD/SFPD)
        limba         = 1,          -- 1 = RO, 0 = EN (ca in PDHelper V7) - limba mesajelor trimise jucatorilor
        uiLang        = "ro",       -- limba interfetei: meniuri, HUD, roata, notificari ("ro" / "en")
        hud           = 1,          -- Afisare indicator HUD dreapta
        hudStyle      = 0,          -- 0 = Modern (dreapta, iconite), 1 = Clasic PDHelper (jos, deasupra rpg.b-zone.ro)
        notifType     = 0,          -- 0 = ImGui Toast modern, 1 = Clasic printStringNow
        updateCheck   = 0,          -- 1 = la pornire verifica pe GitHub daca exista o versiune noua
        errNotif      = 0,          -- 1 = erorile modului ([PDAssist] Niciun jucator..., Blocat...) apar ca notificare, nu in chat
        hudScalePct   = 100,        -- marimea HUD-ului din dreapta (modern + clasic), in procente (60-160)
        notifScalePct = 100,        -- marimea notificarilor, in procente (60-160)
        scaleLinked   = 1,          -- 1 = HUD si notificarile au aceeasi marime (un slider le muta pe amandoua)
        wheelScalePct = 100,        -- marimea rotii de interactiune, in procente (60-160)
        sanMenuType   = 0,          -- 0 = Meniu Mimgui Modern, 1 = Dialog Clasic SA-MP
        menuKeyOn     = 1,          -- Tasta rapida pt meniu sanctiuni (/san)
        menuKey       = 75,         -- VK_K (Meniu Sanctiuni Rapide)
        nMenuKey      = "K",
        hud_custom    = false,
        hud_x         = -1,
        hud_y         = -1,
        classic_custom = false,     -- pozitie mutata pt HUD-ul clasic PDHelper (separat de cel modern)
        classic_x     = -1,         -- marginea dreapta
        classic_y     = -1,         -- marginea de sus
        cp            = 1,          -- Comenzi prescurtate active
        gateKeyOn     = 1,          -- Tasta C pentru porti Jail / NG
        gateKey       = 67,         -- VK_C
        nGateKey      = "C",
        firstStart    = 1,
        kAction       = "PDC",      -- actiunea tastei principale (K)
        lKeyOn        = 0,          -- tasta secundara (L) - implicit OFF
        lKey          = 76,         -- VK_L
        nLKey         = "L",
        lAction       = "PDC",
        wheelOn       = 0,          -- roata interactiune (sofer + pe jos) - implicit OFF
        wheelRadius   = 5,          -- raza (m) pt jucatorii din "Interact" pe jos
        hudOrder      = "",         -- ordinea tastelor in HUD ("" = ordinea implicita)
        cmdCount      = 25,         -- cate sloturi de comenzi custom ai (minim 25, max 100)
        kbcCount      = 10,         -- cate keybinduri custom ai (minim 10, max 50)
        wheelMode     = "hold",     -- "hold" = tii tasta, eliberezi pe felie | "touch" = apesi o data deschide / inchide
        wheelKey      = 113,        -- VK_F2
        nWheelKey     = "F2",
    },
    pd = {
        somatie       = 1,
        TastaS        = 88,
        nTastaS       = "X",
        radar         = 1,
        TastaR        = 52,
        nTastaR       = "4",
        cuffarrest    = 1,
        TastaCA       = 107,
        nTastaCA      = "num+",
        frisk         = 1,
        TastaF        = 80,
        nTastaF       = "P",
        RazaFrisk     = 3.0,
        tazer         = 1,
        TastaT        = 90,
        nTastaT       = "Z",
        wanted        = 1,
        TastaWA       = 111,
        nTastaWA      = "num/",
        nearwanted    = 1,
        TastaNWA      = 106,
        nTastaNWA     = "num*",
        repairon      = 1,
        TastaRepair   = 53,
        nTastaRepair  = "5",
        autoengine    = 1,
        startstop     = 1,
        allowrepeat   = 1,
        arrestid      = -1,
    },
    radar = {
        zona          = "Temple LS",
        limita        = 100,
        stage         = 0,
        lastid        = -1,
        lastnivel     = 0,
        lastviteza    = 0,
        lastnume      = "-",
    },
    fvr = {
        enableR       = 1,
        fvrR          = "Voi da FVR peste 10 secunde!!",
        fvrD          = "Voi da FVR peste 10 secunde!",
        fvrF          = "Am dat Faction Vehicles Respawn.",
        fvrStop       = "Nu voi mai da FVR.",
        secunde       = 10,
    },
    gov = {
        gov1          = "Recrutam membri noi, minim level 15 si skill 5 detectiv;",
        l1            = 1,
        gov2          = "De preferat rank 3 anterior si activitate buna in ultima perioada.",
        l2            = 0,
        gov3          = "Puteti aplica pe rpg.b-zone.ro daca indepliniti criteriile.",
    },
    cmd = {
        cmd           = "cmd",
    },
    comenzi = defaultComenzi,
    auto = {
        findTrack     = 1,          -- anulare automata /find cand HQ anunta arest / kill / deconectare etc.
    },
    login = {
        enabled       = 0,          -- login automat in dialogul serverului
        pass          = "",         -- parola criptata (dp: = Windows DPAPI, hex: = doar codificata)
        pinAuto       = 0,          -- PIN automat pe tastatura (textdraw) de la /pin
        pin           = "",
    },
    wheel = {                       -- roata: ordinea si feliile ascunse, pe nivel (foot / car / player)
        order_foot = "", order_car = "", order_player = "",
        hide_foot  = "", hide_car  = "", hide_player  = "",
    },
    hudrows = {                     -- 1 = tasta apare in HUD, 0 = ascunsa din HUD (tasta ramane activa)
        menuKeyOn = 1, lKeyOn = 1, wheelOn = 1, somatie = 1, radar = 1, cuffarrest = 1,
        frisk = 1, tazer = 1, wanted = 1, nearwanted = 1, repairon = 1,
    },
    kbc = (function()               -- 10 keybinduri personalizate (tasta -> text / comenzi)
        local t = {}
        for i = 1, 10 do
            t["on" .. i] = 0; t["key" .. i] = 0; t["kname" .. i] = "-"
            t["label" .. i] = ""; t["text" .. i] = ""; t["hud" .. i] = 1
            t["icon" .. i] = "KEYBOARD" -- iconita in HUD (numele din fAwesome5, fara ICON_FA_)
        end
        return t
    end)(),
    blacklist = {
        pinned = false,
        posX = 20, posY = 220, w = 330, -- pozitia + latimea listei fixate pe ecran (/blpos)
        bl1 = "TheTom - 18:08 - 17.12.2024 - a mers pe contrasens",
        bl2 = "Kelton NOS",
        bl3 = "GeorgianaA_fr - faruri, m-a suparat, ii dau neaparat amenda",
        bl4 = "-", bl5 = "-", bl6 = "-",
        bl7 = "-", bl8 = "-", bl9 = "-",
    }
}

local cfg = inicfg.load(defaultCfg, CONFIG_FILE)

local function ensureDefaults(target, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then target[k] = {} end
            ensureDefaults(target[k], v)
        elseif target[k] == nil then
            target[k] = v
        end
    end
end
ensureDefaults(cfg, defaultCfg)

-- Numarul de sloturi de comenzi custom (minim 25, se pot adauga din /pdc pana la 100) - salvat in ini
CUSTOM_CMD_MAX = math.max(25, math.min(100, tonumber(cfg.settings.cmdCount) or 25))
for i = 1, CUSTOM_CMD_MAX do
    if cfg.comenzi["en" .. i] == nil then cfg.comenzi["en" .. i] = 0 end
    if cfg.comenzi["cmd" .. i] == nil then cfg.comenzi["cmd" .. i] = "" end
    if cfg.comenzi["txt" .. i] == nil then cfg.comenzi["txt" .. i] = "" end
end

-- Migrare v1 -> v2 (PDHelperV7.ini defaults)
if (tonumber(cfg.settings.cfgVersion) or 1) < 2 then
    local savedFaction = cfg.settings.faction
    local savedHudCust = cfg.settings.hud_custom
    local savedHudX    = cfg.settings.hud_x
    local savedHudY    = cfg.settings.hud_y
    for secName, secTbl in pairs(defaultCfg) do
        if type(secTbl) == "table" then
            cfg[secName] = cfg[secName] or {}
            for k, v in pairs(secTbl) do
                cfg[secName][k] = v
            end
        end
    end
    if savedFaction and savedFaction ~= "" then cfg.settings.faction = savedFaction end
    cfg.settings.hud_custom = savedHudCust
    cfg.settings.hud_x      = savedHudX
    cfg.settings.hud_y      = savedHudY
end

-- Migrare v2 -> v3 (9 sloturi vechi cc1/c1/c12 -> 25 sloturi en1/cmd1/txt1 + eliminare showRutiera)
if (tonumber(cfg.settings.cfgVersion) or 1) < 3 then
    for i = 1, 9 do
        if cfg.comenzi["c" .. i] ~= nil or cfg.comenzi["c" .. i .. "2"] ~= nil then
            local oldEn  = tonumber(cfg.comenzi["cc" .. i])
            local oldCmd = tostring(cfg.comenzi["c" .. i] or "")
            local oldTxt = tostring(cfg.comenzi["c" .. i .. "2"] or "")
            if oldCmd ~= "" or oldTxt ~= "" then
                cfg.comenzi["en" .. i]  = oldEn or 0
                cfg.comenzi["cmd" .. i] = oldCmd
                cfg.comenzi["txt" .. i] = oldTxt
            end
        end
        cfg.comenzi["cc" .. i]       = nil
        cfg.comenzi["c" .. i]        = nil
        cfg.comenzi["c" .. i .. "2"] = nil
    end
    cfg.settings.cfgVersion = 3
end

-- Migrare v3 -> v4: tasta principala (K) deschide acum panoul /pdc
if (tonumber(cfg.settings.cfgVersion) or 1) < 4 then
    cfg.settings.kAction    = "PDC"
    cfg.settings.cfgVersion = 4
end

cfg.settings.showRutiera = nil
cfg.settings.radarHud    = nil
cfg.pd.lockOnCuff        = nil
cfg.radar.stage          = 0
inicfg.save(cfg, CONFIG_FILE)

-- =========================================================================================
--  SECTION 2: RUNTIME STATE & BUFFERS
-- =========================================================================================
local FACTIONS = { "LSPD", "LVPD", "SFPD", "FBI", "NG" }

-- Cached game state (updated once per frame in main loop)
local state = {
    inCar       = false,
    isDriving   = false,
    paused      = false,
    scoreboard  = false,
    dialog      = false,
    chat        = false,
    onDuty      = false,
}

-- Radar history (up to 5 recent speeders, newest tracked cleanly)
local radarHistory = {} -- { id, name, level, speed, limit, timeStr }
local radaron      = false
local liStep       = 0
local potStep      = 0
local patStep      = 0

-- Timers (displayed live on HUD + chat & toast alert on finish)
local timers = {
    mmEnd      = 0, -- 3s megaphone timer
    dEnd       = 0, -- 10s /d radar/patrol question timer
    afkEnd     = 0, -- 30s or 180s AFK timer
    afkLabel   = "",
    fvrActive  = false,
    fvrLeft    = 0,
}

-- Anti-spam toggles
local friskSpamToggle = false
local nefSpamToggle   = false
local mmSpamToggle    = false

-- Start-Stop vehicle engine state
local ssStep      = 0
local ssIdleStart = 0

-- Automatic Dialog Selection State (/ticket & /su)
local pendingTicket = { active = false, id = -1, line = 0, expire = 0 }
local pendingSu     = { active = false, id = -1, line = 0, expire = 0 }

-- Pending /id scan for level-dependent sanctions
local pendingSanction = { active = false, type = nil, id = -1, expire = 0 }

-- Auto-arrest cooldown
local lastAutoArrestTime = 0

-- Keybind capture state
local capturingBind = nil -- { section = "pd", keyId = "TastaS", keyName = "nTastaS", label = "Somatie" }

-- HUD Dragging State
local hudMoving        = false
local hudMoveArmed     = false
local hudMoveStartTime = 0
local hudLastWidth     = 230
local hudLastHeight    = 180
local hudPosX          = new.int(0)
local hudPosY          = new.int(0)
local hudCacheDirty    = true

-- Windows & Smooth Fade Animations
local FADE_DURATION = 0.25
local mainWin = {
    open = new.bool(false), visible = false, closing = false,
    fadeStart = 0, alpha = 0.0, tab = 1
}
local sanWin = {
    open = new.bool(false), visible = false, closing = false,
    fadeStart = 0, alpha = 0.0, subTab = 1
}
local blWin = {
    open = new.bool(false), visible = false, closing = false,
    fadeStart = 0, alpha = 0.0
}
local guideWin = {
    open = new.bool(false), visible = false, closing = false,
    fadeStart = 0, alpha = 0.0, tab = 1
}
local rulesWin = {
    open = new.bool(false), visible = false, closing = false,
    fadeStart = 0, alpha = 0.0
}

-- Rules Viewer State (TaxiAssist RulesBZone Style)
local activeRuleSet     = 1
local activeChapter     = 1
local rulesLangOverride = nil -- nil = synced with cfg.settings.limba, "ro" or "en"
local buf_rulesSearch   = new.char[256]()
local lastRulesSearch   = ""
local highlightRuleId   = nil
local highlightRuleTime = 0

-- ImGui Input Buffers (dimensionate strict pt limita de 128 caractere SA-MP)
local buf_zona       = new.char[41]()   -- max 40 chr (incape in toate mesajele radar/sanctiuni <= 128)
local buf_limita     = new.char[16]()
local buf_cmd        = new.char[20]()   -- max 19 chr
local buf_fvrR       = new.char[126]()  -- "/r " (3) + 125 = max 128 chr
local buf_fvrD       = new.char[126]()  -- "/d " (3) + 125 = max 128 chr
local buf_fvrF       = new.char[126]()  -- "/d " (3) + 125 = max 128 chr
local buf_fvrStop    = new.char[126]()  -- "/d " (3) + 125 = max 128 chr
local buf_fvrSec     = new.char[16]()
local buf_gov1       = new.char[124]()  -- "/gov " (5) + 123 = max 128 chr
local buf_gov2       = new.char[124]()  -- "/gov " (5) + 123 = max 128 chr
local buf_gov3       = new.char[124]()  -- "/gov " (5) + 123 = max 128 chr
local buf_sanId      = new.char[16]()
local buf_cmdSearch  = new.char[128]()
local buf_blAdd      = new.char[256]()

local customCmdBuffers = {}
for i = 1, CUSTOM_CMD_MAX do
    customCmdBuffers[i] = {
        cmd  = new.char[32](),
        text = new.char[256](), -- suporta variabile dinamice (<Nume (ID)>, <ID>, etc.) + comenzi multiple cu ' | '
    }
end
local showCustomVarsHelp = new.bool(true)

local blBuffers = {}
for i = 1, 9 do
    blBuffers[i] = new.char[256]()
end

local function safeCopyBuf(dst, val)
    local maxLen = ffi.sizeof(dst) - 1
    local s = tostring(val or ""):sub(1, maxLen)
    ffi.fill(dst, ffi.sizeof(dst))
    ffi.copy(dst, s, #s)
end

local function syncBuffersFromCfg()
    safeCopyBuf(buf_zona,    cfg.radar.zona or "")
    safeCopyBuf(buf_limita,  cfg.radar.limita or 100)
    safeCopyBuf(buf_cmd,     cfg.cmd.cmd or "cmd")
    safeCopyBuf(buf_fvrR,    cfg.fvr.fvrR or "")
    safeCopyBuf(buf_fvrD,    cfg.fvr.fvrD or "")
    safeCopyBuf(buf_fvrF,    cfg.fvr.fvrF or "")
    safeCopyBuf(buf_fvrStop, cfg.fvr.fvrStop or "")
    safeCopyBuf(buf_fvrSec,  cfg.fvr.secunde or 10)
    safeCopyBuf(buf_gov1,    cfg.gov.gov1 or "")
    safeCopyBuf(buf_gov2,    cfg.gov.gov2 or "")
    safeCopyBuf(buf_gov3,    cfg.gov.gov3 or "")
    for i = 1, CUSTOM_CMD_MAX do
        safeCopyBuf(customCmdBuffers[i].cmd,  cfg.comenzi["cmd" .. i] or "")
        safeCopyBuf(customCmdBuffers[i].text, cfg.comenzi["txt" .. i] or "")
    end
    for i = 1, 9 do
        safeCopyBuf(blBuffers[i], cfg.blacklist["bl" .. i] or "-")
    end
end
syncBuffersFromCfg()

-- =========================================================================================
--  SECTION 3: DESIGN TOKENS, THEME & ANIMATION HELPERS (TaxiAssist + LSSI Style)
-- =========================================================================================
local colors = {
    accent       = imgui.ImVec4(0.16, 0.69, 0.88, 1.00), -- #28AFE0 Police Cyan-Blue
    accentHover  = imgui.ImVec4(0.26, 0.78, 0.96, 1.00),
    accentActive = imgui.ImVec4(0.11, 0.54, 0.72, 1.00),
    accentDim    = imgui.ImVec4(0.16, 0.69, 0.88, 0.14),

    royal        = imgui.ImVec4(0.20, 0.45, 0.95, 1.00),
    royalHover   = imgui.ImVec4(0.30, 0.55, 1.00, 1.00),
    gold         = imgui.ImVec4(1.00, 0.75, 0.18, 1.00),
    goldHover    = imgui.ImVec4(1.00, 0.82, 0.32, 1.00),
    green        = imgui.ImVec4(0.14, 0.72, 0.42, 1.00),
    greenHover   = imgui.ImVec4(0.20, 0.85, 0.52, 1.00),
    red          = imgui.ImVec4(0.82, 0.22, 0.25, 1.00),
    redHover     = imgui.ImVec4(0.95, 0.30, 0.33, 1.00),
    orange       = imgui.ImVec4(0.95, 0.55, 0.15, 1.00),

    dark         = imgui.ImVec4(0.05, 0.06, 0.09, 0.98),
    panel        = imgui.ImVec4(0.08, 0.10, 0.14, 0.96),
    cardBg       = imgui.ImVec4(0.11, 0.13, 0.19, 1.00),
    cardHover    = imgui.ImVec4(0.16, 0.20, 0.28, 1.00),
    cardActive   = imgui.ImVec4(0.20, 0.26, 0.36, 1.00),

    textPrimary  = imgui.ImVec4(0.95, 0.97, 0.99, 1.00),
    textMuted    = imgui.ImVec4(0.58, 0.63, 0.72, 1.00),
    textDim      = imgui.ImVec4(0.40, 0.45, 0.54, 1.00),
    separator    = imgui.ImVec4(0.18, 0.24, 0.34, 0.75),
}

local function easeOutCubic(t)
    t = t - 1
    return t * t * t + 1
end

local function openAnimWin(w)
    w.visible   = true
    w.closing   = false
    w.fadeStart = os.clock()
    w.open[0]   = true
end

local function closeAnimWin(w)
    if w.visible and not w.closing then
        w.closing   = true
        w.fadeStart = os.clock()
    end
end

local function toggleAnimWin(w)
    if w.visible and not w.closing then
        closeAnimWin(w)
    else
        openAnimWin(w)
    end
end

local function updateAnimWin(w)
    local elapsed = os.clock() - w.fadeStart
    local p = math.min(1.0, math.max(0.0, elapsed / FADE_DURATION))
    if w.closing then
        local inv = 1.0 - p
        w.alpha = easeOutCubic(inv)
        if p >= 1.0 then
            w.visible = false
            w.closing = false
            w.open[0] = false
            w.alpha   = 0.0
        end
    else
        w.alpha = easeOutCubic(p)
    end
end

local function PushButtonColors(normal, hovered, active)
    imgui.PushStyleColor(imgui.Col.Button, normal)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, hovered)
    imgui.PushStyleColor(imgui.Col.ButtonActive, active or hovered)
end

local function Tooltip(text)
    imgui.SameLine()
    imgui.TextDisabled("(?)")
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(imgui.GetFontSize() * 32.0)
        imgui.Text("%s", tostring(text))
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

local function ApplyTheme()
    local style = imgui.GetStyle()
    style.WindowRounding    = 12
    style.ChildRounding     = 10
    style.FrameRounding     = 8
    style.PopupRounding     = 10
    style.ScrollbarRounding = 10
    style.GrabRounding      = 6
    style.WindowBorderSize  = 1
    style.ChildBorderSize   = 1
    style.FrameBorderSize   = 0
    style.PopupBorderSize   = 1
    style.WindowPadding     = imgui.ImVec2(18, 18)
    style.FramePadding      = imgui.ImVec2(12, 7)
    style.ItemSpacing       = imgui.ImVec2(9, 9)
    style.ItemInnerSpacing  = imgui.ImVec2(7, 5)
    style.ScrollbarSize     = 8
    style.GrabMinSize       = 8

    local c = style.Colors
    c[imgui.Col.Text]                 = colors.textPrimary
    c[imgui.Col.TextDisabled]         = colors.textMuted
    c[imgui.Col.WindowBg]             = colors.dark
    c[imgui.Col.ChildBg]              = colors.panel
    c[imgui.Col.PopupBg]              = imgui.ImVec4(0.08, 0.10, 0.15, 0.98)
    c[imgui.Col.Border]               = imgui.ImVec4(0.16, 0.69, 0.88, 0.35)
    c[imgui.Col.Separator]            = colors.separator
    c[imgui.Col.TitleBg]              = colors.panel
    c[imgui.Col.TitleBgActive]        = colors.panel
    c[imgui.Col.TitleBgCollapsed]     = colors.panel
    c[imgui.Col.FrameBg]              = imgui.ImVec4(0.13, 0.16, 0.23, 1.00)
    c[imgui.Col.FrameBgHovered]       = imgui.ImVec4(0.18, 0.23, 0.33, 1.00)
    c[imgui.Col.FrameBgActive]        = imgui.ImVec4(0.22, 0.30, 0.42, 1.00)
    c[imgui.Col.Button]               = colors.cardBg
    c[imgui.Col.ButtonHovered]        = colors.cardHover
    c[imgui.Col.ButtonActive]         = colors.cardActive
    c[imgui.Col.Header]               = imgui.ImVec4(0.14, 0.20, 0.28, 1.00)
    c[imgui.Col.HeaderHovered]        = imgui.ImVec4(0.18, 0.28, 0.38, 1.00)
    c[imgui.Col.HeaderActive]         = imgui.ImVec4(0.22, 0.35, 0.48, 1.00)
    c[imgui.Col.ScrollbarBg]          = imgui.ImVec4(0.06, 0.08, 0.12, 0.40)
    c[imgui.Col.ScrollbarGrab]        = imgui.ImVec4(0.20, 0.38, 0.52, 0.80)
    c[imgui.Col.ScrollbarGrabHovered] = colors.accent
    c[imgui.Col.ScrollbarGrabActive]  = colors.accentActive
    c[imgui.Col.CheckMark]            = colors.accent
    c[imgui.Col.SliderGrab]           = colors.accent
    c[imgui.Col.SliderGrabActive]     = colors.accentHover
end

-- =========================================================================================
--  SECTION 4: TOAST NOTIFICATION SYSTEM (TaxiAssist Style)
-- =========================================================================================
local notifications   = {}
local NOTIF_DURATION  = 3.5
local NOTIF_FADE_IN   = 0.30
local NOTIF_FADE_OUT  = 0.45
local NOTIF_WIDTH     = 330
local NOTIF_HEIGHT    = 66
local NOTIF_MAX       = 4
local NOTIF_MARGIN    = 20
local NOTIF_SPACING   = 8
local NOTIF_BAR_W     = 5
local NOTIF_PROG_H    = 3

local notifTypes = {
    info = {
        r = 0.16, g = 0.69, b = 0.88,
        title = "PD ASSIST",
        icon  = fa.ICON_FA_SHIELD_ALT,
        sound = 1058
    },
    radar = {
        r = 1.00, g = 0.72, b = 0.15,
        title = "RADAR ALERT",
        icon  = fa.ICON_FA_TACHOMETER_ALT,
        sound = 1054
    },
    sanction = {
        r = 0.92, g = 0.28, b = 0.28,
        title = "SANCTIUNE / WANTED",
        icon  = fa.ICON_FA_GAVEL,
        sound = 1085
    },
    saved = {
        r = 0.14, g = 0.78, b = 0.45,
        title = "SALVAT",
        icon  = fa.ICON_FA_CHECK_CIRCLE,
        sound = 1057
    },
    timer = {
        r = 0.62, g = 0.42, b = 1.00,
        title = "TIMER EXPIRAT",
        icon  = fa.ICON_FA_CLOCK,
        sound = 1056
    },
    error = {
        r = 1.00, g = 0.54, b = 0.24,
        title = "EROARE",
        icon  = fa.ICON_FA_EXCLAMATION_CIRCLE,
        sound = 1085
    }
}

local function addNotification(text, typeKey)
    local nCfg = notifTypes[typeKey] or notifTypes.info
    if cfg.settings.notifType == 1 then
        printStringNow("~b~(PDAssist)~w~ " .. tostring(pdxTr and pdxTr(tostring(text)) or text), 1500)
        if nCfg.sound then addOneOffSound(0, 0, 0, nCfg.sound) end
        return
    end
    table.insert(notifications, {
        text      = tostring(text),
        config    = nCfg,
        startTime = os.clock(),
        duration  = NOTIF_DURATION,
    })
    while #notifications > NOTIF_MAX do
        table.remove(notifications, 1)
    end
    if nCfg.sound then
        addOneOffSound(0, 0, 0, nCfg.sound)
    end
end

-- =========================================================================================
--  SECTION 5: UTILITY FUNCTIONS & GAME HELPERS
-- =========================================================================================
local cachedSw, cachedSh = 0, 0
local lastResCheck = 0
local function getScreenResCached()
    local now = os.clock()
    if now - lastResCheck > 1.5 or cachedSw == 0 then
        cachedSw, cachedSh = getScreenResolution()
        lastResCheck = now
    end
    return cachedSw, cachedSh
end

local function saveCfg()
    inicfg.save(cfg, CONFIG_FILE)
    hudCacheDirty = true
end

local function isRo()
    return (tonumber(cfg.settings.limba) or 1) == 1
end

local function getFaction()
    local f = tostring(cfg.settings.faction or "LSPD"):upper()
    for _, valid in ipairs(FACTIONS) do
        if f == valid then return f end
    end
    return "LSPD"
end

local function isPdFaction()
    local f = getFaction()
    return (f == "LSPD" or f == "LVPD" or f == "SFPD")
end

-- FBI si NG NU au niciodata Rutiera (nici pe HUD, nici in meniul de taste, nici ca bifa)
local function isRutieraActive()
    if not isPdFaction() then return false end
    return tostring(cfg.settings.pdTeam or "RUTIERA") ~= "SWAT"
end

local function getFactionRuleSetIndex()
    local f = getFaction()
    if f == "FBI" then return 3
    elseif f == "NG" then return 4
    else return 2 end
end

local function openRulesWindow(forceFactionRules)
    if forceFactionRules then
        activeRuleSet = getFactionRuleSetIndex()
        activeChapter = 1
    end
    openAnimWin(rulesWin)
end

-- =========================================================================================
--  SECTION 5B: HOTKEY ACTIONS (K / L), CUSTOM-CMD VARIABLE PICKER DATA (PDX namespace)
-- =========================================================================================
local PDX = {}

PDX.BASE_ACTIONS = {
    { id = "SAN",    label = "Meniu Sanctiuni (/san)" },
    { id = "PDC",    label = "Panou Setari (/pdc)" },
    { id = "RULES",  label = "Regulamente (/reguli)" },
    { id = "BL",     label = "Personal Blacklist (/pdbl)" },
    { id = "GUIDE",  label = "Ghid Comenzi" },
    { id = "PUNISH", label = "Punish cel mai apropiat (/ps)" },
    { id = "FRISK",  label = "Frisk pe raza" },
    { id = "WHEEL",  label = "Roata Interactiune" },
}

function PDX.getActionOptions()
    local list = {}
    for _, a in ipairs(PDX.BASE_ACTIONS) do table.insert(list, a) end
    for i = 1, CUSTOM_CMD_MAX do
        local c = tostring(cfg.comenzi["cmd" .. i] or "")
        if c ~= "" then
            table.insert(list, { id = "CUSTOM:" .. i, label = string.format("Custom #%02d: /%s", i, c) })
        end
    end
    return list
end

function PDX.getActionLabel(id)
    for _, a in ipairs(PDX.getActionOptions()) do
        if a.id == id then return a.label end
    end
    return "-"
end

function PDX.drawActionCombo(comboId, cfgKey)
    local cur = tostring(cfg.settings[cfgKey] or "SAN")
    imgui.PushItemWidth(300)
    if imgui.BeginCombo("##combo_" .. comboId, PDX.getActionLabel(cur)) then
        for _, opt in ipairs(PDX.getActionOptions()) do
            if imgui.Selectable(opt.label .. "##opt_" .. comboId .. opt.id, cur == opt.id) then
                cfg.settings[cfgKey] = opt.id
                saveCfg()
                addNotification("Tasta -> " .. opt.label, "saved")
            end
        end
        imgui.EndCombo()
    end
    imgui.PopItemWidth()
end

-- Variabile disponibile in comenzile custom: { tag, descriere, exemplu rezultat }
PDX.VARS = {
    { "<Nume (ID)>",   "Numele si ID-ul tintei",                 "Kelton (24)" },
    { "<ID (Nume)>",   "ID-ul si numele tintei",                 "24 (Kelton)" },
    { "<Nume>",        "Doar numele tintei",                     "Kelton" },
    { "<ID>",          "Doar ID-ul tintei",                      "24" },
    { "<Nivel>",       "Nivelul tintei",                         "99" },
    { "<Rest>",        "Textul scris dupa ID/nume",              "inceteaza cu pumnii" },
    { "<Apropiat>",    "Cel mai apropiat jucator (fara ID)",     "Kelton (24)" },
    { "<ApropiatNume>","Numele celui mai apropiat jucator",      "Kelton" },
    { "<ApropiatID>",  "ID-ul celui mai apropiat jucator",       "24" },
    { "<Text>",        "Tot ce scrii dupa comanda",              "salut la toti" },
    { "<Arg1>",        "Primul cuvant scris dupa comanda",       "kelt" },
    { "<Arg2>",        "Al doilea cuvant scris dupa comanda",    "inceteaza" },
    { "<Eu>",          "Numele tau",                             "Cristi_NG" },
    { "<MyID>",        "ID-ul tau",                              "7" },
    { "<Dept>",        "Factiunea ta",                           "NG" },
    { "<Ora>",         "Ora curenta",                            "13:25:40" },
    { "<Zona>",        "Zona in care esti (din joc)",            "Idlewood" },
    { "<Find>",        "Suspectul de pe /find: Nume (ID)",       "Kelton (24)" },
    { "<FindNume>",    "Numele suspectului de pe /find",         "Kelton" },
    { "<FindID>",      "ID-ul suspectului de pe /find",          "24" },
    { " | ",           "Separator: trimite urmatoarea comanda",  "mesaj 1 | /punish 24" },
}

PDX.TEMPLATES = {
    "Salut <Nume (ID)>! Stai pe loc!",
    "/punish <ID>",
    "Salut <Nume (ID)>! Stai pe loc! | /punish <ID>",
    "/r <Eu> are nevoie de ajutor langa <Apropiat>",
}

function PDX.appendToBuf(buf, s)
    local cur = ffi.string(buf)
    if #cur + #s < ffi.sizeof(buf) - 1 then
        safeCopyBuf(buf, cur .. s)
    end
end

function PDX.drawVarPicker(slot, targetBuf)
    targetBuf = targetBuf or customCmdBuffers[slot].text
    imgui.TextColored(colors.gold, "%s", "Variabile (hover = exemplu | click = adauga in text)")
    imgui.Separator()
    for _, v in ipairs(PDX.VARS) do
        if imgui.Selectable(v[1] .. "##var_" .. slot .. "_" .. v[1], false) then
            PDX.appendToBuf(targetBuf, v[1])
        end
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.TextColored(colors.accent, "%s", v[2])
            imgui.Text("%s", "Exemplu: " .. v[1] .. "  ->  " .. v[3])
            imgui.EndTooltip()
        end
    end
    imgui.Spacing()
    imgui.TextColored(colors.gold, "%s", "Sabloane gata facute (click = inlocuieste textul)")
    imgui.Separator()
    for ti, tpl in ipairs(PDX.TEMPLATES) do
        if imgui.Selectable(tpl .. "##tpl_" .. slot .. "_" .. ti, false) then
            safeCopyBuf(targetBuf, tpl)
        end
    end
end

-- =========================================================================================
--  SECTION 5C: LIMBA INTERFETEI (RO / EN) - meniuri, HUD, roata, notificari
--  Textele raman scrise in romana in cod; cand e selectata engleza, trec prin dictionarul de mai jos.
--  Functiile de text din imgui (Button, Text, Checkbox...) sunt "invelite" ca sa traduca automat.
--  (Mesajele din chat si cele trimise jucatorilor NU se traduc aici - pt ele e "Limba Sanctiuni".)
-- =========================================================================================
PDX.uiLang  = (tostring(cfg.settings.uiLang or "ro") == "en") and "en" or "ro"
PDX.trCache = {}
PDX.trCacheN = 0

PDX.EN = {
    -- notificari (titluri)
    ["PD ASSIST"] = "PD ASSIST", ["RADAR ALERT"] = "RADAR ALERT", ["SANCTIUNE / WANTED"] = "SANCTION / WANTED",
    ["SALVAT"] = "SAVED", ["TIMER EXPIRAT"] = "TIMER EXPIRED",
    -- actiuni tasta K / L
    ["Meniu Sanctiuni (/san)"] = "Sanctions Menu (/san)", ["Panou Setari (/pdc)"] = "Settings Panel (/pdc)",
    ["Regulamente (/reguli)"] = "Rules (/reguli)", ["Personal Blacklist (/pdbl)"] = "Personal Blacklist (/pdbl)",
    ["Ghid Comenzi"] = "Commands Guide", ["Punish cel mai apropiat (/ps)"] = "Punish nearest (/ps)",
    ["Frisk pe raza"] = "Frisk in radius", ["Roata Interactiune"] = "Interaction Wheel",
    ["Variabile (hover = exemplu | click = adauga in text)"] = "Variables (hover = example | click = add to text)",
    ["Sabloane gata facute (click = inlocuieste textul)"] = "Ready-made templates (click = replace text)",
    ["Exemplu"] = "Example",
    -- notificari (texte)
    ["Pozitia HUD resetata la default"] = "HUD position reset to default", ["Find anulat"] = "Find cancelled",
    ["AFK oprit: jucatorul a revenit"] = "AFK stopped: player is back", ["Bombe confiscate"] = "Bombs confiscated",
    ["Sanctiune aplicata"] = "Sanction applied", ["Jucator nivel 1-4 (protejat)"] = "Level 1-4 player (protected)",
    ["Sanctiune materiale"] = "Materials sanction", ["Intrebare sanctiune (Nivel 5-7)"] = "Sanction question (Level 5-7)",
    ["Permis confiscat (Jail)"] = "License confiscated (Jail)", ["Permis + Amenda"] = "License + Ticket",
    ["FVR efectuat cu succes!"] = "FVR done successfully!", ["FVR a fost anulat!"] = "FVR was cancelled!",
    ["Anuntul /gov a fost trimis!"] = "The /gov announcement was sent!", ["Radar pornit"] = "Radar started",
    ["Radar oprit"] = "Radar stopped", ["Radar reluat"] = "Radar resumed", ["Cuff aplicat"] = "Cuff applied",
    ["Timer AFK oprit"] = "AFK timer stopped", ["Pozitia HUD salvata cu succes!"] = "HUD position saved!",
    ["Mutarea HUD anulata"] = "HUD move cancelled", ["Setarea tastei anulata"] = "Key binding cancelled",
    ["Au trecut 3 secunde!"] = "3 seconds have passed!", ["Au trecut 10 secunde!"] = "10 seconds have passed!",
    ["Start-Stop: Motor oprit (economie combustibil)"] = "Start-Stop: Engine off (saving fuel)",
    ["Parola salvata"] = "Password saved", ["PIN salvat"] = "PIN saved", ["Datele de cont au fost sterse"] = "Account data deleted",
    ["Culorile au fost resetate"] = "Colors were reset", ["Departament setat"] = "Department set",
    ["Echipa setata"] = "Team set", ["Rutiera"] = "Traffic", ["SWAT (Rutiera ascunsa)"] = "SWAT (Traffic hidden)",
    ["Notificari ImGui activate!"] = "ImGui notifications enabled!", ["Notificari clasice activate!"] = "Classic notifications enabled!",
    ["HUD: stil modern"] = "HUD: modern style", ["HUD: stil clasic PDHelper"] = "HUD: classic PDHelper style",
    ["Limita radar setata"] = "Radar limit set", ["Setarile FVR au fost salvate!"] = "FVR settings saved!",
    ["Liniile /gov au fost salvate!"] = "The /gov lines were saved!", ["Comanda setata"] = "Command set",
    ["Comenzile custom au fost salvate!"] = "Custom commands saved!", ["Adauga comanda custom"] = "Add custom command", ["Adauga keybind custom"] = "Add custom keybind",
    ["Personal Blacklist salvat!"] = "Personal Blacklist saved!", ["Blacklist ascuns de pe ecran"] = "Blacklist hidden from screen",
    ["Blacklist fixat pe ecran! (/pdbl pt editare)"] = "Blacklist pinned on screen! (/pdbl to edit)",
    ["Eject"] = "Eject", ["Frisk"] = "Frisk", ["Auto-Arrest executat pe ID"] = "Auto-Arrest done on ID",
    ["Anulare automata /find"] = "Automatic /find cancel", ["Verificare nefondat"] = "Unfounded-call check",
    ["Login automat"] = "Auto login", ["PIN automat"] = "Auto PIN", ["HUD Indicator"] = "HUD Indicator",
    ["Comenzi prescurtate"] = "Shortcut commands", ["Explicatii sanctiuni: Romana"] = "Sanction texts: Romanian",
    ["Sanctions language: English"] = "Sanction texts: English",
    -- HUD (etichete)
    ["ROATA INTERACT"] = "INTERACT WHEEL", ["SOMATIE (/MS)"] = "SUMMONS (/MS)", ["CUFF & ARREST"] = "CUFF & ARREST",
    ["TAZER"] = "TAZER", ["WANTED"] = "WANTED", ["NEARWANTED"] = "NEARWANTED", ["REPAIR"] = "REPAIR", ["FIND"] = "FIND",
    ["SOMATIE /MM"] = "SUMMONS /MM", ["ASTEPTARE /D"] = "WAITING /D", ["TIMER AFK"] = "AFK TIMER", ["FVR IN CURS"] = "FVR IN PROGRESS",
    ["MENIU SANCTIUNI"] = "SANCTIONS MENU", ["PANOU SETARI"] = "SETTINGS PANEL", ["REGULAMENTE"] = "RULES",
    ["PERSONAL BLACKLIST"] = "PERSONAL BLACKLIST", ["GHID COMENZI"] = "COMMANDS GUIDE", ["PUNISH CEL MAI APROPIAT"] = "PUNISH NEAREST",
    ["FRISK PE RAZA"] = "FRISK IN RADIUS", ["ROATA INTERACTIUNE"] = "INTERACTION WHEEL", ["FRISK"] = "FRISK",
    ["RADAR"] = "RADAR", ["RADAR PAUZA"] = "RADAR PAUSED", ["RADAR (IESIT DIN AUTO)"] = "RADAR (OUT OF CAR)",
    ["RADAR ACTIV"] = "RADAR ACTIVE", ["TASTA #"] = "KEY #",
    -- sidebar + status
    ["General"] = "General", ["Radar"] = "Radar", ["Automatizari"] = "Automations", ["Taste & HUD"] = "Keys & HUD",
    ["Aspect"] = "Appearance", ["FVR & GOV"] = "FVR & GOV", ["Comenzi Custom"] = "Custom Commands", ["Cont & PIN"] = "Account & PIN",
    ["MENIU"] = "MENU", ["STATUS"] = "STATUS", ["niciuna"] = "none",
    -- Automatizari
    ["URMARIRE (/find), AFK & SOMATIE"] = "PURSUIT (/find), AFK & SUMMONS",
    ["Anulare automata /find (suspect arestat / omorat / deconectat / /clear)"] = "Automatic /find cancel (suspect arrested / killed / disconnected / /clear)",
    ["Citeste mesajele HQ. Cand apare numele suspectului tau cu arestat/omorat/deconectat/cazier etc., scrie motivul in chat si da /cancel find."] = "Reads HQ messages. When your suspect's name appears with arrested/killed/disconnected/cleared etc., it writes the reason in chat and does /cancel find.",
    ["Urmarire curenta"] = "Current pursuit", ["Anuleaza"] = "Cancel",
    ["/afk = AFK cu clepsidra (3 min)  |  /ffk = fara clepsidra (30s)  |  fara ID = suspectul de pe /find"] = "/afk = AFK with hourglass (3 min)  |  /ffk = no hourglass (30s)  |  no ID = your /find suspect",
    ["/afk sau /ffk din nou = 'a revenit din afk'  |  dupa kill anunta singur pe /d ca nu a revenit"] = "/afk or /ffk again = 'is back from afk'  |  after the kill it announces on /d that he didn't come back",
    ["/ms <id> = daca nu ai /find pe el, ii da intai /find, apoi /ms"] = "/ms <id> = if you don't have /find on him, it does /find first, then /ms",
    ["NEFONDAT DUBLU (// si /nef)"] = "DOUBLE UNFOUNDED CALL (// and /nef)",
    ["Opreste nefondatul daca un coleg l-a anuntat deja pe acelasi jucator"] = "Stop the unfounded call if a colleague already announced the same player",
    ["Recunoaste si nume incomplete (min. 3 litere) sau ID-ul. Fara nume -> te intreaba. Comanda data din nou in 5s forteaza."] = "Also recognizes partial names (min. 3 letters) or the ID. No name -> it asks you. The same command again within 5s forces it.",
    ["Fereastra de verificare"] = "Check window", ["%d secunde"] = "%d seconds", ["SPAWN RAPID"] = "QUICK SPAWN",
    ["Da /spawnchange si alege singur randul potrivit (dupa text, nu dupa pozitie)."] = "Does /spawnchange and picks the right row by itself (by text, not by position).",
    -- Keybinduri custom
    ["KEYBINDURI PERSONALIZATE: TASTA -> TEXT / COMENZI"] = "CUSTOM KEYBINDS: KEY -> TEXT / COMMANDS",
    ["Acelasi format ca la Comenzi Custom: variabile (<Find>, <Apropiat>, <Eu>...) si ' | ' pt mai multe comenzi."] = "Same format as Custom Commands: variables (<Find>, <Apropiat>, <Eu>...) and ' | ' for multiple commands.",
    ["Daca textul cere <Nume>/<ID>, se foloseste suspectul de pe /find."] = "If the text needs <Nume>/<ID>, your /find suspect is used.",
    ["Nume in HUD"] = "Name in HUD", ["[ APASA... ]"] = "[ PRESS... ]", ["[ APASA TASTA... ]"] = "[ PRESS A KEY... ]",
    ["Ex: /r Am nevoie de ajutor langa <Apropiat> | /ms"] = "Ex: /r I need help near <Apropiat> | /ms",
    -- Cont & PIN
    ["Criptat cu Windows (DPAPI): nu poate fi citit pe alt PC sau alt cont de Windows."] = "Encrypted with Windows (DPAPI): cannot be read on another PC or Windows account.",
    ["Criptarea Windows nu a mers: e doar codificat (hex), ca la NG-Helper."] = "Windows encryption failed: it's only encoded (hex), like NG-Helper.",
    ["Nimic salvat."] = "Nothing saved.", ["LOGIN AUTOMAT"] = "AUTO LOGIN",
    ["Completeaza automat parola in dialogul de login al serverului"] = "Automatically fill the password in the server login dialog",
    ["Parola"] = "Password", ["Arata"] = "Show", ["Salveaza parola"] = "Save password", ["Status"] = "Status",
    ["Doar in dialogul de login, dupa ~0.5s, litera cu litera (rapid). Max 3 incercari / 30s. Daca scrii tu in dialog, se opreste."] = "Only in the login dialog, after ~0.5s, letter by letter (fast). Max 3 tries / 30s. If you type in the dialog yourself, it stops.",
    ["PIN AUTOMAT"] = "AUTO PIN", ["Introdu automat PIN-ul pe tastatura de pe ecran (/pin)"] = "Automatically enter the PIN on the on-screen keypad (/pin)",
    ["PIN (4 cifre)"] = "PIN (4 digits)", ["Salveaza PIN"] = "Save PIN",
    ["La 'Bine ai venit' trimite /pin si apasa cifrele. Merge si la /pin dat de tine sau de /dt si /hdt."] = "On 'Welcome' it sends /pin and presses the digits. Also works with /pin typed by you or by /dt and /hdt.",
    ["Sterge parola si PIN-ul salvate"] = "Delete saved password and PIN",
    ["Nu da nimanui folderul moonloader/config, chiar daca parola e criptata."] = "Don't give anyone your moonloader/config folder, even if the password is encrypted.",
    ["Oprit"] = "Off", ["Astept dialogul de login..."] = "Waiting for the login dialog...", ["Introduc parola..."] = "Entering password...",
    ["Parola trimisa"] = "Password sent", ["Limita de 3 incercari atinsa. Verifica parola."] = "3-try limit reached. Check the password.",
    ["Nu ai salvat parola (sau nu se poate decripta pe acest PC)"] = "No password saved (or it can't be decrypted on this PC)",
    -- Aspect
    ["Albastru"] = "Blue", ["Verde"] = "Green", ["Rosu"] = "Red", ["Auriu"] = "Gold", ["Mov"] = "Purple", ["Alb"] = "White",
    ["CULORI HUD (MODERN SI CLASIC) - se vad imediat pe ecran"] = "HUD COLORS (MODERN AND CLASSIC) - applied instantly on screen",
    ["Accent"] = "Accent", ["Text / taste"] = "Text / keys", ["Iconite (HUD clasic)"] = "Icons (classic HUD)", ["Titlu (scut + ASSIST)"] = "Title (shield + ASSIST)",
    ["HUD clasic: etichetele (PANOU SETARI, FRISK...). HUD modern: iconitele si tastele."] = "Classic HUD: the labels (SETTINGS PANEL, FRISK...). Modern HUD: icons and keys.",
    ["HUD clasic: tastele (K, P, num+...). HUD modern: etichetele."] = "Classic HUD: the keys (K, P, num+...). Modern HUD: the labels.",
    ["Preseturi rapide pt accent + titlu"] = "Quick presets for accent + title", ["CULORI NOTIFICARI"] = "NOTIFICATION COLORS",
    ["Fundal card"] = "Card background", ["Text mesaj"] = "Message text", ["Opacitate fundal"] = "Background opacity",
    ["Tip: Info"] = "Type: Info", ["Tip: Radar"] = "Type: Radar", ["Tip: Sanctiune / Wanted"] = "Type: Sanction / Wanted",
    ["Tip: Salvat"] = "Type: Saved", ["Tip: Timer"] = "Type: Timer", ["PREVIEW NOTIFICARE"] = "NOTIFICATION PREVIEW",
    ["Info"] = "Info", ["Sanctiune"] = "Sanction", ["Salvat"] = "Saved", ["Timer"] = "Timer",
    ["Arata pe ecran"] = "Show on screen", ["Ai notificari Clasice (General) -"] = "You have Classic notifications (General) -",
    ["cardul apare doar pe Toast ImGui."] = "the card only appears with Toast ImGui.", ["Reseteaza toate culorile"] = "Reset all colors",
    ["Setarile au fost salvate!"] = "Settings saved!", ["Timpul AFK a expirat!"] = "AFK time expired!",
    -- /pdc General
    ["PANOU CONFIGURARE (/pdc)"] = "SETTINGS PANEL (/pdc)", ["DEPARTAMENT & LIMBA EXPLICATII SANCTIUNI"] = "DEPARTMENT & SANCTION TEXTS LANGUAGE",
    ["Limba Sanctiuni"] = "Sanctions language", ["Limba interfata"] = "Interface language",
    ["Echipa PD"] = "PD Team", ["Rutiera (Radar & Trafic Activ)"] = "Traffic (Radar & Traffic active)", ["SWAT (Fara Radar & Rutiera)"] = "SWAT (No Radar & Traffic)",
    ["AFISARE INDICATORI & POZITIONARE HUD"] = "INDICATORS DISPLAY & HUD POSITION",
    ["Afiseaza HUD-ul cu taste si timere pe ecran (Dreapta)"] = "Show the HUD with keys and timers on screen",
    ["Stil HUD"] = "HUD style", ["Modern (dreapta, cu iconite)"] = "Modern (right, with icons)",
    ["Clasic PDHelper (jos, deasupra rpg.b-zone.ro)"] = "Classic PDHelper (bottom, above rpg.b-zone.ro)",
    ["Stil Notificari"] = "Notifications style", ["Toast Modern ImGui"] = "Modern ImGui Toast", ["Clasic Pe Ecran"] = "Classic On Screen",
    ["Stil Meniu /san"] = "/san menu style", ["Meniu Modern Mimgui"] = "Modern Mimgui menu", ["Dialog Clasic SA-MP"] = "Classic SA-MP dialog",
    ["Muta HUD cu Mouse-ul (/hudpos)"] = "Move HUD with the mouse (/hudpos)", ["Reseteaza Pozitia HUD (/resethud)"] = "Reset HUD position (/resethud)",
    ["Pozitie HUD clasic PDHelper (marginea dreapta / sus)"] = "Classic PDHelper HUD position (right / top edge)",
    ["Pozitie HUD modern (marginea dreapta / sus)"] = "Modern HUD position (right / top edge)",
    ["Pozitie X"] = "Position X", ["Pozitie Y"] = "Position Y", ["%d px"] = "%d px",
    -- Radar
    ["CONFIGURARE ZONA & LIMITA RADAR"] = "RADAR ZONE & LIMIT SETUP", ["Zona Radar"] = "Radar zone", ["Limita"] = "Limit",
    ["Ex: Temple LS / Autostrada LS-LV"] = "Ex: Temple LS / LS-LV Highway", ["SETEAZA"] = "SET",
    ["Preset-uri rapide limita"] = "Quick limit presets",
    ["Preseturi zona radar (click = seteaza zona + limita)"] = "Radar zone presets (click = set zone + limit)",
    ["Efectueaza control de rutina (/frisk) celui mai apropiat jucator (fiecare jucator max o data la 2 min)."] = "Routine check (/frisk) on the nearest player (each player max once every 2 min).", ["ULTIMII JUCATORI SURPRINSI PE RADAR (/last & /sl)"] = "LAST PLAYERS CAUGHT ON RADAR (/last & /sl)",
    ["Find"] = "Find", ["Sanctioneaza (/sl)"] = "Sanction (/sl)",
    -- Automatizari (vechi)
    ["MODULE DE AUTOMATIZARE VEHICUL & PATRULA"] = "VEHICLE & PATROL AUTOMATION",
    ["Auto-Engine (Porneste motorul automat cand urci in vehicul)"] = "Auto-Engine (starts the engine when you get in)",
    ["Start-Stop System (Opreste motorul dupa 10s pe loc, reporneste pe W/S)"] = "Start-Stop System (engine off after 10s idle, restarts on W/S)",
    ["Porti Jail / NG, bariere HQ & lifturi pe tasta"] = "Jail / NG gates, HQ barriers & elevators on key",
    ["Comenzi Prescurtate Active (/fd, /cf, /kc, /rr, /shb, /shu, etc.)"] = "Shortcut commands active (/fd, /cf, /kc, /rr, /shb, /shu, etc.)",
    ["Raza de actionare Frisk pe tasta (metri)"] = "Frisk key radius (meters)", ["%.1f m"] = "%.1f m",
    -- Taste
    ["CONFIGURARE TASTE RAPIDE (CLICK & APASA TASTA, ESC ANULEAZA)"] = "QUICK KEYS SETUP (CLICK & PRESS A KEY, ESC CANCELS)",
    ["Tasta"] = "Key", ["Tasta Principala (K)"] = "Main key (K)", ["Tasta Secundara (L)"] = "Secondary key (L)",
    ["Alege mai jos ce actiune/comanda se executa pe aceasta tasta."] = "Choose below which action/command runs on this key.",
    ["Actiune pe tasta principala"] = "Main key action", ["Actiune pe tasta secundara"] = "Secondary key action",
    ["Tasta aditionala pentru o a doua actiune/comanda (implicit OFF)."] = "Extra key for a second action/command (OFF by default).",
    ["Roata Interactiune (implicit OFF)"] = "Interaction Wheel (OFF by default)",
    ["Roata stil GTA V. Sofer: Eject / Cuff / Uncuff pe pasageri. Pe jos: Interact -> jucator -> Frisk / Confisca / Wanted / Sanctiuni / Find / Licente, iar in Jail si Cuff / Punish. Click stanga alege, click dreapta inapoi."] = "GTA V style wheel. Driver: Eject / Cuff / Uncuff passengers. On foot: Interact -> player -> Frisk / Confiscate / Wanted / Sanctions / Licenses, and in Jail also Cuff / Punish. Left click selects, right click goes back.",
    ["Raza 'Interact' pe jos"] = "On-foot 'Interact' radius", ["%d metri"] = "%d meters", ["Mod tasta roata"] = "Wheel key mode",
    ["Hold (tii apasat)"] = "Hold (keep pressed)", ["Touch (apesi o data)"] = "Touch (press once)",
    ["Hold: tii tasta, misti mouse-ul pe felie si eliberezi tasta ca sa alegi (submeniurile raman deschise, alegi cu click). Touch: apesi o data ca sa deschizi, alegi cu click, apesi iar ca sa inchizi."] = "Hold: keep the key, move the mouse over a slice and release to select (submenus stay open, choose with click). Touch: press once to open, choose with click, press again to close.",
    ["Somatie Jucator (/ms)"] = "Summon player (/ms)", ["Trimite /ms catre jucatorul pe care ai /find activ."] = "Sends /ms to the player you have /find on.",
    ["Sisteme Radar (Start/Stop/Find)"] = "Radar system (Start/Stop/Find)",
    ["Porneste radarul, opreste + da /find pe vitezoman si reia radarul automat."] = "Starts the radar, stops + /find on the speeder and resumes the radar automatically.",
    ["Cuff & Auto-Arrest"] = "Cuff & Auto-Arrest", ["Da /cuff pasagerului din masina si /arrest automat cand ajungi la punctul de arrest."] = "Cuffs the passenger in your car and auto /arrest when you reach the arrest point.",
    ["Frisk pe Raza"] = "Frisk in radius", ["Efectueaza control de rutina (/frisk) jucatorilor din jur."] = "Routine check (/frisk) on nearby players.",
    ["Tazer (/tazer)"] = "Tazer (/tazer)", ["Activeaza sau dezactiveaza tazerul."] = "Turns the tazer on or off.",
    ["Lista Wanted (/wanted)"] = "Wanted list (/wanted)", ["Deschide lista suspectilor cu wanted."] = "Opens the wanted suspects list.",
    ["NearWanted (/nearwanted)"] = "NearWanted (/nearwanted)", ["Afiseaza suspectii cu wanted din apropiere."] = "Shows nearby wanted suspects.",
    ["Repair Rapid (/repair)"] = "Quick repair (/repair)", ["Trimite /repair cand esti la volan."] = "Sends /repair when you're driving.",
    ["Porti, Bariere & Lifturi"] = "Gates, Barriers & Elevators",
    ["Jail LS (/opengate 1/2), garaj NG (/enter, /exit), lifturi LSPD/LVPD (/goup, /godown) si barierele HQ cand esti in masina."] = "LS Jail (/opengate 1/2), NG garage (/enter, /exit), LSPD/LVPD elevators (/goup, /godown) and HQ barriers when in a car.",
    -- FVR & GOV
    ["SETARI FVR (/afvr & /sfvr)"] = "FVR SETTINGS (/afvr & /sfvr)", ["Trimite anunt si pe /r inainte de /d"] = "Also announce on /r before /d",
    ["Text anunt /r"] = "Announcement text /r", ["Text anunt /d Start"] = "Announcement text /d Start", ["Text anunt /d Final"] = "Announcement text /d End",
    ["Text anunt /d Stop"] = "Announcement text /d Stop", ["Secunde asteptare"] = "Wait seconds", ["SALVEAZA FVR"] = "SAVE FVR",
    ["Porneste FVR (/afvr)"] = "Start FVR (/afvr)", ["Stop (/sfvr)"] = "Stop (/sfvr)",
    ["SETARI ANUNTURI RECRUTARE /GOV (/pdgov)"] = "RECRUITMENT /GOV ANNOUNCEMENTS (/pdgov)", ["Linia 1 /gov"] = "Line 1 /gov",
    ["Activeaza Linia 2 /gov"] = "Enable line 2 /gov", ["Activeaza Linia 3 /gov"] = "Enable line 3 /gov", ["SALVEAZA GOV"] = "SAVE GOV",
    ["Trimite /PDgov Acum"] = "Send /PDgov now",
    -- Comenzi custom
    ["COMANDA PRINCIPALA GHID COMENZI"] = "MAIN COMMANDS GUIDE COMMAND", ["Comanda meniu ghid (fara '/')"] = "Guide menu command (without '/')",
    ["SETEAZA COMANDA"] = "SET COMMAND", ["COMENZI CUSTOM PERSONALIZATE (ARGUMENTE DINAMICE)"] = "CUSTOM COMMANDS (DYNAMIC ARGUMENTS)",
    ["Arata Variabile"] = "Show variables", ["SALVEAZA & ACTIVEAZA COMENZILE CUSTOM"] = "SAVE & ENABLE THE CUSTOM COMMANDS",
    ["Ex: Salut <Nume (ID)>! | /punish <ID>"] = "Ex: Hello <Nume (ID)>! | /punish <ID>",
    -- Ghid
    ["Cauta orice comanda PD, Radar, Wanted sau Scurtatura..."] = "Search any PD, Radar, Wanted or Shortcut command...",
    ["GENERAL & MENIURI DEPARTAMENTE"] = "GENERAL & DEPARTMENT MENUS", ["PD ROADS & RADAR"] = "PD ROADS & RADAR",
    ["SANCTIUNI TRAFIC & PERMIS"] = "TRAFFIC & LICENSE SANCTIONS", ["CONFISCARI ARME, DROGURI & MATERIALE"] = "WEAPONS, DRUGS & MATERIALS CONFISCATIONS",
    ["NG / FBI / SWAT & ACORDARE AUTOMATA WANTED (/su)"] = "NG / FBI / SWAT & AUTOMATIC WANTED (/su)", ["COMENZI PRESCURTATE UZUALE"] = "COMMON SHORTCUT COMMANDS",
    -- bara de jos /pdc
    ["SANCTIUNI (/san)"] = "SANCTIONS (/san)", ["REGULAMENTE (/reguli)"] = "RULES (/reguli)", ["BLACKLIST (/pdbl)"] = "BLACKLIST (/pdbl)",
    ["OPRESTE MODUL"] = "STOP THE MOD",
    -- /san
    ["SANCTIUNI"] = "SANCTIONS", ["ACTIUNI RAPIDE TEREN (/san)"] = "QUICK FIELD ACTIONS (/san)", ["SUSPECT SELECTAT"] = "SELECTED SUSPECT",
    ["Introdu un ID valid mai jos sau alege din Radar / Apropiere"] = "Enter a valid ID below or pick from Radar / Nearby",
    ["[ IN JAIL: FARA TICKET ]"] = "[ IN JAIL: NO TICKET ]", ["ID Jucator"] = "Player ID", ["Ultimul Radar"] = "Last Radar",
    ["Suspect /find"] = "/find suspect", ["Cel mai apropiat jucator"] = "Nearest player",
    ["TRAFIC & PERMIS"] = "TRAFFIC & LICENSE", ["ARME, DROGURI & MATS"] = "WEAPONS, DRUGS & MATS", ["WANTED (/SU) & CONTROALE"] = "WANTED (/SU) & CHECKS",
    ["Sanctiune Automata Radar (/sl pe ID)"] = "Automatic Radar Sanction (/sl on ID)",
    ["Depasire Viteza 10-50 km/h (/aa)"] = "Speeding 10-50 km/h (/aa)", ["Depasire Viteza +50 km/h (/aa50)"] = "Speeding +50 km/h (/aa50)",
    ["Depasire Viteza +100 km/h (/aa100)"] = "Speeding +100 km/h (/aa100)", ["Faruri Stinse (/faruri)"] = "Headlights off (/faruri)",
    ["Mers pe Carosabil (/car)"] = "Walking on the road (/car)", ["Alcoolemie > 1.5 (/alc15)"] = "Alcohol > 1.5 (/alc15)",
    ["Alcoolemie > 3.0 (/alc30)"] = "Alcohol > 3.0 (/alc30)", ["Folosire NOS (/nos)"] = "NOS use (/nos)",
    ["Mers pe Contra-Sens (/con)"] = "Wrong-way driving (/con)", ["Parcare Ilegala (/parc)"] = "Illegal parking (/parc)",
    ["Hidraulice (/hidra)"] = "Hydraulics (/hidra)", ["CONFISCARI ARME, DROGURI & MATERIALE"] = "WEAPONS, DRUGS & MATERIALS CONFISCATIONS",
    ["Arme la Vedere (/arme)"] = "Visible weapons (/arme)", ["Posesie Droguri (/dr)"] = "Drug possession (/dr)",
    ["Consum Droguri (/cdr)"] = "Drug use (/cdr)", ["Wanted 3 Droguri (/wdr)"] = "Wanted 3 Drugs (/wdr)", ["Bombe + Wanted 3 (/bm)"] = "Bombs + Wanted 3 (/bm)",
    ["Materiale Fara Licenta (/matslic)"] = "Materials without license (/matslic)", ["Folosire Materiale (/mats)"] = "Materials use (/mats)",
    ["ACORDARE AUTOMATA WANTED (/SU)"] = "AUTOMATIC WANTED (/SU)", ["Neconformare Ordin (/nec)"] = "Disobeying orders (/nec)",
    ["Runner (/run)"] = "Runner (/run)", ["Apel Nefondat (/nef)"] = "Unfounded call (/nef)", ["Cop Attack (/cat)"] = "Cop Attack (/cat)",
    ["Neplata Amenda (/notp)"] = "Unpaid ticket (/notp)", ["Complice (/comp)"] = "Accomplice (/comp)", ["Posesie/Uz Droguri (/wdr)"] = "Drug possession/use (/wdr)",
    ["CONTROALE, JAIL & SOMATII"] = "CHECKS, JAIL & SUMMONS", ["Punish Jail (/ps)"] = "Punish Jail (/ps)", ["Control Rutina (/cl)"] = "Routine check (/cl)",
    ["Request Licenses (/rl)"] = "Request Licenses (/rl)", ["Perchezitie (/frisk)"] = "Frisk (/frisk)", ["Somatie Wanted (/mm + 3s)"] = "Wanted summons (/mm + 3s)",
    ["Teren Guvernamental (/tg)"] = "Government area (/tg)", ["Anunta Nefondat /d (//)"] = "Announce unfounded /d (//)",
    ["Anunta AFK 3m (/afk ID)"] = "Announce AFK 3m (/afk ID)", ["VITEZA & RADAR"] = "SPEED & RADAR",
    -- Blacklist
    ["LISTA PRIVATA JUCATORI (/pdbl)"] = "PRIVATE PLAYERS LIST (/pdbl)",
    ["Scrie numele jucatorului (si motivul optional). Daca e online, apare cu verde pe overlay!"] = "Write the player's name (and an optional reason). If online, it shows green on the overlay!",
    ["NumeJucator - Motiv..."] = "PlayerName - Reason...", ["Salveaza"] = "Save", ["Inchide"] = "Close",
    -- Roata
    ["ROATA SOFER"] = "DRIVER WHEEL", ["Click stanga: alege"] = "Left click: select", ["Click dreapta: inapoi"] = "Right click: back",
    ["ALEGE JUCATOR"] = "CHOOSE PLAYER", ["Niciun jucator in masina"] = "No players in the car", ["Jucatorul s-a deconectat"] = "The player disconnected",
    ["INTERACT"] = "INTERACT", ["CANCEL FIND"] = "CANCEL FIND", ["SPAWN"] = "SPAWN", ["SHIELD"] = "SHIELD", ["DUTY"] = "DUTY",
    ["SCHIMBA SPAWN"] = "CHANGE SPAWN", ["DUTY + HEAL"] = "DUTY + HEAL", ["HEAL"] = "HEAL", ["CASA"] = "HOUSE", ["GARAJ NG"] = "NG GARAGE",
    ["JAIL"] = "JAIL", ["HQ CLAN"] = "CLAN HQ", ["BUNKER"] = "BUNKER", ["INTERACT - ALEGE JUCATOR"] = "INTERACT - CHOOSE PLAYER",
    ["CONFISCA"] = "CONFISCATE", ["CUFF"] = "CUFF", ["UNCUFF"] = "UNCUFF", ["EJECT"] = "EJECT", ["SANCTIUNI"] = "SANCTIONS",
    ["LICENTE"] = "LICENSES", ["PUNISH"] = "PUNISH", ["ARME"] = "WEAPONS", ["DROGURI"] = "DRUGS", ["BOMBE"] = "BOMBS", ["MATERIALE"] = "MATERIALS",
    ["NECONFORMARE"] = "DISOBEYING", ["ATACARE POLITIST"] = "COP ATTACK", ["FUGAR"] = "RUNNER", ["COMPLICE"] = "ACCOMPLICE",
    ["NEFONDAT"] = "UNFOUNDED", ["PATRUNDERE TEREN"] = "TRESPASSING",
    ["CUFF - ALEGE JUCATOR"] = "CUFF - CHOOSE PLAYER", ["UNCUFF - ALEGE JUCATOR"] = "UNCUFF - CHOOSE PLAYER", ["EJECT - ALEGE JUCATOR"] = "EJECT - CHOOSE PLAYER",
    -- diverse
    ["activat"] = "enabled", ["dezactivat"] = "disabled", ["activata"] = "enabled", ["dezactivata"] = "disabled",
    ["activate"] = "enabled", ["dezactivate"] = "disabled",
    ["Romana"] = "Romanian", ["English"] = "English",
    ["Auto-Engine"] = "Auto-Engine", ["Start-Stop"] = "Start-Stop",
    -- Ghid comenzi (descrieri)
    ["Deschide meniul modern de Sanctiuni, Wanted & Controale"] = "Opens the modern Sanctions, Wanted & Checks menu",
    ["Deschide Regulamentele Oficiale B-Zone (Departamente, PD, FBI, NG)"] = "Opens the official B-Zone rules (Departments, PD, FBI, NG)",
    ["Deschide Personal Blacklist (lista privata + overlay pe ecran)"] = "Opens the Personal Blacklist (private list + on-screen overlay)",
    ["Roata de interactiune. Sofer: Eject / Cuff / Uncuff. Pe jos: Interact -> jucator -> Frisk / Confisca / Wanted / Sanctiuni / Find / Licente (+ Cuff / Punish in Jail)"] = "Interaction wheel. Driver: Eject / Cuff / Uncuff. On foot: Interact -> player -> Frisk / Confiscate / Wanted / Sanctions / Licenses (+ Cuff / Punish in Jail)",
    ["Incatuseaza + seteaza auto-arrest | Scoate / opreste auto-arrest"] = "Cuffs + sets auto-arrest | Removes / stops auto-arrest",
    ["Porneste / anuleaza secventa automata de FVR"] = "Starts / cancels the automatic FVR sequence",
    ["Trimite liniile configurate pe /gov"] = "Sends the configured lines on /gov",
    ["Muta HUD-ul cu mouse-ul | Reseteaza pozitia HUD"] = "Move the HUD with the mouse | Reset the HUD position",
    ["Intreaba pe /d daca zona de radar e libera (x1, x2, x3 + timer 10s)"] = "Asks on /d if the radar zone is free (x1, x2, x3 + 10s timer)",
    ["Cere acord pe /d pentru amplasare radar in alt oras (+ timer 10s)"] = "Asks on /d for approval to place the radar in another city (+ 10s timer)",
    ["Cere acord pe /d pentru patrulare in alt oras (+ timer 10s)"] = "Asks on /d for approval to patrol in another city (+ 10s timer)",
    ["Porneste radarul cu limita data | Opreste radarul"] = "Starts the radar with the given limit | Stops the radar",
    ["Afiseaza ultimii 5 jucatori surprinsi pe radar"] = "Shows the last 5 players caught on radar",
    ["Sanctioneaza automat ultimul vitezoman sau unul din ultimii 5"] = "Automatically sanctions the last speeder or one of the last 5",
    ["Amenda depasire limita viteza (10-50 km/h)"] = "Speeding ticket (10-50 km/h)",
    ["Depasire viteza +50 km/h (tine cont de nivel & jail)"] = "Speeding +50 km/h (considers level & jail)",
    ["Depasire viteza +100 km/h (tine cont de nivel & jail)"] = "Speeding +100 km/h (considers level & jail)",
    ["Amenda faruri stinse"] = "Headlights-off ticket", ["Amenda mers pe partea carosabila"] = "Walking-on-the-road ticket",
    ["Amenda alcoolemie peste 1.5"] = "Alcohol over 1.5 ticket", ["Sanctiune alcoolemie peste 3.0 (nivel & jail)"] = "Alcohol over 3.0 sanction (level & jail)",
    ["Sanctiune folosire NOS (nivel & jail)"] = "NOS use sanction (level & jail)", ["Sanctiune mers pe contra-sens (nivel & jail)"] = "Wrong-way driving sanction (level & jail)",
    ["Sanctiune parcare neregulamentara (nivel & jail)"] = "Illegal parking sanction (level & jail)", ["Sanctiune hidraulice (nivel & jail)"] = "Hydraulics sanction (level & jail)",
    ["Confisca armele la vedere (/confiscate weapons)"] = "Confiscates visible weapons (/confiscate weapons)",
    ["Confisca droguri posesie / consum + reminder /wdr"] = "Confiscates drugs (possession / use) + /wdr reminder",
    ["Materiale fara licenta (confisca + amenda)"] = "Materials without license (confiscate + ticket)",
    ["Folosire materiale (nivel 5-7 / 8-20 / 21+)"] = "Materials use (level 5-7 / 8-20 / 21+)",
    ["Aplica rapid /punish jucatorului din Jail (dupa ID sau nume)"] = "Quick /punish on a Jail player (by ID or name)",
    ["Acorda Wanted automat: Neconformare ordin"] = "Automatic Wanted: Disobeying orders", ["Acorda Wanted automat: Runner"] = "Automatic Wanted: Runner",
    ["Acorda Wanted automat: Apel nefondat"] = "Automatic Wanted: Unfounded call (checks if a colleague already announced it)",
    ["Anunta pe /d 'Ii voi da nefondat lui <Nume> (ID)'"] = "Announces on /d 'I'll give an unfounded call to <Name> (ID)' (checks colleagues)",
    ["Confisca bombele + mesaj + Wanted 3"] = "Confiscates bombs + message + Wanted 3",
    ["Somatie. Cu ID: daca nu ai /find pe el, ii da /find intai"] = "Summons. With ID: if you don't have /find on him, it does /find first",
    ["Acorda Wanted automat: Cop Attack"] = "Automatic Wanted: Cop Attack", ["Acorda Wanted automat: Neplata amenda"] = "Automatic Wanted: Unpaid ticket",
    ["Acorda Wanted automat: Complice"] = "Automatic Wanted: Accomplice", ["Acorda Wanted automat: Posesie / folosire droguri"] = "Automatic Wanted: Drug possession / use",
    ["Someaza suspectul cu wanted pe /m sa traga pe dreapta (+ timer 3s)"] = "Summons the wanted suspect on /m to pull over (+ 3s timer)",
    ["Control de rutina + /frisk <id>"] = "Routine check + /frisk <id>", ["Trimite /requestlicenses <id>"] = "Sends /requestlicenses <id>",
    ["Someaza jucatorul sa paraseasca Teritoriul Guvernamental"] = "Summons the player to leave the Government Area",
    ["AFK cu clepsidra 3 min | fara clepsidra 30s (fara ID = suspectul de pe /find). Din nou = a revenit"] = "AFK with hourglass 3 min | without hourglass 30s (no ID = your /find suspect). Again = he's back",
    ["Opreste numaratoarea AFK fara anunt"] = "Stops the AFK countdown without announcing",
    ["Schimba spawn-ul direct (/spawnchange + alegere automata)"] = "Changes spawn directly (/spawnchange + automatic pick)",
    ["Spawn in HQ-ul factiunii tale | Spawn in garajul (parcarea) HQ National Guard"] = "Spawn in your faction HQ | Spawn in the National Guard HQ garage (parking)",
    ["Spawn la HQ Clan / Bunker"] = "Spawn at Clan HQ / Bunker",
    ["Salut / Noapte buna pe /r si /ac  |  Curata chatul"] = "Hello / Good night on /r and /ac  |  Clears the chat",
    ["Telefon on/off, notificari, apeluri/sms pierdute"] = "Phone on/off, notifications, missed calls/sms",
    ["[CLICK STANGA] Fixeaza  |  [ESC] Anuleaza"] = "[LEFT CLICK] Place  |  [ESC] Cancel",
    ["VARIABILE PENTRU /comanda <id/nume> [text]"] = "VARIABLES FOR /command <id/name> [text]",
    ["nivelul lui |"] = "his level |", ["textul de dupa ID"] = "the text after the ID", ["cel mai apropiat Nume (ID) |"] = "nearest Name (ID) |",
    ["ID apropiat |"] = "nearest ID |", ["tot arg |"] = "all args |",
    ["Ascunde de pe Ecran"] = "Hide from screen", ["Save & Keep pe Ecran"] = "Save & Keep on screen",
    ["Coleg (aceeasi culoare)"] = "Colleague (same color)",
    ["Arata tasta in HUD (debifat = tasta merge, dar nu apare pe ecran)"] = "Show the key in the HUD (unchecked = the key works but isn't shown)",
    ["Iconita in HUD (click = schimba)"] = "HUD icon (click = change)", ["Alege iconita pentru HUD:"] = "Choose the HUD icon:",
    ["ORDINEA TASTELOR IN HUD (SUS / JOS)"] = "ORDER OF KEYS IN THE HUD (UP / DOWN)",
    ["Cele gri nu apar acum in HUD (tasta oprita sau HUD debifat), dar le poti aranja dinainte."] = "Grey ones aren't in the HUD right now (key off or HUD unchecked), but you can arrange them in advance.",
    ["Ordinea implicita"] = "Default order", ["Keybind"] = "Keybind",
    ["Trage cu mouse-ul (click stanga tinut pe rand) sau foloseste sagetile."] = "Drag with the mouse (hold left click on a row) or use the arrows.",
    ["Roata"] = "Wheel", ["ROATA PERSONALIZATA - ELEMENTE PROPRII"] = "CUSTOM WHEEL - YOUR OWN ITEMS",
    ["Debifeaza ce nu folosesti si trage randurile in ordinea dorita. Prima felie apare sus (ora 12)."] = "Uncheck what you don't use and drag the rows into the order you want. The first slice is at the top (12 o'clock).",
    ["PRIMUL NIVEL - PE JOS (ORDINE + AFISARE)"] = "FIRST LEVEL - ON FOOT (ORDER + VISIBILITY)",
    ["MENIUL JUCATORULUI (INTERACT -> JUCATOR)"] = "PLAYER MENU (INTERACT -> PLAYER)",
    ["PRIMUL NIVEL - IN MASINA (ORDINE + AFISARE)"] = "FIRST LEVEL - IN CAR (ORDER + VISIBILITY)",
    ["Bifat = apare pe roata"] = "Checked = shown on the wheel", ["Implicit (ordine + toate vizibile)"] = "Default (order + all visible)",
    ["DUTY (doar in interior)"] = "DUTY (interiors only)", ["PUNISH (doar in Jail)"] = "PUNISH (Jail only)",
    ["UNCUFF (doar pe cel incatusat de tine)"] = "UNCUFF (only the one you cuffed)", ["CUFF (doar in Jail)"] = "CUFF (Jail only)",
    ["LICENTE (doar LSPD/LVPD/SFPD)"] = "LICENSES (LSPD/LVPD/SFPD only)",
    ["Elementele tale apar pe primul nivel al rotii, dupa cele implicite. Submeniu = folder cu alte elemente."] = "Your items appear on the wheel's first level, after the default ones. Submenu = a folder with more items.",
    ["Comanda: acelasi format ca la Comenzi Custom (variabile cu '+', ' | ' = mai multe comenzi). Se salveaza singur."] = "Command: same format as Custom Commands (variables with '+', ' | ' = multiple commands). Saves automatically.",
    ["Pe jos"] = "On foot", ["In masina (sofer)"] = "In car (driver)", ["Niciun element inca. Apasa '+ Adauga element'."] = "No items yet. Press '+ Add item'.",
    ["Adauga element"] = "Add item", ["Nume pe roata"] = "Name on the wheel", ["Submeniu"] = "Submenu", ["Alege jucator"] = "Choose player",
    ["Doar click"] = "Click only", ["Alege iconita:"] = "Choose icon:", ["Submeniu gol"] = "Empty submenu",
    ["Ex: /r Backup la <Zona> | /ms   sau   /frisk <ID>"] = "Ex: /r Backup at <Zona> | /ms   or   /frisk <ID>",
    ["Inainte sa execute, roata iti arata jucatorii din jur. <ID>, <Nume>, <Nume (ID)> = jucatorul ales."] = "Before running, the wheel shows nearby players. <ID>, <Nume>, <Nume (ID)> = the chosen player.",
    ["Nu se executa cand eliberezi tasta (Hold) - trebuie click stanga. Bun pt actiuni periculoase."] = "Doesn't run when you release the key (Hold) - needs a left click. Good for risky actions.",
    ["Tine apasat click stanga si trage in sus / jos"] = "Hold left click and drag up / down",
    ["Lista din /jaillist cu celula in care e fiecare"] = "The /jaillist list with each player's cell",
    ["Acorda Wanted automat: Apel nefondat"] = "Automatic Wanted: Unfounded call",
    ["Anunta pe /d 'Ii voi da nefondat lui <Nume> (ID)'"] = "Announces on /d 'I'll give an unfounded call to <Name> (ID)'",
    ["Sanctiune Radar"] = "Radar sanction", ["Wanted"] = "Wanted",
    -- ===== mesaje din chat [PDAssist] (traduse pe bucati, intre codurile de culoare) =====
    ["Structura corecta este"] = "The correct format is", ["Foloseste"] = "Use", ["Scrie"] = "Type", ["sau"] = "or", ["iar"] = "and",
    ["Comenzile prescurtate / custom sunt dezactivate in"] = "Shortcut / custom commands are disabled in",
    ["Comenzile prescurtate sunt dezactivate in"] = "Shortcut commands are disabled in",
    ["sau ai nevoie de un /find activ"] = "or you need an active /find", ["Jucatorul"] = "Player", ["nu este conectat"] = "is not connected",
    ["Niciun jucator nu se afla in apropiere pentru"] = "No player is nearby for", ["Nu ai niciun"] = "You don't have any", ["activ pentru"] = "active for",
    ["Muta HUD-ul"] = "Move the HUD", ["salveaza"] = "saves", ["anuleaza"] = "cancels",
    ["Jucatorul cu ID-ul specificat nu este conectat"] = "The player with that ID is not connected",
    ["Dialogul pentru"] = "The dialog for", ["nu a aparut. Incearca din nou"] = "didn't appear. Try again",
    ["Serverul a raspuns la"] = "The server answered", ["cu un dialog fara lista. Nu selectez nimic automat"] = "with a non-list dialog. Not selecting anything automatically",
    ["Nu am gasit"] = "Couldn't find", ["Alege manual din lista"] = "Pick it manually from the list",
    ["in /spawnchange. Alege manual din lista"] = "in /spawnchange. Pick it manually from the list",
    ["in lista /su. Alege manual din dialog"] = "in the /su list. Pick it manually from the dialog",
    ["Randul cerut nu exista in"] = "The requested row doesn't exist in", ["lista are"] = "the list has",
    ["randuri). Alege manual din lista"] = "rows). Pick it manually from the list",
    ["Nu am putut selecta randul in"] = "Couldn't select the row in", ["probabil lag). Alege manual din lista"] = "probably lag). Pick it manually from the list",
    ["Blocat"] = "Blocked", ["Urmarire anulata pentru"] = "Pursuit cancelled for", ["Motiv"] = "Reason",
    ["A fost preluat"] = "Taken into custody", ["Suspect procesat"] = "Suspect processed", ["Suspectul s-a sinucis"] = "Suspect committed suicide",
    ["Suspectul a fost omorat"] = "Suspect was killed", ["Suspectul a fost arestat"] = "Suspect was arrested", ["Suspect deconectat"] = "Suspect disconnected",
    ["/clear - nu mai are wanted"] = "/clear - no longer wanted", ["Suspectul a scapat de wanted"] = "Suspect lost the wanted level",
    ["Nu mai are wanted (a reusit sa evadeze)"] = "No longer wanted (escaped)", ["Nu mai are wanted (a scapat)"] = "No longer wanted (escaped)",
    ["de tine"] = "by you", ["langa tine"] = "near you",
    ["Jucatorul cu ID-ul"] = "The player with ID", ["Jucatorul cu ID"] = "The player with ID", ["nu mai este conectat"] = "is no longer connected",
    ["pe suspectul de pe /find) sau"] = "on your /find suspect) or", ["Nu ai"] = "You don't have", ["activ pe nimeni. Foloseste"] = "active on anyone. Use",
    ["Numaratoare pornita. Daca revine scrie din nou"] = "Countdown started. If he comes back type again", ["opreste fara anunt"] = "stops without announcing",
    ["Timpul a expirat pt"] = "Time expired for", ["Dupa kill anunt automat pe /d ca nu a revenit"] = "After the kill I'll announce on /d that he didn't come back",
    ["Nu am putut citi raspunsul de la"] = "Couldn't read the answer from", ["Jail list"] = "Jail list", ["jucatori"] = "players", ["Celula"] = "Cell",
    ["Randuri din /jaillist pe care nu le-am putut citi sigur"] = "Rows from /jaillist I couldn't read for sure",
    ["jucator conectat"] = "connected player", ["Ai atins limita de"] = "You reached the limit of", ["comenzi custom"] = "custom commands", ["keybinduri custom"] = "custom keybinds",
    ["nu pot citi parola salvata"] = "can't read the saved password", ["Salveaz-o din nou in /pdc -> Cont & PIN"] = "Save it again in /pdc -> Account & PIN",
    ["limita de 3 incercari atinsa"] = "3-try limit reached", ["Verifica parola din /pdc -> Cont & PIN"] = "Check the password in /pdc -> Account & PIN",
    ["Login automat anulat: dialogul de parola nu mai e deschis"] = "Auto login cancelled: the password dialog is no longer open",
    ["ID invalid sau jucator deconectat"] = "Invalid ID or player disconnected", ["pt a-i acorda Wanted 3 (Droguri"] = "to give him Wanted 3 (Drugs",
    ["Ai uitat sa scrii un ID valid sau jucatorul nu este conectat"] = "You forgot to write a valid ID or the player is not connected",
    ["Nu a fost gasit acest jucator printre ultimii 5 surprinsi pe radar"] = "This player wasn't found among the last 5 caught on radar",
    ["Nu exista niciun jucator inregistrat pe radar inca"] = "No player recorded on radar yet",
    ["Exista deja un FVR in curs! Scrie"] = "An FVR is already running! Type", ["pentru a-l anula"] = "to cancel it",
    ["pentru a opri numaratoarea"] = "to stop the countdown", ["Nu ai un FVR activ in acest moment"] = "You don't have an active FVR right now",
    ["Trebuie sa fii la volanul unei masini de politie pentru a folosi radarul"] = "You must be driving a police car to use the radar",
    ["Radar activ"] = "Radar active", ["ultimul jucator"] = "last player", ["ultimii 5"] = "last 5",
    ["Niciun suspect nu se afla in masina ta (pe G) pentru /cuff"] = "No suspect is in your car (on G) for /cuff",
    ["Niciun jucator nou de verificat pe o raza de"] = "No new player to check within", ["Niciun jucator nu se afla pe o raza de"] = "No player within",
    ["PIN-ul trebuie sa aiba exact"] = "The PIN must have exactly", ["4 cifre"] = "4 digits", ["Setat"] = "Set", ["Comanda"] = "Command",
    ["a fost setata pt ghidul de comenzi!"] = "was set for the commands guide!",
    ["Modul s-a oprit. Apasa"] = "The mod stopped. Press", ["sau reconecteaza-te pt repornire"] = "or reconnect to restart",
    ["Niciun jucator in apropiere"] = "No player nearby", ["Selecteaza un ID valid"] = "Select a valid ID",
    ["Bun venit in"] = "Welcome to", ["Editia Moderna Mimgui"] = "Modern Mimgui Edition", ["pentru configurare"] = "for settings",
    ["sau tasta"] = "or the key", ["pentru sanctiuni rapide si"] = "for quick sanctions and", ["pentru lista comenzilor"] = "for the commands list",
    ["Modul a fost oprit. Apasa CTRL+R pentru repornire"] = "The mod was stopped. Press CTRL+R to restart", ["sau apasa tasta"] = "or press the key",
    ["Niciun jucator nu a fost inregistrat pe radar in aceasta sesiune inca"] = "No player has been recorded on radar this session yet",
    ["Ultimii jucatori surprinsi pe radar"] = "Last players caught on radar", ["pentru sanctionare"] = "to sanction",
    ["Apasa tasta"] = "Press the key", ["pentru a porni radarul sau"] = "to start the radar or", ["pt acord"] = "for approval",
    ["Dupa ce primesti acord apasa tasta"] = "After you get approval press the key", ["pentru a porni radarul"] = "to start the radar",
    ["Auto-Arrest oprit. Daca vrei sa dai si uncuff scrie"] = "Auto-Arrest stopped. If you also want to uncuff type",
    ["pentru a-i acorda wanted daca ai anuntat primul pe /d"] = "to give him wanted if you announced first on /d",
    ["Numaratoarea AFK a fost oprita"] = "AFK countdown stopped", ["Niciun jucator in apropiere pentru /punish"] = "No player nearby for /punish",
    ["v1.0 incarcat! Foloseste"] = "v1.0 loaded! Use", ["pentru toate meniurile"] = "for all menus",
    ["Au trecut"] = "It's been", ["3 secunde"] = "3 seconds", ["10 secunde"] = "10 seconds", ["de la somatie"] = "since the summons",
    ["Timpul AFK"] = "AFK time", ["a expirat"] = "expired", ["Timpul AFK a expirat"] = "AFK time expired",
    ["Jucator nivel 1-4 (protejat)"] = "Level 1-4 player (protected)", ["Suspect"] = "Suspect",
    ["Notificari ImGui activate"] = "ImGui notifications enabled", ["Notificari clasice activate"] = "Classic notifications enabled",
    ["Setarile FVR au fost salvate"] = "FVR settings saved", ["Liniile /gov au fost salvate"] = "The /gov lines were saved",
    ["Comenzile custom au fost salvate"] = "Custom commands saved", ["Personal Blacklist salvat"] = "Personal Blacklist saved",
    ["FVR efectuat cu succes"] = "FVR done successfully", ["FVR a fost anulat"] = "FVR was cancelled",
    ["Anuntul /gov a fost trimis"] = "The /gov announcement was sent", ["Pozitia HUD salvata cu succes"] = "HUD position saved",
    ["EROARE"] = "ERROR", ["Tip: Eroare"] = "Type: Error", ["Eroare"] = "Error",
    ["Marime HUD"] = "HUD size", ["Marime notificari"] = "Notifications size", ["Aceeasi marime pt notificari"] = "Same size for notifications",
    ["Marime roata"] = "Wheel size", ["Preview roata (stanga ecranului)"] = "Wheel preview (left of the screen)", ["Preview"] = "Preview",
    ["Primul nivel"] = "First level", ["Meniul jucatorului"] = "Player menu", ["In masina"] = "In car", ["Meniu jucator"] = "Player menu",
    ["Nicio felie vizibila"] = "No visible slices",
    ["Muta lista Personal Blacklist de pe ecran cu mouse-ul"] = "Move the on-screen Personal Blacklist with the mouse",
    ["incarcat! Foloseste"] = "loaded! Use", ["Verifica update la pornire"] = "Check for updates on start", ["Verifica acum"] = "Check now",
    ["Cauta pe GitHub o versiune noua la fiecare pornire. Manual: /pdupdate"] = "Looks for a new version on GitHub on every start. Manually: /pdupdate",
    ["Verifica / instaleaza ultima versiune PDAssist de pe GitHub"] = "Check / install the latest PDAssist version from GitHub",
    ["Nu am putut verifica update-ul"] = "Couldn't check for updates", ["fara internet sau GitHub indisponibil"] = "no internet or GitHub unavailable",
    ["version.txt de pe GitHub e gresit"] = "version.txt on GitHub is invalid", ["prima linie trebuie sa fie versiunea, ex. 1.0 patch 3"] = "the first line must be the version, e.g. 1.0 patch 3",
    ["Versiune noua"] = "New version", ["versiunea ta"] = "yours", ["ca sa o instalezi"] = "to install it", ["Scrie"] = "Type",
    ["Ai deja ultima versiune"] = "You already have the latest version", ["Descarc ultima versiune de pe GitHub..."] = "Downloading the latest version from GitHub...",
    ["Update esuat:"] = "Update failed:", ["fisierul descarcat nu e PDAssist.lua valid"] = "the downloaded file is not a valid PDAssist.lua",
    ["versiunea de pe GitHub are o eroare"] = "the GitHub version has an error", ["nu pot scrie in"] = "can't write to",
    ["Instalat"] = "Installed", ["Repornesc modul..."] = "Restarting the mod...", ["backup"] = "backup",
    ["Update disponibil"] = "Update available",
    ["Latimea: trage de coltul din dreapta-jos"] = "Width: drag the bottom-right corner",
    ["Trage fereastra unde vrei"] = "Drag the window where you want it", ["(lista e goala)"] = "(list is empty)", ["Gata"] = "Done", ["Muta"] = "Move",
    ["Pozitie blacklist salvata!"] = "Blacklist position saved!", ["Trage lista"] = "Drag the", ["cu mouse-ul"] = "list with the mouse",
    ["cu mouse-ul. Salvezi cu"] = "list with the mouse. Save with", ["click dreapta sau butonul Gata"] = "right click or the Done button",
    ["Click pe felie cu > = intri in submeniu"] = "Click a slice with > = open its submenu", ["Click dreapta = inapoi"] = "Right click = back",
    ["Intri in submeniuri cu butoanele de mai jos sau dand click pe felie in preview (click dreapta = inapoi)."] = "Open submenus with the buttons below or by clicking a slice in the preview (right click = back).",
    ["ORDINE + AFISARE"] = "ORDER + VISIBILITY", ["Submeniuri:"] = "Submenus:", ["Inapoi"] = "Back",
    ["Spawn"] = "Spawn", ["Duty"] = "Duty", ["Confisca"] = "Confiscate", ["Wanted"] = "Wanted", ["(fara nume)"] = "(no name)",
    ["CASA"] = "HOUSE", ["GARAJ NG"] = "NG GARAGE", ["HQ FACTIUNE"] = "FACTION HQ", ["ARME"] = "WEAPONS", ["DROGURI"] = "DRUGS",
    ["BOMBE"] = "BOMBS", ["MATERIALE"] = "MATERIALS", ["NECONFORMARE"] = "NON-COMPLIANCE", ["ATACARE POLITIST"] = "ATTACKING AN OFFICER",
    ["FUGAR"] = "FUGITIVE", ["COMPLICE"] = "ACCOMPLICE", ["NEFONDAT"] = "UNFOUNDED", ["PATRUNDERE TEREN"] = "TRESPASSING",
    ["Test notificare"] = "Test notification", ["Asa arata notificarile la marimea asta"] = "This is how notifications look at this size",
    ["Erorile modului ca notificari"] = "Mod errors as notifications",
    ["Erorile modului apar acum ca notificari"] = "Mod errors now show as notifications", ["Erorile modului apar acum in chat"] = "Mod errors now show in chat",
    ["Mesajele de eroare [PDAssist] (Niciun jucator..., Blocat..., Nu ai /find...) apar ca notificare in loc de chat. Restul raman in chat. Doar cu Toast ImGui."] = "[PDAssist] error messages (No player..., Blocked..., No /find...) show as a notification instead of chat. Everything else stays in chat. Toast ImGui only.",
    ["Limba interfetei: Romana"] = "Interface language: Romanian",
    ["Limba meniurilor, a HUD-ului, a rotii si a notificarilor. Mesajele trimise jucatorilor raman pe 'Limba Sanctiuni'."] = "Language of the menus, HUD, wheel and notifications. Messages sent to players follow 'Sanctions language'.",
}

-- Mesaje cu valori in mijloc (ancorate: tot textul trebuie sa se potriveasca)
PDX.EN_PATTERNS = {
    { "^(.-) are aceeasi culoare ca tine %(coleg%) %- nu ii dau (%a+)(%p*)$", function(who, act, p)
        return who .. " has the same color as you (colleague) - not giving " .. (({ frisk = "a frisk", confiscare = "a confiscation", wanted = "wanted" })[act] or act) .. p
    end },
    { "^Acest jucator are nivel 1%-4 %((%d+)%), nu%-l poti sanctiona$", "This player is level 1-4 (%1), you can't sanction him" },
    { "^Jucatorul are nivel 1%-4 %((%d+)%), nu poate fi sanctionat$", "The player is level 1-4 (%1), he can't be sanctioned" },
    { "^Acest jucator a trecut cu mai putin de (%d+) km/h %((%d+) km/h%)$", "This player passed with less than %1 km/h (%2 km/h)" },
    { "^Acest jucator a trecut cu doar (%d+) km/h %(limita (%d+) km/h%)$", "This player passed with only %1 km/h (limit %2 km/h)" },
    { "^FVR pornit %((%d+)s%)%. Scrie$", "FVR started (%1s). Type" },
    { "^(%u+) (%w+) pornit pt (.+)$", "%1 %2 started for %3" },
    { "^ID: (%d+) %(Niv (%d+)$", "ID: %1 (Lvl %2" },
}

-- Mesaj din chat [PDAssist]: traduce bucatile de text dintre codurile de culoare {RRGGBB}, pastrand culorile
function PDX.trChat(text)
    if PDX.uiLang ~= "en" or type(text) ~= "string" or text == "" then return text end
    local function seg(s)
        if s == "" or not s:find("%a") then return s end
        local l1, c1, t1 = s:match("^(%s*)(.-)(%s*)$")
        local tr1 = (c1 ~= "") and PDX.trCore(c1)
        if tr1 then return l1 .. tr1 .. t1 end
        -- a doua incercare: fara punctuatia de la capete, dar pastrand parantezele (". Motiv: X (de tine)." )
        local l2, c2, t2 = s:match("^([%s%.,!%?:|%-'\"]*)(.-)([%s%.,!%?:|%-'\"]*)$")
        local tr2 = (c2 ~= "") and PDX.trCore(c2)
        if tr2 then return l2 .. tr2 .. t2 end
        -- a treia: si fara paranteze la capete ("(pe ... sau " / "... (Droguri).")
        local l3, c3, t3 = s:match("^([%s%.,!%?:|%-%(%)'\"]*)(.-)([%s%.,!%?:|%-%(%)'\"]*)$")
        local tr3 = (c3 ~= "") and PDX.trCore(c3)
        if tr3 then return l3 .. tr3 .. t3 end
        return s
    end
    local res, pos = {}, 1
    while true do
        local a, b = text:find("{%x%x%x%x%x%x}", pos)
        if not a then
            res[#res + 1] = seg(text:sub(pos))
            break
        end
        res[#res + 1] = seg(text:sub(pos, a - 1))
        res[#res + 1] = text:sub(a, b)
        pos = b + 1
    end
    return table.concat(res)
end

-- Traduce un singur "nucleu" de text (fara iconita / spatii / ##id). nil = nu stie.
function PDX.trCore(core)
    local d = PDX.EN[core]
    if d then return d end
    local zn, lim = core:match("^VITEZA & RADAR %(Zona: (.-) | Limita: (.-)%)$")
    if zn then return "SPEED & RADAR (Zone: " .. zn .. " | Limit: " .. lim .. ")" end
    -- "[ TEXT ]"
    local inner = core:match("^%[%s*(.-)%s*%]$")
    if inner and PDX.EN[inner] then return "[ " .. PDX.EN[inner] .. " ]" end
    -- "<stanga> SEP <dreapta>" cu stanga cunoscuta (ex: "Sanctiune aplicata -> Ion", "CONFISCA - Ion", "Departament setat: NG")
    for _, sep in ipairs({ " -> ", " - ", ": ", " | " }) do
        local a, b = core:find(sep, 1, true)
        if a then
            local L, R = core:sub(1, a - 1), core:sub(b + 1)
            local tL = PDX.EN[L] or (L ~= "" and #L < #core and PDX.trCore(L)) or nil
            if tL then
                -- partea dreapta poate avea punct / semn la final: "Motiv: Suspectul a fost arestat (de tine)."
                local tR = PDX.trCore(R)
                if not tR then
                    local c, t = R:match("^(.-)([%.!%?]+)$")
                    local x = c and c ~= "" and PDX.trCore(c)
                    if x then tR = x .. t end
                end
                return tL .. sep .. (tR or R)
            end
        end
    end
    -- text + "(...)" / "[...]" la final (ex: "Text anunt /r (12/125 chr)", "Ultimul Radar (25)", "pe tasta [C]")
    -- paranteza se traduce si ea daca e cunoscuta: "Suspectul a fost omorat (de tine)" -> "... (by you)"
    local L, P = core:match("^(.-)%s*(%b())$")
    if L and PDX.EN[L] then
        local inner = P:sub(2, -2)
        return PDX.EN[L] .. " " .. (PDX.EN[inner] and ("(" .. PDX.EN[inner] .. ")") or P)
    end
    L, P = core:match("^(.-)%s*(%b[])$")
    if L and PDX.EN[L] then return PDX.EN[L] .. " " .. P end
    -- "X activat / dezactivat"
    local base, st = core:match("^(.-)%s+(dezactivat[ae]?)$")
    if not base then base, st = core:match("^(.-)%s+(activat[ae]?)$") end
    if base and PDX.EN[base] then return PDX.EN[base] .. " " .. PDX.EN[st] end
    -- "NG SANCTIUNI", "LSPD ASSIST" etc.: departament + text
    local fac, rest = core:match("^(%u+)%s+(.+)$")
    if fac and (fac == "LSPD" or fac == "LVPD" or fac == "SFPD" or fac == "FBI" or fac == "NG") then
        local t = PDX.EN[rest] or PDX.trCore(rest)
        if t then return fac .. " " .. t end
    end
    -- speciale
    local n = core:match("^Niciun jucator pe (%d+) m$")
    if n then return "No players within " .. n .. " m" end
    local k = core:match("^Elibereaza (%b[]): alege$")
    if k then return "Release " .. k .. ": select" end
    local who = core:match("^Deschide panoul principal de configurare (.+)$")
    if who then return "Opens the main settings panel of " .. who end
    -- mesaje cu numere / nume in mijloc
    for _, p in ipairs(PDX.EN_PATTERNS) do
        local r, n = core:gsub(p[1], p[2])
        if n > 0 then return r end
    end
    local rid = core:match("^Radar oprit & /find pe ID (%-?%d+)$")
    if rid then return "Radar stopped & /find on ID " .. rid end
    local fs = core:match("^FVR in (%d+) secunde %(/sfvr pt anulare%)$")
    if fs then return "FVR in " .. fs .. " seconds (/sfvr to cancel)" end
    local cnt = core:match("^Control de rutina efectuat %((%d+) jucatori%)$")
    if cnt then return "Routine check done (" .. cnt .. " players)" end
    return nil
end

function PDX.tr(s)
    if PDX.uiLang ~= "en" or type(s) ~= "string" or s == "" then return s end
    local c = PDX.trCache[s]
    if c then return c end
    local body, id = s:match("^(.-)(##.*)$")
    if not body then body, id = s, "" end
    -- prefix: iconite (octeti >= 0x80), spatii, "- ", "| "; sufix: spatii si ":"
    local pre, core, suf = body:match("^([\128-\255]*[%s%-|]*)(.-)([%s:]*)$")
    local res = s
    if core and core ~= "" then
        local t = PDX.trCore(core)
        if t then res = pre .. t .. suf .. id end
    end
    if PDX.trCacheN > 4000 then PDX.trCache, PDX.trCacheN = {}, 0 end
    PDX.trCache[s] = res
    PDX.trCacheN = PDX.trCacheN + 1
    return res
end

pdxTr = PDX.tr -- global in scriptul asta: folosita de addNotification (definita inaintea tabelei PDX)

function PDX.setUiLang(lang)
    PDX.uiLang = (lang == "en") and "en" or "ro"
    cfg.settings.uiLang = PDX.uiLang
    PDX.trCache, PDX.trCacheN = {}, 0
end

-- Invelim functiile de text din imgui ca sa traduca automat (doar in acest script).
do
    local unpack = unpack or table.unpack
    -- in mimgui unele functii sunt Lua (Button, SliderInt), altele sunt direct functii C (cdata): Text, Checkbox...
    local function callable(f) return type(f) == "function" or type(f) == "cdata" end
    -- (eticheta, ...) - eticheta e primul argument
    for _, name in ipairs({ "Button", "SmallButton", "Checkbox", "RadioButtonBool", "Selectable", "ColorEdit3",
                            "CollapsingHeader", "MenuItemBool", "BeginMenu" }) do
        local f = imgui[name]
        if callable(f) then
            imgui[name] = function(label, ...) return f(PDX.tr(label), ...) end
        end
    end
    -- (fmt, ...) sau (culoare, fmt, ...): daca fmt e "%s" traducem argumentul, altfel fmt-ul
    local function wrapFmt(name, nPre)
        local f = imgui[name]
        if not callable(f) then return end
        imgui[name] = function(...)
            if PDX.uiLang ~= "en" then return f(...) end
            local n = select("#", ...)
            local a = { ... }
            local fi = nPre + 1
            if a[fi] == "%s" and type(a[fi + 1]) == "string" then
                a[fi + 1] = PDX.tr(a[fi + 1])
            elseif type(a[fi]) == "string" then
                a[fi] = PDX.tr(a[fi])
            end
            return f(unpack(a, 1, n))
        end
    end
    wrapFmt("Text", 0); wrapFmt("TextDisabled", 0); wrapFmt("TextWrapped", 0); wrapFmt("SetTooltip", 0)
    wrapFmt("TextColored", 1)
    -- InputTextWithHint(label, hint, ...)
    local fHint = imgui.InputTextWithHint
    if callable(fHint) then
        imgui.InputTextWithHint = function(label, hint, ...) return fHint(label, PDX.tr(hint), ...) end
    end
    -- SliderInt / SliderFloat (label, v, min, max, format, ...)
    for _, name in ipairs({ "SliderInt", "SliderFloat" }) do
        local f = imgui[name]
        if callable(f) then
            imgui[name] = function(label, v, mn, mx, fmt, ...)
                return f(PDX.tr(label), v, mn, mx, (type(fmt) == "string") and PDX.tr(fmt) or fmt, ...)
            end
        end
    end
end

-- Limita stricta SA-MP: 128 caractere (inclusiv codurile de culoare {RRGGBB}!)
local SAMP_MAX_LEN = 128
local CHAT_PREFIX  = "{28AFE0}[PDAssist]{FFFFFF} " -- 27 caractere (cu ambele coduri hex incluse)

local function adjustCutOutsideColorTag(str, cutPos)
    local startCheck = math.max(1, cutPos - 6)
    for pos = startCheck, cutPos do
        if str:sub(pos, pos) == "{" then
            local maybeTag = str:sub(pos, pos + 7)
            if maybeTag:match("^%{%x%x%x%x%x%x%}$") and (pos + 7) > cutPos then
                return pos - 1
            end
        end
    end
    return cutPos
end

local function findSplitPos(str, maxLen, minStart)
    minStart = minStart or 1
    local safeEnd = adjustCutOutsideColorTag(str, math.min(#str, maxLen))
    if safeEnd < minStart then safeEnd = math.min(#str, maxLen) end
    for i = safeEnd, minStart + 1, -1 do
        if str:sub(i, i) == " " then
            return i - 1, i + 1
        end
    end
    return safeEnd, safeEnd + 1
end

local function chatOut(rawLine, color)
    local current = tostring(rawLine or "")
    color = color or -1
    if #current <= SAMP_MAX_LEN then
        sampAddChatMessage(current, color)
        return
    end
    local guard = 0
    while #current > 0 and guard < 10 do
        guard = guard + 1
        if #current <= SAMP_MAX_LEN then
            sampAddChatMessage(current, color)
            break
        end
        local cutEnd, nextStart = findSplitPos(current, SAMP_MAX_LEN, #CHAT_PREFIX)
        local chunk = current:sub(1, cutEnd)
        sampAddChatMessage(chunk, color)

        local rest = current:sub(nextStart):gsub("^%s+", "")
        if rest == "" then break end

        local lastCol = "{FFFFFF}"
        for col in chunk:gmatch("(%{%x%x%x%x%x%x%})") do
            lastCol = col
        end
        if rest:match("^%{%x%x%x%x%x%x%}") then
            current = "{28AFE0}[PDAssist] " .. rest
        else
            current = "{28AFE0}[PDAssist] " .. lastCol .. rest
        end
    end
end

-- Mesajele de eroare / avertizare ale modului (recunoscute dupa inceputul textului, in romana)
PDX.ERR_PREFIXES = {
    "Nu ", "Niciun", "Jucatorul", "Blocat", "ID invalid", "Ai uitat", "Trebuie sa", "Structura corecta", "Acest jucator",
    "Randul", "Serverul a raspuns", "Dialogul pentru", "Ai atins", "Login automat", "PIN-ul", "Exista deja", "Selecteaza un ID",
    "Comenzile prescurtate", "Scrie ", "Foloseste ", "Atentie",
}
function PDX.isErrorMsg(plain)
    for _, p in ipairs(PDX.ERR_PREFIXES) do
        if plain:sub(1, #p) == p then return true end
    end
    return false
end

local function msg(text)
    text = tostring(text or "")
    -- optional: erorile modului apar ca notificare (nu in chat)
    if tonumber(cfg.settings.errNotif) == 1 and cfg.settings.notifType ~= 1 then
        local plain = text:gsub("{%x%x%x%x%x%x}", "")
        if PDX.isErrorMsg(plain) then
            addNotification((PDX.trChat(text):gsub("{%x%x%x%x%x%x}", "")), "error")
            return
        end
    end
    -- mesajele modului (doar ale noastre, nu cele trimise jucatorilor) urmeaza limba interfetei
    chatOut(CHAT_PREFIX .. PDX.trChat(text), -1)
end

local CHAT_CHANNEL_PATTERNS = {
    "^(/[rRdDfFmMsSbBcC]%s+)",
    "^(/[aA][cC]%s+)",
    "^(/[cC][wW]%s+)",
    "^(/[gG][oO][vV]%s+)",
    "^(/[tT][xX]%s+)",
    "^(/[sS][xX]%s+)",
}

local function detectChatChannelPrefix(s)
    for i = 1, #CHAT_CHANNEL_PATTERNS do
        local p = s:match(CHAT_CHANNEL_PATTERNS[i])
        if p then return p end
    end
    return nil
end

local function say(text)
    local s = tostring(text or "")
    if s == "" then return end
    if #s <= SAMP_MAX_LEN then
        sampSendChat(s)
        return
    end
    local chanPrefix = detectChatChannelPrefix(s)
    if not chanPrefix and s:sub(1, 1) == "/" then
        -- Comanda normala de server (nu chat): taiere sigura la 128 caractere fara rupere {RRGGBB}
        local cut = adjustCutOutsideColorTag(s, SAMP_MAX_LEN)
        sampSendChat(s:sub(1, cut))
        return
    end
    local prefix = chanPrefix or ""
    local current = s
    local guard = 0
    while #current > 0 and guard < 8 do
        guard = guard + 1
        if #current <= SAMP_MAX_LEN then
            sampSendChat(current)
            break
        end
        local cutEnd, nextStart = findSplitPos(current, SAMP_MAX_LEN, #prefix)
        local chunk = current:sub(1, cutEnd)
        sampSendChat(chunk)
        local rest = current:sub(nextStart):gsub("^%s+", "")
        if rest == "" then break end
        current = prefix .. rest
    end
end

local function isKeySafe()
    if state.paused or state.chat or state.dialog then return false end
    if isSampfuncsLoaded and isSampfuncsLoaded() and isSampfuncsConsoleActive and isSampfuncsConsoleActive() then
        return false
    end
    return true
end

local NUMPAD_KEY_NAMES = {
    [96] = "num0", [97] = "num1", [98] = "num2", [99] = "num3", [100] = "num4",
    [101] = "num5", [102] = "num6", [103] = "num7", [104] = "num8", [105] = "num9",
    [106] = "num*", [107] = "num+", [109] = "num-", [110] = "num.", [111] = "num/",
}

local function cleanKeyName(vk)
    local code = tonumber(vk) or 0
    if NUMPAD_KEY_NAMES[code] then return NUMPAD_KEY_NAMES[code] end
    local name = vkeys.id_to_name(code)
    if not name or name == "" then return tostring(vk or "?") end
    return name:gsub("^VK_", "")
end

local function getPlayerNameSafe(id)
    id = tonumber(id)
    if not id then return nil end
    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if sampIsPlayerConnected(id) or id == myId then
        return sampGetPlayerNickname(id)
    end
    return nil
end

local function isPlayerOnline(id)
    id = tonumber(id)
    if not id or id < 0 then return false end
    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    return sampIsPlayerConnected(id) or id == myId
end

-- Cauta jucator conectat dupa ID exact sau Nume (exact -> prefix -> partial)
local function resolvePlayerQuery(token)
    local q = tostring(token or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if q == "" then return nil, nil end

    if q:match("^%d+$") then
        local pid = tonumber(q)
        if pid and isPlayerOnline(pid) then
            return pid, (getPlayerNameSafe(pid) or ("ID " .. pid))
        end
        return nil, nil
    end

    local low = q:lower()
    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local prefixId, prefixName = nil, nil
    local subId, subName       = nil, nil

    for pid = 0, 999 do
        if pid == myId or sampIsPlayerConnected(pid) then
            local pn = sampGetPlayerNickname(pid)
            if pn and pn ~= "" then
                local pnl = pn:lower()
                if pnl == low then
                    return pid, pn
                elseif not prefixId and pnl:sub(1, #low) == low then
                    prefixId, prefixName = pid, pn
                elseif not subId and pnl:find(low, 1, true) then
                    subId, subName = pid, pn
                end
            end
        end
    end

    if prefixId then return prefixId, prefixName end
    if subId then return subId, subName end
    return nil, nil
end

local function getNearestStreamedPlayer(maxDist)
    if not doesCharExist(PLAYER_PED) then return nil, nil end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local bestId, bestName, bestD = nil, nil, (maxDist or 25.0)
    for pid = 0, 999 do
        if sampIsPlayerConnected(pid) then
            local ok, ped = sampGetCharHandleBySampPlayerId(pid)
            if ok and doesCharExist(ped) and ped ~= PLAYER_PED then
                local tx, ty, tz = getCharCoordinates(ped)
                local d = getDistanceBetweenCoords3d(px, py, pz, tx, ty, tz)
                if d < bestD then
                    bestD    = d
                    bestId   = pid
                    bestName = sampGetPlayerNickname(pid) or ("ID " .. pid)
                end
            end
        end
    end
    return bestId, bestName
end

local function executePunishCmd(rawArg)
    local p = tostring(rawArg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if p == "" then
        msg("Structura corecta este {28AFE0}/ps <id/nume>{FFFFFF}")
        return
    end
    local pid, pName = resolvePlayerQuery(p)
    if pid then
        say("/punish " .. pid)
        addNotification("Punish -> " .. pName .. " (" .. pid .. ")", "sanction")
    else
        say("/punish " .. p)
    end
end

-- Motor de executie pentru cele 25 de Comenzi Custom cu Variabile Dinamice & Comenzi Multiple (' | ' sau ';;')
local function executeCustomCommandSlot(slotIdx, rawArg)
    if cfg.settings.cp ~= 1 then
        msg("Comenzile prescurtate / custom sunt dezactivate in {28AFE0}/pdc{FFFFFF}!")
        return
    end
    PDX.runTemplate(tostring(cfg.comenzi["txt" .. slotIdx] or ""), rawArg, "/" .. tostring(cfg.comenzi["cmd" .. slotIdx] or ""))
end

-- Motor comun: comenzi custom (/cmd) + keybinduri custom (tasta -> text). cmdName = cum apare in mesajele de ajutor.
function PDX.runTemplate(template, rawArg, cmdName)
    template = tostring(template or "")
    if template == "" then return end

    local argTrim = tostring(rawArg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local words = {}
    for w in argTrim:gmatch("%S+") do
        table.insert(words, w)
    end
    local firstWord = words[1] or ""
    local restText  = firstWord ~= "" and (argTrim:sub(#firstWord + 1):gsub("^%s+", "")) or ""

    local lowTpl = template:lower()
    local needsTarget = lowTpl:find("<id>", 1, true)
        or lowTpl:find("<nume>", 1, true)
        or lowTpl:find("<name>", 1, true)
        or lowTpl:find("<nume (id)>", 1, true)
        or lowTpl:find("<nume(id)>", 1, true)
        or lowTpl:find("<id (nume)>", 1, true)
        or lowTpl:find("<id(nume)>", 1, true)
        or lowTpl:find("<nivel>", 1, true)
        or lowTpl:find("<level>", 1, true)

    local tId, tName, tLvl = nil, nil, 0
    if needsTarget then
        if firstWord == "" then
            -- fara ID: foloseste suspectul de pe /find (daca exista)
            if PDX.find and PDX.find.active and PDX.find.id >= 0 and isPlayerOnline(PDX.find.id) then
                tId, tName = PDX.find.id, PDX.find.name
            else
                msg("Foloseste {28AFE0}" .. cmdName .. " <id/nume>{FFFFFF} (sau ai nevoie de un /find activ)!")
                return
            end
        else
            tId, tName = resolvePlayerQuery(firstWord)
            if not tId then
                msg("Jucatorul '{28AFE0}" .. firstWord .. "{FFFFFF}' nu este conectat!")
                return
            end
        end
        tLvl = tonumber(sampGetPlayerScore(tId)) or 0
    end

    local needsFullText = lowTpl:find("<text>", 1, true) or lowTpl:find("<args>", 1, true)
    if needsFullText and argTrim == "" then
        msg("Foloseste {28AFE0}" .. cmdName .. " <text>{FFFFFF}!")
        return
    end

    local needsNearest = lowTpl:find("<apropiat>", 1, true)
        or lowTpl:find("<nearest>", 1, true)
        or lowTpl:find("<apropiatid>", 1, true)
        or lowTpl:find("<nearestid>", 1, true)
        or lowTpl:find("<apropiatnume>", 1, true)
        or lowTpl:find("<nearestname>", 1, true)

    local nearId, nearName = nil, nil
    if needsNearest then
        nearId, nearName = getNearestStreamedPlayer(25.0)
        if not nearId then
            msg("Niciun jucator nu se afla in apropiere pentru {28AFE0}" .. cmdName .. "{FFFFFF}!")
            return
        end
    end

    local needsFind = lowTpl:find("<find", 1, true)
    if needsFind and not (PDX.find and PDX.find.active) then
        msg("Nu ai niciun {28AFE0}/find{FFFFFF} activ pentru " .. cmdName .. "!")
        return
    end

    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    myId = tonumber(myId) or 0
    local myName = getPlayerNameSafe(myId) or "Agent"

    local rendered = template:gsub("<([^<>]+)>", function(tag)
        local k = tag:lower():gsub("^%s+", ""):gsub("%s+$", "")
        if k == "nume (id)" or k == "nume(id)" or k == "name (id)" or k == "name(id)" then
            return string.format("%s (%d)", tostring(tName), tonumber(tId) or 0)
        elseif k == "id (nume)" or k == "id(nume)" or k == "id (name)" then
            return string.format("%d (%s)", tonumber(tId) or 0, tostring(tName))
        elseif k == "nume" or k == "name" then
            return tostring(tName)
        elseif k == "id" then
            return tostring(tId)
        elseif k == "nivel" or k == "level" then
            return tostring(tLvl)
        elseif k == "apropiat" or k == "nearest" then
            return string.format("%s (%d)", tostring(nearName), tonumber(nearId) or 0)
        elseif k == "apropiatid" or k == "nearestid" then
            return tostring(nearId)
        elseif k == "apropiatnume" or k == "nearestname" then
            return tostring(nearName)
        elseif k == "text" or k == "args" or k == "arg" then
            return argTrim
        elseif k == "rest" then
            return restText
        elseif k == "arg1" then
            return words[1] or ""
        elseif k == "arg2" then
            return words[2] or ""
        elseif k == "arg3" then
            return words[3] or ""
        elseif k == "eu" or k == "myname" or k == "me" then
            return myName
        elseif k == "myid" then
            return tostring(myId)
        elseif k == "dept" or k == "factiune" or k == "faction" then
            return getFaction()
        elseif k == "ora" or k == "time" then
            return os.date("%H:%M:%S")
        elseif k == "zona" or k == "zone" then
            return PDX.zoneName()
        elseif k == "find" then
            return string.format("%s (%d)", tostring(PDX.find.name), tonumber(PDX.find.id) or -1)
        elseif k == "findid" then
            return tostring(PDX.find.id)
        elseif k == "findnume" or k == "findname" then
            return tostring(PDX.find.name)
        end
        return "<" .. tag .. ">"
    end)

    -- Suport comenzi inlantuite separate prin ' | ' sau ';;'
    local parts = {}
    local normalized = rendered:gsub(";;", " | ")
    local startPos = 1
    while true do
        local s, e = normalized:find(" | ", startPos, true)
        if not s then
            local tail = normalized:sub(startPos):gsub("^%s+", ""):gsub("%s+$", "")
            if tail ~= "" then table.insert(parts, tail) end
            break
        end
        local seg = normalized:sub(startPos, s - 1):gsub("^%s+", ""):gsub("%s+$", "")
        if seg ~= "" then table.insert(parts, seg) end
        startPos = e + 1
    end

    if #parts <= 1 then
        if parts[1] then say(parts[1]) end
    else
        lua_thread.create(function()
            for idx, line in ipairs(parts) do
                say(line)
                if idx < #parts then wait(220) end
            end
        end)
    end
end

-- Exact IEEE-754 decoded Jail interior coordinates from PDHelper V7.5 CLEO:
-- X: 1755.653 .. 1780.434, Y: -1587.275 .. -1560.542, Z: 1734.535 .. 1755.287
local function isInJailInterior()
    if not doesCharExist(PLAYER_PED) then return false end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    return (px > 1755.65 and px < 1780.44)
       and (py > -1587.28 and py < -1560.54)
       and (pz > 1734.53  and pz < 1755.29)
end

-- 8 Official PD / FBI / NG Arrest Points from PDHelper V7.5 CLEO
local ARREST_POINTS = {
    { x = -1719.5441, y =  1018.7192 }, -- SF FBI / Garage
    { x = -1589.4727, y =   707.3682 }, -- SFPD Garage 1
    { x =  1559.1716, y = -1695.3357 }, -- LSPD Garage 1
    { x =  2283.1333, y =  2429.3604 }, -- LVPD Garage 1
    { x =   186.4597, y =  1931.2211 }, -- NG Area 69
    { x =  2338.1328, y =  2474.5420 }, -- LVPD Garage 2
    { x = -1681.8855, y =   705.9380 }, -- SFPD Garage 2
    { x =  1569.3385, y = -1646.9022 }, -- LSPD Garage 2
}

local function isNearAnyArrestPoint()
    if not doesCharExist(PLAYER_PED) or not isCharInAnyCar(PLAYER_PED) then return false end
    local px, py, _ = getCharCoordinates(PLAYER_PED)
    for i = 1, #ARREST_POINTS do
        local pt = ARREST_POINTS[i]
        local dx, dy = px - pt.x, py - pt.y
        if (dx * dx + dy * dy) <= 25.0 then -- radius 5.0m
            return true
        end
    end
    return false
end

-- Pozitia HUD se tine separat pt fiecare stil: modern (hud_*) si clasic PDHelper (classic_*).
-- In ambele: x = marginea DREAPTA a blocului, y = marginea de SUS.
function PDX.hudPosKeys()
    if tonumber(cfg.settings.hudStyle) == 1 then
        return "classic_custom", "classic_x", "classic_y"
    end
    return "hud_custom", "hud_x", "hud_y"
end

-- Pozitia implicita (cand nu ai mutat HUD-ul) pt stilul curent
function PDX.hudDefaultPos()
    local sw, sh = getScreenResCached()
    if tonumber(cfg.settings.hudStyle) == 1 then
        return sw - 8, math.floor(sh * 0.966 - hudLastHeight) -- jos-dreapta, deasupra "RPG.B-ZONE.RO"
    end
    return sw - 8, math.floor(sh * 0.5 - (hudLastHeight * 0.5))
end

local function syncHudSliders()
    local kC, kX, kY = PDX.hudPosKeys()
    local defX, defY = PDX.hudDefaultPos()
    local custom = cfg.settings[kC] == true
    local x, y = tonumber(cfg.settings[kX]) or -1, tonumber(cfg.settings[kY]) or -1
    hudPosX[0] = (custom and x > 0) and math.floor(x) or defX
    hudPosY[0] = (custom and y > 0) and math.floor(y) or defY
end

local function startHudMoving()
    closeAnimWin(mainWin)
    closeAnimWin(sanWin)
    closeAnimWin(blWin)
    closeAnimWin(guideWin)
    closeAnimWin(rulesWin)
    hudMoving        = true
    hudMoveArmed     = false
    hudMoveStartTime = os.clock()
    showCursor(true, true)
    hudCacheDirty = true
    msg("Muta HUD-ul: {28AFE0}CLICK STANGA{FFFFFF} salveaza | {FF6347}ESC{FFFFFF} anuleaza.")
end

local function resetHudPosition()
    local kC, kX, kY = PDX.hudPosKeys()
    cfg.settings[kC] = false
    cfg.settings[kX] = -1
    cfg.settings[kY] = -1
    saveCfg()
    syncHudSliders()
    addNotification("Pozitia HUD resetata la default", "saved")
end

-- =========================================================================================
--  SECTION 6: CORE POLICE ACTIONS, SANCTIONS & WANTED LOGIC
-- =========================================================================================
local function queueAutoTicket(targetId, lineIndex)
    targetId  = tonumber(targetId)
    lineIndex = tonumber(lineIndex)
    if not targetId or not lineIndex then return end
    -- metoda din PDHelper CLEO / TaxiAssist: dialogul apare normal, se selecteaza randul (dupa pozitie,
    -- ca in CLEO) si se apasa butonul; pana la 3 incercari daca e lag
    lua_thread.create(function()
        wait(320)
        PDX.selectInNextDialog(lineIndex, "/ticket")
        say("/ticket " .. targetId)
    end)
end

local function queueAutoSu(targetId, lineIndex, label)
    targetId = tonumber(targetId)
    if not targetId or not isPlayerOnline(targetId) then
        msg("Jucatorul cu ID-ul specificat nu este conectat!")
        return
    end
    if PDX.blockColleague(targetId, "wanted") then return end
    local search = PDX.SU_SEARCH[tonumber(lineIndex) or -1]
    if label then
        addNotification(string.format("Wanted (%s) -> ID %d", label, targetId), "sanction")
    end
    if search then
        -- metoda TaxiAssist: dialogul apare normal, apoi selectam randul gasit dupa text si apasam butonul
        lua_thread.create(function()
            wait(250)
            PDX.selectInNextDialog(search, "/su")
            say("/su " .. targetId)
        end)
        return
    end
    -- rezerva (linie fara text cunoscut): selectie dupa index, ca inainte
    pendingSu.active = true
    pendingSu.id     = targetId
    pendingSu.line   = lineIndex
    pendingSu.search = nil
    pendingSu.expire = os.clock() + 4.5
    lua_thread.create(function()
        wait(250)
        say("/su " .. targetId)
    end)
end

-- =========================================================================================
--  SECTION 6B: EXTENSII (adaptate dupa NG-Helper): /su dupa text, spawn rapid, urmarire /find,
--  AFK pe suspect, /ms <id>, nefondat dublu, /bm, porti/lifturi, login & PIN automat
-- =========================================================================================

-- Cauta un rand intr-un dialog-lista dupa text (fara culori, fara majuscule). Intoarce indexul (0-based) sau -1.
function PDX.findInList(text, searches, style)
    if type(searches) == "string" then searches = { searches } end
    local lines = {}
    for line in (tostring(text or "") .. "\n"):gmatch("(.-)\n") do
        lines[#lines + 1] = line:gsub("{%x%x%x%x%x%x}", ""):lower()
    end
    local offset = (style == 5) and 1 or 0 -- DIALOG_STYLE_TABLIST_HEADERS: primul rand e capul de tabel
    for _, s in ipairs(searches or {}) do
        local sl = tostring(s):lower()
        -- "^text" = randul trebuie sa INCEAPA cu text (ex: "^hq fbi" nu prinde "Parcare HQ FBI")
        local prefix = (sl:sub(1, 1) == "^") and sl:sub(2) or nil
        for i = 1 + offset, #lines do
            local line = lines[i]:gsub("^%s+", "")
            if prefix then
                if line:sub(1, #prefix) == prefix then return i - 1 - offset end
            elseif line:find(sl, 1, true) then
                return i - 1 - offset
            end
        end
    end
    return -1
end

-- /su: textul cautat pentru fiecare linie veche (merge si daca serverul schimba ordinea)
PDX.SU_SEARCH = {
    [1]  = { "Apel Nefondat", "Prank" },
    [2]  = { "Neconformare Ordin", "Disobey" },
    [3]  = { "Patrundere Teren", "Trespass" },
    [5]  = { "Posesie/Folosire Droguri", "Droguri", "Drugs" },
    [6]  = { "Atacare Politist", "Cop Attack" },
    [7]  = { "Neplata Amenda", "Unpaid" },
    [12] = { "Fugar", "Runner" },
    [13] = { "Complice", "Accomplice" },
}

-- ---------- Preseturi radar: { zona (asa apare in mesajele /d), limita, eticheta buton (optional) } ----------
PDX.RADAR_PRESETS = {
    { "Santa Maria Beach LS", 100, "SMB LS" },
    { "Verona Beach LS",      100 },
    { "Verdant Bluffs LS",    100 },
    { "Market LS",            100 },
    { "Temple LS",            100 },
    { "The Strip LV",         100 },
    { "Downtown LS",          100 },
}

-- ---------- Spawn rapid (/scasa, /slspd ...) ----------
PDX.SPAWNS = {
    scasa = { "Casa", "House" },
    slspd = { "Parcare HQ LSPD", "LSPD HQ Garage" },
    slvpd = { "Parcare HQ LVPD", "LVPD HQ Garage" },
    ssfpd = { "Parcare HQ SFPD", "SFPD HQ Garage" },
    sfbi  = { "Parcare HQ FBI", "FBI HQ Garage" },
    hqng  = { "Parcare HQ National Guard", "National Guard HQ Garage" }, -- garajul NG
    sjail = { "LS Jail" },
    sclan = { "HQ Clan", "Clan HQ" },
    sbunker = { "Bunker" },
    hqf   = {}, -- HQ-ul factiunii tale (calculat in PDX.spawnChange dupa departament)
}
PDX.FACTION_HQ_NAME = { NG = "national guard", FBI = "fbi", LSPD = "lspd", LVPD = "lvpd", SFPD = "sfpd" }

PDX.pendingSpawn = nil
function PDX.spawnChange(key)
    local s = PDX.SPAWNS[key]
    if key == "hqf" then
        local fn = PDX.FACTION_HQ_NAME[getFaction()] or getFaction():lower()
        s = { "^hq " .. fn, "^" .. fn .. " hq" } -- doar randul care INCEPE cu "HQ <factiune>", nu parcarea
    end
    if not s then return end
    PDX.selectInNextDialog(s, "/spawnchange")
    say("/spawnchange")
end

-- Selectie in dialog ca la TaxiAssist: asteapta sa apara dialogul (nou), cauta randul dupa text,
-- il selecteaza in lista (sampSetCurrentDialogListItem) si apasa primul buton. Daca nu gaseste, lasa dialogul deschis.
-- Se apeleaza INAINTE de comanda care deschide dialogul.
function PDX.selectInNextDialog(searches, what, timeout)
    local prevId = sampIsDialogActive() and sampGetCurrentDialogId() or -1
    lua_thread.create(function()
        local start    = os.clock()
        local deadline = start + (timeout or 3.0)
        while os.clock() < deadline do
            if sampIsDialogActive() then
                -- dialog nou; sau acelasi ID (serverul refoloseste ID-ul) dupa ce a avut timp sa se schimbe
                if sampGetCurrentDialogId() ~= prevId or (os.clock() - start) > 0.6 then break end
            end
            wait(10)
        end
        if not sampIsDialogActive() then
            msg("Dialogul pentru {28AFE0}" .. what .. "{FFFFFF} nu a aparut. Incearca din nou.")
            return
        end
        wait(80)
        if not sampIsDialogActive() then return end

        -- SIGURANTA: selectam randuri DOAR intr-un dialog de tip lista (2 = list, 4 = tablist, 5 = tablist cu cap).
        -- Pe un dialog de mesaj / input nu exista lista, iar sampSetCurrentDialogListItem ar da crash jocului.
        local style = sampGetCurrentDialogType()
        if style ~= 2 and style ~= 4 and style ~= 5 then
            msg("Serverul a raspuns la " .. what .. " cu un dialog fara lista. Nu selectez nimic automat.")
            return
        end

        -- numarul de randuri selectabile (fara capul de tabel la stilul 5)
        local dText = tostring(sampGetDialogText() or "")
        local rows = 0
        for _ in (dText .. "\n"):gmatch("(.-)\n") do rows = rows + 1 end
        if dText:sub(-1) == "\n" then rows = rows - 1 end
        if style == 5 then rows = rows - 1 end

        local idx
        if type(searches) == "number" then
            idx = searches -- rand dat direct dupa pozitie (ex: /ticket, ca in CLEO)
        else
            idx = PDX.findInList(dText, searches, style)
            if idx < 0 then
                msg("Nu am gasit {28AFE0}" .. tostring(searches[1]) .. "{FFFFFF} in " .. what .. ". Alege manual din lista.")
                return
            end
        end
        if idx < 0 or idx >= rows then
            msg("Randul cerut nu exista in " .. what .. " (lista are " .. rows .. " randuri). Alege manual din lista.")
            return
        end
        -- pana la 3 incercari (ca in CLEO), pt lag
        for attempt = 1, 3 do
            -- re-verificam la fiecare incercare: dialogul se poate schimba intre timp (lag / alt dialog)
            if not sampIsDialogActive() then return end
            local st = sampGetCurrentDialogType()
            if st ~= 2 and st ~= 4 and st ~= 5 then return end
            sampSetCurrentDialogListItem(idx)
            wait(attempt == 1 and 30 or 200)
            if sampGetCurrentDialogListItem() == idx then
                sampCloseCurrentDialogWithButton(1)
                return
            end
            wait(attempt == 1 and 0 or 300)
        end
        msg("Nu am putut selecta randul in " .. what .. " (probabil lag). Alege manual din lista.")
    end)
end

-- ---------- Utilitare nume ----------
function PDX.myName()
    local ok, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if ok then return sampGetPlayerNickname(id) or "" end
    return ""
end

-- Numele apare ca "cuvant" intreg in mesaj (nu ca parte din alt nume)
function PDX.hasName(message, name)
    if not name or name == "" then return false end
    local start = 1
    while true do
        local a, b = message:find(name, start, true)
        if not a then return false end
        local before, after = message:sub(a - 1, a - 1), message:sub(b + 1, b + 1)
        if (a == 1 or not before:match("[%w_%.@%[%]]")) and (after == "" or not after:match("[%w_%.@%[%]]")) then
            return true
        end
        start = b + 1
    end
end

-- ---------- Protectie colegi: aceeasi culoare de nume ca tine = coleg de factiune ----------
-- Compara culoarea RGB (in ambele formate posibile ARGB / RGBA), fara alpha (serverul poate ascunde markerul cu alpha 0).
function PDX.sameColorAsMe(pid)
    pid = tonumber(pid)
    local ok, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if not ok or not pid or pid == myId or not sampIsPlayerConnected(pid) then return false end
    local a, b = sampGetPlayerColor(pid), sampGetPlayerColor(myId)
    if not a or not b then return false end
    return a == b
        or bit.band(a, 0xFFFFFF) == bit.band(b, 0xFFFFFF)
        or bit.band(bit.rshift(a, 8), 0xFFFFFF) == bit.band(bit.rshift(b, 8), 0xFFFFFF)
end

-- true = blocat (si scrie in chat de ce). actiune = "frisk" / "confiscare" / "wanted"
function PDX.blockColleague(pid, actiune)
    if not PDX.sameColorAsMe(pid) then return false end
    msg(string.format("{FF6347}Blocat:{FFFFFF} %s (%d) are aceeasi culoare ca tine (coleg) - nu ii dau %s.",
        tostring(getPlayerNameSafe(pid) or "?"), tonumber(pid) or -1, actiune or "actiunea"))
    return true
end

-- ---------- Urmarire /find ----------
PDX.find       = { active = false, name = "", id = -1 }
PDX.cancelPick = nil   -- { name, expire } alege markerul corect daca apare dialogul de /cancel find
PDX.msRetry    = nil   -- { id, expire, done } /ms <id> cand serverul zice ca nu urmaresti pe nimeni

function PDX.setFind(name, id)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return end
    id = tonumber(id) or -1
    if id < 0 then
        local low = name:lower()
        for pid = 0, 1003 do
            if sampIsPlayerConnected(pid) then
                local n = sampGetPlayerNickname(pid)
                if n and n:lower() == low then id = pid break end
            end
        end
    end
    PDX.find.active, PDX.find.name, PDX.find.id = true, name, id
    hudCacheDirty = true
end

function PDX.clearFind()
    if PDX.find.active then hudCacheDirty = true end
    PDX.find.active, PDX.find.name, PDX.find.id = false, "", -1
end

-- { cuvant cheie in mesajul HQ, motiv, true = "langa tine" in loc de "de tine" }
PDX.HQ_TRIGGERS = {
    { "custodia",                  "A fost preluat" },
    { "procesat",                  "Suspect procesat" },
    { "sinucis",                   "Suspectul s-a sinucis", true },
    { "omorat",                    "Suspectul a fost omorat" },
    { "arestat",                   "Suspectul a fost arestat" },
    { "deconectat",                "Suspect deconectat", true },
    { "cazierul",                  "/clear - nu mai are wanted" },
    { "suspectul este acum liber", "Suspectul a scapat de wanted" },
    { "evadeze",                   "Nu mai are wanted (a reusit sa evadeze)" },
    { "custody",                   "A fost preluat" },
    { "processed",                 "Suspect procesat" },
    { "suicide",                   "Suspectul s-a sinucis", true },
    { "has killed",                "Suspectul a fost omorat" },
    { "has arrested",              "Suspectul a fost arestat" },
    { "disconnected",              "Suspect deconectat", true },
    { "cleared",                   "/clear - nu mai are wanted" },
    { "suspect is now free",       "Suspectul a scapat de wanted" },
    { "escape",                    "Nu mai are wanted (a scapat)" },
}

function PDX.autoCancelFind(reason)
    local name = PDX.find.name
    PDX.clearFind()
    msg("Urmarire anulata pentru {28AFE0}" .. name .. "{FFFFFF}. Motiv: " .. reason .. ".")
    addNotification("Find anulat: " .. name, "info")
    PDX.cancelPick = { name = name, expire = os.clock() + 4.0 }
    lua_thread.create(function()
        wait(500)
        say("/cancel find")
    end)
end

-- Mesaje /find (pornire / oprire) - apelat din onServerMessage
function PDX.checkFindMessages(clean)
    local low = clean:lower()
    -- DOAR confirmarea de /find a serverului (cea care spune cum se anuleaza / "Marker set on").
    -- Mesajele HQ de tipul "X (ID) is in the ..." / "este in zona ..." NU inseamna ca ai /find pe el.
    if not low:match("^%s*hq:") and (low:find("cancel find", 1, true) or low:find("marker set on", 1, true)) then
        local name, id = clean:match("(%S+)%s*%((%d+)%)%s*este in zona")
        if not name then name, id = clean:match("(%S+)%s*%((%d+)%)%s*foloseste /cancel find") end
        if not name then name, id = clean:match("[Mm]arker set on ([^%(]+)%s*%((%d+)%)") end
        if not name then name, id = clean:match("(%S+)%s*%((%d+)%)%s*[Ii]s in") end
        if not name then name = clean:match("(%S+)%s+este in zona") end
        if name then PDX.setFind(name, id) end
    end
    if low:find("ai anulat cautarea", 1, true) or low:find("nu urmaresti pe nimeni", 1, true)
    or low:find("nu ai facut nicio cautare", 1, true) or low:find("you didn't make any search", 1, true)
    or low:find("nu esti in urmarirea nimanui", 1, true) or low:find("you are not finding anyone", 1, true) then
        PDX.clearFind()
        local r = PDX.msRetry
        if r and not r.done and os.clock() < r.expire then
            r.done = true
            lua_thread.create(function()
                wait(300)
                say("/find " .. r.id)
                wait(700)
                say("/ms")
            end)
        end
    end
end

-- Mesaje HQ: anulare automata /find + anunt AFK dupa kill
function PDX.checkHQ(m)
    if not m:match("^%s*hq:") then return end
    if m:find("incearca sa evadeze", 1, true) or m:find("trying to escape", 1, true) then return end
    local myLow = PDX.myName():lower()

    -- AFK expirat -> ai dat kill -> anunt pe /d
    local p = PDX.afk.pending
    if p and os.clock() < p.untilT and myLow ~= "" and PDX.hasName(m, p.name:lower()) and PDX.hasName(m, myLow)
    and (m:find("omorat", 1, true) or m:find("killed", 1, true)) then
        PDX.afk.pending = nil
        local txt = (p.kind == "ffk") and " nu a revenit in 30 sec | afk fara clepsidra" or " nu a revenit in 3 minute | afk clepsidra"
        lua_thread.create(function()
            wait(900)
            say("/d " .. p.name .. txt)
        end)
    end

    if tonumber(cfg.auto.findTrack) ~= 1 or not PDX.find.active then return end
    local key = PDX.find.name:lower()
    if not PDX.hasName(m, key) then return end
    local victim = m:match("l%-a omorat pe%s+(%S+)") or m:match("has killed%s+(%S+)")
        or m:match("l%-a arestat pe%s+(%S+)") or m:match("has arrested%s+(%S+)")
        or m:match("l%-a procesat pe%s+(%S+)")
    if victim then
        victim = victim:gsub("[%.,!]+$", "")
        if victim ~= key then return end
    end
    for _, tr in ipairs(PDX.HQ_TRIGGERS) do
        if m:find(tr[1], 1, true) then
            local reason = tr[2]
            if myLow ~= "" and PDX.hasName(m, myLow) then
                reason = reason .. (tr[3] and " (langa tine)" or " (de tine)")
            end
            PDX.autoCancelFind(reason)
            return
        end
    end
end

-- /ms <id>: daca n-ai /find pe el, ii da /find intai (inlocuieste find-ul vechi)
function PDX.cmdMs(arg)
    local a = tostring(arg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local id = tonumber(a)
    if not id then
        say(a ~= "" and ("/ms " .. a) or "/ms")
        return
    end
    if not isPlayerOnline(id) then
        msg("Jucatorul cu ID-ul {28AFE0}" .. id .. "{FFFFFF} nu este conectat!")
        return
    end
    if PDX.find.active and PDX.find.id == id then
        PDX.msRetry = { id = id, expire = os.clock() + 3.0, done = false }
        say("/ms")
        return
    end
    PDX.msRetry = nil
    local hadFind = PDX.find.active
    lua_thread.create(function()
        if hadFind then
            say("/cancel find")
            wait(400)
        end
        say("/find " .. id)
        wait(700)
        say("/ms")
    end)
end

-- ---------- AFK (/afk = cu clepsidra 3 min, /ffk = fara clepsidra 30s) ----------
PDX.afk = { kind = nil, name = "", id = -1, pending = nil }

function PDX.afkStop()
    timers.afkEnd   = 0
    timers.afkLabel = ""
    PDX.afk.kind, PDX.afk.name, PDX.afk.id = nil, "", -1
    hudCacheDirty = true
end

function PDX.afkStart(kind, arg)
    local a  = tostring(arg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local id = tonumber(a)

    -- aceeasi comanda, fara ID, cat timp numaratoarea merge = jucatorul a revenit
    if a == "" and PDX.afk.kind == kind and timers.afkEnd > os.clock() then
        say("/d " .. PDX.afk.name .. " a revenit din afk!")
        PDX.afkStop()
        addNotification("AFK oprit: jucatorul a revenit", "info")
        return
    end

    local name
    if id then
        if not isPlayerOnline(id) then
            msg("Jucatorul cu ID-ul {28AFE0}" .. id .. "{FFFFFF} nu este conectat!")
            return
        end
        name = getPlayerNameSafe(id)
    elseif a ~= "" then
        msg("Foloseste {28AFE0}/" .. kind .. "{FFFFFF} (pe suspectul de pe /find) sau {28AFE0}/" .. kind .. " <id>{FFFFFF}.")
        return
    elseif PDX.find.active then
        id, name = PDX.find.id, PDX.find.name
    else
        msg("Nu ai {28AFE0}/find{FFFFFF} activ pe nimeni. Foloseste {28AFE0}/" .. kind .. " <id>{FFFFFF}.")
        return
    end

    local dur
    if kind == "ffk" then
        dur = 30
        say("/d " .. name .. " afk fara clepsidra | 30 sec kill")
    else
        dur = 180
        say("/d " .. name .. " afk cu clepsidra | " .. os.date("%M:%S") .. " | 3min kill")
    end
    PDX.afk.kind, PDX.afk.name, PDX.afk.id, PDX.afk.pending = kind, name, id or -1, nil
    timers.afkEnd   = os.clock() + dur
    timers.afkLabel = (kind == "ffk" and "FFK " or "AFK ") .. name
    hudCacheDirty   = true
    msg("Numaratoare pornita. Daca revine scrie din nou {28AFE0}/" .. kind .. "{FFFFFF}, iar {28AFE0}/stopafk{FFFFFF} opreste fara anunt.")
    addNotification(string.format("%s %s pornit pt %s", kind == "ffk" and "FFK" or "AFK", kind == "ffk" and "30s" or "3m", name), "info")
end

-- Apelat din bucla principala cand numaratoarea ajunge la 0
function PDX.afkExpired()
    if PDX.afk.kind then
        PDX.afk.pending = { name = PDX.afk.name, kind = PDX.afk.kind, untilT = os.clock() + 300 }
        msg("Timpul a expirat pt {28AFE0}" .. PDX.afk.name .. "{FFFFFF}. Dupa kill anunt automat pe /d ca nu a revenit.")
        PDX.afk.kind, PDX.afk.name, PDX.afk.id = nil, "", -1
    end
end

-- ---------- /jc: lista din /jaillist cu celula fiecaruia (citita DOAR din raspunsul /jaillist) ----------
-- Accepta: dialog tabel (coloana "Celula"/"Cell"), linii "Nume (ID) ... Celula: 8" / "Cell 8".
-- Ce nu poate citi sigur afiseaza exact cum a venit de la server (fara estimari dupa pozitie).
PDX.jc = { active = false, untilT = 0, lines = {} }

local function jcCellFrom(s)
    local low = tostring(s or ""):lower()
    return low:match("celula%s*:?%s*#?%s*(%d+)") or low:match("cell%s*:?%s*#?%s*(%d+)")
        or low:match("cel%.%s*:?%s*#?%s*(%d+)") or low:match("^%s*#?(%d+)%s*$")
end

-- numele + ID-ul jucatorului dintr-o linie: intai "Nume (ID)", apoi orice jucator conectat al carui nume apare
local function jcNameFrom(line, myId)
    local n, id = line:match("([%w_%[%]%.%-@$=]+)%s*%((%d+)%)")
    if n and tonumber(id) and sampIsPlayerConnected(tonumber(id)) then return n, tonumber(id) end
    local low = line:lower()
    for pid = 0, 1003 do
        if pid ~= myId and sampIsPlayerConnected(pid) then
            local nick = sampGetPlayerNickname(pid)
            if nick and nick ~= "" and PDX.hasName(low, nick:lower()) then return nick, pid end
        end
    end
    return n, tonumber(id)
end

function PDX.jcFinish()
    PDX.jc.active = false
    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local rows, raw = {}, {}

    local src = {}
    if PDX.jc.dialog then
        for line in (PDX.jc.dialog .. "\n"):gmatch("(.-)\n") do src[#src + 1] = line end
    else
        src = PDX.jc.lines
    end

    -- tabel cu cap (ex: "Nume\tCelula\tTimp"): aflam coloana celulei din primul rand
    local cellCol
    if src[1] and src[1]:find("\t", 1, true) then
        local c = 0
        for col in (src[1] .. "\t"):gmatch("(.-)\t") do
            c = c + 1
            local l = col:lower()
            if l:find("celul", 1, true) or l:find("cell", 1, true) then cellCol = c end
        end
    end

    for i, line in ipairs(src) do
        if line:find("%S") and not (cellCol and i == 1) then
            local cell
            if cellCol then
                local c = 0
                for col in (line .. "\t"):gmatch("(.-)\t") do
                    c = c + 1
                    if c == cellCol then cell = col:match("(%d+)") end
                end
            end
            cell = cell or jcCellFrom(line)
            local name, id = jcNameFrom(line, myId)
            if name and cell then
                rows[#rows + 1] = { name = name, id = id, cell = tonumber(cell) }
            elseif name or cell then
                raw[#raw + 1] = line -- are ceva util, dar nu pot citi sigur nume + celula
            end
        end
    end

    if #rows == 0 and #raw == 0 then
        msg("Nu am putut citi raspunsul de la {28AFE0}/jaillist{FFFFFF}.")
        return
    end
    table.sort(rows, function(a, b) return a.cell < b.cell end)
    if #rows > 0 then
        msg("Jail list ({28AFE0}" .. #rows .. "{FFFFFF} jucatori):")
        for _, r in ipairs(rows) do
            msg(string.format("{28AFE0}%s%s{FFFFFF} - Celula {FFD700}%d", r.name, r.id and (" (" .. r.id .. ")") or "", r.cell))
        end
    end
    if #raw > 0 then
        msg("{AAAAAA}Randuri din /jaillist pe care nu le-am putut citi sigur:")
        for _, l in ipairs(raw) do msg("{AAAAAA}" .. l) end
    end
end

function PDX.cmdJc()
    if PDX.jc.active then return end
    PDX.jc = { active = true, untilT = os.clock() + 0.8, lines = {} } -- raspuns in chat: asteptam doar 0.8s
    local prevId = sampIsDialogActive() and sampGetCurrentDialogId() or -1
    say("/jaillist")
    lua_thread.create(function()
        local deadline = os.clock() + 2.0 -- dialogul poate veni mai tarziu daca e lag
        while os.clock() < deadline do
            -- /jaillist cu dialog: citim textul, il inchidem imediat si gata
            if sampIsDialogActive() and sampGetCurrentDialogId() ~= prevId then
                wait(30)
                PDX.jc.dialog = tostring(sampGetDialogText() or ""):gsub("{%x%x%x%x%x%x}", "")
                sampCloseCurrentDialogWithButton(0)
                break
            end
            -- raspuns in chat: dupa 0.8s fara dialog, lista e deja venita
            if os.clock() > PDX.jc.untilT and #PDX.jc.lines > 0 then break end
            wait(10)
        end
        PDX.jcFinish()
    end)
end

-- ---------- /hdt + roata "DUTY + HEAL" ----------
-- /heal da armura doar dupa ce /duty e aplicat de server: cu 0.1s (ca in CLEO) /heal ajungea prea devreme
-- si primeai doar viata. Pauza de 1s (NG-Helper folosea 0.9s).
function PDX.dutyHeal()
    lua_thread.create(function()
        say("/pin")
        say("/duty")
        wait(1000)
        say("/heal")
    end)
end

-- ---------- /bm <id> ----------
function PDX.bombs(id)
    id = tonumber(id)
    if not id or not isPlayerOnline(id) then
        msg("Scrie {28AFE0}/bm <id>{FFFFFF} (jucator conectat)")
        return
    end
    if PDX.blockColleague(id, "confiscare") then return end
    local pName = getPlayerNameSafe(id)
    lua_thread.create(function()
        say("/confiscate " .. id .. " bombs")
        wait(500)
        if isRo() then
            say(pName .. ", ai fost surprins cu bombe asupra ta, le-am confiscat si vei primi Wanted 3 pentru posesie.")
        else
            say(pName .. ", you were found carrying bombs, they have been confiscated and you will receive Wanted 3 for possession.")
        end
        wait(1000)
        queueAutoSu(id, 5, "Bombe")
    end)
    addNotification("Bombe confiscate -> " .. pName, "sanction")
end

-- ---------- Porti / bariere HQ & lifturi (tasta C) ----------
PDX.LIFTS = {
    { 2268.0515, 2448.1704,   3.5313, "/goup"   }, -- LVPD garaj -> acoperis
    { 2293.8452, 2459.1221,  38.6875, "/godown" },
    { 1525.3896, -1677.9115,  5.8906, "/goup"   }, -- LSPD garaj -> acoperis
    { 1564.8199, -1666.5800, 28.3956, "/godown" },
}
PDX.BARRIERS = { -- in masina: tasta C apasa H (claxon) ca sa deschida bariera
    { 1541.4429, -1627.2263, 12.9596 }, { 1548.4004, -1627.5295, 12.9552 },
    { 1588.2277, -1635.3005, 12.9640 }, { 1589.4775, -1641.2065, 12.6367 },
    { -1767.5056, 984.8835, 22.9931 },  { -1773.5680, 984.6699, 23.5395 },
    { 2332.6184, 2444.8635, 5.3188 },   { 2337.6938, 2441.6855, 6.4333 },
    { 2297.0166, 2498.6345, 3.2734 },   { 2290.7229, 2497.9141, 3.8284 },
    { -1631.3307, 692.3049, 7.0800 },   { -1631.3459, 683.5396, 7.1875 },
    { -1577.4180, 662.0541, 7.1875 },   { -1567.8625, 662.0994, 7.1875 },
    { -1697.7579, 684.1389, 24.1659 },  { -1706.0348, 684.1495, 24.8906 },
    { 2243.0510, 2454.7800, 10.8203 },  { 2232.3477, 2453.1882, 10.8744 },
}
function PDX.gateExtra()
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    for _, p in ipairs(PDX.LIFTS) do
        if getDistanceBetweenCoords3d(px, py, pz, p[1], p[2], p[3]) <= 2.0 then
            say(p[4])
            return
        end
    end
    if isCharInAnyCar(PLAYER_PED) then
        for _, p in ipairs(PDX.BARRIERS) do
            if getDistanceBetweenCoords3d(px, py, pz, p[1], p[2], p[3]) <= 4.8 then
                lua_thread.create(function()
                    setVirtualKeyDown(vkeys.VK_H, true)
                    wait(100)
                    setVirtualKeyDown(vkeys.VK_H, false)
                end)
                return
            end
        end
    end
end

-- ---------- Keybinduri custom (minim 10, se pot adauga din /pdc pana la 50) ----------
PDX.KBC_MAX = math.max(10, math.min(50, tonumber(cfg.settings.kbcCount) or 10))
PDX.KBC_SLOT_DEFAULTS = { on = 0, key = 0, kname = "-", label = "", text = "", hud = 1, icon = "KEYBOARD" }

function PDX.ensureKbcSlot(i)
    for k, v in pairs(PDX.KBC_SLOT_DEFAULTS) do
        if cfg.kbc[k .. i] == nil then cfg.kbc[k .. i] = v end
    end
end
for i = 1, PDX.KBC_MAX do PDX.ensureKbcSlot(i) end

-- + Adauga: slot nou de comanda custom / keybind custom (numarul se salveaza in ini)
function PDX.addCustomCmdSlot()
    if CUSTOM_CMD_MAX >= 100 then
        msg("Ai atins limita de {28AFE0}100{FFFFFF} comenzi custom.")
        return
    end
    CUSTOM_CMD_MAX = CUSTOM_CMD_MAX + 1
    local i = CUSTOM_CMD_MAX
    cfg.comenzi["en" .. i], cfg.comenzi["cmd" .. i], cfg.comenzi["txt" .. i] = 0, "", ""
    customCmdBuffers[i] = { cmd = new.char[32](), text = new.char[256]() }
    cfg.settings.cmdCount = CUSTOM_CMD_MAX
    saveCfg()
end

function PDX.addKbcSlot()
    if PDX.KBC_MAX >= 50 then
        msg("Ai atins limita de {28AFE0}50{FFFFFF} keybinduri custom.")
        return
    end
    PDX.KBC_MAX = PDX.KBC_MAX + 1
    local i = PDX.KBC_MAX
    PDX.ensureKbcSlot(i)
    if PDX.kbcBuf then PDX.kbcBuf[i] = { label = new.char[33](), text = new.char[256]() } end
    PDX.HUD_ORDER_DEFAULT[#PDX.HUD_ORDER_DEFAULT + 1] = "kbc" .. i
    PDX.hudOrderCache = nil
    cfg.settings.kbcCount = PDX.KBC_MAX
    saveCfg()
end

-- Tasta implicita apare in HUD? (separat de activarea tastei)
function PDX.hudRowOn(key)
    return not (cfg.hudrows and tonumber(cfg.hudrows[key]) == 0)
end

-- Ordinea randurilor cu taste in HUD (implicite + custom). Salvata in cfg.settings.hudOrder ca "id1,id2,...".
PDX.HUD_ORDER_DEFAULT = { "menuKeyOn", "lKeyOn", "wheelOn", "somatie", "radar", "cuffarrest", "frisk", "tazer", "wanted", "nearwanted", "repairon" }
for i = 1, PDX.KBC_MAX do PDX.HUD_ORDER_DEFAULT[#PDX.HUD_ORDER_DEFAULT + 1] = "kbc" .. i end

function PDX.getHudOrder()
    local raw = tostring(cfg.settings.hudOrder or "")
    if PDX.hudOrderCache and PDX.hudOrderRaw == raw then return PDX.hudOrderCache end
    local known = {}
    for _, id in ipairs(PDX.HUD_ORDER_DEFAULT) do known[id] = true end
    local list, seen = {}, {}
    for id in raw:gmatch("[^,%s]+") do
        if known[id] and not seen[id] then list[#list + 1] = id; seen[id] = true end
    end
    for _, id in ipairs(PDX.HUD_ORDER_DEFAULT) do -- ce lipseste (randuri noi) se adauga la final
        if not seen[id] then list[#list + 1] = id end
    end
    PDX.hudOrderCache, PDX.hudOrderRaw = list, raw
    return list
end

function PDX.setHudOrder(list, noSave)
    cfg.settings.hudOrder = table.concat(list, ",")
    if not noSave then saveCfg() end
end

-- Iconitele din care poti alege pt keybindurile custom (doar cele care exista in fAwesome5 se afiseaza)
PDX.KBC_ICONS = {
    "KEYBOARD", "STAR", "BULLHORN", "GAVEL", "SEARCH", "CAR", "MOTORCYCLE", "HELICOPTER", "PLANE", "TRUCK",
    "USER_SHIELD", "SHIELD_ALT", "USER_SECRET", "USERS", "USER", "BOLT", "LINK", "UNLINK", "LOCK", "KEY",
    "MAP_MARKER_ALT", "CROSSHAIRS", "FLAG", "HOME", "BUILDING", "PHONE", "COMMENT", "COMMENTS", "BELL", "ENVELOPE",
    "HEART", "MEDKIT", "AMBULANCE", "WRENCH", "GAS_PUMP", "TACHOMETER_ALT", "BOMB", "CANNABIS", "BOX_OPEN", "CUBES",
    "ID_CARD", "HAND_PAPER", "RUNNING", "FIST_RAISED", "EXCLAMATION_TRIANGLE", "CLOCK", "CHECK", "TIMES", "DOLLAR_SIGN", "GIFT",
}

function PDX.kbcIcon(i)
    return fa["ICON_FA_" .. tostring(cfg.kbc["icon" .. i] or "KEYBOARD")] or fa.ICON_FA_KEYBOARD
end
function PDX.runCustomKeybinds()
    for i = 1, PDX.KBC_MAX do
        local k = tonumber(cfg.kbc["key" .. i]) or 0
        if tonumber(cfg.kbc["on" .. i]) == 1 and k > 0 and wasKeyPressed(k) then
            local t = tostring(cfg.kbc["text" .. i] or "")
            if t ~= "" then
                PDX.runTemplate(t, "", "tasta [" .. tostring(cfg.kbc["kname" .. i]) .. "]")
            end
        end
    end
end

-- ---------- Parola / PIN: criptare Windows DPAPI (legata de contul tau de Windows) ----------
PDX.dp = nil
function PDX.dpInit()
    if PDX.dp ~= nil then return PDX.dp end
    pcall(ffi.cdef, [[
        typedef struct { unsigned long cbData; unsigned char* pbData; } PDA_BLOB;
        int __stdcall CryptProtectData(PDA_BLOB*, const void*, void*, void*, void*, unsigned long, PDA_BLOB*);
        int __stdcall CryptUnprotectData(PDA_BLOB*, void*, void*, void*, void*, unsigned long, PDA_BLOB*);
        void* __stdcall LocalFree(void*);
    ]])
    local ok, lib = pcall(ffi.load, "crypt32")
    PDX.dp = (ok and lib) or false
    return PDX.dp
end

function PDX.dpCall(data, protect)
    local lib = PDX.dpInit()
    if not lib or not data or data == "" then return nil end
    local ok, res = pcall(function()
        local inB, outB = ffi.new("PDA_BLOB[1]"), ffi.new("PDA_BLOB[1]")
        local buf = ffi.new("unsigned char[?]", #data + 1)
        ffi.copy(buf, data, #data)
        inB[0].cbData, inB[0].pbData = #data, buf
        local r
        if protect then
            r = lib.CryptProtectData(inB, nil, nil, nil, nil, 1, outB)    -- 1 = CRYPTPROTECT_UI_FORBIDDEN
        else
            r = lib.CryptUnprotectData(inB, nil, nil, nil, nil, 1, outB)
        end
        if r == 0 then return nil end
        local s = ffi.string(outB[0].pbData, outB[0].cbData)
        ffi.C.LocalFree(outB[0].pbData)
        return s
    end)
    if ok then return res end
    return nil
end

function PDX.toHex(s) return (tostring(s):gsub(".", function(c) return string.format("%02x", c:byte()) end)) end
function PDX.fromHex(h)
    if not h or #h % 2 ~= 0 or h:find("[^%x]") then return nil end
    return (h:gsub("%x%x", function(p) return string.char(tonumber(p, 16)) end))
end

function PDX.secretEncode(plain)
    plain = tostring(plain or "")
    if plain == "" then return "" end
    local enc = PDX.dpCall(plain, true)
    if enc then return "dp:" .. PDX.toHex(enc) end
    return "hex:" .. PDX.toHex(plain)
end

function PDX.secretDecode(s)
    s = tostring(s or "")
    local h = s:match("^dp:(%x*)$")
    if h then
        local raw = PDX.fromHex(h)
        return raw and PDX.dpCall(raw, false) or nil
    end
    h = s:match("^hex:(%x*)$")
    if h then return PDX.fromHex(h) end
    return nil
end

-- ---------- Login automat (ca in NG-Helper) ----------
PDX.login = { gen = 0, attempts = 0, last = 0, status = "Oprit" }

function PDX.loginDialog(id, style, title, text)
    if tonumber(cfg.login.enabled) ~= 1 then return end
    local ttl  = tostring(title or ""):gsub("{%x%x%x%x%x%x}", ""):lower()
    local body = tostring(text or ""):gsub("{%x%x%x%x%x%x}", ""):lower()
    local recognized = (style == 1 or style == 3) and (
        ttl:find("account login", 1, true)
        or ((ttl:find("login", 1, true) or ttl:find("autentific", 1, true))
            and (body:find("password", 1, true) or body:find("parola", 1, true))))
    if not recognized then return end

    -- doar un dialog de login nou anuleaza o completare in curs (alte dialoguri / RPC-uri nu mai conteaza)
    PDX.login.gen      = PDX.login.gen + 1
    PDX.login.dialogId = id
    local token        = PDX.login.gen

    local password = PDX.secretDecode(cfg.login.pass)
    if not password or password == "" then
        PDX.login.status = "Nu ai salvat parola (sau nu se poate decripta pe acest PC)"
        msg("Login automat: {FF6347}nu pot citi parola salvata{FFFFFF}. Salveaz-o din nou in /pdc -> Cont & PIN.")
        return
    end
    local ts = os.time()
    if ts - PDX.login.last > 30 then PDX.login.attempts = 0 end
    PDX.login.last = ts
    PDX.login.attempts = PDX.login.attempts + 1
    if PDX.login.attempts > 3 then
        PDX.login.status = "Limita de 3 incercari atinsa. Verifica parola."
        msg("Login automat: {FF6347}limita de 3 incercari atinsa{FFFFFF}. Verifica parola din /pdc -> Cont & PIN.")
        return
    end

    -- dialogul de parola e inca pe ecran? (nu mai cerem acelasi ID - unele servere il retrimit / schimba)
    local function valid()
        if tonumber(cfg.login.enabled) ~= 1 or token ~= PDX.login.gen then return false end
        if not sampIsDialogActive() then return false end
        local st = sampGetCurrentDialogType()
        return st == 1 or st == 3
    end

    PDX.login.status = "Astept dialogul de login..."
    lua_thread.create(function()
        -- asteapta sa apara efectiv dialogul pe ecran (max 5s), apoi o pauza scurta
        local t0 = os.clock()
        while not sampIsDialogActive() and os.clock() - t0 < 5 do wait(50) end
        wait(500)
        if not valid() then
            if token == PDX.login.gen then
                msg("Login automat anulat: dialogul de parola nu mai e deschis.")
            end
            return
        end
        sampSetCurrentDialogEditboxText("")
        PDX.login.status = "Introduc parola..."
        wait(50)
        for i = 1, #password do
            if not valid() then return end
            sampSetCurrentDialogEditboxText(password:sub(1, i))
            wait(math.random(20, 40))
        end
        wait(150)
        if not valid() then return end
        PDX.login.sending = true
        sampCloseCurrentDialogWithButton(1)
        PDX.login.sending = false
        PDX.login.status = "Parola trimisa (" .. os.date("%H:%M:%S") .. ")"
    end)
end

-- Verifica dialogul vizibil (ca la TaxiAssist): daca e un dialog de parola "Account Login" nou, il completeaza.
-- Apelat din bucla principala (o data la ~0.1s).
PDX.loginNext = 0
function PDX.loginPoll()
    if tonumber(cfg.login.enabled) ~= 1 then return end
    local now = os.clock()
    if now < PDX.loginNext then return end
    PDX.loginNext = now + 0.1
    if not sampIsDialogActive() then
        PDX.login.seen = nil -- dialogul s-a inchis -> daca reapare (ex: parola gresita) il tratam din nou
        return
    end
    local st = sampGetCurrentDialogType()
    if st ~= 1 and st ~= 3 then return end
    local id = sampGetCurrentDialogId()
    if PDX.login.seen == id then return end
    PDX.login.seen = id
    PDX.loginDialog(id, st, sampGetDialogCaption(), sampGetDialogText())
end

-- ---------- PIN automat (tastatura textdraw de la /pin) ----------
PDX.keypad = {}
function PDX.onKeypadTextDraw(id, data)
    if tonumber(cfg.login.pinAuto) ~= 1 or not data or not data.text then return end
    local txt = data.text
    if txt == "1" then
        local z = PDX.keypad["0"]
        PDX.keypad = {}
        if z then PDX.keypad["0"] = z end
    end
    if txt:match("^%d$") then
        PDX.keypad[txt] = id
    elseif txt == "_" and data.position then
        local x = math.floor(data.position.x)
        if x == 312 then
            PDX.keypad.ok = id
        elseif x == 378 then
            local pin = PDX.secretDecode(cfg.login.pin) or ""
            if not pin:match("^%d%d%d%d$") then return end
            local k = PDX.keypad
            local d = { pin:sub(1, 1), pin:sub(2, 2), pin:sub(3, 3), pin:sub(4, 4) }
            if k[d[1]] and k[d[2]] and k[d[3]] and k[d[4]] and k.ok then
                lua_thread.create(function()
                    wait(400)
                    for _, c in ipairs(d) do
                        sampSendClickTextdraw(k[c])
                        wait(1)
                    end
                    sampSendClickTextdraw(k.ok)
                    PDX.keypad = {}
                end)
            end
        end
    end
end

-- Direct sanctions (do not require /id level check)
local function sanctionDirect(kind, targetId)
    targetId = tonumber(targetId)
    if not targetId or not isPlayerOnline(targetId) then
        msg("ID invalid sau jucator deconectat!")
        return
    end
    local pName  = getPlayerNameSafe(targetId) or ("ID " .. targetId)
    local ro     = isRo()
    local limita = tonumber(cfg.radar.limita) or 100
    local zona   = tostring(cfg.radar.zona or "LS")

    -- confiscari: nu pe colegi (aceeasi culoare de nume)
    if (kind == "arme" or kind == "dr" or kind == "cdr" or kind == "matslic") and PDX.blockColleague(targetId, "confiscare") then
        return
    end

    if kind == "aa" then
        if ro then
            say(string.format("Salut %s! Ai fost surprins(a) depasind limita de viteza, limita: %dkm/h", pName, limita))
            say(string.format("In zona %s, acum ceva timp, iti voi acorda o amenda.", zona))
        else
            say(string.format("Hi %s! You were caught breaking the speedlimit, limit: %dkm/h", pName, limita))
            say(string.format("In zone %s, some time ago, I'll give you a ticket.", zona))
        end
        queueAutoTicket(targetId, 7)

    elseif kind == "faruri" then
        if ro then
            say(string.format("Salut %s! Ai uitat sa iti aprinzi farurile, iti voi acorda o amenda.", pName))
        else
            say(string.format("Hi %s! You forgot to turn on your headlights, I'll give you a ticket.", pName))
        end
        queueAutoTicket(targetId, 6)

    elseif kind == "car" then
        if ro then
            say(string.format("Salut %s! Ai fost surprins(a) mergand pe carosabil, iti voi acorda o amenda.", pName))
        else
            say(string.format("Hi %s! You were caught walking on the roadway, I'll give you a ticket.", pName))
        end
        queueAutoTicket(targetId, 10)

    elseif kind == "alc15" then
        if ro then
            say(string.format("Salut %s!", pName))
            say("Ai fost surprins(a) conducand cu o alcoolemie mai mare de 1.5, iti voi acorda o amenda.")
        else
            say(string.format("Hi %s!", pName))
            say("You were caught driving with alcoholemy more than 1.5, I'll give you a ticket.")
        end
        queueAutoTicket(targetId, 11)

    elseif kind == "arme" then
        if ro then
            say(string.format("Salut %s! Ai fost surprins(a) cu armele la vedere, drept urmare ti le voi confisca.", pName))
        else
            say(string.format("Hi %s! You were caught with weapons in sight, so I will confiscate your weapons.", pName))
        end
        say("/confiscate " .. targetId .. " weapons")

    elseif kind == "dr" then
        if ro then
            say(string.format("Salut %s! Ai fost surprins(a) detinand droguri, le voi confisca si vei primi Wanted 3.", pName))
        else
            say(string.format("Hi %s! You were caught with drugs, I will confiscate them and give you Wanted 3.", pName))
        end
        say("/confiscate " .. targetId .. " drugs")
        msg("Scrie {28AFE0}/wdr " .. targetId .. "{FFFFFF} pt a-i acorda Wanted 3 (Droguri).")

    elseif kind == "cdr" then
        if ro then
            say(string.format("Salut %s! Ai fost surprins(a) consumand droguri, le voi confisca si vei primi Wanted 3.", pName))
        else
            say(string.format("Hi %s! You were caught using drugs, I will confiscate them and give you Wanted 3.", pName))
        end
        say("/confiscate " .. targetId .. " drugs")
        msg("Scrie {28AFE0}/wdr " .. targetId .. "{FFFFFF} pt a-i acorda Wanted 3 (Droguri).")

    elseif kind == "matslic" then
        if ro then
            say(string.format("Salut %s! Ai fost surprins(a) detinand materiale fara licenta.", pName))
            say("Le voi confisca si vei primi o amenda.")
        else
            say(string.format("Hi %s! You were caught having materials without a license for them.", pName))
            say("I will confiscate your materials and I'll give you a ticket.")
        end
        say("/confiscate " .. targetId .. " materials")
        queueAutoTicket(targetId, 5)
    end
    addNotification("Sanctiune aplicata -> " .. pName, "sanction")
end

-- Execute level- & jail-dependent sanctions once level is obtained from /id
local function executeLevelSanction(kind, targetId, nivel)
    targetId = tonumber(targetId)
    nivel    = tonumber(nivel) or 0
    if not targetId or not isPlayerOnline(targetId) then return end

    if nivel < 5 then
        msg("Acest jucator are nivel 1-4 (" .. tostring(nivel) .. "), nu-l poti sanctiona!")
        addNotification("Jucator nivel 1-4 (protejat)", "info")
        return
    end

    local pName  = getPlayerNameSafe(targetId) or ("ID " .. targetId)
    local ro     = isRo()
    local limita = tonumber(cfg.radar.limita) or 100
    local zona   = tostring(cfg.radar.zona or "LS")
    local inJail = isInJailInterior()

    -- Special case: /mats (5-7 choice, 8-20 confiscate only, 21+ confiscate + ticket)
    if kind == "mats" then
        if nivel >= 5 and nivel <= 7 then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) folosind materiale. Doresti amenda sau sa ti le confisc?", pName))
            else
                say(string.format("Hi %s! You were caught using materials, do you want ticket or confiscate materials?", pName))
            end
        elseif nivel >= 8 and nivel <= 20 then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) folosind materiale, ti le voi confisca.", pName))
            else
                say(string.format("Hi %s! You were caught using materials, I'll confiscate them.", pName))
            end
            say("/confiscate " .. targetId .. " materials")
        else
            if inJail then
                if ro then
                    say(string.format("Salut %s! Ai fost surprins(a) folosind materiale, ti le voi confisca.", pName))
                else
                    say(string.format("Hi %s! You were caught using materials, I'll confiscate them.", pName))
                end
                say("/confiscate " .. targetId .. " materials")
            else
                if ro then
                    say(string.format("Salut %s! Ai fost surprins(a) folosind materiale, ti le voi confisca si vei primi o amenda.", pName))
                else
                    say(string.format("Hi %s! You were caught using materials, I'll confiscate them and I'll give you a ticket.", pName))
                end
                say("/confiscate " .. targetId .. " materials")
                queueAutoTicket(targetId, 5)
            end
        end
        addNotification("Sanctiune materiale -> " .. pName, "sanction")
        return
    end

    -- Level 5-7: Player chooses between ticket or driving license suspension
    if nivel >= 5 and nivel <= 7 then
        if kind == "aa50" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) depasind limita cu peste 50km/h, limita: %dkm/h", pName, limita))
                say(string.format("In zona %s, acum ceva timp. Doresti amenda sau confiscarea licentei de condus o ora?", zona))
            else
                say(string.format("Hi %s! You were caught breaking speedlimit with more than 50km/h, limit: %dkm/h", pName, limita))
                say(string.format("In zone %s, some time ago. Do you want ticket or suspend driving license for 1h?", zona))
            end
        elseif kind == "aa100" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) depasind limita cu peste 100km/h, limita: %dkm/h", pName, limita))
                say(string.format("In zona %s, acum ceva timp. Doresti amenda sau confiscarea licentei de condus 2 ore?", zona))
            else
                say(string.format("Hi %s! You were caught breaking speedlimit with more than 100km/h, limit: %dkm/h", pName, limita))
                say(string.format("In zone %s, some time ago. Do you want ticket or suspend driving license for 2h?", zona))
            end
        elseif kind == "alc30" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) conducand cu o alcoolemie mai mare de 3.0", pName))
                say("Doresti sa fii sanctionat(a) cu o amenda sau prin confiscarea permisului de condus o ora?")
            else
                say(string.format("Hi %s! You were caught driving with alcoholemy more than 3.0", pName))
                say("Do you want a ticket or to confiscate your driving license for 1 hour?")
            end
        elseif kind == "nos" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) conducand un vehicul folosind NOS.", pName))
                say("Doresti sa fii sanctionat(a) cu o amenda sau prin confiscarea permisului de conducere o ora?")
            else
                say(string.format("Hi %s! You were caught driving a vehicle with NOS.", pName))
                say("Do you want a ticket or to confiscate your driving license for one hour?")
            end
        elseif kind == "con" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) conducand neregulamentar.", pName))
                say("Doresti sa fii sanctionat(a) cu o amenda sau prin confiscarea permisului de conducere o ora?")
            else
                say(string.format("Hi %s! You were caught driving illegally.", pName))
                say("Do you want a ticket or to confiscate your driving license for one hour?")
            end
        elseif kind == "parc" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) parcand neregulamentar.", pName))
                say("Doresti sa fii sanctionat(a) cu o amenda sau prin confiscarea permisului de conducere o ora?")
            else
                say(string.format("Hi %s! You were caught parking illegally.", pName))
                say("Do you want a ticket or to confiscate your driving license for one hour?")
            end
        elseif kind == "hidra" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) folosind hidraulice.", pName))
                say("Doresti sa fii sanctionat(a) cu o amenda sau prin confiscarea permisului de conducere o ora?")
            else
                say(string.format("Hi %s! You were caught using hydraulics.", pName))
                say("Do you want a ticket or to confiscate your driving license for 1 hour?")
            end
        end
        addNotification("Intrebare sanctiune (Nivel 5-7) -> " .. pName, "sanction")
        return
    end

    -- Level 8+: Confiscate license (+ ticket if NOT in Jail interior)
    if inJail then
        if kind == "aa50" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) depasind limita cu peste 50km/h, limita: %dkm/h", pName, limita))
                say(string.format("In zona %s, acum ceva timp, iti voi confisca permisul o ora.", zona))
            else
                say(string.format("Hi %s! You were caught breaking speedlimit with more than 50km/h, limit: %dkm/h", pName, limita))
                say(string.format("In zone %s, some time ago, I'll confiscate your license for 1 hour.", zona))
            end
            say("/confiscate " .. targetId .. " drivinglic 1")
        elseif kind == "aa100" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) depasind limita cu peste 100km/h, limita: %dkm/h", pName, limita))
                say(string.format("In zona %s, acum ceva timp, iti voi confisca permisul 2 ore.", zona))
            else
                say(string.format("Hi %s! You were caught breaking speedlimit with more than 100km/h, limit: %dkm/h", pName, limita))
                say(string.format("In zone %s, some time ago, I'll confiscate your license for 2 hours.", zona))
            end
            say("/confiscate " .. targetId .. " drivinglic 2")
        elseif kind == "alc30" then
            if ro then
                say(string.format("Salut %s, ai fost surprins(a) conducand cu o alcoolemie mai mare de 3.0", pName))
                say("Iti voi suspenda permisul de condus o ora.")
            else
                say(string.format("Hi %s! You were caught driving with alcoholemy more than 3.0", pName))
                say("I'll confiscate your driving license for one hour.")
            end
            say("/confiscate " .. targetId .. " drivinglic 1")
        elseif kind == "nos" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) conducand un vehicul folosind NOS.", pName))
                say("Iti voi suspenda permisul de conducere o ora.")
            else
                say(string.format("Hi %s! You were caught driving a vehicle with NOS.", pName))
                say("I'll suspend your driving license for one hour.")
            end
            say("/confiscate " .. targetId .. " drivinglic 1")
        elseif kind == "con" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) conducand neregulamentar.", pName))
                say("Iti voi suspenda permisul de conducere o ora.")
            else
                say(string.format("Hi %s! You were caught driving illegally.", pName))
                say("I'll confiscate your driving license for one hour.")
            end
            say("/confiscate " .. targetId .. " drivinglic 1")
        elseif kind == "parc" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) parcand neregulamentar.", pName))
                say("Iti voi suspenda permisul de conducere o ora.")
            else
                say(string.format("Hi %s! You were caught parking illegally.", pName))
                say("I'll confiscate your driving license for one hour.")
            end
            say("/confiscate " .. targetId .. " drivinglic 1")
        elseif kind == "hidra" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) folosind hidraulice.", pName))
                say("Iti voi confisca permisul de conducere pentru o ora.")
            else
                say(string.format("Hi %s! You were caught using hydraulics.", pName))
                say("I'll confiscate your driving license for one hour.")
            end
            say("/confiscate " .. targetId .. " drivinglic 1")
        end
        addNotification("Permis confiscat (Jail) -> " .. pName, "sanction")
    else
        if kind == "aa50" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) depasind limita cu peste 50km/h, limita: %dkm/h", pName, limita))
                say(string.format("In zona %s, acum ceva timp, iti voi confisca permisul o ora si vei primi o amenda.", zona))
            else
                say(string.format("Hi %s! You were caught breaking speedlimit with more than 50km/h, limit: %dkm/h", pName, limita))
                say(string.format("In zone %s, some time ago, I'll confiscate your license for 1h and give you a ticket.", zona))
            end
            say("/confiscate " .. targetId .. " drivinglic 1")
            queueAutoTicket(targetId, 8)
        elseif kind == "aa100" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) depasind limita cu peste 100km/h, limita: %dkm/h", pName, limita))
                say(string.format("In zona %s, acum ceva timp, iti voi confisca permisul 2 ore si vei primi o amenda.", zona))
            else
                say(string.format("Hi %s! You were caught breaking speedlimit with more than 100km/h, limit: %dkm/h", pName, limita))
                say(string.format("In zone %s, some time ago, I'll confiscate your license for 2h and give you a ticket.", zona))
            end
            say("/confiscate " .. targetId .. " drivinglic 2")
            queueAutoTicket(targetId, 8)
        elseif kind == "alc30" then
            if ro then
                say(string.format("Salut %s, ai fost surprins(a) conducand cu o alcoolemie mai mare de 3.0", pName))
                say("Iti voi suspenda permisul de condus o ora si iti voi acorda o amenda.")
            else
                say(string.format("Hi %s! You were caught driving with alcoholemy more than 3.0", pName))
                say("I'll give you a ticket and confiscate your driving license for one hour.")
            end
            say("/confiscate " .. targetId .. " drivinglic 1")
            queueAutoTicket(targetId, 11)
        elseif kind == "nos" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) conducand un vehicul folosind NOS.", pName))
                say("Iti voi suspenda permisul de conducere o ora si iti voi acorda o amenda.")
            else
                say(string.format("Hi %s! You were caught driving a vehicle with NOS.", pName))
                say("I'll suspend your driving license for one hour and give you a ticket.")
            end
            say("/confiscate " .. targetId .. " drivinglic 1")
            queueAutoTicket(targetId, 4)
        elseif kind == "con" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) conducand neregulamentar.", pName))
                say("Iti voi suspenda permisul de conducere o ora si iti voi acorda o amenda.")
            else
                say(string.format("Hi %s! You were caught driving illegally.", pName))
                say("I'll confiscate your driving license for one hour and give you a ticket.")
            end
            say("/confiscate " .. targetId .. " drivinglic 1")
            queueAutoTicket(targetId, 1)
        elseif kind == "parc" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) parcand neregulamentar.", pName))
                say("Iti voi suspenda permisul de conducere o ora si iti voi acorda o amenda.")
            else
                say(string.format("Hi %s! You were caught parking illegally.", pName))
                say("I'll confiscate your driving license for one hour and give you a ticket.")
            end
            say("/confiscate " .. targetId .. " drivinglic 1")
            queueAutoTicket(targetId, 0)
        elseif kind == "hidra" then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) folosind hidraulice, iti voi acorda o amenda si", pName))
                say("iti voi confisca permisul de conducere pentru o ora.")
            else
                say(string.format("Hi %s! You were caught using hydraulics. I'll give you a ticket and", pName))
                say("I'll confiscate your driving license for one hour.")
            end
            say("/confiscate " .. targetId .. " drivinglic 1")
            queueAutoTicket(targetId, 3)
        end
        addNotification("Permis + Amenda -> " .. pName, "sanction")
    end
end

local function sanctionWithIdCheck(kind, targetId)
    targetId = tonumber(targetId)
    if not targetId or not isPlayerOnline(targetId) then
        msg("Ai uitat sa scrii un ID valid sau jucatorul nu este conectat!")
        return
    end
    if kind == "mats" and PDX.blockColleague(targetId, "confiscare") then return end
    pendingSanction.active = true
    pendingSanction.type   = kind
    pendingSanction.id     = targetId
    pendingSanction.expire = os.clock() + 3.5
    say("/id " .. targetId)

    -- Fallback safety if server /id format differs
    lua_thread.create(function()
        wait(1200)
        if pendingSanction.active and pendingSanction.id == targetId and pendingSanction.type == kind then
            pendingSanction.active = false
            local fallbackScore = sampGetPlayerScore(targetId)
            if fallbackScore and fallbackScore > 0 then
                executeLevelSanction(kind, targetId, fallbackScore)
            end
        end
    end)
end

-- Automatic Radar Sanction (/sl & /sl <id>)
local function executeRadarSl(argId)
    local entry = nil
    if argId and argId ~= "" then
        local wantedId = tonumber(argId)
        if not wantedId then
            msg("Foloseste {28AFE0}/sl{FFFFFF} sau {28AFE0}/sl <id>{FFFFFF}.")
            return
        end
        for i = 1, #radarHistory do
            if radarHistory[i].id == wantedId then
                entry = radarHistory[i]
                break
            end
        end
        if not entry then
            msg("Nu a fost gasit acest jucator printre ultimii 5 surprinsi pe radar!")
            return
        end
    else
        if cfg.radar.lastid and cfg.radar.lastid >= 0 then
            entry = {
                id    = cfg.radar.lastid,
                nivel = cfg.radar.lastnivel,
                speed = cfg.radar.lastviteza,
            }
        end
        if not entry then
            msg("Nu exista niciun jucator inregistrat pe radar inca!")
            return
        end
    end

    local id     = entry.id
    local nivel  = tonumber(entry.nivel or entry.level) or 0
    local viteza = tonumber(entry.speed) or 0
    local limita = tonumber(cfg.radar.limita) or 100
    local zona   = tostring(cfg.radar.zona or "LS")
    local ro     = isRo()

    if not isPlayerOnline(id) then
        msg("Jucatorul cu ID " .. tostring(id) .. " nu mai este conectat!")
        return
    end
    if nivel < 5 then
        msg("Jucatorul are nivel 1-4 (" .. tostring(nivel) .. "), nu poate fi sanctionat!")
        return
    end

    local pName = getPlayerNameSafe(id) or ("ID " .. id)
    local inJail = isInJailInterior()

    if limita == 100 then
        if viteza < 103 then
            msg("Acest jucator a trecut cu mai putin de 103 km/h (" .. viteza .. " km/h).")
            return
        elseif viteza < 150 then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) conducand cu %dkm/h, limita fiind de %dkm/h", pName, viteza, limita))
                say(string.format("In zona %s, acum ceva timp, iti voi acorda o amenda.", zona))
            else
                say(string.format("Hi %s! You were caught driving with %dkm/h, speedlimit is %dkm/h", pName, viteza, limita))
                say(string.format("In zone %s, some time ago, I'll give you a ticket.", zona))
            end
            queueAutoTicket(id, 7)
        elseif viteza < 200 then
            if nivel <= 7 then
                if ro then
                    say(string.format("Salut %s! Ai fost surprins(a) conducand cu %dkm/h, limita fiind de %dkm/h", pName, viteza, limita))
                    say(string.format("In zona %s, acum ceva timp. Doresti amenda sau confiscarea licentei de condus o ora?", zona))
                else
                    say(string.format("Hi %s! You were caught driving with %dkm/h, speedlimit is %dkm/h", pName, viteza, limita))
                    say(string.format("In zone %s, some time ago. Do you want a ticket or suspended driving license for 1h?", zona))
                end
            else
                if inJail then
                    if ro then
                        say(string.format("Salut %s! Ai fost surprins(a) conducand cu %dkm/h, limita fiind de %dkm/h", pName, viteza, limita))
                        say(string.format("In zona %s, acum ceva timp, iti voi confisca permisul o ora.", zona))
                    else
                        say(string.format("Hi %s! You were caught driving with %dkm/h, speedlimit is %dkm/h", pName, viteza, limita))
                        say(string.format("In zone %s, some time ago, I'll confiscate your license for 1h.", zona))
                    end
                    say("/confiscate " .. id .. " drivinglic 1")
                else
                    if ro then
                        say(string.format("Salut %s! Ai fost surprins(a) conducand cu %dkm/h, limita fiind de %dkm/h", pName, viteza, limita))
                        say(string.format("In zona %s, acum ceva timp, iti voi confisca permisul o ora si vei primi o amenda.", zona))
                    else
                        say(string.format("Hi %s! You were caught driving with %dkm/h, speedlimit is %dkm/h", pName, viteza, limita))
                        say(string.format("In zone %s, some time ago, I'll confiscate your license for 1h and give you a ticket.", zona))
                    end
                    say("/confiscate " .. id .. " drivinglic 1")
                    queueAutoTicket(id, 8)
                end
            end
        else -- 200+ km/h
            if nivel <= 7 then
                if ro then
                    say(string.format("Salut %s! Ai fost surprins(a) conducand cu %dkm/h, limita fiind de %dkm/h", pName, viteza, limita))
                    say(string.format("In zona %s, acum ceva timp. Doresti amenda sau confiscarea licentei de condus 2 ore?", zona))
                else
                    say(string.format("Hi %s! You were caught driving with %dkm/h, speedlimit is %dkm/h", pName, viteza, limita))
                    say(string.format("In zone %s, some time ago. Do you want a ticket or suspended driving license for 2h?", zona))
                end
            else
                if inJail then
                    if ro then
                        say(string.format("Salut %s! Ai fost surprins(a) conducand cu %dkm/h, limita fiind de %dkm/h", pName, viteza, limita))
                        say(string.format("In zona %s, acum ceva timp, iti voi confisca permisul 2 ore.", zona))
                    else
                        say(string.format("Hi %s! You were caught driving with %dkm/h, speedlimit is %dkm/h", pName, viteza, limita))
                        say(string.format("In zone %s, some time ago, I'll confiscate your license for 2h.", zona))
                    end
                    say("/confiscate " .. id .. " drivinglic 2")
                else
                    if ro then
                        say(string.format("Salut %s! Ai fost surprins(a) conducand cu %dkm/h, limita fiind de %dkm/h", pName, viteza, limita))
                        say(string.format("In zona %s, acum ceva timp, iti voi confisca permisul 2 ore si vei primi o amenda.", zona))
                    else
                        say(string.format("Hi %s! You were caught driving with %dkm/h, speedlimit is %dkm/h", pName, viteza, limita))
                        say(string.format("In zone %s, some time ago, I'll confiscate your license for 2h and give you a ticket.", zona))
                    end
                    say("/confiscate " .. id .. " drivinglic 2")
                    queueAutoTicket(id, 8)
                end
            end
        end

    elseif limita == 130 then
        if viteza < 133 then
            msg("Acest jucator a trecut cu mai putin de 133 km/h (" .. viteza .. " km/h).")
            return
        elseif viteza < 180 then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) conducand cu %dkm/h, limita fiind de %dkm/h", pName, viteza, limita))
                say(string.format("In zona %s, acum ceva timp, iti voi acorda o amenda.", zona))
            else
                say(string.format("Hi %s! You were caught driving with %dkm/h, speedlimit is %dkm/h", pName, viteza, limita))
                say(string.format("In zone %s, some time ago, I'll give you a ticket.", zona))
            end
            queueAutoTicket(id, 7)
        else
            local hours = (viteza >= 230) and 2 or 1
            if nivel <= 7 then
                if ro then
                    say(string.format("Salut %s! Ai fost surprins(a) conducand cu %dkm/h, limita fiind de %dkm/h", pName, viteza, limita))
                    say(string.format("In zona %s, acum ceva timp. Doresti amenda sau confiscarea licentei de condus %s?", zona, hours == 2 and "2 ore" or "o ora"))
                else
                    say(string.format("Hi %s! You were caught driving with %dkm/h, speedlimit is %dkm/h", pName, viteza, limita))
                    say(string.format("In zone %s, some time ago. Do you want a ticket or suspended driving license for %dh?", zona, hours))
                end
            else
                if inJail then
                    if ro then
                        say(string.format("Salut %s! Ai fost surprins(a) conducand cu %dkm/h, limita fiind de %dkm/h", pName, viteza, limita))
                        say(string.format("In zona %s, acum ceva timp, iti voi confisca permisul %s.", zona, hours == 2 and "2 ore" or "o ora"))
                    else
                        say(string.format("Hi %s! You were caught driving with %dkm/h, speedlimit is %dkm/h", pName, viteza, limita))
                        say(string.format("In zone %s, some time ago, I'll confiscate your license for %dh.", zona, hours))
                    end
                    say("/confiscate " .. id .. " drivinglic " .. hours)
                else
                    if ro then
                        say(string.format("Salut %s! Ai fost surprins(a) conducand cu %dkm/h, limita fiind de %dkm/h", pName, viteza, limita))
                        say(string.format("In zona %s, acum ceva timp, iti voi confisca permisul %s si vei primi o amenda.", zona, hours == 2 and "2 ore" or "o ora"))
                    else
                        say(string.format("Hi %s! You were caught driving with %dkm/h, speedlimit is %dkm/h", pName, viteza, limita))
                        say(string.format("In zone %s, some time ago, I'll confiscate your license for %dh and give you a ticket.", zona, hours))
                    end
                    say("/confiscate " .. id .. " drivinglic " .. hours)
                    queueAutoTicket(id, 8)
                end
            end
        end

    elseif limita == 160 then
        if viteza < 163 then
            msg("Acest jucator a trecut cu mai putin de 163 km/h (" .. viteza .. " km/h).")
            return
        elseif viteza < 210 then
            if ro then
                say(string.format("Salut %s! Ai fost surprins(a) conducand cu %dkm/h, limita fiind de %dkm/h", pName, viteza, limita))
                say(string.format("In zona %s, acum ceva timp, iti voi acorda o amenda.", zona))
            else
                say(string.format("Hi %s! You were caught driving with %dkm/h, speedlimit is %dkm/h", pName, viteza, limita))
                say(string.format("In zone %s, some time ago, I'll give you a ticket.", zona))
            end
            queueAutoTicket(id, 7)
        else
            local hours = (viteza >= 260) and 2 or 1
            if nivel <= 7 then
                if ro then
                    say(string.format("Salut %s! Ai fost surprins(a) conducand cu %dkm/h, limita fiind de %dkm/h", pName, viteza, limita))
                    say(string.format("In zona %s, acum ceva timp. Doresti amenda sau confiscarea licentei de condus %s?", zona, hours == 2 and "2 ore" or "o ora"))
                else
                    say(string.format("Hi %s! You were caught driving with %dkm/h, speedlimit is %dkm/h", pName, viteza, limita))
                    say(string.format("In zone %s, some time ago. Do you want a ticket or suspended driving license for %dh?", zona, hours))
                end
            else
                if inJail then
                    if ro then
                        say(string.format("Salut %s! Ai fost surprins(a) conducand cu %dkm/h, limita fiind de %dkm/h", pName, viteza, limita))
                        say(string.format("In zona %s, acum ceva timp, iti voi confisca permisul %s.", zona, hours == 2 and "2 ore" or "o ora"))
                    else
                        say(string.format("Hi %s! You were caught driving with %dkm/h, speedlimit is %dkm/h", pName, viteza, limita))
                        say(string.format("In zone %s, some time ago, I'll confiscate your license for %dh.", zona, hours))
                    end
                    say("/confiscate " .. id .. " drivinglic " .. hours)
                else
                    if ro then
                        say(string.format("Salut %s! Ai fost surprins(a) conducand cu %dkm/h, limita fiind de %dkm/h", pName, viteza, limita))
                        say(string.format("In zona %s, acum ceva timp, iti voi confisca permisul %s si vei primi o amenda.", zona, hours == 2 and "2 ore" or "o ora"))
                    else
                        say(string.format("Hi %s! You were caught driving with %dkm/h, speedlimit is %dkm/h", pName, viteza, limita))
                        say(string.format("In zone %s, some time ago, I'll confiscate your license for %dh and give you a ticket.", zona, hours))
                    end
                    say("/confiscate " .. id .. " drivinglic " .. hours)
                    queueAutoTicket(id, 8)
                end
            end
        end
    else
        -- Generic fallback for custom speed limit
        local diff = viteza - limita
        if diff < 3 then
            msg("Acest jucator a trecut cu doar " .. viteza .. " km/h (limita " .. limita .. " km/h).")
            return
        elseif diff < 50 then
            sanctionDirect("aa", id)
        elseif diff < 100 then
            executeLevelSanction("aa50", id, nivel)
        else
            executeLevelSanction("aa100", id, nivel)
        end
        return
    end

    addNotification(string.format("Sanctiune Radar (%d km/h) -> %s", viteza, pName), "sanction")
end

-- Classic SA-MP Dialog 7000 fallback (if user chooses classic mode in settings)
local CLASSIC_SANCTION_TEXT_FULL = table.concat({
    "- {296dff}Depasire limita de viteza",
    "- {348ceb}Depasire limita de viteza peste 50km/h",
    "- {47c2ff}Depasire limita de viteza peste 100km/h",
    " ",
    "- {296dff}Faruri stinse",
    "- {348ceb}Mers pe partea carosabila",
    "- {47c2ff}Alcoolemie peste 1.5",
    " ",
    "- {296dff}Folosire nos",
    "- {348ceb}Mers pe contra-sens",
    "- {47c2ff}Parcare ilegala",
    "- {75fffa}Hidraulice",
    "- {9efffb}Alcoolemie peste 3.0",
    " ",
    "- {296dff}Arme la Vedere",
    "- {348ceb}Posesie Droguri",
    "- {47c2ff}Folosire Droguri",
    " ",
    "- {296dff}Materiale Fara Licenta",
    "- {348ceb}Folosire Materiale"
}, "\n")

local CLASSIC_SANCTION_TEXT_NOROADS = table.concat({
    "- {296dff}Arme la Vedere",
    "- {348ceb}Posesie Droguri",
    "- {47c2ff}Folosire Droguri",
    " ",
    "- {296dff}Materiale Fara Licenta",
    "- {348ceb}Folosire Materiale"
}, "\n")

local classicSanctionTarget = -1
local classicSanctionRoads  = true
local function openSanctionsFor(targetId)
    if targetId and tonumber(targetId) then
        safeCopyBuf(buf_sanId, tostring(tonumber(targetId)))
        classicSanctionTarget = tonumber(targetId)
    end
    if cfg.settings.sanMenuType == 1 and classicSanctionTarget >= 0 then
        classicSanctionRoads = isRutieraActive()
        local dlgTxt = classicSanctionRoads and CLASSIC_SANCTION_TEXT_FULL or CLASSIC_SANCTION_TEXT_NOROADS
        sampShowDialog(7000, "{28AFE0}" .. getFaction() .. " Assist{FFFFFF} - Sanctiuni", dlgTxt, "Select", "Cancel", 2)
    else
        openAnimWin(sanWin)
    end
end

-- FVR Sequence Runner
local function startFvrSequence()
    if timers.fvrActive then
        msg("Exista deja un FVR in curs! Scrie {28AFE0}/sfvr{FFFFFF} pentru a-l anula.")
        return
    end
    timers.fvrActive = true
    local secs = math.max(1, tonumber(cfg.fvr.secunde) or 10)
    timers.fvrLeft = secs
    hudCacheDirty = true

    lua_thread.create(function()
        if cfg.fvr.enableR == 1 and cfg.fvr.fvrR ~= "" then
            say("/r " .. cfg.fvr.fvrR)
            wait(150)
        end
        if cfg.fvr.fvrD ~= "" then
            say("/d " .. cfg.fvr.fvrD)
        end
        msg("FVR pornit (" .. secs .. "s). Scrie {28AFE0}/sfvr{FFFFFF} pentru a opri numaratoarea.")
        addNotification("FVR in " .. secs .. " secunde (/sfvr pt anulare)", "info")

        for i = secs, 1, -1 do
            if not timers.fvrActive then return end
            timers.fvrLeft = i
            hudCacheDirty = true
            wait(1000)
        end

        if timers.fvrActive then
            timers.fvrActive = false
            timers.fvrLeft = 0
            hudCacheDirty = true
            say("/fvr")
            wait(200)
            if cfg.fvr.fvrF ~= "" then
                say("/d " .. cfg.fvr.fvrF)
            end
            addNotification("FVR efectuat cu succes!", "saved")
        end
    end)
end

local function stopFvrSequence()
    if timers.fvrActive then
        timers.fvrActive = false
        timers.fvrLeft = 0
        hudCacheDirty = true
        if cfg.fvr.fvrStop ~= "" then
            say("/d " .. cfg.fvr.fvrStop)
        end
        addNotification("FVR a fost anulat!", "sanction")
    else
        msg("Nu ai un FVR activ in acest moment.")
    end
end

-- GOV Sequence Runner
local function sendPdGov()
    lua_thread.create(function()
        if cfg.gov.gov1 ~= "" then
            say("/gov " .. cfg.gov.gov1)
        end
        if cfg.gov.l1 == 1 and cfg.gov.gov2 ~= "" then
            wait(450)
            say("/gov " .. cfg.gov.gov2)
        end
        if cfg.gov.l2 == 1 and cfg.gov.gov3 ~= "" then
            wait(450)
            say("/gov " .. cfg.gov.gov3)
        end
        addNotification("Anuntul /gov a fost trimis!", "saved")
    end)
end

-- Radar Key Action (3-stage cycle from CLEO)
local function triggerRadarKeyAction()
    if not state.isDriving then
        msg("Trebuie sa fii la volanul unei masini de politie pentru a folosi radarul!")
        return
    end
    local limita = tonumber(cfg.radar.limita) or 100
    local zona   = tostring(cfg.radar.zona or "LS")
    local stg    = tonumber(cfg.radar.stage) or 0

    if stg == 0 then
        cfg.radar.stage = 1
        liStep = 0
        hudCacheDirty = true
        say("/startradar " .. limita)
        say("/d Pun radar in zona " .. zona .. ".")
        msg(string.format("Radar activ: {28AFE0}%d km/h{FFFFFF} (%s). Stop: {28AFE0}[%s]", limita, zona, cfg.pd.nTastaR))
        addNotification("Radar pornit: " .. zona .. " (" .. limita .. " km/h)", "radar")

    elseif stg == 1 then
        cfg.radar.stage = 2
        liStep = 0
        hudCacheDirty = true
        if radaron and cfg.radar.lastid and cfg.radar.lastid >= 0 then
            radaron = false
            say("/stopradar")
            say("/find " .. cfg.radar.lastid)
            msg("{28AFE0}/sl{FFFFFF} - ultimul jucator | {28AFE0}/sl <id>{FFFFFF} - ultimii 5.")
            addNotification("Radar oprit & /find pe ID " .. cfg.radar.lastid, "radar")
        else
            say("/stopradar")
            addNotification("Radar oprit", "info")
        end

    else -- stg == 2: Resume radar
        cfg.radar.stage = 1
        hudCacheDirty = true
        say("/startradar " .. limita)
        say("/cancel find")
        if cfg.pd.allowrepeat == 1 then
            cfg.pd.allowrepeat = 0
            say("/d Reiau radarul din zona " .. zona)
        else
            cfg.pd.allowrepeat = 1
            say("/d Reiau radarul din zona " .. zona .. ".")
        end
        addNotification("Radar reluat: " .. zona .. " (" .. limita .. " km/h)", "radar")
    end
end

-- Cuff Key Action (cuffs passengers in your car / right next to you)
local function triggerCuffKeyAction()
    -- doar in masina: pe jos tasta (de obicei C) se apasa des din alte motive -> nu face nimic, fara mesaje
    if not (doesCharExist(PLAYER_PED) and isCharInAnyCar(PLAYER_PED)) then return end
    lua_thread.create(function()
        local myCar = isCharInAnyCar(PLAYER_PED) and storeCarCharIsInNoSave(PLAYER_PED) or nil
        local px, py, pz = getCharCoordinates(PLAYER_PED)
        local cuffedAny = false

        for id = 0, 999 do
            if sampIsPlayerConnected(id) then
                local ok, ped = sampGetCharHandleBySampPlayerId(id)
                if ok and doesCharExist(ped) and ped ~= PLAYER_PED then
                    local sameCar = (myCar ~= nil and myCar ~= 0 and isCharInCar(ped, myCar))
                    local tx, ty, tz = getCharCoordinates(ped)
                    local dist = getDistanceBetweenCoords3d(px, py, pz, tx, ty, tz)
                    if sameCar or dist < 0.8 then
                        say("/cuff " .. id)
                        say("/cancel find")
                        cfg.pd.arrestid = id
                        hudCacheDirty = true
                        cuffedAny = true
                        local pName = getPlayerNameSafe(id) or ("ID " .. id)
                        addNotification("Cuff aplicat -> " .. pName .. " (" .. id .. ")", "sanction")
                        wait(300)
                    end
                end
            end
        end

        if not cuffedAny then
            msg("Niciun suspect nu se afla in masina ta (pe G) pentru /cuff!")
        end
    end)
end

-- Frisk pe tasta: UN singur jucator - cel mai apropiat de pe raza care nu e coleg si nu a mai fost verificat
-- in ultimele 2 minute. Lista de asteptare e interna (nu se afiseaza nicaieri), dupa nume (nu dupa ID).
PDX.friskCooldown = {}          -- [nume_lowercase] = os.clock() pana cand e "verificat recent"
PDX.FRISK_COOLDOWN_SEC = 120

local function triggerFriskKeyAction()
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local radius = tonumber(cfg.pd.RazaFrisk) or 3.0
    local now = os.clock()

    -- curata intrarile expirate
    for nick, untilT in pairs(PDX.friskCooldown) do
        if now >= untilT then PDX.friskCooldown[nick] = nil end
    end

    local bestId, bestD, anyInRange = nil, nil, false
    for id = 0, 1003 do
        if sampIsPlayerConnected(id) then
            local ok, ped = sampGetCharHandleBySampPlayerId(id)
            if ok and doesCharExist(ped) and ped ~= PLAYER_PED then
                local tx, ty, tz = getCharCoordinates(ped)
                local dist = getDistanceBetweenCoords3d(px, py, pz, tx, ty, tz)
                if dist <= radius then
                    anyInRange = true
                    local nick = (sampGetPlayerNickname(id) or ""):lower()
                    if not PDX.sameColorAsMe(id) and not PDX.friskCooldown[nick] and (not bestD or dist < bestD) then
                        bestId, bestD = id, dist
                    end
                end
            end
        end
    end

    if not bestId then
        if anyInRange then
            msg("Niciun jucator nou de verificat pe o raza de {28AFE0}" .. string.format("%.1fm", radius) .. "{FFFFFF}.")
        else
            msg("Niciun jucator nu se afla pe o raza de {28AFE0}" .. string.format("%.1fm", radius) .. "{FFFFFF}!")
        end
        return
    end

    local pName = getPlayerNameSafe(bestId) or ("ID " .. bestId)
    PDX.friskCooldown[pName:lower()] = now + PDX.FRISK_COOLDOWN_SEC
    lua_thread.create(function()
        if getFaction() ~= "NG" and not isInJailInterior() then
            if isRo() then
                say("Salut " .. pName .. "! Acesta este un control de rutina" .. (friskSpamToggle and "." or ""))
            else
                say("Hello " .. pName .. "! This is a routine check" .. (friskSpamToggle and "." or ""))
            end
            friskSpamToggle = not friskSpamToggle
        end
        say("/frisk " .. bestId)
    end)
    addNotification("Frisk -> " .. pName .. " (" .. bestId .. ")", "info")
end

-- Gate / Door Key Action (Key C near Jail LS gates & NG Area 69 gates)
local function triggerGateKeyAction()
    if not doesCharExist(PLAYER_PED) then return end
    local px, py, _ = getCharCoordinates(PLAYER_PED)
    local inCar = isCharInAnyCar(PLAYER_PED)

    local function near2D(tx, ty, r)
        local dx, dy = px - tx, py - ty
        return (dx * dx + dy * dy) <= (r * r)
    end

    if not inCar then
        if near2D(1779.03, -1581.22, 5.0) then say("/opengate 2") end
        if near2D(1768.05, -1581.73, 5.0) then say("/opengate 1") end
    else
        if near2D(135.1971, 1935.0648, 5.0) then say("/exit") end
        if near2D(135.0252, 1947.2804, 5.0) then say("/enter") end
        if near2D(280.9749, 1821.3486, 5.0) then say("/exit") end
        if near2D(290.1082, 1821.7593, 5.0) then say("/enter") end
    end
    PDX.gateExtra() -- lifturi LSPD/LVPD (/goup /godown) + bariere HQ in masina
end

-- =========================================================================================
--  SECTION 7: SAMP EVENTS (Zero-Lag Chat & Dialog Interception)
-- =========================================================================================
-- Hook-urile sunt protejate cu pcall: SAMP.Lua NU prinde erorile din handler, iar o eroare
-- aici poate face ca mesajul/dialogul serverului sa nu mai fie afisat (sau sa omoare scriptul).
function sampev.onShowDialog(...)
    local ok, res = pcall(PDX.onShowDialogImpl, ...)
    if not ok then print("[PDAssist] onShowDialog error: " .. tostring(res)) return end
    return res
end

function sampev.onServerMessage(...)
    local ok, err = pcall(PDX.onServerMessageImpl, ...)
    if not ok then print("[PDAssist] onServerMessage error: " .. tostring(err)) end
    -- intentionat nu returnam nimic: PDAssist nu ascunde si nu modifica niciodata mesajele serverului
end

function sampev.onSendDialogResponse(dialogId, button, listboxId, input)
    -- ai raspuns TU la dialogul de login (ai scris parola / Quit) -> opreste completarea automata in curs
    if not PDX.login.sending and PDX.login.dialogId ~= nil and dialogId == PDX.login.dialogId then
        PDX.login.gen = PDX.login.gen + 1
    end
end

-- Serverul ascunde / arata nametag-ul unui jucator (ex: Hitmen in /undercover)
function sampev.onShowPlayerNameTag(playerId, show)
    pcall(function()
        if playerId and playerId >= 0 then
            PDX.hiddenTag[playerId] = (show == false or show == 0) or nil
        end
    end)
end

function sampev.onPlayerQuit(playerId, reason)
    pcall(function() if playerId then PDX.hiddenTag[playerId] = nil end end)
end

function sampev.onShowTextDraw(id, data)
    local ok, err = pcall(PDX.onKeypadTextDraw, id, data)
    if not ok then print("[PDAssist] onShowTextDraw error: " .. tostring(err)) end
end

function sampev.onSendCommand(cmd)
    local ok, err = pcall(function()
        local c = tostring(cmd or ""):lower():gsub("^%s+", "")
        if c:find("^/cancel%s+find") then PDX.clearFind() end
    end)
    if not ok then print("[PDAssist] onSendCommand error: " .. tostring(err)) end
end

function sampev.onDisplayGameText(style, time, text)
    local ok, err = pcall(function()
        local m = tostring(text or ""):gsub("~[%a%d_]+~", " "):lower()
        if m:find("marker gone", 1, true) or m:find("marker eliminat", 1, true) then PDX.clearFind() end
    end)
    if not ok then print("[PDAssist] onDisplayGameText error: " .. tostring(err)) end
end

function PDX.onShowDialogImpl(dialogId, style, title, button1, button2, text)
    local now = os.clock()
    local isList = (style == 2 or style == 4 or style == 5)

    -- Login automat: NU se mai face aici (hook-ul de dialog nu e de incredere pe 0.3DL),
    -- ci din bucla principala, pe dialogul vizibil -> PDX.loginPoll()

    -- /cancel find cu mai multe markere: alege markerul suspectului anulat automat
    if PDX.cancelPick then
        if now > PDX.cancelPick.expire then
            PDX.cancelPick = nil
        elseif isList then
            local ttl = tostring(title or ""):gsub("{%x%x%x%x%x%x}", ""):lower()
            if ttl:find("localizare", 1, true) or ttl:find("cancel find", 1, true) then
                local idx = PDX.findInList(text, { PDX.cancelPick.name }, style)
                PDX.cancelPick = nil
                if idx >= 0 then
                    lua_thread.create(function() wait(150); sampSendDialogResponse(dialogId, 1, idx, "") end)
                    return false
                end
            end
        end
    end

    -- Spawn rapid (/scasa, /slspd ...)
    if PDX.pendingSpawn then
        if now > PDX.pendingSpawn.expire then
            PDX.pendingSpawn = nil
        elseif isList then
            local srch = PDX.pendingSpawn.searches
            PDX.pendingSpawn = nil
            local idx = PDX.findInList(text, srch, style)
            if idx >= 0 then
                lua_thread.create(function() wait(150); sampSendDialogResponse(dialogId, 1, idx, "") end)
                return false
            end
            msg("Nu am gasit {28AFE0}" .. tostring(srch[1]) .. "{FFFFFF} in /spawnchange. Alege manual din lista.")
        end
    end

    -- Instant lag-free auto-selection for /ticket
    if pendingTicket.active then
        if now <= pendingTicket.expire and (style == 2 or style == 4 or style == 5) then
            local line = pendingTicket.line
            pendingTicket.active = false
            sampSendDialogResponse(dialogId, 1, line, "")
            return false
        elseif now > pendingTicket.expire then
            pendingTicket.active = false
        end
    end

    -- Instant lag-free auto-selection for /su
    if pendingSu.active then
        if now <= pendingSu.expire and isList then
            local line = pendingSu.line
            pendingSu.active = false
            if pendingSu.search then
                -- cauta randul dupa text: nu se strica daca serverul schimba ordinea
                line = PDX.findInList(text, pendingSu.search, style)
                if line < 0 then
                    msg("Nu am gasit {28AFE0}" .. tostring(pendingSu.search[1]) .. "{FFFFFF} in lista /su. Alege manual din dialog.")
                    return
                end
            end
            sampSendDialogResponse(dialogId, 1, line, "")
            return false
        elseif now > pendingSu.expire then
            pendingSu.active = false
        end
    end
end

function PDX.onServerMessageImpl(color, text)
    local clean = tostring(text or ""):gsub("{%x+}", "")
    local now = os.clock()

    -- 0. Extensii: PIN automat la intrare, urmarire /find, HQ, nefondat dublu
    do
        local low = clean:lower()
        if tonumber(cfg.login.pinAuto) == 1 and (cfg.login.pin or "") ~= ""
        and (low:find("bine ai venit", 1, true) or low:find("welcome,", 1, true) or low:find("welcome back", 1, true)) then
            PDX.keypad = {}
            lua_thread.create(function() wait(1500); sampSendChat("/pin") end)
        end
        PDX.checkFindMessages(clean)
        PDX.checkHQ(low)
        -- /jc: strange liniile primite dupa /jaillist (nu le ascunde)
        if PDX.jc.active and now < PDX.jc.untilT then
            -- fara mesajele obisnuite de chat (altfel numele celor care vorbesc ar aparea gresit in lista)
            local isChat = low:find(" spune:", 1, true) or low:find(" says:", 1, true) or low:find("[freq", 1, true)
                or low:find("anunt publicat", 1, true) or low:find("ad placed", 1, true) or low:find("sms ", 1, true)
                or low:match("^%s*hq:") or low:find("%*%*") or low:find("(r)", 1, true) or low:find("(d)", 1, true)
                or low:find("a intrebat", 1, true) or low:find("asked:", 1, true) or low:find("a raspuns", 1, true)
            if not isChat then PDX.jc.lines[#PDX.jc.lines + 1] = clean end
        end

        -- Arest efectuat -> scoate ID-ul de la CUFF & ARREST din HUD
        local aid = tonumber(cfg.pd.arrestid) or -1
        if aid >= 0 then
            local done = low:find("you arrested", 1, true) or low:find("ai arestat", 1, true)
                or low:find("l-ai arestat", 1, true) or low:find("ai procesat", 1, true)
                or low:find("l-ai procesat", 1, true) or low:find("suspect has been", 1, true)
            if not done and low:match("^%s*hq:") and (low:find("arrested", 1, true) or low:find("arestat", 1, true) or low:find("procesat", 1, true)) then
                local an = (getPlayerNameSafe(aid) or ""):lower()
                done = an ~= "" and PDX.hasName(low, an)
            end
            if done then
                cfg.pd.arrestid = -1
                hudCacheDirty   = true
            end
        end
    end

    -- 1. Duty state detection (PD / FBI / NG)
    local lowerClean = clean:lower()
    if lowerClean:find("is now on duty") or lowerClean:find("este acum la datorie") or lowerClean:find("you are now on duty") or lowerClean:find("esti acum la datorie") then
        local myNick = getPlayerNameSafe(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
        if not myNick or clean:find(myNick, 1, true) or lowerClean:find("you are") or lowerClean:find("esti acum") then
            state.onDuty = true
            hudCacheDirty = true
        end
    elseif lowerClean:find("is no longer on duty") or lowerClean:find("nu mai este la datorie") or lowerClean:find("you are now off duty") or lowerClean:find("nu mai esti la datorie") then
        local myNick = getPlayerNameSafe(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
        if not myNick or clean:find(myNick, 1, true) or lowerClean:find("you are") or lowerClean:find("nu mai esti") then
            state.onDuty = false
            hudCacheDirty = true
        end
    end

    -- 2. Auto-Engine prompt detection
    if cfg.pd.autoengine == 1 then
        if clean:find("Use /engine or press 2 to turn on the engine.", 1, true)
        or clean:find("Scrie /engine sau apasa 2 pentru a porni motorul.", 1, true)
        or clean:find("Use /engine to turn on the engine.", 1, true)
        or clean:find("Scrie /engine pentru a porni motorul.", 1, true) then
            lua_thread.create(function()
                wait(120)
                say("/engine")
            end)
        end
    end

    -- 3. /id Level parser for level-dependent sanctions (/aa50, /aa100, /nos, /con, /parc, /hidra, /alc30, /mats)
    if pendingSanction.active and now <= pendingSanction.expire then
        if clean:find("Ping:", 1, true) and (clean:find("Level:", 1, true) or clean:find("Nivel:", 1, true)) then
            local lvlStr = clean:match("Level:%s*(%d+)") or clean:match("Nivel:%s*(%d+)")
            -- raspunsul /id incepe cu "(ID) Nume | Ping: ..." -> trebuie sa fie jucatorul cerut
            local lineId = tonumber(clean:match("^%s*%((%d+)%)"))
            if lineId and lineId ~= pendingSanction.id then lvlStr = nil end
            if lvlStr then
                local kind = pendingSanction.type
                local tId  = pendingSanction.id
                pendingSanction.active = false
                lua_thread.create(function()
                    wait(80)
                    executeLevelSanction(kind, tId, tonumber(lvlStr))
                end)
            end
        end
    elseif pendingSanction.active and now > pendingSanction.expire then
        pendingSanction.active = false
    end

    -- 3B. Server Radar status sync (RO & EN) so HUD always reflects real radar state
    if lowerClean:find("radar started", 1, true)
    or lowerClean:find("you have activated the radar", 1, true)
    or lowerClean:find("ai pornit radarul", 1, true)
    or lowerClean:find("radarul a fost pornit", 1, true) then
        cfg.radar.stage = 1
        hudCacheDirty = true
    elseif lowerClean:find("radar stopped", 1, true)
    or lowerClean:find("radar deactivated", 1, true)
    or lowerClean:find("you have deactivated the radar", 1, true)
    or lowerClean:find("ai oprit radarul", 1, true)
    or lowerClean:find("radarul a fost oprit", 1, true) then
        if cfg.radar.stage == 1 then
            cfg.radar.stage = 2
            hudCacheDirty = true
        end
    end

    -- 4. Radar speeder detection (RO & EN)
    -- EN: Name [ID:12, L:34] is driving with 178 km/h, limit: 100 km/h.
    -- RO: Name [ID:12, N:34] conduce cu 178 km/h, limita: 100 km/h.
    if clean:find("km/h", 1, true) and clean:find("[ID:", 1, true) then
        local sName, sId, sLvl, sSpd, sLim = clean:match("^(.-)%s*%[ID:(%d+),%s*[LN]:(%d+)%]%s*is driving with%s*(%d+)%s*km/h,%s*limit:%s*(%d+)%s*km/h")
        if not sId then
            sName, sId, sLvl, sSpd, sLim = clean:match("^(.-)%s*%[ID:(%d+),%s*[LN]:(%d+)%]%s*conduce cu%s*(%d+)%s*km/h,%s*limita:%s*(%d+)%s*km/h")
        end
        if sId then
            local idNum  = tonumber(sId)
            local lvlNum = tonumber(sLvl) or 0
            local spdNum = tonumber(sSpd) or 0
            local limNum = tonumber(sLim) or (tonumber(cfg.radar.limita) or 100)

            cfg.radar.lastid     = idNum
            cfg.radar.lastnivel  = lvlNum
            cfg.radar.lastviteza = spdNum
            cfg.radar.lastnume   = sName or ("ID " .. sId)
            cfg.radar.stage      = 1
            radaron              = true
            hudCacheDirty        = true

            -- Insert at top of last-5 radar history
            table.insert(radarHistory, 1, {
                id      = idNum,
                name    = sName or ("ID " .. sId),
                level   = lvlNum,
                speed   = spdNum,
                limit   = limNum,
                timeStr = os.date("%H:%M:%S"),
            })
            while #radarHistory > 5 do
                table.remove(radarHistory)
            end

            lua_thread.create(function()
                wait(30)
                msg(string.format(
                    "ID: %d (Niv %d) - {FF6347}%d km/h{FFFFFF} | [{28AFE0}%s{FFFFFF}] stop & find",
                    idNum, lvlNum, spdNum, tostring(cfg.pd.nTastaR)
                ))
                addNotification(string.format("%s [%d] -> %d km/h (Niv %d)", sName or "Suspect", idNum, spdNum, lvlNum), "radar")
            end)
        end
    end
end

-- =========================================================================================
--  SECTION 8: ON-SCREEN INDICATORS & HUDS
--  1. Right-Side Outlined Keybinds + Status + Live Timers HUD (TaxiAssist + LSSI Hybrid)
--  2. Radar Active Mini-HUD Card (Modern Glass Card)
--  3. Personal Blacklist Pinned Overlay
--  4. Toast Notification Renderer
-- =========================================================================================
local OUTLINE_DX = { -1,  1,  0,  0, -1,  1, -1,  1 }
local OUTLINE_DY = {  0,  0, -1,  1, -1, -1,  1,  1 }
local hudDrawPos = imgui.ImVec2(0, 0)

local function drawOutlinedText(dl, font, fontSize, x, y, colU32, text)
    local addTextFn = imgui.lib.ImDrawList_AddTextFontPtr
    local outline   = (math.floor(colU32 / 16777216) % 256) * 16777216 -- negru, cu acelasi alpha ca textul (pt fade)
    for k = 1, 8 do
        hudDrawPos.x, hudDrawPos.y = x + OUTLINE_DX[k], y + OUTLINE_DY[k]
        addTextFn(dl, font, fontSize, hudDrawPos, outline, text, nil, 0.0, nil)
    end
    hudDrawPos.x, hudDrawPos.y = x, y
    addTextFn(dl, font, fontSize, hudDrawPos, colU32, text, nil, 0.0, nil)
end

-- 1. Right-Side Keybinds & Live Status Indicator
-- HUD stil clasic PDHelper (CLEO): jos-dreapta, deasupra "RPG.B-ZONE.RO", "Nume: Tasta", titlul la final
function PDX.drawClassicHud(dl, font, sw, sh, rows)
    local fs = imgui.GetFontSize() * 1.3
    if PDX.hudFont then
        font, fs = PDX.hudFont, PDX.hudFontSize
    end
    local hs = PDX.hudScale() -- marimea HUD din /pdc -> General
    fs = fs * hs
    local lineH  = math.floor(fs * 1.12 + 0.5) -- randuri strinse: textul creste in latime, nu in inaltime
    local cLabel = PDX.lc.hudAccent -- implicit #28AFE0, aceeasi culoare ca [PDAssist] din chat
    local cValue = PDX.lc.hudText
    local cIcon  = PDX.lc.hudIcon
    local cTitle = PDX.lc.hudTitle

    -- etichetele raman cu MAJUSCULE (ca la HUD-ul modern), doar fara spatiile de la capete
    local function nice(s)
        return (s:gsub("^%s+", ""):gsub("%s+$", ""))
    end

    local lines = {}
    local iconW = 0
    local function add(icon, ci, a, b, ca, cb)
        icon = (icon or ""):gsub("%s+$", "")
        local wi = icon ~= "" and font:CalcTextSizeA(fs, 10000, -1, icon).x or 0
        if wi > iconW then iconW = wi end
        lines[#lines + 1] = {
            icon = icon, ci = ci, a = a, b = b, ca = ca, cb = cb,
            wa = font:CalcTextSizeA(fs, 10000, -1, a).x,
            wb = font:CalcTextSizeA(fs, 10000, -1, b).x,
        }
    end
    for i = 2, #rows do -- randul 1 e titlul modern
        local r   = rows[i]
        local val = r.tag:gsub("^%s*%[", ""):gsub("%]%s*$", "")
        local head, rest = r.label:match("^([^:]+):%s*(.-)%s*$")
        if head then
            add(r.icon, cIcon, nice(head) .. ": ", rest .. (val ~= "" and (" (" .. val .. ")") or ""), cLabel, cValue)
        else
            add(r.icon, cIcon, nice(r.label) .. ": ", val, cLabel, cValue)
        end
    end
    add(fa.ICON_FA_SHIELD_ALT, cTitle, getFaction() .. " ", "ASSIST V1.0", cValue, cTitle)

    local gap  = math.floor(7 * hs + 0.5) -- spatiu intre coloana de iconite si text
    local maxW = 0
    for _, l in ipairs(lines) do
        if l.wa + l.wb > maxW then maxW = l.wa + l.wb end
    end
    local totalW = iconW + gap + maxW
    local totalH = #lines * lineH
    hudLastWidth, hudLastHeight = totalW, totalH -- folosite de /hudpos si de slidere

    -- pozitie: in mutare (/hudpos) = dupa mouse; mutata = salvata; altfel jos-dreapta deasupra "RPG.B-ZONE.RO"
    local right, top
    if hudMoving then
        local mx, my = getCursorPos()
        right = math.max(totalW + 12, math.min(sw - 6, mx + totalW * 0.5))
        top   = math.max(12, math.min(sh - totalH - 12, my - totalH * 0.5))
        dl:AddRectFilled(imgui.ImVec2(right - totalW - 10, top - 6), imgui.ImVec2(right + 6, top + totalH + 6), 0xAA0A1018, 8.0)
        dl:AddRect(imgui.ImVec2(right - totalW - 10, top - 6), imgui.ImVec2(right + 6, top + totalH + 6), cLabel, 8.0, 15, 1.5)
        local hint = PDX.tr("[CLICK STANGA] Fixeaza  |  [ESC] Anuleaza")
        local hfs  = imgui.GetFontSize()
        local hw   = imgui.GetFont():CalcTextSizeA(hfs, 10000, -1, hint).x
        drawOutlinedText(dl, imgui.GetFont(), hfs, right - totalW * 0.5 - hw * 0.5, top - 24, 0xFF2EC0FF, hint)
    elseif cfg.settings.classic_custom == true and (tonumber(cfg.settings.classic_x) or -1) > 0 and (tonumber(cfg.settings.classic_y) or -1) > 0 then
        right = math.max(totalW + 10, math.min(sw - 6, tonumber(cfg.settings.classic_x)))
        top   = math.max(10, math.min(sh - totalH - 10, tonumber(cfg.settings.classic_y)))
    else
        right = sw - 8
        top   = math.floor(sh * 0.966) - totalH
    end

    local textX = math.floor(right - maxW)
    local iconX = textX - gap - iconW
    local y     = math.floor(top)
    for _, l in ipairs(lines) do
        if l.icon ~= "" then
            -- iconite centrate in coloana lor, ca sa fie aliniate frumos
            local wi = font:CalcTextSizeA(fs, 10000, -1, l.icon).x
            drawOutlinedText(dl, font, fs, iconX + (iconW - wi) * 0.5, y, l.ci or cLabel, l.icon)
        end
        drawOutlinedText(dl, font, fs, textX, y, l.ca, l.a)
        if l.b ~= "" then drawOutlinedText(dl, font, fs, textX + l.wa, y, l.cb, l.b) end
        y = y + lineH
    end
end

local hudOverlay = imgui.OnFrame(
    function()
        return ((cfg.settings.hud == 1) or hudMoving) and not state.paused and not state.scoreboard
    end,
    function(self)
        self.HideCursor = not hudMoving
        local sw, sh = getScreenResCached()
        local now    = os.clock()
        local dl     = imgui.GetBackgroundDrawList()
        local font   = imgui.GetFont()
        local fSize  = imgui.GetFontSize() * 1.18 * PDX.hudScale() -- marimea HUD din /pdc -> General
        local lineH  = math.floor(fSize + 5)

        local u32Cyan   = PDX.lc.hudAccent -- culoare accent din /pdc -> Aspect
        local u32Gold   = imgui.ColorConvertFloat4ToU32(colors.gold)
        local u32Green  = 0xFF55EA6C
        local u32Red    = 0xFF5050FF
        local u32White  = PDX.lc.hudText
        local u32Muted  = 0xFFB8C4D4

        local rows = {}
        local function addRow(icon, label, tag, colIcon, colLabel, colTag)
            local iconPart  = icon and (icon .. " ") or ""
            local labelPart = PDX.tr(label or "")
            local tagPart   = tag or ""
            local wIcon     = iconPart ~= "" and font:CalcTextSizeA(fSize, 10000, -1, iconPart).x or 0
            local wLabel    = labelPart ~= "" and font:CalcTextSizeA(fSize, 10000, -1, labelPart).x or 0
            local wTag      = tagPart ~= "" and font:CalcTextSizeA(fSize, 10000, -1, tagPart).x or 0
            table.insert(rows, {
                icon = iconPart, label = labelPart, tag = tagPart,
                wIcon = wIcon, wLabel = wLabel, wTag = wTag,
                totalW = wIcon + wLabel + wTag,
                cIcon = colIcon or u32Cyan,
                cLabel = colLabel or u32White,
                cTag = colTag or u32Cyan,
            })
        end

        -- Title row
        local fac = getFaction()
        addRow(nil, fa.ICON_FA_SHIELD_ALT .. " " .. fac .. " ASSIST V1.0 " .. fa.ICON_FA_SHIELD_ALT, nil, PDX.lc.hudTitle, PDX.lc.hudTitle, PDX.lc.hudTitle)

        -- Randurile cu taste (implicite + custom): fiecare are un ID, afisate in ordinea din /pdc -> Taste & HUD
        local B = {}
        B.menuKeyOn = function()
            if cfg.settings.menuKeyOn == 1 and PDX.hudRowOn("menuKeyOn") then
                local kLbl = (PDX.getActionLabel(tostring(cfg.settings.kAction)):gsub("%s*%(.-%)", "")):upper()
                addRow(fa.ICON_FA_GAVEL, kLbl .. " ", "[" .. tostring(cfg.settings.nMenuKey) .. "]", u32Cyan, u32White, u32Gold)
            end
        end
        B.lKeyOn = function()
            if cfg.settings.lKeyOn == 1 and PDX.hudRowOn("lKeyOn") then
                local lLbl = (PDX.getActionLabel(tostring(cfg.settings.lAction)):gsub("%s*%(.-%)", "")):upper()
                addRow(fa.ICON_FA_GAVEL, lLbl .. " ", "[" .. tostring(cfg.settings.nLKey) .. "]", u32Cyan, u32White, u32Gold)
            end
        end
        B.wheelOn = function()
            if cfg.settings.wheelOn == 1 and PDX.hudRowOn("wheelOn") then
                addRow(fa.ICON_FA_CAR, "ROATA INTERACT ", "[" .. tostring(cfg.settings.nWheelKey) .. "]", u32Cyan, u32White, u32Gold)
            end
        end
        B.somatie = function()
            if cfg.pd.somatie == 1 and PDX.hudRowOn("somatie") then
                addRow(fa.ICON_FA_BULLHORN, "SOMATIE (/MS) ", "[" .. tostring(cfg.pd.nTastaS) .. "]", u32Cyan, u32White, u32Cyan)
            end
        end
        B.radar = function()
            if isRutieraActive() and cfg.pd.radar == 1 and PDX.hudRowOn("radar") then
                local rStg = cfg.radar.stage
                local rCol = u32Cyan
                local rLabel = "RADAR "
                local rSuffix = "[" .. tostring(cfg.pd.nTastaR) .. "]"
                if rStg == 1 then
                    if state.inCar then
                        rCol = u32Green
                        rLabel = "RADAR ACTIV (" .. tostring(cfg.radar.limita) .. ") "
                        rSuffix = "[" .. tostring(cfg.pd.nTastaR) .. " | ON]"
                    else
                        rCol = u32Gold
                        rLabel = "RADAR (IESIT DIN AUTO) "
                        rSuffix = "[" .. tostring(cfg.pd.nTastaR) .. "]"
                    end
                elseif rStg == 2 then
                    rCol = u32Gold
                    rLabel = "RADAR PAUZA "
                    rSuffix = "[" .. tostring(cfg.pd.nTastaR) .. "]"
                end
                addRow(fa.ICON_FA_TACHOMETER_ALT, rLabel, rSuffix, rCol, u32White, rCol)
            end
        end
        B.cuffarrest = function()
            if cfg.pd.cuffarrest == 1 and PDX.hudRowOn("cuffarrest") then
                local hasArr = (cfg.pd.arrestid and cfg.pd.arrestid >= 0)
                local caTag = hasArr and ("[" .. tostring(cfg.pd.nTastaCA) .. " | ID:" .. cfg.pd.arrestid .. "]") or ("[" .. tostring(cfg.pd.nTastaCA) .. "]")
                addRow(fa.ICON_FA_LINK, "CUFF & ARREST ", caTag, hasArr and u32Gold or u32Cyan, u32White, hasArr and u32Gold or u32Cyan)
            end
        end
        B.frisk = function()
            if cfg.pd.frisk == 1 and PDX.hudRowOn("frisk") then
                addRow(fa.ICON_FA_SEARCH, "FRISK ", "[" .. tostring(cfg.pd.nTastaF) .. "]", u32Cyan, u32White, u32Cyan)
            end
        end
        B.tazer = function()
            if cfg.pd.tazer == 1 and PDX.hudRowOn("tazer") then
                addRow(fa.ICON_FA_BOLT, "TAZER ", "[" .. tostring(cfg.pd.nTastaT) .. "]", u32Cyan, u32White, u32Cyan)
            end
        end
        B.wanted = function()
            if cfg.pd.wanted == 1 and PDX.hudRowOn("wanted") then
                addRow(fa.ICON_FA_EXCLAMATION_TRIANGLE, "WANTED ", "[" .. tostring(cfg.pd.nTastaWA) .. "]", u32Cyan, u32White, u32Cyan)
            end
        end
        B.nearwanted = function()
            if cfg.pd.nearwanted == 1 and PDX.hudRowOn("nearwanted") then
                addRow(fa.ICON_FA_CROSSHAIRS, "NEARWANTED ", "[" .. tostring(cfg.pd.nTastaNWA) .. "]", u32Cyan, u32White, u32Cyan)
            end
        end
        B.repairon = function()
            if cfg.pd.repairon == 1 and PDX.hudRowOn("repairon") then
                addRow(fa.ICON_FA_WRENCH, "REPAIR ", "[" .. tostring(cfg.pd.nTastaRepair) .. "]", u32Cyan, u32White, u32Cyan)
            end
        end
        for i = 1, PDX.KBC_MAX do
            B["kbc" .. i] = function()
                if tonumber(cfg.kbc["on" .. i]) == 1 and tonumber(cfg.kbc["hud" .. i]) == 1 and (tonumber(cfg.kbc["key" .. i]) or 0) > 0 then
                    local lbl = tostring(cfg.kbc["label" .. i] or "")
                    if lbl == "" then lbl = "TASTA #" .. i end
                    addRow(PDX.kbcIcon(i), lbl:upper() .. " ", "[" .. tostring(cfg.kbc["kname" .. i]) .. "]", u32Cyan, u32White, u32Cyan)
                end
            end
        end
        for _, rowId in ipairs(PDX.getHudOrder()) do
            local f = B[rowId]
            if f then f() end
        end

        -- Suspect urmarit (/find)
        if PDX.find.active then
            local fTag = (PDX.find.id >= 0) and ("[" .. PDX.find.id .. "]") or "[?]"
            addRow(fa.ICON_FA_MAP_MARKER_ALT, "FIND: " .. u8(PDX.find.name) .. " ", fTag, u32Gold, u32White, u32Gold)
        end

        -- Live Countdown Timers
        if timers.mmEnd > now then
            local rem = timers.mmEnd - now
            addRow(fa.ICON_FA_BULLHORN, "SOMATIE /MM ", string.format("[%.1fs]", rem), u32Gold, u32White, u32Green)
        end
        if isRutieraActive() and timers.dEnd > now then
            local rem = timers.dEnd - now
            addRow(fa.ICON_FA_CLOCK, "ASTEPTARE /D ", string.format("[%.1fs]", rem), u32Gold, u32White, u32Green)
        end
        if timers.afkEnd > now then
            local rem = math.ceil(timers.afkEnd - now)
            local m = math.floor(rem / 60)
            local s = rem % 60
            addRow(fa.ICON_FA_USER_CLOCK, (timers.afkLabel ~= "" and timers.afkLabel or "TIMER AFK") .. " ", string.format("[%02d:%02d]", m, s), u32Red, u32White, u32Gold)
        end
        if timers.fvrActive and timers.fvrLeft > 0 then
            addRow(fa.ICON_FA_CAR, "FVR IN CURS ", string.format("[%ds]", timers.fvrLeft), u32Gold, u32White, u32Red)
        end

        -- Stil clasic PDHelper (are pozitia lui, editabila cu /hudpos si din /pdc)
        if tonumber(cfg.settings.hudStyle) == 1 then
            PDX.drawClassicHud(dl, font, sw, sh, rows)
            return
        end

        -- Compute bounding box
        local maxW = 190
        for i = 1, #rows do
            if rows[i].totalW > maxW then maxW = rows[i].totalW end
        end
        local totalH = #rows * lineH
        hudLastWidth  = maxW
        hudLastHeight = totalH

        local anchorRightX, topY
        if hudMoving then
            local mx, my = getCursorPos()
            anchorRightX = math.max(maxW + 12, math.min(sw - 6, mx + maxW * 0.5))
            topY         = math.max(12, math.min(sh - totalH - 12, my - totalH * 0.5))

            dl:AddRectFilled(
                imgui.ImVec2(anchorRightX - maxW - 10, topY - 6),
                imgui.ImVec2(anchorRightX + 6, topY + totalH + 6),
                0xAA0A1018, 8.0
            )
            dl:AddRect(
                imgui.ImVec2(anchorRightX - maxW - 10, topY - 6),
                imgui.ImVec2(anchorRightX + 6, topY + totalH + 6),
                u32Cyan, 8.0, 15, 1.5
            )
            local hint = PDX.tr("[CLICK STANGA] Fixeaza  |  [ESC] Anuleaza")
            local hw = font:CalcTextSizeA(fSize * 0.9, 10000, -1, hint).x
            drawOutlinedText(dl, font, fSize * 0.9, anchorRightX - maxW * 0.5 - hw * 0.5, topY - 22, u32Gold, hint)
        elseif cfg.settings.hud_custom and cfg.settings.hud_x > 0 and cfg.settings.hud_y > 0 then
            anchorRightX = math.max(maxW + 10, math.min(sw - 6, cfg.settings.hud_x))
            topY         = math.max(10, math.min(sh - totalH - 10, cfg.settings.hud_y))
        else
            anchorRightX = sw - 8
            topY         = math.floor(sh * 0.5 - totalH * 0.5)
        end

        local curY = topY
        for i = 1, #rows do
            local r = rows[i]
            local startX = anchorRightX - r.totalW
            if r.icon ~= "" then
                drawOutlinedText(dl, font, fSize, startX, curY, r.cIcon, r.icon)
            end
            if r.label ~= "" then
                drawOutlinedText(dl, font, fSize, startX + r.wIcon, curY, r.cLabel, r.label)
            end
            if r.tag ~= "" then
                drawOutlinedText(dl, font, fSize, startX + r.wIcon + r.wLabel, curY, r.cTag, r.tag)
            end
            curY = curY + lineH
            if i == 1 then curY = curY + 3 end
        end
    end
)
hudOverlay.HideCursor = true

-- 2. Personal Blacklist Pinned Overlay (/pdbl Save & Keep modernized)
-- /blpos (sau butonul din /pdbl) = muti lista cu mouse-ul; Gata / ENTER / click dreapta = salveaza pozitia
PDX.blMoving = false

function PDX.startBlMoving()
    closeAnimWin(blWin)
    closeAnimWin(mainWin)
    PDX.blMoving = true
    PDX.blMoveSetPos = true
    showCursor(true, true)
    msg("Trage lista {28AFE0}Personal Blacklist{FFFFFF} cu mouse-ul. Salvezi cu {28AFE0}ENTER{FFFFFF}, click dreapta sau butonul Gata.")
end

function PDX.stopBlMoving()
    if not PDX.blMoving then return end
    PDX.blMoving = false
    showCursor(false, false)
    saveCfg()
    addNotification("Pozitie blacklist salvata!", "saved")
end

local blPinnedSub = imgui.OnFrame(
    function()
        return (PDX.blMoving or ((cfg.blacklist.pinned == true) and (not blWin.visible)))
            and (not state.paused) and (not state.scoreboard)
    end,
    function(self)
        local moving = PDX.blMoving
        self.HideCursor = not moving
        local entries = {}
        for i = 1, 9 do
            local line = tostring(cfg.blacklist["bl" .. i] or "-"):gsub("^%s+", ""):gsub("%s+$", "")
            if line ~= "" and line ~= "-" then
                table.insert(entries, line)
            end
        end
        if #entries == 0 and not moving then return end

        local sw, sh = getScreenResCached()
        local bw = math.max(200, math.min(sw - 20, tonumber(cfg.blacklist.w) or 330))
        local px = math.max(0, math.min(sw - 60, tonumber(cfg.blacklist.posX) or 20))
        local py = math.max(0, math.min(sh - 40, tonumber(cfg.blacklist.posY) or 220))
        if not moving or PDX.blMoveSetPos then
            imgui.SetNextWindowPos(imgui.ImVec2(px, py), imgui.Cond.Always)
            PDX.blMoveSetPos = false
        end
        -- latimea o alegi tu (manerul din dreapta-jos la /blpos), inaltimea se potriveste singura dupa text
        imgui.SetNextWindowSize(imgui.ImVec2(bw, 0), imgui.Cond.Always)

        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 9.0)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(12, 10))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.05, 0.06, 0.09, 0.86))
        imgui.PushStyleColor(imgui.Col.Border, moving and imgui.ImVec4(0.16, 0.69, 0.88, 0.95) or imgui.ImVec4(0.82, 0.22, 0.25, 0.55))

        imgui.Begin("##PDPinnedBlacklist", nil,
            imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize +
            imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoSavedSettings +
            (moving and 0 or imgui.WindowFlags.NoInputs)
        )
        if moving then
            local p = imgui.GetWindowPos()
            cfg.blacklist.posX, cfg.blacklist.posY = math.floor(p.x), math.floor(p.y)
            imgui.TextColored(colors.accent, "%s", fa.ICON_FA_ARROWS_ALT .. " " .. PDX.tr("Trage fereastra unde vrei"))
            imgui.TextColored(colors.textMuted, "%s", PDX.tr("Latimea: trage de coltul din dreapta-jos"))
            if imgui.SmallButton(fa.ICON_FA_CHECK .. " Gata##blPosDone") then PDX.stopBlMoving() end
            imgui.SameLine()
            if imgui.SmallButton(fa.ICON_FA_UNDO .. " Reset##blPosReset") then
                cfg.blacklist.posX, cfg.blacklist.posY, cfg.blacklist.w = 20, 220, 330
                PDX.blMoveSetPos = true
            end
            if imgui.IsMouseClicked(1) or imgui.IsKeyPressed(vkeys.VK_RETURN) then PDX.stopBlMoving() end
        end
        imgui.TextColored(colors.redHover, fa.ICON_FA_USER_SLASH .. " PERSONAL BLACKLIST (/pdbl)")
        imgui.Separator()
        imgui.PushTextWrapPos(0) -- textul lung trece pe randul urmator, nu se mai taie
        if #entries == 0 then imgui.TextColored(colors.textMuted, "%s", PDX.tr("(lista e goala)")) end
        for idx, item in ipairs(entries) do
            -- Check if first token matches any connected player's nickname
            local firstWord = item:match("^(%S+)") or ""
            local foundId = nil
            if firstWord ~= "" then
                local targetLower = firstWord:lower()
                for pid = 0, 999 do
                    if sampIsPlayerConnected(pid) then
                        local pn = sampGetPlayerNickname(pid)
                        if pn and pn:lower():find(targetLower, 1, true) then
                            foundId = pid
                            break
                        end
                    end
                end
            end
            if foundId then
                imgui.TextColored(colors.green, "%s", string.format("[ON - ID %d]", foundId))
                imgui.SameLine()
                imgui.TextColored(colors.textPrimary, "%s", u8(item))
            else
                imgui.TextColored(colors.textMuted, "%s", string.format("%d. %s", idx, u8(item)))
            end
        end
        imgui.PopTextWrapPos()
        if moving then
            -- maner de latime (colt dreapta-jos)
            -- pus pe ultimul rand de text (nu mai jos), ca fereastra sa nu creasca singura
            local wp, ws = imgui.GetWindowPos(), imgui.GetWindowSize()
            local cur = imgui.GetCursorScreenPos()
            local g = 16
            local bx, by = wp.x + ws.x - g - 2, cur.y - g - 2
            imgui.SetCursorScreenPos(imgui.ImVec2(bx, by))
            imgui.InvisibleButton("##blResize", imgui.ImVec2(g, g))
            local hot = imgui.IsItemHovered() or imgui.IsItemActive()
            if imgui.IsItemActive() then
                cfg.blacklist.w = math.floor(math.max(200, math.min(sw - 20, bw + imgui.GetIO().MouseDelta.x)))
            end
            imgui.GetWindowDrawList():AddTriangleFilled(
                imgui.ImVec2(bx + g, by), imgui.ImVec2(bx + g, by + g), imgui.ImVec2(bx, by + g),
                hot and 0xFFE0AF28 or 0x99E0AF28)
        end
        imgui.End()
        imgui.PopStyleColor(2)
        imgui.PopStyleVar(2)
    end
)
blPinnedSub.HideCursor = true

-- =========================================================================================
--  CULORI PERSONALIZABILE (HUD + notificari) - sectiunea "Aspect" din /pdc
--  Salvate ca "#RRGGBB" in [look] (cu # ca inicfg sa nu le transforme in numere)
-- =========================================================================================
PDX.LOOK_DEFAULTS = {
    hudAccent  = "#28AFE0", -- HUD: etichete (clasic) / iconite + taste (modern)
    hudText    = "#FFFFFF", -- HUD: taste (clasic) / etichete (modern)
    hudIcon    = "#FFFFFF", -- HUD clasic: iconite
    hudTitle   = "#28AFE0", -- HUD: titlul (scut + ASSIST)
    notifBg    = "#0D1219", -- notificari: fundal card
    notifText  = "#F1F5F9", -- notificari: textul mesajului
    notifInfo  = "#28B0E0",
    notifRadar = "#FFB826",
    notifSanction = "#EB4747",
    notifSaved = "#24C773",
    notifTimer = "#9E6BFF",
    notifError = "#FF8A3D",
}
PDX.LOOK_NOTIF_KEYS = { info = "notifInfo", radar = "notifRadar", sanction = "notifSanction", saved = "notifSaved", timer = "notifTimer", error = "notifError" }
PDX.lc = {} -- culori calculate (u32 ABGR / float)

function PDX.hexToRGB(hex)
    hex = tostring(hex or ""):gsub("#", "")
    if not hex:match("^%x%x%x%x%x%x$") then return 1, 1, 1 end
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

function PDX.rgbToHex(r, g, b)
    local function c(v) return math.max(0, math.min(255, math.floor(v * 255 + 0.5))) end
    return string.format("#%02X%02X%02X", c(r), c(g), c(b))
end

function PDX.hexToU32(hex, a)
    local r, g, b = PDX.hexToRGB(hex)
    local A = math.floor((a or 1) * 255 + 0.5)
    return A * 16777216 + math.floor(b * 255 + 0.5) * 65536 + math.floor(g * 255 + 0.5) * 256 + math.floor(r * 255 + 0.5)
end

-- Marime HUD / notificari (pt ecrane mici sau mari), din /pdc -> General
function PDX.hudScale()
    return math.max(0.6, math.min(1.6, (tonumber(cfg.settings.hudScalePct) or 100) / 100))
end
function PDX.notifScale()
    return math.max(0.6, math.min(1.6, (tonumber(cfg.settings.notifScalePct) or 100) / 100))
end
function PDX.wheelScale()
    return math.max(0.6, math.min(1.6, (tonumber(cfg.settings.wheelScalePct) or 100) / 100))
end

-- Recalculeaza culorile din cfg.look (apelat la pornire si la fiecare modificare)
function PDX.applyLook()
    cfg.look = cfg.look or {}
    for k, v in pairs(PDX.LOOK_DEFAULTS) do
        if type(cfg.look[k]) ~= "string" or not cfg.look[k]:match("^#%x%x%x%x%x%x$") then cfg.look[k] = v end
    end
    cfg.look.notifAlpha = math.max(40, math.min(100, tonumber(cfg.look.notifAlpha) or 94))
    local L = PDX.lc
    L.hudAccent = PDX.hexToU32(cfg.look.hudAccent)
    L.hudText   = PDX.hexToU32(cfg.look.hudText)
    L.hudIcon   = PDX.hexToU32(cfg.look.hudIcon)
    L.hudTitle  = PDX.hexToU32(cfg.look.hudTitle)
    L.notifText = PDX.hexToU32(cfg.look.notifText)
    L.bgR, L.bgG, L.bgB = PDX.hexToRGB(cfg.look.notifBg)
    for typeKey, lookKey in pairs(PDX.LOOK_NOTIF_KEYS) do
        local t = notifTypes[typeKey]
        if t then t.r, t.g, t.b = PDX.hexToRGB(cfg.look[lookKey]) end
    end
end
PDX.applyLook()

-- Deseneaza un card de notificare (folosit de notificarile reale SI de preview-ul din /pdc)
function PDX.drawNotifCard(dl, x0, y0, scale, alpha, nc, text, prog)
    local font   = imgui.GetFont()
    local fBase  = imgui.GetFontSize()
    local addTxt = imgui.lib.ImDrawList_AddTextFontPtr
    local bw, bh = NOTIF_WIDTH * scale, NOTIF_HEIGHT * scale
    local x1, y1 = x0 + bw, y0 + bh
    local L      = PDX.lc
    local bgA    = (tonumber(cfg.look.notifAlpha) or 94) / 100
    local function acc(a) return imgui.ColorConvertFloat4ToU32(imgui.ImVec4(nc.r, nc.g, nc.b, a * alpha)) end

    -- umbra + card + contur in culoarea tipului
    dl:AddRectFilled(imgui.ImVec2(x0 + 2, y0 + 4), imgui.ImVec2(x1 + 2, y1 + 4), PDX.colA(0x66000000, alpha * bgA), 12 * scale)
    dl:AddRectFilled(imgui.ImVec2(x0, y0), imgui.ImVec2(x1, y1), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(L.bgR, L.bgG, L.bgB, bgA * alpha)), 12 * scale)
    dl:AddRect(imgui.ImVec2(x0, y0), imgui.ImVec2(x1, y1), acc(0.35), 12 * scale, 15, 1.2)

    -- insigna cu iconita (patrat rotunjit, stanga)
    local bs  = 38 * scale
    local bx0 = x0 + 12 * scale
    local by0 = y0 + (bh - bs) * 0.5
    dl:AddRectFilled(imgui.ImVec2(bx0, by0), imgui.ImVec2(bx0 + bs, by0 + bs), acc(0.18), 9 * scale)
    local icStr = nc.icon or ">"
    local fIc   = fBase * 1.25 * scale
    local icSz  = font:CalcTextSizeA(fIc, 10000, -1, icStr)
    addTxt(dl, font, fIc, imgui.ImVec2(bx0 + (bs - icSz.x) * 0.5, by0 + (bs - icSz.y) * 0.5), acc(1.0), icStr, nil, 0.0, nil)

    -- titlu (mic, colorat) + text
    local tx = bx0 + bs + 12 * scale
    addTxt(dl, font, fBase * 0.88 * scale, imgui.ImVec2(tx, y0 + 12 * scale), acc(1.0), PDX.tr(nc.title or "PD ASSIST"), nil, 0.0, nil)
    addTxt(dl, font, fBase * scale, imgui.ImVec2(tx, y0 + 30 * scale), PDX.colA(L.notifText, alpha), text or "", nil, 0.0, nil)

    -- bara de timp ramas (subtire, jos)
    prog = math.max(0.0, math.min(1.0, prog or 1))
    local px0, px1 = x0 + 12 * scale, x1 - 12 * scale
    local py = y1 - 5 * scale
    dl:AddRectFilled(imgui.ImVec2(px0, py), imgui.ImVec2(px1, py + 2 * scale), acc(0.15), 2)
    dl:AddRectFilled(imgui.ImVec2(px0, py), imgui.ImVec2(px0 + (px1 - px0) * prog, py + 2 * scale), acc(0.85), 2)
end

-- 4. Slide-In Toast Notifications Renderer (TaxiAssist Style)
-- Notificari: card desenat direct (fara ferestre), deasupra radarului (stanga-jos).
-- Apar pe loc cu un mic "pop" (fade + scale cu overshoot), dispar cu fade; cand una dispare, celelalte alunec lin la locul lor.
PDX.notifLastT = 0
local notifSub = imgui.OnFrame(
    function() return #notifications > 0 and not state.paused end,
    function(self)
        self.HideCursor = true
        local resX, resY = getScreenResCached()
        local now = os.clock()
        local dt  = math.min(0.05, math.max(0, now - (PDX.notifLastT or now)))
        PDX.notifLastT = now

        local dl     = imgui.GetBackgroundDrawList()
        local ns     = PDX.notifScale() -- marimea notificarilor din /pdc -> General
        local W, H   = NOTIF_WIDTH * ns, NOTIF_HEIGHT * ns
        local baseX  = math.floor(resX * 0.052)
        local bottom = math.floor(resY * 0.725)

        local POP_IN  = 0.22
        local FADE_OUT = 0.35

        local slot = 0 -- 0 = cea mai noua (jos, langa radar)
        local i = #notifications
        while i >= 1 do
            local n         = notifications[i]
            local elapsed   = now - n.startTime
            local remaining = n.duration - elapsed

            if remaining <= 0 then
                table.remove(notifications, i)
            else
                -- intrare: fade + scale 0.90 -> 1.00 cu putin overshoot (easeOutBack)
                local alpha, scale = 1.0, 1.0
                if elapsed < POP_IN then
                    local t  = elapsed / POP_IN
                    local c1 = 1.70158
                    local eb = 1 + (c1 + 1) * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
                    alpha = easeOutCubic(t)
                    scale = 0.90 + 0.10 * eb
                end
                -- iesire: doar fade (+ se strange foarte putin)
                if remaining < FADE_OUT then
                    local t = remaining / FADE_OUT
                    alpha = math.min(alpha, t)
                    scale = scale * (0.97 + 0.03 * t)
                end
                alpha = math.max(0.0, math.min(1.0, alpha))

                -- pozitie: tinta pe slot, iar y curent aluneca lin spre tinta
                local targetY = bottom - H - slot * (H + NOTIF_SPACING * ns)
                if not n.yCur then n.yCur = targetY end
                n.yCur = n.yCur + (targetY - n.yCur) * math.min(1, dt * 12)

                local x0   = baseX + (W - W * scale) * 0.5
                local y0   = n.yCur + (H - H * scale) * 0.5
                local prog = math.max(0.0, math.min(1.0, remaining / n.duration))
                PDX.drawNotifCard(dl, x0, y0, scale * ns, alpha, n.config or notifTypes.info, u8(PDX.tr(n.text)), prog)

                slot = slot + 1
            end
            i = i - 1
        end
    end
)
notifSub.HideCursor = true

-- =========================================================================================
--  SECTION 9: SHARED WINDOW HEADER HELPER (TaxiAssist Signature Style)
-- =========================================================================================
local function drawModernHeader(icon, titleMain, titleSub, closeFn, btnId)
    local dl      = imgui.GetWindowDrawList()
    local winPos  = imgui.GetWindowPos()
    local winSize = imgui.GetWindowSize()

    -- Top gradient glow bar
    dl:AddRectFilledMultiColor(
        winPos,
        imgui.ImVec2(winPos.x + winSize.x, winPos.y + 3),
        imgui.ColorConvertFloat4ToU32(colors.accent),
        imgui.ColorConvertFloat4ToU32(colors.royal),
        imgui.ColorConvertFloat4ToU32(colors.royal),
        imgui.ColorConvertFloat4ToU32(colors.accent)
    )

    -- Header backdrop tint
    local headerH = 42
    dl:AddRectFilledMultiColor(
        winPos,
        imgui.ImVec2(winPos.x + winSize.x, winPos.y + headerH),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(colors.accent.x, colors.accent.y, colors.accent.z, 0.16)),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(colors.royal.x, colors.royal.y, colors.royal.z, 0.04)),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0, 0, 0, 0)),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0, 0, 0, 0))
    )
    dl:AddLine(
        imgui.ImVec2(winPos.x, winPos.y + headerH),
        imgui.ImVec2(winPos.x + winSize.x, winPos.y + headerH),
        imgui.ColorConvertFloat4ToU32(colors.separator), 1.0
    )

    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
    imgui.SetCursorPosX(imgui.GetCursorPosX() + 6)
    imgui.TextColored(colors.accent, "%s", tostring(icon) .. "  " .. tostring(titleMain))
    imgui.SameLine()
    imgui.TextColored(colors.textDim, "%s", " |  " .. tostring(titleSub))

    local verTxt = PDX.verLabel(PDX.curVer())
    local availX = imgui.GetContentRegionAvail().x
    imgui.SameLine()
    imgui.SetCursorPosX(imgui.GetCursorPosX() + availX - imgui.CalcTextSize(verTxt).x - 42)
    imgui.TextColored(colors.textDim, verTxt)

    imgui.SameLine()
    imgui.SetCursorPosY(imgui.GetCursorPosY() - 2)
    PushButtonColors(colors.red, colors.redHover)
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6)
    imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(6, 3))
    if imgui.Button(fa.ICON_FA_TIMES .. "##" .. btnId, imgui.ImVec2(26, 22)) then
        closeFn()
    end
    imgui.PopStyleVar(2)
    imgui.PopStyleColor(3)
    imgui.Spacing()
    imgui.Spacing()
end

-- =========================================================================================
--  SECTION 9B: COMPONENTE UI NOI (sidebar, automatizari, keybinduri custom, cont & PIN, AFK pe ecran)
-- =========================================================================================
local function sectionTitle(icon, text)
    imgui.Spacing()
    imgui.TextColored(colors.accent, "%s", icon .. "  " .. text)
    imgui.Separator()
    imgui.Spacing()
end

function PDX.drawSidebar()
    local showRadarTab = isRutieraActive()
    if mainWin.tab == 6 and not showRadarTab then mainWin.tab = 1 end
    local tabs = { { 1, fa.ICON_FA_SLIDERS_H .. "  General" } }
    if showRadarTab then table.insert(tabs, { 6, fa.ICON_FA_TACHOMETER_ALT .. "  Radar" }) end
    table.insert(tabs, { 7, fa.ICON_FA_ROBOT .. "  Automatizari" })
    table.insert(tabs, { 2, fa.ICON_FA_KEYBOARD .. "  Taste & HUD" })
    table.insert(tabs, { 10, fa.ICON_FA_DHARMACHAKRA .. "  Roata" })
    table.insert(tabs, { 9, fa.ICON_FA_PALETTE .. "  Aspect" })
    table.insert(tabs, { 3, fa.ICON_FA_BULLHORN .. "  FVR & GOV" })
    table.insert(tabs, { 4, fa.ICON_FA_TERMINAL .. "  Comenzi Custom" })
    table.insert(tabs, { 8, fa.ICON_FA_USER_LOCK .. "  Cont & PIN" })
    table.insert(tabs, { 5, fa.ICON_FA_BOOK .. "  Ghid Comenzi" })

    imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.06, 0.08, 0.12, 0.96))
    imgui.BeginChild("##pdSidebar", imgui.ImVec2(190, -46), true)
    imgui.TextColored(colors.textDim, "MENIU")
    imgui.Spacing()
    imgui.PushStyleVarVec2(imgui.StyleVar.ButtonTextAlign, imgui.ImVec2(0.08, 0.5))
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 8)
    for _, tb in ipairs(tabs) do
        local active = (mainWin.tab == tb[1])
        if active then
            PushButtonColors(colors.accent, colors.accentHover, colors.accentActive)
            imgui.PushStyleColor(imgui.Col.Text, colors.dark)
        else
            PushButtonColors(imgui.ImVec4(0, 0, 0, 0), colors.cardHover, colors.cardActive)
            imgui.PushStyleColor(imgui.Col.Text, colors.textPrimary)
        end
        if imgui.Button(tb[2] .. "##navtab" .. tb[1], imgui.ImVec2(-1, 34)) then
            mainWin.tab = tb[1]
        end
        imgui.PopStyleColor(4)
    end
    imgui.PopStyleVar(2)

    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()
    imgui.TextColored(colors.textDim, "STATUS")
    imgui.TextColored(colors.accent, "%s", getFaction() .. (isPdFaction() and (" | " .. tostring(cfg.settings.pdTeam)) or ""))
    imgui.TextColored(colors.textMuted, "/find:")
    imgui.SameLine()
    if PDX.find.active then
        imgui.TextColored(colors.gold, "%s", u8(string.format("%s (%d)", PDX.find.name, PDX.find.id)))
    else
        imgui.TextDisabled("niciuna")
    end
    if timers.afkEnd > os.clock() and timers.afkLabel ~= "" then
        local rem = math.ceil(timers.afkEnd - os.clock())
        imgui.TextColored(colors.orange, "%s", u8(string.format("%s %d:%02d", timers.afkLabel, math.floor(rem / 60), rem % 60)))
    end
    imgui.EndChild()
    imgui.PopStyleColor()
end

function PDX.drawAutomationExtras()
    sectionTitle(fa.ICON_FA_MAP_MARKER_ALT, "URMARIRE (/find), AFK & SOMATIE")

    local cbF = new.bool(tonumber(cfg.auto.findTrack) == 1)
    if imgui.Checkbox("Anulare automata /find (suspect arestat / omorat / deconectat / /clear)", cbF) then
        cfg.auto.findTrack = cbF[0] and 1 or 0; saveCfg()
        addNotification("Anulare automata /find " .. (cbF[0] and "activata" or "dezactivata"), "saved")
    end
    Tooltip("Citeste mesajele HQ. Cand apare numele suspectului tau cu arestat/omorat/deconectat/cazier etc., scrie motivul in chat si da /cancel find.")

    imgui.Text("Urmarire curenta:")
    imgui.SameLine()
    if PDX.find.active then
        imgui.TextColored(colors.gold, "%s", u8(string.format("%s (ID %d)", PDX.find.name, PDX.find.id)))
        imgui.SameLine()
        PushButtonColors(colors.red, colors.redHover)
        if imgui.Button("Anuleaza##cfNow", imgui.ImVec2(90, 22)) then say("/cancel find") end
        imgui.PopStyleColor(3)
    else
        imgui.TextDisabled("niciuna")
    end
    imgui.TextDisabled("/afk = AFK cu clepsidra (3 min)  |  /ffk = fara clepsidra (30s)  |  fara ID = suspectul de pe /find")
    imgui.TextDisabled("/afk sau /ffk din nou = 'a revenit din afk'  |  dupa kill anunta singur pe /d ca nu a revenit")
    imgui.TextDisabled("/ms <id> = daca nu ai /find pe el, ii da intai /find, apoi /ms")

    sectionTitle(fa.ICON_FA_HOME, "SPAWN RAPID")
    imgui.TextColored(colors.accent, "/scasa  /slspd  /slvpd  /ssfpd  /sfbi  /hqng  /hqf  /sjail  /sclan  /sbunker")
    imgui.TextDisabled("Da /spawnchange si alege singur randul potrivit (dupa text, nu dupa pozitie).")
end

function PDX.drawCustomKeybinds()
    if not PDX.kbcBuf then
        PDX.kbcBuf = {}
        for i = 1, PDX.KBC_MAX do
            PDX.kbcBuf[i] = { label = new.char[33](), text = new.char[256]() }
            safeCopyBuf(PDX.kbcBuf[i].label, tostring(cfg.kbc["label" .. i] or ""))
            safeCopyBuf(PDX.kbcBuf[i].text, tostring(cfg.kbc["text" .. i] or ""))
        end
    end

    sectionTitle(fa.ICON_FA_KEYBOARD, "KEYBINDURI PERSONALIZATE: TASTA -> TEXT / COMENZI")
    imgui.TextDisabled("Acelasi format ca la Comenzi Custom: variabile (<Find>, <Apropiat>, <Eu>...) si ' | ' pt mai multe comenzi.")
    imgui.TextDisabled("Daca textul cere <Nume>/<ID>, se foloseste suspectul de pe /find.")
    imgui.Spacing()

    for i = 1, PDX.KBC_MAX do
        local b = PDX.kbcBuf[i]
        local cbOn = new.bool(tonumber(cfg.kbc["on" .. i]) == 1)
        if imgui.Checkbox("##kbcOn" .. i, cbOn) then
            cfg.kbc["on" .. i] = cbOn[0] and 1 or 0; saveCfg()
        end
        imgui.SameLine(0, 6)
        imgui.TextColored(colors.textMuted, "%s", string.format("#%02d", i))

        -- iconita din HUD: click = alegi din lista
        imgui.SameLine()
        PushButtonColors(colors.cardBg, colors.cardHover)
        imgui.PushStyleColor(imgui.Col.Text, colors.accent)
        if imgui.Button(PDX.kbcIcon(i) .. "##kbcIco" .. i, imgui.ImVec2(30, 26)) then imgui.OpenPopup("##kbcIcoPop" .. i) end
        imgui.PopStyleColor(4)
        if imgui.IsItemHovered() then imgui.SetTooltip("%s", "Iconita in HUD (click = schimba)") end
        if imgui.BeginPopup("##kbcIcoPop" .. i) then
            imgui.TextColored(colors.gold, "%s", "Alege iconita pentru HUD:")
            imgui.Separator()
            local col = 0
            for _, name in ipairs(PDX.KBC_ICONS) do
                local glyph = fa["ICON_FA_" .. name]
                if glyph then
                    if col > 0 then imgui.SameLine() end
                    local sel = (tostring(cfg.kbc["icon" .. i]) == name)
                    if sel then
                        PushButtonColors(colors.accent, colors.accentHover)
                        imgui.PushStyleColor(imgui.Col.Text, colors.dark)
                    else
                        PushButtonColors(colors.cardBg, colors.cardHover)
                        imgui.PushStyleColor(imgui.Col.Text, colors.textPrimary)
                    end
                    if imgui.Button(glyph .. "##ico_" .. i .. "_" .. name, imgui.ImVec2(32, 30)) then
                        cfg.kbc["icon" .. i] = name
                        saveCfg()
                        imgui.CloseCurrentPopup()
                    end
                    imgui.PopStyleColor(4)
                    col = (col + 1) % 10
                end
            end
            imgui.EndPopup()
        end

        imgui.SameLine()
        imgui.PushItemWidth(110)
        if imgui.InputTextWithHint("##kbcLbl" .. i, "Nume in HUD", b.label, ffi.sizeof(b.label)) then
            cfg.kbc["label" .. i] = ffi.string(b.label)
        end
        if imgui.IsItemDeactivatedAfterEdit() then saveCfg() end
        imgui.PopItemWidth()

        imgui.SameLine()
        local keyId = "key" .. i
        local isCap = (capturingBind ~= nil and capturingBind.section == "kbc" and capturingBind.keyId == keyId)
        if isCap then
            PushButtonColors(colors.orange, colors.goldHover)
            imgui.PushStyleColor(imgui.Col.Text, colors.dark)
        else
            PushButtonColors(colors.cardBg, colors.cardHover)
            imgui.PushStyleColor(imgui.Col.Text, colors.accent)
        end
        local keyTxt = isCap and "[ APASA... ]" or ("[" .. tostring(cfg.kbc["kname" .. i]) .. "]")
        if imgui.Button(keyTxt .. "##kbcKey" .. i, imgui.ImVec2(95, 26)) then
            capturingBind = (not isCap) and { section = "kbc", keyId = keyId, keyName = "kname" .. i, label = "Keybind #" .. i } or nil
        end
        imgui.PopStyleColor(4)

        imgui.SameLine()
        imgui.PushItemWidth(-140)
        if imgui.InputTextWithHint("##kbcTxt" .. i, "Ex: /r Am nevoie de ajutor langa <Apropiat> | /ms", b.text, ffi.sizeof(b.text)) then
            cfg.kbc["text" .. i] = ffi.string(b.text)
        end
        if imgui.IsItemDeactivatedAfterEdit() then saveCfg() end
        imgui.PopItemWidth()

        imgui.SameLine()
        PushButtonColors(colors.accent, colors.accentHover)
        imgui.PushStyleColor(imgui.Col.Text, colors.dark)
        if imgui.Button("+##kbcAdd" .. i, imgui.ImVec2(26, 26)) then imgui.OpenPopup("##kbcPop" .. i) end
        imgui.PopStyleColor(4)
        if imgui.BeginPopup("##kbcPop" .. i) then
            local before = ffi.string(b.text)
            PDX.drawVarPicker("k" .. i, b.text)
            if ffi.string(b.text) ~= before then
                cfg.kbc["text" .. i] = ffi.string(b.text); saveCfg()
            end
            imgui.EndPopup()
        end

        imgui.SameLine()
        local cbHud = new.bool(tonumber(cfg.kbc["hud" .. i]) == 1)
        if imgui.Checkbox("HUD##kbcHud" .. i, cbHud) then
            cfg.kbc["hud" .. i] = cbHud[0] and 1 or 0; saveCfg()
        end

        imgui.SameLine()
        PushButtonColors(colors.red, colors.redHover)
        if imgui.Button("X##kbcClr" .. i, imgui.ImVec2(26, 26)) then
            cfg.kbc["on" .. i], cfg.kbc["key" .. i], cfg.kbc["kname" .. i], cfg.kbc["icon" .. i] = 0, 0, "-", "KEYBOARD"
            cfg.kbc["label" .. i], cfg.kbc["text" .. i] = "", ""
            safeCopyBuf(b.label, ""); safeCopyBuf(b.text, "")
            saveCfg()
        end
        imgui.PopStyleColor(3)
    end

    imgui.Spacing()
    PushButtonColors(colors.green, colors.greenHover)
    if imgui.Button(fa.ICON_FA_PLUS .. " Adauga keybind custom##addKbcSlot", imgui.ImVec2(230, 28)) then
        PDX.addKbcSlot()
    end
    imgui.PopStyleColor(3)
    imgui.SameLine()
    imgui.TextDisabled("%s", string.format("%d / 50 sloturi", PDX.KBC_MAX))
end

-- =========================================================================================
--  ROATA PERSONALIZATA: elemente proprii in roata (pe jos / in masina), cu submeniuri si comenzi
--  Element = { label, icon, cmd (text/comenzi cu variabile, ' | ' = mai multe), player (cere jucator -> <ID>/<Nume>),
--              click (nu se executa la eliberarea tastei, doar cu click), children (submeniu) }
--  Salvat in moonloader\config\PDAssist_wheel.txt (structura cu submeniuri nu incape bine in .ini)
-- =========================================================================================
PDX.CW_MAX_ITEMS = 8   -- elemente pe nivel (sa ramana lizibila roata)
PDX.CW_MAX_DEPTH = 3   -- niveluri: element -> submeniu -> submeniu
PDX.cw      = { foot = {}, car = {} }
PDX.cwMode  = "foot"
PDX.cwSaveAt = nil

function PDX.cwPath()
    return getWorkingDirectory() .. "\\config\\PDAssist_wheel.txt"
end

-- ID stabil pt fiecare element propriu (folosit la ordinea / ascunderea pe roata)
PDX.cwUidN = 0
function PDX.cwNewUid()
    PDX.cwUidN = PDX.cwUidN + 1
    return string.format("c%x%x%x", os.time() % 1048576, math.random(0, 4095), PDX.cwUidN)
end

-- curata ce se incarca din fisier (tipuri sigure, limite)
local function cwSanitize(list, depth)
    local out = {}
    if type(list) ~= "table" then return out end
    for _, n in ipairs(list) do
        if type(n) == "table" and #out < PDX.CW_MAX_ITEMS then
            local node = {
                uid    = (type(n.uid) == "string" and n.uid:match("^%w+$")) and n.uid or (function() PDX.cwUidsGenerated = true; return PDX.cwNewUid() end)(),
                label  = tostring(n.label or ""):sub(1, 40),
                icon   = tostring(n.icon or "STAR"),
                cmd    = tostring(n.cmd or ""):sub(1, 255),
                player = n.player == true,
                click  = n.click == true,
            }
            if type(n.children) == "table" and depth < PDX.CW_MAX_DEPTH then
                node.children = cwSanitize(n.children, depth + 1)
            end
            out[#out + 1] = node
        end
    end
    return out
end

local function cwSer(list, ind)
    local out = { "{\n" }
    for _, n in ipairs(list) do
        out[#out + 1] = string.format("%s  { uid = %q, label = %q, icon = %q, cmd = %q, player = %s, click = %s",
            ind, tostring(n.uid or PDX.cwNewUid()), tostring(n.label or ""), tostring(n.icon or "STAR"), tostring(n.cmd or ""),
            n.player and "true" or "false", n.click and "true" or "false")
        if n.children then out[#out + 1] = ",\n" .. ind .. "    children = " .. cwSer(n.children, ind .. "    ") end
        out[#out + 1] = " },\n"
    end
    out[#out + 1] = ind .. "}"
    return table.concat(out)
end

function PDX.cwLoad()
    local f = io.open(PDX.cwPath(), "rb")
    if not f then return end
    local src = f:read("*a")
    f:close()
    local fn = loadstring(src)
    if not fn then return end
    setfenv(fn, {}) -- fisier de date: fara acces la nimic
    local ok, data = pcall(fn)
    if ok and type(data) == "table" then
        PDX.cwUidsGenerated = false
        PDX.cw.foot = cwSanitize(data.foot, 1)
        PDX.cw.car  = cwSanitize(data.car, 1)
        if PDX.cwUidsGenerated then PDX.cwSave() end -- ID-uri noi: le salvam ca ordinea sa ramana stabila
    end
end

function PDX.cwSave()
    PDX.cwSaveAt = nil
    local f = io.open(PDX.cwPath(), "wb")
    if not f then return end
    f:write("-- PDAssist: roata personalizata (generat automat din /pdc -> Roata)\n")
    f:write("return {\nfoot = " .. cwSer(PDX.cw.foot, "") .. ",\ncar = " .. cwSer(PDX.cw.car, "") .. "\n}\n")
    f:close()
end

function PDX.cwMarkDirty() PDX.cwSaveAt = os.clock() + 0.8 end

-- Numele zonei in care esti (ex: "Idlewood"), pt variabila <Zona>
function PDX.zoneName()
    local ok, name = pcall(function()
        local x, y, z = getCharCoordinates(PLAYER_PED)
        return getGxtText(getNameOfInfoZone(x, y, z))
    end)
    if ok and type(name) == "string" and name ~= "" then return name end
    return "zona necunoscuta"
end

PDX.cwLoad()

-- ---------- Din date -> felii de roata ----------
function PDX.cwRun(node, arg)
    if (node.cmd or "") ~= "" then
        PDX.runTemplate(node.cmd, arg or "", "roata: " .. tostring(node.label))
    end
end

function PDX.cwPlayers(node)
    local w = PDX.wheel
    local r = tonumber(cfg.settings.wheelRadius) or 5
    if not w.pCache or (os.clock() - w.pCacheT) > 0.25 then
        w.pCache, w.pCacheT = PDX.collectNearbyPlayers(r), os.clock()
    end
    local items = {}
    for _, t in ipairs(w.pCache) do
        local pid = t.id
        items[#items + 1] = {
            label = string.format("%s (%d)", t.name, pid), label2 = string.format("%.1f m", t.dist),
            col = PDX.argbToU32(t.color), noRelease = node.click,
            run = function() PDX.cwRun(node, tostring(pid)) end,
        }
    end
    return {
        title = tostring(node.label) .. " - ALEGE JUCATOR",
        hint  = (#items == 0) and string.format("Niciun jucator pe %d m", r) or "Click dreapta: inapoi",
        items = items,
    }
end

function PDX.cwItem(node)
    local icon = fa["ICON_FA_" .. tostring(node.icon or "STAR")] or fa.ICON_FA_STAR
    if node.children then
        return { icon = icon, label = node.label, sub = function() return PDX.cwLevel(node) end }
    elseif node.player then
        return { icon = icon, label = node.label, sub = function() return PDX.cwPlayers(node) end }
    end
    return { icon = icon, label = node.label, noRelease = node.click, run = function() PDX.cwRun(node, "") end }
end

function PDX.cwLevel(node)
    local items = {}
    for _, c in ipairs(node.children or {}) do
        if (c.label or "") ~= "" then
            local it = PDX.cwItem(c)
            it.wid = "u:" .. tostring(c.uid)
            items[#items + 1] = it
        end
    end
    items = PDX.wApply(items, "cw_" .. tostring(node.uid)) -- ordinea / ascunderea din /pdc -> Roata
    return { title = tostring(node.label), hint = (#items == 0) and "Submeniu gol" or "Click dreapta: inapoi", items = items }
end

-- adauga elementele proprii la nivelul de baza al roții
function PDX.cwAppendRoot(items, mode)
    for _, n in ipairs(PDX.cw[mode] or {}) do
        if (n.label or "") ~= "" then
            local it = PDX.cwItem(n)
            it.wid = "u:" .. tostring(n.uid)
            items[#items + 1] = it
        end
    end
end

-- ---------- Ordine + afisare pe roata (implicite + proprii), pe nivel: foot / car / player ----------
-- In cfg.wheel: order_<nivel> = "id1,id2,..." ; hide_<nivel> = "id,..." (ascunse)
-- { id, iconita, nume, submeniu (nivelul in care intri, optional) }
PDX.W_DEFAULTS = {
    foot = {
        { "interact",   "USERS",                "INTERACT", "player" },
        { "cancelfind", "TIMES_CIRCLE",         "CANCEL FIND" },
        { "wanted",     "EXCLAMATION_TRIANGLE", "WANTED" },
        { "spawn",      "HOME",                 "SPAWN", "spawn" },
        { "shield",     "SHIELD_ALT",           "SHIELD" },
        { "duty",       "USER_SHIELD",          "DUTY (doar in interior)", "duty" },
    },
    car = {
        { "eject",  "SIGN_OUT_ALT", "EJECT" },
        { "cuff",   "LINK",         "CUFF" },
        { "uncuff", "UNLINK",       "UNCUFF" },
        { "repair", "WRENCH",       "REPAIR" },
    },
    player = {
        { "punish",    "HAND_PAPER", "PUNISH (doar in Jail)" },
        { "frisk",     "SEARCH",     "FRISK" },
        { "uncuff",    "UNLINK",     "UNCUFF (doar pe cel incatusat de tine)" },
        { "cuff",      "LINK",       "CUFF (doar in Jail)" },
        { "confisca",  "BOX_OPEN",   "CONFISCA", "confisca" },
        { "wantedsu",  "STAR",       "WANTED", "wanted" },
        { "sanctiuni", "GAVEL",      "SANCTIUNI" },
        { "licente",   "ID_CARD",    "LICENTE (doar LSPD/LVPD/SFPD)" },
    },
    spawn = {
        { "scasa", "HOME", "CASA" }, { "slspd", "BUILDING", "LSPD" }, { "slvpd", "BUILDING", "LVPD" },
        { "ssfpd", "BUILDING", "SFPD" }, { "sfbi", "USER_SECRET", "FBI" }, { "hqng", "SHIELD_ALT", "GARAJ NG" },
        { "hqf", "FLAG", "HQ FACTIUNE" }, { "sjail", "LOCK", "JAIL" }, { "sclan", "USERS", "HQ CLAN" }, { "sbunker", "DOOR_OPEN", "BUNKER" },
    },
    duty = {
        { "duty", "USER_SHIELD", "DUTY" }, { "dutyheal", "PLUS", "DUTY + HEAL" }, { "heal", "HEART", "HEAL" },
    },
    confisca = {
        { "arme", "CROSSHAIRS", "ARME" }, { "droguri", "CANNABIS", "DROGURI" }, { "bombe", "BOMB", "BOMBE" }, { "materiale", "CUBES", "MATERIALE" },
    },
    wanted = {
        { "w2", "HAND_PAPER", "NECONFORMARE" }, { "w6", "FIST_RAISED", "ATACARE POLITIST" }, { "w12", "RUNNING", "FUGAR" },
        { "w13", "USER_FRIENDS", "COMPLICE" }, { "w1", "PHONE_SLASH", "NEFONDAT" }, { "w3", "LANDMARK", "PATRUNDERE TEREN" },
    },
}
PDX.W_LEVEL_NAMES = {
    foot = "Pe jos", car = "In masina", player = "Meniu jucator", spawn = "Spawn", duty = "Duty", confisca = "Confisca", wanted = "Wanted",
}

-- elementul tau cu ID-ul dat (cautat si in submeniuri)
function PDX.cwFindByUid(uid, list)
    for _, n in ipairs(list or {}) do
        if tostring(n.uid) == uid then return n end
        local f = n.children and PDX.cwFindByUid(uid, n.children)
        if f then return f end
    end
    return nil
end

function PDX.wLevelName(level)
    local uid = level:match("^cw_(.+)$")
    if uid then
        local n = PDX.cwFindByUid(uid, PDX.cw.foot) or PDX.cwFindByUid(uid, PDX.cw.car)
        return n and ((n.label ~= "" and n.label) or "(fara nume)") or "?"
    end
    return PDX.W_LEVEL_NAMES[level] or level
end

-- toate feliile unui nivel, in ordinea naturala: { wid, icon, label, sub } (implicite + ale tale)
function PDX.wLevelItems(level)
    local items = {}
    for _, d in ipairs(PDX.W_DEFAULTS[level] or {}) do
        items[#items + 1] = { wid = d[1], icon = fa["ICON_FA_" .. d[2]] or "", label = d[3], sub = d[4] }
    end
    local list
    if level == "foot" or level == "car" then
        list = PDX.cw[level]
    else
        local uid = level:match("^cw_(.+)$")
        local node = uid and (PDX.cwFindByUid(uid, PDX.cw.foot) or PDX.cwFindByUid(uid, PDX.cw.car))
        list = node and node.children
    end
    for _, n in ipairs(list or {}) do
        if (n.label or "") ~= "" then
            items[#items + 1] = {
                wid = "u:" .. tostring(n.uid), icon = fa["ICON_FA_" .. tostring(n.icon)] or fa.ICON_FA_STAR,
                label = n.label, own = true, sub = n.children and ("cw_" .. tostring(n.uid)) or nil,
            }
        end
    end
    return items
end

function PDX.wIsHidden(level, id)
    local raw = "," .. tostring((cfg.wheel and cfg.wheel["hide_" .. level]) or "") .. ","
    return raw:find("," .. id .. ",", 1, true) ~= nil
end

function PDX.wSetHidden(level, id, hidden)
    local set, out = {}, {}
    for x in tostring(cfg.wheel["hide_" .. level] or ""):gmatch("[^,]+") do set[x] = true end
    set[id] = hidden or nil
    for x in pairs(set) do out[#out + 1] = x end
    cfg.wheel["hide_" .. level] = table.concat(out, ",")
    saveCfg()
end

-- ordinea completa pt nivel: ce e salvat (doar ID-uri existente) + restul in ordinea naturala
function PDX.wOrder(level, allIds)
    local present = {}
    for _, id in ipairs(allIds) do present[id] = true end
    local list, seen = {}, {}
    for id in tostring((cfg.wheel and cfg.wheel["order_" .. level]) or ""):gmatch("[^,]+") do
        if present[id] and not seen[id] then list[#list + 1] = id; seen[id] = true end
    end
    for _, id in ipairs(allIds) do
        if not seen[id] then list[#list + 1] = id end
    end
    return list
end

-- aplica ordinea + ascunderea pe feliile construite (cele fara wid raman la final)
function PDX.wApply(items, level)
    local byId, natural, out = {}, {}, {}
    for _, it in ipairs(items) do
        if it.wid then byId[it.wid] = it; natural[#natural + 1] = it.wid end
    end
    for _, id in ipairs(PDX.wOrder(level, natural)) do
        if not PDX.wIsHidden(level, id) then out[#out + 1] = byId[id] end
    end
    for _, it in ipairs(items) do
        if not it.wid then out[#out + 1] = it end
    end
    return out
end

-- ---------- Editorul din /pdc -> Roata ----------
local function cwIconPicker(popupId, node)
    if imgui.BeginPopup(popupId) then
        imgui.TextColored(colors.gold, "%s", "Alege iconita:")
        imgui.Separator()
        local col = 0
        for _, name in ipairs(PDX.KBC_ICONS) do
            local glyph = fa["ICON_FA_" .. name]
            if glyph then
                if col > 0 then imgui.SameLine() end
                local sel = (node.icon == name)
                if sel then
                    PushButtonColors(colors.accent, colors.accentHover)
                    imgui.PushStyleColor(imgui.Col.Text, colors.dark)
                else
                    PushButtonColors(colors.cardBg, colors.cardHover)
                    imgui.PushStyleColor(imgui.Col.Text, colors.textPrimary)
                end
                if imgui.Button(glyph .. "##" .. popupId .. name, imgui.ImVec2(32, 30)) then
                    node.icon = name
                    PDX.cwMarkDirty()
                    imgui.CloseCurrentPopup()
                end
                imgui.PopStyleColor(4)
                col = (col + 1) % 10
            end
        end
        imgui.EndPopup()
    end
end

local function cwDrawList(list, depth, path)
    local action -- { "up"/"down"/"del", index }
    for i, node in ipairs(list) do
        local pid = path .. "_" .. i
        if not node._lb then
            node._lb = new.char[41](); safeCopyBuf(node._lb, node.label or "")
            node._cb = new.char[256](); safeCopyBuf(node._cb, node.cmd or "")
        end
        if depth > 0 then imgui.Indent(28) end

        -- rand 1: iconita | nume | submeniu? | sus / jos / sterge
        PushButtonColors(colors.cardBg, colors.cardHover)
        imgui.PushStyleColor(imgui.Col.Text, colors.accent)
        if imgui.Button((fa["ICON_FA_" .. tostring(node.icon)] or fa.ICON_FA_STAR) .. "##cwIco" .. pid, imgui.ImVec2(30, 26)) then
            imgui.OpenPopup("##cwIcoPop" .. pid)
        end
        imgui.PopStyleColor(4)
        cwIconPicker("##cwIcoPop" .. pid, node)
        imgui.SameLine()
        imgui.PushItemWidth(170)
        if imgui.InputTextWithHint("##cwLbl" .. pid, "Nume pe roata", node._lb, ffi.sizeof(node._lb)) then
            node.label = ffi.string(node._lb); PDX.cwMarkDirty()
        end
        imgui.PopItemWidth()
        imgui.SameLine()
        local isSub = new.bool(node.children ~= nil)
        if depth + 1 < PDX.CW_MAX_DEPTH then
            if imgui.Checkbox("Submeniu##cwSub" .. pid, isSub) then
                node.children = isSub[0] and (node.children or {}) or nil
                PDX.cwMarkDirty()
            end
            imgui.SameLine()
        end
        PushButtonColors(colors.cardBg, colors.cardHover)
        if imgui.Button(fa.ICON_FA_ARROW_UP .. "##cwUp" .. pid, imgui.ImVec2(26, 26)) then action = { "up", i } end
        imgui.SameLine(0, 4)
        if imgui.Button(fa.ICON_FA_ARROW_DOWN .. "##cwDn" .. pid, imgui.ImVec2(26, 26)) then action = { "down", i } end
        imgui.PopStyleColor(3)
        imgui.SameLine(0, 4)
        PushButtonColors(colors.red, colors.redHover)
        if imgui.Button("X##cwDel" .. pid, imgui.ImVec2(26, 26)) then action = { "del", i } end
        imgui.PopStyleColor(3)

        if node.children then
            -- submeniu: elementele lui, indentate
            cwDrawList(node.children, depth + 1, pid)
            imgui.Indent(28)
            if #node.children < PDX.CW_MAX_ITEMS then
                PushButtonColors(colors.green, colors.greenHover)
                if imgui.Button(fa.ICON_FA_PLUS .. " Adauga in " .. ((node.label ~= "" and node.label) or "submeniu") .. "##cwAddIn" .. pid, imgui.ImVec2(0, 24)) then
                    node.children[#node.children + 1] = { uid = PDX.cwNewUid(), label = "", icon = "STAR", cmd = "", player = false, click = false }
                    PDX.cwMarkDirty()
                end
                imgui.PopStyleColor(3)
            end
            imgui.Unindent(28)
        else
            -- rand 2: comanda / text (+ variabile) | cere jucator | doar click
            imgui.Indent(34)
            imgui.PushItemWidth(-250)
            if imgui.InputTextWithHint("##cwCmd" .. pid, "Ex: /r Backup la <Zona> | /ms   sau   /frisk <ID>", node._cb, ffi.sizeof(node._cb)) then
                node.cmd = ffi.string(node._cb); PDX.cwMarkDirty()
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            PushButtonColors(colors.accent, colors.accentHover)
            imgui.PushStyleColor(imgui.Col.Text, colors.dark)
            if imgui.Button("+##cwVar" .. pid, imgui.ImVec2(26, 26)) then imgui.OpenPopup("##cwVarPop" .. pid) end
            imgui.PopStyleColor(4)
            if imgui.BeginPopup("##cwVarPop" .. pid) then
                local before = ffi.string(node._cb)
                PDX.drawVarPicker("cw" .. pid, node._cb)
                if ffi.string(node._cb) ~= before then node.cmd = ffi.string(node._cb); PDX.cwMarkDirty() end
                imgui.EndPopup()
            end
            imgui.SameLine()
            local cbP = new.bool(node.player == true)
            if imgui.Checkbox("Alege jucator##cwPl" .. pid, cbP) then node.player = cbP[0]; PDX.cwMarkDirty() end
            if imgui.IsItemHovered() then imgui.SetTooltip("%s", "Inainte sa execute, roata iti arata jucatorii din jur. <ID>, <Nume>, <Nume (ID)> = jucatorul ales.") end
            imgui.SameLine()
            local cbC = new.bool(node.click == true)
            if imgui.Checkbox("Doar click##cwCl" .. pid, cbC) then node.click = cbC[0]; PDX.cwMarkDirty() end
            if imgui.IsItemHovered() then imgui.SetTooltip("%s", "Nu se executa cand eliberezi tasta (Hold) - trebuie click stanga. Bun pt actiuni periculoase.") end
            imgui.Unindent(34)
        end
        if depth > 0 then imgui.Unindent(28) end
        imgui.Spacing()
    end

    if action then
        local i = action[2]
        if action[1] == "del" then
            table.remove(list, i)
        elseif action[1] == "up" and i > 1 then
            list[i], list[i - 1] = list[i - 1], list[i]
        elseif action[1] == "down" and i < #list then
            list[i], list[i + 1] = list[i + 1], list[i]
        end
        PDX.cwMarkDirty()
    end
end

-- Lista unui nivel de roata: bifa = apare pe roata, rand tras cu mouse-ul = ordinea (prima felie = sus, ora 12)
function PDX.drawWheelLevelOrder(level, title)
    sectionTitle(fa.ICON_FA_SORT, title)
    local entries, allIds = {}, {}
    for _, it in ipairs(PDX.wLevelItems(level)) do
        entries[it.wid] = { icon = it.icon, label = it.label .. (it.own and "  [al tau]" or "") .. (it.sub and "  >" or "") }
        allIds[#allIds + 1] = it.wid
    end
    local order = PDX.wOrder(level, allIds)
    local rowTops, dragPos = {}, nil
    for pos, id in ipairs(order) do
        rowTops[pos] = imgui.GetCursorScreenPos().y
        local e = entries[id]
        local hidden = PDX.wIsHidden(level, id)
        local cb = new.bool(not hidden)
        if imgui.Checkbox("##wShow_" .. level .. id, cb) then PDX.wSetHidden(level, id, not cb[0]) end
        if imgui.IsItemHovered() then imgui.SetTooltip("%s", "Bifat = apare pe roata") end
        imgui.SameLine()
        imgui.TextColored(colors.textMuted, "%s", string.format("%2d.", pos))
        imgui.SameLine()
        imgui.PushStyleColor(imgui.Col.Text, hidden and colors.textDim or colors.textPrimary)
        imgui.PushStyleColor(imgui.Col.HeaderHovered, imgui.ImVec4(0.16, 0.69, 0.88, 0.20))
        imgui.PushStyleColor(imgui.Col.HeaderActive, imgui.ImVec4(0.16, 0.69, 0.88, 0.40))
        imgui.Selectable(fa.ICON_FA_GRIP_VERTICAL .. "   " .. e.icon .. "   " .. PDX.tr(e.label) .. "##wSel_" .. level .. id, false)
        if imgui.IsItemActive() then dragPos = pos end
        if imgui.IsItemHovered() and not imgui.IsItemActive() then
            imgui.SetTooltip("%s", "Tine apasat click stanga si trage in sus / jos")
        end
        imgui.PopStyleColor(3)
    end
    -- tras cu mouse-ul: randul tinut se pune pe randul de sub mouse; salvare cand dai drumul
    if dragPos then
        local my = imgui.GetMousePos().y
        local target = 1
        for i = 1, #rowTops do
            if my >= rowTops[i] then target = i end
        end
        if target ~= dragPos then
            local item = table.remove(order, dragPos)
            table.insert(order, target, item)
            cfg.wheel["order_" .. level] = table.concat(order, ",")
            PDX.wOrderDirty = true
        end
    end
    if PDX.wOrderDirty and not imgui.IsMouseDown(0) then
        PDX.wOrderDirty = false
        saveCfg()
    end
    PushButtonColors(colors.red, colors.redHover)
    if imgui.Button(fa.ICON_FA_UNDO .. " Implicit (ordine + toate vizibile)##wReset_" .. level, imgui.ImVec2(300, 24)) then
        cfg.wheel["order_" .. level], cfg.wheel["hide_" .. level] = "", ""
        saveCfg()
    end
    imgui.PopStyleColor(3)
end

-- ---------- Preview roata (stanga ecranului, cat timp esti in /pdc -> Roata) ----------
-- click stanga pe o felie cu submeniu = intri in el (lista de ordine/afisare il urmeaza), click dreapta = inapoi
PDX.wheelPreviewOn = false
PDX.wPrevStack     = {}   -- nivelurile in care ai intrat (sub radacina pe jos / in masina)
PDX.wPrevRootMode  = nil

function PDX.wPrevLevel()
    local root = (PDX.cwMode == "car") and "car" or "foot"
    if PDX.wPrevRootMode ~= root then PDX.wPrevStack, PDX.wPrevRootMode = {}, root end
    return PDX.wPrevStack[#PDX.wPrevStack] or root, root
end

function PDX.wPrevEnter(level)
    PDX.wPrevLevel()
    PDX.wPrevStack[#PDX.wPrevStack + 1] = level
end

function PDX.wPrevBack()
    if #PDX.wPrevStack > 0 then table.remove(PDX.wPrevStack) end
end

-- feliile pt preview: toate (si cele care apar doar uneori), cu ordinea + ascunderea ta aplicate
function PDX.wheelPreviewItems(level)
    local items = PDX.wLevelItems(level)
    for _, it in ipairs(items) do it.label = it.label:gsub("%s*%(.-%)$", "") end
    return PDX.wApply(items, level)
end

PDX.wheelPreviewFrame = imgui.OnFrame(
    function() return PDX.wheelPreviewOn and mainWin.visible and mainWin.tab == 10 and not state.paused end,
    function(self)
        self.HideCursor = false
        local sw, sh = getScreenResCached()
        local level  = PDX.wPrevLevel()
        local items  = PDX.wheelPreviewItems(level)
        local s      = PDX.wheelScale()
        local R_IN, R_OUT = 92 * s, 205 * s
        local half   = R_OUT + 30 * s
        local cx, cy = half + 10, sh * 0.5

        imgui.SetNextWindowPos(imgui.ImVec2(cx - half, cy - half), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(half * 2, half * 2 + 60 * s), imgui.Cond.Always)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
        imgui.Begin("##PDWheelPreview", nil,
            imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove +
            imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoBackground + imgui.WindowFlags.NoCollapse +
            imgui.WindowFlags.NoSavedSettings
        )

        local center = imgui.ImVec2(cx, cy)
        local dl     = imgui.GetWindowDrawList()
        local font   = imgui.GetFont()
        local baseF  = imgui.GetFontSize()
        local n      = #items
        local step   = (n > 0) and (2 * math.pi / n) or 0
        local gap    = (n > 1) and 0.03 or 0.0
        local rMid   = (R_IN + R_OUT) * 0.5

        -- felia de sub mouse
        local mp     = imgui.GetMousePos()
        local dx, dy = mp.x - cx, mp.y - cy
        local dist   = math.sqrt(dx * dx + dy * dy)
        local inWin  = imgui.IsWindowHovered()
        local hover  = 0
        if inWin and n > 0 and dist > R_IN - 12 * s and dist < R_OUT + 22 * s then
            local rel = (math.atan2(dy, dx) + math.pi / 2) % (2 * math.pi)
            hover = math.floor((rel + step / 2) / step) % n + 1
        end

        dl:AddCircleFilled(center, R_OUT + 22 * s, 0x66000000, 64)
        for i, it in ipairs(items) do
            local ang = -math.pi / 2 + (i - 1) * step
            local a0, a1 = ang - step / 2 + gap, ang + step / 2 - gap
            local hov = (i == hover)
            dl:PathArcTo(center, rMid, a0, a1, 36)
            dl:PathStroke(imgui.ColorConvertFloat4ToU32(hov and imgui.ImVec4(0.10, 0.30, 0.42, 0.92) or imgui.ImVec4(0.06, 0.08, 0.12, 0.88)), false, R_OUT - R_IN)
            dl:PathArcTo(center, R_OUT - 1.5, a0, a1, 36)
            dl:PathStroke(imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.16, 0.69, 0.88, hov and 0.95 or 0.35)), false, 3)
            -- numarul din ordine (+ sageata daca are submeniu) + iconita + nume
            local lines = {
                { tostring(i) .. (it.sub and "  >" or ""), baseF * 0.85 * s, 0xFFE0AF28 },
                { it.icon, baseF * 1.35 * s, 0xFFFFFFFF },
                { PDX.tr(it.label), baseF * 1.08 * s, 0xFFFFFFFF },
            }
            local totalH = 0
            for _, l in ipairs(lines) do totalH = totalH + l[2] + 2 end
            local tcx = cx + math.cos(ang) * rMid
            local ty  = cy + math.sin(ang) * rMid - totalH * 0.5
            for _, l in ipairs(lines) do
                if l[1] ~= "" then
                    local tw = font:CalcTextSizeA(l[2], 10000, -1, l[1]).x
                    drawOutlinedText(dl, font, l[2], tcx - tw * 0.5, ty, l[3], l[1])
                end
                ty = ty + l[2] + 2
            end
        end
        local rC = R_IN - 12 * s
        dl:AddCircleFilled(center, rC, 0xE60E131C, 64)
        dl:AddCircle(center, rC, imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.16, 0.69, 0.88, 0.55)), 64, 2)
        local t1 = "PREVIEW"
        local t2 = PDX.tr(PDX.wLevelName(level))
        local f1, f2 = baseF * s, baseF * 0.9 * s
        local w1 = font:CalcTextSizeA(f1, 10000, -1, t1).x
        local w2 = font:CalcTextSizeA(f2, 10000, -1, t2).x
        drawOutlinedText(dl, font, f1, cx - w1 * 0.5, cy - 18 * s, 0xFFE0AF28, t1)
        drawOutlinedText(dl, font, f2, cx - w2 * 0.5, cy + 4 * s, 0xFFC8D0DC, t2)
        -- puncte = cat de adanc esti
        local depth = #PDX.wPrevStack + 1
        for d = 1, depth do
            local px = cx + (d - (depth + 1) / 2) * 12 * s
            dl:AddCircleFilled(imgui.ImVec2(px, cy + 30 * s), 3 * s, d == depth and 0xFFE0AF28 or 0x88C8D0DC, 12)
        end
        -- indicatie sub roata
        local hints = { PDX.tr("Click pe felie cu > = intri in submeniu"), PDX.tr("Click dreapta = inapoi") }
        if n == 0 then table.insert(hints, 1, PDX.tr("Nicio felie vizibila")) end
        local hy = cy + R_OUT + 26 * s
        for _, t3 in ipairs(hints) do
            local w3 = font:CalcTextSizeA(f2, 10000, -1, t3).x
            drawOutlinedText(dl, font, f2, cx - w3 * 0.5, hy, 0xFFC8D0DC, t3)
            hy = hy + f2 + 3
        end

        if inWin then
            if imgui.IsMouseClicked(0) and hover > 0 and items[hover] and items[hover].sub then
                PDX.wPrevEnter(items[hover].sub)
            elseif imgui.IsMouseClicked(1) then
                PDX.wPrevBack()
            end
        end

        imgui.End()
        imgui.PopStyleVar(2)
    end
)
PDX.wheelPreviewFrame.HideCursor = false

function PDX.drawWheelEditor()
    imgui.Text("Roata:")
    imgui.SameLine()
    if imgui.RadioButtonBool("Pe jos##cwFootTop", PDX.cwMode == "foot") then PDX.cwMode = "foot" end
    imgui.SameLine()
    if imgui.RadioButtonBool("In masina (sofer)##cwCarTop", PDX.cwMode == "car") then PDX.cwMode = "car" end

    -- marime roata (roata reala + preview)
    imgui.Text("Marime roata:")
    imgui.SameLine()
    imgui.PushItemWidth(200)
    local vW = new.int(tonumber(cfg.settings.wheelScalePct) or 100)
    if imgui.SliderInt("##wheelScale", vW, 60, 160, "%d%%") then
        cfg.settings.wheelScalePct = vW[0]
        PDX.lookSaveAt = os.clock() + 0.8
    end
    imgui.PopItemWidth()

    -- preview in stanga ecranului
    imgui.SameLine(0, 20)
    local cbPrev = new.bool(PDX.wheelPreviewOn)
    if imgui.Checkbox("Preview roata (stanga ecranului)##wPrev", cbPrev) then PDX.wheelPreviewOn = cbPrev[0] end
    imgui.TextDisabled("Debifeaza ce nu folosesti si trage randurile in ordinea dorita. Prima felie apare sus (ora 12).")
    imgui.TextDisabled("Intri in submeniuri cu butoanele de mai jos sau dand click pe felie in preview (click dreapta = inapoi).")

    -- unde esti: Pe jos > Meniu jucator > Wanted ...
    local level, root = PDX.wPrevLevel()
    local path = { root }
    for _, l in ipairs(PDX.wPrevStack) do path[#path + 1] = l end
    for i, l in ipairs(path) do
        if i > 1 then imgui.SameLine(); imgui.TextDisabled(">"); imgui.SameLine() end
        local name = PDX.tr(PDX.wLevelName(l))
        if i == #path then
            imgui.TextColored(colors.accent or imgui.ImVec4(0.16, 0.69, 0.88, 1), "%s", name)
        elseif imgui.SmallButton(name .. "##wcrumb" .. i) then
            for _ = i, #PDX.wPrevStack do table.remove(PDX.wPrevStack) end
        end
    end

    PDX.drawWheelLevelOrder(level, PDX.tr("ORDINE + AFISARE") .. ": " .. string.upper(PDX.tr(PDX.wLevelName(level))))

    -- submeniurile nivelului curent
    local subs = {}
    for _, it in ipairs(PDX.wLevelItems(level)) do if it.sub then subs[#subs + 1] = it end end
    if #subs > 0 or #PDX.wPrevStack > 0 then
        imgui.Text("Submeniuri:")
        for i, it in ipairs(subs) do
            imgui.SameLine()
            if imgui.SmallButton(it.icon .. " " .. PDX.tr((it.label:gsub("%s*%(.-%)$", ""))) .. " >##wsub" .. i) then
                PDX.wPrevEnter(it.sub)
            end
        end
        if #PDX.wPrevStack > 0 then
            imgui.SameLine(0, 16)
            if imgui.SmallButton(fa.ICON_FA_ARROW_LEFT .. " Inapoi##wsubBack") then PDX.wPrevBack() end
        end
    end

    sectionTitle(fa.ICON_FA_DHARMACHAKRA, "ROATA PERSONALIZATA - ELEMENTE PROPRII")
    imgui.TextDisabled("Elementele tale apar pe primul nivel al rotii, dupa cele implicite. Submeniu = folder cu alte elemente.")
    imgui.TextDisabled("Comanda: acelasi format ca la Comenzi Custom (variabile cu '+', ' | ' = mai multe comenzi). Se salveaza singur.")
    imgui.Spacing()

    local list = PDX.cw[PDX.cwMode]
    if #list == 0 then imgui.TextDisabled("Niciun element inca. Apasa '+ Adauga element'.") end
    cwDrawList(list, 0, PDX.cwMode)

    if #list < PDX.CW_MAX_ITEMS then
        PushButtonColors(colors.green, colors.greenHover)
        if imgui.Button(fa.ICON_FA_PLUS .. " Adauga element##cwAddRoot", imgui.ImVec2(200, 28)) then
            list[#list + 1] = { uid = PDX.cwNewUid(), label = "", icon = "STAR", cmd = "", player = false, click = false }
            PDX.cwMarkDirty()
        end
        imgui.PopStyleColor(3)
        imgui.SameLine()
    end
    imgui.TextDisabled("%s", string.format("%d / %d elemente pe nivel", #list, PDX.CW_MAX_ITEMS))
end

-- ---------- Ordinea tastelor in HUD (sus / jos) ----------
PDX.HUD_ROW_INFO = {
    menuKeyOn  = { fa.ICON_FA_GAVEL,                "Tasta Principala (K)" },
    lKeyOn     = { fa.ICON_FA_GAVEL,                "Tasta Secundara (L)" },
    wheelOn    = { fa.ICON_FA_CAR,                  "Roata Interactiune" },
    somatie    = { fa.ICON_FA_BULLHORN,             "Somatie Jucator (/ms)" },
    radar      = { fa.ICON_FA_TACHOMETER_ALT,       "Sisteme Radar (Start/Stop/Find)" },
    cuffarrest = { fa.ICON_FA_LINK,                 "Cuff & Auto-Arrest" },
    frisk      = { fa.ICON_FA_SEARCH,               "Frisk pe Raza" },
    tazer      = { fa.ICON_FA_BOLT,                 "Tazer (/tazer)" },
    wanted     = { fa.ICON_FA_EXCLAMATION_TRIANGLE, "Lista Wanted (/wanted)" },
    nearwanted = { fa.ICON_FA_CROSSHAIRS,           "NearWanted (/nearwanted)" },
    repairon   = { fa.ICON_FA_WRENCH,               "Repair Rapid (/repair)" },
}

-- Randul apare efectiv in HUD acum? (activ + bifat pt HUD)
function PDX.hudRowVisible(id)
    local n = tonumber(id:match("^kbc(%d+)$"))
    if n then
        return tonumber(cfg.kbc["on" .. n]) == 1 and tonumber(cfg.kbc["hud" .. n]) == 1 and (tonumber(cfg.kbc["key" .. n]) or 0) > 0
    end
    local sec = (id == "menuKeyOn" or id == "lKeyOn" or id == "wheelOn") and cfg.settings or cfg.pd
    if id == "radar" and not isRutieraActive() then return false end
    return tonumber(sec[id]) == 1 and PDX.hudRowOn(id)
end

function PDX.drawHudOrder()
    sectionTitle(fa.ICON_FA_SORT, "ORDINEA TASTELOR IN HUD (SUS / JOS)")
    imgui.TextDisabled("Trage cu mouse-ul (click stanga tinut pe rand) sau foloseste sagetile.")
    imgui.TextDisabled("Cele gri nu apar acum in HUD (tasta oprita sau HUD debifat), dar le poti aranja dinainte.")
    imgui.Spacing()
    local order = PDX.getHudOrder()
    local moved
    local rowTops, dragPos = {}, nil
    for pos, id in ipairs(order) do
        rowTops[pos] = imgui.GetCursorScreenPos().y -- inceputul randului (pt tras cu mouse-ul)
        local icon, label
        local n = tonumber(id:match("^kbc(%d+)$"))
        if n then
            icon = PDX.kbcIcon(n)
            local lbl = tostring(cfg.kbc["label" .. n] or "")
            label = "Keybind #" .. n .. ((lbl ~= "") and (": " .. lbl) or "")
        else
            local info = PDX.HUD_ROW_INFO[id] or { "", id }
            icon, label = info[1], info[2]
        end
        local vis = PDX.hudRowVisible(id)

        imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(4, 2))
        PushButtonColors(colors.cardBg, colors.cardHover)
        if imgui.Button(fa.ICON_FA_ARROW_UP .. "##hoUp" .. pos, imgui.ImVec2(26, 22)) and pos > 1 then moved = { pos, pos - 1 } end
        imgui.SameLine(0, 4)
        if imgui.Button(fa.ICON_FA_ARROW_DOWN .. "##hoDn" .. pos, imgui.ImVec2(26, 22)) and pos < #order then moved = { pos, pos + 1 } end
        imgui.PopStyleColor(3)
        imgui.PopStyleVar()
        imgui.SameLine(0, 10)
        imgui.TextColored(colors.textMuted, "%s", string.format("%2d.", pos))
        imgui.SameLine()

        -- rand "apucabil": tii click stanga pe el si tragi in sus / jos (ID-ul e dupa rand, nu dupa pozitie,
        -- ca imgui sa tina randul "prins" cand se muta)
        imgui.PushStyleColor(imgui.Col.Text, vis and colors.textPrimary or colors.textDim)
        imgui.PushStyleColor(imgui.Col.HeaderHovered, imgui.ImVec4(0.16, 0.69, 0.88, 0.20))
        imgui.PushStyleColor(imgui.Col.HeaderActive, imgui.ImVec4(0.16, 0.69, 0.88, 0.40))
        imgui.Selectable(fa.ICON_FA_GRIP_VERTICAL .. "   " .. icon .. "   " .. label .. "##hoSel_" .. id, false)
        if imgui.IsItemActive() then dragPos = pos end -- randul tinut cu click
        if imgui.IsItemHovered() and not imgui.IsItemActive() then
            imgui.SetTooltip("%s", "Tine apasat click stanga si trage in sus / jos")
        end
        imgui.PopStyleColor(3)
    end
    -- sagetile: schimba cu vecinul si salveaza
    if moved then
        local list = {}
        for i, v in ipairs(order) do list[i] = v end
        list[moved[1]], list[moved[2]] = list[moved[2]], list[moved[1]]
        PDX.setHudOrder(list)
    -- tras cu mouse-ul: randul tinut se muta EXACT pe randul aflat sub mouse (dupa Y), nu "cate unul pe frame"
    elseif dragPos then
        local my = imgui.GetMousePos().y
        local target = 1
        for i = 1, #rowTops do
            if my >= rowTops[i] then target = i end
        end
        if target ~= dragPos then
            local list = {}
            for i, v in ipairs(order) do list[i] = v end
            local item = table.remove(list, dragPos)
            table.insert(list, target, item)
            PDX.setHudOrder(list, true) -- in memorie; salvam cand dai drumul la click
            PDX.hudOrderDirty = true
        end
    end
    if PDX.hudOrderDirty and not imgui.IsMouseDown(0) then
        PDX.hudOrderDirty = false
        saveCfg()
    end
    imgui.Spacing()
    PushButtonColors(colors.red, colors.redHover)
    if imgui.Button(fa.ICON_FA_UNDO .. " Ordinea implicita##hudOrderReset", imgui.ImVec2(190, 26)) then
        cfg.settings.hudOrder = ""
        saveCfg()
    end
    imgui.PopStyleColor(3)
end

PDX.passBuf  = new.char[65]()
PDX.pinBuf   = new.char[5]()
PDX.showPass = new.bool(false)
PDX.secretsLoaded = false

local function drawSecretState(stored)
    stored = tostring(stored or "")
    if stored:find("^dp:") then
        imgui.TextColored(colors.green, "%s", fa.ICON_FA_LOCK .. "  Criptat cu Windows (DPAPI): nu poate fi citit pe alt PC sau alt cont de Windows.")
    elseif stored:find("^hex:") then
        imgui.TextColored(colors.orange, "%s", fa.ICON_FA_EXCLAMATION_TRIANGLE .. "  Criptarea Windows nu a mers: e doar codificat (hex), ca la NG-Helper.")
    else
        imgui.TextDisabled("Nimic salvat.")
    end
end

function PDX.drawAccountTab()
    if not PDX.secretsLoaded then
        PDX.secretsLoaded = true
        safeCopyBuf(PDX.passBuf, PDX.secretDecode(cfg.login.pass) or "")
        safeCopyBuf(PDX.pinBuf, PDX.secretDecode(cfg.login.pin) or "")
    end

    sectionTitle(fa.ICON_FA_USER_LOCK, "LOGIN AUTOMAT")
    local cbL = new.bool(tonumber(cfg.login.enabled) == 1)
    if imgui.Checkbox("Completeaza automat parola in dialogul de login al serverului", cbL) then
        cfg.login.enabled = cbL[0] and 1 or 0; saveCfg()
        addNotification("Login automat " .. (cbL[0] and "activat" or "dezactivat"), "saved")
    end
    imgui.Text("Parola:")
    imgui.SameLine(110)
    imgui.PushItemWidth(230)
    local flags = PDX.showPass[0] and 0 or imgui.InputTextFlags.Password
    imgui.InputText("##loginPass", PDX.passBuf, ffi.sizeof(PDX.passBuf), flags)
    imgui.PopItemWidth()
    imgui.SameLine()
    imgui.Checkbox("Arata##showPass", PDX.showPass)
    imgui.SameLine()
    PushButtonColors(colors.green, colors.greenHover)
    if imgui.Button(fa.ICON_FA_SAVE .. " Salveaza parola", imgui.ImVec2(150, 26)) then
        cfg.login.pass = PDX.secretEncode(ffi.string(PDX.passBuf)); saveCfg()
        addNotification("Parola salvata", "saved")
    end
    imgui.PopStyleColor(3)
    drawSecretState(cfg.login.pass)
    imgui.TextColored(colors.textMuted, "%s", "Status: " .. tostring(PDX.login.status))
    imgui.TextDisabled("Doar in dialogul de login, dupa ~0.5s, litera cu litera (rapid). Max 3 incercari / 30s. Daca scrii tu in dialog, se opreste.")

    sectionTitle(fa.ICON_FA_KEY, "PIN AUTOMAT")
    local cbP = new.bool(tonumber(cfg.login.pinAuto) == 1)
    if imgui.Checkbox("Introdu automat PIN-ul pe tastatura de pe ecran (/pin)", cbP) then
        cfg.login.pinAuto = cbP[0] and 1 or 0; saveCfg()
        addNotification("PIN automat " .. (cbP[0] and "activat" or "dezactivat"), "saved")
    end
    imgui.Text("PIN (4 cifre):")
    imgui.SameLine(110)
    imgui.PushItemWidth(80)
    imgui.InputText("##pinCode", PDX.pinBuf, ffi.sizeof(PDX.pinBuf), imgui.InputTextFlags.CharsDecimal + (PDX.showPass[0] and 0 or imgui.InputTextFlags.Password))
    imgui.PopItemWidth()
    imgui.SameLine()
    PushButtonColors(colors.green, colors.greenHover)
    if imgui.Button(fa.ICON_FA_SAVE .. " Salveaza PIN", imgui.ImVec2(130, 26)) then
        local p = ffi.string(PDX.pinBuf)
        if p:match("^%d%d%d%d$") then
            cfg.login.pin = PDX.secretEncode(p); saveCfg()
            addNotification("PIN salvat", "saved")
        else
            msg("PIN-ul trebuie sa aiba exact {28AFE0}4 cifre{FFFFFF}!")
        end
    end
    imgui.PopStyleColor(3)
    drawSecretState(cfg.login.pin)
    imgui.TextDisabled("La 'Bine ai venit' trimite /pin si apasa cifrele. Merge si la /pin dat de tine sau de /dt si /hdt.")

    imgui.Spacing()
    imgui.Spacing()
    PushButtonColors(colors.red, colors.redHover)
    if imgui.Button(fa.ICON_FA_TRASH .. " Sterge parola si PIN-ul salvate", imgui.ImVec2(270, 28)) then
        cfg.login.pass, cfg.login.pin, cfg.login.enabled, cfg.login.pinAuto = "", "", 0, 0
        safeCopyBuf(PDX.passBuf, ""); safeCopyBuf(PDX.pinBuf, "")
        saveCfg()
        addNotification("Datele de cont au fost sterse", "info")
    end
    imgui.PopStyleColor(3)
    imgui.TextColored(colors.orange, "Nu da nimanui folderul moonloader/config, chiar daca parola e criptata.")
end

-- ---------- Tab "Aspect": culori HUD + notificari, cu preview ----------
PDX.lookBuf     = {}
PDX.lookPreview = "info"
PDX.lookSaveAt  = nil

PDX.LOOK_PRESETS = {
    { "Albastru",  "#28AFE0" },
    { "Verde",     "#3DDC84" },
    { "Rosu",      "#FF4D5E" },
    { "Auriu",     "#FFC23D" },
    { "Mov",       "#A77BFF" },
    { "Alb",       "#FFFFFF" },
}

local function lookColorRow(key, label, tip)
    local b = PDX.lookBuf[key]
    if not b then
        local r, g, bl = PDX.hexToRGB(cfg.look[key])
        b = ffi.new("float[3]", r, g, bl)
        PDX.lookBuf[key] = b
    end
    imgui.Text(label)
    imgui.SameLine(300)
    if imgui.ColorEdit3("##look_" .. key, b, imgui.ColorEditFlags.NoInputs) then
        cfg.look[key] = PDX.rgbToHex(b[0], b[1], b[2])
        PDX.applyLook()
        PDX.lookSaveAt = os.clock() + 0.8 -- salvare dupa ce te opresti din tras de culoare
    end
    imgui.SameLine()
    imgui.TextDisabled("%s", cfg.look[key])
    if tip then Tooltip(tip) end
end

function PDX.drawLookTab()
    sectionTitle(fa.ICON_FA_DESKTOP, "CULORI HUD (MODERN SI CLASIC) - se vad imediat pe ecran")
    lookColorRow("hudAccent", "Accent", "HUD clasic: etichetele (PANOU SETARI, FRISK...). HUD modern: iconitele si tastele.")
    lookColorRow("hudText",   "Text / taste", "HUD clasic: tastele (K, P, num+...). HUD modern: etichetele.")
    lookColorRow("hudIcon",   "Iconite (HUD clasic)")
    lookColorRow("hudTitle",  "Titlu (scut + ASSIST)")

    imgui.TextDisabled("Preseturi rapide pt accent + titlu:")
    for i, p in ipairs(PDX.LOOK_PRESETS) do
        local r, g, b = PDX.hexToRGB(p[2])
        PushButtonColors(imgui.ImVec4(r, g, b, 0.85), imgui.ImVec4(r, g, b, 1.0))
        imgui.PushStyleColor(imgui.Col.Text, colors.dark)
        if imgui.Button(p[1] .. "##lookPreset" .. i, imgui.ImVec2(88, 24)) then
            cfg.look.hudAccent, cfg.look.hudTitle = p[2], p[2]
            PDX.lookBuf.hudAccent, PDX.lookBuf.hudTitle = nil, nil
            PDX.applyLook()
            saveCfg()
        end
        imgui.PopStyleColor(4)
        if i < #PDX.LOOK_PRESETS then imgui.SameLine() end
    end

    sectionTitle(fa.ICON_FA_BELL, "CULORI NOTIFICARI")
    lookColorRow("notifBg",   "Fundal card")
    lookColorRow("notifText", "Text mesaj")
    local vA = new.int(tonumber(cfg.look.notifAlpha) or 94)
    imgui.Text("Opacitate fundal")
    imgui.SameLine(300)
    imgui.PushItemWidth(200)
    if imgui.SliderInt("##notifAlpha", vA, 40, 100, "%d%%") then
        cfg.look.notifAlpha = vA[0]
        PDX.lookSaveAt = os.clock() + 0.8
    end
    imgui.PopItemWidth()
    lookColorRow("notifInfo",     "Tip: Info")
    lookColorRow("notifRadar",    "Tip: Radar")
    lookColorRow("notifSanction", "Tip: Sanctiune / Wanted")
    lookColorRow("notifSaved",    "Tip: Salvat")
    lookColorRow("notifTimer",    "Tip: Timer")
    lookColorRow("notifError",    "Tip: Eroare")

    -- Preview: acelasi card ca notificarea reala, desenat aici in meniu
    sectionTitle(fa.ICON_FA_EYE, "PREVIEW NOTIFICARE")
    local types = {
        { "info",     "Info",      "Sanctiune aplicata -> Ion_Popescu" },
        { "radar",    "Radar",     "Ion_Popescu [25] -> 178 km/h (Niv 34)" },
        { "sanction", "Sanctiune", "Wanted (Fugar) -> ID 25" },
        { "saved",    "Salvat",    "Setarile au fost salvate!" },
        { "timer",    "Timer",     "Timpul AFK a expirat!" },
        { "error",    "Eroare",    "Niciun jucator nu se afla pe o raza de 3.0m!" },
    }
    local sample = types[1][3]
    for i, t in ipairs(types) do
        if imgui.RadioButtonBool(t[2] .. "##prevType" .. i, PDX.lookPreview == t[1]) then PDX.lookPreview = t[1] end
        if PDX.lookPreview == t[1] then sample = t[3] end
        if i < #types then imgui.SameLine() end
    end
    imgui.Spacing()
    local p    = imgui.GetCursorScreenPos()
    local prog = 1 - (os.clock() % NOTIF_DURATION) / NOTIF_DURATION -- bara de timp animata, ca in joc
    local pns = PDX.notifScale() -- preview la marimea reala setata
    PDX.drawNotifCard(imgui.GetWindowDrawList(), p.x + 4, p.y, pns, 1.0, notifTypes[PDX.lookPreview] or notifTypes.info, PDX.tr(sample), prog)
    imgui.Dummy(imgui.ImVec2(NOTIF_WIDTH * pns + 10, NOTIF_HEIGHT * pns + 8))
    imgui.SameLine()
    imgui.BeginGroup()
    PushButtonColors(colors.royal, colors.royalHover)
    if imgui.Button(fa.ICON_FA_PLAY .. " Arata pe ecran##prevShow", imgui.ImVec2(170, 28)) then
        addNotification(sample, PDX.lookPreview)
    end
    imgui.PopStyleColor(3)
    if cfg.settings.notifType == 1 then
        imgui.TextColored(colors.orange, "Ai notificari Clasice (General) -")
        imgui.TextColored(colors.orange, "cardul apare doar pe Toast ImGui.")
    end
    imgui.EndGroup()

    imgui.Spacing()
    PushButtonColors(colors.red, colors.redHover)
    if imgui.Button(fa.ICON_FA_UNDO .. " Reseteaza toate culorile", imgui.ImVec2(230, 28)) then
        for k, v in pairs(PDX.LOOK_DEFAULTS) do cfg.look[k] = v end
        cfg.look.notifAlpha = 94
        PDX.lookBuf = {}
        PDX.applyLook()
        saveCfg()
        addNotification("Culorile au fost resetate", "saved")
    end
    imgui.PopStyleColor(3)
end

-- Numaratoare AFK mare, pe mijlocul ecranului
PDX.afkFrame = imgui.OnFrame(
    function() return PDX.afk.kind ~= nil and timers.afkEnd > os.clock() and not state.paused end,
    function(self)
        self.HideCursor = true
        local sw, sh = getScreenResCached()
        local dl   = imgui.GetBackgroundDrawList()
        local font = imgui.GetFont()
        local fs   = imgui.GetFontSize() * 1.6
        local rem  = math.max(0, math.ceil(timers.afkEnd - os.clock()))
        local isF  = (PDX.afk.kind == "ffk")
        local txt  = string.format("[%s] %s  |  %d:%02d", isF and "FFK" or "AFK", u8(PDX.afk.name), math.floor(rem / 60), rem % 60)
        local w    = font:CalcTextSizeA(fs, 10000, -1, txt).x
        drawOutlinedText(dl, font, fs, sw * 0.5 - w * 0.5, sh * 0.5 - 130, isF and 0xFF4444FF or 0xFF0088FF, txt)
    end
)
PDX.afkFrame.HideCursor = true

-- =========================================================================================
--  SECTION 10: MAIN CONFIGURATION MENU (/pdc)
-- =========================================================================================
imgui.OnFrame(
    function() return mainWin.visible end,
    function() updateAnimWin(mainWin) end,
    function(self)
        self.HideCursor = false
        if mainWin.alpha <= 0.001 then return end

        local sw, sh = getScreenResCached()
        local yAnim  = (1.0 - mainWin.alpha) * 14.0
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, mainWin.alpha)
        imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5 + yAnim), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(980, 620), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSizeConstraints(imgui.ImVec2(math.min(940, sw - 20), math.min(560, sh - 20)), imgui.ImVec2(1250, 900))

        imgui.Begin("##PDAssistConfigWin", mainWin.open, imgui.WindowFlags.NoTitleBar)
        if not mainWin.open[0] then
            mainWin.open[0] = true
            closeAnimWin(mainWin)
        end
        if not capturingBind and imgui.IsWindowFocused(imgui.FocusedFlags.RootAndChildWindows) and imgui.IsKeyPressed(vkeys.VK_ESCAPE) then
            closeAnimWin(mainWin)
        end

        drawModernHeader(fa.ICON_FA_SHIELD_ALT, getFaction() .. " ASSIST", "PANOU CONFIGURARE (/pdc)", function() closeAnimWin(mainWin) end, "closeMain")

        -- Meniu lateral (sidebar) + status rapid
        PDX.drawSidebar()
        imgui.SameLine()
        imgui.BeginChild("##pdMainContent", imgui.ImVec2(0, -46), true)

        -- ──────────────────────────────────────────────────────────────
        -- TAB 1: RADAR & AUTOMATIZARE
        -- ──────────────────────────────────────────────────────────────
        if mainWin.tab == 1 then
            -- Faction & Language Selector
            imgui.TextColored(colors.accent, fa.ICON_FA_BUILDING .. " DEPARTAMENT & LIMBA EXPLICATII SANCTIUNI")
            imgui.Separator()
            imgui.Spacing()

            for idx, facName in ipairs(FACTIONS) do
                if idx > 1 then imgui.SameLine() end
                local isSel = (getFaction() == facName)
                if isSel then
                    PushButtonColors(colors.accent, colors.accentHover)
                    imgui.PushStyleColor(imgui.Col.Text, colors.dark)
                else
                    PushButtonColors(colors.cardBg, colors.cardHover)
                    imgui.PushStyleColor(imgui.Col.Text, colors.textPrimary)
                end
                if imgui.Button((isSel and (fa.ICON_FA_CHECK .. " ") or "") .. facName, imgui.ImVec2(95, 28)) then
                    cfg.settings.faction = facName
                    saveCfg()
                    addNotification("Departament setat: " .. facName, "saved")
                end
                imgui.PopStyleColor(4)
            end

            imgui.Spacing()
            imgui.Text("Limba interfata:")
            imgui.SameLine()
            if imgui.RadioButtonBool("Romana##uiLangRo", PDX.uiLang ~= "en") then
                PDX.setUiLang("ro"); saveCfg()
                addNotification("Limba interfetei: Romana", "saved")
            end
            imgui.SameLine()
            if imgui.RadioButtonBool("English##uiLangEn", PDX.uiLang == "en") then
                PDX.setUiLang("en"); saveCfg()
                addNotification("Interface language: English", "saved")
            end
            Tooltip("Limba meniurilor, a HUD-ului, a rotii si a notificarilor. Mesajele trimise jucatorilor raman pe 'Limba Sanctiuni'.")
            imgui.SameLine(0, 30)
            imgui.Text("Limba Sanctiuni:")
            imgui.SameLine()
            if imgui.RadioButtonBool("RO", cfg.settings.limba == 1) then
                cfg.settings.limba = 1; saveCfg()
                addNotification("Explicatii sanctiuni: Romana", "saved")
            end
            imgui.SameLine()
            if imgui.RadioButtonBool("EN", cfg.settings.limba == 0) then
                cfg.settings.limba = 0; saveCfg()
                addNotification("Sanctions language: English", "saved")
            end

            if isPdFaction() then
                imgui.Spacing()
                imgui.Text("Echipa PD:")
                imgui.SameLine()
                local curTeam = tostring(cfg.settings.pdTeam or "RUTIERA")
                if imgui.RadioButtonBool("Rutiera (Radar & Trafic Activ)", curTeam ~= "SWAT") then
                    cfg.settings.pdTeam = "RUTIERA"; saveCfg()
                    addNotification("Echipa setata: Rutiera", "saved")
                end
                imgui.SameLine()
                if imgui.RadioButtonBool("SWAT (Fara Radar & Rutiera)", curTeam == "SWAT") then
                    cfg.settings.pdTeam = "SWAT"; cfg.radar.stage = 0; saveCfg()
                    addNotification("Echipa setata: SWAT (Rutiera ascunsa)", "saved")
                end
            end

            imgui.Spacing()
            imgui.TextColored(colors.accent, fa.ICON_FA_DESKTOP .. " AFISARE INDICATORI & POZITIONARE HUD")
            imgui.Separator()
            imgui.Spacing()

            local cb_hud = new.bool(cfg.settings.hud == 1)
            if imgui.Checkbox("Afiseaza HUD-ul cu taste si timere pe ecran (Dreapta)", cb_hud) then
                cfg.settings.hud = cb_hud[0] and 1 or 0; saveCfg()
                addNotification("HUD Indicator " .. (cb_hud[0] and "activat" or "dezactivat"), "saved")
            end

            imgui.Text("Stil HUD:")
            imgui.SameLine(150)
            if imgui.RadioButtonBool("Modern (dreapta, cu iconite)", tonumber(cfg.settings.hudStyle) ~= 1) then
                cfg.settings.hudStyle = 0; saveCfg()
                addNotification("HUD: stil modern", "saved")
            end
            imgui.SameLine()
            if imgui.RadioButtonBool("Clasic PDHelper (jos, deasupra rpg.b-zone.ro)", tonumber(cfg.settings.hudStyle) == 1) then
                cfg.settings.hudStyle = 1; saveCfg()
                addNotification("HUD: stil clasic PDHelper", "saved")
            end

            -- Marime HUD + notificari (pt ecrane mici / mari). Legate = un slider le muta pe amandoua.
            local linked = tonumber(cfg.settings.scaleLinked) == 1
            local vHud   = new.int(tonumber(cfg.settings.hudScalePct) or 100)
            local vNot   = new.int(tonumber(cfg.settings.notifScalePct) or 100)
            imgui.Text("Marime HUD:")
            imgui.SameLine(150)
            imgui.PushItemWidth(220)
            if imgui.SliderInt("##hudScale", vHud, 60, 160, "%d%%") then
                cfg.settings.hudScalePct = vHud[0]
                if linked then cfg.settings.notifScalePct = vHud[0] end
                PDX.lookSaveAt = os.clock() + 0.8
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            local cbLink = new.bool(linked)
            if imgui.Checkbox("Aceeasi marime pt notificari##scaleLink", cbLink) then
                cfg.settings.scaleLinked = cbLink[0] and 1 or 0
                if cbLink[0] then cfg.settings.notifScalePct = cfg.settings.hudScalePct end
                saveCfg()
            end
            if not linked then
                imgui.Text("Marime notificari:")
                imgui.SameLine(150)
                imgui.PushItemWidth(220)
                if imgui.SliderInt("##notifScale", vNot, 60, 160, "%d%%") then
                    cfg.settings.notifScalePct = vNot[0]
                    PDX.lookSaveAt = os.clock() + 0.8
                end
                imgui.PopItemWidth()
            end
            imgui.SameLine()
            PushButtonColors(colors.royal, colors.royalHover)
            if imgui.Button(fa.ICON_FA_EYE .. " Test notificare##scaleTest", imgui.ImVec2(150, 22)) then
                addNotification("Asa arata notificarile la marimea asta", "info")
            end
            imgui.PopStyleColor(3)

            imgui.Text("Stil Notificari:")
            imgui.SameLine(150)
            if imgui.RadioButtonBool("Toast Modern ImGui", cfg.settings.notifType == 0) then
                cfg.settings.notifType = 0; saveCfg()
                addNotification("Notificari ImGui activate!", "saved")
            end
            imgui.SameLine()
            if imgui.RadioButtonBool("Clasic Pe Ecran", cfg.settings.notifType == 1) then
                cfg.settings.notifType = 1; notifications = {}; saveCfg()
                addNotification("Notificari clasice activate!", "saved")
            end
            imgui.SameLine(0, 20)
            local cbErr = new.bool(tonumber(cfg.settings.errNotif) == 1)
            if imgui.Checkbox("Erorile modului ca notificari##errNotif", cbErr) then
                cfg.settings.errNotif = cbErr[0] and 1 or 0; saveCfg()
                addNotification("Erorile modului apar acum " .. (cbErr[0] and "ca notificari" or "in chat"), "saved")
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("%s", "Mesajele de eroare [PDAssist] (Niciun jucator..., Blocat..., Nu ai /find...) apar ca notificare in loc de chat. Restul raman in chat. Doar cu Toast ImGui.")
            end
            local cbUpd = new.bool(tonumber(cfg.settings.updateCheck) ~= 0)
            if imgui.Checkbox("Verifica update la pornire##updCheck", cbUpd) then
                cfg.settings.updateCheck = cbUpd[0] and 1 or 0; saveCfg()
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("%s", PDX.tr("Cauta pe GitHub o versiune noua la fiecare pornire. Manual: /pdupdate"))
            end
            imgui.SameLine(0, 12)
            if imgui.SmallButton(fa.ICON_FA_SYNC .. " Verifica acum##updNow") then PDX.checkUpdate(true) end

            imgui.Text("Stil Meniu /san:")
            imgui.SameLine(150)
            if imgui.RadioButtonBool("Meniu Modern Mimgui", cfg.settings.sanMenuType == 0) then
                cfg.settings.sanMenuType = 0; saveCfg()
            end
            imgui.SameLine()
            if imgui.RadioButtonBool("Dialog Clasic SA-MP", cfg.settings.sanMenuType == 1) then
                cfg.settings.sanMenuType = 1; saveCfg()
            end

            imgui.Spacing()
            PushButtonColors(colors.accent, colors.accentHover)
            imgui.PushStyleColor(imgui.Col.Text, colors.dark)
            if imgui.Button(fa.ICON_FA_MOUSE_POINTER .. " Muta HUD cu Mouse-ul (/hudpos)", imgui.ImVec2(260, 28)) then
                startHudMoving()
            end
            imgui.PopStyleColor(4)

            imgui.SameLine()
            PushButtonColors(colors.cardBg, colors.cardHover)
            if imgui.Button(fa.ICON_FA_UNDO .. " Reseteaza Pozitia HUD (/resethud)", imgui.ImVec2(250, 28)) then
                resetHudPosition()
            end
            imgui.PopStyleColor(3)

            -- sliderele editeaza pozitia stilului de HUD activ (modern sau clasic PDHelper)
            local sw_s, sh_s = getScreenResCached()
            local kC, kX, kY = PDX.hudPosKeys()
            if PDX.lastHudStyleSynced ~= cfg.settings.hudStyle then
                PDX.lastHudStyleSynced = cfg.settings.hudStyle
                syncHudSliders()
            end
            imgui.TextDisabled((tonumber(cfg.settings.hudStyle) == 1) and "Pozitie HUD clasic PDHelper (marginea dreapta / sus):" or "Pozitie HUD modern (marginea dreapta / sus):")
            imgui.PushItemWidth(250)
            if imgui.SliderInt("Pozitie X##hudX", hudPosX, 200, sw_s, "%d px") then
                cfg.settings[kC] = true
                cfg.settings[kX] = hudPosX[0]
                if (tonumber(cfg.settings[kY]) or -1) <= 0 then cfg.settings[kY] = hudPosY[0] end
                saveCfg()
            end
            imgui.SameLine()
            if imgui.SliderInt("Pozitie Y##hudY", hudPosY, 15, math.max(50, sh_s - 30), "%d px") then
                cfg.settings[kC] = true
                cfg.settings[kY] = hudPosY[0]
                if (tonumber(cfg.settings[kX]) or -1) <= 0 then cfg.settings[kX] = hudPosX[0] end
                saveCfg()
            end
            imgui.PopItemWidth()

        -- ──────────────────────────────────────────────────────────────
        -- TAB 6: RADAR (doar Rutiera)
        -- ──────────────────────────────────────────────────────────────
        elseif mainWin.tab == 6 then
            if isRutieraActive() then
                imgui.Spacing()
                imgui.TextColored(colors.accent, fa.ICON_FA_TACHOMETER_ALT .. " CONFIGURARE ZONA & LIMITA RADAR")
                imgui.Separator()
                imgui.Spacing()

                imgui.Text("Zona Radar:")
                imgui.SameLine(110)
                imgui.PushItemWidth(220)
                imgui.InputTextWithHint("##zonaInp", "Ex: Temple LS / Autostrada LS-LV", buf_zona, ffi.sizeof(buf_zona))
                imgui.PopItemWidth()

                imgui.SameLine()
                imgui.Text("Limita:")
                imgui.SameLine()
                imgui.PushItemWidth(70)
                imgui.InputText("##limitaInp", buf_limita, ffi.sizeof(buf_limita), imgui.InputTextFlags.CharsDecimal)
                imgui.PopItemWidth()

                imgui.SameLine()
                PushButtonColors(colors.green, colors.greenHover)
                if imgui.Button(fa.ICON_FA_SAVE .. " SETEAZA", imgui.ImVec2(115, 28)) then
                    local z = ffi.string(buf_zona):gsub("^%s+", ""):gsub("%s+$", ""):sub(1, 40)
                    local l = tonumber(ffi.string(buf_limita)) or 100
                    if z ~= "" then cfg.radar.zona = z end
                    cfg.radar.limita = l
                    cfg.radar.stage  = 0
                    liStep = 0
                    safeCopyBuf(buf_zona, cfg.radar.zona)
                    safeCopyBuf(buf_limita, tostring(l))
                    saveCfg()
                    msg(string.format("Setat: {28AFE0}%s{FFFFFF} (%d km/h).", cfg.radar.zona, l))
                    addNotification(string.format("Radar: %s (%d km/h)", cfg.radar.zona, l), "saved")
                end
                imgui.PopStyleColor(3)

                -- Quick Speed Limit Presets (100 / 130 / 160 km/h)
                imgui.TextDisabled("Preset-uri rapide limita:")
                imgui.SameLine()
                for _, limPreset in ipairs({ 100, 130, 160 }) do
                    local activeLim = (tonumber(cfg.radar.limita) == limPreset)
                    PushButtonColors(activeLim and colors.royal or colors.cardBg, colors.royalHover)
                    if imgui.Button(limPreset .. " km/h##p" .. limPreset, imgui.ImVec2(85, 24)) then
                        cfg.radar.limita = limPreset
                        cfg.radar.stage  = 0
                        safeCopyBuf(buf_limita, tostring(limPreset))
                        saveCfg()
                        addNotification("Limita radar setata: " .. limPreset .. " km/h", "saved")
                    end
                    imgui.PopStyleColor(3)
                    imgui.SameLine()
                end
                imgui.NewLine()

                -- Preseturi de zona: un click seteaza zona + limita
                imgui.Spacing()
                imgui.TextDisabled("Preseturi zona radar (click = seteaza zona + limita):")
                for i, p in ipairs(PDX.RADAR_PRESETS) do
                    local isCur = (tostring(cfg.radar.zona) == p[1] and tonumber(cfg.radar.limita) == p[2])
                    if isCur then
                        PushButtonColors(colors.accent, colors.accentHover)
                        imgui.PushStyleColor(imgui.Col.Text, colors.dark)
                    else
                        PushButtonColors(colors.cardBg, colors.cardHover)
                        imgui.PushStyleColor(imgui.Col.Text, colors.textPrimary)
                    end
                    if imgui.Button(string.format("%s (%d)##rzp%d", p[3] or p[1], p[2], i), imgui.ImVec2(180, 26)) then
                        cfg.radar.zona   = p[1]
                        cfg.radar.limita = p[2]
                        cfg.radar.stage  = 0
                        liStep = 0
                        safeCopyBuf(buf_zona, p[1])
                        safeCopyBuf(buf_limita, tostring(p[2]))
                        saveCfg()
                        msg(string.format("Setat: {28AFE0}%s{FFFFFF} (%d km/h).", p[1], p[2]))
                        addNotification(string.format("Radar: %s (%d km/h)", p[1], p[2]), "saved")
                    end
                    imgui.PopStyleColor(4)
                    if i % 4 ~= 0 and i < #PDX.RADAR_PRESETS then imgui.SameLine() end
                end

                -- Last 5 Radar Speeders Preview right inside the tab!
                if #radarHistory > 0 then
                    imgui.Spacing()
                    imgui.TextColored(colors.gold, fa.ICON_FA_HISTORY .. " ULTIMII JUCATORI SURPRINSI PE RADAR (/last & /sl)")
                    for i, rh in ipairs(radarHistory) do
                        imgui.TextColored(colors.textMuted, "%s", string.format("#%d [%s]", i, rh.timeStr))
                        imgui.SameLine()
                        imgui.TextColored(colors.textPrimary, "%s", u8(string.format("%s (ID: %d | Niv: %d)", rh.name, rh.id, rh.level)))
                        imgui.SameLine()
                        imgui.TextColored(colors.redHover, "%s", string.format("%d km/h", rh.speed))
                        imgui.SameLine(0, 14)
                        PushButtonColors(colors.royal, colors.royalHover)
                        if imgui.Button("Find##rf" .. i, imgui.ImVec2(60, 22)) then
                            say("/find " .. rh.id)
                        end
                        imgui.PopStyleColor(3)
                        imgui.SameLine()
                        PushButtonColors(colors.red, colors.redHover)
                        if imgui.Button("Sanctioneaza (/sl)##rsl" .. i, imgui.ImVec2(145, 22)) then
                            executeRadarSl(tostring(rh.id))
                        end
                        imgui.PopStyleColor(3)
                    end
                end
            end

        -- ──────────────────────────────────────────────────────────────
        -- TAB 7: AUTOMATIZARI
        -- ──────────────────────────────────────────────────────────────
        elseif mainWin.tab == 7 then
            imgui.Spacing()
            imgui.TextColored(colors.accent, fa.ICON_FA_COGS .. " MODULE DE AUTOMATIZARE VEHICUL & PATRULA")
            imgui.Separator()
            imgui.Spacing()

            local cb_ae = new.bool(cfg.pd.autoengine == 1)
            if imgui.Checkbox("Auto-Engine (Porneste motorul automat cand urci in vehicul)", cb_ae) then
                cfg.pd.autoengine = cb_ae[0] and 1 or 0; saveCfg()
                addNotification("Auto-Engine " .. (cb_ae[0] and "activat" or "dezactivat"), "saved")
            end

            local cb_ss = new.bool(cfg.pd.startstop == 1)
            if imgui.Checkbox("Start-Stop System (Opreste motorul dupa 10s pe loc, reporneste pe W/S)", cb_ss) then
                cfg.pd.startstop = cb_ss[0] and 1 or 0; ssStep = 0; saveCfg()
                addNotification("Start-Stop " .. (cb_ss[0] and "activat" or "dezactivat"), "saved")
            end

            local cb_gate = new.bool(cfg.settings.gateKeyOn == 1)
            if imgui.Checkbox("Porti Jail / NG, bariere HQ & lifturi pe tasta [" .. tostring(cfg.settings.nGateKey) .. "]", cb_gate) then
                cfg.settings.gateKeyOn = cb_gate[0] and 1 or 0; saveCfg()
            end

            local cb_cp = new.bool(cfg.settings.cp == 1)
            if imgui.Checkbox("Comenzi Prescurtate Active (/fd, /cf, /kc, /rr, /shb, /shu, etc.)", cb_cp) then
                cfg.settings.cp = cb_cp[0] and 1 or 0; saveCfg()
                addNotification("Comenzi prescurtate " .. (cb_cp[0] and "activate" or "dezactivate"), "saved")
            end

            imgui.Spacing()
            local val_frisk = new.float(tonumber(cfg.pd.RazaFrisk) or 3.0)
            imgui.Text("Raza de actionare Frisk pe tasta (metri):")
            imgui.SameLine(300)
            imgui.PushItemWidth(240)
            if imgui.SliderFloat("##friskRadius", val_frisk, 0.5, 5.0, "%.1f m") then
                cfg.pd.RazaFrisk = tonumber(string.format("%.1f", val_frisk[0]))
                saveCfg()
            end
            imgui.PopItemWidth()
            PDX.drawAutomationExtras()

        -- ──────────────────────────────────────────────────────────────
        -- TAB 2: TASTE & KEYBINDS CUSTOM
        -- ──────────────────────────────────────────────────────────────
        elseif mainWin.tab == 2 then
            imgui.Spacing()
            imgui.TextColored(colors.accent, fa.ICON_FA_KEYBOARD .. " CONFIGURARE TASTE RAPIDE (CLICK & APASA TASTA, ESC ANULEAZA)")
            imgui.Separator()
            imgui.Spacing()

            local function drawBindRow(sec, toggleKey, vkKey, nameKey, title, tip)
                local cb = new.bool(cfg[sec][toggleKey] == 1)
                if imgui.Checkbox(title .. "##cb_" .. vkKey, cb) then
                    cfg[sec][toggleKey] = cb[0] and 1 or 0
                    saveCfg()
                end
                if tip then Tooltip(tip) end

                imgui.SameLine(340)
                imgui.TextDisabled("Tasta:")
                imgui.SameLine()

                local isCap = (capturingBind ~= nil and capturingBind.keyId == vkKey)
                if isCap then
                    PushButtonColors(colors.orange, colors.goldHover)
                    imgui.PushStyleColor(imgui.Col.Text, colors.dark)
                else
                    PushButtonColors(colors.cardBg, colors.cardHover)
                    imgui.PushStyleColor(imgui.Col.Text, colors.accent)
                end
                local btnText = isCap and "[ APASA TASTA... ]" or ("[" .. tostring(cfg[sec][nameKey]) .. "]")
                if imgui.Button(btnText .. "##btn_" .. vkKey, imgui.ImVec2(170, 26)) then
                    if isCap then
                        capturingBind = nil
                    else
                        capturingBind = { section = sec, keyId = vkKey, keyName = nameKey, label = title }
                    end
                end
                imgui.PopStyleColor(4)

                -- Afisare in HUD (separat de activare): poti ascunde tasta de pe HUD chiar daca e activa
                if cfg.hudrows and cfg.hudrows[toggleKey] ~= nil then
                    imgui.SameLine()
                    local cbH = new.bool(PDX.hudRowOn(toggleKey))
                    if imgui.Checkbox("HUD##hudrow_" .. toggleKey, cbH) then
                        cfg.hudrows[toggleKey] = cbH[0] and 1 or 0
                        saveCfg()
                    end
                    if imgui.IsItemHovered() then
                        imgui.SetTooltip("%s", "Arata tasta in HUD (debifat = tasta merge, dar nu apare pe ecran)")
                    end
                end
            end

            drawBindRow("settings", "menuKeyOn", "menuKey", "nMenuKey", "Tasta Principala (K)", "Alege mai jos ce actiune/comanda se executa pe aceasta tasta.")
            imgui.Text("      Actiune pe tasta principala:")
            imgui.SameLine(340)
            PDX.drawActionCombo("k", "kAction")
            drawBindRow("settings", "lKeyOn", "lKey", "nLKey", "Tasta Secundara (L)", "Tasta aditionala pentru o a doua actiune/comanda (implicit OFF).")
            imgui.Text("      Actiune pe tasta secundara:")
            imgui.SameLine(340)
            PDX.drawActionCombo("l", "lAction")
            drawBindRow("settings", "wheelOn", "wheelKey", "nWheelKey", "Roata Interactiune (implicit OFF)", "Roata stil GTA V. Sofer: Eject / Cuff / Uncuff pe pasageri. Pe jos: Interact -> jucator -> Frisk / Confisca / Wanted / Sanctiuni / Find / Licente, iar in Jail si Cuff / Punish. Click stanga alege, click dreapta inapoi.")
            imgui.Text("      Raza 'Interact' pe jos:")
            imgui.SameLine(340)
            local vWr = new.int(tonumber(cfg.settings.wheelRadius) or 5)
            imgui.PushItemWidth(170)
            if imgui.SliderInt("##wheelRadius", vWr, 1, 10, "%d metri") then
                cfg.settings.wheelRadius = vWr[0]; saveCfg()
            end
            imgui.PopItemWidth()
            imgui.Text("      Mod tasta roata:")
            imgui.SameLine(340)
            local wMode = tostring(cfg.settings.wheelMode or "hold")
            if imgui.RadioButtonBool("Hold (tii apasat)##wmHold", wMode ~= "touch") then
                cfg.settings.wheelMode = "hold"; saveCfg()
            end
            imgui.SameLine()
            if imgui.RadioButtonBool("Touch (apesi o data)##wmTouch", wMode == "touch") then
                cfg.settings.wheelMode = "touch"; saveCfg()
            end
            Tooltip("Hold: tii tasta, misti mouse-ul pe felie si eliberezi tasta ca sa alegi (submeniurile raman deschise, alegi cu click). Touch: apesi o data ca sa deschizi, alegi cu click, apesi iar ca sa inchizi.")
            drawBindRow("pd", "somatie",    "TastaS",      "nTastaS",      "Somatie Jucator (/ms)",           "Trimite /ms catre jucatorul pe care ai /find activ.")
            if isRutieraActive() then
                drawBindRow("pd", "radar",  "TastaR",      "nTastaR",      "Sisteme Radar (Start/Stop/Find)", "Porneste radarul, opreste + da /find pe vitezoman si reia radarul automat.")
            end
            drawBindRow("pd", "cuffarrest", "TastaCA",     "nTastaCA",     "Cuff & Auto-Arrest",              "Da /cuff pasagerului din masina si /arrest automat cand ajungi la punctul de arrest.")
            drawBindRow("pd", "frisk",      "TastaF",      "nTastaF",      "Frisk pe Raza",                   "Efectueaza control de rutina (/frisk) celui mai apropiat jucator (fiecare jucator max o data la 2 min).")
            drawBindRow("pd", "tazer",      "TastaT",      "nTastaT",      "Tazer (/tazer)",                  "Activeaza sau dezactiveaza tazerul.")
            drawBindRow("pd", "wanted",     "TastaWA",     "nTastaWA",     "Lista Wanted (/wanted)",          "Deschide lista suspectilor cu wanted.")
            drawBindRow("pd", "nearwanted", "TastaNWA",    "nTastaNWA",    "NearWanted (/nearwanted)",        "Afiseaza suspectii cu wanted din apropiere.")
            drawBindRow("pd", "repairon",   "TastaRepair", "nTastaRepair", "Repair Rapid (/repair)",          "Trimite /repair cand esti la volan.")
            drawBindRow("settings", "gateKeyOn", "gateKey", "nGateKey",    "Porti, Bariere & Lifturi",        "Jail LS (/opengate 1/2), garaj NG (/enter, /exit), lifturi LSPD/LVPD (/goup, /godown) si barierele HQ cand esti in masina.")
            PDX.drawCustomKeybinds()
            PDX.drawHudOrder()

        -- ──────────────────────────────────────────────────────────────
        -- TAB 3: FVR & GOV
        -- ──────────────────────────────────────────────────────────────
        elseif mainWin.tab == 3 then
            imgui.TextColored(colors.accent, fa.ICON_FA_CAR .. " SETARI FVR (/afvr & /sfvr)")
            imgui.Separator()
            imgui.Spacing()

            local cb_fvrR = new.bool(cfg.fvr.enableR == 1)
            if imgui.Checkbox("Trimite anunt si pe /r inainte de /d", cb_fvrR) then
                cfg.fvr.enableR = cb_fvrR[0] and 1 or 0; saveCfg()
            end

            imgui.PushItemWidth(-1)
            imgui.Text(string.format("Text anunt /r (%d/125 chr):", #ffi.string(buf_fvrR)))
            imgui.InputText("##fvrR", buf_fvrR, ffi.sizeof(buf_fvrR))
            imgui.Text(string.format("Text anunt /d Start (%d/125 chr):", #ffi.string(buf_fvrD)))
            imgui.InputText("##fvrD", buf_fvrD, ffi.sizeof(buf_fvrD))
            imgui.Text(string.format("Text anunt /d Final (%d/125 chr):", #ffi.string(buf_fvrF)))
            imgui.InputText("##fvrF", buf_fvrF, ffi.sizeof(buf_fvrF))
            imgui.Text(string.format("Text anunt /d Stop (%d/125 chr):", #ffi.string(buf_fvrStop)))
            imgui.InputText("##fvrStop", buf_fvrStop, ffi.sizeof(buf_fvrStop))
            imgui.PopItemWidth()

            imgui.Text("Secunde asteptare:")
            imgui.SameLine()
            imgui.PushItemWidth(80)
            imgui.InputText("##fvrSec", buf_fvrSec, ffi.sizeof(buf_fvrSec), imgui.InputTextFlags.CharsDecimal)
            imgui.PopItemWidth()

            imgui.SameLine(0, 16)
            PushButtonColors(colors.green, colors.greenHover)
            if imgui.Button(fa.ICON_FA_SAVE .. " SALVEAZA FVR", imgui.ImVec2(150, 28)) then
                cfg.fvr.fvrR    = ffi.string(buf_fvrR)
                cfg.fvr.fvrD    = ffi.string(buf_fvrD)
                cfg.fvr.fvrF    = ffi.string(buf_fvrF)
                cfg.fvr.fvrStop = ffi.string(buf_fvrStop)
                cfg.fvr.secunde = math.max(1, tonumber(ffi.string(buf_fvrSec)) or 10)
                saveCfg()
                addNotification("Setarile FVR au fost salvate!", "saved")
            end
            imgui.PopStyleColor(3)

            imgui.SameLine()
            PushButtonColors(colors.royal, colors.royalHover)
            if imgui.Button(fa.ICON_FA_PLAY .. " Porneste FVR (/afvr)", imgui.ImVec2(175, 28)) then
                startFvrSequence()
            end
            imgui.PopStyleColor(3)

            imgui.SameLine()
            PushButtonColors(colors.red, colors.redHover)
            if imgui.Button(fa.ICON_FA_STOP .. " Stop (/sfvr)", imgui.ImVec2(120, 28)) then
                stopFvrSequence()
            end
            imgui.PopStyleColor(3)

            imgui.Spacing()
            imgui.Spacing()
            imgui.TextColored(colors.accent, fa.ICON_FA_BULLHORN .. " SETARI ANUNTURI RECRUTARE /GOV (/pdgov)")
            imgui.Separator()
            imgui.Spacing()

            imgui.Text(string.format("Linia 1 /gov (%d/123 chr):", #ffi.string(buf_gov1)))
            imgui.PushItemWidth(-1)
            imgui.InputText("##gov1", buf_gov1, ffi.sizeof(buf_gov1))
            imgui.PopItemWidth()

            local cb_g2 = new.bool(cfg.gov.l1 == 1)
            if imgui.Checkbox(string.format("Activeaza Linia 2 /gov (%d/123 chr)##cbg2", #ffi.string(buf_gov2)), cb_g2) then
                cfg.gov.l1 = cb_g2[0] and 1 or 0; saveCfg()
            end
            imgui.PushItemWidth(-1)
            imgui.InputText("##gov2", buf_gov2, ffi.sizeof(buf_gov2))
            imgui.PopItemWidth()

            local cb_g3 = new.bool(cfg.gov.l2 == 1)
            if imgui.Checkbox(string.format("Activeaza Linia 3 /gov (%d/123 chr)##cbg3", #ffi.string(buf_gov3)), cb_g3) then
                cfg.gov.l2 = cb_g3[0] and 1 or 0; saveCfg()
            end
            imgui.PushItemWidth(-1)
            imgui.InputText("##gov3", buf_gov3, ffi.sizeof(buf_gov3))
            imgui.PopItemWidth()

            PushButtonColors(colors.green, colors.greenHover)
            if imgui.Button(fa.ICON_FA_SAVE .. " SALVEAZA GOV", imgui.ImVec2(170, 28)) then
                cfg.gov.gov1 = ffi.string(buf_gov1)
                cfg.gov.gov2 = ffi.string(buf_gov2)
                cfg.gov.gov3 = ffi.string(buf_gov3)
                saveCfg()
                addNotification("Liniile /gov au fost salvate!", "saved")
            end
            imgui.PopStyleColor(3)

            imgui.SameLine()
            PushButtonColors(colors.royal, colors.royalHover)
            if imgui.Button(fa.ICON_FA_PAPER_PLANE .. " Trimite /PDgov Acum", imgui.ImVec2(190, 28)) then
                cfg.gov.gov1 = ffi.string(buf_gov1)
                cfg.gov.gov2 = ffi.string(buf_gov2)
                cfg.gov.gov3 = ffi.string(buf_gov3)
                saveCfg()
                sendPdGov()
            end
            imgui.PopStyleColor(3)

        -- ──────────────────────────────────────────────────────────────
        -- TAB 4: COMENZI CUSTOM & COMANDA GHID
        -- ──────────────────────────────────────────────────────────────
        elseif mainWin.tab == 4 then
            imgui.TextColored(colors.accent, fa.ICON_FA_SLIDERS_H .. " COMANDA PRINCIPALA GHID COMENZI")
            imgui.Separator()
            imgui.Spacing()

            imgui.Text("Comanda meniu ghid (fara '/'):")
            imgui.SameLine()
            imgui.PushItemWidth(140)
            imgui.InputText("##mainCmdInp", buf_cmd, ffi.sizeof(buf_cmd))
            imgui.PopItemWidth()
            imgui.SameLine()
            PushButtonColors(colors.royal, colors.royalHover)
            if imgui.Button("SETEAZA COMANDA", imgui.ImVec2(160, 28)) then
                local newC = ffi.string(buf_cmd):gsub("^/+", ""):gsub("%s+", "")
                if newC ~= "" then
                    if cfg.cmd.cmd ~= "" then pcall(sampUnregisterChatCommand, cfg.cmd.cmd) end
                    cfg.cmd.cmd = newC
                    sampRegisterChatCommand(newC, function() openGuideTab("") end)
                    saveCfg()
                    msg("Comanda {28AFE0}/" .. newC .. "{FFFFFF} a fost setata pt ghidul de comenzi!")
                    addNotification("Comanda setata: /" .. newC, "saved")
                end
            end
            imgui.PopStyleColor(3)

            imgui.Spacing()
            imgui.TextColored(colors.accent, fa.ICON_FA_TERMINAL .. " COMENZI CUSTOM PERSONALIZATE (ARGUMENTE DINAMICE)")
            imgui.SameLine()
            imgui.Checkbox("Arata Variabile##showVars", showCustomVarsHelp)
            imgui.Separator()

            if showCustomVarsHelp[0] then
                imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.09, 0.13, 0.20, 0.92))
                if imgui.BeginChild("##customVarsLegend", imgui.ImVec2(0, 88), true, imgui.WindowFlags.NoScrollbar) then
                    imgui.TextColored(colors.gold, "%s", "VARIABILE PENTRU /comanda <id/nume> [text]:")
                    imgui.TextColored(colors.accent, "<Nume (ID)>")
                    imgui.SameLine(0, 4); imgui.TextDisabled("Kelton (12) |")
                    imgui.SameLine(0, 6); imgui.TextColored(colors.accent, "<Nume>")
                    imgui.SameLine(0, 4); imgui.TextDisabled("Kelton |")
                    imgui.SameLine(0, 6); imgui.TextColored(colors.accent, "<ID>")
                    imgui.SameLine(0, 4); imgui.TextDisabled("12 |")
                    imgui.SameLine(0, 6); imgui.TextColored(colors.accent, "<Nivel>")
                    imgui.SameLine(0, 4); imgui.TextDisabled("nivelul lui |")
                    imgui.SameLine(0, 6); imgui.TextColored(colors.accent, "<Rest>")
                    imgui.SameLine(0, 4); imgui.TextDisabled("textul de dupa ID")

                    imgui.TextColored(colors.accent, "<Apropiat>")
                    imgui.SameLine(0, 4); imgui.TextDisabled("cel mai apropiat Nume (ID) |")
                    imgui.SameLine(0, 6); imgui.TextColored(colors.accent, "<ApropiatID>")
                    imgui.SameLine(0, 4); imgui.TextDisabled("ID apropiat |")
                    imgui.SameLine(0, 6); imgui.TextColored(colors.accent, "<Text>")
                    imgui.SameLine(0, 4); imgui.TextDisabled("tot arg |")
                    imgui.SameLine(0, 6); imgui.TextColored(colors.accent, "<Eu> <MyID> <Dept>")

                    imgui.TextDisabled("Exemplu:  /salp  ->  Salut <Nume (ID)>! Stai pe loc! | /punish <ID>   (foloseste ' | ' pt 2 comenzi la rand)")
                end
                imgui.EndChild()
                imgui.PopStyleColor()
            end

            PushButtonColors(colors.green, colors.greenHover)
            if imgui.Button(fa.ICON_FA_SAVE .. " SALVEAZA & ACTIVEAZA COMENZILE CUSTOM", imgui.ImVec2(-1, 30)) then
                for i = 1, CUSTOM_CMD_MAX do
                    local oldCmd = tostring(cfg.comenzi["cmd" .. i] or ""):gsub("^/+", "")
                    if oldCmd ~= "" then pcall(sampUnregisterChatCommand, oldCmd) end

                    local newCmd = ffi.string(customCmdBuffers[i].cmd):gsub("^/+", ""):gsub("%s+", "")
                    local newTxt = ffi.string(customCmdBuffers[i].text)
                    cfg.comenzi["cmd" .. i] = newCmd
                    cfg.comenzi["txt" .. i] = newTxt

                    if cfg.settings.cp == 1 and cfg.comenzi["en" .. i] == 1 and newCmd ~= "" then
                        local slot = i
                        sampRegisterChatCommand(newCmd, function(arg)
                            executeCustomCommandSlot(slot, arg)
                        end)
                    end
                end
                saveCfg()
                addNotification("Comenzile custom au fost salvate!", "saved")
            end
            imgui.PopStyleColor(3)
            imgui.Spacing()

            for i = 1, CUSTOM_CMD_MAX do
                local cbC = new.bool(cfg.comenzi["en" .. i] == 1)
                if imgui.Checkbox("##cc_chk_" .. i, cbC) then
                    cfg.comenzi["en" .. i] = cbC[0] and 1 or 0
                end
                imgui.SameLine(0, 6)
                imgui.TextColored(colors.textMuted, "%s", string.format("#%02d", i))
                imgui.SameLine(0, 6)
                imgui.TextColored(colors.accent, "/")
                imgui.SameLine(0, 2)
                imgui.PushItemWidth(115)
                imgui.InputTextWithHint("##cc_name_" .. i, "cmd" .. i, customCmdBuffers[i].cmd, ffi.sizeof(customCmdBuffers[i].cmd))
                imgui.PopItemWidth()
                imgui.SameLine()
                imgui.TextDisabled("->")
                imgui.SameLine()
                imgui.PushItemWidth(-72)
                imgui.InputTextWithHint("##cc_txt_" .. i, "Ex: Salut <Nume (ID)>! | /punish <ID>", customCmdBuffers[i].text, ffi.sizeof(customCmdBuffers[i].text))
                imgui.PopItemWidth()
                imgui.SameLine()
                PushButtonColors(colors.accent, colors.accentHover)
                imgui.PushStyleColor(imgui.Col.Text, colors.dark)
                if imgui.Button("+##cc_add_" .. i, imgui.ImVec2(28, 26)) then
                    imgui.OpenPopup("##varpop_" .. i)
                end
                imgui.PopStyleColor(4)
                if imgui.BeginPopup("##varpop_" .. i) then
                    PDX.drawVarPicker(i)
                    imgui.EndPopup()
                end
                imgui.SameLine()
                PushButtonColors(colors.red, colors.redHover)
                if imgui.Button("X##cc_clr_" .. i, imgui.ImVec2(28, 26)) then
                    safeCopyBuf(customCmdBuffers[i].cmd, "")
                    safeCopyBuf(customCmdBuffers[i].text, "")
                    cfg.comenzi["en" .. i] = 0
                end
                imgui.PopStyleColor(3)
            end

            imgui.Spacing()
            PushButtonColors(colors.green, colors.greenHover)
            if imgui.Button(fa.ICON_FA_PLUS .. " Adauga comanda custom##addCmdSlot", imgui.ImVec2(230, 28)) then
                PDX.addCustomCmdSlot()
            end
            imgui.PopStyleColor(3)
            imgui.SameLine()
            imgui.TextDisabled("%s", string.format("%d / 100 sloturi", CUSTOM_CMD_MAX))

        -- ──────────────────────────────────────────────────────────────
        -- TAB 5: GHID COMPLET COMENZI (Searchable)
        -- ──────────────────────────────────────────────────────────────
        elseif mainWin.tab == 5 then
            imgui.PushItemWidth(-1)
            imgui.InputTextWithHint("##searchCmdMain", fa.ICON_FA_SEARCH .. " Cauta orice comanda PD, Radar, Wanted sau Scurtatura...", buf_cmdSearch, ffi.sizeof(buf_cmdSearch))
            imgui.PopItemWidth()
            imgui.Spacing()

            local q = ffi.string(buf_cmdSearch):lower()
            local showRoads = isRutieraActive()
            local ALL_GUIDE_GROUPS = {
                {
                    cat = "GENERAL & MENIURI DEPARTAMENTE",
                    items = {
                        { "/pdc",                "Deschide panoul principal de configurare " .. getFaction() .. " Assist" },
                        { "/san [id]",           "Deschide meniul modern de Sanctiuni, Wanted & Controale" },
                        { "/reguli | /pdrules",  "Deschide Regulamentele Oficiale B-Zone (Departamente, PD, FBI, NG)" },
                        { "/pdbl",               "Deschide Personal Blacklist (lista privata + overlay pe ecran)" },
                        { "/pdupdate",           "Verifica / instaleaza ultima versiune PDAssist de pe GitHub" },
                        { "/blpos",             "Muta lista Personal Blacklist de pe ecran cu mouse-ul" },
                        { "/roata",              "Roata de interactiune. Sofer: Eject / Cuff / Uncuff. Pe jos: Interact -> jucator -> Frisk / Confisca / Wanted / Sanctiuni / Find / Licente (+ Cuff / Punish in Jail)" },
                        { "/dt | /hdt",          "/pin + /duty  |  /pin + /duty + /heal" },
                        { "/cuff <id> | /uncuff [id]", "Incatuseaza + seteaza auto-arrest | Scoate / opreste auto-arrest" },
                        { "/afvr | /sfvr",       "Porneste / anuleaza secventa automata de FVR" },
                        { "/pdgov",              "Trimite liniile configurate pe /gov" },
                        { "/hudpos | /resethud", "Muta HUD-ul cu mouse-ul | Reseteaza pozitia HUD" },
                    }
                },
            }
            if showRoads then
                table.insert(ALL_GUIDE_GROUPS, {
                    cat = "PD ROADS & RADAR",
                    items = {
                        { "/ll",                     "Intreaba pe /d daca zona de radar e libera (x1, x2, x3 + timer 10s)" },
                        { "/potls /potlv /potsf",    "Cere acord pe /d pentru amplasare radar in alt oras (+ timer 10s)" },
                        { "/patls /patlv /patsf",    "Cere acord pe /d pentru patrulare in alt oras (+ timer 10s)" },
                        { "/startradar <lim> | /sto","Porneste radarul cu limita data | Opreste radarul" },
                        { "/last",                   "Afiseaza ultimii 5 jucatori surprinsi pe radar" },
                        { "/sl | /sl <id>",          "Sanctioneaza automat ultimul vitezoman sau unul din ultimii 5" },
                    }
                })
                table.insert(ALL_GUIDE_GROUPS, {
                    cat = "SANCTIUNI TRAFIC & PERMIS",
                    items = {
                        { "/aa <id>",     "Amenda depasire limita viteza (10-50 km/h)" },
                        { "/aa50 <id>",   "Depasire viteza +50 km/h (tine cont de nivel & jail)" },
                        { "/aa100 <id>",  "Depasire viteza +100 km/h (tine cont de nivel & jail)" },
                        { "/faruri <id>", "Amenda faruri stinse" },
                        { "/car <id>",    "Amenda mers pe partea carosabila" },
                        { "/alc15 <id>",  "Amenda alcoolemie peste 1.5" },
                        { "/alc30 <id>",  "Sanctiune alcoolemie peste 3.0 (nivel & jail)" },
                        { "/nos <id>",    "Sanctiune folosire NOS (nivel & jail)" },
                        { "/con <id>",    "Sanctiune mers pe contra-sens (nivel & jail)" },
                        { "/parc <id>",   "Sanctiune parcare neregulamentara (nivel & jail)" },
                        { "/hidra <id>",  "Sanctiune hidraulice (nivel & jail)" },
                    }
                })
            end
            table.insert(ALL_GUIDE_GROUPS, {
                cat = "CONFISCARI ARME, DROGURI & MATERIALE",
                items = {
                    { "/arme <id>",    "Confisca armele la vedere (/confiscate weapons)" },
                    { "/dr | /cdr <id>","Confisca droguri posesie / consum + reminder /wdr" },
                    { "/matslic <id>", "Materiale fara licenta (confisca + amenda)" },
                    { "/mats <id>",    "Folosire materiale (nivel 5-7 / 8-20 / 21+)" },
                }
            })
            table.insert(ALL_GUIDE_GROUPS, {
                cat = "NG / FBI / SWAT & ACORDARE AUTOMATA WANTED (/su)",
                items = {
                    { "/ps <id/nume>", "Aplica rapid /punish jucatorului din Jail (dupa ID sau nume)" },
                    { "/jc",           "Lista din /jaillist cu celula in care e fiecare" },
                    { "/nec <id>",     "Acorda Wanted automat: Neconformare ordin" },
                    { "/run <id>",     "Acorda Wanted automat: Runner" },
                    { "/nef <id>",     "Acorda Wanted automat: Apel nefondat" },
                    { "// <id>",       "Anunta pe /d 'Ii voi da nefondat lui <Nume> (ID)'" },
                    { "/bm <id>",      "Confisca bombele + mesaj + Wanted 3" },
                    { "/ms [id]",      "Somatie. Cu ID: daca nu ai /find pe el, ii da /find intai" },
                    { "/cat <id>",     "Acorda Wanted automat: Cop Attack" },
                    { "/notp <id>",    "Acorda Wanted automat: Neplata amenda" },
                    { "/comp <id>",    "Acorda Wanted automat: Complice" },
                    { "/wdr <id>",     "Acorda Wanted automat: Posesie / folosire droguri" },
                    { "/mm <id>",      "Someaza suspectul cu wanted pe /m sa traga pe dreapta (+ timer 3s)" },
                    { "/cl <id>",      "Control de rutina + /frisk <id>" },
                    { "/rl <id>",      "Trimite /requestlicenses <id>" },
                    { "/tg <id>",      "Someaza jucatorul sa paraseasca Teritoriul Guvernamental" },
                    { "/afk [id] | /ffk [id]",       "AFK cu clepsidra 3 min | fara clepsidra 30s (fara ID = suspectul de pe /find). Din nou = a revenit" },
                    { "/stopafk",                    "Opreste numaratoarea AFK fara anunt" },
                    { "/scasa /slspd /slvpd /ssfpd /sfbi /sjail", "Schimba spawn-ul direct (/spawnchange + alegere automata)" },
                    { "/hqf | /hqng",                "Spawn in HQ-ul factiunii tale | Spawn in garajul (parcarea) HQ National Guard" },
                    { "/sclan /sbunker",             "Spawn la HQ Clan / Bunker" },
                }
            })
            table.insert(ALL_GUIDE_GROUPS, {
                cat = "COMENZI PRESCURTATE UZUALE",
                items = {
                    { "/fd <id/nume> | /cf | /kc", "/id + /find  |  /cancel find  |  /killcp" },
                    { "/shb | /shu | /shr",        "/shield buy  |  /shield use  |  /shield remove" },
                    { "/rr | /rep | /ref",         "/repair + /refill  |  /repair  |  /refill" },
                    { "/at <id> | /ct | /acp",     "/accept ticket  |  /cancel ticket  |  /acceptpoints" },
                    { "/mb | /cmb | /ra | /st",    "/members  |  /clanmembers  |  /raport  |  /stats" },
                    { "/jl",                       "/jaillist" },
                    { "/ha | /sa | /sp | /en",     "/heal  |  /stopanim  |  /spawnchange  |  /engine" },
                    { "/bg <arma> <gl> | /gk <id>","/buygun  |  /givekey" },
                    { "/sal | /nb | /cch",         "Salut / Noapte buna pe /r si /ac  |  Curata chatul" },
                    { "/ton | /toff | /not | /missm | /missc", "Telefon on/off, notificari, apeluri/sms pierdute" },
                }
            })

            for _, grp in ipairs(ALL_GUIDE_GROUPS) do
                local anyVisible = false
                for _, it in ipairs(grp.items) do
                    if q == "" or it[1]:lower():find(q, 1, true) or it[2]:lower():find(q, 1, true) then
                        anyVisible = true
                        break
                    end
                end
                if anyVisible then
                    imgui.TextColored(colors.gold, "%s", "[ " .. grp.cat .. " ]")
                    imgui.Separator()
                    for _, it in ipairs(grp.items) do
                        if q == "" or it[1]:lower():find(q, 1, true) or it[2]:lower():find(q, 1, true) then
                            imgui.TextColored(colors.accent, "%s", it[1])
                            imgui.SameLine(255)
                            imgui.TextWrapped("%s", "- " .. it[2])
                        end
                    end
                    imgui.Spacing()
                end
            end

        -- ──────────────────────────────────────────────────────────────
        -- TAB 8: CONT & PIN (login + PIN automat)
        -- ──────────────────────────────────────────────────────────────
        elseif mainWin.tab == 8 then
            PDX.drawAccountTab()

        -- ──────────────────────────────────────────────────────────────
        -- TAB 9: ASPECT (culori HUD + notificari, preview)
        -- ──────────────────────────────────────────────────────────────
        elseif mainWin.tab == 9 then
            PDX.drawLookTab()

        -- ──────────────────────────────────────────────────────────────
        -- TAB 10: ROATA PERSONALIZATA (elemente + submeniuri proprii)
        -- ──────────────────────────────────────────────────────────────
        elseif mainWin.tab == 10 then
            PDX.drawWheelEditor()
        end

        imgui.EndChild()

        -- Bottom Action Bar
        PushButtonColors(colors.royal, colors.royalHover)
        if imgui.Button(fa.ICON_FA_GAVEL .. " SANCTIUNI (/san)", imgui.ImVec2(185, 32)) then
            openAnimWin(sanWin)
        end
        imgui.PopStyleColor(3)

        imgui.SameLine()
        PushButtonColors(colors.gold, colors.goldHover)
        imgui.PushStyleColor(imgui.Col.Text, colors.dark)
        if imgui.Button(fa.ICON_FA_BALANCE_SCALE .. " REGULAMENTE (/reguli)", imgui.ImVec2(215, 32)) then
            openRulesWindow(false)
        end
        imgui.PopStyleColor(4)

        imgui.SameLine()
        PushButtonColors(colors.cardBg, colors.cardHover)
        if imgui.Button(fa.ICON_FA_USER_SLASH .. " BLACKLIST (/pdbl)", imgui.ImVec2(175, 32)) then
            openAnimWin(blWin)
        end
        imgui.PopStyleColor(3)

        local rightW = 165
        imgui.SameLine(imgui.GetWindowWidth() - rightW - 18)
        PushButtonColors(colors.red, colors.redHover)
        if imgui.Button(fa.ICON_FA_POWER_OFF .. " OPRESTE MODUL", imgui.ImVec2(rightW, 32)) then
            msg("Modul s-a oprit. Apasa {28AFE0}CTRL+R{FFFFFF} sau reconecteaza-te pt repornire.")
            thisScript():unload()
        end
        imgui.PopStyleColor(3)

        imgui.End()
        imgui.PopStyleVar()
    end
)

-- =========================================================================================
--  SECTION 11: INTERACTIVE SANCTIONS, WANTED & FIELD CONTROLS MENU (/san & Key K)
-- =========================================================================================
imgui.OnFrame(
    function() return sanWin.visible end,
    function() updateAnimWin(sanWin) end,
    function(self)
        self.HideCursor = false
        if sanWin.alpha <= 0.001 then return end

        local sw, sh = getScreenResCached()
        local yAnim  = (1.0 - sanWin.alpha) * 14.0
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, sanWin.alpha)
        imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5 + yAnim), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(720, 510), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSizeConstraints(imgui.ImVec2(640, 440), imgui.ImVec2(920, 760))

        imgui.Begin("##PDSanctionsWin", sanWin.open, imgui.WindowFlags.NoTitleBar)
        if not sanWin.open[0] then
            sanWin.open[0] = true
            closeAnimWin(sanWin)
        end
        if imgui.IsWindowFocused(imgui.FocusedFlags.RootAndChildWindows) and imgui.IsKeyPressed(vkeys.VK_ESCAPE) then
            closeAnimWin(sanWin)
        end

        drawModernHeader(fa.ICON_FA_GAVEL, getFaction() .. " SANCTIUNI", "ACTIUNI RAPIDE TEREN (/san)", function() closeAnimWin(sanWin) end, "closeSan")

        -- Target Player Bar (LSSI Helper Target Card Style!)
        imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.09, 0.12, 0.18, 0.95))
        if imgui.BeginChild("##sanTargetBar", imgui.ImVec2(0, 78), true, imgui.WindowFlags.NoScrollbar) then
            local tIdNum = tonumber(ffi.string(buf_sanId))
            local online = tIdNum and isPlayerOnline(tIdNum)
            local pName  = online and getPlayerNameSafe(tIdNum) or nil
            local pLvl   = (online and tIdNum) and sampGetPlayerScore(tIdNum) or 0

            imgui.TextColored(colors.accent, fa.ICON_FA_USER_SHIELD .. " SUSPECT SELECTAT:")
            imgui.SameLine()
            if online and pName then
                imgui.TextColored(colors.green, "%s", u8(string.format("%s [ID: %d | Nivel: %d]", pName, tIdNum, pLvl)))
            else
                imgui.TextDisabled("Introdu un ID valid mai jos sau alege din Radar / Apropiere")
            end

            if isInJailInterior() then
                imgui.SameLine(imgui.GetWindowWidth() - 155)
                imgui.TextColored(colors.gold, "[ IN JAIL: FARA TICKET ]")
            end

            imgui.Text("ID Jucator:")
            imgui.SameLine()
            imgui.PushItemWidth(80)
            imgui.InputText("##sanTargetInp", buf_sanId, ffi.sizeof(buf_sanId), imgui.InputTextFlags.CharsDecimal)
            imgui.PopItemWidth()

            -- Quick pick buttons: Last Radar (only if Rutiera active) + Closest Player
            imgui.SameLine()
            if isRutieraActive() and cfg.radar.lastid and cfg.radar.lastid >= 0 then
                PushButtonColors(colors.gold, colors.goldHover)
                imgui.PushStyleColor(imgui.Col.Text, colors.dark)
                if imgui.Button(fa.ICON_FA_TACHOMETER_ALT .. " Ultimul Radar (" .. cfg.radar.lastid .. ")", imgui.ImVec2(165, 26)) then
                    safeCopyBuf(buf_sanId, tostring(cfg.radar.lastid))
                end
                imgui.PopStyleColor(4)
                imgui.SameLine()
            end

            if PDX.find.active and PDX.find.id >= 0 then
                PushButtonColors(colors.green, colors.greenHover)
                if imgui.Button(fa.ICON_FA_MAP_MARKER_ALT .. " Suspect /find (" .. PDX.find.id .. ")", imgui.ImVec2(165, 26)) then
                    safeCopyBuf(buf_sanId, tostring(PDX.find.id))
                end
                imgui.PopStyleColor(3)
                imgui.SameLine()
            end

            PushButtonColors(colors.cardBg, colors.cardHover)
            if imgui.Button(fa.ICON_FA_STREET_VIEW .. " Cel mai apropiat jucator", imgui.ImVec2(185, 26)) then
                local px, py, pz = getCharCoordinates(PLAYER_PED)
                local bestId, bestDist = nil, 50.0
                for pid = 0, 999 do
                    if sampIsPlayerConnected(pid) then
                        local ok, ped = sampGetCharHandleBySampPlayerId(pid)
                        if ok and doesCharExist(ped) and ped ~= PLAYER_PED then
                            local tx, ty, tz = getCharCoordinates(ped)
                            local d = getDistanceBetweenCoords3d(px, py, pz, tx, ty, tz)
                            if d < bestDist then
                                bestDist = d
                                bestId = pid
                            end
                        end
                    end
                end
                if bestId then
                    safeCopyBuf(buf_sanId, tostring(bestId))
                else
                    msg("Niciun jucator in apropiere!")
                end
            end
            imgui.PopStyleColor(3)

            imgui.SameLine()
            PushButtonColors(colors.royal, colors.royalHover)
            if imgui.Button(fa.ICON_FA_SEARCH_LOCATION .. " /fd", imgui.ImVec2(65, 26)) then
                if tIdNum then say("/id " .. tIdNum); say("/find " .. tIdNum) end
            end
            imgui.PopStyleColor(3)

            imgui.EndChild()
        end
        imgui.PopStyleColor()

        -- Sub-tabs: 1 = Trafic & Licente (only when Rutiera active), 2 = Arme / Droguri / Mats, 3 = Wanted (/su) & Controale
        local showRoadsSan = isRutieraActive()
        if not showRoadsSan and sanWin.subTab == 1 then
            sanWin.subTab = 3
        end
        local subTabs = {}
        if showRoadsSan then
            table.insert(subTabs, { id = 1, name = fa.ICON_FA_CAR .. " TRAFIC & PERMIS" })
        end
        table.insert(subTabs, { id = 2, name = fa.ICON_FA_BOX_OPEN .. " ARME, DROGURI & MATS" })
        table.insert(subTabs, { id = 3, name = fa.ICON_FA_EXCLAMATION_TRIANGLE .. " WANTED (/SU) & CONTROALE" })
        local stW = (imgui.GetContentRegionAvail().x - (#subTabs - 1) * 8) / #subTabs
        for i, st in ipairs(subTabs) do
            local act = (sanWin.subTab == st.id)
            if act then
                PushButtonColors(colors.accent, colors.accentHover)
                imgui.PushStyleColor(imgui.Col.Text, colors.dark)
            else
                PushButtonColors(colors.accentDim, imgui.ImVec4(0.16, 0.69, 0.88, 0.25))
                imgui.PushStyleColor(imgui.Col.Text, colors.accent)
            end
            imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 14)
            if imgui.Button(st.name, imgui.ImVec2(stW, 30)) then sanWin.subTab = st.id end
            imgui.PopStyleVar()
            imgui.PopStyleColor(4)
            if i < #subTabs then imgui.SameLine(0, 8) end
        end

        imgui.Spacing()
        imgui.BeginChild("##sanActionsBody", imgui.ImVec2(0, 0), true)

        local curId = tonumber(ffi.string(buf_sanId))
        local colW  = (imgui.GetContentRegionAvail().x - 10) * 0.5

        if sanWin.subTab == 1 and showRoadsSan then
            imgui.TextColored(colors.gold, "%s", "VITEZA & RADAR (Zona: " .. tostring(cfg.radar.zona) .. " | Limita: " .. tostring(cfg.radar.limita) .. " km/h)")
            imgui.Separator()

            PushButtonColors(colors.royal, colors.royalHover)
            if imgui.Button(fa.ICON_FA_BOLT .. " Sanctiune Automata Radar (/sl pe ID)", imgui.ImVec2(-1, 32)) then
                if curId then executeRadarSl(tostring(curId)) else executeRadarSl("") end
            end
            imgui.PopStyleColor(3)

            local trafficBtns = {
                { "Depasire Viteza 10-50 km/h (/aa)",     function() sanctionDirect("aa", curId) end,         colors.cardBg, colors.cardHover },
                { "Depasire Viteza +50 km/h (/aa50)",     function() sanctionWithIdCheck("aa50", curId) end,  colors.cardBg, colors.cardHover },
                { "Depasire Viteza +100 km/h (/aa100)",   function() sanctionWithIdCheck("aa100", curId) end, colors.red,    colors.redHover  },
                { "Faruri Stinse (/faruri)",              function() sanctionDirect("faruri", curId) end,     colors.cardBg, colors.cardHover },
                { "Mers pe Carosabil (/car)",             function() sanctionDirect("car", curId) end,        colors.cardBg, colors.cardHover },
                { "Alcoolemie > 1.5 (/alc15)",            function() sanctionDirect("alc15", curId) end,      colors.cardBg, colors.cardHover },
                { "Alcoolemie > 3.0 (/alc30)",            function() sanctionWithIdCheck("alc30", curId) end, colors.cardBg, colors.cardHover },
                { "Folosire NOS (/nos)",                  function() sanctionWithIdCheck("nos", curId) end,   colors.cardBg, colors.cardHover },
                { "Mers pe Contra-Sens (/con)",           function() sanctionWithIdCheck("con", curId) end,   colors.cardBg, colors.cardHover },
                { "Parcare Ilegala (/parc)",              function() sanctionWithIdCheck("parc", curId) end,  colors.cardBg, colors.cardHover },
                { "Hidraulice (/hidra)",                  function() sanctionWithIdCheck("hidra", curId) end, colors.cardBg, colors.cardHover },
            }
            for idx, b in ipairs(trafficBtns) do
                PushButtonColors(b[3], b[4])
                if imgui.Button(b[1], imgui.ImVec2(colW, 32)) then b[2]() end
                imgui.PopStyleColor(3)
                if idx % 2 == 1 and idx < #trafficBtns then imgui.SameLine(0, 10) end
            end

        elseif sanWin.subTab == 2 then
            imgui.TextColored(colors.gold, "CONFISCARI ARME, DROGURI & MATERIALE")
            imgui.Separator()

            local itemBtns = {
                { fa.ICON_FA_CROSSHAIRS .. " Arme la Vedere (/arme)",         function() sanctionDirect("arme", curId) end },
                { fa.ICON_FA_CANNABIS .. " Posesie Droguri (/dr)",            function() sanctionDirect("dr", curId) end },
                { fa.ICON_FA_BONG .. " Consum Droguri (/cdr)",                function() sanctionDirect("cdr", curId) end },
                { fa.ICON_FA_EXCLAMATION_CIRCLE .. " Wanted 3 Droguri (/wdr)",function() queueAutoSu(curId, 5, "Droguri") end },
                { fa.ICON_FA_BOMB .. " Bombe + Wanted 3 (/bm)",             function() PDX.bombs(curId) end },
            }
            if showRoadsSan then
                table.insert(itemBtns, { fa.ICON_FA_BOX .. " Materiale Fara Licenta (/matslic)", function() sanctionDirect("matslic", curId) end })
            end
            table.insert(itemBtns, { fa.ICON_FA_CUBES .. " Folosire Materiale (/mats)", function() sanctionWithIdCheck("mats", curId) end })
            for idx, b in ipairs(itemBtns) do
                PushButtonColors(colors.cardBg, colors.cardHover)
                if imgui.Button(b[1], imgui.ImVec2(colW, 36)) then b[2]() end
                imgui.PopStyleColor(3)
                if idx % 2 == 1 and idx < #itemBtns then imgui.SameLine(0, 10) end
            end

        elseif sanWin.subTab == 3 then
            imgui.TextColored(colors.gold, "ACORDARE AUTOMATA WANTED (/SU)")
            imgui.Separator()

            local wantedBtns = {
                { "Neconformare Ordin (/nec)",  2,  "Neconformare ordin" },
                { "Runner (/run)",              12, "Runner" },
                { "Apel Nefondat (/nef)",       1,  "Nefondat" },
                { "Cop Attack (/cat)",          6,  "Cop Attack" },
            }
            if showRoadsSan then
                table.insert(wantedBtns, { "Neplata Amenda (/notp)", 7, "Neplata amenda" })
            end
            table.insert(wantedBtns, { "Complice (/comp)",          13, "Complice" })
            table.insert(wantedBtns, { "Posesie/Uz Droguri (/wdr)", 5,  "Droguri" })
            for idx, wb in ipairs(wantedBtns) do
                PushButtonColors(colors.red, colors.redHover)
                if imgui.Button(fa.ICON_FA_STAR .. " " .. wb[1], imgui.ImVec2(colW, 31)) then
                    queueAutoSu(curId, wb[2], wb[3])
                end
                imgui.PopStyleColor(3)
                if idx % 2 == 1 and idx < #wantedBtns then imgui.SameLine(0, 10) end
            end

            imgui.Spacing()
            imgui.TextColored(colors.accent, "CONTROALE, JAIL & SOMATII")
            imgui.Separator()

            local ctrlBtns = {
                { fa.ICON_FA_GAVEL .. " Punish Jail (/ps)", function()
                    if curId then executePunishCmd(tostring(curId)) else msg("Selecteaza un ID valid!") end
                end },
            }
            if showRoadsSan then
                table.insert(ctrlBtns, { fa.ICON_FA_SEARCH .. " Control Rutina (/cl)", function()
                    if curId and isPlayerOnline(curId) then
                        if PDX.blockColleague(curId, "frisk") then return end
                        local pn = getPlayerNameSafe(curId)
                        say((isRo() and ("Salut " .. pn .. "! Acesta este un control de rutina") or ("Hello " .. pn .. "! This is a routine check")) .. (friskSpamToggle and "." or ""))
                        friskSpamToggle = not friskSpamToggle
                        say("/frisk " .. curId)
                    else msg("Selecteaza un ID valid!") end
                end })
                table.insert(ctrlBtns, { fa.ICON_FA_ID_CARD .. " Request Licenses (/rl)", function()
                    if curId then say("/requestlicenses " .. curId) else msg("Selecteaza un ID valid!") end
                end })
            else
                table.insert(ctrlBtns, { fa.ICON_FA_SEARCH .. " Perchezitie (/frisk)", function()
                    if curId and isPlayerOnline(curId) then
                        if PDX.blockColleague(curId, "frisk") then return end
                        say("/frisk " .. curId)
                    else msg("Selecteaza un ID valid!") end
                end })
            end
            table.insert(ctrlBtns, { fa.ICON_FA_BULLHORN .. " Somatie Wanted (/mm + 3s)", function()
                if curId and isPlayerOnline(curId) then
                    local pn = getPlayerNameSafe(curId)
                    say("/m " .. pn .. " esti urmarit de politie, trage pe dreapta imediat!" .. (mmSpamToggle and "!" or ""))
                    mmSpamToggle = not mmSpamToggle
                    timers.mmEnd = os.clock() + 3.0
                else msg("Selecteaza un ID valid!") end
            end })
            table.insert(ctrlBtns, { fa.ICON_FA_LANDMARK .. " Teren Guvernamental (/tg)", function()
                if curId and isPlayerOnline(curId) then
                    local pn = getPlayerNameSafe(curId)
                    if isRo() then
                        say(pn .. ", te rog sa parasesti Teritoriul Guvernamental!")
                        say("Risti sa primesti Wanted 2 - 'Patrundere Teren Guvernamental'")
                    else
                        say(pn .. ", please leave the Governmental Area!")
                        say("You're putting yourself at the risk of getting Wanted 2.")
                    end
                else msg("Selecteaza un ID valid!") end
            end })
            table.insert(ctrlBtns, { fa.ICON_FA_PHONE_SLASH .. " Anunta Nefondat /d (//)", function()
                if curId and isPlayerOnline(curId) then
                    local pn = getPlayerNameSafe(curId)
                    say("/d Ii voi da nefondat lui " .. pn .. (nefSpamToggle and "" or "."))
                    nefSpamToggle = not nefSpamToggle
                else msg("Selecteaza un ID valid!") end
            end })
            table.insert(ctrlBtns, { fa.ICON_FA_USER_CLOCK .. " Anunta AFK 3m (/afk ID)", function()
                if curId and isPlayerOnline(curId) then
                    local pn = getPlayerNameSafe(curId)
                    say("/d " .. pn .. " este AFK, peste 3 minute ii voi da kill.")
                    timers.afkEnd   = os.clock() + 180.0
                    timers.afkLabel = "AFK " .. pn
                else msg("Selecteaza un ID valid!") end
            end })
            for idx, cb in ipairs(ctrlBtns) do
                PushButtonColors(colors.cardBg, colors.cardHover)
                if imgui.Button(cb[1], imgui.ImVec2(colW, 30)) then cb[2]() end
                imgui.PopStyleColor(3)
                if idx % 2 == 1 and idx < #ctrlBtns then imgui.SameLine(0, 10) end
            end
        end

        imgui.EndChild()
        imgui.End()
        imgui.PopStyleVar()
    end
)

-- =========================================================================================
--  SECTION 12: PERSONAL BLACKLIST MANAGER (/pdbl) & STANDALONE GUIDE WINDOW (/pdcmd)
-- =========================================================================================
imgui.OnFrame(
    function() return blWin.visible end,
    function() updateAnimWin(blWin) end,
    function(self)
        self.HideCursor = false
        if blWin.alpha <= 0.001 then return end

        local sw, sh = getScreenResCached()
        local yAnim  = (1.0 - blWin.alpha) * 14.0
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, blWin.alpha)
        imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5 + yAnim), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(560, 460), imgui.Cond.FirstUseEver)

        imgui.Begin("##PDBlacklistWin", blWin.open, imgui.WindowFlags.NoTitleBar)
        if not blWin.open[0] then blWin.open[0] = true; closeAnimWin(blWin) end
        if imgui.IsWindowFocused(imgui.FocusedFlags.RootAndChildWindows) and imgui.IsKeyPressed(vkeys.VK_ESCAPE) then
            closeAnimWin(blWin)
        end

        drawModernHeader(fa.ICON_FA_USER_SLASH, "PERSONAL BLACKLIST", "LISTA PRIVATA JUCATORI (/pdbl)", function() closeAnimWin(blWin) end, "closeBl")

        imgui.TextDisabled("Scrie numele jucatorului (si motivul optional). Daca e online, apare cu verde pe overlay!")
        imgui.Spacing()

        imgui.BeginChild("##blRowsChild", imgui.ImVec2(0, -48), true)
        for i = 1, 9 do
            imgui.TextColored(colors.accent, string.format("#%d", i))
            imgui.SameLine(36)
            imgui.PushItemWidth(-88)
            imgui.InputTextWithHint("##bl_row_" .. i, "NumeJucator - Motiv...", blBuffers[i], 256)
            imgui.PopItemWidth()

            imgui.SameLine()
            PushButtonColors(colors.royal, colors.royalHover)
            if imgui.Button(fa.ICON_FA_SEARCH .. "##blf_" .. i, imgui.ImVec2(32, 26)) then
                local raw = ffi.string(blBuffers[i]):match("^(%S+)")
                if raw and raw ~= "-" then say("/id " .. raw); say("/find " .. raw) end
            end
            imgui.PopStyleColor(3)

            imgui.SameLine()
            PushButtonColors(colors.red, colors.redHover)
            if imgui.Button("X##blx_" .. i, imgui.ImVec2(32, 26)) then
                safeCopyBuf(blBuffers[i], "-")
            end
            imgui.PopStyleColor(3)
        end
        imgui.EndChild()

        local function saveBlAll()
            for i = 1, 9 do
                local v = ffi.string(blBuffers[i]):gsub("^%s+", ""):gsub("%s+$", "")
                cfg.blacklist["bl" .. i] = (v == "") and "-" or v
            end
            saveCfg()
        end

        PushButtonColors(colors.accent, colors.accentHover)
        imgui.PushStyleColor(imgui.Col.Text, colors.dark)
        local pinLabel = cfg.blacklist.pinned and (fa.ICON_FA_EYE_SLASH .. " Ascunde de pe Ecran") or (fa.ICON_FA_THUMBTACK .. " Save & Keep pe Ecran")
        if imgui.Button(pinLabel, imgui.ImVec2(220, 32)) then
            saveBlAll()
            cfg.blacklist.pinned = not cfg.blacklist.pinned
            saveCfg()
            if cfg.blacklist.pinned then
                closeAnimWin(blWin)
                addNotification("Blacklist fixat pe ecran! (/pdbl pt editare)", "saved")
            else
                addNotification("Blacklist ascuns de pe ecran", "info")
            end
        end
        imgui.PopStyleColor(4)

        imgui.SameLine()
        PushButtonColors(colors.green, colors.greenHover)
        if imgui.Button(fa.ICON_FA_SAVE .. " Salveaza", imgui.ImVec2(145, 32)) then
            saveBlAll()
            addNotification("Personal Blacklist salvat!", "saved")
        end
        imgui.PopStyleColor(3)

        imgui.SameLine()
        PushButtonColors(colors.cardBg, colors.cardHover)
        if imgui.Button(fa.ICON_FA_ARROWS_ALT .. " Muta##blMove", imgui.ImVec2(95, 32)) then
            saveBlAll()
            PDX.startBlMoving()
        end
        imgui.PopStyleColor(3)

        imgui.SameLine()
        PushButtonColors(colors.cardBg, colors.cardHover)
        if imgui.Button("Inchide", imgui.ImVec2(-1, 32)) then
            closeAnimWin(blWin)
        end
        imgui.PopStyleColor(3)

        imgui.End()
        imgui.PopStyleVar()
    end
)

-- Quick Reference Dialog Window (/cmd, /com, /isan, /isu) -> opens MainWin directly on Tab 5!
local function openGuideTab(filterStr)
    if filterStr then
        safeCopyBuf(buf_cmdSearch, filterStr)
    else
        safeCopyBuf(buf_cmdSearch, "")
    end
    mainWin.tab = 5
    openAnimWin(mainWin)
end

-- =========================================================================================
--  SECTION 12B: OFFICIAL B-ZONE DEPARTMENT RULES VIEWER (/reguli & /pdrules)
-- =========================================================================================
imgui.OnFrame(
    function() return rulesWin.visible end,
    function() updateAnimWin(rulesWin) end,
    function(self)
        self.HideCursor = false
        if rulesWin.alpha <= 0.001 then return end

        local sw, sh = getScreenResCached()
        local yAnim  = (1.0 - rulesWin.alpha) * 14.0
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, rulesWin.alpha)
        imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5 + yAnim), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(920, 600), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSizeConstraints(imgui.ImVec2(760, 480), imgui.ImVec2(1200, 860))

        imgui.Begin("##PDRulesWin", rulesWin.open, imgui.WindowFlags.NoTitleBar)
        if not rulesWin.open[0] then
            rulesWin.open[0] = true
            closeAnimWin(rulesWin)
        end
        if imgui.IsWindowFocused(imgui.FocusedFlags.RootAndChildWindows) and imgui.IsKeyPressed(vkeys.VK_ESCAPE) then
            closeAnimWin(rulesWin)
        end

        local curLangKey = rulesLangOverride or (isRo() and "ro" or "en")
        local isRulesRo  = (curLangKey == "ro")

        drawModernHeader(
            fa.ICON_FA_BALANCE_SCALE,
            getFaction() .. " ASSIST",
            isRulesRo and "REGULAMENTE OFICIALE B-ZONE (/reguli)" or "B-ZONE OFFICIAL DEPARTMENT RULES (/reguli)",
            function() closeAnimWin(rulesWin) end,
            "closeRules"
        )

        if not deptRulesAll or not deptRulesAll[curLangKey] then
            imgui.TextColored(colors.redHover, "Fisierul moonloader/lib/RulesDepartments.lua nu a putut fi incarcat!")
            imgui.End()
            imgui.PopStyleVar()
            return
        end

        local ruleSets = deptRulesAll[curLangKey]
        if activeRuleSet < 1 or activeRuleSet > #ruleSets then activeRuleSet = 1 end
        local myFactionIdx = getFactionRuleSetIndex()

        -- Top Toolbar: 4 Rule Set Pill Buttons + Language Toggle + Live Search
        for i, rs in ipairs(ruleSets) do
            local isMyDept = (i == myFactionIdx)
            local btnLabel = (rs.shortTitle or rs.title)
            if isMyDept then
                btnLabel = fa.ICON_FA_STAR .. " " .. btnLabel
            end
            if activeRuleSet == i then
                PushButtonColors(colors.gold, colors.goldHover, colors.gold)
                imgui.PushStyleColor(imgui.Col.Text, colors.dark)
            else
                PushButtonColors(
                    imgui.ImVec4(colors.gold.x, colors.gold.y, colors.gold.z, isMyDept and 0.22 or 0.10),
                    imgui.ImVec4(colors.gold.x, colors.gold.y, colors.gold.z, 0.30),
                    imgui.ImVec4(colors.gold.x, colors.gold.y, colors.gold.z, 0.40)
                )
                imgui.PushStyleColor(imgui.Col.Text, colors.gold)
            end
            imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 15)
            if imgui.Button(btnLabel .. "##rset_" .. i, imgui.ImVec2(132, 32)) then
                activeRuleSet = i
                activeChapter = 1
                highlightRuleId = nil
            end
            imgui.PopStyleVar()
            imgui.PopStyleColor(4)
            imgui.SameLine(0, 6)
        end

        -- RO / EN Switch
        PushButtonColors(isRulesRo and colors.accent or colors.cardBg, colors.accentHover)
        imgui.PushStyleColor(imgui.Col.Text, isRulesRo and colors.dark or colors.textPrimary)
        if imgui.Button("RO##rlang_ro", imgui.ImVec2(40, 32)) then
            rulesLangOverride = "ro"
        end
        imgui.PopStyleColor(4)
        imgui.SameLine(0, 4)
        PushButtonColors((not isRulesRo) and colors.accent or colors.cardBg, colors.accentHover)
        imgui.PushStyleColor(imgui.Col.Text, (not isRulesRo) and colors.dark or colors.textPrimary)
        if imgui.Button("EN##rlang_en", imgui.ImVec2(40, 32)) then
            rulesLangOverride = "en"
        end
        imgui.PopStyleColor(4)

        -- Search Input
        imgui.SameLine(0, 10)
        imgui.PushItemWidth(-1)
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 12)
        imgui.InputTextWithHint(
            "##SearchDeptRules",
            fa.ICON_FA_SEARCH .. " " .. (isRulesRo and "Cauta in toate regulamentele..." or "Search all rules..."),
            buf_rulesSearch,
            ffi.sizeof(buf_rulesSearch)
        )
        imgui.PopStyleVar()
        imgui.PopItemWidth()

        local searchStr = ffi.string(buf_rulesSearch):lower():gsub("^%s+", ""):gsub("%s+$", "")
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        if searchStr ~= "" then
            imgui.BeginChild("##DeptRulesSearchResults", imgui.ImVec2(0, 0), true)
            imgui.TextColored(colors.gold, "%s", isRulesRo and "Rezultatele Cautarii (click pentru a sari la articol):" or "Search Results (click to jump to article):")
            imgui.Spacing()
            local foundCount = 0

            for rIdx, rs in ipairs(ruleSets) do
                for cIdx, ch in ipairs(rs.chapters) do
                    for aIdx, art in ipairs(ch.articles) do
                        local fullLower = (art.id .. " " .. art.text):lower()
                        if fullLower:find(searchStr, 1, true) then
                            foundCount = foundCount + 1
                            local flat = art.text:gsub("\n", " ")
                            local sPos = flat:lower():find(searchStr, 1, true)
                            local preview = flat
                            if #preview > 110 then
                                local pStart = sPos and math.max(1, sPos - 35) or 1
                                preview = (pStart > 1 and "..." or "") .. flat:sub(pStart, pStart + 105) .. "..."
                            end

                            local clicked = false
                            PushButtonColors(colors.cardBg, colors.cardHover)
                            if imgui.Button("##dres_" .. rIdx .. "_" .. cIdx .. "_" .. aIdx, imgui.ImVec2(-1, 66)) then
                                clicked = true
                            end
                            imgui.PopStyleColor(3)

                            local cPos = imgui.GetCursorPos()
                            imgui.SetCursorPos(imgui.ImVec2(cPos.x + 10, cPos.y - 58))

                            local badgeCol = (rIdx == 1) and colors.royal or colors.gold
                            local badgeTxtCol = (rIdx == 1) and colors.textPrimary or colors.dark
                            PushButtonColors(badgeCol, badgeCol, badgeCol)
                            imgui.PushStyleColor(imgui.Col.Text, badgeTxtCol)
                            if imgui.Button((rs.shortTitle or rs.title) .. "##dtag_" .. rIdx .. "_" .. cIdx .. "_" .. aIdx, imgui.ImVec2(0, 22)) then
                                clicked = true
                            end
                            imgui.PopStyleColor(4)

                            imgui.SameLine()
                            imgui.TextColored(colors.accent, "%s", ch.title .. "  |  " .. art.id)

                            imgui.SetCursorPos(imgui.ImVec2(cPos.x + 10, cPos.y - 28))
                            local mStart, mEnd = preview:lower():find(searchStr, 1, true)
                            if mStart then
                                local before = preview:sub(1, mStart - 1)
                                local mid    = preview:sub(mStart, mEnd)
                                local after  = preview:sub(mEnd + 1)
                                imgui.TextColored(colors.textMuted, "%s", before)
                                imgui.SameLine(0, 0)
                                imgui.TextColored(colors.greenHover, "%s", mid)
                                imgui.SameLine(0, 0)
                                imgui.TextColored(colors.textMuted, "%s", after)
                            else
                                imgui.TextColored(colors.textMuted, "%s", preview)
                            end

                            imgui.SetCursorPos(cPos)

                            if clicked then
                                lastRulesSearch = searchStr
                                safeCopyBuf(buf_rulesSearch, "")
                                activeRuleSet     = rIdx
                                activeChapter     = cIdx
                                highlightRuleId   = string.format("%d_%d_%d", rIdx, cIdx, aIdx)
                                highlightRuleTime = os.clock()
                            end
                            imgui.Spacing()
                        end
                    end
                end
            end

            if foundCount == 0 then
                imgui.TextColored(colors.textMuted, "%s", isRulesRo and "Niciun articol nu corespunde cautarii." or "No articles matched your search.")
            end
            imgui.EndChild()
        else
            local cRs = ruleSets[activeRuleSet]
            if activeChapter < 1 or activeChapter > #cRs.chapters then activeChapter = 1 end

            -- Left Sidebar: Chapters
            imgui.BeginChild("##DeptRulesSidebar", imgui.ImVec2(240, 0), true)
            imgui.TextColored(colors.accent, "%s", cRs.title)
            imgui.Separator()
            imgui.Spacing()
            for cIdx, ch in ipairs(cRs.chapters) do
                local sel = (activeChapter == cIdx)
                if sel then
                    imgui.PushStyleColor(imgui.Col.Text, colors.gold)
                    imgui.Selectable(ch.title .. "##ch_" .. cIdx, true)
                    imgui.PopStyleColor()
                else
                    if imgui.Selectable(ch.title .. "##ch_" .. cIdx, false) then
                        activeChapter = cIdx
                        highlightRuleId = nil
                    end
                end
            end
            imgui.EndChild()

            imgui.SameLine()

            -- Right Main View: Articles
            imgui.BeginChild("##DeptRulesMain", imgui.ImVec2(0, 0), true)
            if cRs.preamble and cRs.preamble ~= "" and activeChapter == 1 then
                imgui.TextColored(colors.textMuted, "%s", cRs.preamble)
                imgui.Spacing()
                imgui.Separator()
                imgui.Spacing()
            end

            local activeCh = cRs.chapters[activeChapter]
            if activeCh then
                imgui.TextColored(colors.accent, "%s", activeCh.title)
                imgui.Separator()
                imgui.Spacing()

                for aIdx, art in ipairs(activeCh.articles) do
                    local uId = string.format("%d_%d_%d", activeRuleSet, activeChapter, aIdx)
                    local isHighlighted = (highlightRuleId == uId)
                    local cPosStart = imgui.GetCursorScreenPos()

                    if art.id == "Sectiune" then
                        imgui.Spacing()
                        imgui.TextColored(colors.royalHover, "%s", art.text)
                    else
                        if art.id ~= "Info" then
                            local idCol = art.id:sub(1, 1) == "[" and colors.accent or colors.gold
                            imgui.TextColored(idCol, "%s", art.id .. " -")
                            imgui.SameLine(0, 6)
                        end

                        if isHighlighted and lastRulesSearch ~= "" and art.text:lower():find(lastRulesSearch, 1, true) then
                            local availX = imgui.GetContentRegionAvail().x
                            local startX = imgui.GetCursorPosX()
                            local currX  = startX
                            local lowerT = art.text:lower()
                            local lastP  = 1
                            local chunks = {}
                            while true do
                                local s, e = lowerT:find(lastRulesSearch, lastP, true)
                                if not s then
                                    table.insert(chunks, { t = art.text:sub(lastP), m = false })
                                    break
                                end
                                if s > lastP then
                                    table.insert(chunks, { t = art.text:sub(lastP, s - 1), m = false })
                                end
                                table.insert(chunks, { t = art.text:sub(s, e), m = true })
                                lastP = e + 1
                            end
                            for _, chunk in ipairs(chunks) do
                                for w in chunk.t:gmatch("%S+") do
                                    local wSz = imgui.CalcTextSize(w .. " ")
                                    if currX + wSz.x > startX + availX and currX > startX then
                                        imgui.NewLine()
                                        imgui.SetCursorPosX(startX)
                                        currX = startX
                                    end
                                    if chunk.m then
                                        imgui.TextColored(colors.greenHover, "%s", w)
                                    else
                                        imgui.Text("%s", w)
                                    end
                                    imgui.SameLine(0, 0)
                                    imgui.Text(" ")
                                    imgui.SameLine(0, 0)
                                    currX = currX + wSz.x
                                end
                            end
                            imgui.NewLine()
                        else
                            imgui.TextWrapped("%s", art.text)
                        end
                    end

                    local cPosEnd = imgui.GetCursorScreenPos()
                    if isHighlighted then
                        if (os.clock() - highlightRuleTime) < 0.12 then
                            imgui.SetScrollHereY(0.25)
                        end
                        local dl = imgui.GetWindowDrawList()
                        dl:AddRectFilled(
                            imgui.ImVec2(cPosStart.x - 4, cPosStart.y - 3),
                            imgui.ImVec2(cPosStart.x + imgui.GetContentRegionAvail().x + 4, cPosEnd.y + 3),
                            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 0.8, 0.2, 0.14)),
                            6.0
                        )
                        dl:AddRect(
                            imgui.ImVec2(cPosStart.x - 4, cPosStart.y - 3),
                            imgui.ImVec2(cPosStart.x + imgui.GetContentRegionAvail().x + 4, cPosEnd.y + 3),
                            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 0.8, 0.2, 0.70)),
                            6.0, 15, 1.5
                        )
                    end
                    imgui.Spacing()
                end
            end
            imgui.EndChild()
        end

        imgui.End()
        imgui.PopStyleVar()
    end
)

-- =========================================================================================
--  SECTION 13: FONT LOADING & IMGUI INITIALIZATION
-- =========================================================================================
imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil

    local fontCfg = imgui.ImFontConfig()
    fontCfg.MergeMode  = true
    fontCfg.PixelSnapH = true

    local fontCandidates = {
        getWorkingDirectory() .. "\\resource\\fonts\\fa-solid-900.ttf",
        getWorkingDirectory() .. "\\resource\\fonts\\FontAwesome.otf",
        getWorkingDirectory() .. "\\resource\\fonts\\fontawesome-webfont.ttf",
    }
    for _, fp in ipairs(fontCandidates) do
        if doesFileExist(fp) then
            local glyph_ranges = imgui.new("const ImWchar[3]", { fa.min_range, fa.max_range, 0 })
            imgui.GetIO().Fonts:AddFontFromFileTTF(fp, 14.0, fontCfg, glyph_ranges)
            PDX.faFontPath = fp
            break
        end
    end

    -- Font separat pt HUD-ul clasic: Days (futurist, din moonloader/resource/fonts) + iconite FontAwesome integrate
    -- Rezerva: Verdana Bold / Tahoma Bold din Windows
    local winFonts = (os.getenv("WINDIR") or "C:\\Windows") .. "\\Fonts\\"
    local hudFontCandidates = {
        { getWorkingDirectory() .. "\\resource\\fonts\\Days.ttf", 19.0 },
        { winFonts .. "verdanab.ttf", 18.0 },
        { winFonts .. "tahomabd.ttf", 18.0 },
    }
    for _, cand in ipairs(hudFontCandidates) do
        local fp = cand[1]
        if doesFileExist(fp) then
            local io = imgui.GetIO()
            PDX.hudFontSize = cand[2]
            PDX.hudFont = io.Fonts:AddFontFromFileTTF(fp, PDX.hudFontSize, nil, io.Fonts:GetGlyphRangesDefault())
            if PDX.faFontPath then
                local faCfg = imgui.ImFontConfig()
                faCfg.MergeMode  = true
                faCfg.PixelSnapH = true
                local faRanges = imgui.new("const ImWchar[3]", { fa.min_range, fa.max_range, 0 })
                io.Fonts:AddFontFromFileTTF(PDX.faFontPath, 16.0, faCfg, faRanges)
            end
            break
        end
    end

    ApplyTheme()
end)

-- =========================================================================================
--  SECTION 14: COMMAND REGISTRATION & MAIN LOOP
-- =========================================================================================
local function registerAllCommands()
    local function reg(cmdName, fn)
        if not cmdName or cmdName == "" then return end
        pcall(sampUnregisterChatCommand, cmdName)
        sampRegisterChatCommand(cmdName, fn)
    end

    -- Core Menus & Guides
    reg("pdc", function() toggleAnimWin(mainWin) end)
    reg("pdassist", function() toggleAnimWin(mainWin) end)
    if cfg.cmd.cmd and cfg.cmd.cmd ~= "" then
        reg(cfg.cmd.cmd, function() openGuideTab("") end)
    end
    reg("com",  function() openGuideTab("") end)
    reg("isan", function() openGuideTab("Sanctiune") end)
    reg("isu",  function() openGuideTab("Wanted") end)
    reg("reguli",  function() toggleAnimWin(rulesWin) end)
    reg("pdrules", function() toggleAnimWin(rulesWin) end)
    reg("pdbl", function() toggleAnimWin(blWin) end)
    reg("pdupdate", function()
        local cur, curPatch = PDX.curVer()
        if PDX.update.latest and PDX.verNewer(PDX.update.latest, PDX.update.latestPatch, cur, curPatch) then
            PDX.installUpdate()
        else
            -- verifica intai; daca gaseste ceva nou, scrii /pdupdate inca o data
            PDX.checkUpdate(true)
        end
    end)
    reg("blpos", function() if PDX.blMoving then PDX.stopBlMoving() else PDX.startBlMoving() end end)
    reg("hudpos", startHudMoving)
    reg("resethud", resetHudPosition)

    reg("start", function()
        lua_thread.create(function()
            msg("Bun venit in {28AFE0}PDAssist v1.0{FFFFFF} (Editia Moderna Mimgui)!")
            wait(1200)
            msg("Foloseste {28AFE0}/pdc{FFFFFF} pentru configurare, {28AFE0}/san{FFFFFF} (sau tasta {28AFE0}" .. tostring(cfg.settings.nMenuKey) .. "{FFFFFF}) pentru sanctiuni rapide si {28AFE0}/" .. tostring(cfg.cmd.cmd) .. "{FFFFFF} pentru lista comenzilor.")
        end)
    end)

    reg("pdoff", function()
        msg("Modul a fost oprit. Apasa CTRL+R pentru repornire.")
        thisScript():unload()
    end)

    -- Duty, Heal, FVR, GOV
    reg("dt", function()
        say("/pin")
        say("/duty")
    end)
    reg("hdt", function()
        PDX.dutyHeal()
    end)
    reg("ha", function() say("/heal") end)
    reg("afvr", startFvrSequence)
    reg("sfvr", stopFvrSequence)
    reg("pdgov", sendPdGov)

    -- Radar & Patrol Commands
    reg("stopradar", function()
        say("/stopradar")
        cfg.radar.stage = 2
        liStep = 0
        hudCacheDirty = true
    end)
    reg("sto", function()
        say("/stopradar")
        cfg.radar.stage = 2
        liStep = 0
        hudCacheDirty = true
    end)
    reg("startradar", function(arg)
        local lim = tonumber(arg)
        if lim then
            say("/startradar " .. lim)
            cfg.radar.stage = 1
            liStep = 0
            hudCacheDirty = true
        else
            msg("Foloseste {28AFE0}/startradar <limita>{FFFFFF} sau apasa tasta {28AFE0}[" .. tostring(cfg.pd.nTastaR) .. "]{FFFFFF}.")
        end
    end)
    reg("last", function()
        if #radarHistory == 0 then
            msg("Niciun jucator nu a fost inregistrat pe radar in aceasta sesiune inca.")
            return
        end
        msg("Ultimii jucatori surprinsi pe radar ({28AFE0}/sl <id>{FFFFFF} pentru sanctionare):")
        for i, rh in ipairs(radarHistory) do
            local en = PDX.uiLang == "en"
            sampAddChatMessage(string.format(
                "{28AFE0}%d{FFFFFF} - %s [ID: {28AFE0}%d{FFFFFF}] | %s: {28AFE0}%d{FFFFFF} | %s: {FF6347}%d km/h{FFFFFF} (%s)",
                i, rh.name, rh.id, en and "Level" or "Nivel", rh.level, en and "Speed" or "Viteza", rh.speed, rh.timeStr
            ), -1)
        end
    end)
    reg("sl", function(arg)
        executeRadarSl(arg)
    end)

    reg("ll", function()
        local z = tostring(cfg.radar.zona or "LS")
        if liStep == 0 then
            say("/d Este libera zona de radar " .. z .. "?")
            liStep = 1
        elseif liStep == 1 then
            say("/d Este libera zona de radar " .. z .. "? x2")
            liStep = 2
        else
            say("/d Este libera zona de radar " .. z .. "? x3")
            liStep = 0
            msg("Apasa tasta {28AFE0}[" .. tostring(cfg.pd.nTastaR) .. "]{FFFFFF} pentru a porni radarul sau {28AFE0}/pot<ls/lv/sf>{FFFFFF} pt acord.")
        end
        timers.dEnd = os.clock() + 10.0
        hudCacheDirty = true
    end)

    local function makePotCmd(cityTag)
        return function()
            local z = tostring(cfg.radar.zona or "LS")
            if potStep == 0 then
                say("/d " .. cityTag .. ", imi permiteti sa amplasez radar in zona " .. z .. "?")
                msg("Dupa ce primesti acord apasa tasta {28AFE0}[" .. tostring(cfg.pd.nTastaR) .. "]{FFFFFF} pentru a porni radarul.")
                potStep = 1
            elseif potStep == 1 then
                say("/d " .. cityTag .. ", imi permiteti sa amplasez radar in zona " .. z .. "? x2")
                potStep = 2
            else
                say("/d " .. cityTag .. ", imi permiteti sa amplasez radar in zona " .. z .. "? x3")
                potStep = 0
            end
            timers.dEnd = os.clock() + 10.0
            hudCacheDirty = true
        end
    end
    reg("potls", makePotCmd("LSPD"))
    reg("potlv", makePotCmd("LVPD"))
    reg("potsf", makePotCmd("SFPD"))

    local function makePatCmd(cityTag)
        return function()
            if patStep == 0 then
                say("/d " .. cityTag .. ", imi permiteti sa patrulez in orasul vostru?")
                patStep = 1
            elseif patStep == 1 then
                say("/d " .. cityTag .. ", imi permiteti sa patrulez in orasul vostru? x2")
                patStep = 2
            else
                say("/d " .. cityTag .. ", imi permiteti sa patrulez in orasul vostru? x3")
                patStep = 0
            end
            timers.dEnd = os.clock() + 10.0
            hudCacheDirty = true
        end
    end
    reg("patls", makePatCmd("LSPD"))
    reg("patlv", makePatCmd("LVPD"))
    reg("patsf", makePatCmd("SFPD"))

    -- Cuff & Uncuff
    reg("cuff", function(arg)
        local id = tonumber(arg)
        if id then
            say("/cuff " .. id)
            cfg.pd.arrestid = id
            hudCacheDirty = true
        else
            msg("Scrie {28AFE0}/cuff <id>{FFFFFF}")
        end
    end)
    reg("uncuff", function(arg)
        local id = tonumber(arg)
        cfg.pd.arrestid = -1
        hudCacheDirty = true
        if id then
            say("/uncuff " .. id)
        else
            msg("Auto-Arrest oprit. Daca vrei sa dai si uncuff scrie {28AFE0}/uncuff <id>{FFFFFF}.")
        end
    end)

    -- Sanctions Menu & Individual Sanction Commands
    reg("san",     function(arg) openSanctionsFor(arg) end)
    reg("aa",      function(arg) if tonumber(arg) then sanctionDirect("aa", arg) else msg("Scrie {28AFE0}/aa <id>") end end)
    reg("aa50",    function(arg) if tonumber(arg) then sanctionWithIdCheck("aa50", arg) else msg("Scrie {28AFE0}/aa50 <id>") end end)
    reg("aa100",   function(arg) if tonumber(arg) then sanctionWithIdCheck("aa100", arg) else msg("Scrie {28AFE0}/aa100 <id>") end end)
    reg("faruri",  function(arg) if tonumber(arg) then sanctionDirect("faruri", arg) else msg("Scrie {28AFE0}/faruri <id>") end end)
    reg("car",     function(arg) if tonumber(arg) then sanctionDirect("car", arg) else msg("Scrie {28AFE0}/car <id>") end end)
    reg("alc15",   function(arg) if tonumber(arg) then sanctionDirect("alc15", arg) else msg("Scrie {28AFE0}/alc15 <id>") end end)
    reg("alc30",   function(arg) if tonumber(arg) then sanctionWithIdCheck("alc30", arg) else msg("Scrie {28AFE0}/alc30 <id>") end end)
    reg("nos",     function(arg) if tonumber(arg) then sanctionWithIdCheck("nos", arg) else msg("Scrie {28AFE0}/nos <id>") end end)
    reg("con",     function(arg) if tonumber(arg) then sanctionWithIdCheck("con", arg) else msg("Scrie {28AFE0}/con <id>") end end)
    reg("parc",    function(arg) if tonumber(arg) then sanctionWithIdCheck("parc", arg) else msg("Scrie {28AFE0}/parc <id>") end end)
    reg("hidra",   function(arg) if tonumber(arg) then sanctionWithIdCheck("hidra", arg) else msg("Scrie {28AFE0}/hidra <id>") end end)
    reg("arme",    function(arg) if tonumber(arg) then sanctionDirect("arme", arg) else msg("Scrie {28AFE0}/arme <id>") end end)
    reg("dr",      function(arg) if tonumber(arg) then sanctionDirect("dr", arg) else msg("Scrie {28AFE0}/dr <id>") end end)
    reg("cdr",     function(arg) if tonumber(arg) then sanctionDirect("cdr", arg) else msg("Scrie {28AFE0}/cdr <id>") end end)
    reg("matslic", function(arg) if tonumber(arg) then sanctionDirect("matslic", arg) else msg("Scrie {28AFE0}/matslic <id>") end end)
    reg("mats",    function(arg) if tonumber(arg) then sanctionWithIdCheck("mats", arg) else msg("Scrie {28AFE0}/mats <id>") end end)

    -- Wanted (/su) Auto-Select Commands
    reg("nec",  function(arg) if tonumber(arg) then queueAutoSu(arg, 2,  "Neconformare ordin") else msg("Scrie {28AFE0}/nec <id>") end end)
    reg("run",  function(arg) if tonumber(arg) then queueAutoSu(arg, 12, "Runner") else msg("Scrie {28AFE0}/run <id>") end end)
    reg("nef",  function(arg) if tonumber(arg) then queueAutoSu(arg, 1, "Nefondat") else msg("Scrie {28AFE0}/nef <id>") end end)
    reg("bm",   function(arg) PDX.bombs(arg) end)
    reg("jc",   function() PDX.cmdJc() end)
    reg("ms",   function(arg) PDX.cmdMs(arg) end)
    reg("ffk",  function(arg) PDX.afkStart("ffk", arg) end)
    for spawnCmd in pairs(PDX.SPAWNS) do
        reg(spawnCmd, function() PDX.spawnChange(spawnCmd) end)
    end
    reg("cat",  function(arg) if tonumber(arg) then queueAutoSu(arg, 6,  "Cop Attack") else msg("Scrie {28AFE0}/cat <id>") end end)
    reg("notp", function(arg) if tonumber(arg) then queueAutoSu(arg, 7,  "Neplata amenda") else msg("Scrie {28AFE0}/notp <id>") end end)
    reg("comp", function(arg) if tonumber(arg) then queueAutoSu(arg, 13, "Complice") else msg("Scrie {28AFE0}/comp <id>") end end)
    reg("wdr",  function(arg) if tonumber(arg) then queueAutoSu(arg, 5,  "Droguri") else msg("Scrie {28AFE0}/wdr <id>") end end)

    -- Field Controls, Somatii & AFK Timers
    reg("mm", function(arg)
        local id = tonumber(arg)
        if id and isPlayerOnline(id) then
            local pName = getPlayerNameSafe(id)
            say("/m " .. pName .. " esti urmarit de politie, trage pe dreapta imediat!" .. (mmSpamToggle and "!" or ""))
            mmSpamToggle = not mmSpamToggle
            timers.mmEnd = os.clock() + 3.0
            hudCacheDirty = true
        else
            msg("Scrie {28AFE0}/mm <id>{FFFFFF}")
        end
    end)

    -- /fr <id> = frisk simplu (fara mesaj), cu protectie pt colegi
    reg("fr", function(arg)
        local id = tonumber(arg)
        if id and isPlayerOnline(id) then
            if PDX.blockColleague(id, "frisk") then return end
            say("/frisk " .. id)
        else
            msg("Scrie {28AFE0}/fr <id>{FFFFFF}")
        end
    end)

    reg("cl", function(arg)
        local id = tonumber(arg)
        if id and isPlayerOnline(id) then
            if PDX.blockColleague(id, "frisk") then return end
            local pName = getPlayerNameSafe(id)
            if isRo() then
                say("Salut " .. pName .. "! Acesta este un control de rutina" .. (friskSpamToggle and "." or ""))
            else
                say("Hello " .. pName .. "! This is a routine check" .. (friskSpamToggle and "." or ""))
            end
            friskSpamToggle = not friskSpamToggle
            say("/frisk " .. id)
        else
            msg("Scrie {28AFE0}/cl <id>{FFFFFF}")
        end
    end)

    reg("/", function(arg)
        local id = tonumber(arg)
        if id and isPlayerOnline(id) then
            local pName = getPlayerNameSafe(id)
            say("/d Ii voi da nefondat lui " .. pName .. " (" .. id .. ")" .. (nefSpamToggle and "" or "."))
            nefSpamToggle = not nefSpamToggle
            msg("Foloseste {28AFE0}/nef " .. id .. "{FFFFFF} pentru a-i acorda wanted daca ai anuntat primul pe /d.")
        else
            msg("Scrie {28AFE0}// <id>{FFFFFF}")
        end
    end)

    reg("tg", function(arg)
        local id = tonumber(arg)
        if id and isPlayerOnline(id) then
            local pName = getPlayerNameSafe(id)
            if isRo() then
                say(pName .. ", te rog sa parasesti Teritoriul Guvernamental!")
                say("Risti sa primesti Wanted 2 - 'Patrundere Teren Guvernamental'")
            else
                say(pName .. ", please leave the Governmental Area!")
                say("You're putting yourself at the risk of getting Wanted 2.")
            end
        else
            msg("Foloseste {28AFE0}/tg <id>{FFFFFF}")
        end
    end)

    reg("rl", function(arg)
        local id = tonumber(arg)
        if id then
            say("/requestlicenses " .. id)
        else
            msg("Foloseste {28AFE0}/rl <id>{FFFFFF}")
        end
    end)

    reg("afk", function(arg) PDX.afkStart("afk", arg) end)

    reg("stopafk", function()
        PDX.afkStop()
        PDX.afk.pending = nil
        msg("Numaratoarea AFK a fost oprita.")
        addNotification("Timer AFK oprit", "info")
    end)

    -- Shortened Commands (checked dynamically via cfg.settings.cp == 1)
    local function ifCp(fn)
        return function(arg)
            if cfg.settings.cp == 1 then
                fn(arg)
            else
                msg("Comenzile prescurtate sunt dezactivate in {28AFE0}/pdc{FFFFFF}!")
            end
        end
    end

    reg("sa",    ifCp(function() say("/stopanim") end))
    reg("ra",    ifCp(function() say("/raport") end))
    reg("not",   ifCp(function() say("/notifications") end))
    reg("sp",    ifCp(function() say("/spawnchange") end))
    reg("st",    ifCp(function() say("/stats") end))
    reg("cf",    ifCp(function() say("/cancel find") end))
    reg("kc",    ifCp(function() say("/killcp") end))
    reg("mb",    ifCp(function() say("/members") end))
    reg("jl",    ifCp(function() say("/jaillist") end))
    reg("cmb",   ifCp(function() say("/clanmembers") end))
    reg("acp",   ifCp(function() say("/acceptpoints") end))
    reg("gj",    ifCp(function() say("/getjob") end))
    reg("en",    ifCp(function() say("/engine") end))
    reg("ct",    ifCp(function() say("/cancel ticket") end))
    reg("missm", ifCp(function() say("/missed messages") end))
    reg("missc", ifCp(function() say("/missed calls") end))
    reg("toff",  ifCp(function() say("/turn off") end))
    reg("ton",   ifCp(function() say("/turn on") end))
    reg("rr",    ifCp(function() say("/repair"); say("/refill") end))
    reg("rep",   ifCp(function() say("/repair") end))
    reg("ref",   ifCp(function() say("/refill") end))
    reg("shu",   ifCp(function() say("/shield use") end))
    reg("shr",   ifCp(function() say("/shield remove") end))
    reg("shb",   ifCp(function() say("/shield buy") end))
    reg("sal",   ifCp(function() say("/r Salut!"); say("/ac Salut!") end))
    reg("nb",    ifCp(function() say("/r Noapte Buna!"); say("/ac Noapte Buna!") end))
    reg("cch",   ifCp(function() for _ = 1, 22 do sampAddChatMessage(" ", -1) end end))

    reg("fd", ifCp(function(arg)
        local p = (arg or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if p ~= "" then say("/id " .. p); say("/find " .. p)
        else msg("Structura corecta este {28AFE0}/fd <id/nume>{FFFFFF}") end
    end))
    reg("at", ifCp(function(arg)
        local p = (arg or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if p ~= "" then say("/accept ticket " .. p)
        else msg("Structura corecta este {28AFE0}/at <id/nume>{FFFFFF}") end
    end))
    reg("gk", ifCp(function(arg)
        local p = (arg or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if p ~= "" then say("/givekey " .. p)
        else msg("Structura corecta este {28AFE0}/gk <id/nume>{FFFFFF}") end
    end))
    reg("bg", ifCp(function(arg)
        local gun, ammo = (arg or ""):match("^(%S+)%s+(%d+)")
        if gun and ammo then say("/buygun " .. gun .. " " .. ammo)
        else msg("Structura corecta este {28AFE0}/bg <arma> <gloante>{FFFFFF}") end
    end))
    reg("ps", function(arg)
        executePunishCmd(arg)
    end)
    reg("roata", function()
        PDX.openWheel()
    end)

    -- Custom 25 slots with dynamic arguments
    for i = 1, CUSTOM_CMD_MAX do
        local cName = tostring(cfg.comenzi["cmd" .. i] or ""):gsub("^/+", ""):gsub("%s+", "")
        if cfg.settings.cp == 1 and cfg.comenzi["en" .. i] == 1 and cName ~= "" then
            local slot = i
            reg(cName, function(arg)
                executeCustomCommandSlot(slot, arg)
            end)
        end
    end
end

-- =========================================================================================
--  SECTION 14B: HOTKEY RUNNER (K / L) & GTA V STYLE DRIVER INTERACTION WHEEL (F2)
-- =========================================================================================
function PDX.runHotkeyAction(actionId)
    actionId = tostring(actionId or "SAN")
    if actionId == "SAN" then
        toggleAnimWin(sanWin)
    elseif actionId == "PDC" then
        toggleAnimWin(mainWin)
    elseif actionId == "RULES" then
        toggleAnimWin(rulesWin)
    elseif actionId == "BL" then
        toggleAnimWin(blWin)
    elseif actionId == "GUIDE" then
        openGuideTab("")
    elseif actionId == "PUNISH" then
        local nid = getNearestStreamedPlayer(25.0)
        if nid then executePunishCmd(tostring(nid)) else msg("Niciun jucator in apropiere pentru /punish!") end
    elseif actionId == "FRISK" then
        triggerFriskKeyAction()
    elseif actionId == "WHEEL" then
        PDX.openWheel()
    else
        local slot = tonumber(actionId:match("^CUSTOM:(%d+)$"))
        if slot and slot >= 1 and slot <= CUSTOM_CMD_MAX then
            local nid = getNearestStreamedPlayer(25.0)
            executeCustomCommandSlot(slot, nid and tostring(nid) or "")
        end
    end
end

-- =========================================================================================
--  ROATA INTERACTIUNE (stil GTA V)
--  Sofer: Eject / Cuff / Uncuff pe pasageri
--  Pe jos: Interact -> jucatorii din jur (raza reglabila) -> Frisk / Cuff* / Uncuff* / Confisca / Wanted /
--          Sanctiuni / Find / Licente* / Punish*   (* = doar cand are sens)
--  Fiecare nivel e un "builder" (functie) apelat la fiecare frame -> listele se actualizeaza live.
-- =========================================================================================
PDX.wheel = { open = false, mode = "car", stack = {}, animT = 0, closeT = nil, hov = {}, lastT = 0, pCache = nil, pCacheT = 0 }

function PDX.argbToU32(c)
    c = tonumber(c) or 0xFFFFFFFF
    local r = bit.band(bit.rshift(c, 16), 0xFF)
    local g = bit.band(bit.rshift(c, 8), 0xFF)
    local b = bit.band(c, 0xFF)
    if (r + g + b) < 90 then r, g, b = 221, 221, 221 end
    return 0xFF000000 + b * 65536 + g * 256 + r
end

-- Inmulteste alpha-ul unei culori ImU32 (ABGR) cu k (0..1)
function PDX.colA(u32, k)
    local base = u32 % 16777216
    local a    = math.floor(u32 / 16777216) % 256
    return math.floor(a * k + 0.5) * 16777216 + base
end

function PDX.wheelPush(builder)
    local w = PDX.wheel
    table.insert(w.stack, builder)
    w.animT, w.hov = os.clock(), {}
end

function PDX.wheelPop()
    local w = PDX.wheel
    if #w.stack > 1 then
        table.remove(w.stack)
        w.animT, w.hov = os.clock(), {}
    else
        PDX.closeWheel()
    end
end

function PDX.openWheel()
    local w = PDX.wheel
    w.mode   = state.isDriving and "car" or "foot"
    w.stack  = {}
    w.open, w.closeT, w.pCache, w.held, w.hoverItem = true, nil, nil, false, nil
    PDX.wheelPush(w.mode == "car" and PDX.wheelCarRoot or PDX.wheelFootRoot)
end

-- Mod Hold: tasta eliberata -> executa felia de sub mouse (submeniu = intra in el si roata ramane deschisa)
function PDX.wheelRelease()
    local w  = PDX.wheel
    local it = w.hoverItem
    if it and it.noRelease then
        -- actiuni "periculoase" (Punish, Confiscari): NU se executa la eliberarea tastei,
        -- roata ramane deschisa si trebuie click stanga ca sa confirmi
        return
    elseif it and it.sub then
        PDX.wheelPush(it.sub)
    elseif it and it.run then
        PDX.closeWheel()
        it.run()
    else
        PDX.closeWheel()
    end
end

-- instant = fara animatie de inchidere
function PDX.closeWheel(instant)
    local w = PDX.wheel
    w.held = false
    if not w.open then return end
    if instant then
        w.open, w.closeT, w.stack = false, nil, {}
    elseif not w.closeT then
        w.closeT = os.clock()
    end
end

-- ---------- Sofer ----------
-- Pasagerii din masina (+ jucatori pe jos la max 3m pentru cuff/uncuff)
function PDX.collectWheelTargets(action)
    local list, seen = {}, {}
    if not doesCharExist(PLAYER_PED) or not isCharInAnyCar(PLAYER_PED) then return list end
    local veh = storeCarCharIsInNoSave(PLAYER_PED)
    if veh == 0 or not doesVehicleExist(veh) then return list end

    local function add(pid)
        if pid and not seen[pid] and #list < 10 and sampIsPlayerConnected(pid) then
            seen[pid] = true
            table.insert(list, {
                id    = pid,
                name  = sampGetPlayerNickname(pid) or ("ID " .. pid),
                color = sampGetPlayerColor(pid),
            })
        end
    end

    local maxP = tonumber(getMaximumNumberOfPassengers(veh)) or 0
    for seat = 0, maxP - 1 do
        if not isCarPassengerSeatFree(veh, seat) then
            local ped = getCharInCarPassengerSeat(veh, seat)
            if ped and ped ~= PLAYER_PED and doesCharExist(ped) then
                local ok, pid = sampGetPlayerIdByCharHandle(ped)
                if ok then add(pid) end
            end
        end
    end

    if action == "cuff" or action == "uncuff" then
        local px, py, pz = getCharCoordinates(PLAYER_PED)
        for pid = 0, 999 do
            if #list >= 10 then break end
            if not seen[pid] and sampIsPlayerConnected(pid) then
                local ok, ped = sampGetCharHandleBySampPlayerId(pid)
                if ok and doesCharExist(ped) and ped ~= PLAYER_PED then
                    local tx, ty, tz = getCharCoordinates(ped)
                    if getDistanceBetweenCoords3d(px, py, pz, tx, ty, tz) <= 3.0 then add(pid) end
                end
            end
        end
    end
    return list
end

function PDX.runWheelAction(action, pid)
    local name = getPlayerNameSafe(pid) or ("ID " .. tostring(pid))
    if action == "eject" then
        say("/eject " .. pid)
        addNotification("Eject -> " .. name .. " (" .. pid .. ")", "sanction")
    elseif action == "cuff" then
        cfg.pd.arrestid = pid
        hudCacheDirty   = true
        lua_thread.create(function()
            say("/cuff " .. pid)
            wait(150)
            say("/cancel find")
        end)
        addNotification("Cuff -> " .. name .. " (" .. pid .. ")", "sanction")
    elseif action == "uncuff" then
        say("/uncuff " .. pid)
        if cfg.pd.arrestid == pid then
            cfg.pd.arrestid = -1
            hudCacheDirty   = true
        end
        addNotification("Uncuff -> " .. name .. " (" .. pid .. ")", "info")
    end
end

function PDX.wheelCarRoot()
    local items = {}
    for _, a in ipairs({
        { "eject",  "EJECT",  fa.ICON_FA_SIGN_OUT_ALT },
        { "cuff",   "CUFF",   fa.ICON_FA_LINK },
        { "uncuff", "UNCUFF", fa.ICON_FA_UNLINK },
    }) do
        local act = a[1]
        items[#items + 1] = { wid = act, icon = a[3], label = a[2], sub = function() return PDX.wheelCarTargets(act) end }
    end
    items[#items + 1] = { wid = "repair", icon = fa.ICON_FA_WRENCH, label = "REPAIR", run = function() say("/repair") end }
    PDX.cwAppendRoot(items, "car") -- elementele tale din /pdc -> Roata
    return { title = "ROATA SOFER", hint = "Click stanga: alege", items = PDX.wApply(items, "car") }
end

function PDX.wheelCarTargets(action)
    local items = {}
    for _, t in ipairs(PDX.collectWheelTargets(action)) do
        local pid = t.id
        items[#items + 1] = {
            label = string.format("%s (%d)", t.name, pid), col = PDX.argbToU32(t.color),
            run = function() PDX.runWheelAction(action, pid) end,
        }
    end
    return {
        title = string.upper(action) .. " - ALEGE JUCATOR",
        hint  = (#items == 0) and "Niciun jucator in masina" or "Click dreapta: inapoi",
        items = items,
    }
end

-- ---------- Pe jos ----------
-- Vizibilitate: apar doar jucatorii carora li se vede numele (nametag):
--   * nametag-ul nu e ascuns de server (ex: Hitmen Agency in /undercover) - idee din pickpocket.xlua
--   * nu e hitman undercover (culoare 00AA33 + skin de undercover)
--   * e pe ecran si nu e dupa o cladire / un obiect (linie vizuala de la camera la cap)
PDX.hiddenTag = {}
PDX.HITMEN_UNDERCOVER_SKINS = { [118] = true, [120] = true, [93] = true, [294] = true, [165] = true, [186] = true }

function PDX.isHitmanUndercover(pid, ped)
    local c = sampGetPlayerColor(pid)
    if not c then return false end
    local isHit = bit.band(bit.rshift(c, 8), 0xFFFFFF) == 0x00AA33 or bit.band(c, 0xFFFFFF) == 0x00AA33
    if not isHit then return false end
    return PDX.hiddenTag[pid] == true or (ped and doesCharExist(ped) and PDX.HITMEN_UNDERCOVER_SKINS[getCharModel(ped)] == true)
end

function PDX.isNameVisible(pid, ped)
    if PDX.hiddenTag[pid] then return false end
    if PDX.isHitmanUndercover(pid, ped) then return false end
    if not isCharOnScreen(ped) then return false end
    local camX, camY, camZ = getActiveCameraCoordinates()
    local tx, ty, tz = getCharCoordinates(ped)
    -- cladiri + obiecte blocheaza (ca nametag-ul din SA-MP); masinile si alti jucatori nu
    return isLineOfSightClear(camX, camY, camZ, tx, ty, tz + 0.7, true, false, false, true, false)
end

-- Celula din fata ta: textul 3D al usii ("Cell: 8 / Type /opencell 8...") la max 3m de tine.
-- Intoarce { x, y, z, dx, dy } = pozitia usii + directia (2D) dinspre tine spre celula, sau nil.
function PDX.findCellInFront(maxDist)
    if type(sampIs3dTextDefined) ~= "function" or type(sampGet3dTextInfoById) ~= "function" then return nil end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local best, bestD
    for id = 0, 2047 do
        if sampIs3dTextDefined(id) then
            local text, _, x, y, z = sampGet3dTextInfoById(id)
            if text and x then
                local low = tostring(text):gsub("{%x%x%x%x%x%x}", ""):lower()
                if low:find("opencell", 1, true) or low:find("closecell", 1, true) or low:match("^%s*cell") or low:find("celula", 1, true) then
                    local d = getDistanceBetweenCoords3d(px, py, pz, x, y, z)
                    if d <= maxDist and (not bestD or d < bestD) then best, bestD = { x = x, y = y, z = z }, d end
                end
            end
        end
    end
    if not best then return nil end
    -- directia: de la tine spre usa; daca esti chiar langa usa, dupa unde te uiti (heading)
    local dx, dy = best.x - px, best.y - py
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.6 then
        local h = math.rad(getCharHeading(PLAYER_PED))
        dx, dy, len = -math.sin(h), math.cos(h), 1
    end
    best.dx, best.dy = dx / len, dy / len
    return best
end

-- Jucatorul e in celula din fata (in spatele usii, pe latimea unei celule, acelasi etaj)?
function PDX.isInCellAhead(cell, tx, ty, tz)
    local vx, vy = tx - cell.x, ty - cell.y
    local forward = vx * cell.dx + vy * cell.dy           -- cat de adanc in celula
    local lateral = math.abs(vx * cell.dy - vy * cell.dx) -- cat de lateral fata de usa
    return forward > -0.5 and forward < 5.0 and lateral < 2.5 and math.abs(tz - cell.z) < 3.0
end

function PDX.collectNearbyPlayers(radius)
    local list = {}
    if not doesCharExist(PLAYER_PED) then return list end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local cell = PDX.findCellInFront(3.0)
    for pid = 0, 1003 do
        if sampIsPlayerConnected(pid) then
            local ok, ped = sampGetCharHandleBySampPlayerId(pid)
            if ok and doesCharExist(ped) and ped ~= PLAYER_PED then
                local tx, ty, tz = getCharCoordinates(ped)
                local d = getDistanceBetweenCoords3d(px, py, pz, tx, ty, tz)
                -- exceptie celula: jucatorii din celula din fata ta apar si printre gratii (doar daca nu au nametag ascuns / hitman)
                local inCell = cell and d <= 8.0 and PDX.isInCellAhead(cell, tx, ty, tz)
                    and not PDX.hiddenTag[pid] and not PDX.isHitmanUndercover(pid, ped)
                if inCell or (d <= radius and PDX.isNameVisible(pid, ped)) then
                    list[#list + 1] = { id = pid, name = sampGetPlayerNickname(pid) or ("ID " .. pid), color = sampGetPlayerColor(pid), dist = d, inCell = inCell and true or false }
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    while #list > 10 do table.remove(list) end
    return list
end

function PDX.friskOne(pid)
    if not isPlayerOnline(pid) then return end
    if PDX.blockColleague(pid, "frisk") then return end
    local pName = getPlayerNameSafe(pid)
    if getFaction() ~= "NG" and not isInJailInterior() then
        say((isRo() and ("Salut " .. pName .. "! Acesta este un control de rutina")
                     or ("Hello " .. pName .. "! This is a routine check")) .. (friskSpamToggle and "." or ""))
        friskSpamToggle = not friskSpamToggle
    end
    say("/frisk " .. pid)
    addNotification("Frisk -> " .. pName .. " (" .. pid .. ")", "info")
end

function PDX.wheelFootRoot()
    local items = {
        { wid = "interact",   icon = fa.ICON_FA_USERS,                label = "INTERACT",    sub = PDX.wheelFootPlayers },
        { wid = "cancelfind", icon = fa.ICON_FA_TIMES_CIRCLE,         label = "CANCEL FIND", run = function() say("/cancel find") end },
        { wid = "wanted",     icon = fa.ICON_FA_EXCLAMATION_TRIANGLE, label = "WANTED",      run = function() say("/wanted") end },
        { wid = "spawn",      icon = fa.ICON_FA_HOME,                 label = "SPAWN",       sub = PDX.wheelSpawn },
        { wid = "shield",     icon = fa.ICON_FA_SHIELD_ALT,           label = "SHIELD",      run = function() say("/shield use") end },
    }
    -- Duty doar in Jail sau intr-un interior (HQ / vestiar), unde se poate lua
    if isInJailInterior() or (getActiveInterior() or 0) ~= 0 then
        items[#items + 1] = { wid = "duty", icon = fa.ICON_FA_USER_SHIELD, label = "DUTY", sub = PDX.wheelDuty }
    end
    PDX.cwAppendRoot(items, "foot") -- elementele tale din /pdc -> Roata
    return { title = "ROATA INTERACTIUNE", hint = "Click stanga: alege", items = PDX.wApply(items, "foot") }
end

function PDX.wheelSpawn()
    local items = {}
    for _, s in ipairs({
        { "scasa", "CASA",  fa.ICON_FA_HOME },
        { "slspd", "LSPD",  fa.ICON_FA_BUILDING },
        { "slvpd", "LVPD",  fa.ICON_FA_BUILDING },
        { "ssfpd", "SFPD",  fa.ICON_FA_BUILDING },
        { "sfbi",  "FBI",   fa.ICON_FA_USER_SECRET },
        { "hqng",  "GARAJ NG", fa.ICON_FA_SHIELD_ALT },
        { "hqf",   "HQ " .. getFaction(), fa.ICON_FA_FLAG },
        { "sjail", "JAIL",  fa.ICON_FA_LOCK },
        { "sclan", "HQ CLAN", fa.ICON_FA_USERS },
        { "sbunker", "BUNKER", fa.ICON_FA_DOOR_OPEN },
    }) do
        local key = s[1]
        items[#items + 1] = { wid = key, icon = s[3], label = s[2], run = function() PDX.spawnChange(key) end }
    end
    return { title = "SCHIMBA SPAWN", hint = "Click dreapta: inapoi", items = PDX.wApply(items, "spawn") }
end

function PDX.wheelDuty()
    return {
        title = "DUTY", hint = "Click dreapta: inapoi",
        items = PDX.wApply({
            { wid = "duty",     icon = fa.ICON_FA_USER_SHIELD, label = "DUTY", run = function() say("/pin"); say("/duty") end },
            { wid = "dutyheal", icon = fa.ICON_FA_PLUS,        label = "DUTY + HEAL", run = function() PDX.dutyHeal() end },
            { wid = "heal",     icon = fa.ICON_FA_HEART,       label = "HEAL", run = function() say("/heal") end },
        }, "duty"),
    }
end

function PDX.wheelFootPlayers()
    local w = PDX.wheel
    local r = tonumber(cfg.settings.wheelRadius) or 5
    if not w.pCache or (os.clock() - w.pCacheT) > 0.25 then
        w.pCache, w.pCacheT = PDX.collectNearbyPlayers(r), os.clock()
    end
    local items = {}
    for _, t in ipairs(w.pCache) do
        local pid, pname = t.id, t.name
        items[#items + 1] = {
            label = string.format("%s (%d)", pname, pid),
            label2 = string.format("%.1f m", t.dist) .. (t.inCell and ((PDX.uiLang == "en") and " | cell" or " | celula") or ""),
            col = PDX.argbToU32(t.color), sub = PDX.wheelPlayerMenu(pid, pname),
        }
    end
    return {
        title = "INTERACT - ALEGE JUCATOR",
        hint  = (#items == 0) and string.format("Niciun jucator pe %d m", r) or "Click dreapta: inapoi",
        items = items,
    }
end

function PDX.wheelPlayerMenu(pid, pname)
    return function()
        local title = string.format("%s (%d)", pname, pid)
        if not isPlayerOnline(pid) then
            return { title = title, hint = "Jucatorul s-a deconectat", items = {} }
        end
        local inJail    = isInJailInterior()
        local fac       = getFaction()
        local colleague = PDX.sameColorAsMe(pid) -- coleg (aceeasi culoare): fara Frisk / Confisca / Wanted
        local items     = {}
        -- ordinea de aici e cea implicita (Punish primul = sus); poate fi schimbata din /pdc -> Roata
        if inJail then
            items[#items + 1] = { wid = "punish", icon = fa.ICON_FA_HAND_PAPER, label = "PUNISH", noRelease = true, run = function() executePunishCmd(tostring(pid)) end }
        end
        if not colleague then
            items[#items + 1] = { wid = "frisk", icon = fa.ICON_FA_SEARCH, label = "FRISK", run = function() PDX.friskOne(pid) end }
        end
        if cfg.pd.arrestid == pid then
            items[#items + 1] = { wid = "uncuff", icon = fa.ICON_FA_UNLINK, label = "UNCUFF", run = function() PDX.runWheelAction("uncuff", pid) end }
        end
        if inJail then
            items[#items + 1] = { wid = "cuff", icon = fa.ICON_FA_LINK, label = "CUFF", run = function() PDX.runWheelAction("cuff", pid) end }
        end
        if not colleague then
            items[#items + 1] = { wid = "confisca", icon = fa.ICON_FA_BOX_OPEN, label = "CONFISCA", sub = function() return PDX.wheelConfisca(pid, pname) end }
            items[#items + 1] = { wid = "wantedsu", icon = fa.ICON_FA_STAR,     label = "WANTED",   sub = function() return PDX.wheelWanted(pid, pname) end }
        end
        items[#items + 1] = { wid = "sanctiuni", icon = fa.ICON_FA_GAVEL, label = "SANCTIUNI", run = function() openSanctionsFor(pid) end }
        if fac == "LSPD" or fac == "LVPD" or fac == "SFPD" then
            items[#items + 1] = { wid = "licente", icon = fa.ICON_FA_ID_CARD, label = "LICENTE", run = function() say("/requestlicenses " .. pid) end }
        end
        return { title = title, hint = colleague and "Coleg (aceeasi culoare)" or "Click dreapta: inapoi", items = PDX.wApply(items, "player") }
    end
end

function PDX.wheelConfisca(pid, pname)
    return {
        title = "CONFISCA - " .. pname, hint = "Click dreapta: inapoi",
        items = PDX.wApply({
            { wid = "arme",      icon = fa.ICON_FA_CROSSHAIRS, label = "ARME",      noRelease = true, run = function() sanctionDirect("arme", pid) end },
            { wid = "droguri",   icon = fa.ICON_FA_CANNABIS,   label = "DROGURI",   noRelease = true, run = function() sanctionDirect("dr", pid) end },
            { wid = "bombe",     icon = fa.ICON_FA_BOMB,       label = "BOMBE",     noRelease = true, run = function() PDX.bombs(pid) end },
            { wid = "materiale", icon = fa.ICON_FA_CUBES,      label = "MATERIALE", noRelease = true, run = function() sanctionWithIdCheck("mats", pid) end },
        }, "confisca"),
    }
end

function PDX.wheelWanted(pid, pname)
    local items = {}
    for _, wd in ipairs({
        { fa.ICON_FA_HAND_PAPER,   "NECONFORMARE",     2,  "Neconformare ordin" },
        { fa.ICON_FA_FIST_RAISED,  "ATACARE POLITIST", 6,  "Cop Attack" },
        { fa.ICON_FA_RUNNING,      "FUGAR",            12, "Runner" },
        { fa.ICON_FA_USER_FRIENDS, "COMPLICE",         13, "Complice" },
        { fa.ICON_FA_PHONE_SLASH,  "NEFONDAT",         1,  "Nefondat" },
        { fa.ICON_FA_LANDMARK,     "PATRUNDERE TEREN", 3,  "Patrundere teren" },
    }) do
        local line, lbl = wd[3], wd[4]
        items[#items + 1] = {
            wid = "w" .. line, icon = wd[1], label = wd[2],
            run = function() queueAutoSu(pid, line, lbl) end,
        }
    end
    return { title = "WANTED - " .. pname, hint = "Click dreapta: inapoi", items = PDX.wApply(items, "wanted") }
end

-- ---------- Desenare (animatii: deschidere/schimbare nivel, hover, inchidere) ----------
-- Fereastra transparenta pe tot ecranul (nu blocheaza soferul: fara LockPlayer, tastele de condus merg)
PDX.wheelFrame = imgui.OnFrame(
    function() return PDX.wheel.open and not state.paused end,
    function(self)
        self.HideCursor = false
        local w   = PDX.wheel
        local now = os.clock()
        local dt  = math.min(0.05, math.max(0, now - (w.lastT or now)))
        w.lastT = now

        local closeK = 1
        if w.closeT then
            closeK = 1 - math.min(1, (now - w.closeT) / 0.14)
            if closeK <= 0 then
                w.open, w.closeT, w.stack = false, nil, {}
                return
            end
        end
        local openK = easeOutCubic(math.min(1, (now - w.animT) / 0.20))
        local alpha = openK * closeK
        local scale = (0.86 + 0.14 * openK) * (0.94 + 0.06 * closeK) * PDX.wheelScale() -- marimea din /pdc -> Roata

        local sw, sh = getScreenResCached()
        local cx, cy = sw * 0.5, sh * 0.5

        imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(sw, sh), imgui.Cond.Always)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
        imgui.Begin("##PDInteractWheel", nil,
            imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove +
            imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoBackground + imgui.WindowFlags.NoCollapse
        )

        local builder = w.stack[#w.stack]
        local lvl     = builder and builder() or { title = "", hint = "", items = {} }
        local items   = lvl.items or {}
        local n       = #items

        local dl     = imgui.GetWindowDrawList()
        local center = imgui.ImVec2(cx, cy)
        local R_IN   = 92 * scale
        local R_OUT  = 205 * scale

        dl:AddRectFilled(imgui.ImVec2(0, 0), imgui.ImVec2(sw, sh), PDX.colA(0x66000000, alpha))

        local mp     = imgui.GetMousePos()
        local dx, dy = mp.x - cx, mp.y - cy
        local hover  = 0
        if n > 0 and not w.closeT and math.sqrt(dx * dx + dy * dy) > 35 then
            local step = 2 * math.pi / n
            local rel  = (math.atan2(dy, dx) + math.pi / 2) % (2 * math.pi)
            hover = math.floor((rel + step / 2) / step) % n + 1
        end
        w.hoverItem = (hover > 0) and items[hover] or nil

        local font  = imgui.GetFont()
        local baseF = imgui.GetFontSize()
        local step  = (n > 0) and (2 * math.pi / n) or 0
        local gap   = (n > 1) and 0.03 or 0.0

        for i = 1, n do
            local it = items[i]
            local hv = w.hov[i] or 0
            hv = hv + (((i == hover) and 1 or 0) - hv) * math.min(1, dt * 16)
            w.hov[i] = hv

            local ang  = -math.pi / 2 + (i - 1) * step
            local a0   = ang - step / 2 + gap
            local a1   = ang + step / 2 - gap
            local rOut = R_OUT + 12 * hv * scale
            local rMid = (R_IN + rOut) * 0.5

            -- segment: culoare care trece lin din inchis in cyan la hover
            local segCol = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(
                0.06 + 0.10 * hv, 0.08 + 0.61 * hv, 0.12 + 0.76 * hv, (0.84 + 0.08 * hv) * alpha))
            dl:PathArcTo(center, rMid, a0, a1, 36)
            dl:PathStroke(segCol, false, rOut - R_IN)
            -- linie subtire cyan pe marginea exterioara
            dl:PathArcTo(center, rOut - 1.5, a0, a1, 36)
            dl:PathStroke(imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.16, 0.69, 0.88, (0.30 + 0.60 * hv) * alpha)), false, 3)

            -- text: iconita (sus), eticheta, eticheta 2 (mica, gri)
            local lines = {}
            if it.icon then lines[#lines + 1] = { it.icon, baseF * 1.35 * scale, 0xFFFFFFFF } end
            lines[#lines + 1] = { PDX.tr(it.label or ""), baseF * (1.08 + 0.08 * hv) * scale, it.col or 0xFFFFFFFF }
            if it.label2 then lines[#lines + 1] = { it.label2, baseF * 0.92 * scale, 0xFFC8D0DC } end
            local totalH = 0
            for _, l in ipairs(lines) do totalH = totalH + l[2] + 2 end
            local tcx = cx + math.cos(ang) * (rMid + 4 * hv * scale)
            local ty  = cy + math.sin(ang) * (rMid + 4 * hv * scale) - totalH * 0.5
            for _, l in ipairs(lines) do
                local tw = font:CalcTextSizeA(l[2], 10000, -1, l[1]).x
                drawOutlinedText(dl, font, l[2], tcx - tw * 0.5, ty, PDX.colA(l[3], alpha), l[1])
                ty = ty + l[2] + 2
            end
        end

        -- centru: disc + inel cyan + titlu / indiciu
        local rC = R_IN - 12 * scale
        dl:AddCircleFilled(center, rC, PDX.colA(0xE60E131C, alpha), 64)
        dl:AddCircle(center, rC, imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.16, 0.69, 0.88, 0.55 * alpha)), 64, 2)
        local fT = baseF * scale
        local title = PDX.tr(tostring(lvl.title or ""))
        local ttw = font:CalcTextSizeA(fT, 10000, -1, title).x
        if ttw > rC * 1.9 then fT = fT * (rC * 1.9) / ttw; ttw = rC * 1.9 end
        drawOutlinedText(dl, font, fT, cx - ttw * 0.5, cy - 20 * scale, PDX.colA(0xFFE0AF28, alpha), title)
        local hint = tostring(lvl.hint or "")
        if w.held and n > 0 then hint = "Elibereaza [" .. tostring(cfg.settings.nWheelKey) .. "]: alege" end
        hint = PDX.tr(hint)
        local fH  = baseF * 0.92 * scale
        local htw = font:CalcTextSizeA(fH, 10000, -1, hint).x
        drawOutlinedText(dl, font, fH, cx - htw * 0.5, cy + 4 * scale, PDX.colA(0xFFC8D0DC, alpha), hint)
        -- puncte = nivelul curent (cat de adanc esti in meniu)
        local depth = #w.stack
        for d = 1, depth do
            local px = cx + (d - (depth + 1) / 2) * 12 * scale
            dl:AddCircleFilled(imgui.ImVec2(px, cy + 30 * scale), 3 * scale,
                PDX.colA(d == depth and 0xFFE0AF28 or 0x88C8D0DC, alpha), 12)
        end

        if not w.closeT then
            if imgui.IsMouseClicked(0) and hover > 0 and items[hover] then
                local it = items[hover]
                if it.sub then
                    PDX.wheelPush(it.sub)
                elseif it.run then
                    PDX.closeWheel()
                    it.run()
                end
            elseif imgui.IsMouseClicked(1) then
                PDX.wheelPop()
            end
            if imgui.IsKeyPressed(vkeys.VK_ESCAPE) then
                PDX.closeWheel()
            end
        end

        imgui.End()
        imgui.PopStyleVar(3)
    end
)
PDX.wheelFrame.HideCursor = false

-- =========================================================================================
--  UPDATE DE PE GITHUB (manual cu /pdupdate; verificarea la pornire e OPRITA implicit)
--  Modul merge normal si fara repo / internet - update-ul e doar un extra.
--  In repo (branch main) tii:
--    version.txt  -> linia 1 = versiunea + patch-ul, ex. "1.0 patch 3" (sau doar "1.1"); restul = ce s-a schimbat
--    PDAssist.lua -> cu script_version("1.0") si script_version_number(3) sus
--  E update daca versiunea e mai mare; la aceeasi versiune decide patch-ul.
-- =========================================================================================
PDX.UPDATE_RAW = "https://raw.githubusercontent.com/sylwy7/PDAssist/main/"
PDX.update     = { busy = false, latest = nil, latestPatch = 0, notes = {} }

-- compara doar versiunea: "1.10" > "1.9", "1.0.1" > "1.0"; intoarce 1 / 0 / -1
function PDX.verCompare(a, b)
    local pa, pb = {}, {}
    for n in tostring(a):gmatch("%d+") do pa[#pa + 1] = tonumber(n) end
    for n in tostring(b):gmatch("%d+") do pb[#pb + 1] = tonumber(n) end
    for i = 1, math.max(#pa, #pb) do
        local x, y = pa[i] or 0, pb[i] or 0
        if x ~= y then return (x > y) and 1 or -1 end
    end
    return 0
end

-- versiunea mai mare castiga; daca e aceeasi, castiga patch-ul mai mare
function PDX.verNewer(ver, patch, curVer, curPatch)
    local c = PDX.verCompare(ver, curVer)
    if c ~= 0 then return c > 0 end
    return (tonumber(patch) or 0) > (tonumber(curPatch) or 0)
end

function PDX.verLabel(ver, patch)
    patch = tonumber(patch) or 0
    return "v" .. tostring(ver) .. ((patch > 0) and (" patch " .. patch) or "")
end

function PDX.curVer()
    return tostring(thisScript().version), tonumber(thisScript().version_num) or 0
end

-- "1.0 patch 3" / "v1.0 p3" / "1.0 3" / "1.1" -> "1.0", 3
function PDX.parseVerLine(line)
    line = tostring(line or ""):lower()
    local ver, rest = line:match("^v?(%d+[%d%.]*%d)(.*)$")
    if not ver then ver, rest = line:match("^v?(%d+)(.*)$") end
    if not ver then return nil end
    rest = rest:gsub("^%s+", "")
    if rest == "" then return ver, 0 end
    local patch = rest:match("^[%(%-/,]?%s*p?a?t?c?h?%s*[:#=]?%s*(%d+)%)?$")
    if not patch then return nil end
    return ver, tonumber(patch)
end

-- descarca un URL intr-un fisier; cb(ok) cand termina (asincron, nu blocheaza jocul)
function PDX.download(url, path, cb)
    os.remove(path)
    local dl = require("moonloader").download_status
    local done = false
    -- ?t= ca sa nu ia o copie veche din cache-ul Windows
    downloadUrlToFile(url .. "?t=" .. tostring(os.time()), path, function(_, status)
        if done then return end
        if status == dl.STATUSEX_ENDDOWNLOAD then
            done = true
            local f = io.open(path, "rb")
            local ok = f ~= nil and f:seek("end") > 0
            if f then f:close() end
            cb(ok)
        end
    end)
end

function PDX.checkUpdate(manual)
    if PDX.update.busy then return end
    PDX.update.busy = true
    local tmp = getWorkingDirectory() .. "\\config\\PDAssist_version.tmp"
    PDX.download(PDX.UPDATE_RAW .. "version.txt", tmp, function(ok)
        PDX.update.busy = false
        local f = ok and io.open(tmp, "r")
        if not f then
            if manual then msg("{FF6347}Nu am putut verifica update-ul{FFFFFF} (fara internet sau GitHub indisponibil).") end
            return
        end
        local first, notes = nil, {}
        for line in f:lines() do
            line = line:gsub("\r", ""):gsub("^%s+", ""):gsub("%s+$", "")
            if not first then first = line elseif line ~= "" and #notes < 6 then notes[#notes + 1] = line end
        end
        f:close(); os.remove(tmp)
        local latest, latestPatch = PDX.parseVerLine(first)
        if not latest then
            if manual then msg("{FF6347}version.txt de pe GitHub e gresit{FFFFFF} (prima linie trebuie sa fie versiunea, ex. 1.0 patch 3).") end
            return
        end
        local cur, curPatch = PDX.curVer()
        PDX.update.latest, PDX.update.latestPatch, PDX.update.notes = latest, latestPatch, notes
        if PDX.verNewer(latest, latestPatch, cur, curPatch) then
            msg("Versiune noua: {28AFE0}" .. PDX.verLabel(latest, latestPatch) .. "{FFFFFF} - versiunea ta: {28AFE0}" .. PDX.verLabel(cur, curPatch) .. "{FFFFFF}. Scrie {28AFE0}/pdupdate{FFFFFF} ca sa o instalezi.")
            for _, n in ipairs(notes) do chatOut("{28AFE0}  - {FFFFFF}" .. n, -1) end
            addNotification("Update disponibil: " .. PDX.verLabel(latest, latestPatch) .. " (/pdupdate)", "info")
        elseif manual then
            msg("Ai deja ultima versiune ({28AFE0}" .. PDX.verLabel(cur, curPatch) .. "{FFFFFF}).")
        end
    end)
end


function PDX.installUpdate()
    if PDX.update.busy then return end
    PDX.update.busy = true
    msg("Descarc ultima versiune de pe GitHub...")
    local dir = getWorkingDirectory()
    local tmp = dir .. "\\config\\PDAssist_new.tmp"
    PDX.download(PDX.UPDATE_RAW .. "PDAssist.lua", tmp, function(ok)
        PDX.update.busy = false
        local f = ok and io.open(tmp, "rb")
        local src = f and f:read("*a") or ""
        if f then f:close() end
        -- verificari: e chiar PDAssist si nu are erori de sintaxa (altfel nu inlocuiesc nimic)
        local newVer   = src:match('script_version%("([^"]+)"%)')
        local newPatch = tonumber(src:match("script_version_number%((%d+)%)")) or 0
        if #src < 10000 or not src:find('script_name("B-Zone PDAssist")', 1, true) or not newVer then
            os.remove(tmp)
            msg("{FF6347}Update esuat:{FFFFFF} fisierul descarcat nu e PDAssist.lua valid.")
            return
        end
        local fn, err = loadstring(src, "PDAssist_new")
        if not fn then
            os.remove(tmp)
            msg("{FF6347}Update esuat:{FFFFFF} versiunea de pe GitHub are o eroare (" .. tostring(err):sub(1, 60) .. ").")
            return
        end
        local me = thisScript().path
        -- backup la versiunea curenta (o pui la loc manual daca ceva nu merge)
        local cf = io.open(me, "rb")
        if cf then
            local old = cf:read("*a"); cf:close()
            local bf = io.open(dir .. "\\config\\PDAssist_backup.lua", "wb")
            if bf then bf:write(old); bf:close() end
        end
        local out = io.open(me, "wb")
        if not out then
            os.remove(tmp)
            msg("{FF6347}Update esuat:{FFFFFF} nu pot scrie in " .. me)
            return
        end
        out:write(src); out:close(); os.remove(tmp)
        msg("Instalat {28AFE0}" .. PDX.verLabel(newVer, newPatch) .. "{FFFFFF}! Repornesc modul... (backup: config\\PDAssist_backup.lua)")
        lua_thread.create(function() wait(500); thisScript():reload() end)
    end)
end

function onScriptTerminate(scr, quitGame)
    if scr == thisScript() then
        if hudMoving or PDX.blMoving then
            showCursor(false, false)
        end
    end
end

function main()
    while not isSampAvailable() do wait(100) end

    syncHudSliders()
    registerAllCommands()

    msg("{28AFE0}" .. PDX.verLabel(PDX.curVer()) .. "{FFFFFF} incarcat! Foloseste {28AFE0}/pdc{FFFFFF} pentru toate meniurile.")
    if tonumber(cfg.settings.updateCheck) ~= 0 then
        lua_thread.create(function() wait(4000); PDX.checkUpdate(false) end)
    end

    local prevMmActive  = false
    local prevDActive   = false
    local prevAfkActive = false

    while true do
        wait(0)
        local now = os.clock()

        -- Update cached game state once per tick
        state.paused     = isPauseMenuActive()
        state.scoreboard = sampIsScoreboardOpen()
        state.dialog     = sampIsDialogActive()
        state.chat       = sampIsChatInputActive()
        state.inCar      = doesCharExist(PLAYER_PED) and isCharInAnyCar(PLAYER_PED)
        if state.inCar then
            local veh = storeCarCharIsInNoSave(PLAYER_PED)
            state.isDriving = (veh ~= 0 and doesVehicleExist(veh) and getDriverOfCar(veh) == PLAYER_PED)
        else
            state.isDriving = false
        end

        -- urci / cobori din masina cu roata deschisa -> se inchide (alt meniu pt sofer vs pe jos)
        if PDX.wheel.open and not PDX.wheel.closeT and PDX.wheel.mode ~= (state.isDriving and "car" or "foot") then
            PDX.closeWheel()
        end

        -- 1. HUD Mouse Dragging Handler (/hudpos)
        if hudMoving then
            if not hudMoveArmed then
                if not isKeyDown(vkeys.VK_LBUTTON) and (now - hudMoveStartTime > 0.18) then
                    hudMoveArmed = true
                end
            else
                if wasKeyPressed(vkeys.VK_LBUTTON) then
                    local mx, my = getCursorPos()
                    local sw, sh = getScreenResCached()
                    local px = math.max(hudLastWidth + 10, math.min(sw - 6, mx + hudLastWidth * 0.5))
                    local py = math.max(10, math.min(sh - hudLastHeight - 10, my - hudLastHeight * 0.5))
                    local kC, kX, kY = PDX.hudPosKeys() -- salveaza pt stilul activ (modern / clasic)
                    cfg.settings[kC] = true
                    cfg.settings[kX] = math.floor(px)
                    cfg.settings[kY] = math.floor(py)
                    saveCfg()
                    syncHudSliders()
                    hudMoving    = false
                    hudMoveArmed = false
                    showCursor(false, false)
                    addNotification("Pozitia HUD salvata cu succes!", "saved")
                elseif wasKeyPressed(vkeys.VK_ESCAPE) then
                    hudMoving    = false
                    hudMoveArmed = false
                    showCursor(false, false)
                    addNotification("Mutarea HUD anulata", "info")
                end
            end
        end

        -- 2. Live Keybind Capture Handler
        if capturingBind then
            for k = 1, 254 do
                if wasKeyPressed(k) and k ~= vkeys.VK_LBUTTON and k ~= vkeys.VK_RBUTTON then
                    if k == vkeys.VK_ESCAPE then
                        capturingBind = nil
                        addNotification("Setarea tastei anulata", "info")
                    else
                        local kLabel = cleanKeyName(k)
                        cfg[capturingBind.section][capturingBind.keyId]   = k
                        cfg[capturingBind.section][capturingBind.keyName] = kLabel
                        saveCfg()
                        addNotification(capturingBind.label .. " -> [" .. kLabel .. "]", "saved")
                        capturingBind = nil
                    end
                    break
                end
            end
        end

        -- 3. Classic SA-MP Dialog 7000 Response Handler (if classic mode selected)
        local hasResp, btn, item, _ = sampHasDialogRespond(7000)
        if hasResp and btn == 1 and classicSanctionTarget >= 0 then
            local tid = classicSanctionTarget
            if classicSanctionRoads then
                if item == 0 then sanctionDirect("aa", tid)
                elseif item == 1 then sanctionWithIdCheck("aa50", tid)
                elseif item == 2 then sanctionWithIdCheck("aa100", tid)
                elseif item == 4 then sanctionDirect("faruri", tid)
                elseif item == 5 then sanctionDirect("car", tid)
                elseif item == 6 then sanctionDirect("alc15", tid)
                elseif item == 8 then sanctionWithIdCheck("nos", tid)
                elseif item == 9 then sanctionWithIdCheck("con", tid)
                elseif item == 10 then sanctionWithIdCheck("parc", tid)
                elseif item == 11 then sanctionWithIdCheck("hidra", tid)
                elseif item == 12 then sanctionWithIdCheck("alc30", tid)
                elseif item == 14 then sanctionDirect("arme", tid)
                elseif item == 15 then sanctionDirect("dr", tid)
                elseif item == 16 then sanctionDirect("cdr", tid)
                elseif item == 18 then sanctionDirect("matslic", tid)
                elseif item == 19 then sanctionWithIdCheck("mats", tid)
                end
            else
                if item == 0 then sanctionDirect("arme", tid)
                elseif item == 1 then sanctionDirect("dr", tid)
                elseif item == 2 then sanctionDirect("cdr", tid)
                elseif item == 4 then sanctionDirect("matslic", tid)
                elseif item == 5 then sanctionWithIdCheck("mats", tid)
                end
            end
        end

        -- 4. Timer Expiration Alerts
        local mmAct = (timers.mmEnd > now)
        if prevMmActive and not mmAct then
            msg("Au trecut {28AFE0}3 secunde{FFFFFF} de la somatie!")
            addNotification("Au trecut 3 secunde!", "timer")
        end
        prevMmActive = mmAct

        local dAct = (timers.dEnd > now)
        if prevDActive and not dAct then
            msg("Au trecut {28AFE0}10 secunde{FFFFFF}!")
            addNotification("Au trecut 10 secunde!", "timer")
        end
        prevDActive = dAct

        local afkAct = (timers.afkEnd > now)
        if prevAfkActive and not afkAct and timers.afkLabel ~= "" then
            msg("Timpul AFK ({28AFE0}" .. timers.afkLabel .. "{FFFFFF}) a expirat!")
            addNotification("Timpul AFK a expirat! (" .. timers.afkLabel .. ")", "timer")
            timers.afkLabel = ""
            PDX.afkExpired()
        end
        prevAfkActive = afkAct

        -- 5. Hotkeys Execution (only when chat/dialog/pause/capture inactive)
        if not capturingBind and not hudMoving and isKeySafe() then
            if cfg.settings.menuKeyOn == 1 and wasKeyPressed(cfg.settings.menuKey) then
                PDX.runHotkeyAction(cfg.settings.kAction)
            end
            if cfg.settings.lKeyOn == 1 and wasKeyPressed(cfg.settings.lKey) then
                PDX.runHotkeyAction(cfg.settings.lAction)
            end
            if cfg.settings.wheelOn == 1 and wasKeyPressed(cfg.settings.wheelKey) then
                if PDX.wheel.open and not PDX.wheel.closeT then
                    PDX.closeWheel()
                else
                    PDX.openWheel()
                    PDX.wheel.held = (tostring(cfg.settings.wheelMode or "hold") ~= "touch")
                end
            end
            if cfg.pd.somatie == 1 and wasKeyPressed(cfg.pd.TastaS) then
                say("/ms")
            end
            if isRutieraActive() and cfg.pd.radar == 1 and wasKeyPressed(cfg.pd.TastaR) then
                triggerRadarKeyAction()
            end
            if cfg.pd.cuffarrest == 1 and wasKeyPressed(cfg.pd.TastaCA) then
                triggerCuffKeyAction()
            end
            if cfg.pd.frisk == 1 and wasKeyPressed(cfg.pd.TastaF) then
                triggerFriskKeyAction()
            end
            if cfg.pd.tazer == 1 and wasKeyPressed(cfg.pd.TastaT) then
                say("/tazer")
            end
            if cfg.pd.wanted == 1 and wasKeyPressed(cfg.pd.TastaWA) then
                say("/wanted")
            end
            if cfg.pd.nearwanted == 1 and wasKeyPressed(cfg.pd.TastaNWA) then
                say("/nearwanted")
            end
            if cfg.pd.repairon == 1 and state.isDriving and wasKeyPressed(cfg.pd.TastaRepair) then
                say("/repair")
            end
            if cfg.settings.gateKeyOn == 1 and wasKeyPressed(cfg.settings.gateKey) then
                triggerGateKeyAction()
            end
            PDX.runCustomKeybinds()
        end

        -- 5A. Login automat (pe dialogul vizibil)
        PDX.loginPoll()

        -- 5A2. Salvare intarziata a culorilor din tab-ul Aspect (dupa ce te opresti din tras de culoare)
        if PDX.lookSaveAt and now > PDX.lookSaveAt then
            PDX.lookSaveAt = nil
            saveCfg()
        end
        -- Salvare intarziata a rotii personalizate (dupa ce te opresti din scris)
        if PDX.cwSaveAt and now > PDX.cwSaveAt then
            PDX.cwSave()
        end

        -- 5B. Roata in mod Hold: cand eliberezi tasta se executa felia de sub mouse
        if PDX.wheel.held then
            if not PDX.wheel.open or PDX.wheel.closeT then
                PDX.wheel.held = false
            elseif not isKeyDown(cfg.settings.wheelKey) then
                PDX.wheel.held = false
                PDX.wheelRelease()
            end
        end

        -- 6. Auto-Arrest Proximity Check (with 2.5s anti-spam cooldown)
        if cfg.pd.cuffarrest == 1 and cfg.pd.arrestid and cfg.pd.arrestid >= 0 and state.inCar then
            if (now - lastAutoArrestTime) > 2.5 and isNearAnyArrestPoint() then
                local aid = cfg.pd.arrestid
                if sampIsPlayerConnected(aid) then
                    local ok, ped = sampGetCharHandleBySampPlayerId(aid)
                    local myCar = storeCarCharIsInNoSave(PLAYER_PED)
                    if ok and doesCharExist(ped) and myCar ~= 0 and isCharInCar(ped, myCar) then
                        lastAutoArrestTime = now
                        say("/arrest " .. aid)
                        addNotification("Auto-Arrest executat pe ID " .. aid, "saved")
                    end
                else
                    cfg.pd.arrestid = -1
                end
            end
        end

        -- 7. Start-Stop Engine System (10s idle -> /engine, W/S restarts)
        if cfg.pd.startstop == 1 and state.isDriving then
            local veh = storeCarCharIsInNoSave(PLAYER_PED)
            local spd = (veh ~= 0 and doesVehicleExist(veh)) and math.floor(getCarSpeed(veh)) or 0
            if spd == 0 then
                if isKeyDown(vkeys.VK_2) then
                    ssStep = 3
                end
                if ssStep == 0 then
                    ssIdleStart = now
                    ssStep = 1
                elseif ssStep == 1 and (now - ssIdleStart) >= 10.0 then
                    say("/engine")
                    ssStep = 2
                    addNotification("Start-Stop: Motor oprit (economie combustibil)", "info")
                elseif ssStep == 2 and not state.chat and not state.dialog then
                    if isKeyDown(vkeys.VK_W) or isKeyDown(vkeys.VK_S) then
                        say("/engine")
                        ssStep = 0
                    end
                end
            else
                ssStep = 0
            end
        else
            ssStep = 0
        end
    end
end
