#!/usr/bin/env python3
"""
Git Branch Cleaner - Safely delete local git branches
"""
import subprocess
import sys
import argparse
import signal
from typing import List, Set, Optional


def signal_handler(sig, frame):
    """Handle Ctrl+C gracefully"""
    sys.exit(0)


# Set up signal handler for Ctrl+C
signal.signal(signal.SIGINT, signal_handler)


def run_git_command(cmd: List[str]) -> str:
    """Run a git command and return output"""
    try:
        result = subprocess.run(['git'] + cmd, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Git command failed: {e}")
        sys.exit(1)


def get_branch_description(branch: str) -> str:
    """Get the description for a git branch"""
    try:
        result = subprocess.run(['git', 'config', f'branch.{branch}.description'],
                              capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        return ""


def detect_trunk_branch() -> str:
    """Detect the main trunk branch using origin/HEAD"""
    try:
        origin_head = run_git_command(['rev-parse', '--abbrev-ref', 'origin/HEAD'])
        if origin_head and '/' in origin_head:
            return origin_head.split('/')[-1]  # Extract branch name from "origin/main"
    except:
        pass

    print("Error: Could not detect trunk branch. Use --trunk to specify manually.")
    sys.exit(1)


def get_local_branches() -> List[str]:
    """Get list of all local branches"""
    branches_output = run_git_command(['branch'])
    branches = []
    for line in branches_output.split('\n'):
        branch = line.strip().replace('* ', '')
        if branch:
            branches.append(branch)
    return branches


def is_branch_merged(branch: str, trunk: str) -> bool:
    """Check if a branch has been merged into trunk"""
    try:
        # Check if branch is fully merged into trunk
        result = subprocess.run(['git', 'merge-base', '--is-ancestor', branch, trunk],
                              capture_output=True)
        return result.returncode == 0
    except subprocess.CalledProcessError:
        return False


def delete_branch(branch: str) -> bool:
    """Delete a git branch"""
    try:
        run_git_command(['branch', '-d', branch])
        return True
    except:
        try:
            # Force delete if normal delete fails
            run_git_command(['branch', '-D', branch])
            return True
        except:
            return False


def main():
    parser = argparse.ArgumentParser(description='Safely delete local git branches')
    parser.add_argument('--protected', nargs='*', default=[],
                       help='List of protected branches that should never be deleted')
    parser.add_argument('--trunk', help='Specify trunk branch manually')

    args = parser.parse_args()

    # Detect trunk branch
    trunk_branch = args.trunk if args.trunk else detect_trunk_branch()
    print(f"Trunk branch: {trunk_branch}")

    # Get protected branches
    protected_branches: Set[str] = set(args.protected + [trunk_branch])
    if protected_branches - {trunk_branch}:
        print(f"Protected branches: {', '.join(sorted(protected_branches - {trunk_branch}))}")

    # Get all local branches
    all_branches = get_local_branches()
    deletable_branches = [b for b in all_branches if b not in protected_branches]

    if not deletable_branches:
        print("No branches to clean up!")
        return

    print(f"\nFound {len(deletable_branches)} branches to review:\n")

    merged_branches = [branch for branch in deletable_branches
                      if is_branch_merged(branch, trunk_branch)]

    if merged_branches:
        print("Merged branches to delete:")
        for branch in merged_branches:
            desc = get_branch_description(branch)
            if desc:
                print(f"  - {branch}: {desc}")
            else:
                print(f"  - {branch}")

        confirm = input(f"\nDelete all {len(merged_branches)} merged branches? (y/N): ").lower().strip()

        if confirm == 'y':
            deleted_count = 0
            for branch in merged_branches:
                if delete_branch(branch):
                    print(f"✓ Deleted {branch}")
                    deleted_count += 1
                else:
                    print(f"✗ Failed to delete {branch}")

            print(f"\nDeleted {deleted_count} merged branches\n")

            # Remove deleted branches from the list
            deletable_branches = [b for b in deletable_branches if b not in merged_branches]
        else:
            print("Skipped auto-deletion\n")

    # Check if there are remaining branches to review
    if deletable_branches:
        continue_review = input(f"Continue to review {len(deletable_branches)} remaining branches? (y/N): ").lower().strip()
        if continue_review != 'y':
            print("Exiting...")
            return

    # Interactive confirmation for remaining branches
    for branch in deletable_branches:
        is_merged = is_branch_merged(branch, trunk_branch)
        merge_status = "✓ MERGED" if is_merged else "✗ NOT MERGED"
        desc = get_branch_description(branch)

        print(f"Branch: {branch}")
        if desc:
            print(f"Description: {desc}")
        print(f"Status: {merge_status}")

        confirm = input("Delete this branch? (y/N): ").lower().strip()

        if confirm == 'y':
            if delete_branch(branch):
                print(f"✓ Deleted {branch}\n")
            else:
                print(f"✗ Failed to delete {branch}\n")
        else:
            print(f"Skipped {branch}\n")


if __name__ == "__main__":
    main()
