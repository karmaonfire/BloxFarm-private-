-- Blox Fruits Auto Quest Farm v3.0
-- Compatibile con Xeno Executor
-- By VillainAI

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Configurazione
local Config = {
    AutoQuest = true,
    AutoFarm = true,
    AutoSell = false,
    AutoRiprendiQuest = true,
    Distance = 25,
    AttesaUccisione = 3,
    AntiAfk = true,
    Notifiche = true
}

-- Variabili globali
local NpcAttuale = nil
local QuestAttuale = nil
local NemicoAttuale = nil
local InFarming = false
local QuestCompletate = 0
local InizioTempo = tick()

-- Libreria di NPC per quest (aggiornata per Blox Fruits)
local NpcDatabase = {
    -- Primo mare
    ["Marine"] = {
        LivelloMin = 1,
        LivelloMax = 15,
        Posizione = Vector3.new(-2603.79, 38.44, 206.19),
        NomeNPC = "Marine Lieutenant"
    },
    ["Bandit"] = {
        LivelloMin = 15,
        LivelloMax = 30,
        Posizione = Vector3.new(-1146.83, 4.62, 3827.95),
        NomeNPC = "Bandit"
    },
    ["Monkey"] = {
        LivelloMin = 30,
        LivelloMax = 60,
        Posizione = Vector3.new(-1497.62, 13.02, 376.32),
        NomeNPC = "Monkey"
    },
    ["Gorilla"] = {
        LivelloMin = 60,
        LivelloMax = 90,
        Posizione = Vector3.new(-1247.77, 44.29, -476.77),
        NomeNPC = "Gorilla"
    },
    ["Pirate"] = {
        LivelloMin = 90,
        LivelloMax = 120,
        Posizione = Vector3.new(-1168.66, 4.75, 3906.18),
        NomeNPC = "Pirate"
    },
    ["Brute"] = {
        LivelloMin = 120,
        LivelloMax = 150,
        Posizione = Vector3.new(-1141.74, 4.75, 4292.15),
        NomeNPC = "Brute"
    },
    -- Secondo mare
    ["Desert Bandit"] = {
        LivelloMin = 150,
        LivelloMax = 175,
        Posizione = Vector3.new(1085.48, 6.90, 4192.23),
        NomeNPC = "Desert Bandit"
    },
    ["Snow Bandit"] = {
        LivelloMin = 175,
        LivelloMax = 190,
        Posizione = Vector3.new(1347.53, 36.67, -1326.62),
        NomeNPC = "Snow Bandit"
    },
    -- Continua con altri NPC...
}

-- Funzione per ottenere il livello del giocatore
function GetLivelloGiocatore()
    local leaderstats = Player:FindFirstChild("leaderstats")
    if leaderstats then
        local level = leaderstats:FindFirstChild("Level")
        if level then
            return level.Value
        end
    end
    return 1
end

-- Trova NPC adatto al livello
function TrovaNPCPerLivello(livello)
    for nomeNpc, dati in pairs(NpcDatabase) do
        if livello >= dati.LivelloMin and livello <= dati.LivelloMax then
            return dati
        end
    end
    return NpcDatabase["Marine"] -- Default
end

-- Teleport sicuro
function Teleporta(posizione)
    pcall(function()
        Character:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(posizione)
    end)
end

-- Cerca NPC nel workspace
function TrovaNPC(nomeNPC)
    for _, npc in pairs(Workspace.NPCs:GetChildren()) do
        if npc.Name == nomeNPC then
            return npc
        end
    end
    return nil
end

-- Accetta quest
function AccettaQuest(npc)
    if npc:FindFirstChild("ClickDetector") then
        fireclickdetector(npc.ClickDetector)
        wait(1)
        
        -- Cerca finestra quest
        for _, v in pairs(Player.PlayerGui:GetChildren()) do
            if v.Name == "DialogueGui" then
                -- Cerca pulsante "Accept"
                local acceptBtn = v:FindFirstChild("AcceptButton", true)
                if acceptBtn then
                    fireclickdetector(acceptBtn:FindFirstChildOfClass("ClickDetector"))
                    return true
                end
            end
        end
    end
    return false
end

