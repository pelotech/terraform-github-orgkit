# orgkit / organization

Manages GitHub organization membership (owners mapped to `admin`, everyone else
`member`) and the organization-wide rulesets: a baseline branch-protection ruleset
on the default branch of every repository, and a required-signed-commits ruleset.

Who is an owner is entirely the caller's choice (`var.owners`) — no owners team is
hardcoded.

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
| [github_membership.internal](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/membership) | resource |
| [github_organization_ruleset.internal](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/organization_ruleset) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_enabled_presets"></a> [enabled\_presets](#input\_enabled\_presets) | Names of built-in ruleset presets to enable. See modules/organization/main.tf local.presets. | `list(string)` | <pre>[<br/>  "require_pull_request_reviews",<br/>  "restrict_deletions",<br/>  "require_signed_commits"<br/>]</pre> | no |
| <a name="input_members"></a> [members](#input\_members) | Set of GitHub usernames that are members of the organization. | `set(string)` | `[]` | no |
| <a name="input_organization_rulesets"></a> [organization\_rulesets](#input\_organization\_rulesets) | Organization rulesets, keyed by name. Merged with (and overridden by name by)<br/>the presets selected via enabled\_presets. bypass\_actors uses raw numeric<br/>actor\_id (OrganizationAdmin needs none); team-name bypass is per-repo only. | <pre>map(object({<br/>    enforcement          = optional(string, "active")<br/>    target               = optional(string, "branch")<br/>    include_refs         = optional(list(string), ["~ALL"])<br/>    exclude_refs         = optional(list(string), [])<br/>    include_repositories = optional(list(string), ["~ALL"])<br/>    exclude_repositories = optional(list(string), [])<br/>    bypass_actors = optional(list(object({<br/>      actor_type  = string<br/>      actor_id    = optional(number, 0)<br/>      bypass_mode = optional(string, "always")<br/>    })), [])<br/>    rules = object({<br/>      creation                = optional(bool, false)<br/>      update                  = optional(bool, false)<br/>      deletion                = optional(bool, false)<br/>      non_fast_forward        = optional(bool, false)<br/>      required_signatures     = optional(bool, false)<br/>      required_linear_history = optional(bool, false)<br/>      pull_request = optional(object({<br/>        required_approving_review_count   = optional(number, 0)<br/>        require_code_owner_review         = optional(bool, false)<br/>        require_last_push_approval        = optional(bool, false)<br/>        dismiss_stale_reviews_on_push     = optional(bool, false)<br/>        required_review_thread_resolution = optional(bool, false)<br/>      }))<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_owners"></a> [owners](#input\_owners) | Subset of `members` that are organization owners (mapped to GitHub's `admin`<br/>membership role); everyone else is a plain `member`. The consumer decides who<br/>is an owner — there is no hardcoded owners team. | `set(string)` | `[]` | no |
| <a name="input_signed_commits_excluded_repositories"></a> [signed\_commits\_excluded\_repositories](#input\_signed\_commits\_excluded\_repositories) | Repository names excluded from the required-signed-commits ruleset. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_members"></a> [members](#output\_members) | Map of username => managed membership username. Passed to the teams module so team memberships are ordered after organization membership. |
<!-- END_TF_DOCS -->
