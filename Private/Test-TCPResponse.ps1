Function Test-TCPResponse {
   
    [OutputType('Net.TCPResponse')]
    [cmdletbinding()]

    Param (

        [parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Server', 'IP')]
        [string[]]$ComputerName = $env:ComputerName,

        [Parameter(Mandatory = $true)]
        [int[]]$Port,

        [Parameter(Mandatory = $false)]
        [int]$TCPTimeout = 1000

    )
    Process {
        
        $PsVersion = ($PSVersionTable).PSVersion.Major 

        If ($PsVersion -le 3) {

            $TcpClient = New-Object Net.Sockets.TcpClient
            try {

                $tcpClient.Connect("$ComputerName", $Port)
                $true
            }
            catch {

                $false
            }
            finally {

                $tcpClient.Close()
            }

        }
        else {

            ForEach ($Computer in $ComputerName) {

                ForEach ($_port in $Port) {

                    $stringBuilder = New-Object Text.StringBuilder
                    $tcpClient = New-Object System.Net.Sockets.TCPClient
                    $Connect = $tcpClient.ConnectAsync($Computer, $_port)

                    Try {

                        $null = $Connect.GetAwaiter().GetResult()
                        $IsOpen = $True
                    }
                    Catch {
                    
                        $IsOpen = $False
                    }

                    $Object = [PSCustomObject] @{
                        ComputerName = $Computer
                        Port         = $_Port
                        IsOpen       = $IsOpen
                        Response     = $Null
                    }

                    If ($IsOpen -eq $True) {
                        While ($True) {

                            Start-Sleep -Milliseconds 1000
                            Write-Verbose "Bytes available: $($tcpClient.Available)"
                            If ([int64]$tcpClient.Available -gt 0) {
                                $Stream = $TcpClient.GetStream()
                                $bindResponseBuffer = New-Object Byte[] -ArgumentList $tcpClient.Available
                                [Int]$Response = $Stream.Read($bindResponseBuffer, 0, $bindResponseBuffer.count)
                                $Null = $stringBuilder.Append(($bindResponseBuffer | ForEach-Object { [char][int]$_ }) -join '')
                            } 
                            Else { 

                                Break 
                            }
                        } 

                        $Object.Response = $stringBuilder.Tostring()

                        If ($Stream) {
                            $Stream.Close()
                            $Stream.Dispose()
                        }
                    }

                    $tcpClient.Close()
                    $tcpClient.Dispose()

                    $Object.PSTypeNames.Insert(0, 'Net.TCPResponse')
                    Write-Output $Object
                }  
            }
        }   
    }
}