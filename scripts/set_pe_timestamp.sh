#!/bin/bash

# Check for required arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <pe_file> [timestamp]"
    exit 1
fi

PE_FILE="$1"
TIMESTAMP="${2:-0}"  # Use 0 if no timestamp provided

# Check if file exists
if [ ! -f "$PE_FILE" ]; then
    echo "Error: File '$PE_FILE' not found" >&2
    exit 1
fi

# Read and check MZ signature (first 2 bytes should be MZ)
MZ_SIG=$(hexdump -n 2 -v -e '/1 "%02X"' "$PE_FILE")
if [ "$MZ_SIG" != "4D5A" ]; then
    echo "Error: Invalid MZ signature" >&2
    exit 1
fi

# Read PE header offset from offset 0x3C (60 decimal)
PE_OFFSET_HEX=$(hexdump -s 60 -n 4 -v -e '/1 "%02X"' "$PE_FILE" | fold -w2 | tac | tr -d '\n')
PE_OFFSET=$((16#$PE_OFFSET_HEX))

# Read and verify PE signature ("PE\0\0" = "50 45 00 00")
PE_SIG=$(hexdump -s $PE_OFFSET -n 4 -v -e '/1 "%02X"' "$PE_FILE")
if [ "$PE_SIG" != "50450000" ]; then
    echo "Error: Invalid PE signature" >&2
    exit 1
fi

# Calculate timestamp offset
TIMESTAMP_OFFSET=$((PE_OFFSET + 8))

# Convert timestamp to little-endian hex
TIMESTAMP_HEX=$(printf '%08x' "$TIMESTAMP" | fold -w2 | tac | tr -d '\n')

# Write timestamp
printf "\x${TIMESTAMP_HEX:0:2}\x${TIMESTAMP_HEX:2:2}\x${TIMESTAMP_HEX:4:2}\x${TIMESTAMP_HEX:6:2}" | \
    dd of="$PE_FILE" bs=1 seek="$TIMESTAMP_OFFSET" conv=notrunc status=none

echo "Successfully set timestamp to $TIMESTAMP for $PE_FILE"