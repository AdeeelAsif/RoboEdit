Function Get-ServerList {

    Param (

        [parameter(mandatory = $true)]
        [string]$ServerName

    )

    $SQLHostname = "FCVSQL3CLSTR2\FD105OPS1,59081" 
    $Databasename = "NOLIO_DB"
    $List = @("WPFWEBFD", "WPWEBFR", "FCXAWPWSFRONT", "FCXAWPWSBACK", "WPWEBSHOP", "TASK1", "FCXSVC", "WPETL")

    $List | ForEach-Object {

        if ($ServerName -match $_) {
    
            $StringMatched = $Matches.GetEnumerator() | Select-Object -ExpandProperty Value
    
        }
    }

    if ($StringMatched) {
        $Query = "SELECT Server_name FROM [NOLIO_DB].[dbo].[servers] WHERE server_name LIKE '%$($StringMatched)%' AND OS_TYPE LIKE '%WINDOWS%' ORDER BY Server_Name ASC"

        Push-Location

        [PSCustomObject]@{
            ServerList     = @(Invoke-Sqlcmd -ServerInstance $SQLHostname -Database $Databasename -Query $Query).Server_Name
            ServerCategory = $StringMatched
        }

        Pop-Location
        Clear-Variable Matches, StringMatched
    }
    else {

        Write-Output 0

    }
}