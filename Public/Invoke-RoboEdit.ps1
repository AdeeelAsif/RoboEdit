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
        [string[]]$StringToReplace,

        [Parameter(Mandatory = $true)]
        [string]$NewString,

        [Parameter(Mandatory = $true)]
        [int]$TargetPort,

        [Parameter(Mandatory = $true)]
        [string]$TargetHost
    )

    Write-Verbose "Execution mode is $($Mode)"

    Switch ($Mode) {

        { $_ -eq "Deploy" } {

            $i = 1 
            $DeployResult = @()
            $File = Import-File -Path $Path -Lot $Lot -FileType $FileType 

            $TcpResponseObject = $File.Server | Select-Object -Unique | ForEach-Object {

                [PSCustomObject]@{
                    Result = $(Test-TcpResponse -ComputerName $_ -TargetHost $TargetHost -TargetPort $TargetPort)
                    Server = $_
                }    
            }
            
            $File | ForEach-Object {

                $PercentComplete = (($i / $_.ObjectCount) * 100)
                $TcpServerName = $_.Server
                Write-Progress -Activity "Config File" -Status "File $i of $($_.ObjectCount)" -PercentComplete $PercentComplete -CurrentOperation $_.Path

                $DeployResult += [PSCustomObject]@{

                    Server              = $_.Server
                    Path                = $_.Path
                    FileName            = $_.Name
                    FileExistence       = (Test-Path $_.Path)
                    FileConsistencyTest = (Test-FileConsistency -Server $_.Server -Path $_.Path -Lot $_.Lot -StringToReplace $StringToReplace -NewString $NewString).FileConsistencyTest
                    TestTCPConnection   = $($TcpResponseObject | Where-Object { $_.Server -eq $TcpServerName } | Select-Object -ExpandProperty Result)
                    TargetHost          = $TargetHost 
                    TargetPort          = $TargetPort
                    TargetString        = $NewString
                    Lot                 = $_.Lot
                    BackupSequence      = "$($_.Server)\$($i)"
                    RestorePath         = $_.RestorePath
                }
               
                $i++
            }
            
            
            #  New-ConfigFileBackup -Path $DeployResult.Path -FileName $DeployResult.FileName -Server $DeployResult.Server -Lot $Lot -RestorePath $DeployResult.RestorePath -BackupSequence $DeployResult.BackupSequence    
            $DeployResult
        }

        { $_ -eq "Rollback" } {

        }
        
        { $_ -eq "Test" } {

            $i = 1 
            $TestResult = @()
            $File = Import-File -Path $Path -Lot $Lot -FileType $FileType 

            $TcpResponseObject = $File.Server | Select-Object -Unique | ForEach-Object {

                [PSCustomObject]@{
                    Result = $(Test-TcpResponse -ComputerName $_ -TargetHost $TargetHost -TargetPort $TargetPort)
                    Server = $_
                }    
            }
            
            $File | ForEach-Object {

                $PercentComplete = (($i / $_.ObjectCount) * 100)
                $TcpServerName = $_.Server
                Write-Progress -Activity "Config File" -Status "File $i of $($_.ObjectCount)" -PercentComplete $PercentComplete -CurrentOperation $_.Path

                $TestResult += [PSCustomObject]@{

                    Server              = $_.Server
                    Path                = $_.Path
                    FileName            = $_.Name
                    FileExistence       = (Test-Path $_.Path)
                    FileConsistencyTest = (Test-FileConsistency -Server $_.Server -Path $_.Path -Lot $_.Lot -StringToReplace $StringToReplace -NewString $NewString).FileConsistencyTest
                    TestTCPConnection   = $($TcpResponseObject | Where-Object { $_.Server -eq $TcpServerName } | Select-Object -ExpandProperty Result)
                    TargetHost          = $TargetHost 
                    TargetPort          = $TargetPort
                    TargetString        = $NewString
                    Lot                 = $_.Lot
                    BackupSequence      = "$($_.Server)\$($i)"
                    RestorePath         = $_.RestorePath
                }
               
                $i++
            }
                
            $TestResult

        }
    }
}