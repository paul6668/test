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
    json_file="${app}_${env}.json"
    echo "$json_content" > "$json_file"
    echo "Created $json_file"
done < "$csv_file"
