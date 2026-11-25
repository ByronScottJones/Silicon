---
title: "GNU Makefile Guidance"
description: "Load this file when generating, editing, or evaluating a GNU Makefile."
applies_to: ["Makefile", "*.mk"]
---

# GNU Makefile Guidance

Load this file when generating, editing, or evaluating a GNU Makefile. These
rules follow the [Cloud Posse Makefile Best Practices](https://docs.cloudposse.com/best-practices/developer/makefile/)
and are the default for new Makefiles. For an existing Makefile, adapt them to
the project's existing conventions and constraints. Use `cmake_make.md` only to
choose between CMake and GNU Make.

This file has two parts:

* **Part 1: Conventions** apply to every Makefile and module.
* **Part 2: Makefile Sections** define the twelve sections a Makefile contains,
  in order. Each section of the Makefile has a matching section here, and the
  section numbers are the same in both places.

Omit a section's content when the project has no use for it (for example, no
database), but keep the section banner with a one-line "not applicable" note so
the layout stays predictable.

---

## Part 1: Conventions

### C1. Target Naming & Namespacing

* **Namespace All Targets:** Namespace targets in larger Makefiles (e.g., `docker/build`).
* **Use Forward Slash (`/`):** ALWAYS use `/` as the target namespace delimiter.
* **NEVER Use Colons (`:`):** DO NOT use `:` in target names (e.g., `docker:build`); this silently breaks target dependencies in Make.

### C2. File Modularity & Includes

* **Separate by Namespace:** Stick all targets within a specific namespace into a separate file (e.g., place all `docker/*` targets into `Makefile.docker`).
* **Root Includes:** Include these modular files at the top of the root `Makefile` using the `-include` directive (e.g., `-include tasks/Makefile.*`).
* **Suppress Errors:** The leading `-` MUST be used to tell `make` not to error if the included folder is empty.
* **Section Ownership:** Sections 1 to 4 and 11 to 12 live in the root
  `Makefile`. Sections 5 to 10 may live in modules named for their namespace.

### C3. Variables & Arguments

* **Sane Defaults:** Set default values for all variables using the `?=` operator (e.g., `DOCKER_TAG ?= latest`) to avoid requiring excessive command-line arguments.
* **Environment Variables:** Treat environment variables like function arguments. Expect them to be passed at runtime (e.g., `make docker/build DOCKER_TAG=dev`).
* **No Evals:** DO NOT use `$(eval ...)`. It causes confusing execution paths during Make's template preprocessing and execution phases.

### C4. Execution Logic & Dependencies

* **Write Small Targets:** DO NOT embed complex, multi-line bash scripts directly inside a Makefile target.
* **Delegate Complex Logic:** Extract complex logic into standalone shell scripts (under `scripts/`) and execute those scripts from within the Makefile target. The Makefile only passes variables.
* **Use Dependencies:** Define prerequisite target dependencies to ensure required steps (like `deps`) execute and succeed prior to the main target (e.g., `build: deps`).
* **Strict Tabbing:** All leading whitespace for commands MUST be tabbed (`^T`), never spaces.

### C5. Reliability

* Avoid recursive `make` unless separate working directories or independent build graphs require it.
* Consider parallel execution when targets are independent; use `.NOTPARALLEL` only when ordering is required.
* Test the help target and the main dependency paths after changing the Makefile.

### C6. Required Layout

Sections appear in this order. Start each with a banner comment so the file
is scannable:

```text
# ----------------------------------------------------------------------
# 1. System Guards & OS Diagnostics
# ----------------------------------------------------------------------
```

| # | Makefile section | Purpose |
| --- | --- | --- |
| 1 | System Guards & OS Diagnostics | Fail early |
| 2 | Environment & Variable Definitions | Configuration panel |
| 3 | Auto-Generated Dependencies | Compiler setup |
| 4 | Help Target | Default target |
| 5 | Core Build Pipeline | Compile, link, bundle, run |
| 6 | QA, Linting, & Testing Suite | Local developer verification |
| 7 | Container & DevOps Commands | Docker and Kubernetes orchestration |
| 8 | Database Management | Schema updates |
| 9 | Release & Artifact Packaging | Production preparation, SBOM |
| 10 | CI/CD Strict Pipelines | Automation-specialized targets |
| 11 | Housekeeping | `clean`, `distclean`, `purge` |
| 12 | Phony Declarations | Explicit target protection |

---

## Part 2: Makefile Sections

