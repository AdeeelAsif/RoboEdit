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

            Import-File -Path $Path -Lot $Lot -FileType $FileType | ForEach-Object {

                $PercentComplete = (($i / $_.ObjectCount) * 100)

                Write-Progress -Activity "Config File" -Status "File $i of $($_.ObjectCount)" -PercentComplete $PercentComplete -CurrentOperation $_.Path

                $DeployResult += [PSCustomObject]@{

                    Server              = $_.Server
                    Path                = $_.Path
                    FileName            = $_.Name
                    FileExistence       = (Test-Path $_.Path)
                    FileConsistencyTest = (Test-FileConsistency -Server $_.Server -Path $_.Path -Lot $_.Lot -StringToReplace $StringToReplace -NewString $NewString).FileConsistencyTest
                    TestTCPConnection   = $(Test-TcpResponse -ComputerName $_.Server -TargetHost $TargetHost -TargetPort $TargetPort) 
                    TargetHost          = $TargetHost 
                    TargetPort          = $TargetPort
                    TargetString        = $NewString
                    AssociatedServer    = $(Get-ServerList -ServerName $_.Server)
                    Lot                 = $_.Lot
                    BackupSequence      = "$($_.Server)\$($i)"
                    RestorePath         = $_.RestorePath
                }
               
                $i++
            }
            
            
            New-ConfigFileBackup -Path $DeployResult.Path -FileName $DeployResult.FileName -Server $DeployResult.Server -Lot 1 -RestorePath $DeployResult.RestorePath -BackupSequence $DeployResult.BackupSequence    
            $DeployResult
        }

        { $_ -eq "Rollback" } {

        }
        
        { $_ -eq "Test" } {

        }
    }
}