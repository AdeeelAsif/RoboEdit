Function Invoke-RoboEdit {

    Param(

        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string]$Path,

        [Parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [int]$Lot,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Json', 'Csv', 'Xml')]
        [string]$FileType,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Deploy', 'Rollback', 'Test')]
        [string]$Mode,

        [Parameter(Mandatory = $true)]
        [string]$StringToReplace,

        [Parameter(Mandatory = $true)]
        [string]$NewString,

        [Parameter(Mandatory = $true)]
        [int]$TargetPort,

        [Parameter(Mandatory = $true)]
        [string]$TargetHost
    )


    Write-Verbose "Hello $env:USERNAME!"
    Write-verbose "Date is $($Metadata.Date)"
    Write-Verbose "Execution mode is $($Mode)"
    Write-Verbose "Root folder for reports, debug, logs, backup is $($Config.userdesktoppath)"
    Write-Verbose "TestReportPath is $($Config.TestReportPath)"
    Write-Verbose "EligibleReportPath is $($Config.EligibleReportPath)"
    Write-Verbose "FinalReportPath is $($Config.FinalReportPath)"
    Write-Verbose "Debug logs path is $($Config.DebugLogsPath)"
    
    $i = 1 
    $ImportObject = @()
    $File = Import-File -Path $Path -Lot $Lot -FileType $FileType 
    $TotalHosts = ($File.Server | Select-Object -unique).Count

    Write-verbose "Testing Winrm"
    Write-Verbose "Total host count : $($TotalHosts)"

    $TestWinRM = $File.Server | Select-Object -unique | ForEach-Object {

        Test-TCPResponse -ComputerName $($env:COMPUTERNAME) -TargetHost $_ -TargetPort 5985

    }

    if ($TestWinRM.IsOpen -eq $false) {

        $WinRMFailedList = $TestWinRM | Select-Object IsOpen, ComputerName | Where-Object { $_.IsOpen -eq $false }
        Write-Host "WinRM connection failed $($WinRMFailedList.ComputerName -join ",")" -ForegroundColor Red
        Return

    }
    else {

        Write-verbose "WinRM test passed for $($TestWinRM.ComputerName -join ",")"

    }

    $TcpResponseObject = $File.Server | Select-Object -Unique | ForEach-Object {

        [PSCustomObject]@{
            Result = $(Test-TcpResponse -ComputerName $_ -TargetHost $TargetHost -TargetPort $TargetPort).IsOpen
            Server = $_
        }    
    }
    
    $File | ForEach-Object {

        $PercentComplete = (($i / $_.ObjectCount) * 100)
        $TcpServerName = $_.Server
        Write-Progress -Activity "Config File" -Status "File $i of $($_.ObjectCount)" -PercentComplete $PercentComplete -CurrentOperation $_.Path

        $ImportObject += [PSCustomObject]@{

            Server              = $_.Server
            Path                = $_.Path
            FileName            = $_.Name
            FileExistence       = (Test-Path $_.Path)
            StringChecked       = $StringToReplace
            FileConsistencyTest = (Test-FileConsistency -Server $_.Server -Path $_.Path -Lot $_.Lot -StringToReplace $StringToReplace -NewString $NewString).FileConsistencyTest.Result
            TCPIsOpen           = $($TcpResponseObject | Where-Object { $_.Server -eq $TcpServerName } | Select-Object -ExpandProperty Result)
            TargetHost          = $TargetHost 
            TargetPort          = $TargetPort
            TargetString        = $NewString
            Lot                 = $_.Lot
            BackupRootPath      = $Config.BackupPath
            BackupSequence      = "$($_.Server)\$($i)"
            RestorePath         = $_.RestorePath
        }
       
        $i++
    }
  
    Switch ($Mode) {

        { $_ -eq "Deploy" } {
            
            $ImportObject
            New-ConfigFileBackup -Path $ImportObject.Path -FileName $ImportObject.FileName -Server $ImportObject.Server -Lot $Lot -RestorePath $ImportObject.RestorePath -BackupSequence $ImportObject.BackupSequence 
        }

        { $_ -eq "Rollback" } {

            Write-host "Rollback"

        }
        
        { $_ -eq "Test" } {

            $EligibleObject = foreach ($item in $ImportObject) {

                if (($Item.FileExistence -eq $true) -and ($Item.FileConsistencyTest -eq "Passed") -and ($Item.TCPIsOpen -eq $true)) {

                    $Item

                }
            }

            $ImportObject | ConvertTo-Csv -NoTypeInformation -Delimiter ";" | Out-File "$($Config.TestReportPath)\TestReport_lot$($lot).Csv"

            if ($EligibleObject) {

                $EligibleObject | ConvertTo-Csv -NoTypeInformation -Delimiter ";" | Out-File "$($Config.EligibleReportPath)\EligibleItemReport_lot$($lot).csv"
            
            }

            Write-host "Total test count : $($ImportObject.Path.count)" -ForegroundColor Green
            Write-host "Total eligible item : $($EligibleObject.path.count)" -ForegroundColor green

        }
    }
}