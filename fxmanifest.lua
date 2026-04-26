fx_version "bodacious"
game "gta5"

ui_page "nui/index.html"

shared_scripts {
    "@es_extended/imports.lua",
    "cfg/config.lua"
}

client_scripts {
    "client/client.lua"
}

server_scripts {
    "@es_extended/imports.lua",
    "server/server.lua"
}

files {
    "nui/*",
    "nui/imgs/*",
    "nui/sounds/*"
}