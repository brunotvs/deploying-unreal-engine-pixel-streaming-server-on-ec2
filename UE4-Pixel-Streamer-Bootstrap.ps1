<#

.SYNOPSIS
Script to automate setup of environment and download of exported project. Streamer launched from StartPixelStreaming.ps1 file in project automatically.

.DESCRIPTION

.NOTES
You will need to modify the $buildExecutable variable below to match the file name for your executable in your build.

.LINK

#>

$buildExecutable = "Holus.exe"
$basePath = "C:\PixelStreamer\Downloads"

Write-Output "Starting UE-Pixel-Streamer-Bootstrap.ps1 from:", $basePath

# Create basePath if unless it already exists.
if (!(Test-Path -Path $basePath )) {
    New-Item -ItemType directory -Path $basePath
}

Write-Output "Installing Node.js"
Invoke-WebRequest -Uri "https://nodejs.org/dist/v12.8.1/node-v12.8.1-x64.msi" -OutFile "$basePath\node-v12.8.1-x64.msi"
Start-Process -FilePath "$basePath\node-v12.8.1-x64.msi" -ArgumentList "/quiet" -Wait
$env:Path += ";C:\Program Files\nodejs\;C:\Users\Administrator\AppData\Roaming\npm"
Write-Output "Node.js Installed"

Write-Output "Adding Windows Firewall Rules for UE Pixel Streaming"
New-NetFirewallRule -DisplayName 'UE Pixel Streamer' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 80
New-NetFirewallRule -DisplayName 'UE Pixel Streamer' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 443
New-NetFirewallRule -DisplayName 'UE Pixel Streamer' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 19302-19303
New-NetFirewallRule -DisplayName 'UE Pixel Streamer' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8888
New-NetFirewallRule -DisplayName 'UE Pixel Streamer' -Direction Inbound -Action Allow -Protocol UDP -LocalPort 8888
New-NetFirewallRule -DisplayName 'UE Pixel Streamer' -Direction Inbound -Action Allow -Protocol UDP -LocalPort 19302-19303
Write-Output "Windows Firewall Rules Added for UE Pixel Streaming"

Write-Output "Beginning UE Project Extraction"
Expand-Archive -Force -LiteralPath "$basePath\PixelStreamerProject.zip" -DestinationPath C:\PixelStreamer
Write-Output "UE Project Downloaded and Extracted"

Write-Output "Install UE Prerequisites"
Install-WindowsFeature NET-Framework-Core
Start-Process -FilePath "C:\PixelStreamer\Windows\Engine\Extras\Redist\en-us\UEPrereqSetup_x64.exe" -ArgumentList "/passive /quiet /norestart /log C:\PixelStreamer\Windows\Engine\Extras\Redist\en-us\UEPreReqInstall.log" -Wait
Write-Output "UE Prerequisites Installed"

# Run Pixel Streamer as SYSTEM and on startup
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$action = New-ScheduledTaskAction -Execute "C:\PixelStreamer\Windows\$buildExecutable" -Argument "-PixelStreamingIP=localhost -PixelStreamingPort=8888 -RenderOffScreen"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -TaskName "UEPixelStreamer-Project-Launch" -Description "UEPixelStreamer-Project-Launch"

$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "C:\PixelStreamer\Windows\Samples\PixelStreaming\WebServers\SignallingWebServer\platform_scripts\cmd\Start_SignallingServer.ps1"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -TaskName "UEPixelStreamer-SignallingServer-Launch" -Description "UEPixelStreamer-SignallingServer-Launch"

Write-Output "UE-Pixel-Streamer-Bootstrap.ps1 Complete"
