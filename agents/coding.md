---
title: "Coding Standards"
description: "Load this file when a task involves source files, scripts, or configuration."
---

# Coding Standards

Load this file when a task involves source files, scripts, or configuration.
Load the language-specific file named in `AGENTS.md` before editing that
language.

## Formatting and Linting

Use the formatter and linter defined by the applicable language file. Treat
those tools as authoritative and do not recommend conflicting style changes.

## Code Comments

- Prefer clear names and small functions over explanatory comments.
- Add a brief comment or docstring when a function’s purpose or non-obvious behavior would not be clear to a reader.
- Use comments to explain intent, constraints, tradeoffs, or non-obvious behavior.
- Avoid restating what the code already says.
- Keep comments accurate and update or remove them when the code changes.
- Use language-appropriate comment styles and follow the repository’s existing conventions.
- These rules govern code committed to a project. Throwaway scripts written for the agent's own tool use follow the Tool Calling rules in `AGENTS.md`.

## Project Level AGENTS.md Replication

An application project is a repository that builds a deliverable program or
service, as opposed to a notes, configuration, or guidance repository.

Each application project should have:

- `AGENTS.md` file in the root
- `agents` folder for subfiles, skills, etc

For each subfile that you load, if it is relevant to the project, copy it to the
project level agents folder, and update the `AGENTS.md` "Topic Routing" table,
linking it to the subfile.

Project copies are snapshots of the files in `~/.agents`. The project's own
`AGENTS.md` is authoritative for that project, and `agents/AGENTS.md` in a
project refers to the project copy, not the global one. Refresh a copy from
`~/.agents` when the source changes, and record in the project `AGENTS.md` where
a copy was deliberately modified.

## Project Specification, Handoff, and Changelog

Each application project has three living documents in its root, in addition to
`README.md` and `AGENTS.md`. Together they let an engineer or agent who has not
seen the code understand the project, rebuild it, and continue the work.

| File | Role | Question it answers |
| --- | --- | --- |
| `ENGINEERING.md` | Primary specification | What must the system do, and how? |
| `HANDOFF.md` | Outstanding work | What is left, and where do I resume? |
| `CHANGELOG.md` | History of all work | What was done, on which branch, when, and by whom? |

Link all three from `README.md` and `AGENTS.md`.

**All entries in `HANDOFF.md` and `CHANGELOG.md` MUST have an ISO 8601 UTC
timestamp recording when the entry was written or last updated.** This is the
authoring time, never a git commit or merge time (see "Facts that come from git"
below).

### Precedence and reading order

- `ENGINEERING.md` is the source of truth for behavior and design. When the
  code, `README.md`, or any other document disagrees with it, treat that as a
  defect: decide which is correct, then make them agree in the same change set.
  Change requirements in `ENGINEERING.md` first, or in the same change set as
  the code, never only in the code.
- `README.md` is the user-facing summary of the specification and `AGENTS.md`
  routes agents; neither may contradict `ENGINEERING.md`.
- At the start of a session read `AGENTS.md`, then `ENGINEERING.md`, then
  `HANDOFF.md`, then the newest `CHANGELOG.md` entries.
- Write the `CHANGELOG.md` entry and update `HANDOFF.md` in the branch, in the
  same pull request as the work, so both are final when it merges. Also update
  `HANDOFF.md` whenever work is paused or abandoned. Never write a fact into
  either file that only exists after the pull request is opened or merged (see
  "Facts that come from git" below).

### ENGINEERING.md: primary specification

Write it so that someone who has not seen the code could build an equivalent
project from this file alone, and verify that they did. Describe the system as
it is now; history belongs in `CHANGELOG.md` and unfinished work in
`HANDOFF.md`. Do not leave `TODO` markers in it.

- State requirements with RFC 2119 words (MUST, SHOULD, MAY) and give each a
  stable ID (for example `REQ-OUT-3`) so tests, changelog entries, and handoff
  items can refer to it. Keep rationale in plain prose next to the requirement.
- Be exact. Where behavior is non-trivial, give the rules step by step,
  including edge cases, ordering, tie-breaks, limits, defaults, and exact
  user-visible strings, plus at least one worked example.
- Start with a header recording the status, the date (ISO 8601, UTC) it was last
  reviewed against the code, and the base branch. Do not record a commit id: a
  commit cannot name itself, and git history identifies the revision.

Required sections:

1. Overview: purpose, scope, non-goals, and audience.
2. Requirements: functional and non-functional (security, privacy,
   compatibility, accessibility, performance), each with an ID.
3. External interfaces: commands, flags, environment variables, configuration,
   exit codes, and the stdout and stderr contract, with defaults and validation.
   Flags and exit codes follow `cli.md`.
4. Data: input formats and their known quirks, output formats with exact
   structure, directory and file layout, and naming rules.
