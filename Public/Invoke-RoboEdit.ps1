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
    Write-Verbose "Backup path is : $($Config.BackupPath)"

    try {
    
        $ResolveDnsName = Resolve-DnsName -Name $TargetHost -ErrorAction Stop -Verbose:$False
        Write-Verbose "$($TargetHost) type is : $($ResolveDnsName.type)"
        Write-Verbose "$($TargetHost) IP address is : $($ResolveDnsName.IP4Address)"

        if ($ResolveDnsName.type -eq "CNAME") { 

            Write-Verbose "$($TargetHost) NameHost is : $($ResolveDnsName.NameHost)"

        } 
    }
    catch {
    
        Write-Host $_.Exception.Message -ForegroundColor Red
        Return
    }
    
    $ImportObject = @()
    $File = Import-File -Path $Path -Lot $Lot -FileType $FileType 
    $TotalHosts = ($File.Server | Select-Object -unique).Count

    Write-Verbose "Total host count : $($TotalHosts)"
    Write-verbose "Testing Winrm"
    
    $i = 1 
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

    $z = 1
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
    
    $y = 1
    $File | ForEach-Object {

        $PercentComplete = (($y / $_.ObjectCount) * 100)
        $TcpServerName = $_.Server
        Write-Progress -Activity "Config File" -Status "File $y of $($_.ObjectCount)" -PercentComplete $PercentComplete -CurrentOperation $_.Path

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

            Write-host "Total items tested : $($ImportObject.Path.count)" -ForegroundColor Green
            Write-host "Total eligible items : $($EligibleObject.path.count)" -ForegroundColor green

        }
    }
}