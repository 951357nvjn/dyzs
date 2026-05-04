local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/LumiereSeren/UI/refs/heads/main/cyyWind.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 抢银行状态
local robbing = false
local robbingThread = nil

-- 获取银行 Money 物体及其 Prompt
local function getBankMoney()
    local bank = workspace:FindFirstChild("map")
    if bank then bank = bank:FindFirstChild("buildings") end
    if bank then bank = bank:FindFirstChild("bank") end
    if bank then bank = bank:FindFirstChild("bank") end
    if bank then bank = bank:FindFirstChild("Money") end
    if not bank then return nil, nil end
    local prompt = bank:FindFirstChildOfClass("ProximityPrompt")
    return bank, prompt
end

-- 自动抢银行循环
local function startRobbing()
    if robbing then return end
    robbing = true
    robbingThread = coroutine.create(function()
        while robbing do
            local money, prompt = getBankMoney()
            if money and prompt then
                -- 将角色传送到 Money 附近（可选，确保能触发）
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = money.CFrame + Vector3.new(0, 2, 0)  -- 传送到钱袋旁边
                    task.wait(0.1)
                end
                -- 触发 Prompt
                pcall(function() prompt:InputHold() end)
                task.wait(0.2)
                pcall(function() prompt:InputRelease() end)
            end
            task.wait(0.5)  -- 每0.5秒抢一次
        end
    end)
    coroutine.resume(robbingThread)
end

local function stopRobbing()
    robbing = false
    if robbingThread then
        coroutine.close(robbingThread)
        robbingThread = nil
    end
end

-- ==================== UI 部分（沿用你的 WindUI 风格） ====================
local ExternalImages = {
    MainTitleImage = "https://raw.githubusercontent.com/LumiereSeren/rob/refs/heads/main/IMG_20260122_004043.jpg",
    TeamLogoImage = "https://raw.githubusercontent.com/LumiereSeren/rob/refs/heads/main/IMG_20260122_004043.jpg",
    BackgroundImage = "video:https://raw.githubusercontent.com/951357nvjn/dyzs/refs/heads/main/%E9%9B%AA%E5%A4%A9%20%E4%BC%8A%E8%95%BE%E5%A8%9C%20%E6%9C%AA%E5%B0%BD%E4%B9%8B%E6%97%85.mp4",
    ThumbnailImage = "https://raw.githubusercontent.com/LumiereSeren/rob/refs/heads/main/IMG_20260122_004043.jpg"
}
local function loadExternalImage(url, defaultIcon)
    local success = pcall(function() game:HttpGet(url, true) end)
    return success and url or (defaultIcon or "image")
end

WindUI:Popup({
    Title = "債券を刷る",
    Icon = "sparkles",
    Content = "竞",
    Buttons = {
        {
            Title = "进入",
            Icon = "arrow-right",
            Variant = "Primary",
            Callback = function() createMainWindow() end
        }
    }
})

function createMainWindow()
    local windowOptions = {
        Title = "閃光の芦毛怪物<font color='#00FF00'>1.0</font>",
        Icon = "zap",
        IconTransparency = 0.5,
        IconThemed = true,
        Author = "小栗帽",
        Folder = "CloudHub",
        Size = UDim2.fromOffset(400, 350),
        Transparent = true,
        Theme = "Dark",
        User = { Enabled = true, Callback = function() end, Anonymous = false },
        SideBarWidth = 200,
        ScrollBarEnabled = true,
    }
    if ExternalImages.BackgroundImage then
        windowOptions.Background = ExternalImages.BackgroundImage
    else
        windowOptions.Background = {
            Type = "Gradient",
            Colors = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHex("#1a1a2e")),
                ColorSequenceKeypoint.new(0.5, Color3.fromHex("#16213e")),
                ColorSequenceKeypoint.new(1, Color3.fromHex("#0f3460"))
            }),
            Rotation = 45
        }
    end

    local Window = WindUI:CreateWindow(windowOptions)

    -- 时间标签
    local TimeTag = Window:Tag({ Title = "00:00", Color = Color3.fromHex("#30ff6a") })
    local hue = 0
    task.spawn(function()
        while true do
            local now = os.date("*t")
            local hours = string.format("%02d", now.hour)
            local minutes = string.format("%02d", now.min)
            hue = (hue + 0.01) % 1
            TimeTag:SetTitle(hours .. ":" .. minutes)
            TimeTag:SetColor(Color3.fromHSV(hue, 1, 1))
            task.wait(0.06)
        end
    end)

    Window:Tag({ Title = "v1.1", Color = Color3.fromHex("#30ff6a") })

    Window:EditOpenButton({
        Title = "小栗帽之力",
        Icon = "crown",
        CornerRadius = UDim.new(0,16),
        StrokeThickness = 3,
        Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
        Draggable = true,
        StrokeColor = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255,165,0)),
            ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(128,0,128))
        }),
    })

    -- 主页标签页
    local MainTab = Window:Tab({ Title = "主页", Icon = "home", Locked = false })
    MainTab:Paragraph({
        Title = "",
        Desc = "",
        Image = loadExternalImage(ExternalImages.MainTitleImage, "star"),
        ImageSize = 42,
        Thumbnail = loadExternalImage(ExternalImages.ThumbnailImage, "user"),
        ThumbnailSize = 120
    })
    MainTab:Paragraph({
        Title = "德与中山团队",
        Desc = "当前服务器ID: " .. game.PlaceId,
        Image = loadExternalImage(ExternalImages.TeamLogoImage, "users"),
        ImageSize = 32
    })
    MainTab:Paragraph({
        Title = "注入器",
        Desc = ": 小栗帽",
        Image = "cpu",
        ImageSize = 32
    })

    -- ==================== 抢银行标签页 ====================
    local RobTab = Window:Tab({ Title = "抢银行", Icon = "dollar-sign", Locked = false })

    -- 状态显示
    local statusLabel = RobTab:Paragraph({
        Title = "状态",
        Desc = "未开启",
        Image = "activity",
        ImageSize = 24
    })

    -- 开关
    local robToggle = RobTab:Toggle({
        Title = "自动抢银行",
        Desc = "每0.5秒触发一次银行金钱拾取",
        Value = false,
        Callback = function(state)
            if state then
                local money, prompt = getBankMoney()
                if not money then
                    WindUI:Toast("未找到银行Money对象，请确保路径正确", 3)
                    robToggle:SetValue(false)
                    return
                end
                if not prompt then
                    WindUI:Toast("未找到ProximityPrompt，无法抢", 3)
                    robToggle:SetValue(false)
                    return
                end
                startRobbing()
                statusLabel:SetDesc("正在抢银行...")
            else
                stopRobbing()
                statusLabel:SetDesc("已停止")
            end
        end
    })

    -- 手动传送按钮（传送到银行门口）
    RobTab:Button({
        Title = "传送到银行",
        Color = Color3.fromRGB(0,150,200),
        Callback = function()
            local money, _ = getBankMoney()
            if money then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = money.CFrame + Vector3.new(0, 2, 0)
                    WindUI:Toast("已传送到银行", 2)
                else
                    WindUI:Toast("无法获取角色", 2)
                end
            else
                WindUI:Toast("未找到银行位置", 2)
            end
        end
    })

    Window:OnClose(function() end)
    Window:OnDestroy(function() end)
end