# Auteur: Abdallah Alahmed

# Functie voor basisconfiguratie van een Windows device
<#
.SYNOPSIS
Voert de basisconfiguratie van een Windows apparaat uit.
#>
function Set-Basisconfiguratie {
    # Plaats hier de code voor de basisconfiguratie van een Windows device
    Write-Host "Basisconfiguratie van Windows device wordt uitgevoerd..."
    # Voorbeeld: Installeer software, configureer netwerkinstellingen, etc.
    # Pad naar het XML-bestand
    $XmlFilePath = "Z:\scripting\settings\instellingen.xml"

    # Laden van XML
    $xml = [xml](Get-Content $XmlFilePath)

    # Functie om de parameters aan te passen
    function Update-XMLParameters {
        param(
            [string]$ServerInitialen,
            [string[]]$NieuweMACAdressen
        )
        # Aanpassen van servernaam
        $xml.Configuration.ServerName = $xml.Configuration.ServerName + $ServerInitialen

        # Aanpassen van MAC-adressen
        for ($i = 0; $i -lt $xml.Configuration.NetworkAdapters.NetworkAdapter.Count; $i++) {
            $xml.Configuration.NetworkAdapters.NetworkAdapter[$i].MACAddress = $NieuweMACAdressen[$i]
        }

        # Opslaan van wijzigingen naar XML-bestand
        $xml.Save($XmlFilePath)
    }

    # Vraag de gebruiker om initialen en nieuwe MAC-adressen
    $ServerInitialen = Read-Host "Voer uw initialen in voor de servernaam:"
    $NieuweMACAdressen = @()
    for ($i = 1; $i -le $xml.Configuration.NetworkAdapters.NetworkAdapter.Count; $i++) {
        $NieuwMAC = Read-Host "Voer het nieuwe MAC-adres in voor netwerkadapter $i" 
        $NieuweMACAdressen += $NieuwMAC
    }

    # Update XML-parameters
    Update-XMLParameters -ServerInitialen $ServerInitialen -NieuweMACAdressen $NieuweMACAdressen

    Write-Host "Parameters succesvol bijgewerkt in $XmlFilePath."

    # Log de wijziging
    Write-Log "Basisconfiguratie van Windows device uitgevoerd."
}

# Functie om wijzigingen te loggen
function Write-Log {
    param(
        [string]$Change
    )
    $LogFilePath = "Z:\scripting\logs\InstallatieLogxxx.txt"
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFilePath -Value "$Timestamp - $Change"
}

Export-ModuleMember Set-Basisconfiguratie -FunctionDefinition