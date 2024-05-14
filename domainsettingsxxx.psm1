# Auteur: Abdallah Alahmed

# Functie voor configuratie van domain settings
<#
.SYNOPSIS
Voert de configuratie van domeininstellingen uit.
#>

# Functie voor het installeren van een domeincontroller
function Install-DomainController {
    # Plaats hier de code voor de configuratie van domain settings
    Write-Host "Configuratie van domain settings wordt uitgevoerd..."

    $ServerSettings = [xml](Get-Content .\instellingen.xml)
    $DomainName = $ServerSettings.Server.DomainName
    $DomainAdminUsername = $ServerSettings.Server.DomainAdminUsername
    $DomainAdminPassword = $ServerSettings.Server.DomainAdminPassword

    # Controleren of het domein al bestaat
    $domainExists = Test-Connection -ComputerName $DomainName -Quiet -Count 1

    if ($domainExists) {
        # Het domein bestaat al, maak van de server een nieuwe domeincontroller in het bestaande domein
        Add-Content -Path "log.txt" -Value "Het domein $DomainName bestaat al. Een nieuwe domeincontroller wordt toegevoegd."
        Install-ADDSDomainController -DomainName $DomainName -Credential (Get-Credential -UserName $DomainAdminUsername -Message "Voer het wachtwoord voor de domeinbeheerder in") -Force:$true
    }
    else {
        # Het domein bestaat nog niet, maak een nieuw domein aan
        Add-Content -Path "log.txt" -Value "Het domein $DomainName bestaat nog niet. Een nieuw domein wordt aangemaakt."
        Install-ADDSForest -DomainName $DomainName -DomainMode Win2012 -ForestMode Win2012 -DomainNetbiosName ($DomainName.Split('.')[0]) -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText $DomainAdminPassword -Force) -Force:$true
    }

    # Log de wijziging
    Log-Change "Configuratie van domain settings uitgevoerd."

}

# Installatie van de domeincontroller
Install-DomainController


# Functie om wijzigingen te loggen
function Write-Log {
    param(
        [string]$Change
    )
    $LogFilePath = "Z:\scripting\logs\InstallatieLogxxx.txt"
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFilePath -Value "$Timestamp - $Change"
}

Export-ModuleMember .\domainsettingsxxx.psm1 -Function Install-DomainController