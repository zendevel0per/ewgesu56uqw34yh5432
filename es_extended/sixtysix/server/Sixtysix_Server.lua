if Config["ClearMemoryServer"]['ClearMemory'] then
  Citizen.SetTimeout(Config["ClearMemoryServer"]['ClearMemoryTime'] * 60000, function()
    ClearMemory()
  end)
end

function ClearMemory()
  print('[SixtysixServer] Running garbage collection...')
  collectgarbage()
  Citizen.SetTimeout(Config["ClearMemoryServer"]['ClearMemoryTime'] * 60000, ClearMemory)
end

RegisterNetEvent(GetCurrentResourceName() .. 'drop')
AddEventHandler(GetCurrentResourceName() .. 'drop', function(text)
  local playerSource = source
  if playerSource and text then
    print(string.format('[SixtysixServer] Dropping player %d: %s', playerSource, text))
    DropPlayer(playerSource, text)
  else
    print('[SixtysixServer] Failed to drop player. Invalid source or text.')
  end
end)
