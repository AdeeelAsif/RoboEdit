Function Test-FileConsistency {

    param (
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Server,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Lot,
        
        [Parameter(Mandatory = $true)]
        [string]$StringToReplace,

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

        $Exception = [PSCustomObject]@{
            Server              = $Server
            Path                = $Path
            Lot                 = $Lot
            StringToReplace     = $StringToReplace.Replace('\\', '\')
            FileConsistencyTest = [PSCustomObject]@{
                Name   = $StringToReplace.Replace('\\', '\')
                Result = "Failed"
            }
        }

        Return $Exception
    }

    if ([bool]($content -match $StringToReplace) -eq $true) {

        [PSCustomObject]@{
            Server              = $Server
            Path                = $Path
            Lot                 = $Lot
            StringToReplace     = $StringToReplace.Replace('\\', '\')
            FileConsistencyTest = [PSCustomObject]@{
                Name   = $StringToReplace.Replace('\\', '\')
                Result = "Passed"
            }
        }
    }
    else {

        [PSCustomObject]@{
            Server              = $Server
            Path                = $Path
            Lot                 = $Lot
            StringToReplace     = $StringToReplace.Replace('\\', '\')
            FileConsistencyTest = [PSCustomObject]@{
                Name   = $StringToReplace.Replace('\\', '\')
                Result = "Failed"
            }
        }
    }
}