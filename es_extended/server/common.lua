ESX.Players = {}
ESX.Jobs = {}
ESX.Items = {}
Core = {}
Core.JobsPlayerCount = {}
Core.UsableItemsCallbacks = {}
Core.RegisteredCommands = {}
Core.PlayerFunctionOverrides = {}
Core.DatabaseConnected = false
Core.playersByIdentifier = {}

Core.vehicleTypesByModel = {}

RegisterNetEvent("esx:onPlayerSpawn", function()
    ESX.Players[source].spawned = true
end)

local function StartDBSync()
    CreateThread(function()
        local interval <const> = 10 * 60 * 1000
        while true do
            Wait(interval)
            Core.SavePlayers()
        end
    end)
end

function CONVERTTOJSON()
    -- รอเวลา และทำการบันทึกไฟล์ JSON ในรูปแบบที่จัดเรียงแล้ว
    Wait(1000)
    local items = MySQL.query.await("SELECT * FROM items")
    SaveResourceFile(GetCurrentResourceName(), "./shared/ITEMS.json", json.encode(items), -1)
    print('^2[CONVERTTOJSON]^7 ITEMS.json ^2created successfully.')

    Wait(1000)
    local jobs = MySQL.query.await("SELECT * FROM jobs")
    SaveResourceFile(GetCurrentResourceName(), "./shared/JOBS.json", json.encode(jobs), -1)
    print('^2[CONVERTTOJSON]^7 JOBS.json ^2created successfully.')

    Wait(1000)
    local job_grades = MySQL.query.await("SELECT * FROM job_grades")
    SaveResourceFile(GetCurrentResourceName(), "./shared/JOBSGRADES.json", json.encode(job_grades), -1)
    print('^2[CONVERTTOJSON]^7 JOBSGRADES.json ^2created successfully.')

    -- ข้อความแสดงผลสำเร็จทั้งหมดด้วยรหัสสี
    print('^2[CONVERTTOJSON]^7 ^5All JSON files have been created successfully! ^5<3 <3 <3^7')
end

if Config.SQLJSON == 'JSON' then
    Citizen.CreateThread(function()
        if not Fewthzbase then
            Core.DatabaseConnected = true
            local ItemsJS = LoadResourceFile("es_extended", "./shared/ITEMS.json")
            local items = json.decode(ItemsJS)
            --local items = Item -- Config LUA
            if Config.Base.BaseType == 'LIMIT' then
                for _, v in ipairs(items) do
                    ESX.Items[v.name] = { label = v.label, limit = v.limit, rare = v.rare, canRemove = v.can_remove }
                end
            elseif Config.Base.BaseType == 'WEIGHT' then
                for _, v in ipairs(items) do
                    ESX.Items[v.name] = { label = v.label, weight = v.weight, rare = v.rare, canRemove = v.can_remove }
                end
            elseif Config.Base.BaseType == '2Type' then
                for _, v in ipairs(items) do
                    ESX.Items[v.name] = { label = v.label, limit = v.limit, weight = v.weight, rare = v.rare, canRemove = v.can_remove }
                end
            end
        
            Fewthzbase = true
            ESX.RefreshJobs()
        
            print(('[^2FEWTHZ BASE^7] ^5Legacy %s ^2Activate'):format(GetResourceMetadata(GetCurrentResourceName(), "version", 0)))
            
            StartDBSync()
            if Config.EnablePaycheck then
                StartPayCheck()
            end
        end
    end)

elseif Config.SQLJSON == 'SQL' then

    MySQL.ready(function()
        Core.DatabaseConnected = true
        
        local items = MySQL.query.await("SELECT * FROM items")
        if Config.Base.BaseType == 'LIMIT' then
            for _, v in ipairs(items) do
                ESX.Items[v.name] = { label = v.label, limit = v.limit, rare = v.rare, canRemove = v.can_remove }
            end
        elseif Config.Base.BaseType == 'WEIGHT' then
            for _, v in ipairs(items) do
                ESX.Items[v.name] = { label = v.label, weight = v.weight, rare = v.rare, canRemove = v.can_remove }
            end
        elseif Config.Base.BaseType == '2Type' then
            for _, v in ipairs(items) do
                ESX.Items[v.name] = { label = v.label, limit = v.limit, weight = v.weight, rare = v.rare, canRemove = v.can_remove }
            end
        end
        
        ESX.RefreshJobs()
    
        print(('[^2FEWTHZ BASE^7] ^5Legacy %s ^2Activate'):format(GetResourceMetadata(GetCurrentResourceName(), "version", 0)))
        
        StartDBSync()
        if Config.EnablePaycheck then
            StartPayCheck()
        end
    end)
end

RegisterNetEvent("esx:clientLog", function(msg)
    if Config.EnableDebug then
        print(("[^2TRACE^7] %s^7"):format(msg))
    end
end)

RegisterNetEvent("esx:ReturnVehicleType", function(Type, Request)
    if Core.ClientCallbacks[Request] then
        Core.ClientCallbacks[Request](Type)
        Core.ClientCallbacks[Request] = nil
    end
end)

GlobalState.playerCount = 0
