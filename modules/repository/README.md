# orgkit / repository

Manages GitHub repositories and their team grants, the default all-members read
grant, repository and environment Actions variables and secrets, and repository
environments (reviewers, wait timers, deployment branch policies).

Consumes a `name → { id, slug }` team map (e.g. from the teams module, a
`github_team` data source, or literal ids) so it can be used standalone.

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

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [github_actions_environment_secret.internal](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_secret) | resource |
| [github_actions_environment_variable.internal](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_variable) | resource |
| [github_actions_secret.repo](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_variable.repo](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_branch_default.internal](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch_default) | resource |
| [github_repository.internal](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository) | resource |
| [github_repository_environment.internal](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment) | resource |
| [github_repository_environment_deployment_policy.internal](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment_deployment_policy) | resource |
| [github_repository_vulnerability_alerts.internal](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_vulnerability_alerts) | resource |
| [github_team_repository.everyone](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/team_repository) | resource |
| [github_team_repository.internal](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/team_repository) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_all_members_team_id"></a> [all\_members\_team\_id](#input\_all\_members\_team\_id) | ID of the all-members team that receives default read access on non-restricted repositories. null disables the default read grant. | `string` | `null` | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | Repositories to manage and which teams may access them. `readers`, `writers`<br/>and `admins` reference team names from `var.teams`. A team listed at more than<br/>one level gets the highest permission (admin > write > read). Set<br/>`restricted = true` to withhold the default all-members read grant. | <pre>list(object({<br/>    name        = string<br/>    description = string<br/>    visibility  = optional(string, "private")<br/>    readers     = optional(list(string), [])<br/>    writers     = optional(list(string), [])<br/>    admins      = optional(list(string), [])<br/>    restricted  = optional(bool, false)<br/><br/>    topics             = optional(list(string), [])<br/>    homepage_url       = optional(string, null)<br/>    has_issues         = optional(bool, true)<br/>    has_wiki           = optional(bool, false)<br/>    has_projects       = optional(bool, false)<br/>    has_downloads      = optional(bool, true)<br/>    is_template        = optional(bool, false)<br/>    gitignore_template = optional(string, null)<br/>    license_template   = optional(string, null)<br/>    archived           = optional(bool, false)<br/>    archive_on_destroy = optional(bool, false)<br/>    default_branch     = optional(string, null)<br/>    enable_pages       = optional(bool, false)<br/>    signed_commits     = optional(bool, true)<br/><br/>    allow_merge_commit     = optional(bool, true)<br/>    allow_squash_merge     = optional(bool, false)<br/>    allow_rebase_merge     = optional(bool, false)<br/>    allow_auto_merge       = optional(bool, true)<br/>    delete_branch_on_merge = optional(bool, true)<br/>    merge_commit_message   = optional(string, "PR_BODY")<br/>    merge_commit_title     = optional(string, "PR_TITLE")<br/><br/>    template = optional(object({<br/>      owner                = string<br/>      repository           = string<br/>      include_all_branches = optional(bool, false)<br/>    }))<br/><br/>    variables = optional(map(string), {})<br/>    environments = optional(map(object({<br/>      variables  = optional(map(string), {})<br/>      reviewers  = optional(list(string), [])<br/>      wait_timer = optional(number, 0)<br/>      deployment_branch_policy = optional(object({<br/>        protected_branches     = optional(bool, false)<br/>        custom_branch_policies = optional(list(string), [])<br/>      }))<br/>    })), {})<br/>  }))</pre> | `[]` | no |
| <a name="input_repository_secrets"></a> [repository\_secrets](#input\_repository\_secrets) | Per-repository Actions and environment secret values (plaintext), keyed by<br/>repository name. Supplied already-decrypted by the caller; this module never<br/>performs decryption. | <pre>map(object({<br/>    actions      = optional(map(string), {})<br/>    environments = optional(map(map(string)), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_teams"></a> [teams](#input\_teams) | Map of team name => { id, slug } for teams that may be granted repository access or set as environment reviewers. Supplied by the teams module. | <pre>map(object({<br/>    id   = string<br/>    slug = string<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_repositories"></a> [repositories](#output\_repositories) | Map of repository name => full github\_repository resource attributes. |
| <a name="output_repository_ids"></a> [repository\_ids](#output\_repository\_ids) | Map of repository name => numeric repo\_id. Consumed at the root to scope org-level secrets/variables with 'selected' visibility. |
<!-- END_TF_DOCS -->
