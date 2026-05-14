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
    - Don't remove existing unrelated comments
- Order matters for readability (even if it doesn't affect semantics). On the first read, a file is read top-down, so put important things near the top. The main function goes first.
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
- When commiting, always ignore ./cargo/config.toml and Cargo.lock changes (unless Cargo.toml also changes)
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
- Start the commit messages with the project name, e.g.:
    - When working in libstreaming, start all commit messages with: `libstreaming: `
    - When working in assigner_client, start all commit messages with: `assigner_client: `
    - When working across multiple projects in the domain/streaming, start all commit messages with: `streaming: `
- Commit messages must explain why the change is being made, not just what changed.

# Github
- Use the `gh` CLI to interact with github
- Always open PRs as draft using the `--draft` flag with `gh pr create`

# Planning
- When asked to output a plan / tracking document, always put it in agent-plans/ directory which is at the root of the git repo. If it doesn't exist create it
