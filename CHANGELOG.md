# Changelog

All notable changes to this project will be documented in this file.

This is a rolling release - changes are deployed continuously to `main`.

---

## 2026-08-31

### Changed

- **ci-ansible-molecule.yml** caps both jobs with `timeout-minutes` (`molecule`
  at 30, `discover` at 10). A hung run previously reached the GitHub default of
  360 minutes and blocked the consuming repository's pull request for six hours;
  it now fails inside the cap. The 30 minute value is tuned for the
  KVM-accelerated `ubuntu-latest` default, where scenarios finish in 4-12
  minutes — callers overriding `runs_on` with a runner that has no `/dev/kvm`
  fall back to TCG and may need a larger value.

## 2026-08-22

### Changed

- **renovate-base.json** enables `lockFileMaintenance` (weekly, Monday before
  6am, automerged), aligned with sbaerlocher/.github. Consumer repos with
  lockfiles (e.g. `go.sum` via gomod, `package-lock.json`) now get a scheduled
  lockfile refresh PR that merges on green CI; repos without lockfiles are
  unaffected.
- **renovate-go.json** aligned with the current sbaerlocher/.github go preset:
  - Go toolchain rule split — grouping, 14-day release age and priority apply
    to every update type, while a separate rule blocks automerge only for
    major/minor. Go patch releases (1.25.11 -> 1.25.12) now automerge via the
    base non-major rule; previously every toolchain update required manual
    review.
  - `golang.org/x` and `go.uber.org` merged into one "Go ecosystem packages"
    group; `k8s.io`/`sigs.k8s.io` folded into "Go platform packages" (keeping
    `separateMultipleMajor: false` for the co-versioned k8s majors).
  - Testing, linting and dev-tool groups merged into one "Go dev tooling"
    group. Per-rule `automerge: true` and `semanticCommitType: chore`
    overrides dropped — the base preset already automerges non-majors and
    sets the chore type.
  - Blanket "major updates - manual review" and "indirect dependencies" rules
    dropped; the base major rule covers the former, and gomod indirect deps
    are not updated by default.
  - Unused custom managers removed (`.go-version`, Makefile `GO_VERSION` /
    `GOLANGCI_LINT_VERSION`, `# renovate: go-tool` comments) — no arillso
    repository matches any of them. Replaced by the Dockerfile
    `RUN go install <module>@<version>` manager used in the sbaerlocher org,
    keeping the two presets diffable.
- **.github/renovate.json** adopts the self-reference rule from
  sbaerlocher/.github: the repo's own `arillso/.github` date-tag pins (here
  and in `templates/`) skip the preset's 1-day `minimumReleaseAge` and update
  in their own branch at any time, so the pins no longer trail the current
  tag by a day or more. Consumers keep the 1-day soak. The redundant
  `github-actions` grouping rule is dropped — the base preset already groups
  actions.

## 2026-08-17

### Changed

- **ci-ansible-collection.yml** derives the sanity job's controller Python from
  the ansible-core branch instead of the caller. `ansible-test sanity --python X`
  rejects any X outside the branch's `CONTROLLER_PYTHON_VERSIONS`, so the version
  is a property of the branch, not of the consumer. The job previously pinned
  `3.12` for `devel` and `stable->=2.20` and passed `python_version` through for
  everything else, which capped every collection's sanity run at 3.13 even though
  `stable-2.20` and `devel` accept 3.14. A table now maps each branch to the
  newest interpreter it supports — `stable-2.18` and `stable-2.19` to `3.13`,
  `stable-2.20` and `devel` to `3.14` — so sanity runs closest to the interpreter
  `release-ansible-collection.yml` builds the artifact on. `devel` stops at 3.14
  rather than its maximum 3.15, which is unreleased and has no `setup-python`
  build. An unknown branch still honours the caller's `python_version`, and the
  other seven jobs keep using that input unchanged. The matrix default is
  untouched. `scripts/tests/test-controller-python-matrix.sh` asserts the table
  against dated `CONTROLLER_PYTHON_VERSIONS` tuples and runs as its own job in
  `pull-request.yml`: the sanity job executes only in consumer collections, so a
  wrong entry would otherwise surface as every collection turning red at once
  after the merge. `renovate-ansible.json` follows with `allowedVersions` at
  `<3.15`; its description claimed 3.13 as the ansible-test maximum, which the
  bound would have kept enforcing. Expect the first run after the merge to widen
  coverage: `stable-2.18` and `stable-2.19` rise from an effective 3.11 to 3.13,
  which can surface interpreter-specific sanity findings in collections that are
  green today.

### Fixed

- **security-config.yml** and **cleanup-container-registry.yml** quote three
  shell expansions that tripped `SC2086`: `$GITHUB_OUTPUT` twice in the
  Kubernetes manifest search, and `${DAYS}` in the BSD `date` fallback of the
  registry cleanup. None can misbehave with the values these actually carry —
  they were the last actionlint findings in the repository, so the linter is now
  clean and a real finding stands out.
