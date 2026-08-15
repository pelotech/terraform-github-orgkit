# terraform-github-orgkit

A composable Terraform module suite for managing a **whole GitHub organization** —
members, teams, repositories, Actions (variables/secrets/environments), org-level
rulesets, and org roles. Published to the Terraform Registry as
`pelotech/orgkit/github`.

**Use the whole thing, or just one piece:**

```hcl
# everything — the root module
module "github" {
  source = "pelotech/orgkit/github"
  # users, teams, repositories, ...
}

# just one submodule
module "repos" {
  source = "pelotech/orgkit/github//modules/repository"
}
```

## Why this exists

The well-known community modules (`mineiros-io/terraform-github-repository`,
`boldlink/terraform-github-repository`, `mineiros-io/terraform-github-organization`)
are all years-stale. orgkit is the modern, maintained alternative and already does
**more** on the org/Actions axis: Actions variables, environments, environment
secrets, org secrets/variables, org rulesets, and org roles — none of which those
modules implement.

Full design rationale, the module-comparison analysis, and the feature roadmap live
in [`docs/DESIGN.md`](docs/DESIGN.md). Read it before making structural changes.

## Architecture

Three submodules composed by the root, wired as a clean one-directional DAG (no
cycles):

```
modules/organization ──▶ modules/teams ──▶ modules/repository
```

- **`modules/organization`** — org membership, owner/admin assignment, org rulesets
  (baseline + signed commits). Outputs the membership map.
- **`modules/teams`** — teams, team memberships, the optional all-members team, and
  org-role assignments. Consumes the membership map + `owners`; outputs a
  `name → {id, slug}` team map and the all-members team id.
- **`modules/repository`** — repositories, team↔repo grants, repo/environment Actions
  variables & secrets, environments. Consumes the team map; outputs repo id map.
- **Root (`/`)** — resolves `owners`, instantiates the three submodules, wires
  outputs→inputs, and additionally manages **org-level Actions secrets/variables**
  (they need both secret values and repo ids, so they live at the composition root).

## Design principles (do not violate)

1. **No consumer-specific policy hardcoded.** orgkit ships neutral defaults +
   interfaces. In particular: *owners are an input* (`owners` set, or the
   `owners_team` convenience) — there is **no** hardcoded `"leadership"` team. A
   consumer decides which team/users confer ownership. The string `"leadership"`
   must never appear in this repo.
2. **Secrets are never decrypted here.** The caller decrypts and passes plaintext
   values via the `secrets` input. Decryption is a consumer concern.
3. **KISS.** Opinionated, minimal, conventional. Avoid over-engineering.
4. **Conventional Commits** + `release-please`. PR titles are linted. Work on
   feature branches, never commit straight to `main`.

## Roadmap (tracked in docs/DESIGN.md)

- **Tier 1** (per-repo parity): issue labels, per-repo `github_repository_ruleset`,
  exposing hardcoded repo knobs (topics, homepage, templates, …), deploy keys,
  webhooks, individual collaborators + triage/maintain tiers.
- **Tier 2** (org): `blocked_users`, `github_organization_settings`, member preflight.
- **Tier 3** (leapfrog): repository files, autolinks, dependabot/codespaces secrets,
  Actions permissions, custom repo properties + custom org roles.

## Verifying changes

```sh
terraform fmt -recursive
cd examples/complete && terraform init && terraform validate
cd ../repository && terraform init && terraform validate
pre-commit run --all-files
```
