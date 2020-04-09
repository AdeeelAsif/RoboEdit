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
            
            $File = Import-Csv -Path $Path -Delimiter ";" | Where-Object { $_.Lot -eq $Lot } | ForEach-Object {
                [PSCustomObject]@{
                    Path        = "$($_.Location)$($_.Name)"
                    RestorePath = $($_.Location)
                    Server      = $_.Location.Split('\')[2]
                    Name        = $_.Name
                    Lot         = $_.Lot 
                }
            }

            if (($File.Lot | Select-Object -unique).count -eq 1) {

                Write-Verbose "Lot consistency check OK"
                $File | Add-Member -Name Objectcount -MemberType NoteProperty -Value ($File.Path.count)
                Return $File
            }
            else {

                Write-Error -ErrorId 3 -Exception "Lot consistency check KO"
            }
        }
    }
}