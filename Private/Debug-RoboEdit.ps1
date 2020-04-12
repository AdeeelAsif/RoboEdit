Function Debug-RoboEdit {

    param (

        [parameter(mandatory = $true)]
        [hashtable]$DebugInformation,

        [parameter(mandatory = $true)]
        [string]$DebugFileName


    )

    if ($DebugEnabled -eq $true) {

        $DebugInformation | ConvertTo-Json | Out-File "$($Config.debuglogspath)\$($DebugFileName)"

    }

}