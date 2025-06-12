Config = {}

Config.Accounts = {
    bank = {
        label = TranslateCap("account_bank"),
        round = true,
    },
    black_money = {
        label = TranslateCap("account_black_money"),
        round = true,
    },
    money = {
        label = TranslateCap("account_money"),
        round = true,
    },
}

Config.Base = {
    BaseType = 'LIMIT', -- LIMIT, WEIGHT, 2Type
	SetGameType	= 'BASEFEWTHZ Powered By Fewthz' ,
	SetMapName	= 'DISCORD : https://discord.gg/7Hn4WCf' ,
	NCinventory = false ,	-- ใช้กระเป๋า Nc Developer ให้ปรับเป็น true / ใช้กระเป๋า Fewthz_inventory และอื่นๆ ให้ปรับเป็น false
	AutoAdmin = true ,	-- ให้ยศแอดมินออโต้ ตาม Steam Hex หน้า Server.cfg
	HealthArmor = true , -- Save เลือด เกาะ
}

Config.FunctionGiveItem = true -- true = Check limit / false = Check weight

Config.CommandConvert = '+CONVERTTOJSON' -- คำสั่งโหลด SQL เดิม 

Config.SQLJSON = 'JSON' -- 'JSON' ฐานข้อมูล items จาก JSON / 'SQL' ฐานข้อมูล items จาก SQL

Config.Open_getSharedObject = true  -- true = เปิดใช้งาน esx:getSharedObject false ปิดใช้งาน esx:getSharedObject

Config.StartingAccountMoney = { money = 10000, black_money = 0, bank = 0 }

--Config.StartingInventoryItems = false -- ของเริ่มต้นผู้เล่นใหม่
Config.StartingInventoryItems = { -- table/false | -- ของเริ่มต้นผู้เล่นใหม่
	phone = 1,
	gacha_01 = 20,
    boxnewble = 1,
	Boxcar1 = 1,
	BoxcardX2 = 1,
}

Config.DefaultSpawns = { -- หากต้องการมีตำแหน่งเกิดหลายจุดและเลือกแบบสุ่ม ให้ยกเลิกการคอมเมนต์หรือเพิ่มตำแหน่งใหม่
    { x = 1315.6500244140625,  y = 8204.8701171875, z = 549.3599853515625, heading = 1.0 },
    --{x = 224.9865, y = -865.0871, z = 30.2922, heading = 1.0},
    --{x = 227.8436, y = -866.0400, z = 30.2922, heading = 1.0},
    --{x = 230.6051, y = -867.1450, z = 30.2922, heading = 1.0},
    --{x = 233.5459, y = -868.2626, z = 30.2922, heading = 1.0}
}

Config.AdminGroups = {
    ["owner"] = true,
    ["admin"] = true,
}

Config.CustomNotificationEnabled = true -- Custom ESX.ShowNotification
Config.CustomNotification = function(message, notifyType, length)
    TriggerEvent("mythic_notify:client:SendAlert",{ 
        text = message,
        type = "success",
        timeout = 5000,
    })
end

Config.LicenseType = "steam" -- steam, license, discord, xbl, liveid, ip
Config.EnablePaycheck = true -- เปิดระบบเงินเดือน (Paycheck)
Config.LogPaycheck = false -- บันทึกการจ่ายเงินเดือนไปยังช่อง Discord ที่กำหนดผ่าน Webhook (ค่าเริ่มต้นคือปิด)
Config.EnableSocietyPayouts = false -- จ่ายเงินจากบัญชีสังคม (Society) ที่ผู้เล่นทำงานอยู่หรือไม่? (ต้องการ: esx_society)
Config.MaxWeight = 100 -- น้ำหนักสูงสุดของช่องเก็บของโดยไม่มีกระเป๋าเพิ่ม
Config.PaycheckInterval = 7 * 60000 -- ระยะเวลาในการรับเงินเดือนแต่ละครั้ง (หน่วย: มิลลิวินาที)
Config.SaveDeathStatus = true -- Save the death status of a player
Config.EnableDebug = false -- ใช้ตัวเลือก Debug หรือไม่?

Config.DistanceGive = 4.0 -- Max distance when giving items, weapons etc.

Config.AdminLogging = false -- Logs the usage of certain commands by those with group.admin ace permissions (default is false)

local txAdminLocale = GetConvar("txAdmin-locale", "en")
local esxLocale = GetConvar("esx:locale", "invalid")

Config.Locale = (esxLocale ~= "invalid") and esxLocale or (txAdminLocale ~= "custom" and txAdminLocale) or "en"
