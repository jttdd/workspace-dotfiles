#!/usr/bin/env bash

set -eu

path="${1:-$PWD}"

basename_for() {
  local value="${1%/}"

  if [ -z "$value" ]; then
    printf '/\n'
    return
  fi

  printf '%s\n' "${value##*/}"
}

repo_root="$(git -C "$path" rev-parse --show-toplevel 2>/dev/null || true)"

if [ -n "$repo_root" ]; then
  repo_name="$(basename_for "$repo_root")"
  branch="$(
    git -C "$path" symbolic-ref --quiet --short HEAD 2>/dev/null ||
      git -C "$path" rev-parse --short HEAD 2>/dev/null ||
      true
  )"

  if [ -n "$branch" ]; then
    printf '%s:%s\n' "$repo_name" "$branch"
    exit 0
  fi

  printf '%s\n' "$repo_name"
  exit 0
fi

basename_for "$path"
