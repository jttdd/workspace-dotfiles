#!/usr/bin/env bash

# Like git diff, including untracked files without changing the staging area.
set -euo pipefail

index_path=$(git rev-parse --path-format=absolute --git-path index)
diff_directory=$PWD/${GIT_PREFIX:-}
cd -- "$(git rev-parse --show-toplevel)"

temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/git-diff-untracked.XXXXXX")
trap 'rm -rf -- "$temporary_directory"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

# Unlike ls-files, status can reuse Git's untracked-file cache.
git --no-optional-locks status --porcelain=v1 -z --untracked-files=normal \
	--no-renames --ignore-submodules=all |
	while IFS= read -r -d '' entry; do
		if [[ "$entry" == '?? '* ]]; then
			printf '%s\0' "${entry:3}"
		fi
	done >"$temporary_directory/untracked"

if [[ -s "$temporary_directory/untracked" ]]; then
	if [[ -f "$index_path" ]]; then
		cp -p -- "$index_path" "$temporary_directory/index"
	fi
	export GIT_INDEX_FILE="$temporary_directory/index"
	git -c core.splitIndex=false -c core.preloadIndex=false --literal-pathspecs add --intent-to-add \
		--pathspec-from-file="$temporary_directory/untracked" --pathspec-file-nul
fi

cd -- "$diff_directory"
git --no-optional-locks -c core.splitIndex=false diff "$@"
