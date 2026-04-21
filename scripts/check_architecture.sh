#!/bin/bash
CHECK_FILE=$1
REQUIRED_SECTIONS=(
    "## 1. Component Model"
    "## 2. Canonical Routing Matrix and Precedence"
    "## 3. Cache Policy by Layer Class"
    "## 4. Failure Modes and Fallback Behavior"
    "## 5. Current -> Target Component Mapping"
    "## 6. Phase-1 Scope Boundaries"
)

if [ -z "$CHECK_FILE" ] || [ ! -f "$CHECK_FILE" ]; then
    echo "Error: Check file not specified or not found."
    exit 1
fi

MISSING=0
for SECTION in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -q "$SECTION" "$CHECK_FILE"; then
        echo "Error: Missing $SECTION"
        MISSING=1
    fi
done

if [ $MISSING -eq 1 ]; then
    exit 1
fi

echo "Success: $CHECK_FILE is complete."
exit 0
