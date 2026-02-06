# Responses
- Be terse
- Ask me clarifying questions if I don't provide enough context

# Commands
- use `rg` instead of `grep`, don't ask for my confirmation
- use `fd` instead of `find`, don't ask for my confirmation
- ast-grep (`sg`) is available. Whenever a search requires syntax-aware or structural matching, default to `sg --lang rust -p '<pattern>'` (or set `--lang` appropriately)
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

# Ralph Loop
- When completing a ralph loop style plan, always output `<promise>COMPLETE</promise>` when done.

# Formating
- Always run the appropriate code formatting command after you've made changes

# Rust
- When running `cargo` commands directly (instead of `bzl`), run them in the crate root directory
- To validate changes, run:
    * `cargo clippy --all-targets`
    * `cargo test -- --skip=integration_test` # or run the specific set of tests scoped to the change
- Avoid silencing clippy lints with #[allow()]. Fix the underlying issue.
- When finished, format with `cargo fmt`
- Can measure coverage with:
    * `cargo +nightly llvm-cov --branch -- --skip=integration_test`
- When commiting, always ignore ./cargo/config.toml and Cargo.lock changes (unless Cargo.toml also changes)

# Git
- Start the commit messages with the project name, e.g.:
    - When working in libstreaming, start all commit messages with: `libstreaming: `
    - When working in assigner_client, start all commit messages with: `assigner_client: `
    - When working across multiple projects in the domain/streaming, start all commit messages with: `streaming: `

# Github
- Use the `gh` CLI to interact with github

# Atlassian
- Use `acli` when interacting with atlassian products (JIRA, confluence, etc)

