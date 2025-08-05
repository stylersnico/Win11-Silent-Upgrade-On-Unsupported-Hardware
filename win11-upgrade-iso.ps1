# Check if we are on Windows 10, ensure the script is not launching on any other OS
$osInfo = systeminfo
if ($osInfo -like "*Windows 10*") {
    Write-Host "This is Windows 10. Proceeding..."
    Write-Host "Upgrade to Windows 11 ongoing / doesn't reboot your computer - Mise à jour vers Windows 11 en cours / ne redémarrez pas votre ordinateur"
} else {
    Write-Host "This script only runs on Windows 10."
    exit
}

$drive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
if ($freeSpaceGB -ge 20) {
    Write-Output "C: drive has at least 20GB free ($freeSpaceGB GB available)."
} else {
    Write-Output "C: drive has less than 20GB free ($freeSpaceGB GB available)."
	exit
}

# Ensure Temp directory exists or create it
New-Item -Path "C:\Temp" -ItemType Directory -Force -ErrorAction SilentlyContinue
cd "C:\Temp"

# Log the current powershell session
Start-Transcript -Path "C:\Temp\win11upgrade.log"

###################################
### Retreive Windows on Network ###
###################################

# Define source and destination paths
$SourcePath = "\\networkshare\isos\Win11-French.iso"
$DestinationPath = "C:\Temp\Win11-French.iso"

# Ensure destination directory exists
if (!(Test-Path -Path (Split-Path $DestinationPath))) {
    New-Item -Path (Split-Path $DestinationPath) -ItemType Directory | Out-Null
}

# Transfer the ISO file using BITS
Start-BitsTransfer -Source $SourcePath -Destination $DestinationPath


##########################
### Install Windows 11 ###
##########################

### Initialize environment
$IsoPath = Get-ChildItem -Path "C:\Temp\Win11*.iso" | Select-Object -ExpandProperty FullName
$MountPoint = "C:\Win11Mount"
New-Item -Path $MountPoint -ItemType Directory -Force -ErrorAction Stop | Out-Null

### Verify ISO exists
if (-not (Test-Path $IsoPath)) {
    Write-Error "ISO file not found at $IsoPath"
    exit 1
}

### Mount ISO
# Start mounting and get the disk image object
$mount = Mount-DiskImage -ImagePath $isoPath -PassThru

# Wait for the ISO to be fully mounted
while (-not $mount.Attached) {
    Start-Sleep -Seconds 1
    $mount = Get-DiskImage -ImagePath $isoPath
}

# Get the drive letter assigned to the mounted ISO
$driveLetter = (Get-Volume -DiskImage $mount).DriveLetter + ":"

Write-Output "ISO mounted at drive $driveLetter"

### Bypass hardware checks
$regPath = 'HKLM:\SYSTEM\Setup\MoSetup'

if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
$bypassSettings = @{
    'AllowUpgradesWithUnsupportedTPMOrCPU' = 1
    'BypassTPMCheck'                       = 1
    'BypassRAMCheck'                       = 1
    'BypassSecureBootCheck'                = 1
    'bypassStorageCheck'                   = 1
}

foreach ($key in $bypassSettings.Keys) {
    Set-ItemProperty -Path $regPath -Name $key -Value $bypassSettings[$key] -Type DWORD -Force
}

# Set UpgradeEligibility for current user
$PCHC = "HKCU:\SOFTWARE\Microsoft\PCHC"
if (-not (Test-Path $PCHC)) { New-Item -Path $PCHC -Force | Out-Null }
Set-ItemProperty -Path $PCHC -Name "UpgradeEligibility" -Value 1 -Type DWord

# LabConfig bypasses (system-wide)
$LabConfig = "HKLM:\SYSTEM\Setup\LabConfig"
if (-not (Test-Path $LabConfig)) { New-Item -Path $LabConfig -Force | Out-Null }
Set-ItemProperty -Path $LabConfig -Name "BypassRAMCheck" -Value 1 -Type DWord
Set-ItemProperty -Path $LabConfig -Name "BypassSecureBootCheck" -Value 1 -Type DWord
Set-ItemProperty -Path $LabConfig -Name "BypassTPMCheck" -Value 1 -Type DWord
Set-ItemProperty -Path $LabConfig -Name "BypassStorageCheck" -Value 1 -Type DWord

Write-Output "Windows 11 upgrade bypass registry keys configured successfully"

### Execute silent upgrade
Write-Output "[$(Get-Date)] Starting silent upgrade..."
$setupPath = Join-Path -Path $driveLetter -ChildPath "setup.exe"

##########################################
#Test Command, not silent and will reboot#
##########################################
#$UpgradeCommand = "$setupPath /auto upgrade /Eula Accept /Dynamicupdate Disable /product server"

##########################################
# Production Command, silent and noreboot#
##########################################
#$UpgradeCommand = "$setupPath /auto upgrade /Eula Accept /Dynamicupdate Disable /product server /Quiet /noreboot"

Start-Process -FilePath "cmd.exe" -ArgumentList "/c $UpgradeCommand" -PassThru -NoNewWindow -Wait

Write-Output "[$(Get-Date)] Upgrade to Windows 11 initiated. System will reboot automatically."
Write-Output "[$(Get-Date)] Upgrade vers Windows 11 lancée. Le système redémarrera tout seul"
Stop-Transcript
exit 0
Start-Sleep -s 7200
exit 0