- **workflows/README.md** documents the `ansible_versions` default of
  `ci-ansible-collection.yml` as `["stable-2.18", "stable-2.19", "stable-2.20"]`,
  matching the workflow. The section still named the pre-2026-03-08 value
  `["stable-2.16", "stable-2.17", "devel"]` — that entry raised the workflow
  default but left the consumer documentation behind, so anyone copying the
  documented array tested against two EOL ansible-core branches and added
  `devel`, which the reusable no longer selects by default.

---

## 2026-08-16

### Fixed

- **security-code.yml** derives the Go toolchain from `go.mod` instead of a
  hardcoded default. The `go-version` input defaulted to `1.25`, which silently
  applied to every consumer that omitted it, and the only way to avoid it was to
  repeat the version as a literal — `arillso/go.ansible` carried exactly that,
  with a comment asking the next reader to keep it in sync with `go.mod` by hand.
  That sync point is what let the Go 1.26.5 stdlib advisories (GO-2026-5026,
  -5942, -5972, -6088, -6089, -6090, -6091, -6218) sit unnoticed in the CodeQL
  job. `go-version` now defaults to empty and a new `go-version-file` input
  (default `go.mod`) takes over, mirroring how `security-deps.yml` has always
  resolved its toolchain. Consumers that pass an explicit `go-version` keep it;
  the input still wins when set. When neither applies — no `go-version` and no
  `go-version-file` on disk — the job falls back to `stable` rather than failing
  in `Setup Go`, so a Go repository whose module does not sit at the workspace
  root still runs. `security-deps.yml` guards the same way.

- **security-code.yml**, **security-config.yml**, **security-sbom.yml**,
  **ci-ansible-molecule.yml** and **release-go.yml** give their `concurrency`
  group a static per-workflow discriminator. Inside a `workflow_call` reusable
  `github.workflow` and `github.ref` resolve to the _caller_, so a bare
  `${{ github.workflow }}-${{ github.ref }}` group is byte-identical to the
  group the calling workflow declares for itself. With `cancel-in-progress`
  defaulting to `true` the job was dropped at scheduling time — no job record,
  no annotation, no log, just a run reporting `failure` while every job it did
  create is green. The nightly security scans of `arillso/go.ansible` and
  `arillso/action.playbook` lost their CodeQL job this way from 2026-08-12, the
  day they moved from `security-codeql.yml` to `security-code.yml`.
  `security-secrets.yml` and `ci-go.yml` already carried this fix; these five
  did not. Consumers pick it up with the next preset tag.

- **renovate-ansible.json** gives the `Molecule platform images` customManager
  an `autoReplaceStringTemplate`, so the `pinDigests` rule that sits next to it
  can actually pin. Renovate's field-wise rewrite path only rewrites tokens the
  matched line already holds: pinning a bare `:latest` leaves `currentValue`
  unchanged and has no `currentDigest` to swap, so the line came back
  byte-identical, `confirmIfDepUpdated` found no digest, and the branch was
  discarded with `Error updating branch: update failure` — all eight molecule
  pins in `arillso/ansible.agent` failed this way. A template is the only path
  that can add a token, and it reproduces the whole match (`image: ` prefix and
  trailing newline included) because `replaceAt` swaps the match as a unit; the
  `matchStrings` regex is unchanged. The digest slot is guarded by
  `{{#if newDigest}}` so a plain tag update does not emit a bare `@`. One known
  ceiling: the template writes the value unquoted with a single space after
  `image:`, so a quoted value would lose its quotes — still valid YAML, and no
  molecule scenario in the consuming repositories uses that form. Consumers pick
  the fix up when the preset tag they extend moves forward.

### Added

- **pull-request.yml** gains a `renovate-molecule-manager` job backed by
  `scripts/tests/test-renovate-molecule-manager.sh`. The check is a round trip
  rather than a string comparison: the unpinned `image:` line has to match the
  manager's regex, the rendered template has to match that same regex again, and
  the digest has to come back out of it — which is exactly the re-extraction
  `confirmIfDepUpdated` performs and exactly the step that failed. Regex and
  template are read out of the JSON with `jq` instead of restated, so the guard
  cannot drift away from the preset it guards. Without it the manager stays in a
  JSON no CI parses, and a template lost to a later edit would first surface as
  a failing Renovate run on a downstream repository.

## 2026-08-10

### Changed

- **ci-ansible-molecule.yml** prefixes the molecule log artifact with
  `concurrency-suffix` when the caller sets it, so the name becomes
  `molecule-log-[<concurrency-suffix>-]<driver>-<scenario>`. Callers that run
  several molecule jobs against the same driver and scenario previously
  collapsed every log into one artifact name: `arillso/ansible.container` runs
  seven roles that all use the `default` scenario, so all seven uploads
  competed for `molecule-log-qemu-default` and the surviving log could not be
  traced back to a role. The suffix is reused rather than introduced — those
  callers already set it for the concurrency group, and each of the seven
  values is distinct — so no consumer has to pass anything new. Callers that
  leave the input empty keep the exact name they have today.

