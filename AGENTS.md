# Agent Instructions

## Git Workflow

- Start every task by checking `git status --short --branch`.
- Keep `main` clean and in sync with `origin/main`.
- Do not commit directly to `main` unless the user explicitly overrides this workflow.
- Create a feature branch for meaningful changes before editing tracked files.
- Use descriptive branch names such as `feature/player-movement`, `fix/collision-bounds`, or `docs/update-workflow`.
- Commit related changes together with clear commit messages.
- Push the feature branch to `origin`.
- Open a pull request from the feature branch into `main`.
- Request or perform a Codex code review before merging any pull request.

## Review Expectations

- Review the PR diff before merge and confirm the changed files match the stated intent.
- For GameMaker changes, inspect `.yyp`, `.yy`, and `.gml` files for accidental resource or metadata changes.
- Keep ignored local files, generated build output, and editor-only settings out of commits.
- After a PR is merged, update local `main` with `git pull --ff-only` before starting new work.
