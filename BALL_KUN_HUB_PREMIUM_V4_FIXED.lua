--========================================================
-- BALL KUN HUB | PREMIUM INTELLIGENT SYSTEM v4.0
-- Credit: บอลคุง ไงหนู
-- Game: MAHANAKHON RACING
-- Executor: Ninja Executor (Client-Side Lua)
--
-- Features:
-- 1. Pure White Typography System (ฟอนต์สีขาวทั้งระบบ อ่านชัดพรีเมียม)
-- 2. Smart Thai Pin Translator (กรองชิ้นส่วนหลอกเช่น KneeBrace และแปลปักหมุดเป็นภาษาไทย)
-- 3. Responsive UIScale + Drag/Resize (ไม่ล้นขอบจอมือถือ/แท็บเล็ต)
-- 4. Full In-Game UI Customizer (ระบบปรับแต่ง UI ได้ทั้งหมดแบบเรียลไทม์)
-- 5. Safe Prep Mode for Auto Systems (เตรียมระบบออโต้ไว้ต่อยอดภายหลัง)
-- Background Asset: BALL_KUN_BG.png
--========================================================

if game.PlaceId ~= 104549080643413 then
    warn("[BALL KUN HUB] PlaceId ไม่ตรงกับ MAHANAKHON RACING")
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()

local CONFIG = {
    HubTitle = "BALL KUN HUB",
    Subtitle = "PREMIUM INTELLIGENT SYSTEM v4.0",
    Tagline = "ระบบนำทางแปลภาษาไทย • ปรับแต่ง UI ได้ทั้งหมด • เตรียมพร้อมระบบออโต้",
    Credit = "บอลคุง ไงหนู",
    Background = "BALL_KUN_BG.png",
    -- ลิงก์ดาวน์โหลดภาพปกหลัง (อัปโหลด BALL_KUN_BG.png ไว้ใน repo แล้วแก้ลิงก์ให้ตรง)
    BackgroundUrl = "https://raw.githubusercontent.com/ballkun551-max/Kjhhhh.lua/main/BALL_KUN_BG.png",
    BackgroundEnabled = true,
    BackgroundTransparency = 0.38,
    BackgroundScrimTransparency = 0.55,
    BackgroundScaleMode = Enum.ScaleType.Crop,
    WindowWidth = 960,
    WindowHeight = 620,
    SidebarWidth = 215,
    CornerRadius = 14,
    PanelTransparency = 0.10,
    BorderThickness = 1.5,
    BorderTransparency = 0.55,
    UiScale = 1.00,
    AutoFitMobile = true,
    FontScale = 1.00,
    FontBold = Enum.Font.GothamBold,
    FontRegular = Enum.Font.GothamMedium,
    ShowRightPanel = true,
    ShowFooter = true,
    SmoothMotion = true,
    FilterInvalidParts = true,
    ShowRawNameHint = false,
}

local Theme = {
    surface = Color3.fromRGB(7, 12, 9),
    card = Color3.fromRGB(12, 21, 16),
    cardActive = Color3.fromRGB(26, 43, 32),
    accent = Color3.fromRGB(16, 185, 129),
    accentFill = Color3.fromRGB(10, 67, 47),
    white = Color3.fromRGB(255, 255, 255), -- ฟอนต์ทั้งหมดเป็นสีขาวบริสุทธิ์
    mutedWhite = Color3.fromRGB(242, 246, 244),
    switchOff = Color3.fromRGB(40, 48, 44),
}

local PIN_RULES = {
    { keyword = "racestart", thai = "จุดปล่อยตัวสนามแข่ง", category = "สนามแข่ง" },
    { keyword = "racefinish", thai = "เส้นชัยสนามแข่ง", category = "สนามแข่ง" },
    { keyword = "drag", thai = "สนามแดร็กทางตรง", category = "สนามแข่ง" },
    { keyword = "tuneshop", thai = "ร้านจูนรถและแต่งเครื่อง", category = "จูนและแต่งรถ" },
    { keyword = "dyno", thai = "แท่นทดสอบแรงม้า (ไดโน่)", category = "จูนและแต่งรถ" },
    { keyword = "tune", thai = "จุดจูนรถ", category = "จูนและแต่งรถ" },
    { keyword = "garage", thai = "อู่ซ่อมและเก็บรถ", category = "อู่รถ" },
    { keyword = "repair", thai = "จุดซ่อมรถฉุกเฉิน", category = "อู่รถ" },
    { keyword = "dealer", thai = "โชว์รูมซื้อขายรถ", category = "ร้านค้า" },
    { keyword = "piston", thai = "ร้านลูกสูบ 53–90", category = "ร้านค้า" },
    { keyword = "fuel", thai = "ปั๊มน้ำมันเชื้อเพลิง", category = "บริการ" },
    { keyword = "gas", thai = "จุดเติมน้ำมัน", category = "บริการ" },
    { keyword = "shop", thai = "ร้านค้าอุปกรณ์รถ", category = "ร้านค้า" },
    { keyword = "race", thai = "จุดแข่งขันในแผนที่", category = "สนามแข่ง" },
}

local IGNORED_PART_KEYWORDS = {
    "kneebrace", "brace", "accessory", "humanoid", "torso",
    "leftarm", "rightarm", "leftleg", "rightleg", "head",
    "handle", "shirt", "pants", "helmet", "glove", "shoe", "boot", "wheel", "tire"
}

local S = {
    page = "หน้าหลัก",
    selectedCar = nil,
    selectedTarget = nil,
    route = {},
    fps = false,
    saved = {},
    flags = {},
    alive = true,
    piston = 53,
    lastPiston = "",
    dynamicRefs = {},
}

-- ระบบแจ้ง Error: เรียกฟังก์ชันแบบปลอดภัย ถ้าพังจะ warn บอกสาเหตุแทนที่จะทำให้ทั้ง UI ค้าง
local function safeCall(label, fn, ...)
    if type(fn) ~= "function" then
        warn("[BALL KUN HUB] safeCall(" .. tostring(label) .. "): ไม่ใช่ฟังก์ชัน")
        return false
    end
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[BALL KUN HUB] Error @ " .. tostring(label) .. " : " .. tostring(err))
    end
    return ok, err
end

-- ===== ระบบบันทึก / โหลด / รีเซ็ตการตั้งค่า UI =====
local HttpService = game:GetService("HttpService")
local SETTINGS_FILE = "BALL_KUN_HUB_V4_settings.json"
local SAVE_KEYS = {
    "UiScale", "FontScale", "WindowWidth", "WindowHeight", "SidebarWidth", "CornerRadius",
    "PanelTransparency", "BorderThickness", "BackgroundEnabled", "BackgroundTransparency",
    "BackgroundScrimTransparency", "ShowRightPanel", "ShowFooter", "SmoothMotion", "FilterInvalidParts",
}
local DEFAULT_CONFIG = {}
for _, k in ipairs(SAVE_KEYS) do DEFAULT_CONFIG[k] = CONFIG[k] end
local DEFAULT_ACCENT = Theme.accent
local DEFAULT_ACCENT_FILL = Theme.accentFill
local RGB = {border = false, strokes = false, glow = false, text = false, speed = 1}
local FONT_NAME = "ค่าเริ่มต้น"

local function deriveFill(c)
    return Color3.new(c.R * 0.38, c.G * 0.38, c.B * 0.38)
end

local function saveSettings()
    if not writefile then return false, "executor ไม่รองรับ writefile" end
    local data = {}
    for _, k in ipairs(SAVE_KEYS) do data[k] = CONFIG[k] end
    local a = Theme.accent
    data.accent = {math.floor(a.R * 255 + 0.5), math.floor(a.G * 255 + 0.5), math.floor(a.B * 255 + 0.5)}
    data.fontName = FONT_NAME
    data.rgb = {border = RGB.border, strokes = RGB.strokes, glow = RGB.glow, text = RGB.text, speed = RGB.speed}
    local ok, err = pcall(function() writefile(SETTINGS_FILE, HttpService:JSONEncode(data)) end)
    if not ok then
        warn("[BALL KUN HUB] บันทึกการตั้งค่าไม่สำเร็จ: " .. tostring(err))
        return false, tostring(err)
    end
    return true
end

