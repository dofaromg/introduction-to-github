# Merkle Tree Signing System

This repository includes a Merkle tree-based file signing system that automatically tracks and verifies file integrity.

## Components

### 1. merkle-sign.sh
A bash script that creates a Merkle tree of all files in the repository and signs the root hash.

**Location:** Repository root  
**Usage:**
- `./merkle-sign.sh incremental` - Update Merkle tree (used by pre-commit hook)
- `./merkle-sign.sh full` - Full signing and add files to git

### 2. Pre-commit Hook
Automatically runs before each commit to update the Merkle tree.

**Source:** `git-hooks/pre-commit`  
**Installed to:** `.git/hooks/pre-commit`  
**Installation command:**
```bash
cp git-hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### 3. GitHub Actions Workflow
Verifies Merkle tree integrity on push and pull requests.

**Location:** `.github/workflows/merkle-verify.yml`  
**Triggers:** Push to main/master branches, pull requests

## Generated Files

- `.merkle-tree` - Contains file hashes and Merkle root
- `.merkle-signatures` - Contains signed Merkle root with timestamp

## Setup Instructions

Follow these steps to set up the Merkle signing system:

```bash
# 1. Ensure merkle-sign.sh is in repo root and executable
chmod +x merkle-sign.sh

# 2. Install pre-commit hook
cp git-hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# 3. GitHub Actions workflow is already in place at .github/workflows/merkle-verify.yml

# 4. Run full signing for the first time
./merkle-sign.sh full
```

## How It Works

1. **Pre-commit Hook**: Before each commit, the hook automatically:
   - Calculates hashes for all tracked files
   - Builds a Merkle tree from these hashes
   - Signs the Merkle root
   - Adds updated Merkle files to the commit

2. **GitHub Actions**: On each push/PR, the workflow:
   - Verifies Merkle tree files exist
   - Checks that roots in `.merkle-tree` and `.merkle-signatures` match
   - Displays verification results

3. **Merkle Tree Structure**: 
   - Leaf nodes: SHA-256 hashes of individual files
   - Parent nodes: Combined hashes of child nodes
   - Root: Single hash representing entire repository state

## Benefits

- **Integrity Verification**: Detect any unauthorized file modifications
- **Automated**: Works seamlessly with git workflow
- **Auditable**: Complete hash history in git commits
- **CI/CD Integration**: Automatic verification in GitHub Actions
