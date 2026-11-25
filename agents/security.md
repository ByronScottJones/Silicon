---
title: "Security Engineering"
description: "Load this file for security-sensitive design, implementation, review, or deployment work."
---

# Security Engineering

Load this file for security-sensitive design, implementation, review, or
deployment work.

## Secure Design

- Identify assets, trust boundaries, abuse cases, and security assumptions.
- Use authentication for identity and authorization for access decisions.
- Apply least privilege to users, services, credentials, and deployment roles.
- Validate untrusted input at boundaries and encode output for its destination.
- Prefer secure defaults and fail closed for authorization decisions.

## Secrets and Data

- Never commit or log credentials, tokens, private keys, or sensitive personal data.
- Use an approved secret manager and rotate credentials when exposure is suspected.
- Classify sensitive data and minimize collection, retention, and access.
- Redact secrets from errors, logs, traces, test fixtures, and support bundles.

## Public Repositories

Apply this section to every repository that is public or may become public.
The `~/.agents` guidance repository is public.

- Public means permanent. Content and Git history are copied and indexed
  within minutes, and deleting it later does not unpublish it.
- Commit only content that is safe for anyone to read. Never commit:
  - secrets, including those in examples, fixtures, and history;
  - employer-internal or confidential information, such as internal hostnames,
    URLs, ticket, wiki, and chat links, system or customer names, and
    non-public architecture;
  - personal contact details, such as email addresses and phone numbers;
  - absolute local paths that contain a user name;
  - machine, network, or account identifiers that are not required.
- Use placeholders: `example.com`, `<owner>`, `$HOME`, and GitHub noreply
  addresses (`<id>+<user>@users.noreply.github.com`). Describe an internal
  dependency generically, such as "the corporate proxy", unless the file
  cannot work without the exact name.
- Set the commit author email to a GitHub noreply address before the first
  commit, and check `git config user.email` before committing.
- Install the pre-commit guard in each public repository and each clone. The
  guard is `.github/hooks/pre-commit` in the `~/.agents` repository;
  `core.hooksPath` does not copy it. In another repository, copy that file
  (executable) and its `tests/` directory to the same path, then run
  `git config core.hooksPath .github/hooks`. After a clean scan the guard runs
  the repository's own `.git/hooks/pre-commit`, so existing hooks, such as the
  Rust hook in `snippets/SNIPPETS.md`, keep working.
- Keep private patterns, such as employer or project names, in the untracked
  file shown by `git rev-parse --git-path sensitive-denylist`. A pattern that
  fails to compile blocks the commit. Never bypass the guard with
  `--no-verify`.
- Never create a public repository or change visibility to public without the
  user's explicit confirmation. Before doing so, scan the tracked files and the
  full history.
- If something sensitive is committed, stop and tell the user. Revoke or rotate
  any credential first and treat it as compromised, because forks, caches, and
  clones may keep it. Remove it from the tree, and rewrite history only with
  the user's approval.

## Supply Chain

- Pin dependencies and actions where reproducibility and integrity require it.
- Scan dependencies, container images, and generated artifacts for known issues.
- Review licenses, provenance, maintenance status, and transitive dependencies.
- Record accepted risks with an owner, rationale, and expiration date.

## Verification

- Add security tests for authorization, input validation, and abuse-prone paths.
- Review threat-model changes when architecture or trust boundaries change.
- Treat security guidance as supplementary to platform-specific controls.
