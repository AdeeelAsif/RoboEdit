RoboEdit (Robust Edit)
=============
Powershell solution for mass config file modification (Robust Edit).

### Three modes are available

* Test  
* Deploy   
* Rollback  

### Prerequisites
##### 1. Import the module 
```powershell
Import-Module .\RoboEdit.psm1  
```
##### 2. Check global variables inside RobotEdit.configuration.ps1
```powershell
$Config = @{ 
    
    'userdesktoppath'    = $([Environment]::ExpandEnvironmentVariables("C:\Users\%Username%\desktop\RoboEdit\$($metadata.date)"))
    'Debuglogspath'      = $([Environment]::ExpandEnvironmentVariables("C:\Users\%Username%\desktop\RoboEdit\$($metadata.date)\debug"))
    'TestReportPath'     = $([Environment]::ExpandEnvironmentVariables("C:\Users\%Username%\desktop\RoboEdit\$($metadata.date)"))
    'EligibleReportPath' = $([Environment]::ExpandEnvironmentVariables("C:\Users\%Username%\desktop\RoboEdit\$($metadata.date)"))
    'FinalReportPath'    = $([Environment]::ExpandEnvironmentVariables("C:\Users\%Username%\desktop\RoboEdit\$($metadata.date)"))
    'BackupPath'         = $([Environment]::ExpandEnvironmentVariables("C:\Users\%Username%\desktop\RoboEdit\$($metadata.date)\backup"))
   
}
```

### Examples

##### 1. Test mode

```powershell

Invoke-RoboEdit -Path C:\data\file.csv -Lot 1 -Mode Test -StringToReplace 'oldserver.domain.com,50018' -NewString "newserver.domain.com,50019" -TargetPort 50019 -TargetHost newserver.domain.com

```
##### 2. Deploy mode

```powershell

Invoke-RoboEdit -Path C:\data\file.csv -Lot 1 -Mode Deploy -StringToReplace 'oldserver.domain.com,50018' -NewString "newserver.domain.com,50019" -TargetPort 50019 -TargetHost newserver.domain.com

```

##### 3. Rollback mode

```powershell

Invoke-RoboEdit -Mode Rollback -BackupHistoryFile C:\Users\user1\Desktop\RoboEdit\20201404013207\backup\lot_1\BackupReport.json

```
##### 4. BulkEdit mode

```powershell

Invoke-RoboEdit -Mode Rollback -BackupHistoryFile C:\Users\user1\Desktop\RoboEdit\20201404013207\backup\lot_1\BackupReport.json

```