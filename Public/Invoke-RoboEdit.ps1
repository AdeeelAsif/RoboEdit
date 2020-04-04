Function Invoke-RoboEdit {

    Param(

        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string]$Path,

        [Parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [int]$Lot,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Json', 'Csv', 'Xml')]
        [string]$FileType,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Deploy', 'Rollback', 'Test')]
        [string]$Mode,

        [Parameter(Mandatory = $true)]
        [string[]]$StringToReplace,

        [Parameter(Mandatory = $true)]
        [string]$NewString,

        [Parameter(Mandatory = $true)]
        [int]$TargetPort,

        [Parameter(Mandatory = $true)]
        [string]$TargetHost
    )

    Write-Verbose "Execution mode is $($Mode)"

    Switch ($Mode) {

        { $_ -eq "Deploy" } {

            #  $WinSxS = Get-ChildItem C:\Windows\WinSxS
            $i = 1
            <#
$WinSxS | ForEach-Object {
    Write-Progress -Activity "Counting WinSxS file $($_.name)" -Status "File $i of $($WinSxS.Count)" -PercentComplete (($i / $WinSxS.Count) * 100)  
    $i++
} #>
            $i = 1 
            Import-File -Path $Path -Lot $Lot -FileType $FileType | ForEach-Object {
                $PercentComplete = (($i / $_.ObjectCount) * 100)
                [PSCustomObject]@{
                    Server              = $_.Server
                    Path                = $_.Path
                    FileExistence       = (Test-Path $_.Path)
                    FileConsistencyTest = (Test-FileConsistency -Server $_.Server -Path $_.Path -Lot $_.Lot -StringToReplace $StringToReplace -NewString $NewString).FileConsistencyTest
                    TestTCPConnection   = $(

                        $PsVersion = Invoke-Command -ComputerName $_.Server -ScriptBlock { ($PSVersionTable).PSVersion.Major }

                        If ($PsVersion -le 3) {

                            Invoke-Command -ComputerName $_.Server -ScriptBlock {

                                $TcpClient = New-Object Net.Sockets.TcpClient

                                try {
                                    $tcpClient.Connect($args[0], $args[1])
                                    $true
                                }
                                catch {
                                    $false
                                }
                                finally {
                                    $tcpClient.Close()
            
                                }
                            } -ArgumentList $TargetHost, $TargetPort
                        }
                        else {
                            
                            Invoke-Command -ComputerName $_.Server -ScriptBlock ${Function:Test-TCPResponse} -ArgumentList $TargetHost, $TargetPort
                        }
                    ) 
                    TargetHost          = $TargetHost 
                    TargetPort          = $TargetPort
                    TargetString        = $NewString
                    Lot                 = $_.Lot
                }
                Write-Progress -Activity "Config File" -Status "File $i of $($_.ObjectCount)" -PercentComplete $PercentComplete -CurrentOperation $_.Path
                $i++
            } 
        }

        { $_ -eq "Rollback" } {

        }
        
        { $_ -eq "Test" } {

        }
    }
}