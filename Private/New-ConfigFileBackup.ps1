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
    Write-Verbose "Root path for backup is : $($Config.BackupPath)\$($Lot) "
    $RootPath = "$($Config.BackupPath)\$($Lot)"

    [void](New-Item -Type Directory -Path $RootPath)

    for ($i = 0; $i -lt $Path.Count; $i++) {
        
        if ((Test-Path "$($Path[$i])")) {

            Write-Verbose "Backup $($Path[$i])"
            [void](New-Item -Type Directory -Path "$($RootPath)\$($BackupSequence[$i])")
            Copy-Item "$($Path[$i])" -Destination "$($RootPath)\$($BackupSequence[$i])"

            $Report += [PSCustomObject]@{
                Server      = $Server[$i]
                #FileName    = $FileName[$i]
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
}