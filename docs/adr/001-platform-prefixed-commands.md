# ADR 001 – Platform-Prefixed Command Scripts

**Status:** Accepted  
**Date:** 2026-05-14

---

## Context

SoC CLI automates GitHub organization management tasks (creating repos, teams,
projects, invitations, …).  Initially the entire tool was a single monolithic
script (`gh-soc`) that could only target the GitHub platform via the GitHub CLI
(`gh`).

The project was renamed **soc-cli** to reflect a broader vision: the same
workflow should be usable on other Git hosting platforms (e.g. Gitea via the
`tea` CLI, GitLab via `glab`).  This required an architecture that cleanly
separates platform-specific logic from common glue code and from the entry
point.

---

## Decision

We adopt a **platform-prefixed command-script** model inspired by `git`.

### 1. `soc` – dispatcher

A thin `soc` script acts as the entry point for all commands.  It reads
`SOC_PLATFORM_CLI` from `system_config.sh` (default: `gh`) and resolves the
concrete executable to run:

```
soc open
  → reads SOC_PLATFORM_CLI='gh'
  → exec soc-gh-open "$@"

soc open
  → reads SOC_PLATFORM_CLI='tea'
  → exec soc-tea-open "$@"
```

Resolution order:

1. `soc-<platform>-<cmd>` – platform-specific variant (preferred).
2. `soc-<cmd>` – platform-agnostic fallback (for commands that do not depend
   on any external CLI).

### 2. `soc-lib.sh` – common library

Contains utilities that are independent of any particular platform:

- Error handling, visual indicators (`OK`, `YUP`, `WRN`, `ERR`).
- `source_config_files()` – sources the three configuration files.
- Tool-presence checks for `git`, `sed`, `grep`, `jq`, `date`, `touch`.
- All `validate_*` functions.

### 3. `soc-lib-gh.sh` – GitHub platform library

Contains everything specific to the GitHub CLI (`gh`):

- `check_if_gh_installed()`, `check_if_gh_has_required_token_scopes()`.
- All GitHub API / GraphQL helper functions.
- All main command implementations: `init`, `precheck`, `open`, `close`,
  `sync`, `unsync`, `log`, `status`, `assign`, `unassign`, `invite`,
  `disinvite`, `delete`.

### 4. `soc-gh-*` – platform-specific command scripts

One executable file per command, named `soc-gh-<cmd>`.  Each file:

1. Sources `soc-lib.sh` and `soc-lib-gh.sh`.
2. Sources configuration files (except `soc-gh-init`).
3. Calls `precheck 0` and `check_if_gh_has_required_token_scopes` (except
   `soc-gh-init` and `soc-gh-precheck`).
4. Delegates to the corresponding command function.

Current set:

| Script             | Command       |
|--------------------|---------------|
| `soc-gh-init`      | `soc init`    |
| `soc-gh-precheck`  | `soc precheck`|
| `soc-gh-sync`      | `soc sync`    |
| `soc-gh-unsync`    | `soc unsync`  |
| `soc-gh-open`      | `soc open`    |
| `soc-gh-close`     | `soc close`   |
| `soc-gh-invite`    | `soc invite`  |
| `soc-gh-disinvite` | `soc disinvite`|
| `soc-gh-assign`    | `soc assign`  |
| `soc-gh-unassign`  | `soc unassign`|
| `soc-gh-log`       | `soc log`     |
| `soc-gh-status`    | `soc status`  |
| `soc-gh-delete`    | `soc delete`  |

### 5. `gh-soc` – GitHub CLI extension entry point

The file `gh-soc` is kept so that users can continue to invoke the tool as
`gh soc <command>` through the GitHub CLI extension mechanism.  It is now a
one-line thin wrapper that delegates to the `soc` dispatcher:

```bash
exec "$(dirname "${BASH_SOURCE[0]}")/soc" "$@"
```

### 6. `SOC_PLATFORM_CLI` in `system_config.sh`

The `init` command generates a `system_config.sh` file that now includes:

```bash
readonly SOC_PLATFORM_CLI='gh'
```

This variable is the single source of truth for which platform a given working
directory targets.  Changing its value (e.g. to `'tea'`) switches all `soc`
commands to the corresponding `soc-tea-*` scripts.

---

## Consequences

### Positive

- Adding support for a new platform (e.g. Gitea) requires only:
  - A new `soc-lib-tea.sh` with Gitea-specific helper functions.
  - New `soc-tea-<cmd>` scripts.
  - Setting `SOC_PLATFORM_CLI='tea'` in `system_config.sh`.
- The common library (`soc-lib.sh`) and the dispatcher (`soc`) never need to
  change when a new platform is added.
- Each command script is small and easy to read in isolation.

### Negative / Trade-offs

- More files to install compared to the original monolith.
- `soc-lib-gh.sh` is still large; further decomposition may be needed as
  new platforms are added (to identify which utilities are truly common).
