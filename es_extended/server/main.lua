SetMapName(Config.Base.SetMapName)
SetGameType(Config.Base.SetGameType)

local oneSyncState = GetConvar("onesync", "off")
local newPlayer = "INSERT INTO `users` SET `accounts` = ?, `identifier` = ?, `group` = ?"
local loadPlayer = "SELECT `accounts`, `job`, `job_grade`, `group`, `position`, `inventory`, `skin`, `loadout`, `metadata`, `phone_number`"

if Config.StartingInventoryItems then
    newPlayer = newPlayer .. ", `inventory` = ?"
end

loadPlayer = loadPlayer .. " FROM `users` WHERE identifier = ?"

local function createESXPlayer(identifier, playerId, data)
    local accounts = {}

    for account, money in pairs(Config.StartingAccountMoney) do
        accounts[account] = money
    end

    local defaultGroup = "user"
    if Config.Base.AutoAdmin then
        if Core.IsPlayerAdmin(playerId) then
            print(("[^2INFO^0] Player ^5%s^0 Has been granted admin permissions via ^5Ace Perms^7."):format(playerId))
            defaultGroup = "admin"
        end
    end

    local parameters = { json.encode(accounts), identifier, defaultGroup }

    if Config.StartingInventoryItems then
        table.insert(parameters, json.encode(Config.StartingInventoryItems))
    end

    MySQL.prepare(newPlayer, parameters, function()
        loadESXPlayer(identifier, playerId, true)
    end)
end


local function onPlayerJoined(playerId)
    local identifier = ESX.GetIdentifier(playerId)
    if not identifier then
        return DropPlayer(playerId, 'มีข้อผิดพลาดในการเข้าเล่นโปรดเช็ค Steam / Discord / Rockstar License ')
    end

    if ESX.GetPlayerFromIdentifier(identifier) then
        DropPlayer(playerId, 'มีข้อผิดพลาดในการโหลดตัวละครของคุณ ')
    else
        local result = MySQL.scalar.await("SELECT 1 FROM users WHERE identifier = ?", { identifier })
        if result then
            loadESXPlayer(identifier, playerId, false)
        else
            createESXPlayer(identifier, playerId)
        end
    end
end

RegisterNetEvent("esx:onPlayerJoined", function()
    local _source = source
    while not next(ESX.Jobs) do
        Wait(50)
    end
    
    if not ESX.Players[_source] then
        onPlayerJoined(_source)
    end
end)

AddEventHandler("playerConnecting", function(_, _, deferrals)
    local playerId = source
    deferrals.defer()
    Wait(0) -- Required
    local identifier = ESX.GetIdentifier(playerId)
    
    -- luacheck: ignore
    if not SetEntityOrphanMode then
        return deferrals.done(("[ESX] ESX Requires a minimum Artifact version of 10188, Please update your server."))
    end
    
    if oneSyncState == "off" or oneSyncState == "legacy" then
        return deferrals.done(("[ESX] ESX Requires Onesync Infinity to work. This server currently has Onesync set to: %s"):format(oneSyncState))
    end
    
    if not Core.DatabaseConnected then
        return deferrals.done("[ESX] OxMySQL Was Unable To Connect to your database. Please make sure it is turned on and correctly configured in your server.cfg")
    end
    
    if identifier then
        if ESX.GetPlayerFromIdentifier(identifier) then
            return deferrals.done('มีข้อผิดพลาดในการโหลดตัวละครของคุณ ')
        else
            return deferrals.done()
        end
    else
        return deferrals.done('มีข้อผิดพลาดในการเข้าเล่นโปรดเช็ค Steam / Discord / Rockstar License ')
    end
end)

