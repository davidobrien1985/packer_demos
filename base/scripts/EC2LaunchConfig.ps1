$launchConfig = Get-Content -Path C:\ProgramData\Amazon\EC2-Windows\Launch\Config\LaunchConfig.json | ConvertFrom-Json
$launchConfig.adminPasswordType = 'Random'
$launchConfig

Set-Content -Value ($launchConfig | ConvertTo-Json) -Path C:\ProgramData\Amazon\EC2-Windows\Launch\Config\LaunchConfig.json
