---
title: "Dependency Management"
description: "Load this file when adding, upgrading, removing, or reviewing dependencies."
---

# Dependency Management

Load this file when adding, upgrading, removing, or reviewing dependencies.

## Selection

- Prefer the standard library or existing project dependencies for simple needs.
- Review maintenance, license, security history, transitive dependencies, and runtime cost.
- Add the smallest dependency that solves the problem and document non-obvious choices.

## Reproducibility

- Commit the appropriate lockfile or dependency snapshot.
- Use supported versions and define an upgrade policy rather than using unbounded latest versions.
- Keep development, test, and production dependency scopes explicit.

## Maintenance

- Scan dependencies for known vulnerabilities and end-of-life versions.
- Automate update proposals, but review breaking changes and generated diffs.
- Remove unused dependencies and document temporary exceptions.
