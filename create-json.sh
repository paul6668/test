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

---

#!/bin/bash

# Loop through each JSON file in the current folder
for json_file in *.json; do
    if [ -f "$json_file" ]; then
        # Read JSON content from the file
        json_content=$(cat "$json_file")

        # Make a POST request with the JSON content
        echo "Posting $json_file"
        curl -X POST -H "Content-Type: application/json" -d "$json_content" http://your-api-endpoint.com
        # Replace http://your-api-endpoint.com with the actual API endpoint

        # Add a newline for better readability
        echo
    fi
done

---
#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <project> <appname> <env>"
    exit 1
fi

project=$1
app=$2
env=$3

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

# Create a directory to store the JSON files
output_dir="json_output"
mkdir -p "$output_dir"

# Output JSON content to a file
json_file="$output_dir/${app}_${env}.json"
echo "$json_content" > "$json_file"
echo "Created $json_file"

# Make a POST request with the JSON content
echo "Posting $json_file"
curl -X POST -H "Content-Type: application/json" -d "$json_content" http://your-api-endpoint.com
# Replace http://your-api-endpoint.com with the actual API endpoint

# Add a newline for better readability
echo "JSON file has been generated and posted."
