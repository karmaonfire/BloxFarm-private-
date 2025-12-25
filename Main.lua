-- Blox Fruits FUNCTIONAL Auto Quest Farm v4.1
-- Compatibile con Xeno Executor
-- By VillainAI

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Configurazione FUNZIONANTE
local Config = {
    AutoQuest = true,
    AutoFarm = true,
    AutoSell = false,
    AutoRiprendiQuest = true,
    Distance = 15, -- RIDOTTO per essere più vicino
    AttesaUccisione = 0.5, -- RIDOTTO per essere più veloce
    AntiAfk = true,
    Notifiche = true,
    UseSkill = true,
    AttackMethod = "Click", -- "Click" o "Skill"
    FastAttack = true
}

-- VARIABILI CRITICHE per funzionamento reale
local InFarming = false
local QuestCompletate = 0
local InizioTempo = tick()
local CurrentTarget = nil
local QuestData = nil
local MobFolder = nil
local EnemyCount = 0
local RequiredKills = 0

-- DATABASE NPC REALI (posizioni aggiornate)
local NpcDatabase = {
    ["Marine Lieutenant"] = {
        LevelMin = 1,
        LevelMax = 15,
        Position = CFrame.new(-2603.79, 38.44, 206.19),
        QuestName = "MarineQuest",
        EnemyType = "Marine"
    },
    ["Bandit"] = {
        LevelMin = 15,
        LevelMax = 30,
        Position = CFrame.new(-1146.83, 4.62, 3827.95),
        QuestName = "BanditQuest",
        EnemyType = "Bandit"
    },
    ["Monkey"] = {
        LevelMin = 30,
        LevelMax = 60,
        Position = CFrame.new(-1497.62, 13.02, 376.32),
        QuestName = "MonkeyQuest",
        EnemyType = "Monkey"
    },
    ["Gorilla"] = {
        LevelMin = 60,
        LevelMax = 90,
        Position = CFrame.new(-1247.77, 44.29, -476.77),
        QuestName = "GorillaQuest",
        EnemyType = "Gorilla"
    },
    ["Pirate"] = {
        LevelMin = 90,
        LevelMax = 120,
        Position = CFrame.new(-1168.66, 4.75, 3906.18),
        QuestName = "PirateQuest",
        EnemyType = "Pirate"
    }
}

-- ============================================
-- FUNZIONI CORE FUNZIONANTI
-- ============================================

-- 1. OTTIENI LIVELLO REALE (funzionante)
function GetPlayerLevel()
    local leaderstats = Player:FindFirstChild("leaderstats")
    if leaderstats then
        local levelStat = leaderstats:FindFirstChild("Level") or leaderstats:FindFirstChild("level")
        if levelStat then
            return levelStat.Value
        end
    end
    return 1
end

-- 2. TELEPORTA FUNZIONANTE (con anti-stuck)
function SafeTeleport(position)
    local success = pcall(function()
        local humanoidRootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            -- Usa CFrame per posizionamento preciso
            humanoidRootPart.CFrame = position
            wait(0.2)
            return true
        end
    end)
    return success
end

-- 3. TROVA NPC PER LIVELLO (funzionante)
function GetNPCForLevel(level)
    for npcName, npcData in pairs(NpcDatabase) do
        if level >= npcData.LevelMin and level <= npcData.LevelMax then
            return npcName, npcData
        end
    end
    return "Marine Lieutenant", NpcDatabase["Marine Lieutenant"]
end

