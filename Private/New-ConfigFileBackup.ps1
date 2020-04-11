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
    $Date = Get-Date -UFormat "%d-%m-%Y-%H%M-%m%S"
    $RootPath = "\\repository-fr.fd.fnac.dom\FDOPS-PublicShare\adeel\RoboEdit\$($Date)\$($Lot)"

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