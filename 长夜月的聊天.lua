local HoloLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/LumiereSeren/UI/refs/heads/main/ui%E5%BA%93"))()
local HttpService = game:GetService("HttpService")
local Player = game.Players.LocalPlayer

local API_BASE = "https://chat-service.3052034818.workers.dev"
local POLL_INTERVAL = 2
local currentRoom = nil
local pollTask = nil

local function httpPost(endpoint, bodyTable)
    local url = API_BASE .. endpoint
    local body = HttpService:JSONEncode(bodyTable)
    local success, resp = pcall(function()
        return http_request({
            Url = url, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = body
        })
    end)
    if not success then return nil end
    local responseBody = resp.Body or resp.body or resp.text
    if (resp.StatusCode or resp.status or resp.code) ~= 200 then return nil end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, responseBody)
    return ok and data or nil
end

local function httpGet(endpoint)
    local url = API_BASE .. endpoint
    local ok, res = pcall(game.HttpGet, game, url)
    if not ok then return nil end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, res)
    return ok2 and data or nil
end

local function joinRoomRequest(code) return httpGet("/chat/room/join?code=" .. code) end
local function sendMessageRequest(code, name, content) return httpPost("/chat/message/send", {roomCode = code, username = name, content = content}) end

local panel = HoloLib.CreatePanel("聊天室", nil, true)

-- 房间控制行
local controlRow = Instance.new("Frame"); controlRow.Size = UDim2.new(1, -20, 0, 35); controlRow.BackgroundTransparency = 1; controlRow.Parent = panel.Scroll
local rowLayout = Instance.new("UIListLayout"); rowLayout.FillDirection = Enum.FillDirection.Horizontal; rowLayout.Padding = UDim.new(0, 8); rowLayout.Parent = controlRow
local roomInput = panel:AddInput("房间号"); roomInput.Parent = controlRow; roomInput.Size = UDim2.new(0, 100, 1, 0)
local joinBtn = panel:AddButton("加入", function()
    local code = roomInput.Text; if code and code ~= "" then if code == "global" or code:match("^%d%d%d%d$") then joinRoom(code); roomInput.Text = "" end end
end); joinBtn.Parent = controlRow; joinBtn.Size = UDim2.new(0, 55, 1, 0)
local globalBtn = panel:AddButton("大厅", function() joinRoom("global") end); globalBtn.Parent = controlRow; globalBtn.Size = UDim2.new(0, 55, 1, 0)
local exitBtn = panel:AddButton("退出", function() leaveRoom() end); exitBtn.Parent = controlRow; exitBtn.Size = UDim2.new(0, 55, 1, 0); exitBtn.Visible = false

local nickInput = panel:AddInput("自定义昵称"); nickInput.PlaceholderText = "输入你的昵称"; nickInput.Text = "玩家" .. tostring(math.random(100, 999))
local roomStatus = panel:AddLabel("⚪ 未加入房间"); roomStatus.TextColor3 = Color3.fromRGB(180, 200, 255)

local msgContainer = Instance.new("ScrollingFrame"); msgContainer.Size = UDim2.new(1, -20, 0, 150); msgContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 25); msgContainer.BackgroundTransparency = 0.3; msgContainer.BorderSizePixel = 0; msgContainer.CanvasSize = UDim2.new(0, 0, 0, 0); msgContainer.ScrollBarThickness = 4; msgContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y; msgContainer.Parent = panel.Scroll
local msgLayout = Instance.new("UIListLayout"); msgLayout.SortOrder = Enum.SortOrder.LayoutOrder; msgLayout.Padding = UDim.new(0, 4); msgLayout.Parent = msgContainer

local msgInput = panel:AddInput("消息内容"); msgInput.PlaceholderText = "输入消息..."
local sendBtn = panel:AddButton("📤 发送", function() sendMessage() end)

function addMessage(displayName, content, timestamp)
    local bubble = Instance.new("Frame"); bubble.Size = UDim2.new(1, -12, 0, 0); bubble.BackgroundColor3 = Color3.fromRGB(25, 25, 40); bubble.BackgroundTransparency = 0.3; bubble.BorderSizePixel = 0; bubble.AutomaticSize = Enum.AutomaticSize.Y; bubble.Parent = msgContainer
    Instance.new("UICorner").CornerRadius = UDim.new(0, 6); Instance.new("UICorner").Parent = bubble
    local nameLabel = Instance.new("TextLabel"); nameLabel.Size = UDim2.new(1, -8, 0, 18); nameLabel.Position = UDim2.new(0, 4, 0, 4); nameLabel.BackgroundTransparency = 1; nameLabel.Text = displayName .. "  " .. os.date("%H:%M", (timestamp or os.time())/1000); nameLabel.TextColor3 = Color3.fromRGB(160, 180, 240); nameLabel.TextSize = 11; nameLabel.Font = Enum.Font.GothamBold; nameLabel.TextXAlignment = Enum.TextXAlignment.Left; nameLabel.Parent = bubble
    local contentLabel = Instance.new("TextLabel"); contentLabel.Size = UDim2.new(1, -8, 0, 0); contentLabel.Position = UDim2.new(0, 4, 0, 22); contentLabel.BackgroundTransparency = 1; contentLabel.Text = content; contentLabel.TextColor3 = Color3.fromRGB(245, 245, 255); contentLabel.TextSize = 13; contentLabel.Font = Enum.Font.Gotham; contentLabel.TextXAlignment = Enum.TextXAlignment.Left; contentLabel.TextWrapped = true; contentLabel.AutomaticSize = Enum.AutomaticSize.Y; contentLabel.Parent = bubble
    bubble.Size = UDim2.new(1, -12, 0, contentLabel.AbsoluteSize.Y + 28)
    msgContainer.CanvasPosition = Vector2.new(0, 0)
end

function clearMessages() for _, child in ipairs(msgContainer:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end end
function refreshMessages()
    if not currentRoom then return end
    local data = httpGet("/chat/message/list?room=" .. currentRoom .. "&limit=100")
    if data and data.messages then clearMessages() for i = #data.messages, 1, -1 do local m = data.messages[i]; addMessage(m.username, m.content, m.timestamp) end end
end
function joinRoom(code)
    if code == "" then return end local data = joinRoomRequest(code)
    if data and data.success then if pollTask then task.cancel(pollTask) end currentRoom = code; roomStatus.Text = "🌐 房间: " .. (code == "global" and "公共大厅" or code); exitBtn.Visible = true; refreshMessages(); pollTask = task.spawn(function() while true do task.wait(POLL_INTERVAL); refreshMessages() end end) end
end
function leaveRoom()
    if pollTask then task.cancel(pollTask) end currentRoom = nil; roomStatus.Text = "⚪ 未加入房间"; exitBtn.Visible = false; clearMessages(); addMessage("系统", "已退出房间", os.time()*1000)
end
function sendMessage()
    if not currentRoom then return end
    local content = msgInput.Text:gsub("^%s*(.-)%s*$", "%1")
    if content == "" then return end
    local custom = nickInput.Text:gsub("^%s*(.-)%s*$", "%1") if custom == "" then custom = "访客" end
    local displayName = Player.Name .. " (" .. custom .. ")"
    local data = sendMessageRequest(currentRoom, displayName, content)
    if data and data.success then msgInput.Text = ""; refreshMessages() end
end

addMessage("系统", "欢迎使用聊天室 ✨\n[1] 在上方输入4位数字房间号，或点击[大厅]\n[2] 你可以自定义[昵称]\n[3] 若想退出房间，点击[退出]", os.time()*1000)