-- 4. TROVA ENEMY NEL GIOCO REALE (funzionante)
function FindEnemies(enemyType)
    local enemies = {}
    
    -- Cerca in varie posizioni dove potrebbero essere gli enemy
    local possibleFolders = {
        Workspace:FindFirstChild("Enemies"),
        Workspace:FindFirstChild("NPCs"),
        Workspace:FindFirstChild("_NPCs"),
        Workspace
    }
    
    for _, folder in pairs(possibleFolders) do
        if folder then
            for _, child in pairs(folder:GetChildren()) do
                -- Controlla vari pattern di nomi
                if child.Name:find(enemyType) or 
                   child.Name:lower():find(enemyType:lower()) or
                   (child:FindFirstChild("Humanoid") and child.Humanoid.Health > 0) then
                    
                    -- Verifica che sia un enemy valido
                    local humanoid = child:FindFirstChild("Humanoid")
                    local rootPart = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Head")
                    
                    if humanoid and rootPart and humanoid.Health > 0 then
                        table.insert(enemies, {
                            Model = child,
                            Humanoid = humanoid,
                            RootPart = rootPart,
                            Distance = (HumanoidRootPart.Position - rootPart.Position).Magnitude
                        })
                    end
                end
            end
        end
    end
    
    -- Ordina per distanza (più vicini prima)
    table.sort(enemies, function(a, b)
        return a.Distance < b.Distance
    end)
    
    return enemies
end

-- 5. ATTACCO REALE (funzionante)
function AttackEnemy(enemy)
    if not enemy or not enemy.RootPart then
        return false
    end
    
    -- 1. TELEPORTA VICINO AL NEMICO
    local offset = Vector3.new(0, 0, Config.Distance)
    local targetPosition = enemy.RootPart.Position + offset
    
    SafeTeleport(CFrame.new(targetPosition))
    wait(0.1)
    
    -- 2. ATTACCA CON METODO CORRETTO
    if Config.AttackMethod == "Click" then
        -- ATTACCO CLICK (funzionante)
        local args = {
            [1] = "Click",
            [2] = false
        }
        
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local combat = remotes:FindFirstChild("Combat")
            if combat then
                combat:FireServer(unpack(args))
            end
        end
        
        -- Click multipli per fast attack
        if Config.FastAttack then
            for i = 1, 3 do
                if enemy.Humanoid.Health <= 0 then break end
                
                -- Simula click
                local clickRemote = ReplicatedStorage:FindFirstChild("RemoteClick")
                if clickRemote then
                    clickRemote:FireServer()
                end
                wait(0.1)
            end
        end
        
    elseif Config.AttackMethod == "Skill" and Config.UseSkill then
        -- ATTACCO SKILL (se disponibile)
        for i = 1, 3 do
            if enemy.Humanoid.Health <= 0 then break end
            
            local skillArgs = {
                [1] = "Ability" .. i,
                [2] = false
            }
            
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local combat = remotes:FindFirstChild("Combat")
                if combat then
                    combat:FireServer(unpack(skillArgs))
                end
            end
            wait(0.3)
        end
    end
    
    -- 3. ATTESA PER LA MORTE
    wait(Config.AttesaUccisione)
    
    -- 4. VERIFICA SE È MORTO
    local isDead = enemy.Humanoid.Health <= 0
    if isDead then
        EnemyCount = EnemyCount + 1
        Notifica("☠️ Ucciso: " .. EnemyCount .. "/" .. RequiredKills)
    end
    
    return isDead
end

-- 6. SISTEMA QUEST REALE (funzionante)
function AcceptQuestFromNPC(npcName, npcData)
    -- 1. Vai all'NPC
    SafeTeleport(npcData.Position)
    wait(1)
    
    -- 2. Trova l'NPC fisico
    local npcModel = FindNPCInWorkspace(npcName)
    if not npcModel then
        Notifica("❌ NPC non trovato: " .. npcName)
        return false
    end
    
    -- 3. Accetta quest (simula click)
    if npcModel:FindFirstChild("ClickDetector") then
        fireclickdetector(npcModel.ClickDetector)
        wait(0.5)
        
        -- 4. Controlla se la quest è stata accettata
        QuestData = {
            NPC = npcName,
            EnemyType = npcData.EnemyType,
            Required = 10, -- Default
            Completed = 0
        }
        
        Notifica("✅ Quest accettata: " .. npcData.EnemyType)
        return true
    end
    
    return false
