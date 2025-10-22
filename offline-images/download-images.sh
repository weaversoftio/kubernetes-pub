#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Offline Images Download Script
# Downloads and saves all images for 4 Kubernetes tools
# ═══════════════════════════════════════════════════════════

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES_LIST="${SCRIPT_DIR}/images-list.txt"
OUTPUT_DIR="${SCRIPT_DIR}/images-tar"

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Offline Images Download Script           ║${NC}"
echo -e "${BLUE}║  4 Tools: Headlamp, Kyverno, MetalLB, NGINX║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Checks
if [ ! -f "$IMAGES_LIST" ]; then
    echo -e "${RED}❌ Error: images-list.txt not found!${NC}"
    exit 1
fi

# Create directories
mkdir -p "$OUTPUT_DIR"

# Read images (ignore empty lines and comments)
IMAGES=$(grep -v '^#' "$IMAGES_LIST" | grep -v '^$' | grep -v '^─')
TOTAL=$(echo "$IMAGES" | wc -l)
CURRENT=0
SUCCESS=0
FAILED=0

echo -e "${GREEN}📋 Found ${TOTAL} images to download${NC}"
echo -e "${YELLOW}📁 Save path: ${OUTPUT_DIR}${NC}"
echo ""

# Loop over each image
while IFS= read -r IMAGE; do
    CURRENT=$((CURRENT + 1))
    
    # Filename (replace special characters)
    FILENAME=$(echo "$IMAGE" | sed 's/[\/:]/_/g' | sed 's/@sha256.*$//')
    TARFILE="${OUTPUT_DIR}/${FILENAME}.tar"
    
    echo -e "${BLUE}[${CURRENT}/${TOTAL}]${NC} ${IMAGE}"
    
    # Check if already exists
    if [ -f "$TARFILE" ]; then
        SIZE=$(du -h "$TARFILE" | cut -f1)
        echo -e "  ${GREEN}✓${NC} Already exists (${SIZE}) - skipping"
        SUCCESS=$((SUCCESS + 1))
        continue
    fi
    
    # Download with crictl
    echo -e "  ${YELLOW}⬇${NC} Downloading..."
    if sudo crictl pull "$IMAGE" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Pull completed"
        
        # Save to tar file
        echo -e "  ${YELLOW}💾${NC} Saving..."
        if sudo ctr -n k8s.io images export "$TARFILE" "$IMAGE" 2>/dev/null; then
            SIZE=$(du -h "$TARFILE" | cut -f1)
            echo -e "  ${GREEN}✓${NC} Saved (${SIZE})"
            SUCCESS=$((SUCCESS + 1))
        else
            echo -e "  ${RED}✗${NC} Save failed"
            FAILED=$((FAILED + 1))
        fi
    else
        echo -e "  ${RED}✗${NC} Pull failed"
        FAILED=$((FAILED + 1))
    fi
    
    echo ""
done <<< "$IMAGES"

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            Download Summary                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}✓ Success:  ${SUCCESS}/${TOTAL}${NC}"
[ $FAILED -gt 0 ] && echo -e "${RED}✗ Failed:   ${FAILED}/${TOTAL}${NC}"
echo ""
echo -e "${YELLOW}📁 Files in: ${OUTPUT_DIR}${NC}"
du -sh "$OUTPUT_DIR" 2>/dev/null || echo "  (Calculating size...)"
echo ""
echo "📦 File list:"
ls -lh "$OUTPUT_DIR" 2>/dev/null | tail -n +2 | awk '{print "  " $9 " - " $5}' || echo "  (No files yet)"
echo ""
echo -e "${GREEN}✅ Download completed!${NC}"

