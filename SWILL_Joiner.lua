-- SWILL Joiner v2.0 - Интеграция с Chilli Hub Premium
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- КОНФИГУРАЦИЯ
local DISCORD_CHANNEL_ID = "1401775181025775738"
local ACCESS_TOKEN = "gNZSWMBhkCPVaRnyBhccgRxBVVOuFfgc"

-- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
local ServerList = {}
local AutoJoin = false
local MinPlayers = 1
local MaxPlayers = 8
local MinBrainrot = 0

-- ПОИСК CHILLI HUB ELEMENTS
local function FindChilliHubElements()
    local chilliGui = CoreGui:FindFirstChild("ChilliHub") or CoreGui:FindFirstChild("Chilli_Hub")
    
    if chilliGui then
        local jobIdInput = FindTextbox(chilliGui, "JobId", "JobID", "Input")
        local joinButton = FindButton(chilliGui, "Join", "JobID", "Join")
        
        return jobIdInput, joinButton
    end
    return nil, nil
end

local function FindTextbox(gui, ...)
    local names = {...}
    for _, name in ipairs(names) do
        local textbox = gui:FindFirstChild(name, true)
        if textbox and textbox:IsA("TextBox") then
            return textbox
        end
    end
    return nil
end

local function FindButton(gui, ...)
    local names = {...}
    for _, name in ipairs(names) do
        local button = gui:FindFirstChild(name, true)
        if button and button:IsA("TextButton") then
            return button
        end
    end
    return nil
end

-- АВТОМАТИЧЕСКОЕ ПРИСОЕДИНЕНИЕ ЧЕРЕЗ CHILLI HUB
local function JoinViaChilliHub(jobId)
    local jobIdInput, joinButton = FindChilliHubElements()
    
    if jobIdInput and joinButton then
        -- Ввод Job-Id
        jobIdInput.Text = jobId
        jobIdInput:CaptureFocus()
        
        -- Нажатие кнопки Join
        wait(0.1)
        joinButton:Click()
        return true
    end
    return false
end

-- ОСНОВНОЙ ЦИКЛ МОНИТОРИНГА
spawn(function()
    while true do
        if AutoJoin then
            local messages = GetDiscordMessages()
            for _, message in ipairs(messages) do
                local jobId = ExtractJobId(message)
                if jobId and not ServerExists(jobId) then
                    table.insert(ServerList, 1, {
                        jobId = jobId,
                        players = message.players or 0,
                        brainrot = message.brainrot or 0
                    })
                    
                    UpdateGUI()
                    
                    -- Авто-присоединение если соответствует фильтрам
                    if MeetsFilters(ServerList[1]) then
                        JoinViaChilliHub(jobId)
                    end
                end
            end
        end
        wait(3)
    end
end)

-- ФИЛЬТРЫ СЕРВЕРОВ
local function MeetsFilters(server)
    local playerCount = server.players or 0
    local brainrotValue = server.brainrot or 0
    
    return playerCount >= MinPlayers 
        and playerCount <= MaxPlayers
        and brainrotValue >= MinBrainrot
end

-- ОБНОВЛЕНИЕ GUI С КНОПКАМИ JOIN
local function UpdateGUI()
    ServersFrame:ClearAllChildren()
    
    for i, server in ipairs(ServerList) do
        local serverFrame = CreateServerFrame(i, server)
        serverFrame.Parent = ServersFrame
        
        -- Кнопка Join в нашем GUI
        local joinBtn = serverFrame:FindFirstChild("JoinBtn")
        if joinBtn then
            joinBtn.MouseButton1Click:Connect(function()
                JoinViaChilliHub(server.jobId)
            end)
        end
    end
end

-- ИСПРАВЛЕНИЕ СВОРАЧИВАНИЯ
local isMinimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 400, 0, 40) -- Только заголовок
        MinimizeButton.Text = "□"
    else
        MainFrame.Size = UDim2.new(0, 400, 0, 500) -- Полный размер
        MinimizeButton.Text = "_"
    end
end)
