# Responses
- Be terse
- Ask me clarifying questions if I don't provide enough context

# Commands
- use `rg` instead of `grep`, don't ask for my confirmation
- use `fd` instead of `find`, don't ask for my confirmation
- `ast-grep` is available. Whenever a search requires syntax-aware or structural matching, default to `ast-grep --lang rust -p '<pattern>'` (or set `--lang` appropriately)
- Always use `bzl` to run bazel instead of `bazel`
- For any read command, execute without my permission
- For any build/check command, execute without my permission

# Agents
- Always use a sub-agent to run builds or tests.
- Always consult a sub-agent to plan your next steps.
- Always consult a sub-agent for feedback when you have completed part of a change.
- Always leverage sub-agents to explore ideas, summarize documentation, research, etc.
- You can use more than one sub-agent at a time.
- When using sub-agents, always try to leverage as many as possible - parallelize sub-agents for improved efficiency.
- Always use sub-agents when you can. Break you work up into discrete chunks for agents to execute.

# Code style

- Comments
    - don't explain the "what" when the code is reasonably clear. Prefer extracting a descriptive helper function over adding a comment. Always explain "why".
    - Rust doc comments attach to the following item, so place them before attributes/macros like `#[tokio::test]` or `#[derive(...)]`, not after.
    - Always add documentation to public items
    - Keep public/shared API docs general: describe what the member does for any caller, not one caller's use case. Put use-case-specific "why" at the call site (or in config), not on the general-purpose API.
    - Don't remove existing unrelated comments
- Order matters for readability (even if it doesn't affect semantics). On the first read, a file is read top-down, so put important things near the top. The main function goes first.
    - Helpers and supporting fns go below their callers, not above — the caller is the more relevant entry point, the helper is an implementation detail.
    - The whole file should mirror runtime flow: entry point → dispatcher → branches → utilities. The reader walks down the file the same way control flows.
    - For a dispatcher (match/switch that routes to handlers), list the handler fns below it in the **same order as the match arms**. The reader scans the match, then scrolls straight down — no hunting.
    - Shared helpers (multiple callers above) go in a single block at the bottom of the impl, not interleaved with the call sites that use them.
    - If a nested type is complex, make it a top-level struct.
    - At the same time, not everything has a single right order. When in doubt, consider sorting alphabetically, taking advantage of big-endian naming.

# Formating
- Always run the appropriate code formatting command after you've made changes

# Rust
- When running `cargo` commands directly (instead of `bzl`), run them in the crate root directory
- To validate changes, run:
    * `cargo clippy --all-targets`
    * `cargo test -- --skip=integration_test` # or run the specific set of tests scoped to the change
- Avoid silencing clippy lints with #[allow()]. Fix the underlying issue.
- When finished, format with `cargo fmt` - IMPORTANT: Only format files in the crate you're working on by specifying paths explicitly: `cargo fmt -- path/to/file.rs` OR run from the specific crate directory to avoid formatting unrelated workspace crates
- Can measure coverage with:
    * `cargo +nightly llvm-cov --branch -- --skip=integration_test`
- Before work can be considered finished, all #[allow(dead_code)] must be removed
- Whenever a dependency is added to Cargo.toml, run: `bzl run //third_party:crates_vendor` to update the bzl files
- bon
    - prefer using `bon::Builder` for data-only types, especially public ones
    - prefer deriving `Builder` directly on the target struct when the generated `build()` is sufficient
    - prefer using #[bon] macro with #[builder] on `new` when building is non-trivial
    - use struct builder syntax rather than function-builder patterns
    - for field validation/transforms, prefer `#[builder(with = ...)]` on the field instead of custom whole-builder plumbing when possible
    - when a field must be non-empty, prefer enforcing that in the field-level `#[builder(with = ...)]` closure
    - only introduce a separate params/builder struct when you need a custom top-level `build()` path that the default generated builder cannot express cleanly

# Git
- Ensure all branches are prefixed with jeff.lai/

## Commits
- When committing Rust changes, always ignore ./cargo/config.toml and Cargo.lock changes (unless Cargo.toml also changes)
- Start the commit messages with the project name, e.g.:
    - When working in libstreaming, start all commit messages with: `libstreaming: `
    - When working in assigner_client, start all commit messages with: `assigner_client: `
    - When working across multiple projects in the domain/streaming, start all commit messages with: `streaming: `
- When a change is scoped to one language binding within a multi-binding project, add the binding in parentheses after the project name, e.g.:
    - `libstreaming(java): switch pullBatch to use native pull_batch`
    - `libstreaming(go): reject negative GetLastCommitted timeouts`
    - The parenthetical is **only** for language-binding scope (`java`, `go`, `rust`, `python`, `c`, etc.). Don't use it for other sub-areas (modules, features, components).
- Commit messages must explain why the change is being made, not just what changed.
- Commit message subjects should describe what applying the commit accomplishes, not just which files changed or how the change was made.
- After the required project prefix, write commit subjects in imperative mood, present tense, active voice.
- Keep subjects concise but meaningful. Avoid vague titles like `cleanup`, `fix tests`, `address comments`, or `refactor stuff`.
- Use the body when the subject cannot carry enough context. Explain why the change is needed, what tradeoffs matter, and any context future readers should not have to recover from an issue or PR.
- Keep commits small, atomic, cohesive, self-contained, and reviewable. If one commit needs multiple unrelated verbs, scopes, or reasons, split it.
- Separate the subject from the body with a blank line, wrap body text around 72 characters, and put Git trailers last.

# Github
- Use the `gh` CLI to interact with github
- Always open PRs as draft using the `--draft` flag with `gh pr create`
- PR titles use the same prefix pattern as commit messages — `<project>: ...` or `<project>(<binding>): ...` when the change is scoped to a single language binding

# Planning
- When asked to output a plan / tracking document, always put it in agent-plans/ directory which is at the root of the git repo. If it doesn't exist create it
