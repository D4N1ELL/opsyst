#!/bin/bash

# Ensure correct number of arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <username> <source_path> <destination_path>"
    exit 1
fi

# Assign arguments to variables
username="$1"
source_path="$2"
destination="$3"

# Check if the user exists
if ! id "$username" &>/dev/null; then
    echo "Error: User '$username' does not exist."
    exit 1
fi

# Check if the source exists
if [ ! -e "$source_path" ]; then
    echo "Error: Source '$source_path' does not exist."
    exit 1
fi

# Generate a timestamped backup filename
timestamp=$(date +"%Y%m%d_%H%M%S")
backup_file="/tmp/${username}_backup_${timestamp}.tar.gz"

# Create the tar archive
tar -czf "$backup_file" "$source_path"
echo "Backup created: $backup_file"

# Check if the destination is a directory
if [ -d "$destination" ]; then
    cp "$backup_file" "$destination/"
    echo "Backup copied to directory: $destination"
elif [ -f "$destination" ]; then
    cat "$backup_file" >> "$destination"
    echo "Backup appended to file: $destination"
else
    echo "Error: Destination '$destination' is neither a directory nor a file."
    exit 1
fi

exit 0
