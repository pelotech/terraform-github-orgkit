# orgkit / teams

Manages GitHub teams and their memberships, an optional all-members team (for
default repository read access), and predefined organization-role assignments per
team (resolved by name against the org's predefined roles).

Consumes the membership map and owner set from the organization module; outputs a
`name → { id, slug }` team map for the repository module.

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
| [github_organization_role_team.internal](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/organization_role_team) | resource |
| [github_team.everyone](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/team) | resource |
| [github_team.internal](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/team) | resource |
| [github_team_members.everyone](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/team_members) | resource |
| [github_team_members.internal](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/team_members) | resource |
| [github_organization_roles.internal](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/organization_roles) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_all_members_team_description"></a> [all\_members\_team\_description](#input\_all\_members\_team\_description) | Description of the all-members team. | `string` | `"All organization members. Grants default read access to non-restricted repositories."` | no |
| <a name="input_all_members_team_name"></a> [all\_members\_team\_name](#input\_all\_members\_team\_name) | Name of the all-members team. | `string` | `"everyone"` | no |
| <a name="input_create_all_members_team"></a> [create\_all\_members\_team](#input\_create\_all\_members\_team) | Create a team containing every organization member, used to grant default read access to non-restricted repositories. | `bool` | `true` | no |
| <a name="input_members"></a> [members](#input\_members) | Map of org member username => username, from the organization module. Used to<br/>order team membership after organization membership. Falls back to the raw<br/>username when a member is not present (standalone use). | `map(string)` | `{}` | no |
| <a name="input_owners"></a> [owners](#input\_owners) | Organization owner usernames. GitHub force-assigns owners the `maintainer`<br/>role in any team they join, so the module assigns that role to them (and<br/>`member` to everyone else) to avoid perpetual drift. | `set(string)` | `[]` | no |
| <a name="input_teams"></a> [teams](#input\_teams) | Teams and their membership. A team may hold predefined organization-level<br/>GitHub roles via `org_roles` (one assignment per role), resolved by name<br/>against the organization's predefined roles (e.g. `security_manager`,<br/>`app_manager`, `cicd_admin`). Unknown role names fail at plan time. | <pre>list(object({<br/>    name        = string<br/>    description = string<br/>    members     = optional(list(string), [])<br/>    org_roles   = optional(list(string), [])<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_all_members_team_id"></a> [all\_members\_team\_id](#output\_all\_members\_team\_id) | ID of the all-members team, or null when create\_all\_members\_team = false. |
| <a name="output_teams"></a> [teams](#output\_teams) | Map of team name => { id, slug } for every managed team. Consumed by the repository module for team↔repo grants and environment reviewers. |
<!-- END_TF_DOCS -->