local function loadSettings()
    if not (isfile and readfile) then return false, "NOFILE" end
    if not isfile(SETTINGS_FILE) then return false, "NOFILE" end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(SETTINGS_FILE)) end)
    if not ok or type(data) ~= "table" then
        warn("[BALL KUN HUB] ไฟล์ตั้งค่าเสียหรืออ่านไม่ได้: " .. tostring(data))
        return false, "ไฟล์ตั้งค่าเสียหาย"
    end
    for _, k in ipairs(SAVE_KEYS) do
        if data[k] ~= nil and type(data[k]) == type(CONFIG[k]) then CONFIG[k] = data[k] end
    end
    if type(data.accent) == "table" and #data.accent == 3 then
        local c = Color3.fromRGB(data.accent[1], data.accent[2], data.accent[3])
        Theme.accent = c
        Theme.accentFill = deriveFill(c)
    end
    if type(data.fontName) == "string" then FONT_NAME = data.fontName end
    if type(data.rgb) == "table" then
        for _, m in ipairs({"border", "strokes", "glow", "text"}) do
            if type(data.rgb[m]) == "boolean" then RGB[m] = data.rgb[m] end
        end
        if type(data.rgb.speed) == "number" then RGB.speed = math.clamp(data.rgb.speed, 0.5, 5) end
    end
    return true
end

do
    local ok, msg = loadSettings()
    if not ok and msg ~= "NOFILE" then warn("[BALL KUN HUB] โหลดการตั้งค่าไม่สำเร็จ: " .. tostring(msg)) end
end

local function new(class, props, parent)
    local x = Instance.new(class)
    for k, v in pairs(props or {}) do x[k] = v end
    x.Parent = parent
    return x
end

local function corner(obj, r)
    return new("UICorner", {CornerRadius = UDim.new(0, r or CONFIG.CornerRadius)}, obj)
end

local function stroke(obj, color, thick, trans)
    return new("UIStroke", {
        Color = color or Theme.accent,
        Thickness = thick or CONFIG.BorderThickness,
        Transparency = trans or CONFIG.BorderTransparency,
    }, obj)
end

local function gradient(obj, c1, c2, rot)
    return new("UIGradient", {Color = ColorSequence.new(c1, c2), Rotation = rot or 30}, obj)
end

local function fs(baseSize)
    return math.max(9, math.round(baseSize * CONFIG.FontScale))
end

local function tweenProp(obj, props, dur)
    if not CONFIG.SmoothMotion then
        for k, v in pairs(props) do obj[k] = v end
        return
    end
    TweenService:Create(obj, TweenInfo.new(dur or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

-- Clean old instance if re-executed
local GUI_NAME = "BALL_KUN_HUB_PREMIUM_V4"
local function getContainers()
    local list = {}
    if type(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and h then table.insert(list, {"gethui()", h}) end
    end
    local okCore, core = pcall(function() return game:GetService("CoreGui") end)
    if okCore and core then table.insert(list, {"CoreGui", core}) end
    local pg = LP:FindFirstChildOfClass("PlayerGui") or LP:FindFirstChild("PlayerGui")
    if pg then table.insert(list, {"PlayerGui", pg}) end
    return list
end

safeCall("CleanOldGui", function()
    for _, c in ipairs(getContainers()) do
        local old = c[2]:FindFirstChild(GUI_NAME)
        if old then old:Destroy() end
    end
end)

local Gui = new("ScreenGui", {
    Name = GUI_NAME,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, nil)

-- ลอง Parent ตามลำดับ gethui -> CoreGui -> PlayerGui และ warn ทุกครั้งที่ล้มเหลว
local parentedTo = nil
for _, c in ipairs(getContainers()) do
    local ok, err = pcall(function() Gui.Parent = c[2] end)
    if ok and Gui.Parent then
        parentedTo = c[1]
        break
    end
    warn("[BALL KUN HUB] Parent GUI เข้า " .. c[1] .. " ไม่สำเร็จ: " .. tostring(err))
end
if not parentedTo then
    local okPG, pg = pcall(function() return LP:WaitForChild("PlayerGui", 10) end)
    if okPG and pg then
        Gui.Parent = pg
        parentedTo = "PlayerGui (WaitForChild)"
    else
        error("[BALL KUN HUB] ไม่สามารถ Parent ScreenGui ได้เลย (gethui/CoreGui/PlayerGui)")
    end
end
print("[BALL KUN HUB] ScreenGui parent =", parentedTo)

local Main = new("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(CONFIG.WindowWidth, CONFIG.WindowHeight),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundColor3 = Theme.surface,
    BackgroundTransparency = CONFIG.PanelTransparency,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, Gui)
local MainCorner = corner(Main, CONFIG.CornerRadius)
local MainStroke = stroke(Main, Theme.accent, CONFIG.BorderThickness, 0.15)
gradient(Main, Theme.card, Theme.surface, 35)

local MainScale = new("UIScale", {Scale = CONFIG.UiScale}, Main)

local function updateResponsiveScale()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local baseScale = CONFIG.UiScale
    if CONFIG.AutoFitMobile then
        local fitX = (vp.X - 24) / math.max(1, Main.Size.X.Offset)
        local fitY = (vp.Y - 24) / math.max(1, Main.Size.Y.Offset)
        local fit = math.min(1, fitX, fitY)
        MainScale.Scale = math.clamp(math.min(baseScale, fit), 0.45, 1.35)
    else
        MainScale.Scale = math.clamp(baseScale, 0.45, 1.35)
    end
end
updateResponsiveScale()
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale)
end

-- Background Artwork + Dark Scrim for readable White Text
local Art = new("ImageLabel", {
    Name = "Backdrop",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ImageTransparency = CONFIG.BackgroundTransparency,
    ScaleType = CONFIG.BackgroundScaleMode,
    Visible = CONFIG.BackgroundEnabled,
    ZIndex = 0,
}, Main)
-- ภาพปกหลังโหลดด้วย loadBackdrop() ในบล็อก Appearance ด้านล่าง

local Scrim = new("Frame", {
    Name = "BackdropScrim",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Theme.surface,
    BackgroundTransparency = CONFIG.BackgroundScrimTransparency,
    BorderSizePixel = 0,
    ZIndex = 1,
}, Main)

-- Top Header (Premium Luxury Bar, All White Typography)
local Top = new("Frame", {
    Size = UDim2.new(1, 0, 0, 88),
    BackgroundColor3 = Theme.surface,
    BackgroundTransparency = 0.18,
    BorderSizePixel = 0,
    ZIndex = 3,
}, Main)
local TopStroke = stroke(Top, Theme.accent, 1, 0.45)

local Logo = new("TextLabel", {
    Position = UDim2.new(0, 18, 0, 10),
    Size = UDim2.new(1, -130, 0, 32),
    BackgroundTransparency = 1,
    Text = "♛  " .. CONFIG.HubTitle,
    TextColor3 = Theme.white,
    Font = Enum.Font.GothamBlack,
    TextSize = fs(24),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
}, Top)

local Sub = new("TextLabel", {
    Position = UDim2.new(0, 18, 0, 42),
    Size = UDim2.new(1, -130, 0, 18),
    BackgroundTransparency = 1,
    Text = CONFIG.Subtitle .. "  •  โดย " .. CONFIG.Credit,
    TextColor3 = Theme.white,
    Font = CONFIG.FontBold,
    TextSize = fs(12),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
}, Top)

local Tagline = new("TextLabel", {
    Position = UDim2.new(0, 18, 0, 62),
    Size = UDim2.new(1, -130, 0, 18),
    BackgroundTransparency = 1,
    Text = CONFIG.Tagline,
    TextColor3 = Theme.mutedWhite,
    Font = CONFIG.FontRegular,
    TextSize = fs(11),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
}, Top)

local Reopen = new("TextButton", {
    Size = UDim2.fromOffset(164, 42),
    Position = UDim2.new(0, 16, 0.5, -21),
    BackgroundColor3 = Theme.surface,
    Text = "♛  " .. CONFIG.HubTitle,
    TextColor3 = Theme.white,
    Font = Enum.Font.GothamBlack,
    TextSize = 13,
    Visible = false,
    ZIndex = 50,
}, Gui)
corner(Reopen, 10)
stroke(Reopen, Theme.accent, 1.5, 0.2)

local function topButton(text, xOffset, callback)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(34, 32),
        Position = UDim2.new(1, xOffset, 0, 14),
        BackgroundColor3 = Theme.cardActive,
        Text = text,
        TextColor3 = Theme.white,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        ZIndex = 5,
    }, Top)
    corner(b, 8)
    stroke(b, Theme.accent, 1, 0.35)
    b.MouseButton1Click:Connect(function() safeCall("topButton:" .. tostring(text), callback) end)
    return b
end

topButton("—", -86, function()
    Main.Visible = false
    Reopen.Visible = true
end)

topButton("×", -44, function()
    S.alive = false
    if S.fps then
        Lighting.GlobalShadows = S.saved.shadows
        Lighting.FogEnd = S.saved.fog
        for obj, v in pairs(S.saved.effects or {}) do
            if obj and obj.Parent then pcall(function() obj.Enabled = v end) end
        end
    end
    Gui:Destroy()
end)

Reopen.MouseButton1Click:Connect(function()
    Main.Visible = true
    Reopen.Visible = false
end)

-- Layout Containers
local Sidebar = new("ScrollingFrame", {
    Position = UDim2.fromOffset(12, 98),
    Size = UDim2.new(0, CONFIG.SidebarWidth, 1, CONFIG.ShowFooter and -150 or -110),
    BackgroundColor3 = Theme.surface,
    BackgroundTransparency = 0.16,
    BorderSizePixel = 0,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = Theme.accent,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex = 3,
}, Main)
corner(Sidebar, math.max(6, CONFIG.CornerRadius - 2))
stroke(Sidebar, Theme.accent, 1, 0.55)
new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, Sidebar)
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, Sidebar)