## 1. System Guards & OS Diagnostics

Fail early, before any target runs, with a message that names the fix.

* **Shell and flags:** Set a strict shell so failures are not swallowed.

  <!-- markdownlint-disable MD010 -->

  ```makefile
  SHELL := bash
  .SHELLFLAGS := -eu -o pipefail -c
  .DELETE_ON_ERROR:
  MAKEFLAGS += --warn-undefined-variables --no-builtin-rules
  ```

  <!-- markdownlint-enable MD010 -->

* **Make version:** macOS ships GNU Make 3.81. If the Makefile needs 4.x
  features, check `$(MAKE_VERSION)` at parse time and fail with an upgrade hint
  (for example `brew install make`, then `gmake`).
* **OS detection:** Detect once with `UNAME_S := $(shell uname -s)` and
  `UNAME_M := $(shell uname -m)`. Branch on these in section 2 only; do not
  scatter OS conditionals through recipes.
* **Tool guards:** Provide a reusable `guard/tool-%` target that fails when a
  command is missing, and list it as a prerequisite of targets that need the
  tool. Do not check tools at parse time, so `make help` always works.
* **Variable guards:** Provide `guard/env-%` that fails when a required
  variable is empty. Use it before any destructive or remote operation
  (sections 7, 8, 9, and 11).
* **Parse-time errors** (`$(error ...)`) are reserved for conditions that make
  the whole Makefile unusable, such as an unsupported Make version.

<!-- markdownlint-disable MD010 -->

```makefile
guard/tool-%:
	@command -v $* >/dev/null 2>&1 || { echo "ERROR: '$*' is required but not installed."; exit 1; }

guard/env-%:
	@test -n "$($*)" || { echo "ERROR: variable '$*' must be set (make <target> $*=...)."; exit 1; }
```

<!-- markdownlint-enable MD010 -->

## 2. Environment & Variable Definitions

The single configuration panel. Every tunable lives here, with a default and a
one-line comment.

* Define every variable with `?=` so callers can override it (see C3).
* Group variables: identity, directories, toolchain, build mode, and
  environment-specific values.
* Derive values once with `:=` (for example `VERSION := $(shell git describe --tags --always --dirty)`);
  use `?=` only for values callers should override.
* Standard directories: `BUILD_DIR ?= build`, `ARTIFACT_DIR ?= artifacts`,
  `BIN_DIR ?= $(BUILD_DIR)/bin`, `SBOM_DIR ?= $(ARTIFACT_DIR)/sbom`.
* Build mode: `BUILD_TYPE ?= debug` (`debug` or `release`). Section 5 uses it.
* Runtime arguments: `ARGS ?=` passes arguments through to the application.
* Never give secrets a default and never commit them. Require them through
  `guard/env-%`, and follow `configuration.md`.
* Do not default to production for any remote, container, or database target.
* Use `export` sparingly, only for variables that child processes need.

## 3. Auto-Generated Dependencies

Let the compiler or toolchain discover header and source dependencies so
incremental builds are correct without hand-maintained lists.

* **C and C++:** Add `-MMD -MP` to the compile flags, collect the `.d` files,
  and include them with `-include $(DEPS)`. The leading `-` keeps the first
  build from failing.
* Place the `-include` after `.DEFAULT_GOAL := help` is set (section 4) so a
  generated `.d` file can never become the default goal.
* Write generated dependency files under `$(BUILD_DIR)`, never beside sources.
* **Cargo, Go, .NET, and Node:** The toolchain owns its dependency graph. Keep
  the banner and write "toolchain-managed" rather than duplicating it in Make.
* Do not hand-write header lists or use `makedepend`.

<!-- markdownlint-disable MD010 -->

```makefile
CFLAGS += -MMD -MP
DEPS := $(OBJS:.o=.d)
-include $(DEPS)
```

<!-- markdownlint-enable MD010 -->

## 4. Help Target

The default target. Running `make` with no arguments prints the help menu.

* **Default Target:** Make help the default target with `.DEFAULT_GOAL := help`.
  Do not define a separate `default` target.
* **Comment Syntax:** Document all user-facing targets with a double-hash comment (`##`) on the preceding line.
* **Help Implementation:** You MUST include the following `awk` script in the Makefile to auto-generate the help menu:

<!-- markdownlint-disable MD010 -->

