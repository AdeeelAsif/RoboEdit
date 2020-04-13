Function New-ConfigFileBackup {

    Param(

        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string[]]$Path,

        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string[]]$FileName,

        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string[]]$Server,

        [Parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [String[]]$BackupSequence,

        [Parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [String[]]$RestorePath,

        [Parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [int]$Lot

    )

    $Report = @()
    $RootPath = "$($Config.BackupPath)\lot_$($Lot)"

    [void](New-Item -Type Directory -Path $RootPath)

    for ($i = 0; $i -lt $Path.Count; $i++) {
        
        $PercentComplete = (($i / $Path.count) * 100)

        if ((Test-Path "$($Path[$i])")) {

            Write-Progress -Activity "Backup config files" -Status "$(([math]::Round($PercentComplete)))%" `
                -PercentComplete $PercentComplete -CurrentOperation "Backup $($Path[$i]) to $($RootPath)\$($BackupSequence[$i])"

            [void](New-Item -Type Directory -Path "$($RootPath)\$($BackupSequence[$i])")
            Copy-Item "$($Path[$i])" -Destination "$($RootPath)\$($BackupSequence[$i])"

            $Report += [PSCustomObject]@{

                Server      = $Server[$i]
                RestorePath = $RestorePath[$i]
                BackupPath  = "$($RootPath)\$($BackupSequence[$i])\$($FileName[$i])"
                Lot         = $lot
                Timestamp   = (Get-Date -format o)

            } 
        }
        else {

            Write-Verbose "Could not found file $($Path[$i])"
        }  
    }
    
    $Report | ConvertTo-Json | Out-File $RootPath\BackupReport.json
    Write-Verbose "Total backed up files : $($Report.server.count)"
    Write-Verbose "Backup report generated at : $($RootPath)\BackupReport.json"
}