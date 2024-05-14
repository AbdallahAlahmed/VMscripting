# Auteur: Abdallah Alahmed

# Laden van de algemene configuratiemodule
Import-Module Z:\scripting\algemeenxxx.psm1

# Laden van de module voor domain settings
Import-Module Z:\scripting\domainsettingsxxx.psm1

# Laden van de module voor het bijhouden van de wijzigingen
Import-Module Z:\scripting\logmodule.psm1

# Functie om de basisconfiguratie voor Windows Server 2022 uit te voeren
<#
.SYNOPSIS
Voert de basisconfiguratie uit voor Windows Server 2022, inclusief het instellen van servernaam, IP-adressen, default gateway en DNS.
#>
function Invoke-BasisconfiguratieWindowsServer2022 {
    # Implementeer de functionaliteit voor basisconfiguratie van Windows Server 2022
}

# Functie om de basisconfiguratie voor Windows 10 Pro/Education uit te voeren
<#
.SYNOPSIS
Voert de basisconfiguratie uit voor Windows 10 Pro/Education, inclusief het instellen van computernaam, IP-adressen, default gateway en DNS.
#>
function Invoke-BasisconfiguratieWindows10 {
    # Implementeer de functionaliteit voor basisconfiguratie van Windows 10 Pro/Education
}

# Functie voor het tonen van het menu
function Show-Menu {
    Write-Host "===== Welkom bij het configuratiemenu ====="
    Write-Host "1. Basisconfiguratie Windows Server 2022"
    Write-Host "2. Basisconfiguratie Windows 10 Pro/Education"
    $choice = Read-Host "Maak een keuze (1/2):"

    switch ($choice) {
        '1' {
            Invoke-BasisconfiguratieWindowsServer2022
        }
        '2' {
            Invoke-BasisconfiguratieWindows10
        }
        default {
            Write-Host "Ongeldige keuze. Probeer opnieuw."
            Show-Menu
        }
    }
}

# Main script

# Toon het menu
Show-Menu
