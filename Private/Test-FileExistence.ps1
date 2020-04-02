function Test-FileExistence {

    param (
    
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Server,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Lot

    )

    [PSCustomObject]@{
        Server = $Server
        Exist  = $(Test-Path $Path)
        Path   = $Path
        Lot = $Lot
    }
}