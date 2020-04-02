Function Invoke-RoboEdit {

    Param(

        [Parameter(Mandatory = $True,
            ValueFromPipeline = $True)]
        [string]$Path,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $True)]
        [int]$Lot,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Json', 'Csv', 'Xml')]
        [string]$FileType,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Deploy', 'Rollback', 'Test')]
        [string]$Mode

    )

    Write-Verbose "Execution mode is $($Mode)"

    Switch ($Mode) {

        { $_ -eq "Deploy" } {

            $File = Import-File -Path $Path -Lot $Lot -FileType $FileType 
            $File | Convertto-json | Out-File c:\temp\debug.json
            $File.Server | ForEach-Object {

                $Server = $_
                $Lot = $File.Lot | Select-Object -unique
                ($File | Where-Object { $_.Server -eq $Server }).Path | ForEach-Object {

                    Test-FileExistence -Server $Server -Path $_ -Lot $Lot

                }
            }
        }

        { $_ -eq "Rollback" } {

            <#Test#>

        }

        
        { $_ -eq "Test" } {

            Import-File -Path $Path -Lot $Lot -FileType $FileType

        }
    }
}