local RightWidth = 196
local Right = new("Frame", {
    Position = UDim2.new(1, -(RightWidth + 12), 0, 98),
    Size = UDim2.new(0, RightWidth, 1, CONFIG.ShowFooter and -150 or -110),
    BackgroundTransparency = 1,
    Visible = CONFIG.ShowRightPanel,
    ZIndex = 3,
}, Main)
new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, Right)

local Body = new("Frame", {
    Position = UDim2.fromOffset(CONFIG.SidebarWidth + 22, 98),
    Size = UDim2.new(1, -(CONFIG.SidebarWidth + (CONFIG.ShowRightPanel and (RightWidth + 44) or 34)), 1, CONFIG.ShowFooter and -150 or -110),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 3,
}, Main)

local Scroll = new("ScrollingFrame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Theme.accent,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex = 3,
}, Body)
local BodyList = new("UIListLayout", {Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder}, Scroll)
new("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 12)}, Scroll)

local Footer = new("Frame", {
    Position = UDim2.new(0, 12, 1, -44),
    Size = UDim2.new(1, -24, 0, 32),
    BackgroundColor3 = Theme.surface,
    BackgroundTransparency = 0.14,
    Visible = CONFIG.ShowFooter,
    ZIndex = 4,
}, Main)
corner(Footer, 9)
stroke(Footer, Theme.accent, 1, 0.5)
new("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "⚡ ใช้งานง่าย   •   🛡 โหมดตรวจสอบปลอดภัย   •   🇹🇭 ปักหมุดแปลไทย   •   ♛ " .. CONFIG.Credit,
    TextColor3 = Theme.white,
    Font = CONFIG.FontBold,
    TextSize = fs(11),
    ZIndex = 5,
}, Footer)

local function applyLayoutRefresh()
    Main.Size = UDim2.fromOffset(CONFIG.WindowWidth, CONFIG.WindowHeight)
    Main.BackgroundTransparency = CONFIG.PanelTransparency
    MainCorner.CornerRadius = UDim.new(0, CONFIG.CornerRadius)
    MainStroke.Color = RGB.border and Color3.fromRGB(255, 255, 255) or Theme.accent
    MainStroke.Thickness = CONFIG.BorderThickness
    TopStroke.Color = RGB.border and Color3.fromRGB(255, 255, 255) or Theme.accent
    Art.Visible = CONFIG.BackgroundEnabled
    Art.ImageTransparency = CONFIG.BackgroundTransparency
    Scrim.BackgroundTransparency = CONFIG.BackgroundScrimTransparency
    Right.Visible = CONFIG.ShowRightPanel
    Footer.Visible = CONFIG.ShowFooter

    local bottomOffset = CONFIG.ShowFooter and -150 or -110
    Sidebar.Size = UDim2.new(0, CONFIG.SidebarWidth, 1, bottomOffset)
    Right.Size = UDim2.new(0, RightWidth, 1, bottomOffset)
    Body.Position = UDim2.fromOffset(CONFIG.SidebarWidth + 22, 98)
    Body.Size = UDim2.new(1, -(CONFIG.SidebarWidth + (CONFIG.ShowRightPanel and (RightWidth + 44) or 34)), 1, bottomOffset)
    updateResponsiveScale()
end

-- ===== Appearance: สีหลัก / ฟอนต์ / ไฟรุ้ง / ภาพปกหลัง =====
local RAINBOW_SEQ = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0.00, 1, 1)),
    ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
    ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
    ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
    ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
    ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
    ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1.00, 1, 1)),
})
local MainGrad = new("UIGradient", {Color = RAINBOW_SEQ, Enabled = false}, MainStroke)
local TopGrad = new("UIGradient", {Color = RAINBOW_SEQ, Enabled = false}, TopStroke)
local Glow = new("Frame", {
    Name = "RainbowGlow",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.84,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 1,
}, Main)
local GlowGrad = new("UIGradient", {Color = RAINBOW_SEQ}, Glow)

local function setAccent(c, fill)
    local old, oldFill = Theme.accent, Theme.accentFill
    Theme.accent = c
    Theme.accentFill = fill or deriveFill(c)
    for _, v in ipairs(Gui:GetDescendants()) do
        if v:IsA("UIStroke") then
            if v.Color == old then v.Color = c end
        elseif v:IsA("ScrollingFrame") then
            v.ScrollBarImageColor3 = c
        end
        if v:IsA("GuiObject") and v.BackgroundColor3 == oldFill then v.BackgroundColor3 = Theme.accentFill end
    end
    applyLayoutRefresh()
end

