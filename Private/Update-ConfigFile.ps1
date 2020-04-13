Function Update-ConfigFile {

    param (
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Path,

        [Parameter(Mandatory = $true)]
        [string]$StringToReplace,

        [Parameter(Mandatory = $true)]
        [string]$NewString,

        [Parameter(Mandatory = $true)]
        [int]$lot

    )    

    $i = 0
    $UpdatedFileReport = @()
    
    foreach ($FilePath in $Path) {
     
        $PercentComplete = (($i / $Path.count) * 100)
        Write-Progress -Activity "Modifying config files" -Status "$(([math]::Round($PercentComplete)))%" `
            -PercentComplete $PercentComplete -CurrentOperation "Modifying $($FilePath)"

        $Content = [System.IO.File]::ReadAllText($FilePath)
        $Content = $Content.Replace($StringToReplace, $NewString)

        Try {

            [System.IO.File]::WriteAllText($FilePath, $Content)

            $UpdatedFileReport += [PSCustomObject]@{
                FilePath  = $FilePath
                OldString = $StringToReplace
                NewString = $NewString
                Status    = "Done"
            }
        }
        catch {

            $UpdatedFileReport += [PSCustomObject]@{
                FilePath  = $FilePath
                OldString = $StringToReplace
                NewString = $NewString
                Status    = "Failed"
            }
        }

        $i++
    }

    $SuccessCount = ($UpdatedFileReport | Where-Object { $_.Status -eq "Done" }).count
    $FailedCount = ($UpdatedFileReport | Where-Object { $_.Status -eq "Failed" }).count
    Write-Verbose "Total successfully modified files : $($SuccessCount)"
    Write-Verbose "Total failed modified files : $($FailedCount)"
    $UpdatedFileReport | ConvertTo-Csv -NoTypeInformation -Delimiter ";" | Out-File "$($Config.FinalReportPath)\UpdatedFilesReport_lot_$($lot).csv"
}