```makefile
.DEFAULT_GOAL := help

## This help screen
help:
	@printf "Available targets:\n\n"
	@awk '/^[a-zA-Z\-_0-9%:\\\/]+/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = $$1; \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			gsub("\\\\", "", helpCommand); \
			gsub(":+$$", "", helpCommand); \
			printf "  \x1b[32;01m%-35s\x1b[0m %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST) | sort -u
	@printf "\n"
```

<!-- markdownlint-enable MD010 -->

* The pattern character class includes `/` so namespaced targets such as
  `docker/build` appear in the menu.
* Test `make` and `make help` after every change to the Makefile.

## 5. Core Build Pipeline

Compiling, linking, bundling, installing, and running the application.

* **Standard Targets:** Define `deps`, `build`, `install`, and `all` when they
  match the project workflow. Chain them with dependencies (`build: deps`).
* **Build modes:** Provide `build/debug` and `build/release`. `build` builds
  `$(BUILD_TYPE)`. Debug keeps symbols and assertions; release enables
  optimization and strips or separates symbols. Each mode writes to its own
  directory (`$(BUILD_DIR)/debug`, `$(BUILD_DIR)/release`) so switching modes
  never reuses stale objects.
* **Display Artifact Paths:** Always display the full path to generated
  artifacts. For build steps, include instructions for running the application.
* **Run:** See below.

### Running debug or release

Provide `run/debug` and `run/release`, following the namespacing in C1.

* `run/debug` depends on `build/debug` and `run/release` depends on
  `build/release`, so each always runs current code.
* `run` is a convenience that runs `run/$(BUILD_TYPE)`, so `make run` runs
  debug and `make run BUILD_TYPE=release` runs release.
* Pass application arguments with `ARGS`, for example
  `make run/release ARGS="--port 8080"`.
* Do not parse `$(MAKECMDGOALS)` or accept bare mode words such as
  `make run debug`.

<!-- markdownlint-disable MD010 -->

```makefile
# Integration snippet: run targets
## Run the app in $(BUILD_TYPE) mode (default: debug)
run: run/$(BUILD_TYPE)

## Build and run the debug binary
run/debug: build/debug
	@echo "Running $(BUILD_DIR)/debug/$(PROJECT_NAME)"
	@$(BUILD_DIR)/debug/$(PROJECT_NAME) $(ARGS)

## Build and run the release binary
run/release: build/release
	@echo "Running $(BUILD_DIR)/release/$(PROJECT_NAME)"
	@$(BUILD_DIR)/release/$(PROJECT_NAME) $(ARGS)
```

<!-- markdownlint-enable MD010 -->

## 6. QA, Linting, & Testing Suite

Local developer verification. These targets must be safe to run repeatedly.

* **Targets:** `lint`, `fmt`, `fmt/check`, `test`, `test/unit`,
  `test/integration`, `coverage`, and an aggregate `check` that runs
  `fmt/check`, `lint`, and `test`.
* `lint`, `fmt/check`, and `test` MUST NOT modify tracked files. Only `fmt`
  rewrites sources.
* Each target exits non-zero on failure and prints what failed. Do not mask
  failures with `-` or `|| true`.
* Write reports and coverage output under `$(ARTIFACT_DIR)/reports` and show
  the path.
* Declare tool prerequisites with `guard/tool-%` (section 1).
* Keep test strategy and implementation in `testing.md`; the Makefile only
  invokes the project's runner.
* Unit tests should not require containers, databases, or network access.
  Put those under `test/integration`.

## 7. Container & DevOps Commands

Docker and Kubernetes orchestration, namespaced `docker/*` and `k8s/*`. This
section normally lives in `Makefile.docker` and `Makefile.k8s` (see C2).

* **Targets:** `docker/build`, `docker/run`, `docker/scan`, `docker/push`,
  `k8s/validate`, `k8s/diff`, `k8s/apply`, `k8s/rollback`.
* **Tags:** Default `DOCKER_TAG` to the git version, not `latest`, and never
  push a mutable tag as the only tag. Follow `containers.md`.
* **Registry:** Require `DOCKER_REGISTRY` through `guard/env-%` before `docker/push`.
* **Safety:** `docker/push`, `k8s/apply`, and `k8s/rollback` change shared
  state. Require `guard/env-KUBE_CONTEXT` and print the target context before
  acting. Never default the context to a production cluster.
* **Dry run first:** `k8s/apply` depends on `k8s/validate` and `k8s/diff`.
  Follow `kubernetes.md`.
* **Scanning:** `docker/scan` runs the image vulnerability scan and fails on
  findings at or above `SCAN_SEVERITY ?= HIGH`.
