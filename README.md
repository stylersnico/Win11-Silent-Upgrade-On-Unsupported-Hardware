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

# Script configuration

Adapt the following part in the script you will use, one command is made for testing, the other one for the real GPO deployment: 
```powershell
##########################################
#Test Command, not silent and will reboot#
##########################################
#$UpgradeCommand = "$setupPath /auto upgrade /Eula Accept /Dynamicupdate Disable /product server"

##########################################
# Production Command, silent and noreboot#
##########################################
#$UpgradeCommand = "$setupPath /auto upgrade /Eula Accept /Dynamicupdate Disable /product server /Quiet /noreboot"
```

# GPO deployment Steps
First, deploy the script to the computers via logon script or any other means:
```cmd
robocopy \\share\Win11\ C:\Users\Public\Documents\ win11-upgrade-iso.ps1
```

Then, create a GPO with the following settings, to deploy a scheduled task that will try the upgrade at user logon using the system account (make sure a Windows 11 iso is available on network for "everyone" user if you use iso method):

```
Computer configuration
- Administrative Templates
-- System/Logon
--- Always wait for the network at computer startup and logon -> Enabled

-- System/Scripts
--- Run startup scripts asynchronously -> Enabled

-- Windows Components/Windows Powershell
--- Turn on Script Execution  -> Enabled


-Preferences
-- Control panel settings
--- Scheduled tasks (at least Windows 7)

Task:
- Name  Upgrade to Win 11   
- Run only when user is logged on  S4U   
- UserId  NT AUTHORITY\SYSTEM   
- Run with highest privileges  HighestAvailable   
- Hidden  No   
- Configure for  1.2   
- Enabled  Yes 

Triggers
- 1. Run at user logon     
-  Enabled  Yes 

Actions
- 1. Start a program     
-  Program/script  powershell.exe   
-  Arguments  -ExecutionPolicy Bypass -File "C:\Users\Public\Documents\win11-upgrade-iso.ps1"

Settings
-  Stop if the computer ceases to be idle  Yes   
- Restart if the idle state resumes  No   
-  Start the task only if the computer is on AC power  Yes   
-  Stop if the computer switches to battery power  Yes   
-  Allow task to be run on demand  Yes   
-  Stop task if it runs longer than  3 days   
-  If the running task does not end when requested, force it to stop  Yes   
-  If the task is already running, then the following rule applies  IgnoreNew
```