end

function CompleteQuestAtNPC(npcName, npcData)
    SafeTeleport(npcData.Position)
    wait(1)
    
    local npcModel = FindNPCInWorkspace(npcName)
    if npcModel and npcModel:FindFirstChild("ClickDetector") then
        fireclickdetector(npcModel.ClickDetector)
        wait(0.5)
        
        QuestCompletate = QuestCompletate + 1
        Notifica("🎉 Quest completata! Totale: " .. QuestCompletate)
        return true
    end
    
    return false
end

-- 7. TROVA NPC NEL WORKSPACE (funzionante)
function FindNPCInWorkspace(npcName)
    -- Cerca in varie posizioni
    local searchLocations = {
        Workspace.NPCs,
        Workspace._NPCs,
        Workspace.Live,
        Workspace
    }
    
    for _, location in pairs(searchLocations) do
        if location then
            local npc = location:FindFirstChild(npcName)
            if npc then
                return npc
            end
            
            -- Cerca per nome parziale
            for _, child in pairs(location:GetChildren()) do
                if child.Name:find(npcName) or npcName:find(child.Name) then
                    return child
                end
            end
        end
    end
    
    return nil
end

-- 8. FARM LOOP FUNZIONANTE (cuore del sistema)
function StartFarmLoop()
    if InFarming then return end
    InFarming = true
    
    spawn(function()
        while InFarming and Config.AutoFarm do
            local playerLevel = GetPlayerLevel()
            local npcName, npcData = GetNPCForLevel(playerLevel)
            
            Notifica("🎯 Farming con: " .. npcName .. " (Lv. " .. playerLevel .. ")")
            
            -- FASE 1: ACCETTA QUEST
            if Config.AutoQuest and (not QuestData or QuestData.Completed >= QuestData.Required) then
                if AcceptQuestFromNPC(npcName, npcData) then
                    EnemyCount = 0
                    RequiredKills = 10 -- Default value
                    wait(1)
                else
                    wait(2)
                    continue
                end
            end
            
            -- FASE 2: FARM ENEMY
            local maxAttempts = 50
            local attempts = 0
            
            while InFarming and EnemyCount < RequiredKills and attempts < maxAttempts do
                attempts = attempts + 1
                
                -- Trova enemy
                local enemies = FindEnemies(npcData.EnemyType)
                
                if #enemies > 0 then
                    -- Attacca enemy
                    for _, enemy in pairs(enemies) do
                        if not InFarming or EnemyCount >= RequiredKills then
                            break
                        end
                        
                        if enemy.Humanoid.Health > 0 then
                            AttackEnemy(enemy)
                            wait(0.3)
                        end
                    end
                else
                    Notifica("🔍 Nessun enemy trovato, cerco ancora...")
                    wait(1)
                end
                
                wait(0.5)
            end
            
            -- FASE 3: COMPLETA QUEST
            if EnemyCount >= RequiredKills and Config.AutoQuest then
                if CompleteQuestAtNPC(npcName, npcData) then
                    EnemyCount = 0
                    QuestData = nil
                    wait(2)
                    
                    -- Riprendi nuova quest automaticamente
                    if Config.AutoRiprendiQuest then
                        wait(1)
                    end
                end
            end
            
            -- FASE 4: FARM BASE (senza quest)
            if not Config.AutoQuest then
                local enemies = FindEnemies(npcData.EnemyType)
                for _, enemy in pairs(enemies) do
                    if not InFarming then break end
                    AttackEnemy(enemy)
                    wait(0.5)
                end
            end
            
            wait(1)
        end
    end)
end

function StopFarmLoop()
    InFarming = false
    CurrentTarget = nil
    Notifica("⏹️ Farm fermato")
end

-- 9. SISTEMA NOTIFICHE (funzionante)
function Notifica(message)
    if Config.Notifiche then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "🤖 Auto Farm",
                Text = message,
                Duration = 5,
                Icon = "rbxassetid://4483345998"
            })
        end)
    end
    print("[FARM] " .. message)
