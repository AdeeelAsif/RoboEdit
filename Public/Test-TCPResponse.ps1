Function Test-TCPResponse {
   
    [OutputType('Net.TCPResponse')]
    [cmdletbinding()]

    Param (

        [parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Server', 'IP')]
        [string]$ComputerName,

        [parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Target', 'TargetComputer', 'TargetComputerName')]
        [string]$TargetHost,

        [Parameter(Mandatory = $true)]
        [int]$TargetPort,

        [Parameter(Mandatory = $false)]
        [int]$TCPTimeout = 1000

    )

    $PsVersion = Invoke-Command -ComputerName $ComputerName -ScriptBlock { ($PSVersionTable).PSVersion.Major }

    Switch ($PsVersion) {

        { $_ -le 3 } {

            $TCPResponse = Invoke-Command -ComputerName $ComputerName -ScriptBlock {

                $TcpClient = New-Object Net.Sockets.TcpClient

                try {

                    $tcpClient.Connect($args[0], $args[1])

                    [PSCustomObject] @{
                        ComputerName = $args[0]
                        Port         = $args[1]
                        IsOpen       = $true

                    }
                    
                }
                catch {

                    [PSCustomObject] @{
                        ComputerName = $args[0]
                        Port         = $args[1]
                        IsOpen       = $false
                    }
                }
                finally {

                    $tcpClient.Close()
                }

            } -ArgumentList $TargetHost, $TargetPort

        }

        Default {

            $TCPResponse = Invoke-Command -ComputerName $ComputerName -ScriptBlock {

                $stringBuilder = New-Object Text.StringBuilder
                $tcpClient = New-Object System.Net.Sockets.TCPClient
                $Connect = $tcpClient.ConnectAsync($args[0], $args[1])
        
                Try {
        
                    $null = $Connect.GetAwaiter().GetResult()
                    $IsOpen = $True
                }
                Catch {
                            
                    $IsOpen = $False
                }
        
                $Object = [PSCustomObject] @{
                    ComputerName = $args[0]
                    Port         = $args[1]
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
                        Else { Break }
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

            } -ArgumentList $TargetHost, $TargetPort
        }
    }

    $TCPResponse
} 