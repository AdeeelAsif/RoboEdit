Function Import-File {

    Param(

        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string]$Path,

        [Parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [int]$Lot

    )

    if (!(Test-Path $Path)) {

        Write-Error -ErrorAction Stop -ErrorId 1 -Exception "File $($Path) doesn't exist" 
    }

    if ($lot -lt 0) {

        Write-Error -ErrorAction Stop -ErrorId 2 -Exception "Lot should be greater or equal to 0"
    }

    Write-Verbose "Importing File $($Path)"
    Write-Verbose "Lot is $($Lot)"

    $File = Import-Csv -Path $Path -Delimiter ";" | Where-Object { $_.Lot -eq $Lot }

    if (!$File) {

        Write-Error -ErrorAction Stop -ErrorId 3 -Exception "No data found for lot $($lot)" 
    }

    $Servers = ($File | Select-Object -ExpandProperty Location | ForEach-Object { $_.Split('\')[2] }) | Select-Object -unique
    $i = 1

    $ProcessedList = $Servers | ForEach-Object {

        $UniqueServerName = $_
        $ServerCatalog = Get-ServerList -ServerName $_
        Write-verbose "Server list $($i) : $($ServerCatalog.ServerList -join ",")"
            
        $File | Where-Object { ($_.Location.Split('\')[2]) -eq $UniqueServerName } | ForEach-Object { 
            
            $FileContent = $_
                    
            $ServerCatalog.ServerList | ForEach-Object {
            
                [PSCustomObject]@{
                    Path        = "$($FileContent.Location)$($FileContent.Name)".Replace($UniqueServerName, $_)
                    RestorePath = $($FileContent.Location).Replace($UniqueServerName, $_)
                    Server      = $_
                    Name        = $FileContent.Name
                    Lot         = $FileContent.Lot 
                } 
            }
        }

        $i++
    }

    if (($File.Lot | Select-Object -unique).count -eq 1) {

        $ReturnProcessedList = $ProcessedList | Select-Object * -Unique
        Write-Verbose "Lot consistency check OK"
        Write-Verbose "Total config file to check : $($ReturnProcessedList.Path.count)"
        $ReturnProcessedList | Add-Member -Name Objectcount -MemberType NoteProperty -Value ($ReturnProcessedList.Path.count)
        Return $ReturnProcessedList
    }
    else {

        Write-Error -ErrorAction Stop -ErrorId 3 -Exception "Lot consistency check KO"
    }
}