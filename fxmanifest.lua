fx_version 'cerulean'
game 'gta5'

description 'Sustav za rentanje vozila sa UI i databazom'
author 'Emanuel'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/script.js',
    'html/style.css'
}

shared_scripts {
    'config.lua',
    '@es_extended/imports.lua',
    '@qb-core/shared.lua'
}

client_script 'client.lua'
server_script {
    '@oxmysql/lib/MySQL.lua', -- ili mysql-async
    'server.lua'
}