5. Behavior and algorithms: every non-trivial transformation, precisely enough
   to implement.
6. Architecture: modules and their responsibilities, data flow, key types, and a
   file map with a one-line purpose per file.
7. Security and privacy model: trust boundaries, untrusted inputs, threats,
   mitigations, and permissions.
8. Error handling and logging: failure modes, which are fatal, messages, and
   exit statuses.
9. Technology and dependencies: language and runtime versions, and each
   dependency with its version and the reason it is used.
10. Build, run, test, and release: commands, task-runner targets, CI, and
    pinned tool versions.
11. Verification plan: acceptance criteria mapped to requirement IDs and to
    tests, how to validate against realistic data, and required coverage.
    Results of running it go in `CHANGELOG.md`, not here.
12. Decisions: for each, the context, the choice, the rationale, the rejected
    alternatives, and the consequences. Mark a decision superseded rather than
    deleting it.

Check the specification periodically by giving a reviewer only this file and
asking what they would have to guess to build the project. Answer every gap in
the file. If the reviewer finds that the specification disagrees with the code,
do not quietly document the wrong behavior: fix whichever is wrong, or record
the disagreement as a stated exception in the requirement and as an item in
`HANDOFF.md`.

Keep the specification true with tests. Where it quotes the code or output
literally (templates, scripts, stylesheets, pinned versions, lists, worked
examples), add a test that reads the specification and fails when the quoted
text drifts from the code, and make the worked example executable. Show that
such a test can fail by altering the specification once and restoring it.

### HANDOFF.md: outstanding work

The single place for work that is not done and the context needed to resume it,
for the next session, whether by the same person or someone else. It holds only
open items. Remove an item in the pull request that finishes it, and record the
work in `CHANGELOG.md`; describe the state as it will be once that pull request
merges. Keep it short and current: a stale item is worse than none. Name the
owner of every item.

- Write for the merged state. HANDOFF describes the project as it will be after
  the branch merges, not as it is during review.
- Never record commit ids, pull request numbers, merge times, or pull request
  state such as "awaiting review", "pending merge", or "in flight: PR". They go
  stale at the merge, and git has them. `CHANGELOG.md` has the same ban.
- Do not track review or merge as work. An item like "review and merge PR" is the
  process, not the project.
- "In flight" is for unfinished work only. Use "none" when the branch completes
  its task.
- Say when a status was last verified. Test counts and similar facts go stale, so
  record the date, or leave out numbers that change every commit.
- Pre-PR check: before opening a PR, re-read HANDOFF and ask whether every line is
  still true the moment the PR merges.

Required sections:

1. Status: the date it was last updated, what work is in flight (by branch
   name), and the build, test, and CI results as of the date they were last
   verified.
2. Resume here: the exact next step and the commands to run first.
3. In progress: for each branch in flight other than the one this update ships
   with, its state, uncommitted or unpublished changes, and what is left.
4. Outstanding work: a prioritized list. Each item has an ID, a description, the
   reason, acceptance criteria (referring to requirement IDs where they exist),
   its owner, and what blocks it.
5. Decisions needed: the question, the options, and a recommendation.
6. Known issues, risks, and unverified areas.
7. Environment and access notes: tooling quirks, who performs which step (for
   example who pushes), and where credentials live. Never record secrets.
8. Cleanup debt: temporary files, stale branches, and unpublished changes.

### CHANGELOG.md: history of all work

A complete record of every unit of work: each branch, what it did, and by whom.
Newest first, in one list. Include direct commits to the default branch and work
that predates the file; when adopting this standard, backfill from the repository
history. Keep abandoned and superseded work listed with its outcome. Use one
entry per branch, even when branches are stacked.

Write the entry in the branch, in the same pull request as the work. For
abandoned or superseded work that will not merge, record the entry on the default
branch through a small docs-only branch and pull request (or the next pull
request), with `Outcome` filled in. Use this template:

```markdown
---
### <branch-name>: <one-line summary>

- Branch: `<branch>`, base `<base>`
- Outcome: abandoned | superseded, and why (omit when the work is merged)
- Worked on by: <person> (<role>); <AI agent and model> (<tool>, <role>)
- What it did: <behavior and design changes, as bullets>
- Spec and docs: <ENGINEERING.md sections and requirement IDs changed>
- Verification: <what was run and the result; what was not exercised>
- Notes: <surprises, reverts, incidents, and items moved to HANDOFF.md>
```

#### Facts that come from git

An entry holds only what is known when the work is done. It never holds the pull
request number, the merge time, the merged status, commit ids or ranges, or
commit times. Those facts do not exist until after the entry is written, so
copying them in forces a follow-up commit after every merge, and a merge that
outruns that commit leaves the file wrong. They are already in the repository:
a merge commit made by the hosting service names the pull request and the
branch, and carries the merge time, and its two parents give the branch's
commits.

