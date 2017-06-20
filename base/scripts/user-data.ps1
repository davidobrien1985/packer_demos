<powershell>

Set-ExecutionPolicy -ExecutionPolicy bypass -Force

Start-Transcript -path C:\UserDataTranscript.log

$scriptsPath = "c:\packer\scripts"
$dependencyPath = 'c:\packer\dependencies'
$powerShellModulePath = 'C:\Program Files\WindowsPowerShell\Modules\PSWindowsUpdate\'

$instanceId = (New-Object System.Net.WebClient).DownloadString("http://instance-data/latest/meta-data/instance-id")
$s3BucketTag =  Get-EC2Tag -Region ap-southeast-2 | Where-Object {$_.ResourceId -eq $instanceId -and $_.Key -eq 'DependencyS3BucketName'}
$s3BucketName = $s3BucketTag.Value

$az = (New-Object System.Net.WebClient).DownloadString("http://instance-data/latest/meta-data/placement/availability-zone")
$region = $az.Substring(0, $az.Length - 1)

Write-Output "Downloading dependencies from S3 bucket $s3BucketName."
Read-S3Object -BucketName $s3BucketName -KeyPrefix windows_soe/scripts -Folder $scriptsPath -Region $region
Read-S3Object -BucketName $s3BucketName -KeyPrefix windows_soe/PSWindowsUpdate -Folder $powerShellModulePath -Region $region
Unblock-File -Path "$scriptsPath\*.*"
Unblock-File -path "$dependencyPath\*.*"
Unblock-File -path "$powerShellModulePath\*.*"

#Write-Output "Disabling WinRM over HTTP..."
#Disable-NetFirewallRule -Name "WINRM-HTTP-In-TCP"
#Disable-NetFirewallRule -Name "WINRM-HTTP-In-TCP-PUBLIC"

#Start-Process -FilePath winrm `
#    -ArgumentList "delete winrm/config/listener?Address=*+Transport=HTTP" `
#    -NoNewWindow -Wait

Write-Output "Configuring WinRM for HTTPS..."
Start-Process -FilePath winrm `
    -ArgumentList "set winrm/config @{MaxTimeoutms=`"1800000`"}" `
    -NoNewWindow -Wait

Start-Process -FilePath winrm `
    -ArgumentList "set winrm/config/winrs @{MaxMemoryPerShellMB=`"1024`"}" `
    -NoNewWindow -Wait

Start-Process -FilePath winrm `
    -ArgumentList "set winrm/config/service @{AllowUnencrypted=`"false`"}" `
    -NoNewWindow -Wait

Start-Process -FilePath winrm `
    -ArgumentList "set winrm/config/service/auth @{Basic=`"true`"}" `
    -NoNewWindow -Wait

Start-Process -FilePath winrm `
    -ArgumentList "set winrm/config/service/auth @{CredSSP=`"true`"}" `
    -NoNewWindow -Wait

New-NetFirewallRule -Name "WINRM-HTTPS-In-TCP" `
    -DisplayName "Windows Remote Management (HTTPS-In)" `
    -Description "Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]" `
    -Group "Windows Remote Management" `
    -Program "System" `
    -Protocol TCP `
    -LocalPort "5986" `
    -Action Allow `
    -Profile Domain,Private

New-NetFirewallRule -Name "WINRM-HTTPS-In-TCP-PUBLIC" `
    -DisplayName "Windows Remote Management (HTTPS-In)" `
    -Description "Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]" `
    -Group "Windows Remote Management" `
    -Program "System" `
    -Protocol TCP `
    -LocalPort "5986" `
    -Action Allow `
    -Profile Public

$certContent = "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"

$certBytes = [System.Convert]::FromBase64String($certContent)
$pfx = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$pfx.Import($certBytes, "", "Exportable,PersistKeySet,MachineKeySet")
$certThumbprint = $pfx.Thumbprint
$certSubjectName = $pfx.SubjectName.Name.TrimStart("CN = ").Trim()

$store = new-object System.Security.Cryptography.X509Certificates.X509Store("My", "LocalMachine")
try {
    $store.Open("ReadWrite,MaxAllowed")
    $store.Add($pfx)

} finally {
    $store.Close()
}

Start-Process -FilePath winrm `
    -ArgumentList "create winrm/config/listener?Address=*+Transport=HTTPS @{Hostname=`"$certSubjectName`";CertificateThumbprint=`"$certThumbprint`";Port=`"5986`"}" `
    -NoNewWindow -Wait

# # Basic authentication has been disabled in the CIS image with a local
# # group policy. The policy writes to the registry key below so we can
# # temporarily edit the reg key to allow basic auth until the machine
# # is restarted.
# # We need to do this because there is no way to edit the local group
# # policy via the command line.
# & $scriptsPath\edit-reg-key.ps1 `
#     -RegistryPath "HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service\" `
#     -Key "AllowBasic" `
#     -Value "1" `
#     -Type DWORD

Write-Output "Restarting WinRM Service..."
Stop-Service winrm
Set-Service winrm -StartupType "Automatic"
Start-Service winrm

Stop-Transcript

</powershell>