## 2026-08-09

### Added

- **renovate-alpine.json** is a new shared preset for Alpine apk pins in
  Dockerfiles, with a copy-paste consumer example in
  `templates/renovate-alpine.example.json`. `docker.ansible` and
  `action.playbook` each carry their own copy of this regex manager today, so
  every Alpine bump and every change to the match behaviour has to be applied
  twice. A two-stage recursive match first cuts the `apk add` block and then
  extracts the pins from it, which covers both the `>=` lower-bound and the `=`
  exact style in one manager; the single-stage regex in use today anchors on the
  line continuation instead and only avoids matching `ENV` values because every
  environment variable in both repos happens to be upper-case. The preset stays
  out of `renovate-base.json` because the go and ansible presets extend the
  base and would inherit repology lookups they have no pins for. It carries the
  `Alpine packages` grouping rule, so a consumer adopting it gets one grouped PR
  instead of one per pin — a behaviour change for `docker.ansible` and its 30
  pins. The Alpine release stays hard-coded at `alpine_3_24` and nothing bumps
  it; moving to a newer base image means raising it in the preset. Consumers are
  migrated separately, so the preset is unused until then and the manager never
  runs twice.
- **pull-request.yml** gains a `workflow-input-injection` job backed by
  `scripts/tests/test-workflow-input-injection.sh`. A `${{ inputs.* }}`
  reference inside a `run:` body is substituted before the shell parses the
  line, so a caller-supplied value is shell source on the runner rather than an
  argument; an unquoted heredoc expands a substituted value the same way. The
  check is structural on the YAML, so a regression fails in CI instead of on a
  consumer's runner. The scanned set is derived from the `workflow_call`
  trigger by `scripts/list-reusable-workflows.sh` rather than maintained as a
  list — a workflow missing from an allow-list is unchecked by default, and the
  reason for its absence tends to be the very defect the guard exists to catch.
  The job is red until the unquoted heredoc in `security-secrets.yml` is
  quoted, which is tracked as its own change.

### Changed

- **self-pull-request.yml**, **self-merge.yml** and **self-weekly-security.yml**
  are renamed to **pull-request.yml**, **merge.yml** and
  **weekly-security.yml**. The repository standard names these three files
  without a prefix, and an audit looks them up by exact name — under the old
  names it reported all three as missing rather than as present under a
  different name. The `self-` prefix was introduced to separate this repo's own
  CI from the reusables it ships, but no reusable here occupies any of the three
  names, so the prefix distinguished nothing. Triggers, permissions and job
  bodies are unchanged; the `readme-sync` job already discriminated on
  `workflow_call` rather than on the file name.

### Fixed

- **security-secrets.yml** excludes the `lob` detector from TruffleHog, which
  reported ordinary source code as verified credentials and failed the scan for
  consumers with nothing to find. The detector matches
  `(live|test)_[a-zA-Z0-9_]{35}` with no entropy requirement, so any
  40-character identifier beginning with `test_` qualifies — a length
  descriptive pytest function names reach routinely. Verification then POSTs an
  empty body and counts the 422 that comes back as proof the credential is
  live, which is why `--only-verified` did not filter these out. A consumer hit
  this with two test function names of exactly 40 characters, producing exactly
  two verified findings and a red scan on its default branch. Gitleaks and
  pattern detection are untouched, so a real credential is still caught by two
  of the three scanners. Upstream tracks the defect as
  trufflesecurity/trufflehog#5184; the exclusion carries a comment pointing
  there and should be dropped once a release includes the fix.

---

## 2026-08-08

### Fixed

- **ci-lint.yml**, **ci-ansible-collection.yml**,
  **cleanup-container-registry.yml**, **security-config.yml**,
  **security-deps.yml** and **security-sbom.yml** pass caller inputs into
  `run:` bodies through `env:` instead of interpolating `${{ inputs.* }}`
  directly. The workflow parser substitutes such a reference before the shell
  parses the line, so a caller-supplied value was shell source on the runner
  rather than an argument. Step summaries build their output with `printf`
  instead of unquoted heredocs, which expand a substituted value the same way,
  and argument lists are built as quoted arrays. `python_version` is
  additionally constrained to a version shape before it is written to
  `$GITHUB_OUTPUT`, because it travels from there into `setup-python` in a
  second step.
- **cleanup-container-registry.yml** parses the Docker Hub retention day count
  with the shell parameter expansion `${RETENTION_DAYS%d}` instead of
  `echo … | sed 's/d$//'`, dropping two subprocesses per run. This resolves a
  `shellcheck` `SC2001` finding that `actionlint` reports at error level and
  that therefore fails the `Lint / Action Lint` job whenever a pull request
  touches this line.

### Changed

