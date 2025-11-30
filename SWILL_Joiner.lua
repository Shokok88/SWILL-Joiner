-- SWILL Joiner - Полностью рабочий для Delta
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

-- КОНФИГУРАЦИЯ
local DISCORD_CHANNEL_ID = "1401775181025775738"
local ACCESS_TOKEN = "gNZSWMBhkCPVaRnyBhccgRxBVVOuFfgc"
local MIN_PLAYERS = 1
local MAX_PLAYERS = 8
local MIN_BRAINROT_VALUE = 0

-- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
local ServerList = {}
local AutoJoin = false
local LastChecked = 0

-- СОЗДАНИЕ GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SWILLJoiner"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 500)
MainFrame.Position = UDim2.new(0, 50, 0, 50)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Заголовок
local TitleFrame = Instance.new("Frame")
TitleFrame.Size = UDim2.new(1, 0, 0, 40)
TitleFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TitleFrame.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "SWILL JOINTER v1.0"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = TitleFrame

-- Кнопка сворачивания
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -35, 0, 5)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
MinimizeButton.Text = "_"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 16
MinimizeButton.Parent = TitleFrame

-- Область настроек
local SettingsFrame = Instance.new("Frame")
SettingsFrame.Size = UDim2.new(1, -20, 0, 120)
SettingsFrame.Position = UDim2.new(0, 10, 0, 50)
SettingsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
SettingsFrame.Parent = MainFrame

-- Контролы
local AutoJoinToggle = Instance.new("TextButton")
AutoJoinToggle.Size = UDim2.new(0, 120, 0, 30)
AutoJoinToggle.Position = UDim2.new(0, 10, 0, 10)
AutoJoinToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AutoJoinToggle.Text = "AUTO JOIN: OFF"
AutoJoinToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoJoinToggle.Parent = SettingsFrame

local PlayersLabel = Instance.new("TextLabel")
PlayersLabel.Size = UDim2.new(0, 100, 0, 20)
PlayersLabel.Position = UDim2.new(0, 10, 0, 50)
PlayersLabel.BackgroundTransparency = 1
PlayersLabel.Text = "Players: 1-8"
PlayersLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayersLabel.Parent = SettingsFrame

local BrainrotLabel = Instance.new("TextLabel")
BrainrotLabel.Size = UDim2.new(0, 150, 0, 20)
BrainrotLabel.Position = UDim2.new(0, 10, 0, 80)
BrainrotLabel.BackgroundTransparency = 1
BrainrotLabel.Text = "Min Brainrot: 0"
BrainrotLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
BrainrotLabel.Parent = SettingsFrame

-- Список серверов
local ServersFrame = Instance.new("ScrollingFrame")
ServersFrame.Size = UDim2.new(1, -20, 0, 300)
ServersFrame.Position = UDim2.new(0, 10, 0, 180)
ServersFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ServersFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ServersFrame.Parent = MainFrame

-- ФУНКЦИЯ ДЛЯ HTTP ЗАПРОСОВ
local function HttpRequest(url, method, headers)
    local success, result = pcall(function()
        if syn and syn.request then
            return syn.request({Url=url, Method=method, Headers=headers})
        elseif request then
            return request({Url=url, Method=method, Headers=headers})
        else
            return {Success=false}
        end
    end)
    return success and result or {Success=false}
end

-- ПОЛУЧЕНИЕ СООБЩЕНИЙ ИЗ DISCORD
local function GetDiscordMessages()
    local url = "https://discord.com/api/v9/channels/"..DISCORD_CHANNEL_ID.."/messages"
    local response = HttpRequest(url, "GET", {
        ["Authorization"] = ACCESS_TOKEN
    })
    
    if response.Success and response.Body then
        local success, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if success then
            return data
        end
    end
    return {}
end

-- ИЗВЛЕЧЕНИЕ JOB ID ИЗ СООБЩЕНИЯ
local function ExtractJobId(message)
    if message and message.content then
        local patterns = {
            "jobid: (%w+)",
            "JobId: (%w+)", 
            "JOIN: (%w+)",
            "(%w+%-%w+%-%w+)"
        }
        
        for _, pattern in ipairs(patterns) do
            local jobId = string.match(message.content, pattern)
            if jobId and #jobId > 10 then
                return jobId
            end
        end
    end
    return nil
end

-- АВТОМАТИЧЕСКОЕ ПРИСОЕДИНЕНИЕ
local function AutoJoinServer(jobId)
    if jobId and AutoJoin then
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, Players.LocalPlayer)
        end)
    end
end

-- ОБНОВЛЕНИЕ ИНТЕРФЕЙСА
local function UpdateGUI()
    ServersFrame:ClearAllChildren()
    ServersFrame.CanvasSize = UDim2.new(0, 0, 0, #ServerList * 40)
    
    for i, server in ipairs(ServerList) do
        local serverFrame = Instance.new("Frame")
        serverFrame.Size = UDim2.new(1, -10, 0, 35)
        serverFrame.Position = UDim2.new(0, 5, 0, (i-1)*40)
        serverFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        serverFrame.Parent = ServersFrame
        
        local serverLabel = Instance.new("TextLabel")
        serverLabel.Size = UDim2.new(0.7, 0, 1, 0)
        serverLabel.BackgroundTransparency = 1
        serverLabel.Text = "JobID: "..string.sub(server.jobId, 1, 10).."..."
        serverLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        serverLabel.TextXAlignment = Enum.TextXAlignment.Left
        serverLabel.Parent = serverFrame
        
        local joinButton = Instance.new("TextButton")
        joinButton.Size = UDim2.new(0.25, 0, 0, 25)
        joinButton.Position = UDim2.new(0.73, 0, 0, 5)
        joinButton.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
        joinButton.Text = "JOIN"
        joinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        joinButton.Parent = serverFrame
        
        joinButton.MouseButton1Click:Connect(function()
            AutoJoinServer(server.jobId)
        end)
    end
end

-- ОСНОВНОЙ ЦИКЛ МОНИТОРИНГА
spawn(function()
    while true do
        if AutoJoin then
            local messages = GetDiscordMessages()
            for _, message in ipairs(messages) do
                local jobId = ExtractJobId(message)
                if jobId then
                    local exists = false
                    for _, server in ipairs(ServerList) do
                        if server.jobId == jobId then
                            exists = true
                            break
                        end
                    end
                    
                    if not exists then
                        table.insert(ServerList, 1, {jobId = jobId})
                        if #ServerList > 20 then
                            table.remove(ServerList, 21)
                        end
                        UpdateGUI()
                        AutoJoinServer(jobId)
                    end
                end
            end
        end
        wait(2) -- Проверка каждые 2 секунды
    end
end)

-- ОБРАБОТЧИКИ СОБЫТИЙ
AutoJoinToggle.MouseButton1Click:Connect(function()
    AutoJoin = not AutoJoin
    if AutoJoin then
        AutoJoinToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        AutoJoinToggle.Text = "AUTO JOIN: ON"
    else
        AutoJoinToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        AutoJoinToggle.Text = "AUTO JOIN: OFF"
    end
end)

MinimizeButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- ПЕРЕТАСКИВАНИЕ ОКНА
local dragging = false
local dragInput, dragStart, startPos

TitleFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ИНИЦИАЛИЗАЦИЯ
UpdateGUI()
print("SWILL Joiner активирован! Канал: "..DISCORD_CHANNEL_ID)
