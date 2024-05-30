# Auteur: Abdallah Alahmed

# Laden van de algemene configuratiemodule
Import-Module Z:\scripting\algemeenxxx.psm1

# Laden van de module voor domain settings
Import-Module Z:\scripting\domainsettingsxxx.psm1

# Laden van de module voor het bijhouden van de wijzigingen
Import-Module Z:\scripting\logmodule.psm1

# Auteur: Abdallah Alahmed

# Importeren van de modules
Import-Module -Name .\domainsettingsxxx.psm1

# Functie om het menu te tonen
function Show-Menu {
    Clear-Host
    Write-Host "======================="
    Write-Host " Server Configuratie Menu "
    Write-Host "======================="
    Write-Host "1. Basisconfiguratie van Windows device"
    Write-Host "2. Domeincontroller installeren"
    Write-Host "3. OUs aanmaken"
    Write-Host "4. Beveiligingsgroepen aanmaken"
    Write-Host "5. Domeingebruikers aanmaken"
    Write-Host "6. Gebruikers toevoegen aan beveiligingsgroepen"
    Write-Host "7. Directories en shares aanmaken"
    Write-Host "8. Share en NTFS-rechten toekennen"
    Write-Host "9. Exit"
}

# Functie om de keuze van de gebruiker te verwerken
function show-Menu {
    param (
        [int]$choice
    )

    switch ($choice) {
        1 {
            Write-Host "Basisconfiguratie van Windows device wordt uitgevoerd..."
            Set-Basisconfiguratie
            Pause
        }
        2 {
            Write-Host "Domeincontroller installeren..."
            Install-DomainController
            Pause
        }
        3 {
            Write-Host "OUs aanmaken..."
            New-OUs
            Pause
        }
        4 {
            Write-Host "Beveiligingsgroepen aanmaken..."
            New-SecurityGroups
            Pause
        }
        5 {
            Write-Host "Domeingebruikers aanmaken..."
            New-DomainUsers
            Pause
        }
        6 {
            Write-Host "Gebruikers toevoegen aan beveiligingsgroepen..."
            Add-UsersToGroups
            Pause
        }
        7 {
            Write-Host "Directories en shares aanmaken..."
            New-DirectoriesAndShares
            Pause
        }
        8 {
            Write-Host "Share en NTFS-rechten toekennen..."
            Set-ShareAndNTFSRights
            Pause
        }
        9 {
            Write-Host "Exiting..."
            Exit
        }
        default {
            Write-Host "Ongeldige keuze, probeer opnieuw."
            Pause
        }
    }
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Voer uw keuze in"
    Process-Menu -choice $choice
} while ($choice -ne 9)
