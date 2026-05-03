-- Inserisci questo item in ox_inventory/data/items.lua
-- Non impostare consume se la bodycam deve restare nell'inventario.

['bodycam'] = {
    label = 'Bodycam',
    weight = 250,
    stack = false,
    close = true,
    consume = 0,
    description = 'Bodycam di servizio.',
    client = {
        export = 'bg_bodycam.useBodycam'
    }
},
