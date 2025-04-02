https://github.com/AbdallahAlahmed/VMscripting

# VMscripting

This repository contains scripts for virtual machine management.

## Server Configuration Automation

### Overview

This set of PowerShell scripts automates the configuration of a Windows server environment, including installing a domain controller, creating organizational units (OUs), security groups, domain users, and managing directories, shares, and permissions.

## Files

algemeenxxx.psm1: Module with general functions.
domainsettingsxxx.psm1: Module with domain-specific functions.
menu.ps1: Main menu script for executing various tasks.
ou.txt: File containing the list of OUs to be created.
groups.csv: CSV file containing the security groups information.
users.csv: CSV file containing the domain users information.
usergroups.csv: CSV file containing the user-to-group mappings.
share.csv: CSV file containing the share details.
rechten.csv: CSV file containing share and NTFS permissions.
instellingen.xml: XML file containing the server settings.

## Prerequisites

Windows Server environment with Active Directory Domain Services (ADDS) installed.
Appropriate permissions to execute PowerShell scripts and manage ADDS.
Ensure PowerShell execution policy is set to allow running scripts:
powershell
Copy code
Set-ExecutionPolicy RemoteSigned

## Installation

Place all the scripts and configuration files in a directory on your server.
Update the configuration files (ou.txt, groups.csv, users.csv, usergroups.csv, share.csv, rechten.csv, and instellingen.xml) with your specific settings.

## Usage

Open a PowerShell prompt as an administrator.
Navigate to the directory containing your scripts.
Run the menu.ps1 script to start the interactive menu:
powershell
Copy code
.\menu.ps1
Follow the on-screen menu to execute various configuration tasks.

### Menu Options

Basisconfiguratie van Windows device: Executes basic configuration for a Windows device.
Domeincontroller installeren: Installs a domain controller.
OUs aanmaken: Creates organizational units as specified in ou.txt.
Beveiligingsgroepen aanmaken: Creates security groups as specified in groups.csv.
Domeingebruikers aanmaken: Creates domain users as specified in users.csv.
Gebruikers toevoegen aan beveiligingsgroepen: Adds users to security groups as specified in usergroups.csv.
Directories en shares aanmaken: Creates directories and shares as specified in share.csv.
Share en NTFS-rechten toekennen: Sets share and NTFS permissions as specified in rechten.csv.
Exit: Exits the menu.

## Logging

All actions performed by the scripts are logged in log.txt located in the same directory as the scripts. This includes:

Creation of OUs, security groups, and users.
Addition of users to groups.
Creation of directories and shares.
Assignment of share and NTFS permissions.
Any errors encountered during execution.

## Error Handling

If any errors occur (e.g., an OU, security group, or share already exists), they are logged in log.txt but do not stop the execution of the script. This ensures that the script continues to run and attempts to process all items.

## Contributing

Describe how others can contribute to this repository, including any guidelines or requirements.

## License

Include information about the license under which this repository is released.

## Support

For any issues or questions, please contact the script author: Abdallah Alahmed.
