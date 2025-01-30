#!/usr/bin/env bash

# Function to display heading
print_heading() {
    echo -e "\n$1"
    echo "===================================="
}

# Initialize counters for the summary
total_files_perm=0
total_files_modified=0
total_dirs_accessed=0
total_files_readable=0
total_dirs_owner_restricted=0

while true; do
    # Accept two arguments
    if [ "$#" -lt 2 ]; then
        echo "Usage: $0 <permissions_octal> <days_modified>"
        exit 1
    fi

    perm_arg=$1
    days_arg=$2

    # Ask the user for the directory name
    read -p "Enter the directory name (absolute path): " dir

    # Ensure directory exists
    if [ ! -d "$dir" ]; then
        echo "Directory does not exist. Please try again."
        continue
    fi

    # 1. Files with specific permissions
    files_with_perm=$(find "$dir" -type f -perm "$perm_arg")
    count_files_perm=$(echo "$files_with_perm" | wc -l)
    total_files_perm=$((total_files_perm + count_files_perm))
    print_heading "Files with permissions $perm_arg ($count_files_perm)"
    echo "$files_with_perm"

    # 2. Files modified in the last 'x' days
    files_modified=$(find "$dir" -type f -mtime "-$days_arg")
    count_files_modified=$(echo "$files_modified" | wc -l)
    total_files_modified=$((total_files_modified + count_files_modified))
    print_heading "Files modified in the last $days_arg days ($count_files_modified)"
    echo "$files_modified"

    # 3. Subdirectories accessed in the last 'x' days
    dirs_accessed=$(find "$dir" -type d -atime "-$days_arg")
    count_dirs_accessed=$(echo "$dirs_accessed" | wc -l)
    total_dirs_accessed=$((total_dirs_accessed + count_dirs_accessed))
    print_heading "Subdirectories accessed in the last $days_arg days ($count_dirs_accessed)"
    echo "$dirs_accessed"

    # 4. Files readable by all users
    files_readable=$(ls -lR "$dir" | grep -E "^.r..r..r.." | awk '{print $9}')
    count_files_readable=$(echo "$files_readable" | wc -l)
    total_files_readable=$((total_files_readable + count_files_readable))
    print_heading "Files readable by all users ($count_files_readable)"
    echo "$files_readable"

    # 5. Subdirectories with restricted owner permissions
    dirs_owner_restricted=$(ls -ld "$dir"/*/ 2>/dev/null | grep -E "^drwx------" | awk '{print $9}')
    count_dirs_owner_restricted=$(echo "$dirs_owner_restricted" | wc -l)
    total_dirs_owner_restricted=$((total_dirs_owner_restricted + count_dirs_owner_restricted))
    print_heading "Subdirectories restricted to owner only ($count_dirs_owner_restricted)"
    echo "$dirs_owner_restricted"

    # Ask if the user wants to continue
    read -p "Do you want to search another directory? (y/n): " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        break
    fi
done

# Print summary
print_heading "Summary"
echo "Total files with permissions $perm_arg: $total_files_perm"
echo "Total files modified in the last $days_arg days: $total_files_modified"
echo "Total subdirectories accessed in the last $days_arg days: $total_dirs_accessed"
echo "Total files readable by all users: $total_files_readable"
echo "Total subdirectories restricted to owner only: $total_dirs_owner_restricted"

echo "Script finished."