-- Completa quest
function CompletaQuest(npc)
    if npc:FindFirstChild("ClickDetector") then
        fireclickdetector(npc.ClickDetector)
        wait(1)
        
        -- Cerca pulsante "Complete"
        for _, v in pairs(Player.PlayerGui:GetChildren()) do
            if v.Name == "DialogueGui" then
                local completeBtn = v:FindFirstChild("CompleteButton", true)
                if completeBtn then
                    fireclickdetector(completeBtn:FindFirstChildOfClass("ClickDetector"))
                    return true
                end
            end
        end
    end
    return false
end

-- Ottieni dettagli quest
function GetDettagliQuest()
    local questText = ""
    
    for _, v in pairs(Player.PlayerGui:GetChildren()) do
        if v.Name == "QuestGui" then
            local textLabel = v:FindFirstChild("QuestText", true)
            if textLabel then
                questText = textLabel.Text
                break
            end
        end
    end
    
    -- Estrai nome nemico dal testo quest
    local nemico = ""
    for nomeNpc, _ in pairs(NpcDatabase) do
        if questText:find(nomeNpc) then
            nemico = nomeNpc
            break
        end
    end
    
    return {
        testo = questText,
        nemico = nemico,
        quantità = tonumber(questText:match("%d+")) or 1
    }
end

-- Trova nemici da uccidere
function TrovaNemici(tipoNemico)
    local nemici = {}
    
    for _, npc in pairs(Workspace.NPCs:GetChildren()) do
        if npc.Name:find(tipoNemico) and npc:FindFirstChild("Humanoid") then
            table.insert(nemici, npc)
        end
    end
    
    return nemici
end

-- Attacca nemico
function AttaccaNemico(nemico)
    if not nemico or not nemico:FindFirstChild("Humanoid") then
        return false
    end
    
    -- Teleport vicino al nemico
    Teleporta(nemico.HumanoidRootPart.Position + Vector3.new(0, 0, Config.Distance))
    
    -- Usa abilità
    pcall(function()
        -- Simula attacchi
        local args = {
            [1] = "Click",
            [2] = false
        }
        
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):FireServer(unpack(args))
        
        -- Attacchi speciali
        for i = 1, 3 do
            local args2 = {
                [1] = "Ability1",
                [2] = false
            }
            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):FireServer(unpack(args2))
            wait(0.5)
        end
    end)
    
    wait(Config.AttesaUccisione)
    return nemico.Humanoid.Health <= 0
end

-- Sistema Auto-Farm
function AvviaFarm()
    if InFarming then return end
    InFarming = true
    
    spawn(function()
        while InFarming and Config.AutoFarm do
            local livello = GetLivelloGiocatore()
            local npcDati = TrovaNPCPerLivello(livello)
            
            -- 1. Vai all'NPC
            Teleporta(npcDati.Posizione)
            wait(2)
            
            -- 2. Trova NPC fisico
            local npcFisico = TrovaNPC(npcDati.NomeNPC)
            if not npcFisico then
                Notifica("NPC non trovato: " .. npcDati.NomeNPC)
                wait(5)
                continue
            end
            
            -- 3. Accetta quest
            if Config.AutoQuest then
                if AccettaQuest(npcFisico) then
                    Notifica("Quest accettata da: " .. npcDati.NomeNPC)
                    QuestAttuale = GetDettagliQuest()
                    wait(2)
                end
            end
            
            -- 4. Farm dei nemici
            if QuestAttuale and QuestAttuale.nemico ~= "" then
                local nemici = TrovaNemici(QuestAttuale.nemico)
                local uccisi = 0
                local richiesti = QuestAttuale.quantità or 10
                
                Notifica("Farming: " .. QuestAttuale.nemico .. " (" .. richiesti .. ")")
                
                while uccisi < richiesti and InFarming do
                    for _, nemico in pairs(nemici) do
                        if not InFarming then break end
                        
                        if nemico:FindFirstChild("Humanoid") and nemico.Humanoid.Health > 0 then
                            if AttaccaNemico(nemico) then
                                uccisi = uccisi + 1
                                Notifica("Progresso: " .. uccisi .. "/" .. richiesti)
                                
                                if uccisi >= richiesti then
                                    break
                                end
                            end
                        end
                        
                        wait(0.5)
                    end
                    
                    -- Ricerca nuovi nemici
                    nemici = TrovaNemici(QuestAttuale.nemico)
                    wait(1)
                end
                
                -- 5. Completa quest
                if uccisi >= richiesti then
                    Teleporta(npcDati.Posizione)
                    wait(2)
                    
                    if CompletaQuest(npcFisico) then
                        QuestCompletate = QuestCompletate + 1
                        Notifica("✅ Quest completata! Totale: " .. QuestCompletate)
                        
                        -- Riprendi automaticamente nuova quest
                        if Config.AutoRiprendiQuest then
                            wait(3)
                            AccettaQuest(npcFisico)
                            QuestAttuale = GetDettagliQuest()
                        end
                    end
                end
            else
                -- Farm normale senza quest
                local nemici = TrovaNemici(npcDati.NomeNPC)
                for _, nemico in pairs(nemici) do
                    if not InFarming then break end
                    AttaccaNemico(nemico)
                    wait(1)
                end
            end
            
            wait(1)
        end
    end)
