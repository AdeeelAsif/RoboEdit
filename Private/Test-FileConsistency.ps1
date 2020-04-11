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

    $Content = try {
        
        Get-Content $Path -ErrorAction Stop
        [bool]$FileContentException = $false
    }
    catch {

        [bool]$FileContentException = $true

    }

    if ($FileContentException -eq $true) {

        $ReturnExceptionContext = $StringToReplace | ForEach-Object {

            [PSCustomObject]@{
                Server              = $Server
                Path                = $Path
                Lot                 = $Lot
                StringToReplace     = $_.Replace('\\', '\')
                FileConsistencyTest = [PSCustomObject]@{
                    Name   = $_.Replace('\\', '\')
                    Result = "Failed"
                }
            }
        }

        Return $ReturnExceptionContext

    }


    $StringToReplace | ForEach-Object {

        if ([bool]($content -match $_) -eq $true) {

            [PSCustomObject]@{
                Server              = $Server
                Path                = $Path
                Lot                 = $Lot
                FileConsistencyTest = [PSCustomObject]@{
                    Name   = $_.Replace('\\', '\')
                    Result = "Passed"
                }
            }
        }
        else {

            [PSCustomObject]@{
                Server              = $Server
                Path                = $Path
                Lot                 = $Lot
                StringToReplace     = $_.Replace('\\', '\')
                FileConsistencyTest = [PSCustomObject]@{
                    Name   = $_.Replace('\\', '\')
                    Result = "Failed"
                }
            }
        }
    }
}