function loadESXPlayer(identifier, playerId, isNew)
    local userData = {
        accounts = {},
        inventory = {},
        loadout = {},
        weight = 0,
        name = GetPlayerName(playerId),
        identifier = identifier,
        firstName = "John",
        lastName = "Doe",
        dateofbirth = "01/01/2000",
        height = 120,
        dead = false,
    }

    local result = MySQL.prepare.await(loadPlayer, { identifier })

    -- Accounts
    local accounts = result.accounts
    accounts = (accounts and accounts ~= "") and json.decode(accounts) or {}

    for account, data in pairs(Config.Accounts) do
        data.round = data.round or data.round == nil

        local index = #userData.accounts + 1
        userData.accounts[index] = {
            name = account,
            money = accounts[account] or Config.StartingAccountMoney[account] or 0,
            label = data.label,
            round = data.round,
            index = index,
        }
    end

    -- Job
    local job, grade = result.job, tostring(result.job_grade)

    if not ESX.DoesJobExist(job, grade) then
        print(("[^3WARNING^7] Ignoring invalid job for ^5%s^7 [job: ^5%s^7, grade: ^5%s^7]"):format(identifier, job, grade))
        job, grade = "unemployed", "0"
    end

    local jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]

    userData.job = {
        id = jobObject.id,
        name = jobObject.name,
        label = jobObject.label,

        grade = tonumber(grade),
        grade_name = gradeObject.name,
        grade_label = gradeObject.label,
        grade_salary = gradeObject.salary,

        skin_male = gradeObject.skin_male and json.decode(gradeObject.skin_male) or {},
        skin_female = gradeObject.skin_female and json.decode(gradeObject.skin_female) or {},
    }

    -- Inventory
    local inventory = (result.inventory and result.inventory ~= "") and json.decode(result.inventory) or {}

    -- Ensure userData.inventory exists
    userData.inventory = userData.inventory or {}

    -- Initialize weight if needed
    userData.weight = userData.weight or 0

    for name, item in pairs(ESX.Items) do
        local count = inventory[name] or 0
        local inventoryItem = {
            name = name,
            count = count,
            label = item.label,
            usable = Core.UsableItemsCallbacks[name] ~= nil,
            rare = item.rare,
            canRemove = item.canRemove
        }

        if Config.Base.BaseType == 'LIMIT' then
            inventoryItem.limit = item.limit or 0
        elseif Config.Base.BaseType == 'WEIGHT' then
            userData.weight = userData.weight + (count * (item.weight or 0))
            inventoryItem.weight = item.weight or 0
        elseif Config.Base.BaseType == '2Type' then
            userData.weight = userData.weight + (count * (item.weight or 0))
            inventoryItem.limit = item.limit or 0
            inventoryItem.weight = item.weight or 0
        end

        table.insert(userData.inventory, inventoryItem)
    end

    -- Sort inventory by label
    table.sort(userData.inventory, function(a, b)
        return a.label < b.label
    end)

        --local inventory = (result.inventory and result.inventory ~= "") and json.decode(result.inventory) or {}
--
        --for name, item in pairs(ESX.Items) do
        --    local count = inventory[name] or 0
        --    userData.weight += (count * item.weight)
