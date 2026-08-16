# Complete example — manage a whole organization

A comprehensive sample of the full orgkit interface: members, owners-by-team, teams
(including one holding an org role), repositories across every access level (with a
restricted repo, GitHub Pages, and merge / signed-commit opt-outs), per-repo and
environment Actions variables & secrets, environments using both deployment-branch-
policy styles, and org-level secrets & variables. All values are illustrative.

```sh
terraform init
terraform validate
```

Applying requires a `github` provider configured with a token that has org-admin
scope; see the provider docs.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_orgkit"></a> [orgkit](#module\_orgkit) | ../../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_repository_ids"></a> [repository\_ids](#output\_repository\_ids) | Managed repositories (name => repo\_id). |
| <a name="output_teams"></a> [teams](#output\_teams) | Managed teams (name => { id, slug }). |
<!-- END_TF_DOCS -->
