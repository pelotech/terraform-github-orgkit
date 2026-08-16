# terraform-github-orgkit

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

See [`docs/PLAN.md`](docs/PLAN.md) for the design rationale, a comparison with the
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
| <a name="input_baseline_ruleset"></a> [baseline\_ruleset](#input\_baseline\_ruleset) | Baseline org-wide branch-protection ruleset. See the organization submodule for the object schema; set enabled = false to disable. | <pre>object({<br/>    enabled                           = optional(bool, true)<br/>    block_deletion                    = optional(bool, true)<br/>    block_force_pushes                = optional(bool, false)<br/>    required_approving_review_count   = optional(number, 1)<br/>    require_code_owner_review         = optional(bool, true)<br/>    require_last_push_approval        = optional(bool, false)<br/>    dismiss_stale_reviews_on_push     = optional(bool, false)<br/>    required_review_thread_resolution = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_create_all_members_team"></a> [create\_all\_members\_team](#input\_create\_all\_members\_team) | Create an all-members team that grants default read access to non-restricted repositories. | `bool` | `true` | no |
| <a name="input_organization_secrets"></a> [organization\_secrets](#input\_organization\_secrets) | Visibility config for org-level shared secrets. Values come from var.secrets.org. | <pre>map(object({<br/>    visibility   = optional(string, "private")<br/>    repositories = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_organization_variables"></a> [organization\_variables](#input\_organization\_variables) | Org-level shared Actions variables (plaintext value + visibility). | <pre>map(object({<br/>    value        = string<br/>    visibility   = optional(string, "private")<br/>    repositories = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_owners"></a> [owners](#input\_owners) | Explicit set of owner usernames (mapped to GitHub's `admin` role). Ignored when `owners_team` is set. | `set(string)` | `[]` | no |
| <a name="input_owners_team"></a> [owners\_team](#input\_owners\_team) | Convenience: derive organization owners from the members of this team, by<br/>name. `null` (default) means use the explicit `owners` set instead. There is<br/>no hardcoded owners team — the consumer chooses. | `string` | `null` | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | Repositories and which teams may access them. See the repository submodule for the full object schema and validations. | <pre>list(object({<br/>    name           = string<br/>    description    = string<br/>    visibility     = optional(string, "private")<br/>    readers        = optional(list(string), [])<br/>    writers        = optional(list(string), [])<br/>    admins         = optional(list(string), [])<br/>    restricted     = optional(bool, false)<br/>    enable_pages   = optional(bool, false)<br/>    unsafe_merges  = optional(bool, false)<br/>    signed_commits = optional(bool, true)<br/>    variables      = optional(map(string), {})<br/>    environments = optional(map(object({<br/>      variables  = optional(map(string), {})<br/>      reviewers  = optional(list(string), [])<br/>      wait_timer = optional(number, 0)<br/>      deployment_branch_policy = optional(object({<br/>        protected_branches     = optional(bool, false)<br/>        custom_branch_policies = optional(list(string), [])<br/>      }))<br/>    })), {})<br/>  }))</pre> | `[]` | no |
| <a name="input_require_signed_commits"></a> [require\_signed\_commits](#input\_require\_signed\_commits) | Require signed commits on all branches of all repositories (except repositories with signed\_commits = false). | `bool` | `true` | no |
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
