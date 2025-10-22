#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Offline Images Load Script
# Loads images from offline tar files to containerd
# ═══════════════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES_DIR="${SCRIPT_DIR}/images-tar"

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Offline Images Load Script             ║${NC}"
echo -e "${BLUE}║     Load Images to Containerd              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Checks
if [ ! -d "$IMAGES_DIR" ]; then
    echo -e "${RED}❌ Error: Directory ${IMAGES_DIR} not found!${NC}"
    echo -e "${YELLOW}💡 Run first: ./download-images.sh${NC}"
    exit 1
fi

# Find tar files
TAR_FILES=$(find "$IMAGES_DIR" -name "*.tar" 2>/dev/null | sort)
TOTAL=$(echo "$TAR_FILES" | grep -c . || echo 0)

if [ "$TOTAL" -eq 0 ]; then
    echo -e "${RED}❌ No tar files found!${NC}"
    exit 1
fi

echo -e "${GREEN}📋 Found ${TOTAL} image files${NC}"
echo ""

CURRENT=0
SUCCESS=0
FAILED=0

# Loop over each file
for TARFILE in $TAR_FILES; do
    CURRENT=$((CURRENT + 1))
    FILENAME=$(basename "$TARFILE")
    SIZE=$(du -h "$TARFILE" | cut -f1)
    
    echo -e "${BLUE}[${CURRENT}/${TOTAL}]${NC} ${FILENAME} (${SIZE})"
    
    if sudo ctr -n k8s.io images import "$TARFILE" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Loaded successfully"
        SUCCESS=$((SUCCESS + 1))
    else
        echo -e "  ${RED}✗${NC} Load failed"
        FAILED=$((FAILED + 1))
    fi
    
    echo ""
done

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Load Summary                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}✓ Success:  ${SUCCESS}/${TOTAL}${NC}"
[ $FAILED -gt 0 ] && echo -e "${RED}✗ Failed:   ${FAILED}/${TOTAL}${NC}"
echo ""
echo -e "${YELLOW}📊 Loaded images (first 20):${NC}"
sudo crictl images | head -20
echo ""
echo -e "${GREEN}✅ Load completed!${NC}"

