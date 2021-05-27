ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('esx_fbi_computer:getUserByPhoneNumber', function(source, cb, phone_number)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    MySQL.Async.fetchAll('SELECT * FROM users WHERE phone_number=@phone_number', {
        ['@phone_number'] = phone_number
    }, function(results)
        if not results then
            cb(nil)
        else
            cb(results[1])
        end
    end)
end)

ESX.RegisterServerCallback('esx_fbi_computer:getFractionInfo', function(source, cb, fraction)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    MySQL.Async.fetchAll('SELECT * FROM users WHERE job=@job', {
        ['@job'] = fraction
    }, function(results)
        if not results then
            cb(nil)
        else
            cb(results)
        end
    end)
end)

ESX.RegisterServerCallback('esx_fbi_computer:getAccountStatements', function (source, cb, identifier)
    MySQL.Async.fetchAll('SELECT * FROM account_statement WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function (results)
        cb(results)
    end)
end)

ESX.RegisterServerCallback('esx_fbi_computer:getPersonEntries', function (source, cb, firstname, lastname)
    MySQL.Async.fetchAll('SELECT * FROM entries WHERE firstname = @firstname AND lastname = @lastname', {
        ['@firstname'] = firstname,
        ['@lastname'] = lastname
    }, function (results)
        if results[1] == nil then
            cb(nil)
        else
            cb(results)
        end
    end)
end)

ESX.RegisterServerCallback('esx_fbi_computer:getUserByName', function(source, cb, firstName, lastName)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    MySQL.Async.fetchAll('SELECT * FROM users WHERE firstname=@firstname AND lastname=@lastname', {
        ['@firstname'] = firstName,
        ['@lastname'] = lastName
    }, function(results)
        if not results then
            cb(nil)
        else
            cb(results[1])
        end
    end)
end)

ESX.RegisterServerCallback('esx_fbi_computer:getVehicleInfo', function(source, cb, plate)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE plate=@plate', {
        ['@plate'] = plate
    }, function(results)
        if not results then
            cb(nil)
        else
            MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier=@identifier', {
                ['@identifier'] = results[1].owner
            }, function(results2)
                cb(results2[1])
            end)
        end
    end)
end)

ESX.RegisterServerCallback('esx_fbi_computer:getFractionStorage', function(source, cb, fraction)
    TriggerEvent('esx_datastore:getSharedDataStore', 'society_' .. fraction, function(store)
      local weapons = store.get('weapons')
  
      if weapons == nil then
        cb(nil)
      end
      cb(weapons)
  
    end)
  
end)

RegisterServerEvent('esx_fbi_computer:addEntry')
AddEventHandler('esx_fbi_computer:addEntry', function (entry)
    MySQL.Async.execute('INSERT INTO entries (firstname, lastname, creator, job, strafe, description) VALUES (@firstname, @lastname, @creator, @job, @strafe, @description)', {
        ['@firstname'] = entry.firstname,
        ['@lastname'] = entry.lastname,
        ['@creator'] = entry.creator,
        ['@job'] = entry.job,
        ['@strafe'] = entry.strafe,
        ['@description'] = entry.description
    })
end)

RegisterServerEvent('esx_fbi_computer:addMostWanted')
AddEventHandler('esx_fbi_computer:addMostWanted', function (firstname, lastname, reason)
    MySQL.Async.execute('INSERT INTO most_wanted (firstname, lastname, reason) VALUES (@firstname, @lastname, @reason)', {
        ['@firstname'] = firstname,
        ['@lastname'] = lastname,
        ['@reason'] = reason
    })
end)

RegisterServerEvent('esx_fbi_computer:removeMostWanted')
AddEventHandler('esx_fbi_computer:removeMostWanted', function (firstname, lastname)
    MySQL.Async.execute('DELETE FROM most_wanted WHERE firstname = @firstname AND lastname = @lastname', {
        ['@firstname'] = firstname,
        ['@lastname'] = lastname
    })
end)

ESX.RegisterServerCallback('esx_fbi_computer:isWanted', function (source, cb, firstname, lastname)
    MySQL.Async.fetchAll('SELECT * FROM most_wanted WHERE firstname = @firstname AND lastname = @lastname', {
        ['@firstname'] = firstname,
        ['@lastname'] = lastname
    }, function (results) 
        if results == nil then
            cb(nil)
        else
            cb(results[1])
        end
    end)
end)

TriggerEvent('es:addGroupCommand', 'interpol', 'user', function(source, args, user)
	local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.job.name == 'fbi' or xPlayer.job.name == 'police' or xPlayer.job.name == 'marshal' then
        TriggerClientEvent('esx_fbi_computer:openComputer', xPlayer.source, xPlayer.job.name)
	else
		TriggerClientEvent('esx:showNotification', source, 'Nicht autorisiert!')
	end
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Insufficient Permissions.' } })
end, {help = 'Interpol Datenbank'})