--
        --    userData.inventory[#userData.inventory + 1] = {
        --        name = name,
        --        count = count,
        --        label = item.label,
        --        weight = item.weight,
        --        usable = Core.UsableItemsCallbacks[name] ~= nil,
        --        rare = item.rare,
        --        canRemove = item.canRemove,
        --    }
        --end
        --table.sort(userData.inventory, function(a, b)
        --    return a.label < b.label
        --end)

    -- Group
    if result.group then
        if result.group == "superadmin" then
            userData.group = "admin"
            print("[^3WARNING^7] ^5Superadmin^7 detected, setting group to ^5admin^7")
        else
            userData.group = result.group
        end
    else
        userData.group = "user"
    end

    -- Loadout
        if result.loadout and result.loadout ~= "" then

            local loadout = json.decode(result.loadout)
            for name, weapon in pairs(loadout) do
                local label = ESX.GetWeaponLabel(name)

                if label then
                    userData.loadout[#userData.loadout + 1] = {
                        name = name,
                        ammo = weapon.ammo,
                        label = label,
                        components = weapon.components or {},
                        tintIndex = weapon.tintIndex or 0,
                    }
                end
            end
        end

    -- Position
    userData.coords = json.decode(result.position) or Config.DefaultSpawns[ESX.Math.Random(1,#Config.DefaultSpawns)]

    -- Skin
    userData.skin = (result.skin and result.skin ~= "") and json.decode(result.skin) or { sex = userData.sex == "f" and 1 or 0 }

    -- Metadata
    userData.metadata = (result.metadata and result.metadata ~= "") and json.decode(result.metadata) or {}

    -- xPlayer Creation
    local xPlayer = CreateExtendedPlayer(playerId, identifier, userData.group, userData.accounts, userData.inventory, userData.weight, userData.job, userData.loadout, GetPlayerName(playerId), userData.coords, userData.metadata)

    GlobalState["playerCount"] = GlobalState["playerCount"] + 1
    ESX.Players[playerId] = xPlayer
    Core.playersByIdentifier[identifier] = xPlayer

    -- Identity
    if result.firstname and result.firstname ~= "" then
        userData.firstName = result.firstname
        userData.lastName = result.lastname

        local name = ("%s %s"):format(result.firstname, result.lastname)
        userData.name = name

        xPlayer.set("firstName", result.firstname)
        xPlayer.set("lastName", result.lastname)
        xPlayer.setName(name)

        if result.dateofbirth then
            userData.dateofbirth = result.dateofbirth
            xPlayer.set("dateofbirth", result.dateofbirth)
        end
        if result.sex then
            userData.sex = result.sex
            xPlayer.set("sex", result.sex)
        end
        if result.height then
            userData.height = result.height
            xPlayer.set("height", result.height)
        end
    end

    -- phone
	if result.phone_number ~= '' then
        userData.phone = result.phone_number
    end

    TriggerEvent("esx:playerLoaded", playerId, xPlayer, isNew)
    userData.money = xPlayer.getMoney()
    userData.maxWeight = xPlayer.getMaxWeight()
    xPlayer.triggerEvent("esx:playerLoaded", userData, isNew, userData.skin)

    xPlayer.triggerEvent("esx:registerSuggestions", Core.RegisteredCommands)
    print(('[^2INFO^0] Player ^5"%s"^0 has connected to the server. ID: ^5%s^7'):format(xPlayer.getName(), playerId))
end

AddEventHandler("chatMessage", function(playerId, _, message)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer and message:sub(1, 1) == "/" and playerId > 0 then
        CancelEvent()
        local commandName = message:sub(1):gmatch("%w+")()
        xPlayer.showNotification(TranslateCap("commanderror_invalidcommand", commandName))
    end
end)

AddEventHandler("playerDropped", function(reason)
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)

    if xPlayer then
        TriggerEvent("esx:playerDropped", playerId, reason)
        local job = xPlayer.getJob().name
        local currentJob = Core.JobsPlayerCount[job]
        Core.JobsPlayerCount[job] = ((currentJob and currentJob > 0) and currentJob or 1) - 1

        GlobalState[("%s:count"):format(job)] = Core.JobsPlayerCount[job]
        Core.playersByIdentifier[xPlayer.identifier] = nil

        Core.SavePlayer(xPlayer, function()
            GlobalState["playerCount"] = GlobalState["playerCount"] - 1
            ESX.Players[playerId] = nil
        end)
    end
end)

AddEventHandler("esx:playerLoaded", function(_, xPlayer)
    local job = xPlayer.getJob().name
    local jobKey = ("%s:count"):format(job)

    Core.JobsPlayerCount[job] = (Core.JobsPlayerCount[job] or 0) + 1
    GlobalState[jobKey] = Core.JobsPlayerCount[job]
end)

AddEventHandler("esx:setJob", function(_, job, lastJob)
    local lastJobKey = ("%s:count"):format(lastJob.name)
    local jobKey = ("%s:count"):format(job.name)
    local currentLastJob = Core.JobsPlayerCount[lastJob.name]

    Core.JobsPlayerCount[lastJob.name] = ((currentLastJob and currentLastJob > 0) and currentLastJob or 1) - 1
    Core.JobsPlayerCount[job.name] = (Core.JobsPlayerCount[job.name] or 0) + 1

    GlobalState[lastJobKey] = Core.JobsPlayerCount[lastJob.name]
    GlobalState[jobKey] = Core.JobsPlayerCount[job.name]
end)

AddEventHandler("esx:playerLogout", function(playerId, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer then
        TriggerEvent("esx:playerDropped", playerId)

        Core.playersByIdentifier[xPlayer.identifier] = nil
        Core.SavePlayer(xPlayer, function()
            GlobalState["playerCount"] = GlobalState["playerCount"] - 1
            ESX.Players[playerId] = nil
            if cb then
                cb()
            end
        end)
    end
    TriggerClientEvent("esx:onPlayerLogout", playerId)
end)

    RegisterNetEvent("esx:updateWeaponAmmo", function(weaponName, ammoCount)
        local xPlayer = ESX.GetPlayerFromId(source)

        if xPlayer then
            xPlayer.updateWeaponAmmo(weaponName, ammoCount)
        end
    end)

    RegisterNetEvent("esx:giveInventoryItem", function(target, itemType, itemName, itemCount)
        local playerId = source
        local sourceXPlayer = ESX.GetPlayerFromId(playerId)
        local targetXPlayer = ESX.GetPlayerFromId(target)
        local distance = #(GetEntityCoords(GetPlayerPed(playerId)) - GetEntityCoords(GetPlayerPed(target)))
        if not sourceXPlayer or not targetXPlayer or distance > Config.DistanceGive then
            print(("[^3WARNING^7] Player Detected Cheating: ^5%s^7"):format(GetPlayerName(playerId)))
            return
        end

        if itemType == "item_standard" then
            local sourceItem = sourceXPlayer.getInventoryItem(itemName)
            local targetItem = targetXPlayer.getInventoryItem(itemName)
    
            if Config.FunctionGiveItem then
                if targetItem.limit ~= -1 and (targetItem.count + itemCount) > targetItem.limit then
                    sourceXPlayer.showNotification(TranslateCap("ex_inv_lim", targetXPlayer.name))
                else
                    sourceXPlayer.removeInventoryItem(itemName, itemCount)
                    targetXPlayer.addInventoryItem(itemName, itemCount)
                    
                    sourceXPlayer.showNotification(TranslateCap("gave_item", itemCount, sourceItem.label, targetXPlayer.name))
                    targetXPlayer.showNotification(TranslateCap("received_item", itemCount, sourceItem.label, sourceXPlayer.name))
                end
            else
                if itemCount < 1 or sourceItem.count < itemCount then
                    return sourceXPlayer.showNotification(TranslateCap("imp_invalid_quantity"))
                end
                
                if not targetXPlayer.canCarryItem(itemName, itemCount) then
                    return sourceXPlayer.showNotification(TranslateCap("ex_inv_lim", targetXPlayer.name))
                end
                
                sourceXPlayer.removeInventoryItem(itemName, itemCount)
                targetXPlayer.addInventoryItem(itemName, itemCount)
                
                sourceXPlayer.showNotification(TranslateCap("gave_item", itemCount, sourceItem.label, targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_item", itemCount, sourceItem.label, sourceXPlayer.name))
            end
        elseif itemType == "item_account" then
            if itemCount < 1 or sourceXPlayer.getAccount(itemName).money < itemCount then
                return sourceXPlayer.showNotification(TranslateCap("imp_invalid_amount"))
            end

            sourceXPlayer.removeAccountMoney(itemName, itemCount, "Gave to " .. targetXPlayer.name)
            targetXPlayer.addAccountMoney(itemName, itemCount, "Received from " .. sourceXPlayer.name)

            sourceXPlayer.showNotification(TranslateCap("gave_account_money", ESX.Math.GroupDigits(itemCount), Config.Accounts[itemName].label, targetXPlayer.name))
            targetXPlayer.showNotification(TranslateCap("received_account_money", ESX.Math.GroupDigits(itemCount), Config.Accounts[itemName].label, sourceXPlayer.name))
        elseif itemType == "item_weapon" then
            if not sourceXPlayer.hasWeapon(itemName) then
                return
            end

            local weaponLabel = ESX.GetWeaponLabel(itemName)
            if targetXPlayer.hasWeapon(itemName) then
                sourceXPlayer.showNotification(TranslateCap("gave_weapon_hasalready", targetXPlayer.name, weaponLabel))
                targetXPlayer.showNotification(TranslateCap("received_weapon_hasalready", sourceXPlayer.name, weaponLabel))
                return
            end

            local _, weapon = sourceXPlayer.getWeapon(itemName)
            local _, weaponObject = ESX.GetWeapon(itemName)
            itemCount = weapon.ammo
            local weaponComponents = ESX.Table.Clone(weapon.components)
            local weaponTint = weapon.tintIndex

            if weaponTint then
                targetXPlayer.setWeaponTint(itemName, weaponTint)
            end

            if weaponComponents then
                for _, v in pairs(weaponComponents) do
                    targetXPlayer.addWeaponComponent(itemName, v)
                end
            end

            sourceXPlayer.removeWeapon(itemName)
            targetXPlayer.addWeapon(itemName, itemCount)

            if weaponObject.ammo and itemCount > 0 then
                local ammoLabel = weaponObject.ammo.label
                sourceXPlayer.showNotification(TranslateCap("gave_weapon_withammo", weaponLabel, itemCount, ammoLabel, targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_weapon_withammo", weaponLabel, itemCount, ammoLabel, sourceXPlayer.name))
            else
                sourceXPlayer.showNotification(TranslateCap("gave_weapon", weaponLabel, targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_weapon", weaponLabel, sourceXPlayer.name))
            end
        elseif itemType == "item_ammo" then
            if not sourceXPlayer.hasWeapon(itemName) then
                return
            end

            local _, weapon = sourceXPlayer.getWeapon(itemName)

            if not targetXPlayer.hasWeapon(itemName) then
                sourceXPlayer.showNotification(TranslateCap("gave_weapon_noweapon", targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_weapon_noweapon", sourceXPlayer.name, weapon.label))
                return
            end

            local _, weaponObject = ESX.GetWeapon(itemName)

            if not weaponObject.ammo then return end

            local ammoLabel = weaponObject.ammo.label
            if weapon.ammo >= itemCount then
                sourceXPlayer.removeWeaponAmmo(itemName, itemCount)
                targetXPlayer.addWeaponAmmo(itemName, itemCount)

                sourceXPlayer.showNotification(TranslateCap("gave_weapon_ammo", itemCount, ammoLabel, weapon.label, targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_weapon_ammo", itemCount, ammoLabel, weapon.label, sourceXPlayer.name))
            end
        end
    end)

    RegisterNetEvent("esx:removeInventoryItem", function(itemType, itemName, itemCount)
        local playerId = source
        local xPlayer = ESX.GetPlayerFromId(playerId)

        if itemType == "item_standard" then
            if not itemCount or itemCount < 1 then
                return xPlayer.showNotification(TranslateCap("imp_invalid_quantity"))
            end

            local xItem = xPlayer.getInventoryItem(itemName)

            if itemCount > xItem.count or xItem.count < 1 then
                return xPlayer.showNotification(TranslateCap("imp_invalid_quantity"))
            end

            xPlayer.removeInventoryItem(itemName, itemCount)
            xPlayer.showNotification(TranslateCap("threw_standard", itemCount, xItem.label))
        elseif itemType == "item_account" then
            if itemCount == nil or itemCount < 1 then
                return xPlayer.showNotification(TranslateCap("imp_invalid_amount"))
            end

            local account = xPlayer.getAccount(itemName)

            if itemCount > account.money or account.money < 1 then
                return xPlayer.showNotification(TranslateCap("imp_invalid_amount"))
            end

            xPlayer.removeAccountMoney(itemName, itemCount, "Threw away")
            xPlayer.showNotification(TranslateCap("threw_account", ESX.Math.GroupDigits(itemCount), string.lower(account.label)))
        elseif itemType == "item_weapon" then
            itemName = string.upper(itemName)

            if not xPlayer.hasWeapon(itemName) then return end

            local _, weapon = xPlayer.getWeapon(itemName)
            local _, weaponObject = ESX.GetWeapon(itemName)
            -- luacheck: ignore weaponPickupLabel
            --local weaponPickupLabel = ""
            local components = ESX.Table.Clone(weapon.components)
            xPlayer.removeWeapon(itemName)

            if weaponObject.ammo and weapon.ammo > 0 then
                --local ammoLabel = weaponObject.ammo.label
                --weaponPickupLabel = ("%s [%s %s]"):format(weapon.label, weapon.ammo, ammoLabel)
                xPlayer.showNotification(TranslateCap("threw_weapon_ammo", weapon.label, weapon.ammo, ammoLabel))
            else
                --weaponPickupLabel = ("%s"):format(weapon.label)
                xPlayer.showNotification(TranslateCap("threw_weapon", weapon.label))
            end

           -- ESX.CreatePickup("item_weapon", itemName, weapon.ammo, weaponPickupLabel, playerId, components, weapon.tintIndex)
        end
    end)

    RegisterNetEvent("esx:useItem", function(itemName)
        local source = source
        local xPlayer = ESX.GetPlayerFromId(source)
        local count = xPlayer.getInventoryItem(itemName).count

        if count < 1 then
            return xPlayer.showNotification(TranslateCap("act_imp"))
        end

        ESX.UseItem(source, itemName)
    end)

ESX.RegisterServerCallback("esx:getPlayerData", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    cb({
        identifier = xPlayer.identifier,
        accounts = xPlayer.getAccounts(),
        inventory = xPlayer.getInventory(),
        job = xPlayer.getJob(),
        loadout = xPlayer.getLoadout(),
        money = xPlayer.getMoney(),
        position = xPlayer.getCoords(true),
        metadata = xPlayer.getMeta(),
    })
end)

ESX.RegisterServerCallback("esx:isUserAdmin", function(source, cb)
    cb(Core.IsPlayerAdmin(source))
end)

ESX.RegisterServerCallback("esx:getGameBuild", function(_, cb)
    cb(tonumber(GetConvar("sv_enforceGameBuild", "1604")))
end)

ESX.RegisterServerCallback("esx:getOtherPlayerData", function(_, cb, target)
    local xPlayer = ESX.GetPlayerFromId(target)

    cb({
        identifier = xPlayer.identifier,
        accounts = xPlayer.getAccounts(),
        inventory = xPlayer.getInventory(),
        job = xPlayer.getJob(),
        loadout = xPlayer.getLoadout(),
        money = xPlayer.getMoney(),
        position = xPlayer.getCoords(true),
        metadata = xPlayer.getMeta(),
    })
end)

ESX.RegisterServerCallback("esx:getPlayerNames", function(source, cb, players)
    players[source] = nil

    for playerId, _ in pairs(players) do
        local xPlayer = ESX.GetPlayerFromId(playerId)

        if xPlayer then
            players[playerId] = xPlayer.getName()
        else
            players[playerId] = nil
        end
    end

    cb(players)
end)

ESX.RegisterServerCallback("esx:spawnVehicle", function(source, cb, vehData)
    local ped = GetPlayerPed(source)
    ESX.OneSync.SpawnVehicle(vehData.model or `ADDER`, vehData.coords or GetEntityCoords(ped), vehData.coords.w or 0.0, vehData.props or {}, function(id)
        if vehData.warp then
            local vehicle = NetworkGetEntityFromNetworkId(id)
            local timeout = 0
            while GetVehiclePedIsIn(ped, false) ~= vehicle and timeout <= 15 do
                Wait(0)
                TaskWarpPedIntoVehicle(ped, vehicle, -1)
                timeout += 1
            end
        end
        cb(id)
    end)
end)

AddEventHandler("txAdmin:events:scheduledRestart", function(eventData)
    if eventData.secondsRemaining == 60 then
        CreateThread(function()
            Wait(50000)
            Core.SavePlayers()
        end)
    end
end)

AddEventHandler("txAdmin:events:serverShuttingDown", function()
    Core.SavePlayers()
end)

local DoNotUse = {
    ["essentialmode"] = true,
    ["es_admin2"] = true,
    ["basic-gamemode"] = true,
    ["mapmanager"] = true,
    ["fivem-map-skater"] = true,
    ["fivem-map-hipster"] = true,
    ["qb-core"] = true,
    ["default_spawnpoint"] = true,
}

AddEventHandler("onResourceStart", function(key)
    if DoNotUse[string.lower(key)] then
        while GetResourceState(key) ~= "started" do
            Wait(0)
        end

        StopResource(key)
        error(("WE STOPPED A RESOURCE THAT WILL BREAK ^1ESX^1, PLEASE REMOVE ^5%s^1"):format(key))
    end
    -- luacheck: ignore
    if not SetEntityOrphanMode then
        CreateThread(function()
            while true do
                error("ESX Requires a minimum Artifact version of 10188, Please update your server.")
                Wait(60 * 1000)
            end
        end)
    end
end)

for key in pairs(DoNotUse) do
    if GetResourceState(key) == "started" or GetResourceState(key) == "starting" then
        StopResource(key)
        error(("WE STOPPED A RESOURCE THAT WILL BREAK ^1ESX^1, PLEASE REMOVE ^5%s^1"):format(key))
    end
end
