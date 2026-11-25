---
title: "Markdown"
description: "Load this file when creating, editing, or reviewing Markdown files."
applies_to: ["*.md"]
---

# Markdown

Load this file when creating, editing, or reviewing Markdown files.

## Structure

- Start each document with one top-level `#` heading, placed immediately
  after any YAML front matter.
- Use headings in a logical hierarchy; do not skip levels for visual styling.
- Keep each document focused on one topic and identify its intended audience.
- Use short paragraphs and lists when they improve scanning.
- Keep related guidance together and avoid duplicating rules owned by another
  topic file.

## Links and References

- Use descriptive link text rather than bare URLs or phrases such as “click
  here.”
- Use relative links for files in the same repository.
- Verify that referenced files, anchors, commands, and examples exist.
- Keep external links current and link to authoritative sources.

## Code and Examples

- Use fenced code blocks with a language identifier, such as `bash`, `go`, or
  `makefile`.
- Preserve syntax-sensitive whitespace in examples. Makefile recipes require
  literal tab characters.
- Label fragments as examples or integration snippets when they are not
  standalone programs.
- Keep examples minimal, safe, and consistent with the surrounding guidance.
- Never include real credentials, tokens, or private data in examples.

## Lists and Tables

- Use consistent list markers and indentation throughout a document.
- Leave blank lines around headings, lists, tables, and fenced code blocks when
  required by the configured linter.
- Use tables for compact comparisons, not for long prose or nested content.
- Keep table columns aligned with the repository's Markdown style.

## Linting

- Run the repository's configured Markdown linter after editing Markdown:

  ```bash
  npx --yes markdownlint-cli2 '**/*.md' '#.git/**'
  ```

- Fix lint errors instead of suppressing them broadly.
- Add a narrowly scoped rule exception only when the content requires it, and
  document the reason in the lint configuration or the relevant file.
- Run `git diff --check` to catch trailing whitespace and other patch errors.

## Review Checklist

- Confirm the document is routed from `AGENTS.md` when it is a reusable topic.
- Check that normative language is intentional: distinguish requirements,
  recommendations, and optional examples.
- Check for contradictions with more general or more specific guidance.
- Confirm commands and file paths are accurate for the stated platform.
- Confirm sensitive values are not exposed in prose or code examples.
