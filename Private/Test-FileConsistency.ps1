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
                Hits   = 0
                Text   = "N/A"
            }
        }

        Return $Exception
    }
    
    try {
        
        [bool]($content -match $StringToReplace) 
    }
    catch [System.ArgumentException] {
    
        if (($_.Exception.Message -match "Unrecognized escape sequence") -or ($_.Exception.Message -match 'Malformed')) {

            $StringToReplace = $StringToReplace.Replace("\", "\\")
        }
    }
    catch { 

        $_.Exception
    }

    if ([bool]($content -match $StringToReplace) -eq $true) {

        $Text = [string]($content -match $StringToReplace)
        $Text = $Text.Replace(";", " ")

        [PSCustomObject]@{
            Server              = $Server
            Path                = $Path
            Lot                 = $Lot
            StringToReplace     = $StringToReplace.Replace('\\', '\')
            FileConsistencyTest = [PSCustomObject]@{

                Name   = $StringToReplace.Replace('\\', '\')
                Result = "Passed"
                Hits   = ($Content -match $StringToReplace).count
                Text   = $Text.Trim()
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
                Hits   = ($Content -match $StringToReplace).count
                Text   = "N/A"
            }
        }
    }
}