end

-- Ferma farm
function FermaFarm()
    InFarming = false
    Notifica("Farm fermato")
end

-- Sistema Anti-AFK
if Config.AntiAfk then
    spawn(function()
        while true do
            wait(30)
            VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        end
    end)
end

-- Sistema notifiche
function Notifica(testo)
    if Config.Notifiche then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Blox Fruits Auto Farm",
            Text = testo,
            Duration = 5
        })
    end
    print("[AutoFarm] " .. testo)
end

-- UI per Xeno Executor
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Blox Fruits Auto Farm v3.0", "DarkTheme")

-- Tab principale
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Auto Farm Settings")

MainSection:NewToggle("Auto Quest", "Accetta quest automaticamente", function(state)
    Config.AutoQuest = state
    Notifica("Auto Quest: " .. (state and "ON" or "OFF"))
end)

MainSection:NewToggle("Auto Farm", "Farm automatico NPC", function(state)
    Config.AutoFarm = state
    if state then
        AvviaFarm()
    else
        FermaFarm()
    end
end)

MainSection:NewToggle("Auto Riprendi Quest", "Riprende quest dopo completamento", function(state)
    Config.AutoRiprendiQuest = state
end)

MainSection:NewToggle("Anti-AFK", "Previeni kick AFK", function(state)
    Config.AntiAfk = state
end)

-- Tab Stats
local StatsTab = Window:NewTab("Stats")
local StatsSection = StatsTab:NewSection("Farm Statistics")

StatsSection:NewLabel("Quest Completate: 0")
StatsSection:NewLabel("Tempo di Farm: 00:00:00")
StatsSection:NewLabel("Livello Attuale: " .. GetLivelloGiocatore())

-- Tab Teleport
local TeleportTab = Window:NewTab("Teleport")
local TeleportSection = TeleportTab:NewSection("NPC Locations")

for nomeNpc, dati in pairs(NpcDatabase) do
    TeleportSection:NewButton(nomeNpc .. " (Lv. " .. dati.LivelloMin .. "-" .. dati.LivelloMax .. ")", 
        "Teleport a " .. nomeNpc, function()
            Teleporta(dati.Posizione)
            Notifica("Teleport a " .. nomeNpc)
    end)
end

-- Tab Config
local ConfigTab = Window:NewTab("Config")
local ConfigSection = ConfigTab:NewSection("Configuration")

ConfigSection:NewSlider("Distanza Attack", "Distanza dagli NPC", 50, 5, function(value)
    Config.Distance = value
end)

ConfigSection:NewSlider("Attesa Uccisione", "Secondi tra gli attacchi", 10, 1, function(value)
    Config.AttesaUccisione = value
end)

ConfigSection:NewButton("Salva Config", "Salva configurazione", function()
    writefile("BloxFruitsConfig.txt", game:GetService("HttpService"):JSONEncode(Config))
    Notifica("Config salvata!")
end)

ConfigSection:NewButton("Carica Config", "Carica configurazione", function()
    if isfile("BloxFruitsConfig.txt") then
        Config = game:GetService("HttpService"):JSONDecode(readfile("BloxFruitsConfig.txt"))
        Notifica("Config caricata!")
    end
end)

-- Avvio automatico
Notifica("Blox Fruits Auto Farm v3.0 caricato!")
Notifica("Livello: " .. GetLivelloGiocatore())

-- Aggiorna stats in tempo reale
spawn(function()
    while true do
        wait(5)
        -- Aggiorna label stats
        pcall(function()
            -- Qui aggiungeresti l'aggiornamento delle UI
        end)
    end
end)

-- Attendi caricamento character
Player.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    wait(2)
    
    if Config.AutoFarm then
        AvviaFarm()
    end
end)

-- Inizia farm se config attivo
wait(3)
if Config.AutoFarm then
    AvviaFarm()
end
