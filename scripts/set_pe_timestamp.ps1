param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,
    
    [Parameter(Mandatory=$false)]
    [int64]$Timestamp = 0
)

try {
    # Open the file in read/write mode
    $stream = [System.IO.File]::Open($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)
    $reader = New-Object System.IO.BinaryReader($stream)
    
    # Check MZ signature
    $mzSignature = $reader.ReadInt16()
    if ($mzSignature -ne 0x5A4D) {
        throw "Invalid MZ signature"
    }
    
    # Seek to PE header offset location
    $stream.Position = 0x3C
    $peOffset = $reader.ReadInt32()
    
    # Seek to PE signature and verify
    $stream.Position = $peOffset
    $peSignature = $reader.ReadInt32()
    if ($peSignature -ne 0x00004550) { # "PE\0\0"
        throw "Invalid PE signature"
    }
    
    # COFF header starts immediately after PE signature
    # Timestamp is at offset 8 in the COFF header
    $stream.Position = $peOffset + 8
    
    # Create writer to modify timestamp
    $writer = New-Object System.IO.BinaryWriter($stream)
    $writer.Write([Int32]$Timestamp)
    
    Write-Host "Successfully set timestamp to $Timestamp for $FilePath"
}
catch {
    Write-Error "Failed to modify PE file: $_"
    exit 1
}
finally {
    if ($writer) { $writer.Close() }
    if ($reader) { $reader.Close() }
    if ($stream) { $stream.Close() }
}