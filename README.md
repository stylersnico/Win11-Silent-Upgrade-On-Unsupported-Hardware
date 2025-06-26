# Win11 Silent Upgrade On Unsupported Hardware
The goal of this project is to provide an upgrade to Windows 11 24H2 silently from unsupported Hardware running Windows 10

Tested on : 
- Windows 10 22h2 (Source OS)
- Windows 11 24H2 (Target OS)

# Running local ISO Script
Use the `win11-upgrade-iso.ps1` if you want to deploy Windows 11 on your network with the iso image hosted on a network share locally.

# Running FIDO download Script
Use the `win11-upgrade-fido.ps1` if you want to deploy Windows 11 using the latest ISO available from Microsoft.
The script will detect the windows version and language used on the computer and download the right iso directly.

Note : If you have a large number of computers, you could get a temporary ban from Microsoft, preventing the script for working.


# GPO deployment Steps
- Create a new GPO under Computer Configuration > Policies > Windows Settings > Scripts (Startup/Shutdown).
- Add the PowerShell script to Startup Scripts.
- Enable the GPO settings: Administrative Templates > System > Scripts > Turn on PowerShell Execution → Set to Allow all scripts.
