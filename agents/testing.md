---
title: "Testing"
description: "Load this file when defining test strategy or adding tests."
---

# Testing

Load this file when defining test strategy or adding tests. Language files own
tool-specific commands and conventions.

## Strategy

- Test behavior at the narrowest useful layer: unit, integration, contract,
  end-to-end, smoke, and acceptance tests as appropriate.
- Test success paths, failure paths, boundaries, empty states, and cancellation.
- Prefer deterministic tests with isolated data and controlled time.
- Use real dependencies when integration behavior is the subject; use test
  doubles when isolation is the subject.

## Test Quality

- Match the project's existing test framework and test layout.
- Avoid tests that depend on execution order, wall-clock timing, or shared state.
- Treat flaky tests as defects; quarantine them only with an owner and removal plan.
- Use coverage to find untested behavior, not as the only quality measure.

## Delivery

- Run focused tests before broader suites.
- Run unit and integration tests in CI for every relevant change.
- Make external test resources disposable and clean them up after each run.
- Record required services, environment variables, and setup steps in documentation.
