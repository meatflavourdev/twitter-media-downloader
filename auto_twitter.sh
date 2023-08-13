#!/bin/bash

# Default values
twitter_profile=""
flag_twitter=false
flag_zip=false
flag_cleandir=false
flag_cleanurls=false

# Parse command-line options using getopts
while getopts ":n:t:z:d:f:" opt; do
    case $opt in
        n)
            twitter_profile="$OPTARG"
            ;;
#        t)
#           flag_twitter=true
#            ;;   
#        z)
#           flag_zip=true
#            ;;     
#        d)
#           flag_cleandir=true
#            ;;     
#        f)
#           flag_cleanurls=true
#            ;;      
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Create the output directory if it doesn't exist
output_dir="$twitter_profile"
mkdir -p "$output_dir"

#Set url filename
urls_file="$twitter_profile.txt"

#Get twitter image links (large)
#if $flag_twitter; then
    echo "Retrieving Twitter profile images: $twitter_profile"
    ./twmd -i -u $twitter_profile -z -L | tee -a $urls_file
    echo "Done."
#fi

#Remove extra /img dir
rm -R "$output_dir/img/"

#Remove duplicate urls
echo "Removing duplicate urls from file..."
sort -u -o "$urls_file" "$urls_file"
echo "Done."

# Specify the maximum number of download retries
max_retries=3

# Loop through each URL in the file
echo "Downloading each URL from $url_file"
while IFS= read -r url; do
    # Extract the filename without query parameters
    filename=$(echo "$url" | awk -F'[/?]' '{print $(NF-1)}')

    #Reset retry index
    retries=0
    
    while [ $retries -lt $max_retries ]; do
    # Download the file using wget and save it in the output directory
    wget "$url" -O "$output_dir/$filename" -q
        
        # Check if the downloaded file exists and has a size greater than 0 bytes
        if [ -s "$output_dir/$filename" ]; then
            echo "Downloaded: $filename"
            echo "-------------------------------------------------"
            break  # Successful download, exit retry loop
        else
            echo "Retrying: $filename (Attempt $((retries+1)))"
            rm "$output_dir/$filename"  # Remove the incomplete download
            ((retries++))
        fi
    done
done < "$urls_file"

#Echo total downloaded 
total_files=$(find "$output_dir" -type f | wc -l)
non_empty_files=$(find "$output_dir" -type f -size +0c | wc -l)

echo "Total files: $total_files"
echo "Non-empty files (> 0 bytes): $non_empty_files"

#Zip contents of directory for download
#if $flag_zip; then
    echo "Zipping $twitter_profile.zip at ./$output_dir"
    zip -j -r "$twitter_profile.zip" "$output_dir" -q
#fi

#Cleanup the image directory
#if $flag_cleandir; then
    echo "Removing ./$output_dir/"
    rm -Rd "$output_dir"
#fi

#Cleanup the urls text file
#if $flag_cleanurls; then
    echo "Removing URL text file: $urls_file"
    rm "$urls_file"
#fi