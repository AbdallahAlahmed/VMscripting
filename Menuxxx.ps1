# Auteur: Abdallah Alahmed

# Laden van de algemene configuratiemodule
Import-Module .\algemeenxxx.psm1

# Laden van de domain settings configuratiemodule
Import-Module .\domainsettingsxxx.psm1

# Definieer het menu
function Show-Menu {
    Clear-Host
    Write-Host "=== Menu ==="
    Write-Host "1. Basisconfiguratie van Windows device"
    Write-Host "2. Configuratie van domain settings"
    Write-Host "Q. Afsluiten"
}

# Functie voor basisconfiguratie van Windows device
<#
.SYNOPSIS
Voert de basisconfiguratie van een Windows apparaat uit.
#>
function Perform-Basisconfiguratie {
    # Roep de functie uit algemene configuratiemodule aan
    Do-Basisconfiguratie
    Log-Change "Basisconfiguratie van Windows device uitgevoerd."
    Read-Host "Druk op Enter om terug te keren naar het menu."
}

# Functie voor configuratie van domain settings
<#
.SYNOPSIS
Voert de configuratie van domeininstellingen uit.
#>
function Perform-DomainSettings {
    # Roep de functie uit domain settings configuratiemodule aan
    Do-DomainSettings
    Log-Change "Configuratie van domain settings uitgevoerd."
    Read-Host "Druk op Enter om terug te keren naar het menu."
}

# Functie om wijzigingen te loggen
function Log-Change {
    param(
        [string]$Change
    )
    $LogFilePath = "Z:\scripting\logs\InstallatieLogxxx.txt"
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFilePath -Value "$Timestamp - $Change"
}

# Hoofdprogramma
while ($true) {
    Show-Menu
    $choice = Read-Host "Maak een keuze"
    switch ($choice) {
        '1' { Perform-Basisconfiguratie }
        '2' { Perform-DomainSettings }
        'Q' { break }
        default { Write-Host "Ongeldige keuze. Probeer opnieuw." }
    }
}
