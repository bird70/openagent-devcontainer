#!/usr/bin/env python3
import sys
import os

REQUIRED_SECTIONS = [
    "## 1. Component Model",
    "## 2. Canonical Routing Matrix and Precedence",
    "## 3. Cache Policy by Layer Class",
    "## 4. Failure Modes and Fallback Behavior",
    "## 5. Current -> Target Component Mapping",
    "## 6. Phase-1 Scope Boundaries"
]

def check_spec(file_path):
    if not os.path.exists(file_path):
        print(f"Error: Spec file {file_path} not found.")
        return False

    with open(file_path, "r") as f:
        content = f.read()

    missing = []
    for section in REQUIRED_SECTIONS:
        if section not in content:
            missing.append(section)

    if missing:
        print(f"Error: Missing required sections in {file_path}:")
        for m in missing:
            print(f"  - {m}")
        return False

    print(f"Success: {file_path} is complete.")
    return True

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: check_architecture.py <spec_file>")
        sys.exit(1)
    
    if not check_spec(sys.argv[1]):
        sys.exit(1)
    sys.exit(0)
