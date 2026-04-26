cfg = {}

cfg.comandoXenon    = "xenon"
cfg.comandoNeon     = "neon"
cfg.comandoSuspensao = "suspe"

cfg.apenasDonoAcessaXenon     = true
cfg.apenasDonoAcessaNeon      = true
cfg.apenasDonoAcessaSuspensao = true

-- Set these to your ESX job names (xPlayer.getJob().name)
cfg.permissaoParaInstalar = {
    existePermissao = true,
    permissoes = { "mecanico", "bennys" }
}

cfg.blipsShopMec = {
    { loc = { x = 822.48, y = -952.23, z = 22.09 }, perms = { "mecanico" } }
}

cfg.valores = {
    { item = "suspensaoar", quantidade = 1, compra = 10000 },
    { item = "moduloneon",  quantidade = 1, compra = 5000  },
    { item = "moduloxenon", quantidade = 1, compra = 5000  },
}