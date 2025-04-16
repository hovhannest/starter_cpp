# Function to configure a target for no CRT builds
function(target_disable_crt target)
    target_compile_options(${target} PRIVATE
        -ffreestanding
        -nostdlib
        -nostartfiles
    )
    target_link_options(${target} PRIVATE
        -nostdlib
        -nostartfiles
        -ffreestanding
    )
endfunction()

# Function to configure a target for minimal size
function(target_optimize_size target)
    target_compile_options(${target} PRIVATE
        -Oz
        -fdata-sections
        -ffunction-sections
        -fno-unwind-tables
        -fno-asynchronous-unwind-tables
    )
    target_link_options(${target} PRIVATE
        -Wl,--gc-sections
        -Wl,--strip-all
        -s
    )
endfunction()

# Combined function to configure both no CRT and size optimization
function(target_minimal_binary target)
    target_disable_crt(${target})
    target_optimize_size(${target})
endfunction()