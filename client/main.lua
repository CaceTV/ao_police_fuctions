local CurrentActionData = {}
local CurrentActionMsg
local CurrentAction

local PlayerData                = {}

local ComputerJob = nil

ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
end)

-- Create Markers
Citizen.CreateThread(function()
	while true do
		Wait(0)

		local coords = GetEntityCoords(GetPlayerPed(-1))

		for i=1, #Config.Computers, 1 do
			if GetDistanceBetweenCoords(coords, Config.Computers[i].x, Config.Computers[i].y, Config.Computers[i].z, true) < 6.0 then
				DrawMarker(1, Config.Computers[i].x, Config.Computers[i].y, Config.Computers[i].z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.5, 1.5, 0.3, Config.Computers[i].r, Config.Computers[i].g, Config.Computers[i].b, 100, false, true, 2, false, false, false, false)
			end
		end
	end
end)

-- Enter / Exit Marker Events
Citizen.CreateThread(function()
	while true do
		Wait(0)
		
		local coords = GetEntityCoords(GetPlayerPed(-1))
		local isInMarker = false

		for i=1, #Config.Computers, 1 do
			if GetDistanceBetweenCoords(coords, Config.Computers[i].x, Config.Computers[i].y, Config.Computers[i].z, true) < 1.5 then
				isInMarker = true
				CurrentActionMsg = 'Drücke ~INPUT_CONTEXT~ um auf den Computer zuzugreifen'
				ComputerJob = Config.Computers[i].job
			end
		end

		local hasExited = false

		if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum) ) then
  
		  if
			(LastStation ~= nil and LastPart ~= nil and LastPartNum ~= nil) and
			(LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)
		  then
			TriggerEvent('esx_fbi_computer:hasExitedMarker', LastStation, LastPart, LastPartNum)
			hasExited = true
		  end
  
		  HasAlreadyEnteredMarker = true
		  LastStation             = currentStation
		  LastPart                = currentPart
		  LastPartNum             = currentPartNum
  
		  TriggerEvent('esx_fbi_computer:hasEnteredMarker')
		end
  
		if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
  
		  HasAlreadyEnteredMarker = false
  
		  TriggerEvent('esx_fbi_computer:hasExitedMarker', LastStation, LastPart, LastPartNum)
		end
	end
end)

AddEventHandler('esx_fbi_computer:hasExitedMarker', function()
	ESX.UI.Menu.CloseAll()
	CurrentActionMsg = nil
	CurrentAction = nil
  end)

AddEventHandler('esx_fbi_computer:hasEnteredMarker', function()
	CurrentAction = 'open'
end)

RegisterNetEvent('esx_fbi_computer:openComputer')
AddEventHandler('esx_fbi_computer:openComputer', function (job)
	ComputerJob = job

	OpenMenu()
end)

function OpenMenu()
	local elements = {}

	table.insert(elements, { label = 'Nummer überprüfen', value = 'check_number' })
	table.insert(elements, { label = 'Person überprüfen', value = 'check_person' })
	table.insert(elements, { label = 'Fahrzeug überprüfen', value = 'check_vehicle' })

	if ComputerJob == 'fbi' then
		table.insert(elements, { label = 'Fraktion überprüfen', value = 'check_fraction' })
		table.insert(elements, { label = 'Lager überprüfen', value = 'check_storage' })
	end
	
