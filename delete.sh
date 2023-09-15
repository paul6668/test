#!/bin/bash

# Check if a CSV file is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <csv_file>"
    exit 1
fi

csv_file="$1"

# Check if the input file exists
if [ ! -f "$csv_file" ]; then
    echo "Error: CSV file '$csv_file' does not exist."
    exit 1
fi

# Quay API endpoint for deleting a tag
quay_api="https://quay.io/api/v1/repository"

# Set the Quay API token (replace with your token)
api_token="YOUR_QUAY_API_TOKEN"

# Function to delete a tag using the Quay API
delete_tag() {
    local repository="$1"
    local tag="$2"

    # Make a DELETE request to delete the tag
    curl -X DELETE -H "Authorization: Bearer $api_token" "$quay_api/$repository/tag/$tag" -o /dev/null -w "%{http_code}\n"
}

# Read and process the CSV file row by row
while IFS=, read -r repository tags; do
    # Skip the header row (if present)
    if [ "$repository" != "Repository" ]; then
        # Split tags into an array (assuming tags are separated by spaces)
        IFS=' ' read -r -a tag_array <<< "$tags"

        # Loop through tags and delete each one
        for tag in "${tag_array[@]}"; do
            echo "Deleting tag '$tag' from repository '$repository'..."
            http_code=$(delete_tag "$repository" "$tag")
            
            # Check the HTTP response code for success
            if [ "$http_code" == "204" ]; then
                echo "Tag '$tag' deleted successfully."
            else
                echo "Failed to delete tag '$tag'. HTTP response code: $http_code"
            fi
        done
    fi
done < "$csv_file"
