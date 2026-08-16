# terraform-github-orgkit

[![Terraform Registry](https://img.shields.io/badge/Terraform%20Registry-orgkit-844FBA?logo=terraform)](https://registry.terraform.io/modules/pelotech/orgkit/github/latest)
[![Release](https://img.shields.io/github/v/release/pelotech/terraform-github-orgkit)](https://github.com/pelotech/terraform-github-orgkit/releases)
[![Tests](https://github.com/pelotech/terraform-github-orgkit/actions/workflows/test.yaml/badge.svg)](https://github.com/pelotech/terraform-github-orgkit/actions/workflows/test.yaml)
[![License](https://img.shields.io/github/license/pelotech/terraform-github-orgkit)](LICENSE)

A composable Terraform module suite for managing a **whole GitHub organization** as
code — members, teams, repositories, GitHub Actions (variables, secrets and
environments), organization rulesets, and organization roles.

Use the whole thing, or just one piece:

```hcl
# Everything — the root module manages the entire organization.
module "github" {
  source  = "pelotech/orgkit/github"
  version = "~> 0.2"

  users        = [/* ... */]
  teams        = [/* ... */]
  repositories = [/* ... */]
}

# Or adopt a single submodule.
module "repos" {
  source  = "pelotech/orgkit/github//modules/repository"
  version = "~> 0.1"

  teams        = { developers = { id = "123", slug = "developers" } }
  repositories = [/* ... */]
}
```

## Why orgkit

The well-known community modules for GitHub-as-code are all years-stale. orgkit is a
maintained, modern alternative that also does **more** than any of them on the
organization and Actions axes:

- **GitHub Actions** — repository and environment variables, repository and
  environment secrets, and **organization-level** secrets/variables with
  `all`/`private`/`selected` visibility.
- **Environments** — reviewers, wait timers, and deployment branch policies.
- **Organization rulesets** — a baseline branch-protection ruleset and a
  required-signed-commits ruleset (the modern replacement for per-repo branch
  protection).
- **Organization roles** — assign predefined org roles (e.g. `security_manager`) to
  teams.
- **Opinionated defaults, no hardcoded policy** — every organization-specific choice
  (who is an owner, the all-members team, ruleset tuning) is an input, not a baked-in
  constant.

See [`docs/DESIGN.md`](docs/DESIGN.md) for the design rationale, a comparison with the
existing ecosystem modules, and the feature roadmap.

## Architecture

Three submodules composed by the root as a one-directional pipeline (no cycles):

```
modules/organization  →  modules/teams  →  modules/repository
```

| Submodule | Manages |
| --------- | ------- |
| [`organization`](modules/organization) | Org membership, owner/admin assignment, org rulesets (baseline + signed commits). |
| [`teams`](modules/teams) | Teams, team memberships, the optional all-members team, org-role assignments. |
| [`repository`](modules/repository) | Repositories, team↔repo grants, repo/environment Actions variables & secrets, environments. |

The **root** additionally manages organization-level Actions secrets and variables
(they need both secret values and repository ids, so they live at the composition
root).

## Examples

- [`examples/complete`](examples/complete) — manage an entire organization.
- [`examples/repository`](examples/repository) — use only the repository submodule.

## Stability

orgkit is **pre-1.0** and the input interface may still change between minor
releases. Pin a version (`version = "~> 0.2"`) and review the changelog before
upgrading. Breaking input changes so far, since the initial release:

- **`unsafe_merges` removed** — use `allow_squash_merge` / `allow_rebase_merge`
  (and the other granular merge controls) instead.
- **`baseline_ruleset` and `require_signed_commits` removed** — use
  `enabled_presets` (defaults reproduce the previous behavior) and
  `organization_rulesets`; per-repo rules via `repositories[].rulesets`.
- **Default merge strategy is now squash-only** (`allow_squash_merge = true`,
  `allow_merge_commit = false`). Set the `allow_*` fields per repository to
  change it.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_github"></a> [github](#provider\_github) | ~> 6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_organization"></a> [organization](#module\_organization) | ./modules/organization | n/a |
| <a name="module_repository"></a> [repository](#module\_repository) | ./modules/repository | n/a |
| <a name="module_teams"></a> [teams](#module\_teams) | ./modules/teams | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [github_actions_organization_secret.internal](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_organization_secret) | resource |
| [github_actions_organization_variable.internal](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_organization_variable) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_all_members_team_name"></a> [all\_members\_team\_name](#input\_all\_members\_team\_name) | Name of the all-members team. | `string` | `"everyone"` | no |
| <a name="input_create_all_members_team"></a> [create\_all\_members\_team](#input\_create\_all\_members\_team) | Create an all-members team that grants default read access to non-restricted repositories. | `bool` | `true` | no |
| <a name="input_enabled_presets"></a> [enabled\_presets](#input\_enabled\_presets) | Names of built-in ruleset presets to enable. See modules/organization/main.tf local.presets. | `list(string)` | <pre>[<br/>  "require_pull_request_reviews",<br/>  "restrict_deletions",<br/>  "require_signed_commits"<br/>]</pre> | no |
| <a name="input_organization_rulesets"></a> [organization\_rulesets](#input\_organization\_rulesets) | Organization rulesets, keyed by name. Merged with (and overridden by name by)<br/>the presets selected via enabled\_presets. bypass\_actors uses raw numeric<br/>actor\_id (OrganizationAdmin needs none); team-name bypass is per-repo only. | <pre>map(object({<br/>    enforcement          = optional(string, "active")<br/>    target               = optional(string, "branch")<br/>    include_refs         = optional(list(string), ["~ALL"])<br/>    exclude_refs         = optional(list(string), [])<br/>    include_repositories = optional(list(string), ["~ALL"])<br/>    exclude_repositories = optional(list(string), [])<br/>    bypass_actors = optional(list(object({<br/>      actor_type  = string<br/>      actor_id    = optional(number, 0)<br/>      bypass_mode = optional(string, "always")<br/>    })), [])<br/>    rules = object({<br/>      creation                = optional(bool, false)<br/>      update                  = optional(bool, false)<br/>      deletion                = optional(bool, false)<br/>      non_fast_forward        = optional(bool, false)<br/>      required_signatures     = optional(bool, false)<br/>      required_linear_history = optional(bool, false)<br/>      pull_request = optional(object({<br/>        required_approving_review_count   = optional(number, 0)<br/>        require_code_owner_review         = optional(bool, false)<br/>        require_last_push_approval        = optional(bool, false)<br/>        dismiss_stale_reviews_on_push     = optional(bool, false)<br/>        required_review_thread_resolution = optional(bool, false)<br/>      }))<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_organization_secrets"></a> [organization\_secrets](#input\_organization\_secrets) | Visibility config for org-level shared secrets. Values come from var.secrets.org. | <pre>map(object({<br/>    visibility   = optional(string, "private")<br/>    repositories = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_organization_variables"></a> [organization\_variables](#input\_organization\_variables) | Org-level shared Actions variables (plaintext value + visibility). | <pre>map(object({<br/>    value        = string<br/>    visibility   = optional(string, "private")<br/>    repositories = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_owners"></a> [owners](#input\_owners) | Explicit set of owner usernames (mapped to GitHub's `admin` role). Ignored when `owners_team` is set. | `set(string)` | `[]` | no |
| <a name="input_owners_team"></a> [owners\_team](#input\_owners\_team) | Convenience: derive organization owners from the members of this team, by<br/>name. `null` (default) means use the explicit `owners` set instead. There is<br/>no hardcoded owners team — the consumer chooses. | `string` | `null` | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | Repositories and which teams may access them. See the repository submodule for the full object schema and validations. | <pre>list(object({<br/>    name        = string<br/>    description = string<br/>    visibility  = optional(string, "private")<br/>    readers     = optional(list(string), [])<br/>    writers     = optional(list(string), [])<br/>    admins      = optional(list(string), [])<br/>    restricted  = optional(bool, false)<br/><br/>    topics             = optional(list(string), [])<br/>    homepage_url       = optional(string, null)<br/>    has_issues         = optional(bool, true)<br/>    has_wiki           = optional(bool, false)<br/>    has_projects       = optional(bool, false)<br/>    has_downloads      = optional(bool, true)<br/>    is_template        = optional(bool, false)<br/>    gitignore_template = optional(string, null)<br/>    license_template   = optional(string, null)<br/>    archived           = optional(bool, false)<br/>    archive_on_destroy = optional(bool, false)<br/>    default_branch     = optional(string, null)<br/>    enable_pages       = optional(bool, false)<br/>    signed_commits     = optional(bool, true)<br/><br/>    allow_merge_commit     = optional(bool, false)<br/>    allow_squash_merge     = optional(bool, true)<br/>    allow_rebase_merge     = optional(bool, false)<br/>    allow_auto_merge       = optional(bool, true)<br/>    delete_branch_on_merge = optional(bool, true)<br/>    merge_commit_message   = optional(string, "PR_BODY")<br/>    merge_commit_title     = optional(string, "PR_TITLE")<br/><br/>    template = optional(object({<br/>      owner                = string<br/>      repository           = string<br/>      include_all_branches = optional(bool, false)<br/>    }))<br/><br/>    rulesets = optional(map(object({<br/>      enforcement  = optional(string, "active")<br/>      target       = optional(string, "branch")<br/>      include_refs = optional(list(string), ["~ALL"])<br/>      exclude_refs = optional(list(string), [])<br/>      bypass_actors = optional(list(object({<br/>        actor_type  = string<br/>        actor_id    = optional(number, 0)<br/>        team        = optional(string)<br/>        bypass_mode = optional(string, "always")<br/>      })), [])<br/>      rules = object({<br/>        creation                = optional(bool, false)<br/>        update                  = optional(bool, false)<br/>        deletion                = optional(bool, false)<br/>        non_fast_forward        = optional(bool, false)<br/>        required_signatures     = optional(bool, false)<br/>        required_linear_history = optional(bool, false)<br/>        pull_request = optional(object({<br/>          required_approving_review_count   = optional(number, 0)<br/>          require_code_owner_review         = optional(bool, false)<br/>          require_last_push_approval        = optional(bool, false)<br/>          dismiss_stale_reviews_on_push     = optional(bool, false)<br/>          required_review_thread_resolution = optional(bool, false)<br/>        }))<br/>      })<br/>    })), {})<br/><br/>    variables = optional(map(string), {})<br/>    environments = optional(map(object({<br/>      variables  = optional(map(string), {})<br/>      reviewers  = optional(list(string), [])<br/>      wait_timer = optional(number, 0)<br/>      deployment_branch_policy = optional(object({<br/>        protected_branches     = optional(bool, false)<br/>        custom_branch_policies = optional(list(string), [])<br/>      }))<br/>    })), {})<br/>  }))</pre> | `[]` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | Decrypted secret values keyed by scope. Supplied already-decrypted by the caller; this module never performs decryption. | <pre>object({<br/>    org = optional(map(string), {})<br/>    repos = optional(map(object({<br/>      actions      = optional(map(string), {})<br/>      environments = optional(map(map(string)), {})<br/>    })), {})<br/>  })</pre> | <pre>{<br/>  "org": {},<br/>  "repos": {}<br/>}</pre> | no |
| <a name="input_teams"></a> [teams](#input\_teams) | Teams and their membership. A team may hold predefined organization-level<br/>GitHub roles via `org_roles`. Repository access is granted per repository via<br/>readers/writers/admins, not through org roles. | <pre>list(object({<br/>    name        = string<br/>    description = string<br/>    members     = optional(list(string), [])<br/>    org_roles   = optional(list(string), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_users"></a> [users](#input\_users) | Organization members. `fullname`/`email` are informational; membership is keyed on `username`. | <pre>list(object({<br/>    username = string<br/>    fullname = optional(string, "")<br/>    email    = optional(string, "")<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_all_members_team_id"></a> [all\_members\_team\_id](#output\_all\_members\_team\_id) | ID of the all-members team, or null when create\_all\_members\_team = false. |
| <a name="output_members"></a> [members](#output\_members) | Map of organization member username => managed membership username. |
| <a name="output_repository_ids"></a> [repository\_ids](#output\_repository\_ids) | Map of repository name => numeric repo\_id. |
| <a name="output_teams"></a> [teams](#output\_teams) | Map of team name => { id, slug }. |
<!-- END_TF_DOCS -->
