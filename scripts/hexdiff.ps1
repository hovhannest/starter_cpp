# Read both files into byte arrays
$file1 = [System.IO.File]::ReadAllBytes($args[0])
$file2 = [System.IO.File]::ReadAllBytes($args[1])

Write-Host "Comparing files..."
$diffCount = 0

# Compare bytes
for ($i = 0; $i -lt $file1.Length -and $i -lt $file2.Length; $i++) {
    if ($file1[$i] -ne $file2[$i]) {
        Write-Host ("Offset {0:X8}: {1:X2} vs {2:X2}" -f $i, $file1[$i], $file2[$i])
        $diffCount++
        if ($diffCount -ge 10) { break }
    }
}

if ($diffCount -eq 0) {
    Write-Host "Files are identical"
}