#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <csv_file>"
    exit 1
fi

csv_file=$1

# Check if the CSV file exists
if [ ! -f "$csv_file" ]; then
    echo "Error: CSV file not found."
    exit 1
fi

# Create a directory to store the JSON files
output_dir="json_output"
mkdir -p "$output_dir"


# Loop through each line in the CSV file
tail -n +2 "$csv_file" | while IFS=, read -r project app env; do
    # Create JSON content
    json_content=$(cat <<EOF
{
    "project": "$project",
    "appname": "$app",
    "env": "$env",
    "kustomize_template": "dotnet",
    "org": "scl-$env"
}
EOF
    )

    # Output JSON content to a file
    json_file="$output_dir/${app}_${env}.json"
    echo "$json_content" > "$json_file"
    echo "Created $json_file"
done < "$csv_file"

echo "JSON files have been generated in the '$output_dir' directory."
