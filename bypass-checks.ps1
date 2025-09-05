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
