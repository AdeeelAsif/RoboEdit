$Metadata = @{

    'Date' = $(Get-Date -UFormat "%Y%d%m%H%M%S")
}

#Declare here the servers category
$ServersType = @("WPFWEBFD", "WPWEBFR", "FCXAWPWSFRONT", "FCXAWPWSBACK", "WPWEBSHOP", "TASK1", "FCXSVC", "WPETL", "FCXAWOEXPLOIT")

#If Debug Enabled is set to $true then debug files are generated 
$DebugEnabled = $true

$Config = @{ 
    
    'userdesktoppath'    = $([Environment]::ExpandEnvironmentVariables("C:\Users\%Username%\desktop\RoboEdit\$($metadata.date)"))
    'Debuglogspath'      = $([Environment]::ExpandEnvironmentVariables("C:\Users\%Username%\desktop\RoboEdit\$($metadata.date)\debug"))
    'TestReportPath'     = $([Environment]::ExpandEnvironmentVariables("C:\Users\%Username%\desktop\RoboEdit\$($metadata.date)"))
    'EligibleReportPath' = $([Environment]::ExpandEnvironmentVariables("C:\Users\%Username%\desktop\RoboEdit\$($metadata.date)"))
    'FinalReportPath'    = $([Environment]::ExpandEnvironmentVariables("C:\Users\%Username%\desktop\RoboEdit\$($metadata.date)"))
    'BackupPath'         = $([Environment]::ExpandEnvironmentVariables("C:\Users\%Username%\desktop\RoboEdit\$($metadata.date)\backup"))
   
}

ForEach ($Configuration in $config.keys) { 

    if (!(Test-Path $Config.$Configuration)) {
    
        [void](New-Item -ItemType Directory -Path $Config.$Configuration)

    }
}