-- ฟอนต์ที่เลือกได้ (ชื่อต้องตรงกับ Enum.Font) ถ้าชื่อใดไม่มีในเกมจะ warn แล้วใช้ค่าเดิม
local FONT_LIST = {
    "ค่าเริ่มต้น", "GothamBold", "GothamBlack", "Gotham", "Arcade", "SciFi", "Bangers", "Michroma",
    "Oswald", "Ubuntu", "Nunito", "FredokaOne", "LuckiestGuy", "PermanentMarker", "Fantasy",
    "Code", "Jura", "Sarpanch", "TitilliumWeb", "SourceSansBold", "Cartoon", "Highway", "SpecialElite",
}
local origFont = setmetatable({}, {__mode = "k"})
local function applyFontAll()
    local chosen = nil
    if FONT_NAME ~= "ค่าเริ่มต้น" then
        local ok, f = pcall(function() return Enum.Font[FONT_NAME] end)
        if ok and f then chosen = f else warn("[BALL KUN HUB] ไม่พบฟอนต์: " .. tostring(FONT_NAME)) end
    end
    for _, v in ipairs(Gui:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then
            if origFont[v] == nil then origFont[v] = v.Font end
            v.Font = chosen or origFont[v]
        end
    end
end
local function setFont(name)
    FONT_NAME = name
    applyFontAll()
end

-- ภาพปกหลัง: ดาวน์โหลดจาก CONFIG.BackgroundUrl -> writefile -> getcustomasset
local BG_STATUS = "ยังไม่ได้โหลดภาพปกหลัง"
local function loadBackdrop(force)
    if not getcustomasset then
        BG_STATUS = "executor ไม่รองรับ getcustomasset"
        warn("[BALL KUN HUB] " .. BG_STATUS)
        return false
    end
    local hasFile = false
    local ok, err = pcall(function()
        hasFile = (isfile and isfile(CONFIG.Background)) and true or false
        if (force or not hasFile) and CONFIG.BackgroundUrl ~= "" and writefile then
            local data = game:HttpGet(CONFIG.BackgroundUrl)
            if type(data) == "string" and data:sub(2, 4) == "PNG" then
                writefile(CONFIG.Background, data)
                hasFile = true
            else
                error("ดาวน์โหลดภาพไม่สำเร็จ (ตรวจลิงก์/ชื่อไฟล์/ว่า repo เป็น public)")
            end
        end
        if hasFile then Art.Image = getcustomasset(CONFIG.Background) end
    end)
    if not ok then
        BG_STATUS = "โหลดภาพปกหลังไม่สำเร็จ: " .. tostring(err)
        warn("[BALL KUN HUB] " .. BG_STATUS)
        return false
    end
    if hasFile then
        BG_STATUS = "ตั้งภาพปกหลังแล้ว (" .. CONFIG.Background .. ")"
    else
        BG_STATUS = "ไม่พบไฟล์ " .. CONFIG.Background .. " และไม่ได้ตั้งลิงก์ดาวน์โหลด"
        warn("[BALL KUN HUB] " .. BG_STATUS)
    end
    return hasFile
end
safeCall("loadBackdrop", loadBackdrop, false)

-- ไฟรุ้ง
local strokeCache, textCache = {}, {}
local function refreshRgbCache()
    strokeCache, textCache = {}, {}
    for _, v in ipairs(Gui:GetDescendants()) do
        if v:IsA("UIStroke") then
            table.insert(strokeCache, v)
        elseif v:IsA("TextLabel") or v:IsA("TextButton") then
            table.insert(textCache, v)
        end
    end
end
local WHITE = Color3.fromRGB(255, 255, 255)
local function isMainStroke(v) return v == MainStroke or v == TopStroke end
local function setRgb(mode, on)
    RGB[mode] = on and true or false
    if mode == "border" then
        MainGrad.Enabled = RGB.border
        TopGrad.Enabled = RGB.border
        MainStroke.Color = RGB.border and WHITE or Theme.accent
        TopStroke.Color = RGB.border and WHITE or Theme.accent
    elseif mode == "glow" then
        Glow.Visible = RGB.glow
    elseif mode == "strokes" and not RGB.strokes then
        refreshRgbCache()
        for _, v in ipairs(strokeCache) do
            if v.Parent then v.Color = (RGB.border and isMainStroke(v)) and WHITE or Theme.accent end
        end
    elseif mode == "text" and not RGB.text then
        refreshRgbCache()
        for _, v in ipairs(textCache) do
            if v.Parent then v.TextColor3 = Theme.white end
        end
    end
end
local function syncAppearance()
    for _, m in ipairs({"border", "strokes", "glow", "text"}) do setRgb(m, RGB[m]) end
    applyFontAll()
    applyLayoutRefresh()
end

task.spawn(function()
    local hue, rot, tick = 0, 0, 0
    while S.alive and Gui.Parent do
        task.wait(0.03)
        safeCall("RainbowLoop", function()
            if not (RGB.border or RGB.strokes or RGB.glow or RGB.text) then return end
            tick = tick + 1
            hue = (hue + 0.004 * RGB.speed) % 1
            rot = (rot + 2 * RGB.speed) % 360
            if tick % 30 == 1 then refreshRgbCache() end
            if RGB.border then
                MainGrad.Rotation = rot
                TopGrad.Rotation = rot
            end
            if RGB.glow then GlowGrad.Rotation = rot end
            if RGB.strokes then
                for i, v in ipairs(strokeCache) do
                    if v.Parent and not (RGB.border and isMainStroke(v)) then
                        v.Color = Color3.fromHSV((hue + i * 0.03) % 1, 0.9, 1)
                    end
                end
            end
            if RGB.text then
                for i, v in ipairs(textCache) do
                    if v.Parent then v.TextColor3 = Color3.fromHSV((hue + i * 0.02) % 1, 0.55, 1) end
                end
            end
        end)
    end
end)

local function toast(msg)
    local t = new("TextLabel", {
        Size = UDim2.fromOffset(340, 42),
        Position = UDim2.new(1, -356, 1, -58),
        BackgroundColor3 = Theme.surface,
        Text = "  " .. tostring(msg),
        TextColor3 = Theme.white,
        Font = CONFIG.FontBold,
        TextSize = fs(12),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 80,
    }, Gui)
    corner(t, 9)
    stroke(t, Theme.accent, 1.3, 0.15)
    if FONT_NAME ~= "ค่าเริ่มต้น" then safeCall("toastFont", applyFontAll) end
    task.delay(3.0, function() if t then t:Destroy() end end)
end

local function clearBody()
    for _, v in ipairs(Scroll:GetChildren()) do
        if v ~= BodyList and v:IsA("GuiObject") then v:Destroy() end
    end
end

local function section(text)
    return new("TextLabel", {
        Size = UDim2.new(1, -4, 0, 28),
        BackgroundTransparency = 1,
        Text = "  " .. text,
        TextColor3 = Theme.white,
        Font = Enum.Font.GothamBlack,
        TextSize = fs(15),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    }, Scroll)
end

local function info(text, h)
    local f = new("TextLabel", {
        Size = UDim2.new(1, -4, 0, h or 48),
        BackgroundColor3 = Theme.card,
        BackgroundTransparency = 0.12,
        Text = text,
        TextColor3 = Theme.white,
        Font = CONFIG.FontRegular,
        TextSize = fs(11),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    }, Scroll)
    new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, f)
    corner(f, 9)
    stroke(f, Theme.accent, 1, 0.62)
    return f
end

local function button(text, fn)
    local b = new("TextButton", {
        Size = UDim2.new(1, -4, 0, 40),
        BackgroundColor3 = Theme.cardActive,
        Text = text,
        TextColor3 = Theme.white,
        Font = CONFIG.FontBold,
        TextSize = fs(12),
        AutoButtonColor = false,
        ZIndex = 4,
    }, Scroll)
    corner(b, 9)
    local st = stroke(b, Theme.accent, 1, 0.45)
    b.MouseEnter:Connect(function()
        tweenProp(b, {BackgroundColor3 = Theme.accentFill})
        tweenProp(st, {Transparency = 0.05})
    end)
    b.MouseLeave:Connect(function()
        tweenProp(b, {BackgroundColor3 = Theme.cardActive})
        tweenProp(st, {Transparency = 0.45})
    end)
    b.MouseButton1Click:Connect(function() safeCall("button:" .. tostring(text), fn) end)
    return b
end

local function toggle(title, desc, default, fn)
    S.flags[title] = default or false
    local f = new("Frame", {
        Size = UDim2.new(1, -4, 0, 68),
        BackgroundColor3 = Theme.card,
        BackgroundTransparency = 0.1,
        ZIndex = 4,
    }, Scroll)
    corner(f, 10)
    stroke(f, Theme.accent, 1, 0.55)
    new("TextLabel", {
        Position = UDim2.fromOffset(12, 8),
        Size = UDim2.new(1, -100, 0, 22),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.white,
        Font = CONFIG.FontBold,
        TextSize = fs(12),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    }, f)
    new("TextLabel", {
        Position = UDim2.fromOffset(12, 32),
        Size = UDim2.new(1, -100, 0, 28),
        BackgroundTransparency = 1,
        Text = desc,
        TextColor3 = Theme.mutedWhite,
        Font = CONFIG.FontRegular,
        TextSize = fs(10),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    }, f)
    local sw = new("TextButton", {
        Position = UDim2.new(1, -78, 0.5, -14),
        Size = UDim2.fromOffset(64, 28),
        BackgroundColor3 = S.flags[title] and Theme.accentFill or Theme.switchOff,
        Text = S.flags[title] and "เปิด" or "ปิด",
        TextColor3 = Theme.white,
        Font = Enum.Font.GothamBlack,
        TextSize = fs(11),
        ZIndex = 5,
    }, f)
    corner(sw, 14)
    stroke(sw, Theme.accent, 1, 0.35)
    sw.MouseButton1Click:Connect(function()
        S.flags[title] = not S.flags[title]
        sw.Text = S.flags[title] and "เปิด" or "ปิด"
        tweenProp(sw, {BackgroundColor3 = S.flags[title] and Theme.accentFill or Theme.switchOff})
        if fn then safeCall("toggle:" .. tostring(title), fn, S.flags[title]) end
        toast(title .. " : " .. (S.flags[title] and "เปิดใช้งาน" or "ปิดใช้งาน"))
    end)
end

-- ตัวปรับค่า − / + (ใช้ปรับค่าตัวเลขของ UI ได้ทุกส่วน)
local function stepper(title, getv, setv, step, minv, maxv, decimals)
    local d = decimals or 0
    local function fmt(v) return string.format("%." .. d .. "f", v) end
    local f = new("Frame", {
        Size = UDim2.new(1, -4, 0, 48),
        BackgroundColor3 = Theme.card,
        BackgroundTransparency = 0.1,
        ZIndex = 4,
    }, Scroll)
    corner(f, 10)
    stroke(f, Theme.accent, 1, 0.55)
    new("TextLabel", {
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -160, 1, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.white,
        Font = CONFIG.FontBold,
        TextSize = fs(11),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    }, f)
    local val = new("TextLabel", {
        Position = UDim2.new(1, -104, 0, 0),
        Size = UDim2.fromOffset(58, 48),
        BackgroundTransparency = 1,
        Text = fmt(getv()),
        TextColor3 = Theme.white,
        Font = CONFIG.FontBold,
        TextSize = fs(12),
        ZIndex = 5,
    }, f)
    local function bump(delta)
        local v = math.clamp(getv() + delta, minv, maxv)
        v = math.floor(v * 1000 + 0.5) / 1000
        setv(v)
        val.Text = fmt(getv())
    end
    local function mk(txt, x, delta)
        local b = new("TextButton", {
            Position = UDim2.new(1, x, 0.5, -15),
            Size = UDim2.fromOffset(34, 30),
            BackgroundColor3 = Theme.cardActive,
            Text = txt,
            TextColor3 = Theme.white,
            Font = Enum.Font.GothamBlack,
            TextSize = 18,
            AutoButtonColor = false,
            ZIndex = 5,
        }, f)
        corner(b, 8)
        stroke(b, Theme.accent, 1, 0.35)
        b.MouseButton1Click:Connect(function() safeCall("stepper:" .. tostring(title), bump, delta) end)
    end
    mk("−", -142, -step)
    mk("+", -44, step)
    return f
