# Repository-only example — use a single submodule

Uses just `modules/repository` to manage repositories and team grants, supplying
team ids yourself (here via a `github_team` data source) instead of adopting the
whole suite. This is the "use just one piece" story.

```sh
terraform init
terraform validate
```

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
| <a name="module_repositories"></a> [repositories](#module\_repositories) | ../../modules/repository | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [github_team.developers](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/team) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_repository_ids"></a> [repository\_ids](#output\_repository\_ids) | Managed repositories (name => repo\_id). |
<!-- END_TF_DOCS -->
