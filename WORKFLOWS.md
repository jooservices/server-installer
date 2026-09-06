# GitHub Actions workflow flow

This document describes the workflows in `.github/workflows/`.
Most jobs run on GitHub-hosted `ubuntu-latest`; OS smoke jobs use Ubuntu,
Debian, and Rocky Linux Docker images, with the ARM64 leg using an
`ubuntu-24.04-arm` runner.
E2E suites use Docker (DinD-capable privileged containers) via `tests/run_e2e.sh`.

## Overall event flow

```mermaid
flowchart TD
    native[GitHub Secret Scanning and Push Protection] --> Alerts[GitHub security alerts or blocked push]

    pr[PR to master or develop] --> CI[CI — full quality gate]
    pr --> CodeQL[CodeQL Actions]
    pr --> Commitlint[Commitlint]
    pr --> Semantic[Semantic PR Title]
    pr --> PathLabel[PR Labeler]
    pr --> Audit{Changed files under .github?}
    Audit -->|yes| WorkflowAudit[Workflow audit]

    push[Push to master or develop] --> PostMerge[CI post-merge]
    push --> CodeQL
    push --> Audit
    push --> Scorecard{master only?}
    Scorecard -->|yes| ScorecardRun[OpenSSF Scorecard]

    tag[Push tag v*.*.*] --> Release[Release]

    weekly[Weekly schedules] --> CodeQL
    weekly --> LinkCheck[Link check]
    weekly --> Scorecard
    weekly --> WorkflowAudit

    daily[Daily schedule] --> Stale[Stale]

    manual[workflow_dispatch] --> LinkCheck
    manual --> Scorecard
    manual --> Stale
    manual --> WorkflowAudit
```

## Pull-request gate (`ci.yml`)

**Trigger:** pull requests targeting `master` or `develop`.

```mermaid
flowchart TD
    PR[Pull request] --> V[Validate]
    V --> L[Lint — shellcheck]
    L --> S[Security matrix]
    L --> T[Test]
    S --> C[Coverage upload — aggregate gate]
    T --> C

    S --- S1[Dependencies: OSV Scanner]
    S --- S2[Secrets: Gitleaks]
    S --- S3[SAST: Semgrep auto]
    T --- T1[Module coverage map]
    T --- T2[Metadata and preflight tests]
    T --- T3[E2E essentials]
    T --- T4[E2E wizard]
    T --- T5[OS smoke matrix]
    T5 --> C
```

Final required-style job name: **Coverage upload** (aggregates Validate → Lint → Security → Test → OS smoke matrix).
There is no Codecov/Sonar upload for this Bash project — omit those README badges until configured.

Dependency Review Action is not used (needs Dependency graph / GHAS support); OSV covers the Dependencies security leg.

Local full matrix: `make e2e` (all suites). CI runs the Ubuntu full essentials/wizard gate plus Debian/Rocky/ARM64 essentials smoke coverage.

## Post-merge (`ci-post-merge.yml`)

Push to `master` / `develop`: syntax check → shellcheck → coverage map → essentials E2E.

## Policy workflows

| Workflow | Job name | Role |
| --- | --- | --- |
| `commitlint.yml` | Validate commit messages | Conventional Commits on PR commits |
| `semantic-pr.yml` | Validate PR Title | Type + uppercase subject |
| `codeql.yml` | Analyze GitHub Actions | Actions language |
| `workflow-audit.yml` | Actionlint / Zizmor | When `.github/**` changes |
| `scorecard.yml` | Scorecard Analysis | OpenSSF |
| `pr-labeler.yml` | Auto-label PR | Path labels |
| `stale.yml` | Mark stale | Issues/PRs |
| `link-check.yml` | Check Markdown links | Weekly lychee |
| `release.yml` | Release | Tag `v*.*.*` on master |

## Dependabot

Weekly `github-actions` updates (`ci` conventional prefix).
