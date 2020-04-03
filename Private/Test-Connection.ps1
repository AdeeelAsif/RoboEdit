Function Get-TCPResponse {
    <#
        .SYNOPSIS
            Tests TCP port of remote or local system and returns a response header
            if applicable

        .DESCRIPTION
            Tests TCP port of remote or local system and returns a response header
            if applicable

            If server has no default response, then Response property will be NULL

        .PARAMETER Computername
            Local or remote system to test connection

        .PARAMETER Port
            TCP Port to connect to

        .PARAMETER TCPTimeout
            Time until connection should abort

        .NOTES
            Name: Get-TCPResponse
            Author: Boe Prox
            Version History:
                1.0 -- 15 Jan 2014
                    -Initial build
                2.0 -- 30 Nov 2017
                    -Script reformatting completed by Rick A.

        .INPUTS
            System.String

        .OUTPUTS
            Net.TCPResponse

        .EXAMPLE
        Get-TCPResponse -Computername Exchange1 -Port 25

        Computername : Exchange1
        Port         : 25
        IsOpen       : True
        Response     : 220 SMTP Server Ready

        Description
        -----------
        Checks port 25 of an exchange server and displays header response.
    #>
    [OutputType('Net.TCPResponse')]
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('__Server', 'IPAddress', 'IP')]
        [string[]]$ComputerName = $env:ComputerName,

        [Parameter()]
        [int[]]$Port = 3389,

        [Parameter()]
        [int]$TCPTimeout = 1000
    )
    Process {
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
                        # Let buffer
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

                    # Update output object
                    $Object.Response = $stringBuilder.Tostring()

                    # Close stream
                    If ($Stream) {
                        $Stream.Close()
                        $Stream.Dispose()
                    }
                }
  
                # Close the TCP connection
                $tcpClient.Close()
                $tcpClient.Dispose()

                $Object.PSTypeNames.Insert(0, 'Net.TCPResponse')
                Write-Output $Object
            }  
        }
    }
}