# BG-Bodycam
Bodycam script FiveM

<img width="1672" height="941" alt="bgbodycam" src="https://github.com/user-attachments/assets/c5125f72-4adb-4317-a824-c819d3960e1e" />


<img width="1024" height="1024" alt="bgbc" src="https://github.com/user-attachments/assets/5489c2c0-88de-4ccf-b20a-0cf2cf04afd1" />

https://www.youtube.com/watch?v=nkA8JQc1a5w


BG Bodycam è uno script FiveM moderno e immersivo pensato per server roleplay che vogliono aggiungere una bodycam realistica, elegante e completamente configurabile.

Utilizzando l’item bodycam tramite ox_inventory, il giocatore può accendere o spegnere la camera direttamente dall’inventario. All’attivazione, il ped esegue un’animazione coerente con l’accensione della bodycam sul petto e compare una UI professionale in stile registrazione, con informazioni live del personaggio.

La UI mostra nome e cognome, job, grado, orario reale e logo del dipartimento, con supporto a loghi diversi per ogni job, come LSPD, EMS, Sheriff e altri ruoli configurabili. Ogni elemento è gestibile dal config, rendendo lo script modulare, scalabile e adatto a qualsiasi struttura RP.

Il pannello bodycam può essere spostato liberamente dal player tramite comando editing, così ogni utente può posizionarlo dove preferisce sullo schermo. Riutilizzando l’item, la bodycam si spegne e l’interfaccia scompare automaticamente.

BG Bodycam è progettato per essere compatibile con ESX Legacy, QBCore, Qbox e server con setup personalizzati tramite bridge configurabile. È leggero, ordinato e pensato per integrarsi facilmente senza appesantire il gameplay.

Perfetto per reparti di polizia, medici, sheriff, federali e qualsiasi job che necessiti di una registrazione visiva in stile bodycam durante pattugliamenti, interventi, arresti, soccorsi e operazioni RP.

Un sistema semplice da usare, bello da vedere e pronto per rendere più professionali le scene del tuo server.

- item `bodycam` tramite `ox_inventory`
- compatibilità bridge: ESX Legacy, QBCore, Qbox e fallback standalone
- animazione di accensione/spegnimento sul petto
- NUI HTML/CSS/JS leggera, senza React
- UI spostabile dal player tramite comando
- salvataggio posizione client-side con KVP
- nome/cognome personaggio, label job, label grado, orario reale locale
- logo e label reparto configurabili per ogni job

## Installazione

1. Copia la cartella `bg_bodycam` in `resources/[scripts]/bg_bodycam`.
2. In `server.cfg`, assicurati di avviarla dopo framework e inventory:

```cfg
ensure es_extended # oppure qb-core / qbx_core
ensure ox_inventory
ensure bg_bodycam
```

3. Aggiungi l'item in `ox_inventory/data/items.lua`:

```lua
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
```

4. Riavvia `ox_inventory` e `bg_bodycam`, oppure riavvia il server.

## Comandi

- `/bodycamedit` abilita/disabilita la modifica della posizione UI. Trascina la UI e premi ESC per uscire.
- `/bodycamreset` resetta la posizione UI.
- `/bodycamdebug` stampa in F8 i dati player rilevati dal bridge, utile per capire nomi job/grade.

## Configurazione job/loghi

Apri `config.lua` e modifica `Config.Jobs`:

```lua
Config.Jobs = {
    police = {
        department = 'LOS SANTOS POLICE DEPARTMENT',
        uiJobLabel = 'LSPD',
        logo = 'assets/logos/lspd.svg',
        minGrade = 0,
        requireDuty = false
    },
}
```

Per aggiungere un job:

```lua
mechanic = {
    department = 'LOS SANTOS CUSTOMS',
    uiJobLabel = 'LSC',
    logo = 'assets/logos/generic.svg',
    minGrade = 0,
    requireDuty = false
}
```

Se vuoi permettere anche job non configurati, imposta:

```lua
Config.AllowUnconfiguredJobs = true
```

## Loghi personalizzati

Puoi sostituire gli SVG in `html/assets/logos/` con PNG, WebP o SVG tuoi. Poi aggiorna il path nel config, ad esempio:

```lua
logo = 'assets/logos/lspd.png'
```

Aggiungi il file al manifest se usi estensioni diverse da SVG:

```lua
files {
    'html/assets/logos/*.png'
}
```

## Qbox

Il bridge prova a leggere `exports.qbx_core:GetPlayerData()` e, se disponibile, `QBX.PlayerData`. Se nel tuo setup Qbox usi solo il modulo ufficiale `QBX.PlayerData`, assicurati che il dato sia disponibile lato client o adatta la funzione `getQboxPlayerData()` in `client/framework.lua`.

## Note

- Lo script non consuma la bodycam: evita `consume` nell'item di ox_inventory.
- La UI usa l'orario reale locale del client tramite JavaScript `Date`.
- Lo stato attivo viene replicato in `LocalPlayer.state.bodycamActive`.
