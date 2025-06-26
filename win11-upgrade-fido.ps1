# Check if we are on Windows 10, ensure the script is not launching on any other OS
$osInfo = Get-ComputerInfo -Property WindowsProductName, OsVersion
if ($osInfo.WindowsProductName -like "*Windows 10*") {
    Write-Host "This is Windows 10. Proceeding..."
    Write-Host "Upgrade to Windows 11 ongoing / doesn't reboot your computer - Mise à jour vers Windows 11 en cours / ne redémarrez pas votre ordinateur"
} else {
    Write-Host "This script only runs on Windows 10."
    exit
}

# Ensure Temp directory exists or create it
New-Item -Path "C:\Temp" -ItemType Directory -Force -ErrorAction SilentlyContinue
cd "C:\Temp"

# Log the current powershell session
Start-Transcript -Path "C:\Temp\win11upgrade.log"

####################
### ISO DOWNLOAD ###
####################

# Get current system information
$systemLocale = (Get-WinSystemLocale).Name
$windowsEdition = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name EditionID).EditionID

# Map locale to FIDO language string
$languageMap = @{
    "en-US" = "English International"
    "en-GB" = "English"
    "de-DE" = "German"
    "fr-FR" = "French"
    "es-ES" = "Spanish"
    "it-IT" = "Italian"
    "nl-NL" = "Dutch"
    "pt-BR" = "Portuguese (Brazil)"
    "ja-JP" = "Japanese"
    "ko-KR" = "Korean"
    "zh-CN" = "Chinese (Simplified)"
    "zh-TW" = "Chinese (Traditional)"
    "ru-RU" = "Russian"
}

# Map edition to FIDO edition string
$editionMap = @{
    "Professional" = "Pro"
    "ProfessionalWorkstation" = "Pro"
    "Home" = "Home"
    "Education" = "Education"
    "Enterprise" = "Enterprise"
    "ProfessionalEducation" = "Education"
}

# Lookup in hashtable
$fidoEdition = $editionMap[$windowsEdition]
$systemLocale = (Get-WinSystemLocale).Name
$fidoLanguage = $LanguageMap[$systemLocale]


# Download FIDO script
$fidoPath = "C:\Temp\Fido.ps1"
if (-not (Test-Path $fidoPath)) {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pbatard/Fido/refs/heads/master/Fido.ps1" -OutFile $fidoPath
}

# Run FIDO to download matching ISO
Write-Host "Downloading Windows 11 ISO for $fidoEdition edition in $fidoLanguage..."
PowerShell -ExecutionPolicy Bypass -File $fidoPath -Win 11 -Rel Latest -Ed $fidoEdition -Lang $fidoLanguage -Arch x64

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

Start-Process -FilePath "cmd.exe" -ArgumentList "/c $UpgradeCommand" -PassThru -NoNewWindow

Write-Output "[$(Get-Date)] Upgrade initiated. System may reboot automatically."

Stop-Transcript
exit 0
