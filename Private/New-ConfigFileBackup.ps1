Function New-ConfigFileBackup {


    Param(

        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string[]]$File,

        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string[]]$Server,

        [Parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [int]$Lot


    )


    $Date = Get-Date -UFormat "%d-%m-%Y-%H%M"
    New-Item -ItemType Directory -Path \\repository-fr.fd.fnac.dom\FDOPS-PublicShare\adeel\RoboEdit\$($Date)\$($Lot)
    $Report = @()

    $File | ForEach-Object {

        $FileName = $_

        $Server | ForEach-Object {

            Copy-Item $FileName -Destination \\repository-fr.fd.fnac.dom\FDOPS-PublicShare\adeel\RoboEdit\$($Date)\$($Lot)\$($_)\

            $Report += [PSCustomObject]@{
                Server     = $_
                BackupPath = $(\\repository-fr.fd.fnac.dom\FDOPS-PublicShare\adeel\RoboEdit\$($Date)\$($Lot)\$($_)\$($FileName))
                Lot        = $lot
            }
        }
    }

    $Report | ConvertTo-Json | Out-File \\repository-fr.fd.fnac.dom\FDOPS-PublicShare\adeel\RoboEdit\$($Date)\$($Lot)\BackupReport.json
}