- **ISSUE_TEMPLATE/\*.yml**, **templates/ISSUE_TEMPLATE/\*.yml**: Generalize the
  org-wide issue templates, completing the work `pull_request_template.md`
  received on 2026-08-07. The required role dropdown (Alloy, DO, Tailscale) came
  from `ansible.agent` and was meaningless in every other repository these
  org-wide defaults apply to — `go.ansible` and `guide` have no roles at all, yet
  every reporter there had to pick one. It is now an optional free-form
  `Affected Component(s)` input, matching the PR template. The bug report also
  asked for the version of `arillso.agent` specifically, and the `arillso.agent`
  playbook examples are replaced by neutral placeholders.
- **LICENSE** now states `Copyright (c) 2025-2026 Arillso` instead of the
  single year `2025`, matching the canonical `YEAR-YEAR` range used across the
  arillso repositories.
- **renovate-base.json** consumers within this repository
  (`.github/renovate.json`, `renovate-actions.json`, `renovate-ansible.json`,
  `renovate-go.json`) and all four `templates/renovate*.json` examples now pin
  the `github>arillso/.github:…` reference to a `#YYYY-MM-DD` date tag. This
  repository required every consumer to pin while extending its own presets
  untagged, and the templates are the copy-paste source for new repositories,
  so the unpinned form propagated from here. The `customManager` in
  `renovate-base.json` only matches refs that already carry a date tag, so
  these references were invisible to Renovate before and are now kept current
  automatically.
- **AGENTS.md**: The "Renovate Presets" usage table shows the pinned form and
  states why the pin is required; it previously documented the unpinned
  reference that this change removes elsewhere.

---

## 2026-08-07

### Added

- **self-pull-request.yml**, **self-merge.yml**, **self-weekly-security.yml**:
  This repository now runs its own CI, mirroring `sbaerlocher/.github`. Until
  now every workflow here was `workflow_call`-only and nothing verified the
  repository itself. Each new workflow calls this repo's own reusables through
  a local `./` path, so the workflows consumers depend on are exercised before
  they ship.
- **self-merge.yml**: Moves the `YYYY-MM-DD` date tag to the newest commit on
  `main`, forward-only and serialised via `concurrency: date-tag`. Tagging was
  manual before; the newest tag was `2026-06-18`, which is exactly what the
  consumer repositories pin — so fixes merged after that date never reached
  them without a hand-cut tag.

### Changed

- **ai-claude-review.yml**: Dropped the `pull_request:` trigger; the workflow is
  now `workflow_call`-only like every other reusable here, and
  `self-pull-request.yml` invokes it. Note that this does not change the
  `claude-code-action` workflow-validation guard: it checks every workflow file
  taking part in a run against the default branch, so a PR modifying this file
  still has its review skipped regardless of where the trigger lives.

### Fixed

- **workflows/security-code.yml**: Caller inputs (`paths-ignore`,
  `package-manager`, `build-command`) and the step summary values were expanded
  by the workflow parser into `run:` bodies, so a value carrying a command
  substitution executed on the runner with `security-events: write`. They now
  travel through `env:` and are read as shell variables; the summary heredoc is
  replaced by `printf`.
- **ai-claude-review.yml**: Read `REVIEW.md`, `AGENTS.md` and `CLAUDE.md` from
  the base ref instead of the PR's own checkout. A PR that changed these files
  rewrote the instructions of the agent reviewing it, while that agent holds
  `gh pr review --approve`. A second sparse `actions/checkout` provides them
  under `.review-base/`, and the prompt now reads only from there.

### Changed

- **workflows/security-code.yml**: `package-manager` is restricted to
  `npm | pnpm | yarn`. Its value leaves the step through `$GITHUB_OUTPUT` and is
  interpolated into a second `run:` body, so an unconstrained string would
  execute there. Any other non-empty value now fails the step; lock-file
  detection is unchanged when the input is empty.
- **pull_request_template.md**, **templates/pull_request_template.md**:
  Generalize the org-wide PR template. The fixed role checklist (Alloy, DO,
  Tailscale) came from `ansible.agent` and was meaningless in every other
  repository the template applies to — it is now a free-form
  `## Affected Component(s)` list. Removed the trailing comment block, which
  thanked contributors for the wrong repository and carried an attribution
  line the commit conventions forbid; every PR in the organization inherited
  both.

### Removed

- **workflows/release-go.yml**: The `pre-build-commands` input is removed. It
  was expanded into a `run:` body in the job holding `contents: write`,
  `packages: write` and `GITHUB_TOKEN`, and no caller sets it.

### Migration notes

- Breaking: callers that passed `pre-build-commands` to `release-go.yml` must run
  those commands in their own job before calling the workflow.
- Callers passing a `package-manager` other than `npm`, `pnpm` or `yarn` to
  `security-code.yml` will now see the run fail instead of the value being used.

## 2026-06-18

### Added

- **workflows/README.md**: Document `ci-ansible-molecule.yml` (usage, inputs,
  jobs, the `driver: docker|qemu` selector) — it was listed in the AGENTS.md
  CI table but missing from the workflow reference.

## 2026-06-17

### Added

