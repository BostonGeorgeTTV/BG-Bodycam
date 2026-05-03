Config = {}

-- Framework supportati: 'auto', 'esx', 'qbcore', 'qbox', 'standalone'
-- auto rileva qbx_core, qb-core o es_extended se avviati.
Config.Framework = 'auto'

-- Inventory principale. Per ox_inventory usa l'export item: bg_bodycam.useBodycam
Config.Inventory = 'ox'
Config.ItemName = 'bodycam'

-- Se false, solo i job presenti in Config.Jobs possono usare la bodycam.
-- Se true, anche job non configurati possono usarla con Config.DefaultJob.
Config.AllowUnconfiguredJobs = false

-- Se true, per framework QB/Qbox controlla job.onduty quando il job lo richiede.
Config.RequireDutyWhenConfigured = true

Config.Commands = {
    edit = 'bodycamedit',       -- toggle editing/spostamento UI
    reset = 'bodycamreset',     -- reset posizione UI
    debug = 'bodycamdebug'      -- stampa i dati rilevati del player in F8, utile in setup
}

Config.Keybinds = {
    enableEditKeybind = false,
    editDescription = 'Modifica posizione Bodycam UI',
    editDefaultKey = 'F7'
}

Config.Notifications = {
    -- auto prova ox_lib, qbox, qbcore, esx, poi GTA feed nativo.
    provider = 'auto', -- 'auto', 'ox', 'qbox', 'qbcore', 'esx', 'native'
    duration = 3500
}

Config.Animation = {
    enabled = true,
    dict = 'clothingtie',
    clip = 'try_tie_positive_a',
    flag = 49,
    duration = 1600
}

Config.Sounds = {
    enabled = true,
    on = { name = '5_SEC_WARNING', set = 'HUD_MINI_GAME_SOUNDSET' },
    off = { name = 'ATM_WINDOW', set = 'HUD_FRONTEND_DEFAULT_SOUNDSET' }
}

Config.UI = {
    title = 'BODYCAM',
    model = 'BG-CAM X1',
    showLogo = true,
    showRecordingDot = true,
    scale = 1.0,

    -- posizione di default prima che il player la modifichi.
    -- Puoi usare top/right/bottom/left CSS, oppure lasciare che la UI salvi left/top in pixel.
    defaultPosition = {
        top = '6.5vh',
        right = '2.0vw'
    }
}

Config.Time = {
    locale = 'it-IT',
    hour12 = false,
    showDate = true,
    showSeconds = true
}

Config.Text = {
    bodycamOn = 'Bodycam accesa.',
    bodycamOff = 'Bodycam spenta.',
    noPermission = 'Non puoi usare questa bodycam con il tuo job.',
    notOnDuty = 'Devi essere in servizio per usare questa bodycam.',
    editEnabled = 'Modalità modifica bodycam attiva. Trascina la UI e premi ESC per chiudere.',
    editDisabled = 'Modalità modifica bodycam disattivata.',
    resetPosition = 'Posizione bodycam ripristinata.'
}

-- Configurazione modulare per job. Aggiungi qui altri reparti.
-- logo può puntare a un file locale in html/assets/logos/ oppure a una URL NUI consentita.
-- minGrade è opzionale; usa il numero grade/level del framework.
-- requireDuty ha effetto su QB/Qbox se Config.RequireDutyWhenConfigured = true.
Config.Jobs = {
    police = {
        department = 'LOS SANTOS POLICE DEPARTMENT',
        uiJobLabel = 'LSPD',
        logo = 'assets/logos/lspd.svg',
        minGrade = 0,
        requireDuty = false
    },
    ambulance = {
        department = 'LOS SANTOS MEDICAL SERVICES',
        uiJobLabel = 'EMS',
        logo = 'assets/logos/ems.svg',
        minGrade = 0,
        requireDuty = false
    },
    sheriff = {
        department = 'BLAINE COUNTY SHERIFF OFFICE',
        uiJobLabel = 'BCSO',
        logo = 'assets/logos/sheriff.svg',
        minGrade = 0,
        requireDuty = false
    },
    fib = {
        department = 'FEDERAL INVESTIGATION BUREAU',
        uiJobLabel = 'FIB',
        logo = 'assets/logos/fib.svg',
        minGrade = 0,
        requireDuty = false
    },
    governo = {
        department = 'GOVERNMENT SECURITY',
        uiJobLabel = 'GOV',
        logo = 'assets/logos/generic.svg',
        minGrade = 0,
        requireDuty = false
    }
}

Config.DefaultJob = {
    department = 'BODY WORN CAMERA',
    uiJobLabel = 'SERVICE',
    logo = 'assets/logos/generic.svg'
}
