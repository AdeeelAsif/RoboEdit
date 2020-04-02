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
        [string]$Mode,

        [Parameter(Mandatory = $true)]
        [string[]]$StringToReplace,

        [Parameter(Mandatory = $true)]
        [string]$NewString

    )

    Write-Verbose "Execution mode is $($Mode)"

    Switch ($Mode) {

        { $_ -eq "Deploy" } {

            Import-File -Path $Path -Lot $Lot -FileType $FileType | ForEach-Object {

                #    Test-FileExistence -Server $_.Server -Path $_.Path -Lot $_.Lot

                Test-FileConsistency -Server $_.Server -Path $_.Path -Lot $_.Lot -StringToReplace $StringToReplace -NewString $NewString

            } | Sort-Object FileConsistencyTest | Ft

        }


        { $_ -eq "Rollback" } {

            <#Test#>

        }

        
        { $_ -eq "Test" } {

            Import-File -Path $Path -Lot $Lot -FileType $FileType

        }
    }
}