* Do not embed credentials in recipes; read them from the environment.

## 8. Database Management

Schema updates, namespaced `db/*`. This section normally lives in `Makefile.db`.

* **Targets:** `db/status`, `db/migrate`, `db/rollback`, `db/seed`, `db/reset`
  (local only).
* Require `DATABASE_URL` (or the project's equivalent) through
  `guard/env-%`. Never give it a default that points at a shared database.
* `db/status` is read-only and safe anywhere.
* `db/migrate` and `db/rollback` print the target database host and name
  (never the password) and require `CONFIRM=yes` when the target is not
  `localhost`.
* `db/reset` and `db/seed` refuse to run unless `ENVIRONMENT=local`.
* Put migration logic in `scripts/`, per C4. Follow `database.md` for
  schema design, backward-compatible migrations, and rollback plans.

## 9. Release & Artifact Packaging

Production preparation. Nothing here deploys; deployment belongs to the
release process in `release.md`.

* **Targets:** `release/package`, `release/checksums`, `release/verify`,
  `libs-version`, `sbom`, and `sbom/install`.
* Build with `BUILD_TYPE=release` and stamp the version from `$(VERSION)`.
* Write artifacts under `$(ARTIFACT_DIR)` and display the full path of each.
* `release/checksums` writes SHA-256 sums next to the artifacts.
* Packaging targets MUST NOT push, tag, or publish. Those steps require
  explicit confirmation outside the Makefile or in a gated CI job (section 10).

### 9.1 Dependency Inventory & SBOM Targets

Every project Makefile that builds or ships code MUST provide these targets so
dependencies are auditable the same way in every repo.

* **`libs-version`:** Print every direct and transitive library the shipped
  artifact depends on, one `name  version` pair per line, aligned in columns,
  sorted by name. Scope it to what ships (exclude test and dev-only projects).
  Depend on `deps` so the lock/restore state is current.
* **`sbom`:** Write a CycloneDX JSON SBOM to `$(SBOM_DIR)/bom.json`
  (`SBOM_DIR ?= artifacts/sbom`). Depend on `deps`.
* **`sbom/install`:** Install the SBOM tool once, pinned in a committed
  manifest or lock file, so the tool version is reproducible. Once the
  manifest is committed, restore from it (e.g. `dotnet tool restore`) rather
  than installing the latest version, and invoke the tool by the exact,
  case-sensitive command name the manifest declares. `sbom` MUST fail
  with a clear "run `make sbom/install`" message when the tool is missing.
* **Publish/release targets:** Also write the SBOM next to each published
  artifact (`<publish dir>/bom.json`). A missing SBOM tool MUST only warn and
  skip (e.g. `sbom.sh ... --skip-if-missing`) so publishing is not blocked;
  genuine tool failures still fail the build. The standalone `sbom` target
  stays strict.
* **`clean`:** Remove `$(SBOM_DIR)` (see section 11). Add `artifacts/` (or the
  build output directory) to `.gitignore`.
* **Scripts, not recipes:** Put the logic in `scripts/libs-version.sh` and
  `scripts/sbom.sh` (see C4); the Makefile only passes variables.
  Mark all of these targets `.PHONY` (section 12) and document them with `##`
  help text.

Pick the ecosystem's standard tooling rather than parsing files by hand:

| Ecosystem | `libs-version` | `sbom` |
| --- | --- | --- |
| .NET | `dotnet list <project> package --include-transitive` | `dotnet-CycloneDX` (local tool, `dotnet-tools.json`) |
| Node | `npm ls --all --omit=dev` | `@cyclonedx/cyclonedx-npm` |
| Python | `pip freeze` or `uv pip list` in the project venv | `cyclonedx-py` |
| Go | `go list -m all` | `cyclonedx-gomod` |
| Rust | `cargo tree --prefix none` | `cargo-cyclonedx` |

Verify each tool's flags against its `--help` before writing the script; do not
rely on remembered options.

* **Self-reporting binaries:**
  All executables should have the following command line arguments:
  * `--libs-version` returns the same format as `make libs-version`.
  * `--sbom` returns the `bom.json`.

## 10. CI/CD Strict Pipelines

Targets specialized for automation, namespaced `ci/*`. CI workflows call these
targets instead of repeating commands, so local and CI behavior match.

* **Targets:** `ci/deps`, `ci/lint`, `ci/test`, `ci/build`, `ci/package`, and an
  aggregate `ci/all`.
* **Compose, do not duplicate:** `ci/*` targets depend on or call the section 5,
  6, and 9 targets with stricter variables, for example
  `ci/test: WERROR=1 FROZEN=1 test`.
* **Strict means:**
  * Non-interactive: never prompt; fail if a required variable is missing.
  * Reproducible: install from lock files only (`--frozen`, `--locked`,
    `npm ci`), with pinned tool versions.
  * Warnings are errors (`WERROR=1`).
  * No automatic fixing: `fmt/check`, never `fmt`.
  * Plain output: disable color and progress bars when `CI` is set.
* **Reports:** Write JUnit, coverage, lint, and SBOM output under
  `$(ARTIFACT_DIR)` so the workflow can upload them.
* **No publishing from `ci/*` by default.** A publish or deploy target must be
  separate, require explicit variables, and run only from a protected branch
  or tag job.
* Follow `githubactions.md` for the workflow side, including least-privilege
  permissions and pinned actions.

## 11. Housekeeping

Cleanup targets, from least to most destructive. Each level includes the one
before it.

| Target | Removes | Confirmation |
| --- | --- | --- |
| `clean` | Build outputs: `$(BUILD_DIR)`, `$(ARTIFACT_DIR)` including `$(SBOM_DIR)`, coverage and reports | None |
| `distclean` | Everything `clean` removes, plus downloaded dependencies, generated sources, local caches, and generated config | None |
| `purge` | Everything `distclean` removes, plus project containers, volumes, images, and tool or global caches the project created | `CONFIRM=yes` |

* Guard every `rm` against an empty variable: use `guard/env-BUILD_DIR` and
  `rm -rf -- "$(BUILD_DIR)"`. An empty or `/` path MUST fail, not delete.
* Never remove tracked files, user data, or anything outside the project
  directory (except a named, project-created global cache in `purge`).
* Print what was removed. Cleaning twice MUST succeed (use `rm -rf`).
* `purge` MUST print what it will remove and require `CONFIRM=yes`.

<!-- markdownlint-disable MD010 -->

```makefile
## Remove build outputs
clean: guard/env-BUILD_DIR guard/env-ARTIFACT_DIR
	rm -rf -- "$(BUILD_DIR)" "$(ARTIFACT_DIR)"

## Remove build outputs, dependencies, and caches
distclean: clean
	rm -rf -- node_modules .cache

## Remove everything the project created, including containers (CONFIRM=yes)
purge: distclean guard/env-CONFIRM
	@test "$(CONFIRM)" = "yes" || { echo "ERROR: set CONFIRM=yes to purge."; exit 1; }
	docker compose down --volumes --rmi local
```

<!-- markdownlint-enable MD010 -->

## 12. Phony Declarations

Explicit target protection, at the end of each Makefile and module. A file
named `build` or `test` in the working directory must never stop the target
from running.

* Mark every command target `.PHONY` unless it intentionally creates a file.
* Place declarations in one block at the end of the file, grouped by section
  and one group per line, so the list is reviewable. Each module declares its
  own targets in its own file.
* Include the guard targets.
* Pattern rules such as `guard/tool-%` cannot be declared `.PHONY`; give them
  recipes that never create the target file.
* Keep the list in sync: every target with `##` help text appears here.
  Verify with `make -pn | grep '^\.PHONY'` and compare against `make help`.

<!-- markdownlint-disable MD010 -->

```makefile
# 12. Phony Declarations
.PHONY: help
.PHONY: deps build build/debug build/release install all
.PHONY: run run/debug run/release
.PHONY: lint fmt fmt/check test test/unit test/integration coverage check
.PHONY: docker/build docker/run docker/scan docker/push
.PHONY: db/status db/migrate db/rollback
.PHONY: release/package release/checksums release/verify libs-version sbom sbom/install
.PHONY: ci/deps ci/lint ci/test ci/build ci/package ci/all
.PHONY: clean distclean purge
```

<!-- markdownlint-enable MD010 -->

---

## Review Checklist

* Sections 1 to 12 are present, in order, with banners.
* `make` with no arguments prints help, and every `##` target is listed.
* `make run`, `make run/debug`, and `make run/release` each build the right
  mode first.
* No target name contains `:`.
* Destructive and remote targets use `guard/env-%` and, where stated,
  `CONFIRM=yes`.
* `make clean` twice in a row succeeds.
* All command targets appear in a `.PHONY` declaration.
