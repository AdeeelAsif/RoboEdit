Function New-ConfigFileBackup {

    Param(

        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string[]]$Path,

        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string[]]$Name,

        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string[]]$Server,

        [Parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [int]$Lot

    )

    Function Test-ConfigFilePath {

        param(

            [Parameter(Mandatory = $true)]        
            [string]$FilePath
        )

        if (!(Test-Path $FilePath)) {

            New-Item -ItemType Directory -Path $FilePath
        }
    }

    $Date = Get-Date -UFormat "%d-%m-%Y-%H%M"
    $Report = @()

    $Path | ForEach-Object {

        $Path = $_

        $Server | ForEach-Object {

            $ServerName = $_

            $FullPath = "\\repository-fr.fd.fnac.dom\FDOPS-PublicShare\adeel\RoboEdit\$($Date)\$($Lot)\$($ServerName)"
            #$LotPath = "\\repository-fr.fd.fnac.dom\FDOPS-PublicShare\adeel\RoboEdit\$($Date)\$($Lot)"

            #Test-ConfigFilePath  $LotPath 
            Test-ConfigFilePath $FullPath

            $Name | ForEach-Object {
    
                Copy-Item $Path "\\repository-fr.fd.fnac.dom\FDOPS-PublicShare\adeel\RoboEdit\$($Date)\$($Lot)\$($ServerName)\"
                $Report += [PSCustomObject]@{
                    Server     = $ServerName
                    FileName   = $_
                    BackupPath = "\\repository-fr.fd.fnac.dom\FDOPS-PublicShare\adeel\RoboEdit\$($Date)\$($Lot)\$($_)\$($FileName))"
                    Lot        = $lot
                    Timestamp  = (Get-Date -format o)
                } 
            }
        }
    }

    $Report | ConvertTo-Json | Out-File \\repository-fr.fd.fnac.dom\FDOPS-PublicShare\adeel\RoboEdit\$($Date)\$($Lot)\BackupReport.json
}