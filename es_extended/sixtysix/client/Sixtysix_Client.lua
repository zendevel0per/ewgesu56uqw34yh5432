if Config["ClearMemoryClient"]['ClearMemory'] then
  Citizen.SetTimeout(Config["ClearMemoryClient"]['ClearMemoryTime'] * 60000, function()
    ClientMemory()
  end)
end

function ClientMemory()
  print('ClientMemoryAuto+')
  TriggerEvent("HaxHexCore:ClientMemoryGarbage")
  Citizen.SetTimeout(Config["ClearMemoryClient"]['ClearMemoryTime'] * 60000, ClientMemory)
end

AddEventHandler("HaxHexCore:ClientMemoryGarbage", function()
  collectgarbage()
end)

Citizen.CreateThread(function()
  local resource_name = GetCurrentResourceName()
  local dropt_text = Config["DROPTEXT"]
  while true do
    Citizen.Wait(5000) -- เพิ่มเวลาระหว่างการตรวจสอบ
    for k, v in pairs(Config["CONVARNUM"]) do
      local convar = tonumber(GetConvarInt(k, v["Default"]))
      if convar < v["Min"] then
        TriggerServerEvent(resource_name .. 'drop', string.format("%s %s %d", dropt_text, k, convar))
      end
    end
  end
end)
