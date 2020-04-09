Function Get-ServerList {

    Param (

        [parameter(mandatory = $true)]
        [string]$ServerName

    )

    $SQLHostname = "FCVSQL3CLSTR2\FD105OPS1,59081" 
    $Databasename = "NOLIO_DB"

    Function Get-NolioList {

        param (

            [String]$StringMatched

        )
        
        $Query = "SELECT Server_name FROM [NOLIO_DB].[dbo].[servers] WHERE server_name LIKE '%$($StringMatched)%'"

        [PSCustomObject]@{
            ServerList     = @(Invoke-Sqlcmd -ServerInstance $SQLHostname -Database $Databasename -Query $Query).Server_Name
            ServerCategory = $StringMatched
        }
    }
    
    Switch ($ServerName) {


        { $_ -match "WPFWEBFD" } {

            Push-Location
            Get-NolioList -StringMatched ($Matches.GetEnumerator() | Select-Object -ExpandProperty Value)
            Pop-Location
        }

        { $_ -match "WPWEBFR" } {

            Push-Location
            Get-NolioList -StringMatched ($Matches.GetEnumerator() | Select-Object -ExpandProperty Value)
            Pop-Location

    
        }

        { $_ -match "WPWSFRONT" } {

            Push-Location
            Get-NolioList -StringMatched ($Matches.GetEnumerator() | Select-Object -ExpandProperty Value)
            Pop-Location

        }

        { $_ -match "WPWSBACK" } {

            Push-Location
            Get-NolioList -StringMatched ($Matches.GetEnumerator() | Select-Object -ExpandProperty Value)
            Pop-Location
        }

        { $_ -match "WPWEBSHOP" } {

            Push-Location
            Get-NolioList -StringMatched ($Matches.GetEnumerator() | Select-Object -ExpandProperty Value)
            Pop-Location
        }

        default {

            Write-Output 0
        }
    }
}