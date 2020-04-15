Function Invoke-RoboEdit {

    Param(

        [Parameter(Mandatory = $false)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [int]$Lot,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Deploy', 'Rollback', 'Test')]
        [string]$Mode,

        [Parameter(Mandatory = $false)]
        [string]$StringToReplace,

        [Parameter(Mandatory = $false)]
        [string]$NewString,

        [Parameter(Mandatory = $false)]
        [int]$TargetPort,

        [Parameter(Mandatory = $false)]
        [string]$TargetHost,

        [Parameter(Mandatory = $false)]
        [ValidateScript( { Test-Path $_ })]
        [ValidateNotNullOrEmpty()]
        [String]$BackupHistoryFile 

    )

    Invoke-RoboEditConfiguration
    Write-Verbose "Hello $env:USERNAME!"
    Write-verbose "Date is $($Metadata.Date)"
    Write-Verbose "Execution mode is $($Mode)"
    Write-Verbose "Debug is set to : $($DebugEnabled)"
    Write-Verbose "Root folder for reports, debug, logs, backup is $($Config.userdesktoppath)"
    Write-Verbose "Backup path is : $($Config.BackupPath)"
    
    if (($Mode -eq "Deploy") -or ($Mode -eq "Test")) {

        try {
    
            $ResolveDnsName = Resolve-DnsName -Name $TargetHost -ErrorAction Stop -Verbose:$False
            Write-Verbose "$($TargetHost) DNS type is : $($ResolveDnsName.type)"
            Write-Verbose "$($TargetHost) IP address is : $($ResolveDnsName.IP4Address)"

            if ($ResolveDnsName.type -eq "CNAME") { 

                Write-Verbose "$($TargetHost) DNS NameHost is : $($ResolveDnsName.NameHost)"

            } 
        }
        catch {
    
            Write-Host $_.Exception.Message -ForegroundColor Red
            Return
        }
    
        $ImportObject = @()
        $File = Import-File -Path $Path -Lot $Lot
        $TotalHosts = ($File.Server | Select-Object -unique).Count
        Write-Verbose "Total host count : $($TotalHosts)"
        Write-verbose "Testing Winrm"
    
        $i = 1
        $z = 1
        $y = 1

        $TestWinRM = $File.Server | Select-Object -unique | ForEach-Object {

            $PercentComplete = (($i / $TotalHosts) * 100)
            Test-TCPResponse -ComputerName $($env:COMPUTERNAME) -TargetHost $_ -TargetPort 5985
            Write-Progress -Activity "Testing WinRM connectivity" -Status "$(([math]::Round($PercentComplete)))%" `
                -PercentComplete $PercentComplete -CurrentOperation "Testing target $($_) on port 5985 from $($env:COMPUTERNAME)"
            $i++

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

            $PercentComplete = (($z / $TotalHosts) * 100)

            [PSCustomObject]@{

                Result = $(Test-TcpResponse -ComputerName $_ -TargetHost $TargetHost -TargetPort $TargetPort).IsOpen
                Server = $_
            }
        
            Write-Progress -Activity "Testing TCP port $($Targetport)" -Status "$(([math]::Round($PercentComplete)))%" `
                -PercentComplete $PercentComplete -CurrentOperation "Testing target $($Targethost) on port $($Targetport) from $($_)"
            $z++

        }
    
        $File | ForEach-Object {

            $PercentComplete = (($y / $_.ObjectCount) * 100)
            $TcpServerName = $_.Server
            Write-Progress -Activity "Config File Scanning" -Status "File $y of $($_.ObjectCount)" -PercentComplete $PercentComplete -CurrentOperation $_.Path

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
                BackupSequence      = "$($_.Server)\$($y)"
                RestorePath         = $_.RestorePath
            }
       
            $y++
        }
    }

    Switch ($Mode) {

        { $_ -eq "Deploy" } {
            
            $EligibleObject = foreach ($item in $ImportObject) {

                if (($Item.FileExistence -eq $true) -and ($Item.FileConsistencyTest -eq "Passed") -and ($Item.TCPIsOpen -eq $true)) {

                    $Item
                }
            }

            Write-Verbose "Total eligible items : $($EligibleObject.path.count)" 

            if ($EligibleObject) {

                New-ConfigFileBackup -Path $EligibleObject.Path -FileName $EligibleObject.FileName -Server $EligibleObject.Server `
                    -Lot $Lot -RestorePath $EligibleObject.RestorePath -BackupSequence $EligibleObject.BackupSequence 

                $EligibleObject | ConvertTo-Csv -NoTypeInformation -Delimiter ";" | Out-File "$($Config.EligibleReportPath)\EligibleItemReport_lot$($lot).csv"
                
                Write-verbose "Eligible items report generated at : $($Config.EligibleReportPath)\EligibleItemReport_lot$($lot).csv"
                Write-Verbose "Starting files modification"
                
                Update-ConfigFile -Path $EligibleObject.Path -StringToReplace $StringToReplace -NewString $NewString -Lot $Lot
                
                Write-Verbose "Done"
                Write-Verbose "Files updated report generated at : $($Config.FinalReportPath)\UpdatedFilesReport_lot_$($lot).csv"

            }
            else {

                Write-Verbose "No items eligible : stop"
                Return
            }
        }

        { $_ -eq "Rollback" } {

            $RollbackJson = Get-Content $BackupHistoryFile
            $RollbackFile = $RollbackJson | ConvertFrom-Json 
            Write-Verbose "Number of files to rollback : $($RollbackFile.count)"

            foreach ($item in $RollbackFile) {
            
                Copy-Item $item.BackupPath -destination $item.restorepath
            
            }
            
            Write-Verbose "Rollback : done"
        }
        
        { $_ -eq "Test" } {

            $EligibleObject = foreach ($item in $ImportObject) {

                if (($Item.FileExistence -eq $true) -and ($Item.FileConsistencyTest -eq "Passed") -and ($Item.TCPIsOpen -eq $true)) {

                    $Item

                }
            }

            $ImportObject | ConvertTo-Csv -NoTypeInformation -Delimiter ";" | Out-File "$($Config.TestReportPath)\TestReport_lot$($lot).Csv"

            Write-Verbose "Tests report generated at : $($Config.TestReportPath)\TestReport_lot$($lot).Csv"

            if ($EligibleObject) {

                $EligibleObject | ConvertTo-Csv -NoTypeInformation -Delimiter ";" | Out-File "$($Config.EligibleReportPath)\EligibleItemReport_lot$($lot).csv"

                Write-verbose "Eligible items report generated at : $($Config.EligibleReportPath)\EligibleItemReport_lot$($lot).csv"

            }

            Write-host "Total items tested : $($ImportObject.Path.count)" -ForegroundColor Green
            Write-host "Total eligible items : $($EligibleObject.path.count)" -ForegroundColor green
        }
    }
}