--	table.insert(elements, { label = '', value = ''})
--	table.insert(elements, { label = 'Akteneintrag erstellen', value = 'entry_create' })

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'checker', {
		title    = 'Department of Justice Datenbank',
		align    = 'top-left',
		elements = elements
	}, function(data, menu)

		if data.current.value == 'check_number' then
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'put_item_count', {
				title = 'Nummber eingeben'
			}, function(data2, menu2)
				local number = data2.value

				if number == nil then
					ESX.ShowNotification('~r~Bitte gib eine Nummer an!')
				else
					menu2.close()

					ESX.TriggerServerCallback('esx_fbi_computer:getUserByPhoneNumber', function (user)
						if user == nil then
							ESX.ShowNotification('~r~Nummer nicht gefunden!')
						else
							OpenPersonMenu(user)
						end
					end, number)
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		elseif data.current.value == 'check_person' then
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'put_item_count', {
				title = 'Vorname eingeben'
			}, function(data2, menu2)
				local firstname = data2.value

				if firstname == nil then
					ESX.ShowNotification('~r~Bitte gib einen Vornamen an!')
				else
					menu2.close()

					ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'put_item_count', {
						title = 'Nachname eingeben'
					}, function(data3, menu3)
						local secondName = data3.value
		
						if secondName == nil then
							ESX.ShowNotification('~r~Bitte gib einen Nachnamen an!')
						else
							menu3.close()
		
							ESX.TriggerServerCallback('esx_fbi_computer:getUserByName', function (user)
								if user == nil then
									ESX.ShowNotification('~r~Person nicht gefunden!')
								else
									OpenPersonMenu(user)
								end
							end, firstname, secondName)
						end
					end, function(data3, menu3)
						menu3.close()
					end)
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		elseif data.current.value == 'check_vehicle' then
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'put_item_count', {
				title = 'Nummernschild eingeben'
			}, function(data2, menu2)
				local number = data2.value

				if number == nil then
					ESX.ShowNotification('~r~Bitte gib ein Nummernschild an!')
				else
					menu2.close()

					ESX.TriggerServerCallback('esx_fbi_computer:getVehicleInfo', function (user)
						if user == nil then
							ESX.ShowNotification('~r~Auto nicht gefunden!')
						else
							OpenPersonMenu(user)
						end
					end, number)
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		elseif data.current.value == 'check_fraction' then
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'put_item_count', {
				title = 'Fraktion angeben'
			}, function(data2, menu2)
				local fraction = data2.value

				if fraction == nil then
					ESX.ShowNotification('~r~Bitte gib eine Fraktion an!')
				else
					menu2.close()

					if not IsValidFraction(fraction) then
						ESX.ShowNotification('Kein Treffer')
						return
					end

					ESX.TriggerServerCallback('esx_fbi_computer:getFractionInfo', function (fraction)
						if fraction == nil then
							ESX.ShowNotification('~r~Fraktion nicht gefunden!')
						else
							
							OpenFractionMenu(fraction)
						end
					end, fraction)
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		elseif data.current.value == 'check_storage' then
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'put_item_count', {
				title = 'Fraktion angeben'
			}, function(data2, menu2)
				local fraction = data2.value

				if fraction == nil then
					ESX.ShowNotification('~r~Bitte gib eine Fraktion an!')
				else
					if not IsValidFraction(fraction) then
						ESX.ShowNotification('Kein Treffer')
						return
					end
					menu2.close()

					ESX.TriggerServerCallback('esx_fbi_computer:getFractionStorage', function (weapons)
						if weapons == nil then
							ESX.ShowNotification('~r~Fraktion nicht gefunden!')
						else
							OpenFractionStorageMenu(weapons)
						end
					end, fraction)
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		elseif data.current.value == 'entry_create' then
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'put_item_count', {
				title = 'Vorname'
			}, function(data3, menu3)
				local firstName = data3.value

				if firstName == nil then
					ESX.ShowNotification('~r~Bitte gib einen Vornamen an!')
				else
					menu3.close()

					ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'put_item_count', {
						title = 'Nachname'
					}, function(data4, menu4)
						local nachName = data4.value
		
						if nachName == nil then
							ESX.ShowNotification('~r~Bitte gib einen Nachnamen an!')
						else
							menu4.close()

							ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'put_item_count', {
								title = 'Dein Name'
							}, function(data5, menu5)
								local creator = data5.value
				
								if creator == nil then
									ESX.ShowNotification('~r~Bitte gib deinen Namen an!')
								else
									menu5.close()
		
									ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'put_item_count', {
										title = 'Strafe'
									}, function(data6, menu6)
										local strafe = data6.value
						
										if strafe == nil then
											ESX.ShowNotification('~r~Bitte gib eine Strafe an!')
										else
											menu6.close()
				
											ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'put_item_count', {
												title = 'Beschreibung'
											}, function(data7, menu7)
												local description = data7.value
								
												if description == nil then
													ESX.ShowNotification('~r~Bitte gib eine Beschreibung an!')
												else
													menu7.close()
						
													local entry = {
														firstname = firstName,
														lastname = nachName,
														creator = creator,
														job = 'FIB',
														strafe = strafe,
														description = description
													}

													if PlayerData and PlayerData.job and PlayerData.job.name == 'police' or PlayerData.job.name == 'marshal' then
														entry.job = 'LSPD'
													end

													TriggerServerEvent('esx_fbi_computer:addEntry', entry)
													ESX.ShowNotification('~g~Eintrag erfolgreich angelegt!')
												end
											end, function(data7, menu7)
												menu7.close()
											end)
										end
									end, function(data6, menu6)
										menu6.close()
									end)
								end
							end, function(data5, menu5)
								menu5.close()
							end)

						end
					end, function(data4, menu4)
						menu4.close()
					end)

				end
			end, function(data3, menu3)
				menu3.close()
			end)
		end

	end, function(data, menu)
		menu.close()
	end)
end

function OpenPersonMenu (user)
	local elements = {}

	table.insert(elements, { label = 'Name: ' .. user.firstname .. ' ' .. user.lastname, value = 'test' })
	table.insert(elements, { label = 'Telefon: ' .. user.phone_number, value = nil })
	table.insert(elements, { label = 'Kontostand: ' .. ESX.Math.GroupDigits(user.bank) .. '$', value = nil })

	if IsValidFraction(user.job) then
		table.insert(elements, { label = 'Beruf: ' .. user.job, value = nil })
	else
		table.insert(elements, { label = 'Beruf: Arbeitslos', value = nil })
	end

	table.insert(elements, { label = 'Kontoauszüge', value = 'account_statement' })
