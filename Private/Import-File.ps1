Function Import-File {

    Param(

        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string]$Path,

        [Parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [int]$Lot,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Json', 'Csv', 'Xml')]
        [string]$FileType
    )

    Write-Verbose "Function Import-File" 

    if (!(Test-Path $Path)) {
        Write-Error -ErrorId 1 -Exception "File doesn't exist"
        Return
    }

    if ($lot -lt 0) {

        Write-Error -ErrorId 2 -Exception "Lot should be greater or equal to 0"
        Return
    }

    Switch ($FileType) {
        
        { $_ -eq "Csv" } {

            Write-Verbose "File Type is CSV"
            Write-Verbose "Importing File $($Path)"
            Write-Verbose "Lot is $($Lot)"
            $Servers = @()
            $File = Import-Csv -Path $Path -Delimiter ";" | Where-Object { $_.Lot -eq $Lot }
            $File | ForEach-Object { $Servers += $_.Location.Split('\')[2] }

            $ProcessedList = $Servers | Select-Object -unique | ForEach-Object {

                $UniqueServerName = $_
                $ServerCatalog = Get-ServerList -ServerName $_
                Write-verbose "Server list : $($ServerCatalog.ServerList)"
            
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
            }

            if (($File.Lot | Select-Object -unique).count -eq 1) {

                Write-Verbose "Lot consistency check OK"
                Write-Verbose "Total config file to check : $($ProcessedList.Path.count)"
                $ProcessedList | Add-Member -Name Objectcount -MemberType NoteProperty -Value ($ProcessedList.Path.count)
                Return $ProcessedList
            }
            else {

                Write-Error -ErrorId 3 -Exception "Lot consistency check KO"
            }
        }
    }
}