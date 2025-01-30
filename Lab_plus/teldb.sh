#!/bin/bash

CATALOG="catalog"

# Ensure the catalog file exists
if [ ! -f "$CATALOG" ]; then
    touch "$CATALOG"
fi

# Function to display usage instructions
usage() {
    echo "Usage: $0 -a | -l | -s <column> | -c <keyword> | -d <keyword> -b|-r | -n"
    echo "-a              Add a new entry to the catalog."
    echo "-l              Print the contents of the catalog with numbered lines."
    echo "-s <column>     Sort the catalog by the specified column (1: name, 2: surname, etc.)."
    echo "-c <keyword>    Show lines containing the keyword."
    echo "-d <keyword> -b|-r  Delete lines containing the keyword. Use -b to replace with blank lines, -r to remove entirely."
    echo "-n              Count blank lines and prompt to delete them."
    exit 1
}

# Add an entry to the catalog
add_entry() {
    read -p "Enter name: " name
    read -p "Enter surname: " surname
    read -p "Enter city: " city
    read -p "Enter phone number: " phone
    echo "$name $surname $city $phone" >> "$CATALOG"
    echo "Entry added successfully."
}

# Print the catalog with numbered lines
list_catalog() {
    nl -ba "$CATALOG" | sed '/^[[:space:]]*$/d'
}

# Sort the catalog by a specific column
sort_catalog() {
    column=$1
    sort -k "$column" "$CATALOG" | sed '/^[[:space:]]*$/d'
}

# Show lines containing a keyword
search_keyword() {
    keyword=$1
    grep -i "$keyword" "$CATALOG" || echo "No lines containing '$keyword' were found."
}

# Delete lines containing a keyword
delete_keyword() {
    keyword=$1
    mode=$2

    if ! grep -q "$keyword" "$CATALOG"; then
        echo "No lines containing '$keyword' were found."
        return
    fi

    if [ "$mode" = "-b" ]; then
        sed -i.bak "/$keyword/ s/.*/ /" "$CATALOG"
        echo "Lines containing '$keyword' replaced with blank lines."
    elif [ "$mode" = "-r" ]; then
        sed -i.bak "/$keyword/d" "$CATALOG"
        echo "Lines containing '$keyword' removed."
    else
        usage
    fi
}

# Count blank lines and optionally delete them
count_blank_lines() {
    count=$(grep -c '^$' "$CATALOG")
    echo "The catalog contains $count blank lines."
    if [ "$count" -gt 0 ]; then
        read -p "Do you want to delete them? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            sed -i.bak '/^$/d' "$CATALOG"
            echo "Blank lines removed."
        else
            echo "No changes made."
        fi
    fi
}

# Main script logic
if [ "$#" -eq 0 ]; then
    usage
fi

case "$1" in
    -a)
        add_entry
        ;;
    -l)
        list_catalog
        ;;
    -s)
        if [ -n "$2" ]; then
            sort_catalog "$2"
        else
            usage
        fi
        ;;
    -c)
        if [ -n "$2" ]; then
            search_keyword "$2"
        else
            usage
        fi
        ;;
    -d)
        if [ -n "$2" ] && [ -n "$3" ]; then
            delete_keyword "$2" "$3"
        else
            usage
        fi
        ;;
    -n)
        count_blank_lines
        ;;
    *)
        usage
        ;;
esac
