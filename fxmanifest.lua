fx_version 'cerulean'
game 'gta5'

author 'cace'
description 'AO POLICE Computer'
version '1.0.4'

server_scripts {
	'@es_extended/locale.lua',
	'@mysql-async/lib/MySQL.lua',
	'config.lua',
	'server/main.lua'
}

client_scripts {
	'@es_extended/locale.lua',
	'config.lua',
	'client/main.lua'
}

dependencies {
	'es_extended',
	'instance',
	'cron',
	'esx_addonaccount',
	'esx_addoninventory',
	'esx_datastore'
}
