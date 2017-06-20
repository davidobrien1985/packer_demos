function Set-WindowsUpdates {
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]
    Param(
        [Parameter(Mandatory=$false,
                   ValueFromPipeLine=$true,
                   ValueFromPipeLineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullorEmpty()]
        [String[]]$ComputerName = "$env:COMPUTERNAME",

        [Parameter(Mandatory=$false,
                   Position=1)]
        [ValidateSet("NoCheck","CheckOnly","DownloadOnly","Install")]
        [String[]]$Options = "Install"
    )

    $k = 0
    switch ($Options) {
        "NoCheck"      { $AuOptions = 1; $Op = "Never check for updates" }
        "CheckOnly"    { $AuOptions = 2; $Op = "Check for updates but let me choose wether to download and install them" }
        "DownloadOnly" { $AuOptions = 3; $Op = "Download updates but let me choose whether to install them" }
        "Install"      { $AuOptions = 4; $Op = "Install updates automatically" }
    }
    $Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"

    try {
        Set-ItemProperty -Path $Key -Name "AUOptions" -Value $AuOptions -Force -Confirm:$false
        Set-ItemProperty -Path $Key -Name "CachedAUOptions" -Value $AuOptions -Force -Confirm:$false

        Write-Output "Windows Automatic Updates has been set to '$Op'"
    } catch {
        Write-Warning "Failed to set Windows Automatic Updates on computer '$Computer'"
    }
}

# Enable windows update
Set-WindowsUpdates -Options Install

# WindowsUpdate PowerShell module
Write-Host "Installing windows update PowerShell module..."
Copy-Item C:\\Windows\\Temp\\PSWindowsUpdate "$PSHome\Modules" -Recurse -Force

Write-Host "Check if module installed properly..."
Get-Module PSWindowsUpdate -ListAvailable

# Register Scheduled Task for triggering windows updates
Write-Host "Creating a scheduled task..."

$arguments = "-NoProfile -NoLogo -NonInteractive -File C:\\Packer\\Install-SoftwareElevated.ps1"
$action = New-ScheduledTaskAction -Execute "powershell" -Argument $arguments
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date)
$settings = New-ScheduledTaskSettingsSet
$principal = New-ScheduledTaskPrincipal -RunLevel Highest -UserId "$env:COMPUTERNAME\Administrator" -LogonType S4U
$task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal

Write-Host "Registering scheduled task for installing software under elevated permission..."
Register-ScheduledTask TriggerSoftwareInstallation -InputObject $task
