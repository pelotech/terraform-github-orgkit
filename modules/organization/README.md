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
| [github_organization_ruleset.baseline](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/organization_ruleset) | resource |
| [github_organization_ruleset.signed_commits](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/organization_ruleset) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_baseline_ruleset"></a> [baseline\_ruleset](#input\_baseline\_ruleset) | Baseline org-wide branch-protection ruleset applied to the default branch of<br/>every repository. Set `enabled = false` to disable it entirely. Defaults<br/>reproduce a require-review + code-owner-review + thread-resolution policy. | <pre>object({<br/>    enabled                           = optional(bool, true)<br/>    block_deletion                    = optional(bool, true)<br/>    block_force_pushes                = optional(bool, false)<br/>    required_approving_review_count   = optional(number, 1)<br/>    require_code_owner_review         = optional(bool, true)<br/>    require_last_push_approval        = optional(bool, false)<br/>    dismiss_stale_reviews_on_push     = optional(bool, false)<br/>    required_review_thread_resolution = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_members"></a> [members](#input\_members) | Set of GitHub usernames that are members of the organization. | `set(string)` | `[]` | no |
| <a name="input_owners"></a> [owners](#input\_owners) | Subset of `members` that are organization owners (mapped to GitHub's `admin`<br/>membership role); everyone else is a plain `member`. The consumer decides who<br/>is an owner — there is no hardcoded owners team. | `set(string)` | `[]` | no |
| <a name="input_require_signed_commits"></a> [require\_signed\_commits](#input\_require\_signed\_commits) | Require signed commits on all branches of all repositories (except those excluded). | `bool` | `true` | no |
| <a name="input_signed_commits_excluded_repositories"></a> [signed\_commits\_excluded\_repositories](#input\_signed\_commits\_excluded\_repositories) | Repository names excluded from the required-signed-commits ruleset. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_members"></a> [members](#output\_members) | Map of username => managed membership username. Passed to the teams module so team memberships are ordered after organization membership. |
<!-- END_TF_DOCS -->