--	table.insert(elements, { label = 'Akte öffnen', value = 'open_entries' })

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'person_check', {
		title = 'Department of Justice Personenabfrage',
		align = 'top-left',
		elements = elements
	}, function (data, menu)

		if data.current.value == 'add_wanted' then
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'put_item_count', {
				title = 'Grund der Fahnung'
			}, function(data2, menu2)
				local reason = data2.value
	
				if reason == nil then
					ESX.ShowNotification('~r~Bitte gib einen Grund an!')
				else
					menu2.close()
	
					TriggerServerEvent('esx_fbi_computer:addMostWanted', user.firstname, user.lastname, reason)
					ESX.ShowNotification('~g~Fahnung erstellt!')
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		elseif data.current.value == 'remove_wanted' then
			TriggerServerEvent('esx_fbi_computer:removeMostWanted', user.firstname, user.lastname)
			ESX.ShowNotification('~g~Die Fahnung wurde entfernt!')
		elseif data.current.value == 'open_entries' then
			ESX.TriggerServerCallback('esx_fbi_computer:getPersonEntries', function (results)
				if results == nil then
					ESX.ShowNotification('Person besitzt keine Einträge')
				else
					OpenEntries(results)
				end
			end, user.firstname, user.lastname)
		elseif data.current.value == 'account_statement' then
			ESX.TriggerServerCallback('esx_fbi_computer:getAccountStatements', function (statements)
				OpenAccountStatements(statements)
			end, user.identifier)
		end
	end, 
	function (data, menu)
		menu.close()
	end)
end

function OpenEntries (entries)
	local elements = {
		head = { 'Autor', 'Behörde', 'Strafe', 'Bescheibung' },
		rows = {}
	}

	for i=1, #entries, 1 do
		table.insert(elements.rows, {
			data = entries[i],
			cols = {
				entries[i].creator,
				entries[i].job,
				entries[i].strafe,
				entries[i].description
			}
		})
	end

	ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'entry_list', elements,  function (data, menu)

	end, function (data, menu)
		menu.close()
	end)
end

function OpenAccountStatements (statements)
	local elements = {
		head = { 'Id', 'Anzahl', 'Quelle', 'Nachricht'},
		rows = {}
	}

	for i=1, #statements, 1 do
		local amount

		if statements[i].plus then
			amount = '(+) ' .. ESX.Math.GroupDigits(statements[i].value) .. ' $'
		else
			amount = '(-) ' .. ESX.Math.GroupDigits(statements[i].value) .. ' $'
		end

		table.insert(elements.rows, {
			data = statements[i],
			cols = {
				statements[i].id,
				amount,
				statements[i].source,
				statements[i].message,
			}
		})
	end

	ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'account_statements', elements,  function (data, menu)

	end, function (data, menu)
		menu.close()
	end)
end

function OpenFractionMenu (fraction)
	local elements = {}

	table.insert(elements, {label = 'Fraktion: ' .. fraction[1].job})

	for i=1, #fraction, 1 do
		table.insert(elements, { label = 'Name: ' .. fraction[i].firstname .. ' ' .. fraction[i].lastname } )
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'checker', {
		title    = 'Department of Justice Datenbank',
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		menu.close()
	end, function(data, menu)
		menu.close()
	end)
end

function OpenFractionStorageMenu (weapons)
	local elements = {}

	for i=1, #weapons, 1 do
		if weapons[i].count > 0 then
		  table.insert(elements, {label = 'x' .. weapons[i].count .. ' ' .. ESX.GetWeaponLabel(weapons[i].name)})
		end
	end

	ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'armory_get_weapon',
      {
        title    = 'Department of Justice Datenbank',
        align    = 'top-left',
        elements = elements,
      },
      function(data, menu)
        menu.close()
      end,
      function(data, menu)
        menu.close()
      end
    )
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if CurrentActionMsg then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, 38) then
				if CurrentAction == 'open' then
					if PlayerData and PlayerData.job and (PlayerData.job.name == ComputerJob or PlayerData.job.name == 'fbi') then
						OpenMenu()
					else
						ESX.ShowNotification('~r~Du bist nicht autorisiert!')
					end
				end

			--	CurrentAction = nil
			--	CurrentActionMsg = nil
			end
		else
			Citizen.Wait(500)
		end
	end
end)

function IsValidFraction (fraction)
	for i=1, #Config.ValidFractions, 1 do
		if fraction == Config.ValidFractions[i] then
			return true
		end
	end
end