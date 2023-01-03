#Prepare CCMSetup 
#Frank Maxwitat, 01-2023

$SiteCode = 'BA1'
$MP = 'IBB-SCCM'

$ccmInstall = @"
echo "Starting cmmsetup launcher script" | Out-File c:\windows\Logs\ccminstall.log
Start-Process $PSScriptRoot\ccmsetup.exe -ArgumentList "SMSSITECODE=$SiteCode /mp:$MP SMSMP=$MP" -wait
Start-Process SCHTASKS -ArgumentList '/DELETE /TN "TriggerCCMSetup" /F' -Wait
Remove-Item -Path C:\ccmsetup\* -Force -Recurse
Remove-Item -Path C:\ccmsetup -Force
echo "Ending cmmsetup launcher script" | Out-File c:\windows\Logs\ccminstall.log
"@

'Starting PrepareCCMSetup - Creating scheduled task v1.0.2' | Out-File 'C:\Windows\Logs\PrepareCCMSetup.log' -Append

$ClientSetupDir = 'c:\ccmsetup'

New-Item -ItemType Directory $ClientSetupDir
Attrib +h $ClientSetupDir

$Source = $PSScriptRoot + '\Client'
$Arg = $Source + ' ' + $ClientSetupDir + ' /MIR'
('Starting robocopy ' + $Arg) | Out-File 'C:\Windows\Logs\PrepareCCMSetup.log' -Append

Start-Process robocopy -ArgumentList $Arg -wait -PassThru

if((Test-Path -Path ($ClientSetupDir + '\ccmsetup.exe')) -eq $true){'Successfully filled ccmsetup directory' | Out-File 'C:\Windows\Logs\PrepareCCMSetup.log' -Append}

$ccmInstall | Out-File "$ClientSetupDir\ccminstall.ps1"

#Create a scheduled task
$triggers = @()

$taskname = 'TriggerCCMSetup'

$taskdescription = 'Run the script at startup. The script should delete this scheduled task'

$action = New-ScheduledTaskAction 'powershell.exe' -Argument ('-executionpolicy bypass -noprofile -file ' + $ClientSetupDir + '\ccminstall.ps1')

$Trigger1 = New-ScheduledTaskTrigger -AtStartup

$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 30) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 120)

$triggers += $Trigger1

Register-ScheduledTask -Action $action -Trigger $triggers -TaskName $taskname -Description $taskdescription -Settings $settings -User 'System' -RunLevel Highest

'Completed PrepareCCMSetup - Creating scheduled task' | Out-File 'C:\Windows\Logs\PrepareCCMSetup.log' -Append
