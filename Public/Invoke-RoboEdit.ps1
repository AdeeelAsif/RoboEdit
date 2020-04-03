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

            Import-File -Path $Path -Lot $Lot -FileType $FileType | ForEach-Object {

                [PSCustomObject]@{
                    Server              = $_.Server
                    Path                = $_.Path
                    FileExistence       = (Test-Path $_.Path)
                    FileConsistencyTest = (Test-FileConsistency -Server $_.Server -Path $_.Path -Lot $_.Lot -StringToReplace $StringToReplace -NewString $NewString).FileConsistencyTest
                    TestTCPConnection   = (Invoke-Command -ComputerName $_.Server -ScriptBlock ${Function:Test-TCPResponse} -ArgumentList $TargetHost, $TargetPort) | Select-Object IsOpen
                    TargetHost          = $TargetHost 
                    TargetPort          = $TargetPort
                    Lot                 = $_.Lot
                }                
            } 
        }

        { $_ -eq "Rollback" } {

        }
        
        { $_ -eq "Test" } {

        }
    }
}