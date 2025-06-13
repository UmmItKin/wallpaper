#!/bin/bash

# Check if dwebp is installed
if ! command -v dwebp &> /dev/null; then
    echo -e "${RED}Error: dwebp is not installed. Please install libwebp package.${NC}"
    echo -e "${BLUE}Run: sudo pacman -S libwebp${NC}"
    exit 1
fi

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo -e "${YELLOW}Warning: ImageMagick is not installed. Some format conversions might not work.${NC}"
    echo -e "${BLUE}To install: sudo pacman -S imagemagick${NC}"
fi

# Default values
output_format="png"
quality=100

# Supported formats
supported_formats=(png jpg jpeg tiff bmp)

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
                echo -e "${RED}Error: Unsupported format '$output_format'. Supported formats are: ${supported_formats[*]}${NC}"
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
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            ;;
    esac
done

# Validate quality
if ! [[ "$quality" =~ ^[0-9]+$ ]] || [ "$quality" -lt 1 ] || [ "$quality" -gt 100 ]; then
    echo -e "${RED}Error: Quality must be a number between 1 and 100${NC}"
    exit 1
fi

# Directory to store original webp files
originals_dir="webp_originals"
mkdir -p "$originals_dir"

# Find all .webp files (excluding webp_originals)
mapfile -t webp_files < <(find . -type f -name "*.webp" ! -path "./$originals_dir/*")

if [ ${#webp_files[@]} -eq 0 ]; then
    echo -e "${YELLOW}No .webp files found in the current directory or subdirectories (excluding $originals_dir).${NC}"
    exit 0
fi

for file in "${webp_files[@]}"; do
    filename="${file%.*}"
    echo -e "${BLUE}Converting $file to ${filename}.${output_format}${NC}"
    
    # First convert to PNG using dwebp
    dwebp "$file" -o "${filename}.png"
    
    if [ "$output_format" = "png" ]; then
        echo -e "${GREEN}Saved as ${filename}.png${NC}"
    elif command -v magick &> /dev/null; then
        magick "${filename}.png" -quality "$quality" "${filename}.${output_format}"
        rm "${filename}.png"
        echo -e "${GREEN}Saved as ${filename}.${output_format}${NC}"
    else
        echo -e "${YELLOW}Warning: Could not convert to ${output_format} - ImageMagick (magick) not installed${NC}"
        echo -e "${GREEN}File saved as PNG instead${NC}"
    fi

    # Move original webp file to originals_dir (directory for original webp files)
    rel_path="${file#./}"
    dest_dir="$originals_dir/$(dirname "$rel_path")"
    mkdir -p "$dest_dir"
    mv "$file" "$dest_dir/"
    echo -e "${BLUE}Moved original webp file to $dest_dir${NC}"
done

# Check script run correctly
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Conversion failed${NC}"
    exit 1
fi

echo -e "${GREEN}Conversion complete!${NC}"