end

-- แถวสี (swatch) กดเลือกสีได้
local function swatches(title, colors, onPick)
    new("TextLabel", {
        Size = UDim2.new(1, -4, 0, 22),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.white,
        Font = CONFIG.FontBold,
        TextSize = fs(11),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    }, Scroll)
    local grid = new("Frame", {
        Size = UDim2.new(1, -4, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, Scroll)
    new("UIGridLayout", {
        CellSize = UDim2.fromOffset(38, 38),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)
    for i, entry in ipairs(colors) do
        local b = new("TextButton", {
            BackgroundColor3 = entry[2],
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = i,
            ZIndex = 5,
        }, grid)
        corner(b, 10)
        stroke(b, Color3.fromRGB(255, 255, 255), 1.5, 0.3)
        b.MouseButton1Click:Connect(function() safeCall("swatch:" .. tostring(entry[1]), onPick, entry[1], entry[2]) end)
    end
end

local function cardGrid(items)
    local wrap = new("Frame", {
        Size = UDim2.new(1, -4, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 3,
    }, Scroll)
    new("UIGridLayout", {
        CellSize = UDim2.new(0.5, -5, 0, 118),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, wrap)
    for _, item in ipairs(items) do
        local f = new("Frame", {
            BackgroundColor3 = Theme.card,
            BackgroundTransparency = 0.08,
            ZIndex = 4,
        }, wrap)
        corner(f, 10)
        stroke(f, Theme.accent, 1.1, 0.45)
        gradient(f, Theme.cardActive, Theme.surface, 25)
        new("TextLabel", {
            Position = UDim2.fromOffset(10, 8),
            Size = UDim2.new(1, -20, 0, 24),
            BackgroundTransparency = 1,
            Text = item.icon .. "  " .. item.title,
            TextColor3 = Theme.white,
            Font = Enum.Font.GothamBlack,
            TextSize = fs(12),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
        }, f)
        new("TextLabel", {
            Position = UDim2.fromOffset(10, 34),
            Size = UDim2.new(1, -20, 0, 44),
            BackgroundTransparency = 1,
            Text = item.desc,
            TextColor3 = Theme.mutedWhite,
            Font = CONFIG.FontRegular,
            TextSize = fs(10),
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
        }, f)
        local b = new("TextButton", {
            Position = UDim2.new(1, -86, 1, -30),
            Size = UDim2.fromOffset(76, 22),
            BackgroundColor3 = Theme.cardActive,
            Text = "ตั้งค่า",
            TextColor3 = Theme.white,
            Font = Enum.Font.GothamBlack,
            TextSize = fs(10),
            ZIndex = 5,
        }, f)
        corner(b, 6)
        stroke(b, Theme.accent, 1, 0.3)
        b.MouseButton1Click:Connect(function()
            safeCall("card:" .. tostring(item.title), item.fn or function() toast(item.title .. " (โหมดเตรียมระบบออโต้)") end)
        end)
    end
end

--========================================================
-- Smart Vehicle & Thai Pin Destination Scanner
--========================================================
local function vehicles()
    local out, seen = {}, {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("VehicleSeat") then
            local m = v:FindFirstAncestorOfClass("Model")
            if m and not seen[m] then
                seen[m] = true
                table.insert(out, m)
            end
        end
    end
    table.sort(out, function(a, b) return a.Name < b.Name end)
    return out
end

local function isIgnoredPart(part)
    if not CONFIG.FilterInvalidParts then return false end
    local fullLower = part:GetFullName():lower()
    local nameLower = part.Name:lower()
    -- ข้ามชิ้นส่วนของตัวละครผู้เล่น เช่น KneeBrace ที่ไปตรงกับคำว่า race
    if part:FindFirstAncestorOfClass("Accessory") then return true end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and part:IsDescendantOf(plr.Character) then return true end
    end
    if fullLower:find("players%.") or fullLower:find("accessory") then return true end
    for _, kw in ipairs(IGNORED_PART_KEYWORDS) do
        if nameLower:find(kw, 1, true) then return true end
    end
    return false
end

local function translateDestination(rawName)
    local lower = rawName:lower()
    for _, rule in ipairs(PIN_RULES) do
        if lower:find(rule.keyword, 1, true) then
            if CONFIG.ShowRawNameHint then
                return rule.thai .. " (" .. rawName .. ")", rule.category
            end
            return rule.thai, rule.category
        end
    end
    if CONFIG.ShowRawNameHint then
        return "จุดหมายในแผนที่ (" .. rawName .. ")", "จุดหมาย"
    end
    return "จุดหมาย: " .. rawName, "จุดหมาย"
end

local function destinations()
    local out, seen = {}, {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and not isIgnoredPart(v) then
            local n = v.Name:lower()
            local matched = false
            for _, rule in ipairs(PIN_RULES) do
                if n:find(rule.keyword, 1, true) then matched = true; break end
            end
            if matched and not seen[v] then
                seen[v] = true
                local thaiName, cat = translateDestination(v.Name)
                table.insert(out, {part = v, thai = thaiName, category = cat})
            end
        end
    end
    table.sort(out, function(a, b) return a.thai < b.thai end)
    return out
end

local function clearRoute()
    for _, v in ipairs(S.route) do pcall(function() v:Destroy() end) end
    table.clear(S.route)
end

local function routeTo(part, thaiLabel)
    clearRoute()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not part then toast("ไม่พบตัวละครหรือจุดหมาย"); return end
    local path = PathfindingService:CreatePath({AgentRadius = 4, AgentHeight = 6, AgentCanJump = true, WaypointSpacing = 12})
    local ok = pcall(function() path:ComputeAsync(root.Position, part.Position) end)
    local pts = {}
    if ok and path.Status == Enum.PathStatus.Success then
        for _, w in ipairs(path:GetWaypoints()) do table.insert(pts, w.Position) end
    else
        pts = {root.Position, part.Position}
    end
    for i = 1, #pts - 1 do
        local a, b = pts[i], pts[i + 1]
        local d = b - a
        local beam = new("Part", {
            Name = "BALLKUN_ROUTE",
            Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
            Material = Enum.Material.Neon, Color = Theme.accent, Transparency = 0.08,
            Size = Vector3.new(0.45, 0.45, d.Magnitude),
            CFrame = CFrame.lookAt((a + b) / 2, b),
        }, Workspace)
        table.insert(S.route, beam)
    end
    local pin = new("Part", {
        Name = "BALLKUN_PIN",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(2.2, 2.2, 2.2),
        Position = part.Position + Vector3.new(0, 3, 0),
        Anchored = true, CanCollide = false,
        Material = Enum.Material.Neon, Color = Theme.white,
    }, Workspace)
    table.insert(S.route, pin)
    S.selectedTarget = part
    toast("ปักหมุดเส้นทาง: " .. (thaiLabel or "จุดหมาย"))
end

--========================================================
-- Pages
--========================================================
local showPage

local function dashboard()
    section("ภาพรวมระบบ  •  BALL KUN PREMIUM")
    info("ยินดีต้อนรับสู่ " .. CONFIG.HubTitle .. " — ฟอนต์สีขาวล้วน อ่านง่าย พรีเมียม พร้อมระบบปักหมุดแปลไทย", 48)
    cardGrid({
        {icon = "⛽", title = "ระบบน้ำมัน", desc = "ตรวจระดับน้ำมัน (เตรียมระบบออโต้ในเวอร์ชันถัดไป)", fn = function() toast("ระบบน้ำมัน: โหมดเตรียมพร้อมออโต้") end},
        {icon = "🔧", title = "ระบบซ่อมรถ", desc = "เฝ้าตรวจสภาพตัวรถ (เตรียมระบบออโต้ในเวอร์ชันถัดไป)", fn = function() toast("ระบบซ่อมรถ: โหมดเตรียมพร้อมออโต้") end},
        {icon = "📍", title = "ปักหมุดนำทางไทย", desc = "สแกนร้าน จุดจูน และสนามแข่งเป็นภาษาไทยทั้งหมด", fn = function() showPage("การนำทาง") end},
        {icon = "🎨", title = "ปรับแต่ง UI ทั้งหมด", desc = "เปลี่ยนสี ขนาดหน้าต่าง ความโปร่งใส และพื้นหลังได้ทันที", fn = function() showPage("ปรับแต่ง UI") end},
    })
    section("ระบบจูนรถและผู้เล่น")
    button("🚘  เลือกรถเป้าหมายสำหรับจูน", function() showPage("ระบบรถยนต์") end)
    button("⚙  เปิดห้องทดลอง ECU (เตรียมออโต้)", function() showPage("ECU Tuning") end)
    local c = LP.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    info("ผู้เล่น: " .. LP.DisplayName .. " (@" .. LP.Name .. ")  •  พลังชีวิต: " .. (h and math.floor(h.Health) or 0) .. "/" .. (h and math.floor(h.MaxHealth) or 0), 44)
end

local function carPage()
    section("ระบบรถยนต์  •  เลือกคันเป้าหมาย")
    info("สแกนรถที่มี VehicleSeat ใน Workspace แล้วเลือกคันที่ต้องการวิเคราะห์", 44)
    button("🔍  สแกนรถทั้งหมดในแผนที่", function()
        local list = vehicles()
        toast("พบรถทั้งหมด " .. #list .. " คัน")
        for _, car in ipairs(list) do
            button("เลือกรถ  •  " .. car.Name, function()
                S.selectedCar = car
                toast("เลือกรถ " .. car.Name .. " เรียบร้อย")
            end)
        end
    end)
    button("แสดงข้อมูลรถที่เลือกไว้", function()
        toast(S.selectedCar and ("รถที่เลือก: " .. S.selectedCar.Name) or "ยังไม่ได้เลือกรถ")
    end)
end

local function navPage()
    section("การนำทาง  •  ปักหมุดภาษาไทยอัจฉริยะ")
    info("กรองชิ้นส่วนตัวละครออกอัตโนมัติ (เช่น KneeBrace) และแปลชื่อจุดหมายในแผนที่เป็นภาษาไทยทั้งหมด", 50)
    button("🔍  สแกนร้าน / อู่ / สนามแข่ง (แปลไทย)", function()
        local list = destinations()
        toast("พบจุดหมายที่ใช้งานได้ " .. #list .. " จุด")
        for _, item in ipairs(list) do
            button("ปักหมุด  •  " .. item.thai .. "  [" .. item.category .. "]", function()
                routeTo(item.part, item.thai)
            end)
        end
    end)
    button("ล้างเส้นทางและหมุดทั้งหมด", function()
        clearRoute()
        toast("ล้างเส้นทางแล้ว")
    end)
    toggle("อัปเดตเส้นทางตามตำแหน่ง", "คำนวณเส้นทางใหม่อัตโนมัติทุก 3 วินาที", false, function(on)
        if on then
            task.spawn(function()
                while S.alive and S.flags["อัปเดตเส้นทางตามตำแหน่ง"] do
                    task.wait(3)
                    if S.selectedTarget and S.selectedTarget.Parent then
                        local thaiName = translateDestination(S.selectedTarget.Name)
                        safeCall("AutoRoute", routeTo, S.selectedTarget, thaiName)
                    end
                end
            end)
        end
    end)
end

local function ecuPage()
    section("ห้องทดลอง ECU  •  เตรียมระบบออโต้")
    info("อ่านค่าความเร็ว/แรงบิดของรถที่เลือกไว้ ส่วนระบบจูนออโต้จะเพิ่มในรอบถัดไปเพื่อความปลอดภัย", 50)
    button("สแกนค่ารถที่เลือก", function()
        local v = S.selectedCar
        if not v then toast("กรุณาเลือกรถในเมนู ระบบรถยนต์ ก่อน"); return end
        local seat = v:FindFirstChildWhichIsA("VehicleSeat", true)
        info("รถ: " .. v.Name .. "\nความเร็วสูงสุด: " .. tostring(seat and seat.MaxSpeed or "ไม่พบ") ..
            "  |  แรงบิด: " .. tostring(seat and seat.Torque or "ไม่พบ"), 54)
    end)
    toggle("ผู้ช่วยวิเคราะห์ ECU", "เปรียบเทียบค่าที่อ่านได้ (โหมดตรวจสอบ)", false)
    toggle("ค้นหาค่าจูนอัตโนมัติ (รอรอบถัดไป)", "เตรียมระบบออโต้ไว้สำหรับเชื่อมต่อรอบหน้า", false)
    toggle("จูนรถทุกคันทีละคัน (รอรอบถัดไป)", "เตรียมคิวรถไว้พร้อมสำหรับระบบออโต้", false)
end

local function pistonPage()
    section("เรดาร์ลูกสูบ  •  เบอร์ 53–90")
    info("กำหนดเบอร์ลูกสูบที่ต้องการ ระบบจะคอยตรวจจับบนหน้าจอ (ระบบซื้อออโต้จะเพิ่มทีหลัง)", 46)
    local box = new("TextBox", {
        Size = UDim2.new(1, -4, 0, 40),
        BackgroundColor3 = Theme.cardActive,
        Text = tostring(S.piston),
        PlaceholderText = "ใส่เบอร์ลูกสูบ 53–90",
        PlaceholderColor3 = Theme.mutedWhite,
        TextColor3 = Theme.white,
        Font = Enum.Font.GothamBold,
        TextSize = fs(14),
        ClearTextOnFocus = false,
        ZIndex = 5,
    }, Scroll)
    corner(box, 9)
    stroke(box, Theme.accent, 1, 0.35)
    button("บันทึกเบอร์ลูกสูบเป้าหมาย", function()
        local n = tonumber(box.Text)
        if n and n % 1 == 0 and n >= 53 and n <= 90 then
            S.piston = n
            toast("ตั้งเป้าลูกสูบเบอร์ " .. n .. " เรียบร้อย")
        else
            toast("กรุณาใส่เลขจำนวนเต็ม 53–90 เท่านั้น")
        end
    end)
    toggle("ตรวจจับลูกสูบเป้าหมาย", "แจ้งเตือนทันทีเมื่อพบข้อความลูกสูบตรงเบอร์", false)
    toggle("ซื้อลูกสูบอัตโนมัติ (เพิ่มทีหลัง)", "โหมดเตรียมพร้อม รอเพิ่มระบบออโต้ในรอบถัดไป", false)
end

local function fpsPage()
    section("เพิ่มความลื่นไหล  •  FPS BOOST")
    info("ลดเงา หมอก และเอฟเฟกต์แสงเพื่อเพิ่ม FPS และสามารถกดคืนค่าเดิมได้ทุกเมื่อ", 48)
    toggle("เปิดใช้งาน FPS Boost", "ลดภาระกราฟิกฝั่งเครื่องผู้เล่น", false, function(on)
        if on and not S.fps then
            S.fps = true
            S.saved.shadows = Lighting.GlobalShadows
            S.saved.fog = Lighting.FogEnd
            S.saved.effects = {}
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1000000
            for _, v in ipairs(Lighting:GetDescendants()) do
                if v:IsA("PostEffect") then S.saved.effects[v] = v.Enabled; v.Enabled = false end
            end
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                    S.saved.effects[v] = v.Enabled; v.Enabled = false
                end
            end
            toast("เปิด FPS Boost แล้ว")
        elseif not on and S.fps then
            S.fps = false
            Lighting.GlobalShadows = S.saved.shadows
            Lighting.FogEnd = S.saved.fog
            for obj, val in pairs(S.saved.effects or {}) do
                if obj and obj.Parent then pcall(function() obj.Enabled = val end) end
            end
            toast("คืนค่ากราฟิกเดิมแล้ว")
        end
    end)
end

local function alertsPage()
    section("ศูนย์รวมแจ้งเตือน")
    info("จัดการการแจ้งเตือนแบบเรียลไทม์ทั้งหมดของ BALL KUN HUB", 40)
    toggle("แจ้งเตือนลูกสูบ", "แจ้งเตือนเมื่อตรวจพบเบอร์ลูกสูบเป้าหมาย", false)
    toggle("แจ้งเตือนจุดหมายใหม่", "ตรวจจับการเปลี่ยนแปลงของร้านและอู่ในแผนที่", false)
end

local function playerPage()
    section("โปรไฟล์ผู้เล่น")
    local avatar = new("ImageLabel", {
        Size = UDim2.fromOffset(88, 88),
        BackgroundColor3 = Theme.cardActive,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=150&h=150",
        ZIndex = 4,
    }, Scroll)
    corner(avatar, 44)
    stroke(avatar, Theme.accent, 2, 0.15)
    info("ชื่อแสดง: " .. LP.DisplayName .. "\nบัญชี: @" .. LP.Name .. "\nUser ID: " .. LP.UserId .. "\nอายุบัญชี: " .. LP.AccountAge .. " วัน", 76)
end

local ACCENT_PRESETS = {
    {"มรกต", Color3.fromRGB(16, 185, 129)},
    {"เขียวนีออน", Color3.fromRGB(57, 255, 20)},
    {"ทอง", Color3.fromRGB(245, 158, 11)},
    {"ฟ้าคริสตัล", Color3.fromRGB(6, 182, 212)},
    {"น้ำเงิน", Color3.fromRGB(59, 130, 246)},
    {"ม่วง", Color3.fromRGB(168, 85, 247)},
    {"ชมพู", Color3.fromRGB(236, 72, 153)},
    {"แดง", Color3.fromRGB(239, 68, 68)},
    {"ส้ม", Color3.fromRGB(249, 115, 22)},
    {"ขาว", Color3.fromRGB(255, 255, 255)},
}

local function cfgStepper(title, key, step, minv, maxv, decimals)
    stepper(title, function() return CONFIG[key] end, function(v)
        CONFIG[key] = v
        applyLayoutRefresh()
    end, step, minv, maxv, decimals)
end

local function resetAllUi()
    for _, k in ipairs(SAVE_KEYS) do CONFIG[k] = DEFAULT_CONFIG[k] end
    RGB.speed = 1
    for _, m in ipairs({"border", "strokes", "glow", "text"}) do setRgb(m, false) end
    FONT_NAME = "ค่าเริ่มต้น"
    setAccent(DEFAULT_ACCENT, DEFAULT_ACCENT_FILL)
    applyFontAll()
    applyLayoutRefresh()
end

local function customizePage()
    section("ปรับแต่ง UI ได้ทั้งหมด (เรียลไทม์)")
    info("ปรับสี ขนาด ความโปร่งใส ปกหลัง ฟอนต์ และไฟรุ้งได้ทันทีในเกม กด 💾 บันทึกเพื่อจำค่าไว้ใช้ครั้งต่อไป", 46)

    button("🎨  เปลี่ยนสีหลัก: มรกตพรีเมียม", function()
        setAccent(Color3.fromRGB(16, 185, 129), DEFAULT_ACCENT_FILL); showPage(S.page); toast("เปลี่ยนธีมเป็น มรกตพรีเมียม")
    end)
    button("🏆  เปลี่ยนสีหลัก: ทองแชมเปี้ยน", function()
        setAccent(Color3.fromRGB(245, 158, 11)); showPage(S.page); toast("เปลี่ยนธีมเป็น ทองแชมเปี้ยน")
    end)
    button("💠  เปลี่ยนสีหลัก: ฟ้าคริสตัล", function()
        setAccent(Color3.fromRGB(6, 182, 212)); showPage(S.page); toast("เปลี่ยนธีมเป็น ฟ้าคริสตัล")
    end)
    swatches("สีหลักทั้งหมด (แตะเพื่อเปลี่ยนทั้ง UI)", ACCENT_PRESETS, function(name, color)
        setAccent(color); showPage(S.page); toast("เปลี่ยนสีหลัก: " .. tostring(name))
    end)

    section("ขนาดและรูปทรง")
    cfgStepper("ขนาด UI ทั้งหมด (Scale)", "UiScale", 0.05, 0.5, 1.3, 2)
    cfgStepper("ความกว้างหน้าต่าง", "WindowWidth", 40, 600, 1250, 0)
    cfgStepper("ความสูงหน้าต่าง", "WindowHeight", 30, 420, 860, 0)
    cfgStepper("ความกว้างเมนูด้านซ้าย", "SidebarWidth", 10, 150, 300, 0)
    cfgStepper("ความโค้งมุม", "CornerRadius", 2, 0, 30, 0)
    cfgStepper("ความหนาเส้นขอบ", "BorderThickness", 0.5, 0.5, 5, 1)
    cfgStepper("ความโปร่งใสหน้าต่าง", "PanelTransparency", 0.05, 0, 0.9, 2)
    button("📐  ปรับขนาดหน้าต่าง: โหมดมือถือ / แท็บเล็ต", function()
        CONFIG.WindowWidth = 780; CONFIG.WindowHeight = 500; CONFIG.ShowRightPanel = false
        applyLayoutRefresh(); showPage(S.page); toast("ปรับเป็นขนาดมือถือแล้ว")
    end)
    button("🖥  ปรับขนาดหน้าต่าง: โหมดเต็มจอพรีเมียม", function()
        CONFIG.WindowWidth = 980; CONFIG.WindowHeight = 620; CONFIG.ShowRightPanel = true
        applyLayoutRefresh(); showPage(S.page); toast("ปรับเป็นขนาดเต็มจอแล้ว")
    end)
    toggle("ซ่อนแถบสถานะด้านขวา", "เพิ่มพื้นที่แสดงผลตรงกลางให้กว้างขึ้น", not CONFIG.ShowRightPanel, function(on)
        CONFIG.ShowRightPanel = not on
        applyLayoutRefresh()
    end)
    toggle("แสดงแถบท้ายหน้าต่าง (Footer)", "ปิดเพื่อเพิ่มพื้นที่แนวตั้ง", CONFIG.ShowFooter, function(on)
        CONFIG.ShowFooter = on
        applyLayoutRefresh()
    end)
    toggle("เอฟเฟกต์เคลื่อนไหวนุ่มนวล", "ปิดแล้วสีปุ่มจะเปลี่ยนทันที (ลื่นขึ้นในเครื่องช้า)", CONFIG.SmoothMotion, function(on)
        CONFIG.SmoothMotion = on
    end)

    section("ภาพปกหลัง")
    info(BG_STATUS, 46)
    button("🖼  สลับแสดง / ซ่อนภาพพื้นหลัง", function()
        CONFIG.BackgroundEnabled = not CONFIG.BackgroundEnabled
        applyLayoutRefresh()
        toast(CONFIG.BackgroundEnabled and "แสดงภาพพื้นหลังแล้ว" or "ซ่อนภาพพื้นหลังแล้ว")
    end)
    cfgStepper("ความโปร่งใสภาพปกหลัง (น้อย = ชัด)", "BackgroundTransparency", 0.05, 0, 1, 2)
    cfgStepper("ความมืดฟิลเตอร์หลังภาพ (น้อย = มืด)", "BackgroundScrimTransparency", 0.05, 0, 1, 2)
    button("⬇  โหลดภาพปกหลังใหม่ (ดาวน์โหลดทับ)", function()
        local ok = loadBackdrop(true)
        toast(ok and "โหลดภาพปกหลังใหม่แล้ว" or BG_STATUS)
        showPage(S.page)
    end)

    section("บันทึกการตั้งค่า")
    button("💾  บันทึกการตั้งค่า UI", function()
        local ok, err = saveSettings()
        toast(ok and "บันทึกการตั้งค่าแล้ว" or ("บันทึกไม่ได้: " .. tostring(err)))
    end)
    button("📂  โหลดการตั้งค่าที่บันทึกไว้", function()
        local oldA, oldF = Theme.accent, Theme.accentFill
        local ok, msg = loadSettings()
        if ok then
            local newA, newF = Theme.accent, Theme.accentFill
            Theme.accent, Theme.accentFill = oldA, oldF
            setAccent(newA, newF)
            syncAppearance()
            showPage(S.page)
            toast("โหลดการตั้งค่าแล้ว")
        else
            toast(msg == "NOFILE" and "ยังไม่มีไฟล์ตั้งค่าที่บันทึกไว้" or tostring(msg))
        end
    end)
    button("♻  รีเซ็ตค่า UI ทั้งหมดเป็นค่าเริ่มต้น", function()
        resetAllUi()
        showPage(S.page)
        toast("รีเซ็ตค่า UI แล้ว")
    end)

    section("อื่น ๆ")
    toggle("กรองชิ้นส่วนหลอก (เช่น KneeBrace)", "เปิดไว้เพื่อไม่ให้คำว่า race ในชื่อไอเทมโผล่ในรายการปักหมุด", CONFIG.FilterInvalidParts, function(on)
        CONFIG.FilterInvalidParts = on
    end)
    button("ล้างเส้นทางทั้งหมด", clearRoute)
    button("ปิด BALL KUN HUB", function() S.alive = false; clearRoute(); Gui:Destroy() end)
end

local function fontRgbPage()
    section("ฟอนต์ (เลือกได้ทั้ง UI)")
    info("ฟอนต์ปัจจุบัน: " .. FONT_NAME .. "\nบางฟอนต์ไม่มีตัวอักษรไทย ตัวไทยจะใช้ฟอนต์สำรองของระบบ ส่วนตัวอังกฤษและตัวเลขจะเปลี่ยนตามที่เลือก", 66)
    button("▶  ฟอนต์ถัดไป", function()
        local idx = 1
        for i, n in ipairs(FONT_LIST) do if n == FONT_NAME then idx = i end end
        setFont(FONT_LIST[idx % #FONT_LIST + 1])
        showPage(S.page)
        toast("ฟอนต์: " .. FONT_NAME)
    end)
    for _, name in ipairs(FONT_LIST) do
        button((name == FONT_NAME and "✓  " or "🔤  ") .. name, function()
            setFont(name)
            showPage(S.page)
            toast("ฟอนต์: " .. name)
        end)
    end

    section("ไฟรุ้ง")
    toggle("ขอบหน้าต่างรุ้ง", "ไล่สีรุ้งหมุนรอบกรอบหลักและแถบหัว", RGB.border, function(on) setRgb("border", on) end)
    toggle("กรอบทุกส่วนรุ้ง", "ทุกปุ่มและการ์ดเปลี่ยนสีขอบเป็นรุ้งไล่เฉด", RGB.strokes, function(on) setRgb("strokes", on) end)
    toggle("แสงรุ้งบนปกหลัง", "เพิ่มแสงรุ้งหมุนทับภาพปกหลัง", RGB.glow, function(on) setRgb("glow", on) end)
    toggle("ตัวอักษรรุ้ง", "ตัวอักษรเปลี่ยนสีรุ้ง (ปิดแล้วกลับเป็นสีขาว)", RGB.text, function(on) setRgb("text", on) end)
    stepper("ความเร็วไฟรุ้ง", function() return RGB.speed end, function(v) RGB.speed = v end, 0.5, 0.5, 5, 1)
    button("🌈  เปิดไฟรุ้งทั้งหมด", function()
        for _, m in ipairs({"border", "strokes", "glow", "text"}) do setRgb(m, true) end
        showPage(S.page)
        toast("เปิดไฟรุ้งทั้งหมดแล้ว")
    end)
    button("⚪  ปิดไฟรุ้งทั้งหมด", function()
        for _, m in ipairs({"border", "strokes", "glow", "text"}) do setRgb(m, false) end
        showPage(S.page)
        toast("ปิดไฟรุ้งทั้งหมดแล้ว")
    end)
    button("💾  บันทึกการตั้งค่า UI", function()
        local ok, err = saveSettings()
        toast(ok and "บันทึกการตั้งค่าแล้ว" or ("บันทึกไม่ได้: " .. tostring(err)))
    end)
end

local pages = {
    ["หน้าหลัก"] = dashboard,
    ["ระบบรถยนต์"] = carPage,
    ["การนำทาง"] = navPage,
    ["ECU Tuning"] = ecuPage,
    ["ลูกสูบ 53–90"] = pistonPage,
    ["FPS Boost"] = fpsPage,
    ["แจ้งเตือน"] = alertsPage,
    ["โปรไฟล์ผู้เล่น"] = playerPage,
    ["ปรับแต่ง UI"] = customizePage,
    ["ฟอนต์ & ไฟรุ้ง"] = fontRgbPage,
}

local navItems = {
    {"⌂", "หน้าหลัก", "ภาพรวมระบบ"},
    {"🚘", "ระบบรถยนต์", "เลือกและวิเคราะห์รถ"},
    {"📍", "การนำทาง", "ปักหมุดแปลภาษาไทย"},
    {"⚙", "ECU Tuning", "เตรียมจูนอัตโนมัติ"},
    {"◎", "ลูกสูบ 53–90", "เรดาร์ลูกสูบ"},
    {"⚡", "FPS Boost", "เพิ่มความลื่นไหล"},
    {"🔔", "แจ้งเตือน", "ศูนย์รวมแจ้งเตือน"},
    {"●", "โปรไฟล์ผู้เล่น", "ข้อมูลบัญชี"},
    {"🎨", "ปรับแต่ง UI", "ปรับขนาด สี พื้นหลัง"},
    {"🌈", "ฟอนต์ & ไฟรุ้ง", "เลือกฟอนต์ ไฟรุ้งหลายแบบ"},
}

showPage = function(name)
    S.page = name
    clearBody()
    if pages[name] then
        safeCall("page:" .. tostring(name), pages[name])
    else
        warn("[BALL KUN HUB] ไม่พบหน้า: " .. tostring(name))
    end
    if FONT_NAME ~= "ค่าเริ่มต้น" then safeCall("applyFontAll", applyFontAll) end
    for _, v in ipairs(Sidebar:GetChildren()) do
        if v:IsA("TextButton") then
            local active = (v.Name == name)
            tweenProp(v, {BackgroundColor3 = active and Theme.accentFill or Theme.card})
        end
    end
end

for i, item in ipairs(navItems) do
    local b = new("TextButton", {
        Name = item[2],
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.card,
        Text = item[1] .. "  " .. item[2] .. "\n      " .. item[3],
        TextColor3 = Theme.white,
        Font = CONFIG.FontBold,
        TextSize = fs(11),
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        LayoutOrder = i,
        ZIndex = 4,
    }, Sidebar)
    new("UIPadding", {PaddingLeft = UDim.new(0, 8)}, b)
    corner(b, 8)
    stroke(b, Theme.accent, 1, 0.65)
    b.MouseButton1Click:Connect(function() showPage(item[2]) end)
end

-- Right Cards (All White Text)
local function sideCard(title, lines, height)
    local f = new("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Theme.surface,
        BackgroundTransparency = 0.14,
        ZIndex = 3,
    }, Right)
    corner(f, 10)
    stroke(f, Theme.accent, 1.1, 0.35)
    gradient(f, Theme.card, Theme.surface, 30)
    new("TextLabel", {
        Position = UDim2.fromOffset(10, 8),
        Size = UDim2.new(1, -20, 0, 22),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.white,
        Font = Enum.Font.GothamBlack,
        TextSize = fs(13),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    }, f)
    new("TextLabel", {
        Position = UDim2.fromOffset(10, 34),
        Size = UDim2.new(1, -20, 1, -40),
        BackgroundTransparency = 1,
        Text = lines,
        TextColor3 = Theme.mutedWhite,
        Font = CONFIG.FontRegular,
        TextSize = fs(10),
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    }, f)
    return f
end

sideCard("♛  BALL KUN V4", "✓ ฟอนต์สีขาวทั้งระบบ\n✓ ปักหมุดแปลไทย 100%\n✓ กรองชิ้นส่วนหลอก\n✓ ปรับแต่ง UI ได้หมด", 148)
sideCard("✦  สถานะระบบ", "● UI พรีเมียมพร้อมใช้\n● ระบบออโต้: เตรียมรอ\n● ไม่ยิง Remote อันตราย\n● รองรับมือถือพอดีจอ", 132)
sideCard("ผู้เล่นออนไลน์", "ชื่อ: " .. LP.DisplayName .. "\nสถานะ: ออนไลน์\nเครดิต: " .. CONFIG.Credit, 106)

-- Drag & Resize
local dragging, dragStart, startPos
Top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = Main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

local Grip = new("TextButton", {
    Size = UDim2.fromOffset(22, 22),
    Position = UDim2.new(1, -24, 1, -24),
    BackgroundColor3 = Theme.cardActive,
    Text = "◢",
    TextColor3 = Theme.white,
    Font = Enum.Font.GothamBlack,
    TextSize = 12,
    ZIndex = 10,
}, Main)
corner(Grip, 6)
stroke(Grip, Theme.accent, 1, 0.3)

local resizing, rs, sz
Grip.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true; rs = input.Position; sz = Main.Size
    end
end)
UIS.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - rs
        CONFIG.WindowWidth = math.clamp(sz.X.Offset + d.X, 680, 1250)
        CONFIG.WindowHeight = math.clamp(sz.Y.Offset + d.Y, 440, 860)
        applyLayoutRefresh()
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = false end
end)

-- Piston Text Watcher (Safe Monitor Only)
task.spawn(function()
    while S.alive and Gui.Parent do
        task.wait(1.2)
        safeCall("PistonWatcher", function()
        if S.flags["ตรวจจับลูกสูบเป้าหมาย"] or S.flags["แจ้งเตือนลูกสูบ"] then
            for _, o in ipairs(LP:WaitForChild("PlayerGui"):GetDescendants()) do
                if o:IsA("TextLabel") or o:IsA("TextButton") then
                    local txt = (o.Text or ""):lower()
                    if txt:find("ลูกสูบ") and txt:find(tostring(S.piston), 1, true) then
                        local key = o:GetFullName() .. txt
                        if key ~= S.lastPiston then
                            S.lastPiston = key
                            toast("พบข้อความลูกสูบเป้าหมายเบอร์ " .. S.piston)
                        end
                    end
                end
            end
        end
        end)
    end
end)

safeCall("syncAppearance", syncAppearance)
local mainOk = safeCall("showPage(หน้าหลัก)", showPage, "หน้าหลัก")
if not mainOk then warn("[BALL KUN HUB] เปิดหน้าหลักไม่สำเร็จ ดู Error ด้านบน") end
toast(CONFIG.HubTitle .. " โหลดสำเร็จ (ฟอนต์ขาว • ปักหมุดแปลไทย)")
