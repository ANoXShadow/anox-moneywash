fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'anox-moneywash'
author 'ANoXStudio'
version '1.0.1'
description 'MoneyWash script compatible with ESX, QBCore, and QBox'

shared_scripts {
    '@ox_lib/init.lua',
    'bridge/loader.lua',
    'config.lua',
    'locales.lua'
}

client_scripts {
    'bridge/client/*.lua',
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server/*.lua',
    'server/*.lua'
}

files {
    'locales/*.json'
}

dependencies {
    'ox_lib'
}