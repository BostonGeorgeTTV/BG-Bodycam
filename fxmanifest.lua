fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'bg_bodycam'
author 'BostonGeorgeTTV'
description 'Bodycam modulare con NUI spostabile, ox_inventory, ESX/QBCore/Qbox bridge'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/logos/*.svg'
}

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/framework.lua',
    'client/main.lua'
}
