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
    $OUs = Get-Content .\ous.csv

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
New-OUs


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

# Functie voor het aanmaken van directories en shares
function New-DirectoriesAndShares {
    $Shares = Import-Csv .\share.csv

    foreach ($Share in $Shares) {
        $SharePath = $Share.Directory
        $ShareName = $Share.ShareName

        # Controleren of de directory bestaat, anders aanmaken
        if (-Not (Test-Path -Path $SharePath)) {
            New-Item -ItemType Directory -Path $SharePath -Force
            Add-Content -Path "log.txt" -Value "Directory $SharePath is succesvol aangemaakt."
            Write-Host "Directory $SharePath is succesvol aangemaakt."
        }
        else {
            Add-Content -Path "log.txt" -Value "Directory $SharePath bestaat al."
            Write-Host "Directory $SharePath bestaat al."
        }

        # Controleren of de share al bestaat
        $shareExists = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue

        if ($null -eq $shareExists) {
            New-SmbShare -Name $ShareName -Path $SharePath -FullAccess "Everyone"
            Add-Content -Path "log.txt" -Value "Share $ShareName op $SharePath is succesvol aangemaakt."
            Write-Host "Share $ShareName op $SharePath is succesvol aangemaakt."
        }
        else {
            Add-Content -Path "log.txt" -Value "Share $ShareName bestaat al."
            Write-Host "Share $ShareName bestaat al."
        }
    }
}

# Aanroepen van de functie om directories en shares aan te maken
New-DirectoriesAndShares

# Functie voor het toekennen van share- en NTFS-rechten
function Set-ShareAndNTFSRights {
    $Rights = Import-Csv .\rechten.csv

    foreach ($Right in $Rights) {
        $ObjectType = $Right.ObjectType
        $ObjectName = $Right.ObjectName
        $SecurityGroup = $Right.SecurityGroup
        $Permission = $Right.Permission

        # Controleren of de security group bestaat
        $groupExists = Get-ADGroup -Filter "Name -eq '$SecurityGroup'" -ErrorAction SilentlyContinue

        if ($null -eq $groupExists) {
            Write-Host "Security group $SecurityGroup bestaat niet."
            Add-Content -Path "log.txt" -Value "Error: Security group $SecurityGroup bestaat niet."
            continue
        }

        if ($ObjectType -eq "Share") {
            # Controleren of de share bestaat
            $shareExists = Get-SmbShare -Name $ObjectName -ErrorAction SilentlyContinue

            if ($null -eq $shareExists) {
                Write-Host "Share $ObjectName bestaat niet."
                Add-Content -Path "log.txt" -Value "Error: Share $ObjectName bestaat niet."
                continue
            }

            # Share rechten toekennen
            Grant-SmbShareAccess -Name $ObjectName -AccountName $SecurityGroup -AccessRight $Permission -Force
            Add-Content -Path "log.txt" -Value "Rechten $Permission toegekend aan $SecurityGroup op share $ObjectName."
            Write-Host "Rechten $Permission toegekend aan $SecurityGroup op share $ObjectName."
        }
        elseif ($ObjectType -eq "Folder") {
            # Controleren of de map bestaat
            if (-Not (Test-Path -Path $ObjectName)) {
                Write-Host "Map $ObjectName bestaat niet."
                Add-Content -Path "log.txt" -Value "Error: Map $ObjectName bestaat niet."
                continue
            }

            # NTFS rechten toekennen
            $acl = Get-Acl -Path $ObjectName
            $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($SecurityGroup, $Permission, "ContainerInherit,ObjectInherit", "None", "Allow")
            $acl.SetAccessRule($accessRule)
            Set-Acl -Path $ObjectName -AclObject $acl
            Add-Content -Path "log.txt" -Value "Rechten $Permission toegekend aan $SecurityGroup op map $ObjectName."
            Write-Host "Rechten $Permission toegekend aan $SecurityGroup op map $ObjectName."
        }
        else {
            Write-Host "Onbekend ObjectType $ObjectType voor $ObjectName."
            Add-Content -Path "log.txt" -Value "Error: Onbekend ObjectType $ObjectType voor $ObjectName."
        }
    }
}

# Aanroepen van de functie om share- en NTFS-rechten toe te kennen
Set-ShareAndNTFSRights


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
Export-ModuleMember .\domainsettingsxxx.psm1 -Function New-DirectoriesAndShares
Export-ModuleMember .\domainsettingsxxx.psm1 -Function Set-ShareAndNTFSRights


Write-Log "Script gestart op $(Get-Date)"