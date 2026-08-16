# Design

`terraform-github-orgkit` manages an entire GitHub organization as code — members,
teams, repositories, GitHub Actions (variables/secrets/environments), organization
rulesets, and organization roles — as a composable suite you can adopt whole or
piece-by-piece.

## Goals

- **Comprehensive**: cover the organization, teams, repository, and Actions surfaces
  in one coherent suite, using GitHub's current primitives (e.g. rulesets rather than
  legacy per-repo branch protection).
- **Composable**: a root "everything" module plus independently usable submodules
  (`pelotech/orgkit/github//modules/<name>`), so a consumer can manage a whole org or
  just repositories.
- **Unopinionated where it matters**: ship sensible defaults, but express every
  organization-specific decision as an input rather than a hardcoded constant.

## Why this module

The established community modules for GitHub-as-code are all years-stale and split
the problem across separate, thinly-maintained modules. orgkit is a modern,
maintained suite that additionally covers ground none of them do:

| Capability | orgkit |
| ---------- | :----: |
| Org membership, owners, teams, team memberships | ✅ |
| Repositories + team grants | ✅ |
| Actions variables (repo + org) | ✅ |
| Actions secrets (repo + org + environment) | ✅ |
| Environments (reviewers, wait timers, branch policies) | ✅ |
| Organization rulesets (baseline + signed commits) | ✅ |
| Organization roles assigned to teams | ✅ |

## Architecture

Three submodules composed by the root as a one-directional pipeline — no cycles:

```
modules/organization  →  modules/teams  →  modules/repository
```

- **`organization`** — org membership (owners mapped to `admin`, everyone else
  `member`) and org rulesets (baseline branch protection + signed commits). Outputs
  the membership map.
- **`teams`** — teams, team memberships, the optional all-members team, and org-role
  assignments (resolved by name against the org's predefined roles). Consumes the
  membership map + owner set; outputs a `name → {id, slug}` team map and the
  all-members team id.
- **`repository`** — repositories, team↔repo grants, the default all-members read
  grant, repository/environment Actions variables & secrets, and environments.
  Consumes the team map; outputs a repository-id map.

The **root** additionally manages organization-level Actions secrets and variables.
These need both decrypted secret values and repository ids to resolve `selected`
visibility, so they live at the composition root rather than upstream of the
repository module (which would create a dependency cycle).

## Design principles

1. **No hardcoded organization policy.** Every org-specific choice is an input with a
   neutral default:
   - **Owners** are an input — an explicit `owners` set, or the `owners_team`
     convenience that derives owners from a named team. No owners team is assumed.
   - The **all-members team** is controlled by `create_all_members_team` /
     `all_members_team_name`.
   - The **baseline ruleset** is a tunable object (and can be disabled).
   - **Org roles** validate at plan time against the roles GitHub actually exposes,
     not a static allowlist.
2. **Secrets are never decrypted here.** The caller passes already-decrypted values
   via the `secrets` input; decryption is a consumer concern.
3. **KISS.** Opinionated defaults, minimal surface, conventional structure.

## Feature roadmap

**Tier 1 — per-repo depth (`modules/repository`)**

- Issue labels (`github_issue_label`), optional merge-with-github-defaults
- Per-repo `github_repository_ruleset` (composes with the org baseline ruleset)
- Expose currently-fixed repo settings: `topics`, `homepage_url`, merge-strategy
  toggles, `has_wiki`/`has_downloads`, `is_template`, template source,
  `gitignore`/`license_template`, `archived`/`archive_on_destroy`, `default_branch`
- Deploy keys (`github_repository_deploy_key`), webhooks (`github_repository_webhook`)
- Individual collaborators + `triage`/`maintain` permission tiers

**Tier 2 — organization (`modules/organization`)**

- `blocked_users` (`github_organization_block`)
- `github_organization_settings` (default member perms, member privileges)
- Preflight member-existence guard

**Tier 3 — advanced**

- `github_repository_file` — manage shared files (CODEOWNERS, workflows) across repos
- Autolink references (`github_repository_autolink_reference`)
- Dependabot secrets (repo + org), Codespaces secrets
- Actions permissions / allowed-actions (repo + org)
- Custom repository properties + custom org roles

**Out of scope**: classic org/repo Projects (legacy; Projects V2 is not cleanly
manageable in the provider) and the deprecated `branch_protection_v3` resource
(rulesets supersede it).

## Planned default changes

Defaults intended to change in a future major release. They preserve today's
behavior for now, so existing configs see no plan churn until then:

- **Merge strategy** — switch the default from merge commits to squash-only
  (`allow_squash_merge = true`, `allow_merge_commit = false`). The module currently
  defaults to merge commits.
