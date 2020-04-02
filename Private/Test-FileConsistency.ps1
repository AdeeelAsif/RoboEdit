Function Test-FileConsistency {

    param (
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Server,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Lot,
        
        [Parameter(Mandatory = $true)]
        [string[]]$StringToReplace,

        [Parameter(Mandatory = $true)]
        [string]$NewString

    )

    $Content = Get-Content $Path 
    $StringToReplace | ForEach-Object {

        if ([bool]($content -match $_) -eq $true) {

            [PSCustomObject]@{
                Server              = $Server
                #FileConsistency     = $true
                Path                = $Path
                Lot                 = $Lot
                #   Newstring       = $NewString
                FileConsistencyTest = [PSCustomObject]@{
                    Name   = $_.Replace('\\', '\')
                    Result = "Passed"
                }
            }
        }
        else {

            [PSCustomObject]@{
                Server              = $Server
                #  FileConsistency     = $false
                Path                = $Path
                Lot                 = $Lot
                StringToReplace     = $_.Replace('\\', '\')
                #    Newstring       = $NewString
                FileConsistencyTest = [PSCustomObject]@{
                    Name   = $_.Replace('\\', '\')
                    Result = "Failed"
                }
            }
        }
    }
}