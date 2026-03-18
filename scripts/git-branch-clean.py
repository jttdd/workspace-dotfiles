#!/usr/bin/env python3
"""
Git Branch Cleaner - Safely delete local git branches
"""
import subprocess
import sys
import argparse
import signal
from typing import Dict, List, Set

DEFAULT_PROTECTED_BRANCHES = {"main", "master", "streaming-staging", "libevp-staging"}
PERSONAL_BRANCH_PREFIXES = ("jeff.lai/",)


def signal_handler(sig, frame):
    """Handle Ctrl+C gracefully"""
    sys.exit(0)


# Set up signal handler for Ctrl+C
signal.signal(signal.SIGINT, signal_handler)


def run_git_command(cmd: List[str]) -> str:
    """Run a git command and return output"""
    try:
        result = subprocess.run(
            ["git"] + cmd, capture_output=True, text=True, check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Git command failed: {e}")
        sys.exit(1)


def get_branch_description(branch: str) -> str:
    """Get the description for a git branch"""
    try:
        result = subprocess.run(
            ["git", "config", f"branch.{branch}.description"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        return ""


def detect_trunk_branch() -> str:
    """Detect the main trunk branch using origin/HEAD"""
    try:
        origin_head = run_git_command(["rev-parse", "--abbrev-ref", "origin/HEAD"])
        if origin_head and "/" in origin_head:
            return origin_head.split("/")[-1]  # Extract branch name from "origin/main"
    except:
        pass

    print("Error: Could not detect trunk branch. Use --trunk to specify manually.")
    sys.exit(1)


def get_local_branches() -> List[str]:
    """Get list of all local branches"""
    branches_output = run_git_command(["branch", "--format=%(refname:short)"])
    branches = []
    for line in branches_output.split("\n"):
        branch = line.strip()
        if branch:
            branches.append(branch)
    return branches


def is_branch_protected(branch: str, protected_branches: Set[str]) -> bool:
    """Never offer protected long-lived branches for cleanup."""
    return branch in protected_branches


def is_personal_branch(branch: str) -> bool:
    """Keep active personal branches for manual review unless already merged."""
    return any(branch.startswith(prefix) for prefix in PERSONAL_BRANCH_PREFIXES)


def print_branch_list(branches: List[str]) -> None:
    """Show branches with their descriptions so bulk prompts are reviewable."""
    for branch in branches:
        desc = get_branch_description(branch)
        if desc:
            print(f"  - {branch}: {desc}")
        else:
            print(f"  - {branch}")


def delete_branches(branches: List[str]) -> int:
    """Delete branches and report per-branch results."""
    deleted_count = 0
    for branch in branches:
        if delete_branch(branch):
            print(f"✓ Deleted {branch}")
            deleted_count += 1
        else:
            print(f"✗ Failed to delete {branch}")
    return deleted_count


def is_branch_merged(branch: str, trunk: str) -> bool:
    """Check if a branch has been merged into trunk"""
    try:
        # Check if branch is fully merged into trunk
        result = subprocess.run(
            ["git", "merge-base", "--is-ancestor", branch, trunk], capture_output=True
        )
        return result.returncode == 0
    except subprocess.CalledProcessError:
        return False


def delete_branch(branch: str) -> bool:
    """Delete a git branch"""
    try:
        run_git_command(["branch", "-d", branch])
        return True
    except:
        try:
            # Force delete if normal delete fails
            run_git_command(["branch", "-D", branch])
            return True
        except:
            return False


def main():
    parser = argparse.ArgumentParser(description="Safely delete local git branches")
    parser.add_argument(
        "--protected",
        nargs="*",
        default=[],
        help="List of protected branches that should never be deleted",
    )
    parser.add_argument("--trunk", help="Specify trunk branch manually")

    args = parser.parse_args()

    # Detect trunk branch
    trunk_branch = args.trunk if args.trunk else detect_trunk_branch()
    print(f"Trunk branch: {trunk_branch}")

    # Get protected branches
    protected_branches: Set[str] = (
        set(args.protected) | DEFAULT_PROTECTED_BRANCHES | {trunk_branch}
    )
    if protected_branches - {trunk_branch}:
        print(
            f"Protected branches: {', '.join(sorted(protected_branches - {trunk_branch}))}"
        )
    # Get all local branches
    all_branches = get_local_branches()
    review_branches = [
        b for b in all_branches if not is_branch_protected(b, protected_branches)
    ]

    if not review_branches:
        print("No branches to clean up!")
        return

    print(f"\nFound {len(review_branches)} branches to review:\n")

    merge_statuses: Dict[str, bool] = {
        branch: is_branch_merged(branch, trunk_branch) for branch in review_branches
    }

    merged_branches = [branch for branch in review_branches if merge_statuses[branch]]

    if merged_branches:
        print("Merged branches to delete:")
        print_branch_list(merged_branches)

        confirm = (
            input(f"\nDelete all {len(merged_branches)} merged branches? (y/N): ")
            .lower()
            .strip()
        )

        if confirm == "y":
            deleted_count = delete_branches(merged_branches)
            print(f"\nDeleted {deleted_count} merged branches\n")
        else:
            print("Skipped auto-deletion\n")

    remaining_branches = [b for b in review_branches if b not in merged_branches]

    bulk_unmerged_branches = [
        branch for branch in remaining_branches if not is_personal_branch(branch)
    ]

    if bulk_unmerged_branches:
        print("Unmerged non-jeff.lai/* branches to delete:")
        print_branch_list(bulk_unmerged_branches)

        confirm = (
            input(
                f"\nDelete all {len(bulk_unmerged_branches)} unmerged non-jeff.lai/* branches? (y/N): "
            )
            .lower()
            .strip()
        )

        if confirm == "y":
            deleted_count = delete_branches(bulk_unmerged_branches)
            print(f"\nDeleted {deleted_count} unmerged non-jeff.lai/* branches\n")
        else:
            print("Skipped bulk deletion of unmerged non-jeff.lai/* branches\n")

    remaining_branches = [
        b for b in remaining_branches if b not in bulk_unmerged_branches
    ]

    # Interactive confirmation for remaining branches
    for branch in remaining_branches:
        is_merged = merge_statuses[branch]
        merge_status = "✓ MERGED" if is_merged else "✗ NOT MERGED"
        desc = get_branch_description(branch)

        print(f"Branch: {branch}")
        if desc:
            print(f"Description: {desc}")
        print(f"Status: {merge_status}")

        confirm = input("Delete this branch? (y/N): ").lower().strip()

        if confirm == "y":
            if delete_branch(branch):
                print(f"✓ Deleted {branch}\n")
            else:
                print(f"✗ Failed to delete {branch}\n")
        else:
            print(f"Skipped {branch}\n")


if __name__ == "__main__":
    main()
