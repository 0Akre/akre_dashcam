fx_version 'cerulean'
game 'gta5'

author 'Akre'
description 'Police Dashcam Script'
version '1.0.0'

shared_script {
    'config.lua'
}
server_scripts {
    'server.lua'
}

client_scripts {
    'dashcam.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}
