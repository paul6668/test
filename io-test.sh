#!/bin/bash

# Define variables
output_file="fio_test_output.txt"

# Function to perform disk I/O test with fio
perform_io_test() {
    echo "Performing disk I/O test with fio..."
    fio --name=mytest --ioengine=sync --rw=randwrite --bs=4k --numjobs=4 --size=1G --time_based --runtime=30s --time_based --output=$output_file
    echo "Disk I/O test with fio completed. Results stored in $output_file."
}

# Execute the disk I/O test
perform_io_test