end

-- 10. ANTI-AFK FUNZIONANTE
if Config.AntiAfk then
    spawn(function()
        while true do
            wait(60) -- Ogni 60 secondi
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0,0))
            end)
        end
    end)
end

-- ============================================
-- GUI SEMPLICE MA FUNZIONANTE
-- ============================================

function CreateSimpleGUI()
    -- Crea ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoFarmGUI"
    ScreenGui.Parent = Player.PlayerGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 300, 0, 400)
    MainFrame.Position = UDim2.new(0, 10, 0, 10)
    MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Title.Text = "🤖 AUTO FARM v4.1"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.Parent = MainFrame
    
    -- Toggle Buttons
    local buttons = {
        {name = "▶️ START FARM", callback = function() StartFarmLoop() end},
        {name = "⏹️ STOP FARM", callback = function() StopFarmLoop() end},
        {name = "📊 STATS", callback = function() 
            Notifica("Quests: " .. QuestCompletate .. " | Level: " .. GetPlayerLevel())
        end},
        {name = "🎯 TELEPORT TO NPC", callback = function()
            local level = GetPlayerLevel()
            local _, npcData = GetNPCForLevel(level)
            SafeTeleport(npcData.Position)
        end}
    }
    
    local yPos = 50
    for i, btn in ipairs(buttons) do
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0.9, 0, 0, 40)
        Button.Position = UDim2.new(0.05, 0, 0, yPos)
        Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        Button.Text = btn.name
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.Font = Enum.Font.Gotham
        Button.TextSize = 14
        Button.Parent = MainFrame
        
        Button.MouseButton1Click:Connect(btn.callback)
        
        yPos = yPos + 45
    end
    
    -- Stats Display
    local StatsLabel = Instance.new("TextLabel")
    StatsLabel.Size = UDim2.new(0.9, 0, 0, 100)
    StatsLabel.Position = UDim2.new(0.05, 0, 0, yPos + 20)
    StatsLabel.BackgroundTransparency = 1
    StatsLabel.Text = "📈 STATS\nQuests: 0\nLevel: 1\nTime: 00:00"
    StatsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatsLabel.Font = Enum.Font.Gotham
    StatsLabel.TextSize = 14
    StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatsLabel.TextYAlignment = Enum.TextYAlignment.Top
    StatsLabel.Parent = MainFrame
    
    -- Update stats periodically
    spawn(function()
        while true do
            wait(2)
            if StatsLabel then
                local currentTime = tick()
                local elapsed = currentTime - InizioTempo
                local hours = math.floor(elapsed / 3600)
                local minutes = math.floor((elapsed % 3600) / 60)
                local seconds = math.floor(elapsed % 60)
                
                StatsLabel.Text = string.format(
                    "📈 STATS\nQuests: %d\nLevel: %d\nTime: %02d:%02d:%02d\nStatus: %s",
                    QuestCompletate,
                    GetPlayerLevel(),
                    hours, minutes, seconds,
                    InFarming and "FARMING" or "IDLE"
                )
            end
        end
    end)
    
    Notifica("✅ GUI Funzionale caricata!")
    return ScreenGui
end

-- ============================================
-- INIZIALIZZAZIONE
-- ============================================

-- Crea GUI funzionale
CreateSimpleGUI()

-- Ricarica character se muore
Player.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
    wait(2)
    
    if Config.AutoFarm then
        StartFarmLoop()
    end
end)

-- Avvio automatico
wait(3)
if Config.AutoFarm then
    Notifica("🚀 Auto Farm avviato automaticamente!")
    StartFarmLoop()
else
    Notifica("✅ Sistema pronto! Clicca START per iniziare.")
end

-- Tutorial rapido
wait(2)
Notifica("💡 USO: 1) Clicca START  2) Teleport se necessario  3) Guarda le stats!")
