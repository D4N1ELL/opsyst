#!/bin/bash

# Check if a path is a valid directory
check_directory() {
    if [ ! -d "$1" ]; then
        echo "Error: $1 is not a valid directory."
        exit 1
    fi
}

# Calculate the total size of files
calculate_size() {
    local files=("$@")

    # If there are no files, return 0
    if [ "${#files[@]}" -eq 0 ]; then
        echo 0
        return
    fi

    # Use `du` safely with filenames containing spaces
    total_size=0
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            file_size=$(du -b "$file" 2>/dev/null | awk '{print $1}')
            total_size=$((total_size + file_size))
        fi
    done

    echo "$total_size"
}


# Ensure correct usage
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <directory1> <directory2> <destination_directory>"
    exit 1
fi

# Assign arguments to variables
dir1=$1
dir2=$2
dest_dir=$3

# Check if input directories exist
check_directory "$dir1"
check_directory "$dir2"

# Check or create the destination directory
if [ ! -d "$dest_dir" ]; then
    mkdir -p "$dest_dir" || { echo "Error: Could not create destination directory $dest_dir."; exit 1; }
fi

files_dir1=()
while IFS= read -r file; do
    files_dir1+=("$file")
done < <(find "$dir1" -maxdepth 1 -type f -exec basename {} \;)

files_dir2=()
while IFS= read -r file; do
    files_dir2+=("$file")
done < <(find "$dir2" -maxdepth 1 -type f -exec basename {} \;)


# Initialize arrays
unique_dir1=()
unique_dir2=()
common_files=()

# Compare files between the two directories
for file in "${files_dir1[@]}"; do
    if [[ " ${files_dir2[@]} " =~ " $file " ]]; then
        # Check if contents are identical
        hash1=$(shasum "$dir1/$file" | awk '{print $1}')
        hash2=$(shasum "$dir2/$file" | awk '{print $1}')
        if [[ "$hash1" == "$hash2" ]]; then
            common_files+=("$file")
        else
            unique_dir1+=("$dir1/$file")  # Same filename, different content
            unique_dir2+=("$dir2/$file")  # Same filename, different content
        fi
    else
        unique_dir1+=("$dir1/$file")
    fi
done

# Check for unique files in dir2
for file in "${files_dir2[@]}"; do
    if [[ ! " ${files_dir1[@]} " =~ " $file " ]]; then
        unique_dir2+=("$dir2/$file")
    fi
done

# Print unique files in dir1
echo "Files unique to $dir1 (${#unique_dir1[@]} files):"
printf "%s\n" "${unique_dir1[@]}"
size_dir1=$(calculate_size "${unique_dir1[@]}")
echo "Total size: $size_dir1 bytes"

# Print unique files in dir2
echo "Files unique to $dir2 (${#unique_dir2[@]} files):"
printf "%s\n" "${unique_dir2[@]}"
size_dir2=$(calculate_size "${unique_dir2[@]}")
echo "Total size: $size_dir2 bytes"

# Print common files
echo "Common files between $dir1 and $dir2 (${#common_files[@]} files):"
printf "%s\n" "${common_files[@]}"
common_files_paths=()
for file in "${common_files[@]}"; do
    common_files_paths+=("$dir1/$file")
done
size_common=$(calculate_size "${common_files_paths[@]}")
echo "Total size: $size_common bytes"

# Move common files to the destination directory and create hard links
echo "Moving common files to $dest_dir and creating hard links..."
for file in "${common_files[@]}"; do
    mv "$dir1/$file" "$dest_dir/"
    ln "$dest_dir/$file" "$dir1/"
    ln "$dest_dir/$file" "$dir2/"
done
echo "Operation complete."

exit 0