Provide a command that prints them for every entry, read from git and in UTC,
for example `make changelog/status`. Check with a test that the entries hold no
such facts. Entries written before the rule keep what they have; mark them as
backfilled history.

#### Rules

- Write every timestamp you do record as ISO 8601 in UTC, for example
  `2026-10-16T15:30:01Z`. To convert a git time to UTC, use the epoch
  (`date -u -r $(git log -1 --format=%ct <rev>) +%Y-%m-%dT%H:%M:%SZ`) or git's
  `format-local` date style with `TZ=UTC`; git's `format` style keeps the
  commit's own offset.
- Name each person once by their canonical name and GitHub handle, and list
  their other git identities as aliases. Give roles such as author, reviewer,
  pusher, and merger.
- For an AI agent, record the product, the model and version, and the tool it
  ran in, for example "Claude Sonnet 5.5, via Claude Code". Write "not recorded"
  rather than guessing, and credit tools such as Copilot Autofix when a commit
  trailer shows them.
- Never record secrets, and do not copy private data into an entry.
- Correct an entry by amending it with a dated note, not by silently rewriting
  what happened.

## Documentation

- Keep documentation aligned with code and configuration changes.
- Prefer concise, task-focused documentation with clear headings and examples.
- Update README files, usage notes, and references when behavior, setup, or workflows change.
- Avoid adding documentation that simply repeats obvious code behavior.

## Input Validation

When a task adds a user-facing input field and does not define its validation
requirements, ask the user what validation to apply. Do not silently choose
free-form input or invent validation rules.

## Error Handling

- Handle errors where they can be acted on and surfaced meaningfully.
- Prefer explicit, actionable error messages over generic failures.
- Avoid swallowing errors unless there is a documented reason to do so.
- Use retries, fallbacks, or graceful degradation only when they are appropriate for the specific failure mode.
- Keep failure behavior consistent with the surrounding code and project conventions.

## Testing and Validation

- Test behavior, including unhappy paths, empty states, and invalid inputs.
- Match the project's existing test framework instead of introducing a second one.
- Add or update tests when changing behavior, fixing bugs, or covering regressions.
- Run the narrowest relevant executable check after each substantive edit.
- Preserve public APIs unless a breaking change is explicitly requested.
- Keep unrelated refactors out of the change.
- If tests are missing, add at least one focused test that covers the changed behavior or regression.

## Version Selection

- Prefer recent, supported language SDKs, compilers, and libraries.
- Pin libraries and tools in project configuration instead of using `latest`.
- Prefer minimal version bumps unless a broader upgrade is needed.

## Code Generation

- Match the existing project conventions before applying defaults.
- For languages that have a language-wide coding style, use that.
  - Go: [Effective Go](https://go.dev/doc/effective_go), formatted with `gofmt`
  - C#: C# [Coding Conventions](https://github.com/ktaranov/naming-convention/blob/master/C%23%20Coding%20Standards%20and%20Naming%20Conventions.md)
  - Rust: `rust_style_guide.md`
  - Python: [PEP 8](https://peps.python.org/pep-0008/); there is no `python.md`, so use the project's configured formatter and linter
- Include the standard header or preamble required by the language file.
- Use existing snippets and helpers when they solve the same problem.
- Distinguish project conventions and code structure from formatting rules; defer formatting to the project’s formatter and linter.

## Maintenance and Compatibility

- Fix root causes instead of applying surface-level patches.
- Prefer the standard library for trivial functionality.
- Do not wrap every function in `try/catch`; handle errors where they can be acted on.
- Remove dead code or explain why it must remain.
- Do not use deprecated APIs unless migration is explicitly out of scope.
- Never hardcode credentials, account IDs, or environment-specific values.
- Treat compiler and linter warnings as errors unless there is a documented reason not to.

## Public API and Compatibility

- Document public APIs in markdown when other agents or contributors need to use them.
- Preserve backward compatibility unless a breaking change is requested.
- Document or call out breaking changes clearly when they are unavoidable.
- Keep input and output contracts stable unless the task explicitly changes them.
- Update examples and references when public behavior changes.

## Security Considerations

- Validate and sanitize untrusted input before use.
- Avoid shell injection, path traversal, and unsafe deserialization patterns.
- Do not log secrets or sensitive identifiers.
- Use the least-privilege approach when handling credentials, tokens, and permissions.
- Treat security-sensitive changes conservatively and follow existing project patterns.

## Concurrency and Timing

- Be explicit about timeouts, retries, and cancellation behavior when relevant.
- Avoid race conditions by using the project’s established synchronization patterns.
- Keep operations idempotent when they may be retried or run concurrently.
- Document ordering assumptions when they matter to correctness.

## Command-Line Interface

All applications implement the standard arguments in [`cli.md`](cli.md),
including `--help`, `--version`, and the `--about` metadata schema. Do not
restate those rules here.