- **ci-ansible-molecule.yml**: `driver` input (`docker` default, `qemu`) to
  pick the Molecule driver. `qemu` boots full VMs via the `molecule-qemu`
  driver for roles that need a real kernel and init system (k3s
  `modprobe`/cgroups, container engines, agents that must run as a stable
  `systemd` service — under docker the unit reports started while it has
  crash-looped, masking config bugs). GitHub-hosted `ubuntu-latest` exposes a
  writable `/dev/kvm`, so the job installs
  `qemu-system-x86`/`qemu-utils`/`genisoimage`, adds the runner to the `kvm`
  group, and runs molecule via `sg kvm`; molecule-qemu auto-detects KVM
  acceleration and falls back to TCG. Validated end-to-end on `arillso.agent`
  (alloy) and `arillso.container` (k3s).
- **AGENTS.md**: New "Ansible Collection Conventions" section documenting the
  shared release workflow shape (`name`, `run-name`, `concurrency`), the
  Keep-a-Changelog format, the cross-collection dependency-bound matrix
  (`arillso.container` → `arillso.system >=0.0.17`, `arillso.agent` →
  `arillso.system >=0.0.36`) plus min-version policy, and the common
  `.python-version` requirement
- **templates/CHANGELOG.md**: Keep-a-Changelog + SemVer template for bootstrapping
  collection changelogs
- **renovate-ansible.json**: Custom manager that keeps `.python-version` on a
  current released Python (`python-version` datasource, `pep440` versioning)

### Changed

- **AGENTS.md**: Correct the collection release workflow filename from
  `release.yml` to `tag.yml` (the event-focused template slot for tag pushes,
  alongside `pull-request.yml` / `nightly-security.yml`); the `name:` stays
  `Release - Ansible Collection`
- **release-ansible-collection.yml**: Read the publish Python version from the
  repo-root `.python-version` file when the `python_version` input is not set
  (input → `.python-version` → `3.11` fallback). The input default changed from
  `3.11` to empty; callers that pass `python_version` are unaffected, callers
  that relied on the silent `3.11` default now get `.python-version` if present.
  Makes `.python-version` authoritative for releases.

---

## 2026-06-14

### Added

- **renovate-ansible.json**: Dedicated `docker` customManager for molecule
  platform images, covering both layouts — collection-wide
  `extensions/molecule/<scenario>/molecule.yml` and per-role
  `roles/<role>/molecule/<scenario>/molecule.yml`. It parses the `image:`
  line directly (`depName` = repo, `currentValue` = bare tag, optional
  `@sha256:...` = `currentDigest`), the shape the Docker datasource needs to
  refresh the digest. A `pinDigests: true` rule scoped to those files turns a
  bare `:latest` into `:latest@sha256:...` so the test base image becomes
  reproducible and Renovate keeps the digest fresh. The native docker-compose
  manager does not apply — molecule.yml is not a compose schema (`platforms:`,
  no `services:`). Consuming collections (ansible.system, ansible.container,
  ansible.agent) get this with no per-repo config beyond the preset pin.

### Fixed

- **renovate-base.json**: The comment `customManager` greedily captured the
  entire value after a `# renovate:` marker into `currentValue`. For
  digest-pinned image references (`image: repo:tag@sha256:...`) this swallowed
  tag and digest into one string, so Renovate could not compute a valid update
  and produced noisy/failing digest bumps. `currentValue` now stops at `@` and
  an optional `@sha256:...` suffix is captured separately as `currentDigest`,
  letting consumers pin Docker images referenced from arbitrary YAML (e.g.
  molecule `platforms[].image`) via a marker comment and keep the digest fresh.
  Bare values (versions, quoted strings, plain image tags) have no `@` and match
  exactly as before

---

## 2026-06-12

### Added

- **templates/workflows/pull-request.yml**: New event-focused PR template
  (`name: Pull Request`) combining Go CI, lint, CodeQL (via `security-code.yml`),
  and Claude review (via `ai-claude-review.yml`) as jobs — replaces `ci.yml` +
  `codeql.yml`
- **templates/workflows/nightly-security.yml**: New scheduled security template
  (`name: Nightly Security Scan`) running CodeQL, secret, dependency, and Trivy
  scans

### Changed

