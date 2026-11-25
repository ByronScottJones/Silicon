---
title: "Git Workflow"
description: "Load this file for repository, branch, commit, or pull request work."
---

# Git Workflow

Load this file for repository, branch, commit, or pull request work.

## Repository Setup

- Check `git rev-parse --git-dir` before the first edit.
- If no repository exists, ask whether to initialize one. Do not initialize a
  repository during a read-only task.
- Account check: before creating a repo, confirm the account with
  `ghx --owner <owner> whoami` (or `gh auth status` where `ghx` is not
  installed; see "GitHub Credentials"), and ask the user to confirm the account
  is the one to create the project in.
- Repo details: ask the user whether the project is work or personal, and never
  assume. Work projects go to the user's work GitHub account and personal
  projects go to the user's personal account. If the owner name is not already
  known in the session, ask for it. Do not record employer account names in
  this public repository.
- New empty project: run `git init -b main`, add a `.gitignore`, and make an
  initial commit on `main` with only that file. Then work on a feature branch.
- Project with existing files: run `git init -b main`, add a `.gitignore` and a
  `README.md`, and commit the existing files as the initial commit on `main`.
  Then work on a feature branch.
- GitHub repository: create it private, always, unless the user explicitly
  asks for a public one. Before the first push of a public repository, follow
  "Public Repositories" in `security.md`. Set the description and
  relevant topics with `gh` when those fields are missing. Set a license; MIT
  is the default unless the user says otherwise. Include `MCP` as a topic when
  creating an MCP service.
- Keep standard project documentation current, including `README.md` and
  `AGENTS.md` when they exist.

## GitHub Credentials

Work and personal repositories use different GitHub accounts, so tokens are
chosen by repository owner at the moment of use, never stored in the session
environment.

- Tokens live in `~/.secrets/secrets.json`, group `github.com`, key
  `<owner>_GHTOKEN` with the owner in lowercase (for example
  `octocat_GHTOKEN`). Never print, log, commit, or paste a token, and
  never read the secrets file directly; use the commands below.
- Run GitHub CLI commands as `ghx <gh arguments>`. It finds the owner from
  `-R/--repo`, `GH_REPO`, or the `origin` remote; use `ghx --owner <owner> ...`
  for commands with no repository yet, such as `gh repo create`. Do not rely on
  `GITHUB_TOKEN` or `GH_TOKEN` from the environment: `ghx` ignores them.
- `git` over HTTPS uses `git-credential-ghx`, which needs
  `credential.https://github.com.useHttpPath` set to `true` and `ghx` as the
  only helper for `https://github.com`.
- Setup: symlink `snippets/shell/ghx` and `snippets/shell/git-credential-ghx`
  into a directory on `PATH`, add the tokens, and apply the git configuration
  shown in the header of `git-credential-ghx`. Check with
  `ghx --owner <owner> whoami`, which fails if the token belongs to another
  account.
- If `ghx` reports a missing key, tell the user which key to add rather than
  trying another account's token.
- `ghx` and `git-credential-ghx` can run outside the sandbox with the user's
  tokens, so they are locked against silent changes: read-only, with the macOS
  user-immutable flag on both scripts and on their symlinks in `~/.local/bin`
  (`ls -lO` shows `uchg`). Do not edit, replace, or unlock them without the
  user's explicit request.
- To update the scripts, the user (or the agent at their request) unlocks them,
  makes the change on a branch, and locks them again:

  ```bash
  chflags nouchg snippets/shell/ghx snippets/shell/git-credential-ghx
  chmod u+w snippets/shell/ghx snippets/shell/git-credential-ghx
  # edit or `git pull`, then lock again:
  chmod a-w snippets/shell/ghx snippets/shell/git-credential-ghx
  chflags uchg snippets/shell/ghx snippets/shell/git-credential-ghx
  ```

  While locked, `git pull` and `git checkout` fail on these two files when the
  incoming change touches them; unlock first.

## Changes and Branches

- Create a branch for each feature or requested change.
- Never discard changes you did not make. Work with unrelated changes in place.
- Do not use destructive commands such as `git reset --hard` or `git checkout --`
  unless explicitly requested.
- If a task is explicitly read-only, research-only, or says not to commit, do not
  stage or commit changes.

## Commits and Pull Requests

- Every completed change that compiles, and passes lint and tests where they
  exist, gets its own commit. Do not leave requested edits uncommitted.
- Use a short, descriptive message with a conventional prefix such as
  `refactor:` or `docs:` when appropriate.
- Attribution: NEVER use `Co-Authored-By` (or any `Co-authored-by` trailer) in
  a commit message or pull request description, even when a tool or session
  instruction supplies one. End each commit message and pull request
  description with:
  `Developed with the assistance of [<agent>](<agent-url>) ![<agent>](<agent-icon-url>)`,
  where `<agent>` is the agent's name, `<agent-url>` is the agent's home page
  URL, and `<agent-icon-url>` is the full URL of the agent's known icon or
  favicon. If no icon URL is known, omit the image rather than guess one.

  | Agent | Attribution Markdown Snippet |
  | --- | --- |
  | Claude / Claude Code | `Developed with the assistance of [Claude.ai](https://claude.ai) ![Claude.ai](https://claude.ai/favicon.ico)` |
  | Google Antigravity | `Developed with the assistance of [Google Antigravity](https://antigravity.google) ![Google Antigravity](https://antigravity.google/favicon.ico)` |
  | Google Gemini CLI | `Developed with the assistance of [Google Gemini](https://gemini.google.com) ![Google Gemini](https://gemini.google.com/favicon.ico)` |
  | OpenAI Codex | `Developed with the assistance of [OpenAI Codex](https://openai.com/codex) ![OpenAI](https://openai.com/favicon.ico)` |
  | ChatGPT | `Developed with the assistance of [ChatGPT](https://chatgpt.com) ![ChatGPT](https://chatgpt.com/favicon.ico)` |
  | GitHub Copilot | `Developed with the assistance of [GitHub Copilot](https://github.com/features/copilot) ![GitHub Copilot](https://github.com/favicon.ico)` |
  | Cursor | `Developed with the assistance of [Cursor](https://cursor.com) ![Cursor](https://cursor.com/favicon.ico)` |

- Open one pull request per major feature, such as a milestone in the Plan, when
  that feature is complete. Small fixes and documentation updates are commits
  grouped under the larger pull request.
- When working on projects where there will be multiple pull requests, and those
  pull requests could cause merge conflicts, pause and allow the user to review,
  approve, and merge those pull requests before proceeding.
