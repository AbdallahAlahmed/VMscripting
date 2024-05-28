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

# Functie voor het aanmaken van OUs
function New-OUs {
    $OUs = Get-Content .\ou.txt

    foreach ($OU in $OUs) {
        # Controleren of de OU al bestaat
        $ouExists = Get-ADOrganizationalUnit -Filter "Name -eq '$OU'" -ErrorAction SilentlyContinue

        if ($null -eq $ouExists) {
            # De OU bestaat nog niet, maak deze aan
            New-ADOrganizationalUnit -Name $OU
            Add-Content -Path "log.txt" -Value "OU $OU is succesvol aangemaakt."
        }
        else {
            # De OU bestaat al, geef een melding
            Write-Host "OU $OU bestaat al."
        }
    }
}
# Aanmaken van OUs
Create-OUs


# Functie voor het aanmaken van beveiligingsgroepen
function New-SecurityGroups {
    $Groups = Import-Csv .\groups.csv

    foreach ($Group in $Groups) {
        $GroupName = $Group.Name
        $GroupType = $Group.Type
        $OU = $Group.OU

        # Controleren of de OU al bestaat, zo niet, maak de OU aan
        New-OUs -OUName $OU

        # Controleren of de groep al bestaat
        $groupExists = Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue

        if ($null -eq $groupExists) {
            if ($GroupType -eq "DL") {
                New-ADGroup -Name $GroupName -GroupScope DomainLocal -Path "OU=$OU,DC=domain,DC=com"
            }
            elseif ($GroupType -eq "GL") {
                New-ADGroup -Name $GroupName -GroupScope Global -Path "OU=$OU,DC=domain,DC=com"
            }
            Add-Content -Path "log.txt" -Value "Groep $GroupName is succesvol aangemaakt in de OU $OU."
        }
        else {
            Write-Host "Groep $GroupName bestaat al."
        }
    }
}

# Aanroepen van de functie om beveiligingsgroepen aan te maken
New-SecurityGroups

# Functie voor het aanmaken van domeingebruikers
function New-DomainUsers {
    $Users = Import-Csv .\users.csv

    foreach ($User in $Users) {
        $UserName = $User.UserName
        $Password = ConvertTo-SecureString $User.Password -AsPlainText -Force
        $FirstName = $User.FirstName
        $LastName = $User.LastName
        $OU = $User.OU
        $HomeDirectory = "C:\userhomes\$UserName"
        $ProfilePath = "C:\userprofiles\$UserName"

        # Controleren of de OU al bestaat, zo niet, maak de OU aan
        New-OUs -OUName $OU

        # Controleren of de gebruiker al bestaat
        $userExists = Get-ADUser -Filter "SamAccountName -eq '$UserName'" -ErrorAction SilentlyContinue

        if ($null -eq $userExists) {
            # Gebruiker bestaat niet, maak de gebruiker aan
            New-ADUser -Name "$FirstName $LastName" -GivenName $FirstName -Surname $LastName -SamAccountName $UserName `
                -UserPrincipalName "$UserName@domain.com" -Path "OU=$OU,DC=domain,DC=com" `
                -AccountPassword $Password -HomeDirectory $HomeDirectory -HomeDrive "H:" -ProfilePath $ProfilePath -Enabled $true
            Add-Content -Path "log.txt" -Value "Gebruiker $UserName is succesvol aangemaakt in de OU $OU."

            # Aanmaken van home directory en roaming profile directory
            New-Item -ItemType Directory -Path $HomeDirectory -Force
            New-Item -ItemType Directory -Path $ProfilePath -Force
            Add-Content -Path "log.txt" -Value "Home directory en roaming profile voor gebruiker $UserName zijn aangemaakt."
        }
        else {
            Write-Host "Gebruiker $UserName bestaat al."
        }
    }
}

# Aanroepen van de functie om domeingebruikers aan te maken
New-DomainUsers


# Functie voor het toevoegen van gebruikers aan beveiligingsgroepen
function Add-UsersToGroups {
    $UserGroups = Import-Csv .\usergroups.csv

    foreach ($UserGroup in $UserGroups) {
        $UserName = $UserGroup.UserName
        $GroupName = $UserGroup.GroupName

        # Controleren of de beveiligingsgroep bestaat
        $groupExists = Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue

        if ($null -eq $groupExists) {
            Write-Host "Beveiligingsgroep $GroupName bestaat niet."
            Add-Content -Path "log.txt" -Value "Error: Beveiligingsgroep $GroupName bestaat niet."
            continue
        }

        # Controleren of de gebruiker bestaat
        $userExists = Get-ADUser -Filter "SamAccountName -eq '$UserName'" -ErrorAction SilentlyContinue

        if ($null -eq $userExists) {
            Write-Host "Gebruiker $UserName bestaat niet."
            Add-Content -Path "log.txt" -Value "Error: Gebruiker $UserName bestaat niet."
            continue
        }

        # Gebruiker toevoegen aan de groep
        Add-ADGroupMember -Identity $GroupName -Members $UserName
        Add-Content -Path "log.txt" -Value "Gebruiker $UserName is toegevoegd aan de beveiligingsgroep $GroupName."
    }
}

# Aanroepen van de functie om gebruikers aan beveiligingsgroepen toe te voegen
Add-UsersToGroups


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

Export-ModuleMember .\domainsettingsxxx.psm1 -Function New-OUs

Export-ModuleMember .\domainsettingsxxx.psm1 -Function New-SecurityGroups
Export-ModuleMember .\domainsettingsxxx.psm1 -Function New-DomainUsers
Export-ModuleMember .\domainsettingsxxx.psm1 -Function Add-UsersToGroups

Write-Log "Script gestart op $(Get-Date)"