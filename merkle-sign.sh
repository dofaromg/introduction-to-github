#!/bin/bash

# Merkle Tree Signing Script
# This script creates a Merkle tree of file hashes and signs the root

set -e

MERKLE_FILE=".merkle-tree"
SIGNATURES_FILE=".merkle-signatures"

# Function to calculate file hash
calculate_hash() {
    local file="$1"
    if [ -f "$file" ]; then
        sha256sum "$file" | awk '{print $1}'
    fi
}

# Function to calculate Merkle root from file hashes
calculate_merkle_root() {
    local hashes=()
    
    # Collect all file hashes (excluding git and merkle files)
    while IFS= read -r file; do
        if [[ "$file" != .git* ]] && [[ "$file" != .merkle* ]]; then
            local hash=$(calculate_hash "$file")
            if [ -n "$hash" ]; then
                hashes+=("$hash")
            fi
        fi
    done < <(find . -type f -not -path '*/\.*' | sort)
    
    # If no files, return empty
    if [ ${#hashes[@]} -eq 0 ]; then
        echo ""
        return
    fi
    
    # Calculate Merkle root by combining hashes
    local current_level=("${hashes[@]}")
    
    while [ ${#current_level[@]} -gt 1 ]; do
        local next_level=()
        for ((i=0; i<${#current_level[@]}; i+=2)); do
            if [ $((i+1)) -lt ${#current_level[@]} ]; then
                # Combine two hashes
                local combined="${current_level[$i]}${current_level[$((i+1))]}"
                local new_hash=$(echo -n "$combined" | sha256sum | awk '{print $1}')
                next_level+=("$new_hash")
            else
                # Odd one out, carry forward
                next_level+=("${current_level[$i]}")
            fi
        done
        current_level=("${next_level[@]}")
    done
    
    echo "${current_level[0]}"
}

# Function to save Merkle tree
save_merkle_tree() {
    local merkle_root="$1"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo "# Merkle Tree - Generated on $timestamp" > "$MERKLE_FILE"
    echo "Root: $merkle_root" >> "$MERKLE_FILE"
    echo "" >> "$MERKLE_FILE"
    echo "# File Hashes:" >> "$MERKLE_FILE"
    
    while IFS= read -r file; do
        if [[ "$file" != .git* ]] && [[ "$file" != .merkle* ]]; then
            local hash=$(calculate_hash "$file")
            if [ -n "$hash" ]; then
                echo "$file: $hash" >> "$MERKLE_FILE"
            fi
        fi
    done < <(find . -type f -not -path '*/\.*' | sort)
}

# Function to sign Merkle root
sign_merkle_root() {
    local merkle_root="$1"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local signature=$(echo -n "$merkle_root" | sha256sum | awk '{print $1}')
    
    echo "# Merkle Root Signatures" > "$SIGNATURES_FILE"
    echo "Timestamp: $timestamp" >> "$SIGNATURES_FILE"
    echo "Root: $merkle_root" >> "$SIGNATURES_FILE"
    echo "Signature: $signature" >> "$SIGNATURES_FILE"
}

# Main execution
main() {
    local mode="${1:-incremental}"
    
    echo "Running Merkle signing in $mode mode..."
    
    # Calculate Merkle root
    echo "Calculating Merkle root..."
    merkle_root=$(calculate_merkle_root)
    
    if [ -z "$merkle_root" ]; then
        echo "Warning: No files to hash"
        exit 0
    fi
    
    echo "Merkle root: $merkle_root"
    
    # Save Merkle tree
    echo "Saving Merkle tree..."
    save_merkle_tree "$merkle_root"
    
    # Sign the root
    echo "Signing Merkle root..."
    sign_merkle_root "$merkle_root"
    
    if [ "$mode" = "full" ]; then
        echo "Full mode: Adding Merkle files to git..."
        git add "$MERKLE_FILE" "$SIGNATURES_FILE" 2>/dev/null || true
    fi
    
    echo "✓ Merkle signing complete!"
    echo "  - Merkle tree saved to: $MERKLE_FILE"
    echo "  - Signatures saved to: $SIGNATURES_FILE"
}

# Run main function
main "$@"
