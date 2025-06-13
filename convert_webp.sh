#!/bin/bash

# Check if dwebp is installed
if ! command -v dwebp &> /dev/null; then
    echo "Error: dwebp is not installed. Please install libwebp package."
    echo "Run: sudo pacman -S libwebp"
    exit 1
fi

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "Warning: ImageMagick is not installed. Some format conversions might not work."
    echo "To install: sudo pacman -S imagemagick"
fi

# Default values
output_format="png"
quality=100

# Supported formats
supported_formats=(png jpg jpeg tiff bmp)

# Function to check if format is supported
is_supported_format() {
    local fmt="$1"
    for f in "${supported_formats[@]}"; do
        if [[ "$f" == "$fmt" ]]; then
            return 0
        fi
    done
    return 1
}

# Help message
show_help() {
    echo "Usage: $0 [options]"
    echo "Convert WebP images to another format"
    echo ""
    echo "Options:"
    echo "  -f, --format FORMAT    Output format (default: png)"
    echo "  -q, --quality QUALITY  Quality for JPEG output (1-100, default: 100)"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Supported formats: png, jpg, jpeg, tiff, bmp"
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--format)
            output_format="$2"
            # Check if the format is supported
            if ! is_supported_format "$output_format"; then
                echo "Error: Unsupported format '$output_format'. Supported formats are: ${supported_formats[*]}"
                exit 1
            fi
            shift 2
            ;;
        -q|--quality)
            quality="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

# Validate quality
if ! [[ "$quality" =~ ^[0-9]+$ ]] || [ "$quality" -lt 1 ] || [ "$quality" -gt 100 ]; then
    echo "Error: Quality must be a number between 1 and 100"
    exit 1
fi

# Directory to store original webp files
originals_dir="webp_originals"
mkdir -p "$originals_dir"

# Find and convert all WebP files recursively, but ignore webp_originals directory
find . -type f -name "*.webp" ! -path "./$originals_dir/*" | while read -r file; do
    filename="${file%.*}"
    echo "Converting $file to ${filename}.${output_format}"
    
    # First convert to PNG using dwebp
    dwebp "$file" -o "${filename}.png"
    
    if [ "$output_format" = "png" ]; then
        echo "Saved as ${filename}.png"
    elif command -v magick &> /dev/null; then
        magick "${filename}.png" -quality "$quality" "${filename}.${output_format}"
        rm "${filename}.png"
    else
        echo "Warning: Could not convert to ${output_format} - ImageMagick (magick) not installed"
        echo "File saved as PNG instead"
    fi

    # Move original webp file to originals_dir (directory for original webp files)
    rel_path="${file#./}"
    dest_dir="$originals_dir/$(dirname "$rel_path")"
    mkdir -p "$dest_dir"
    mv "$file" "$dest_dir/"
    echo "Moved original webp file to $dest_dir"
done

# Check script run correctly
if [ $? -ne 0 ]; then
    echo "Error: Conversion failed"
    exit 1
fi