- **templates/workflows/**: Migrate the workflow templates from the deprecated
  file-centric layout (`ci.yml`/`codeql.yml`/`deploy.yml`) to the event-focused
  layout (`pull-request.yml`/`nightly-security.yml`/`tag.yml`). `deploy.yml`
  renamed to `tag.yml` (`name: Container Release`) with a `run-name:` added;
  content otherwise unchanged
- **AGENTS.md**: Update the consumer usage example to the event-focused
  `pull-request.yml` layout and a valid reusable (`ci-go.yml`/`ci-lint.yml`,
  not the non-existent `ci-go-action.yml`)
- **README.md / SUPPORT.md / CONTRIBUTING.md**: Repoint standards references from
  the removed `STANDARDS.md` to `AGENTS.md` and `templates/`

### Removed

- **STANDARDS.md**: Removed. It mandated the deprecated file-centric workflow
  layout and duplicated conventions; the Ansible-specific standards it held are
  now tracked in the organization knowledge base, and reusable-workflow
  conventions live in `AGENTS.md` + `templates/`
- **templates/workflows/ci.yml, codeql.yml, deploy.yml**: Removed in favor of the
  event-focused templates above

- **security-secrets.yml**: Add `cancel-in-progress` and `concurrency-suffix`
  inputs with a static `security-secrets-` concurrency group (a bare
  `github.workflow`/`github.ref` group collides across reusables called by the
  same caller, since that context resolves to the caller inside `workflow_call`)
  - Update `trufflesecurity/trufflehog` from `v3.94.0` to `v3.95.5`
  - Update `actions/checkout` from `v6.0.2` to `v6.0.3`
- **ci-go.yml**: Add `go mod verify`, `go vet`, `gofmt -s -l` format check
  (scoped to first-party package dirs via `go list ./...` so `vendor/` and
  generated code don't trip the gate), and `staticcheck` (new
  `enable_staticcheck` input, default `true`); upload an HTML coverage report
  artifact
  - Add `cancel-in-progress` and `concurrency-suffix` inputs with a static
    `ci-go-` concurrency group (see security-secrets note above)
- **renovate-base.json**: Throttle `prHourlyLimit` from `0` (unlimited) to `4`;
  enable `osvVulnerabilityAlerts`; treat pre-1.0 minor bumps as breaking
  (`matchUpdateTypes: ["major", "minor"]`)
- **renovate-go.json**: Split the `google.golang.org` group into a "Kubernetes
  packages" group (`k8s.io/*` + `sigs.k8s.io/*`, co-versioned, with
  `separateMultipleMajor: false` so their majors share one PR) and a "Go platform
  packages" group (gRPC, Prometheus, `google.golang.org`, majors kept separate)

### Fixed

- **renovate-base.json**: Stop digest-pinning dependencies that cannot carry a
  digest. The base preset forces `pinDigests: true` on all `github-actions`
  deps (reinforced by `config:best-practices`), which aborted entire Renovate
  branches with "Digest is not updated" for two dependency shapes. Two targeted
  `packageRules` now set `pinDigests: false`: release binaries installed via
  helper actions (`uses-with` inputs with the `github-releases` datasource —
  gitleaks, trivy, golangci-lint — pinned by release tag, not digest) and the
  `kubesec/kubesec` docker image referenced as a bare version string. These
  deps keep updating by tag/version; only the impossible digest pin is dropped

### Dependencies

- **GitHub Actions** (Renovate batch): SHA-pinned action references updated
  - `actions/checkout` `v6.0.2` → `v6.0.3`
  - `actions/setup-go` `v6.3.0` → `v6.4.0`
  - `actions/upload-artifact` `v7.0.0` → `v7.0.1`
  - `github/codeql-action` `v4.35.5` → `v4.36.2`
  - `aquasecurity/trivy-action` `v0.35.0` → `v0.36.0`
  - `trufflesecurity/trufflehog` `v3.94.0` → `v3.95.5`
  - `snok/container-retention-policy` `v3.0.1` → `v3.1.0`
  - `anthropics/claude-code-action` `v1.0.127` → `v1.0.142`
  - Digest-only refreshes for `golangci/golangci-lint-action` (v9),
    `reviewdog/action-actionlint` (v1), `DavidAnson/markdownlint-cli2-action`
    (v23), `docker/setup-buildx-action` (v4), `docker/build-push-action` (v7)
- **security-config.yml**: Bump `ansible` `13.7.0` → `14.0.0` and pinned
  `python-version` `3.12` → `3.14.5` (the Trivy IaC Ansible security pass)

---

## 2026-06-02

### Added

- **ci-ansible-molecule.yml**: New reusable workflow that runs Molecule
  scenarios for Ansible collections. Auto-discovers scenarios under
  `extensions/molecule/<scenario>/` (subdirectories starting with `.` are
  skipped, so the `.config` shared-helpers convention is respected).
  Inputs: `collection_namespace` (default `arillso`), `collection_name`,
  optional `scenarios` JSON array, `scenarios_root`, `python_version`,
  `runs_on`, plus the standard `cancel-in-progress` and
  `concurrency-suffix` inputs. Driver is docker.
- **release-go.yml**: GoReleaser-based binary release workflow with
  multi-arch artifact handling and optional pre-build commands.
- **security-code.yml**: Multi-language CodeQL (JavaScript/TypeScript,
  Go, Python, Java) with package-manager auto-detect from lock files.
  Supersedes `security-codeql.yml` for new repos without deprecating it.
- **security-config.yml**: Trivy IaC config scan with opt-in
  Terraform, Kubernetes and Ansible security passes (Kubesec, Trivy,
  `ansible-lint`).
- **security-sbom.yml**: CycloneDX/SPDX SBOM generation for container
  images, filesystem paths and Go binaries (via `cyclonedx-gomod`).

### Changed

- **ai-claude-review.yml**: Reworked into a two-mode follow-up flow.
  - Trigger extended with `synchronize` so the review re-runs on every
    PR push, not only on `opened`/`reopened`/`ready_for_review`.
  - Fork-PR guard added (`head.repo.full_name == github.repository`).
    `pull_request` from forks runs without secrets and would otherwise
    look broken; the job now skips cleanly.
  - Mode is determined in shell from the GitHub Reviews API:
    - `first` mode (no prior bot review on this PR): runs
      `/code-review --comment` with **Claude Opus 4.8** and 100 turns,
      then submits `--approve` or `--request-changes`.
    - `followup` mode (prior bot review exists): does **not** re-run
      `/code-review`. Fetches the diff since `last-review-sha`, replies
      to its own prior inline comments via the GitHub API
      (resolved/still open), adds new inline comments only for the
      delta, and resolves review threads via GraphQL on approve.
      Uses **Claude Sonnet 4.6** with 40 turns to keep follow-up cost
      down.
  - Bot login detected dynamically by matching `claude` in `user.login`
    of prior bot reviews and comments, falling back to `claude[bot]`.
  - `anthropics/claude-code-action` bumped to `v1` (SHA `787c5a0`).
    `allowedTools` expanded for `gh pr review:*`,
    `gh api repos/*/compare/*`, `gh api graphql:*`, and the
    comments/replies endpoints needed for the follow-up flow.
  - New `cancel-in-progress` and `concurrency-suffix` inputs.
  - Top-level `permissions: contents: read`.
  - `persist-credentials: false` on `actions/checkout`.
- **ai-claude.yml**: New `cancel-in-progress` and `concurrency-suffix`
  inputs; top-level `permissions: contents: read`;
  `persist-credentials: false` on `actions/checkout`;
  `anthropics/claude-code-action` bumped to `v1.0.127`.

### Migration notes

The `ai-claude-review.yml` change is **behaviour-breaking** for current
consumers (`arillso/ansible.agent`, `arillso/ansible.container`,
`arillso/ansible.system`): every PR push now triggers a review
iteration instead of only the open/reopen events. Token cost is
mitigated by using Sonnet for follow-ups and reading only the delta
diff. Consumers that want the previous cadence can pin to the
`2026-03-25` ref instead of `main`.

---

## 2026-03-25

### Changed

- **ai-claude-review.yml**: Update `anthropics/claude-code-action` from `v1` to `v1.0.78`
  - Model: `claude-opus-4-6`
  - Max turns: `100`
  - Allowed tools: `mcp__github_inline_comment__create_inline_comment`, `Task`, `Agent`,
    `Read`, `Glob`, `Grep`, `Bash(gh pr ...)`, `Bash(gh issue ...)`, `Bash(gh search:*)`,
    `Bash(git log:*)`
- **ai-claude.yml**: Update `anthropics/claude-code-action` from `v1` to `v1.0.78`

### Fixed

- **ci-ansible-collection.yml**: Pin `aquasecurity/trivy-action` to SHA instead of `@master`

---

## 2026-03-24

### Changed

- **renovate-base.json**: Aligned base configuration with `sbaerlocher/.github`
  - Migrated deprecated `stabilityDays` → `minimumReleaseAge`
  - Migrated deprecated `fileMatch` → `managerFilePatterns` in all custom managers
  - Simplified non-major updates into one group (`all-non-major`) instead of
    separate patch and minor groups
  - Changed schedule from `"before 6am on Monday"` to `"before 6am"` (daily)
  - Removed `prCreation: "not-pending"` — PRs are now created regardless of CI status
  - Removed `dependencyDashboardApproval` from major/pre-release rules — PRs are
    created automatically, automerge remains disabled for manual review
  - Added `configMigration: true` — Renovate auto-migrates deprecated config in
    consumer repos
  - Added `npmDedupe` and `pnpmDedupe` to `postUpdateOptions`
  - Removed `"group:allNonMajor"` and `"schedule:weekdays"` from `extends`
    (now configured explicitly)
  - Removed redundant `dependencyDashboard: true` (set via `:dependencyDashboard`
    in `extends`)
- **renovate-go.json**: Aligned with base conventions
  - Migrated deprecated `matchPackagePrefixes` → `matchPackageNames` with `/**` glob
  - Migrated deprecated `matchPackagePatterns` → `matchPackageNames` with regex
  - Migrated deprecated `excludePackagePrefixes` → negative `matchPackageNames`
  - Migrated `stabilityDays` → `minimumReleaseAge`
  - Migrated `fileMatch` → `managerFilePatterns` in all custom managers
  - Removed redundant `:semanticCommitTypeAll(chore)` from `extends`
  - Removed `dependencyDashboardApproval` (consistent with base)
- **renovate-actions.json**: Removed conflicting `github-actions` package rule
  (base already handles GitHub Actions grouping as `"GitHub Actions"` with digest
  pinning); removed redundant `platformAutomerge: true` from package rule
- **renovate-ansible.json**: Migrated `fileMatch` → `managerFilePatterns` in
  custom manager and `ansible-galaxy` manager config

---

## 2026-03-11

### Added

- **ci-go.yml**: New dedicated Go CI workflow with `go test` and `golangci-lint`
- **actions/check-argument-specs**: New composite action to validate Ansible
  role variables in `defaults/main.yml` against `meta/argument_specs.yml`
  with recursive suboptions checking and GitHub Actions annotations
- **ci-ansible-collection.yml**: New `argument-specs` job using the composite
  action (enabled by default via `enable_argument_specs_check` input)
- Support for `# noqa: argument-specs` comments to skip variables from checks

### Changed

- **ci-go-action.yml → ci-lint.yml**: Renamed and reduced to pure linting tools
  (actionlint, shellcheck, yamllint); Go-specific jobs moved to `ci-go.yml`
- **templates/workflows/ci.yml**: Updated to use `ci-go.yml` + `ci-lint.yml`
  instead of `ci-go-action.yml`

### Fixed

- Skip default value comparison for Jinja2 template expressions
- Improved dict heuristic to avoid false warnings on lookup/mapping dicts
  (e.g. OS-family keys like Debian, RedHat)
- Skip suboptions warning for lookup/mapping dicts
- Recursive suboptions quality check now runs independent of default values

### Chore

- Added Python cache files (`__pycache__/`, `*.pyc`) to `.gitignore`

---

## 2026-03-09

### Changed

- **ai-claude-review.yml**: Switch from manual review prompt to official
  Anthropic `code-review` plugin via `claude-code-plugins`

### Fixed

- **ai-claude-review.yml**: Scope Claude review to PR diff only instead of
  reviewing the entire codebase

---

## 2026-03-08

### Added

Initial repository setup:

- **Community health files**: CODE_OF_CONDUCT.md, CONTRIBUTING.md, GOVERNANCE.md, SECURITY.md, SUPPORT.md
- **Templates**: Issue templates (bug report, feature request, documentation), PR template
- **Configuration templates**: .editorconfig, .golangci.yml, .yamllint.yml, github-ruleset.json
- **Organization profile**: profile/README.md
- **Standards**: STANDARDS.md with repository structure and conventions
- **Renovate presets**: base, go, actions, ansible
- **.github/renovate.json**: Repository-specific Renovate configuration extending base preset
- **AGENTS.md**: AI agent documentation for workflow repository
- **CLAUDE.md**: Claude Code import reference
- **CHANGELOG.md**: Rolling release changelog (this file)
- **.editorconfig**: Root editor configuration (2-space indentation)

**Reusable Workflows** (in `.github/workflows/`):

- **ci-ansible-collection.yml**: CI for Ansible Collections (linting, security, sanity/unit/integration tests, build)
- **ci-go-action.yml**: CI for Go projects and GitHub Actions (golangci-lint, actionlint, shellcheck, yamllint)
- **security-codeql.yml**: CodeQL static code analysis
- **security-trivy.yml**: Trivy vulnerability scanning (filesystem and container images)
- **security-deps.yml**: Dependency vulnerability and license scanning (Go)
- **security-secrets.yml**: Secret detection with Gitleaks, TruffleHog, and pattern detection
- **release-ansible-collection.yml**: Publish Ansible Collections to Galaxy
- **cleanup-container-registry.yml**: Automated GHCR and Docker Hub cleanup
- **ai-claude.yml**: Interactive Claude Code assistant via @claude mentions
- **ai-claude-review.yml**: Automated AI code reviews on pull requests

### Fixed

- **security-secrets.yml**: Replace `gitleaks-action` (requires paid license for orgs)
  with direct Gitleaks CLI installation via `jaxxstorm/action-install-gh-release`
- **ci-ansible-collection.yml**: Update default Ansible versions from EOL
  `stable-2.16`/`stable-2.17`/`devel` to supported `stable-2.18`/`stable-2.19`/`stable-2.20`
- **ci-ansible-collection.yml**: Auto-select Python 3.12 for ansible-core >= 2.20
  which requires Python >= 3.12

### Changed

- **ci-go-action.yml**: Replace abandoned `ibiqlik/action-yamllint` with native `pip install yamllint`
- **cleanup-container-registry.yml**: Replace abandoned `philiplehmann/docker-hub-retention` with Docker Hub API script
- **templates/workflows/ci.yml**: Simplified to use reusable `ci-go-action.yml` workflow
- **templates/workflows/codeql.yml**: Simplified to use reusable `security-codeql.yml` workflow
- **templates/workflows/deploy.yml**: Updated action SHAs, added standalone template note
- **GitHub Actions**: Updated SHA-pinned action references via Renovate
  - `actions/upload-artifact` v4 → v7
  - `artis3n/ansible_galaxy_collection` v2 → v3
  - `docker/build-push-action` v6 → v7
  - `docker/setup-buildx-action` v3 → v4
  - `github/codeql-action` updated to latest SHA
  - `golangci/golangci-lint-action` v6 → v9
  - `aquasecurity/trivy-action` updated to latest SHA
