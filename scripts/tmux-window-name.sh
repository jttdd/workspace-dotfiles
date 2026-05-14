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

git_branch_for() {
  git -C "$1" symbolic-ref --quiet --short HEAD 2>/dev/null || true
}

git_commit_for() {
  git -C "$1" rev-parse --short HEAD 2>/dev/null || true
}

jj_nearest_bookmark_for() {
  jj -R "$1" log -r 'heads(::@ & bookmarks())' --no-graph \
    -T 'local_bookmarks.map(|b| b.name()).join(" ")' 2>/dev/null || true
}

jj_description_for() {
  jj -R "$1" log -r @ --no-graph -T 'description' 2>/dev/null | sed -n '1p' || true
}

repo_root="$(git -C "$path" rev-parse --show-toplevel 2>/dev/null || true)"

if [ -n "$repo_root" ]; then
  repo_name="$(basename_for "$repo_root")"
  branch="$(git_branch_for "$path")"

  if [ -n "$branch" ]; then
    printf '%s:%s\n' "$repo_name" "$branch"
    exit 0
  fi

  # In git repos managed by jj, HEAD is often detached. Prefer the nearest
  # local bookmark, then the current change description, before falling back
  # to an opaque commit ID.
  branch="$(jj_nearest_bookmark_for "$path")"
  if [ -n "$branch" ]; then
    printf '%s:%s\n' "$repo_name" "$branch"
    exit 0
  fi

  branch="$(jj_description_for "$path")"
  if [ -n "$branch" ]; then
    printf '%s:%s\n' "$repo_name" "$branch"
    exit 0
  fi

  branch="$(git_commit_for "$path")"
  if [ -n "$branch" ]; then
    printf '%s:%s\n' "$repo_name" "$branch"
    exit 0
  fi

  printf '%s\n' "$repo_name"
  exit 0
fi

basename_for "$path"
